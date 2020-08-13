;NMT.ASM

; Aitor Olarra
; 11-8-00

;Copyright (C) 2001  Aitor Olarra

;This library is free software; you can redistribute it and/or
;modify it under the terms of the GNU Library General Public
;License as published by the Free Software Foundation; either
;version 2 of the License, or (at your option) any later version.
;
;This library is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;Library General Public License for more details.
;
;You should have received a copy of the GNU Library General Public
;License along with this library; if not, write to the
;Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;Boston, MA  02111-1307, USA.

; == variables ============================================================
;

nmtData	UDATA
nmtSwitches	res 1	; bit 7	     -> frecuencia reloj
			;   0 => 4Mhz y 1 => 8Mhz	 
			; bits <6..4>-> velocidad CAN
			;     0   1   2   3   4   5  6  7	
			;   (1000,800,500,250,125,50,20,10 Kb/s)
			; bits <4..0>-> num. nodo para CANopen
nmtNodeId	res 1
nmtEstado	res 1
nmtTemp1	res 1
nmtTemp2	res 1

	GLOBAL	nmtEstado

;nmtEstado:
; 0 -> ARRANCANDO	b'00000000'
; 1 -> OPERACIONAL	b'00000001'
; 2 -> PREOPERACIONAL	b'00000010'
; 4 -> PARADO		b'00000100'


; == define =====================================================
;

#define banco	STATUS,RP0
#define	zero	STATUS,Z
#define led	PORTB,2
#define	carry	STATUS,C

; == include =====================================================
;

nmtCode	CODE

#include<p16f873.inc>
#include<spi.h>
#include<isr.h>
#include<eeprom.h>
#include<ext.h>
#include<pdo.h>

; == Macros, Subrutinas y Codigo ====================================
;

;== Macros ==============================================

nmtFiltroSdo	macro
	movf	nmtNodeId, w
	movwf	nmtTemp1
	rrf	nmtTemp1, f
	rrf	nmtTemp2, f
	rrf	nmtTemp1, f
	rrf	nmtTemp2, f
	rrf	nmtTemp1, w
	rrf	nmtTemp2, f
	andlw	b'00001111'
	iorlw	b'11000000'
	movwf	nmtTemp1
	spiEscribirF	RXF1SIDH,nmtTemp1
	movf	nmtTemp2, w
	andlw   b'11100000'
	movwf	nmtTemp2
	spiEscribirF	RXF1SIDL,nmtTemp2

	endm

; == subrutinas =========================================

;<<<< nmtInicio >>>>

nmtInicio
	;inicializar puertos para el led
	bsf	banco
	bcf	TRISB,2		
	bcf	banco
	
	;inicializar modulo SPI
	spiInicModulo

	;resetear el MCP2510
	spiReset

	;configurar pines /RX0BF y /RX1BF como salidas digitales
	spiModBit	BFPCTRL, b'00001111', b'00001100'

	;configurar pines /TX0RTS, /TX1RTS y /TX2RTS como entradas digitales
	spiModBit	TXRTSCTRL,b'00000111', 0x00

	;leer switches
	call	nmtLeerSwitches

	;extraer el Node_ID
	call	nmtFormarNodeId

	;cambiar la frecuencia del reloj en funcion de los switches
	; bit 7 de nmtSwitches == 0 -> 4 MHz
	;			  1 -> 8 MHz
	btfss	nmtSwitches, 7
	goto	nmtI1
	spiModBit	CANCTRL, b'00000011', b'00000001'	; 8 MHz
	goto	nmtI2
nmtI1	spiModBit	CANCTRL, b'00000011', b'00000010'	; 4 MHz
nmtI2

	;escribir los registros CNFx
	movf	nmtSwitches, w		;obtener los tres bit que
	andlw	b'01110000'		; codifican la velocidad
	movwf	nmtTemp1		; del bus CAN
		
	bcf	carry			;dejarlos a la derecha
	rrf	nmtTemp1, f		
	rrf	nmtTemp1, f
	rrf	nmtTemp1, f
	rrf	nmtTemp1, f		
	
	movf	nmtTemp1, w		;obtener valor de CNF1
	call	nmtCNF1
	movwf	nmtTemp2		;y escribirlo en CNF1
	spiEscribirF	CNF1, nmtTemp2

	movf	nmtTemp1, w		;obtener valor de CNF2
	call	nmtCNF2
	movwf	nmtTemp2		;y escribirlo en CNF2
	spiEscribirF	CNF2, nmtTemp2

	movf	nmtTemp1, w		;obtener valor de CNF3
	call	nmtCNF3
	movwf	nmtTemp2		;y escribirlo en CNF3
	spiEscribirF	CNF3, nmtTemp2

	;inhabilitar interrupciones por el momento
	spiEscribir	CANINTE, 0x00	

	;mascara 0 ( NMT, SDO y SYNC)
	spiEscribir	RXM0SIDH,b'11101111'	;todos los bits excepto el 7
	spiEscribir	RXM0SIDL,b'11100000'	; significativos
	
	;mascara 1 ( PDOs)
	spiEscribir	RXM1SIDH,0xff	;todos los bits significativos
	spiEscribir	RXM1SIDL,0xe0	

	;filtro 0 ( NMT y SYNC -> ID: b'000x0000000')
	spiEscribir	RXF0SIDH,0x00
	spiEscribir	RXF0SIDL,0x00
	
	;filtro 1 ( SDO recepcion -> ID: nmtNodeId) 
	movf	nmtNodeId, w
	movwf	nmtTemp1
	bcf	carry
	rrf	nmtTemp1, f
	rrf	nmtTemp2, f
	rrf	nmtTemp1, f
	rrf	nmtTemp2, f
	rrf	nmtTemp1, w
	rrf	nmtTemp2, f
	andlw	b'00001111'
	iorlw	b'11000000'
	movwf	nmtTemp1
	spiEscribirF	RXF1SIDH,nmtTemp1
	movf	nmtTemp2, w
	andlw   b'11100000'
	movwf	nmtTemp2
	spiEscribirF	RXF1SIDL,nmtTemp2

	;tx buffer 0 (SDO TX)
	spiLeer	RXF1SIDH
	andlw	0x0f
	iorlw	b'10110000'
	movwf	nmtTemp1
	spiEscribirF	TXB0SIDH, nmtTemp1
	spiLeer	RXF1SIDL
	andlw	0xe0
	movwf	nmtTemp2
	spiEscribirF	TXB0SIDL, nmtTemp2

	;filtros y txbuffer de los PDO
	bsf	STATUS,RP0	;banco 3
	bsf	STATUS,RP1	;
	bcf	EECON1,EEPGD	;acceder a los datos 
	bcf	STATUS,RP1	;banco 0
	bcf	STATUS,RP0	;
	
	call	nmtFiltro2
	call	nmtFiltro3
	call	nmtFiltro4TxBuffer1
	call	nmtFiltro5TxBuffer2

	;habilitar interrupciones a la llegada de mensajes
	spiEscribir	CANINTE, 0x03

	;pasar el MCP a modo normal
	call	nmtMcpNormal

	;habilitar la interrupcion RB0 en el flanco descendente
	bsf	banco
	bcf	OPTION_REG,INTEDG
	bcf	banco

	bsf	INTCON,INTE
	bsf	INTCON,GIE

	;salir
	return

	GLOBAL nmtInicio


;<<<< nmtCNF1 >>>>

nmtCNF1	
	movlw	high(nmtCNF1)
	movwf	PCLATH
	movf	nmtTemp1, w
	addwf	PCL, f
	
	retlw	0x00	; 1000 Kb/s
	retlw	0x00	; 800
	retlw	0x00	; 500
	retlw	0x01	; 250
	retlw	0x03	; 125
	retlw	0x07	; 50
	retlw	0x0f	; 20
	retlw	0x1f	; 10 Kb/s

;<<<< nmtCNF2 >>>>

nmtCNF2
	movlw	high(nmtCNF2)
	movwf	PCLATH
	movf	nmtTemp1, w
	addwf	PCL, f
	
	retlw	0x90
	retlw	0xa1
	retlw	0xb8
	retlw	0xb8
	retlw	0xb8
	retlw	0xba
	retlw	0xbf
	retlw	0xbf

;<<<< nmtCNF3 >>>>

nmtCNF3
	movlw	high(nmtCNF3)
	movwf	PCLATH
	movf	nmtTemp1, w
	addwf	PCL, f
	
	retlw	0x02
	retlw	0x01
	retlw	0x05
	retlw	0x05
	retlw	0x05
	retlw	0x07
	retlw	0x07
	retlw	0x07
	
;<<<< nmtLeerSwitches >>>>
; lo llama nmtInicio

nmtLeerSwitches
	;PSC a uno
	spiModBit	BFPCTRL, b'00100000', b'00100000'
		
	;flanco _/ en CLK
	spiModBit	BFPCTRL, b'00010000', 0x00
	spiModBit	BFPCTRL, b'00010000', 0xff
	
	;PSC a cero
	spiModBit	BFPCTRL, b'00100000', 0x00
	
	;inicializar bucle
	movlw	8
	movwf	nmtTemp2

leerS1	;leer estado del switch 
	spiLeer	TXRTSCTRL
	movwf	nmtTemp1

	;pasar el bit a 'lectura'+
	rlf	nmtTemp1, f
	rlf	nmtTemp1, f
	rlf	nmtTemp1, f	; bit en carry
	rlf	nmtSwitches, f

	;flanco _/ en CLK
	spiModBit	BFPCTRL, b'00010000', 0x00
	spiModBit	BFPCTRL, b'00010000', 0xff

	;control del bucle
	decf	nmtTemp2, f
	btfss	zero
	goto	leerS1
	
	;complementar la lectura
	comf	nmtSwitches, f
	
	return

;<<<< nmtMcpConfiguracion >>>>
; Pasar el MCP2510 al estado de configuracion
; (para modificar mascaras y filtros)
	
nmtMcpConfiguracion
	spiModBit	CANCTRL, b'11100000', b'10000000'	

nmtMC1	spiLeer	CANSTAT		;esperar a que el MCP entre en el modo conf.
	andlw	b'11100000'	
	sublw	b'10000000'
	btfss	zero
	goto	nmtMC1

	return

	GLOBAL	nmtMcpConfiguracion

;<<<< nmtMcpNormal >>>>
; Pasar el MCP2510 al estado de funcionamiento normal
	
nmtMcpNormal
	spiModBit	CANCTRL, b'11100000', 0x00	

nmtMN1	spiLeer CANSTAT		;esperar a que el MCP entre en el modo normal
	andlw	b'11100000'	
	btfss	zero
	goto	nmtMN1

	return

	GLOBAL	nmtMcpNormal	

;<<<< nmtDelayLed >>>>
;lo llama nmtPreoperacional

nmtDelayLed
	;inicializar contadores
	movlw	0xff		; a 8 Mhz
	btfss	nmtSwitches, 7	; reloj a 8Mhz saltar siguiente instruccion
	movlw	0x7f		; a 4 Mhz
	movwf	nmtTemp2
	clrf	nmtTemp1
	
nmtDL1	decf	nmtTemp1, f
	btfss	zero
	goto	nmtDL1
nmtDL2	decf	nmtTemp2, f
	btfss	zero
	goto	nmtDL1

	return

;<<<< nmtFormarNodeId >>>>
; a partir de nmtSwitches extrae el numero
; de nodo y lo deja en nmtNodeId

nmtFormarNodeId
	movf	nmtSwitches, w
	andlw	0x0f
	iorlw	b'00010000'
	movwf	nmtNodeId

	return

;<<<< nmtFiltro2 >>>>

nmtFiltro2
	;filtro 2 (PDO recepcion 1 -> ID: en eeprom 0x00 y 0x01)
	eepromLeer	eepromPdo1IDH
	movwf	nmtTemp1
	spiEscribirF	RXF2SIDH,nmtTemp1
	eepromLeer	eepromPdo1IDL
	andlw	b'11100000'
	movwf	nmtTemp1
	spiEscribirF	RXF2SIDL,nmtTemp1
	return	

;<<<< nmtFiltro3 >>>>

nmtFiltro3
	;filtro 3 (PDO recepcion 2 )
	eepromLeer	eepromPdo2IDH
	movwf	nmtTemp1
	spiEscribirF	RXF3SIDH,nmtTemp1
	eepromLeer	eepromPdo2IDL
	andlw	b'11100000'
	movwf	nmtTemp1
	spiEscribirF	RXF3SIDL,nmtTemp1	
	return

;<<<< nmtFiltro4TxBuffer1 >>>>

nmtFiltro4TxBuffer1
	;filtro_4 y tx_buffer_1 (PDO transmision 1 )
	eepromLeer	eepromPdo3IDH
	movwf	nmtTemp1
	spiEscribirF	RXF4SIDH,nmtTemp1
	spiEscribirF	TXB1SIDH, nmtTemp1
	eepromLeer	eepromPdo3IDL
	andlw	b'11100000'
	movwf	nmtTemp1
	spiEscribirF	RXF4SIDL,nmtTemp1
	spiEscribirF	TXB1SIDL,nmtTemp1
	return

;<<<< nmtFiltro5TxBuffer2 >>>>

nmtFiltro5TxBuffer2	
	;filtro_5 y tx_buffer_2 (PDO transmision 2 )
	eepromLeer	eepromPdo4IDH
	movwf	nmtTemp1
	spiEscribirF	RXF5SIDH,nmtTemp1
	spiEscribirF	TXB2SIDH,nmtTemp1
	eepromLeer	eepromPdo4IDL
	andlw	b'11100000'
	movwf	nmtTemp1
	spiEscribirF	RXF5SIDL,nmtTemp1
	spiEscribirF	TXB2SIDL,nmtTemp1	
	return

	GLOBAL	nmtFiltro2, nmtFiltro3, nmtFiltro4TxBuffer1, nmtFiltro5TxBuffer2

;<<<< nmtVALIDRTR >>>>

nmtVALIDRTR
	eepromLeer	eepromVALIDRTR
	movwf	pdoVALIDRTR
	return
	
	GLOBAL	nmtVALIDRTR

; == codigo ===============================================

;<<<< nmtEntrada >>>>

nmtEntrada
	;comprobar que se refiere a este nodo
	;-todos los nodos
	movf	spiBufD1, f
	btfsc	zero		
	goto	nmtEntr1	; Node_ID = 0 -> continuar
	
	;-este en concreto
	movf	nmtNodeId, w
	subwf	spiBufD1, w
	btfsc	zero
	goto	nmtEntr1

	;no se refiere a este nodo -> no hacer nada
	movlw	high(isrFin)
	movwf	PCLATH
	goto	isrFin

nmtEntr1
	;en funcion del comando...
	
	;- Reset_Application
	movlw	0x81
	subwf	spiBufD0, w
	btfsc	zero
	goto	nmtResetAplicacion

	;- Reset_Communication
	movlw	0x82
	subwf	spiBufD0, w
	btfsc	zero
	goto	nmtResetComunicaciones
	
	;- Enter_PreOperational_Mode
	movlw	0x80
	subwf	spiBufD0, w
	btfsc	zero
	goto	nmtPreOperacional

	;- Start_Remote_Node
	movlw	0x01
	subwf	spiBufD0, w
	btfsc	zero
	goto	nmtOperacional

	;- Stop_Remote_Node
	movlw	0x02
	subwf	spiBufD0, w
	btfsc	zero
	goto	nmtParado
	
	;- Comando desconocido (no hacer nada)
	movlw	high(isrFin)
	movwf	PCLATH
	goto	isrFin

	GLOBAL	nmtEntrada

;<<<< nmtResetAplicacion >>>>

nmtResetAplicacion
	;reinicializar la aplicacion
	movlw	high(appVectores)
	movwf	PCLATH
	btfss	nmtEstado, 0		; si estado = OPERACIONAL -> appParar
	call	(appVectores + 9)	; appParar
	;entrar nuevo modo
	clrf	nmtEstado

	call	(appVectores + 0)	; appReset

	;reinicializar las comunicaciones y entrar estado preoperacional
	movlw	high(nmtResetComunicaciones)
	movwf	PCLATH
	goto	nmtResetComunicaciones


;<<<< nmtResetComunicaciones >>>>

nmtResetComunicaciones
	;parar la aplicacion si hace falta
	btfss	nmtEstado, 0		; si estado = OPERACIONAL -> appParar
	call	(appVectores + 9)	; appParar
	;entrar nuevo modo
	clrf	nmtEstado

	;restaurar valores por defecto de los ID de los PDO, 
	;y del mapeo de objetos en éstos
	
	;-contador del bucle y puntero a la tabla en ROM
	clrf	nmtTemp1
	
	;-inicializar bucle
	movlw	high(appVectores)
	movwf	PCLATH
	movf	nmtTemp1, w
	call	(appVectores + 3)	; appPdoTablaPorDefecto
	movwf	nmtTemp2
	eepromEscribirF	0x00, nmtTemp2
	incf	nmtTemp1, f

	;restaurar PCLATH
	movlw	high(nmtRC1)
	movwf	PCLATH

	;-bucle
nmtRC1	movlw	high(appVectores)
	movwf	PCLATH
	movf	nmtTemp1, w
	call	(appVectores + 3)	; appPdoTablaPorDefecto
	movwf	nmtTemp2
	eepromEscribirSF nmtTemp2
	incf	nmtTemp1, f

	;restaurar PCLATH
	movlw	high(nmtRC1)
	movwf	PCLATH

	;-control del bucle
	movlw	(d'48' + 1)
	subwf	nmtTemp1, w	; cada PDO 12 bytes -> 4 PDOs 48 bytes:0..47
	btfss	zero		; más 1 del VALIDRTR		      :48	
	goto	nmtRC1	

	;ID de los PDO modificados por los switches
	call	nmtLeerSwitches
	call	nmtFormarNodeId

	;- los 3 bits del NodeID de menos peso en los eepromPdoxIDL
	movf	nmtNodeId, w
	movwf	nmtTemp1
	bcf	carry
	clrf	nmtTemp2
	rrf	nmtTemp1, f
	rrf	nmtTemp2, f
	rrf	nmtTemp1, f
	rrf	nmtTemp2, f
	rrf	nmtTemp1, f
	rrf	nmtTemp2, f
	eepromEscribirF	eepromPdo1IDL, nmtTemp2
	eepromEscribirF	eepromPdo2IDL, nmtTemp2
	eepromEscribirF	eepromPdo3IDL, nmtTemp2
	eepromEscribirF	eepromPdo4IDL, nmtTemp2

	;- modificar los IDH de los PDOs	
	eepromLeer	eepromPdo1IDH
	iorwf	nmtTemp1, w
	movwf	nmtTemp2
	eepromEscribirF	eepromPdo1IDH, nmtTemp2

	eepromLeer	eepromPdo2IDH
	iorwf	nmtTemp1, w
	movwf	nmtTemp2
	eepromEscribirF	eepromPdo2IDH, nmtTemp2

	eepromLeer	eepromPdo3IDH
	iorwf	nmtTemp1, w
	movwf	nmtTemp2
	eepromEscribirF	eepromPdo3IDH, nmtTemp2

	eepromLeer	eepromPdo4IDH
	iorwf	nmtTemp1, w
	movwf	nmtTemp2
	eepromEscribirF	eepromPdo4IDH, nmtTemp2

	;actualizar registros del MCP
	call	nmtInicio

	;entrar estado preoperacional
	goto	nmtPreOperacional

;<<<< nmtPreOperacional >>>>

nmtPreOperacional
	;actualizar nmtEstado
	movlw	2
	movwf	nmtEstado
	
	;inicializar TXB0 con ID del mensaje EMERGENCY
	spiLeer	RXF1SIDL
	andlw	0xe0
	movwf	nmtTemp1
	spiEscribirF	TXB0SIDL, nmtTemp1

	spiLeer	RXF1SIDH
	andlw	0x0f
	iorlw	b'00010000'
	movwf	nmtTemp1
	spiEscribirF	TXB0SIDH, nmtTemp1
	
	;enviar mensaje Boot_Up
	spiEscribir	TXB0DLC, 0
	spiRts	1

	;esperar a que se envie el mensaje antes de 
	; tratar de modificar el buffer de tx

	call	nmtDelayLed

nmtPre2	;leer estado buffer tx
	spiLeer	TXB0CTRL
	movwf	nmtTemp2
	btfsc	nmtTemp2, TXREQ
	goto	nmtPre2

	;inicializar TXB0 con ID del SDO_Server
	spiLeer	TXB0SIDH
	andlw	0x0f
	iorlw	b'10110000'
	movwf	nmtTemp1
	spiEscribirF	TXB0SIDH, nmtTemp1

	;llamada a appParar
	movlw	high(appVectores)
	movwf	PCLATH
	call	(appVectores + 9)	; appParar
	movlw	high(nmtPreOperacional)
	movwf	PCLATH

	;habilitar las interrupciones (para recibir mensajes)
	bsf	INTCON, GIE

	; el LED parpadea
nmtPre1	;encender led
	bsf	led
	call	nmtDelayLed
	;apagar led
	bcf	led	
	call	nmtDelayLed
	;bucle infinito
	goto	nmtPre1

	GLOBAL nmtPreOperacional


;<<<< nmtOperacional >>>>

nmtOperacional
	;comprobar que el programa está cargado
	eepromLeer eepromProgramFlag
	xorlw	0x01	
	btfss	zero	; si zero==1 => todo bien
	;eepromEscribir eepromErrorRegister
	goto	nmtPreOperacional
	
	;encender el led
	bsf	led

	;actualizar nmtEstado
	movlw	1
	movwf 	nmtEstado

	;actualizar pdoVALIDRTR
	call	nmtVALIDRTR

	;Inicializar PDOs
	movlw	high(pdoInicio)
	movwf	PCLATH
	call	pdoInicio
	call	pdoPrioridadTx

	;habilitar las interrupciones (para recibir mensajes)
	bsf	INTCON, GIE
	
	;entrar en el programa de aplicacion
	movlw	high(appVectores)
	movwf	PCLATH
	goto	(appVectores + 2)		; appEntrada

;<<<< nmtParado >>>>

nmtParado
	;actualizar nmtEstado
	movlw	4
	movwf	nmtEstado

	;llamada a appParar
	movlw	high(appVectores)
	movwf	PCLATH
	call	(appVectores + 9)	; appParar
	movlw	high(nmtParado)
	movwf	PCLATH

	;habilitar las interrupciones (para recibir mensajes)
	bsf	INTCON, GIE

nmtPar1	;apagar el led
	bsf	led
	goto	nmtPar1

	END
