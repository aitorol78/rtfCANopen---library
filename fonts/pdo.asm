; PDO.ASM

; rutinas que se encargan de procesar los PDOs
;
; este archivo, pdo.asm, hay que añadirlo al proyecto
; el archivo pdo.h hay que incluirlo en los archivos que hagan
; referencia a rutinas o variables pdoXXX

; Aitor Olarra
; 27-7-00
; modificado el 16-8-00
; modificado el 10-10-00

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

; == variables ======================================================

pdoData	UDATA	
	pdoTemp1	res 1
	pdoTemp2	res 1
	pdoTipoTx1	res 1
	pdoTipoTx2	res 1
	pdoContSync1	res 1
	pdoContSync2	res 1
	pdoNumBytes	res 1
	pdoVALIDRTR	res 1
	pdoFlags	res 1
	pdoSdoObjeto	res 1	;backup de sdoObjeto

	GLOBAL pdoContSync1, pdoContSync2, pdoNumBytes, pdoVALIDRTR, pdoFlags
	GLOBAL pdoTipoTx1, pdoTipoTx2

;pdoVALIDRTR
; bit 0 -> a cero => RTR permitido sobre el PDO1
; bit 1 -> a cero => RTR permitido sobre el PDO2
; bit 2 -> a cero => RTR permitido sobre el PDO3
; bit 3 -> a cero => RTR permitido sobre el PDO4
; bit 4 -> a cero => PDO1 es valido
; bit 5 -> a cero => PDO2 es valido
; bit 6 -> a cero => PDO3 es valido
; bit 7 -> a cero => PDO4 es valido

;pdoFlags
; bit 0 -> Enviar PDO. Las rutinas appObjetoXX lo ponen a uno cuando el 
;	                objeto a cambiado desde la ultima vez que fueron 
;	                invocadas.
; bit 1 -> Enviar mensaje del buffer de tx 1 -> PDO TX 1
; bit 2 -> Enviar mensaje del buffer de tx 2 -> PDO TX 2


; == Define ===============================================

#define zero	STATUS,Z
#define carry	STATUS,C
#define banco	STATUS,RP0

; == Include ===============================================

pdoCode	CODE

#include<p16f873.inc>
#include<spi.h>
#include<isr.h>
#include<eeprom.h>
#include<ext.h>
#include<sdo.h>

; == subrutinas =============================================

;<<<< pdoInicio >>>>

pdoInicio
	;actualizar pdoContSync1 y pdoContSync2
	eepromLeer	eepromPdo3TxType
	movwf	pdoTipoTx1
	movwf	pdoContSync1
	eepromLeer	eepromPdo4TxType
	movwf	pdoTipoTx2
	movwf	pdoContSync2
	return

	GLOBAL	pdoInicio

;<<<< pdoPrioridadTx >>>>
;compara los ID de los PDO de tx y al buffer que corresponde al 
; menor de ellos le asigna una prioridad b'10' (media alta),
; mientras que al otro le asigna b'01' (media baja).

pdoPrioridadTx
	eepromLeer	eepromPdo3IDH
	movwf	pdoTemp1
	eepromLeer	eepromPdo4IDH
	subwf	pdoTemp1, w
	
	btfsc	zero		
	goto	pdoPrioridadTx1		;IDH iguales
	goto	pdoPrioridadTx2

pdoPrioridadTx1
	eepromLeer	eepromPdo3IDL
	movwf	pdoTemp1
	eepromLeer	eepromPdo4IDL
	subwf	pdoTemp1, w

pdoPrioridadTx2
	; carry = 0 -> ID del PDO3 es menor
	movlw	b'00000001'	; el de menor prioridad
	btfss	carry
	movlw	b'00000010'	; el de mayor prioridad
	
	movwf	pdoTemp1
	xorlw	b'00000011'
	movwf	pdoTemp2

	spiModBitF TXB1CTRL, 0x03, pdoTemp1
	spiModBitF TXB2CTRL, 0x03, pdoTemp2
	return
	
	GLOBAL pdoPrioridadTx

;<<<< pdoFormarMensaje >>>>
;inicializa a 0 el flag pdoFlags<0> y
;mapea los objetos que correspondan al PDO

pdoFormarMensaje
	;flag de peticion de envio a 0
	bcf	pdoFlags,0
	;inicializar puntero a spiBuf
	movlw	spiBufD0
	movwf	FSR
	;flags (PDO tx)
	bcf	sdoEstado, 2
	bcf	sdoEstado, 3
	
	eepromLeerS
	movwf	sdoObjeto
pdoFM1	;¿ era el anterior el ultimo objeto mapeado ?
	incf	sdoObjeto, w
	btfsc	zero			
	goto 	pdoFM2		; si -> fin
				; no -> sigue adelante
	goto	pdoSaltoAObjetos
	
pdoTxFin
	eepromLeerS		; incrementar puntero a EEPROM y leer
	movwf	sdoObjeto
	goto	pdoFM1

pdoFM2	;actualizar pdoNumBytes
	movlw	spiBufD0
	subwf	FSR,w
	movwf	pdoNumBytes

	return

	GLOBAL pdoTxFin

;<<<< pdoEsperarTx1 >>>>
;espera hasta que se envia el mensaje del buffer de tx1 
; para modificarlo a continuacion

pdoEsperarTx1
	;leer estado buffer tx
	spiLeer	TXB1CTRL
	movwf	pdoTemp1
	btfsc	pdoTemp1, TXREQ
	goto	pdoEsperarTx1
	return

; == codigo =================================================

;<<<< pdoRx1 y pdoRx2 >>>>

pdoRx1	;salvar sdoObjeto
	movf	sdoObjeto,w
	movwf	pdoSdoObjeto
		
	;inicializar el puntero a spiBuf
	movlw	spiBufD0
	movwf	FSR
	;flags (PDO rx)
	bsf	sdoEstado, 2
	bcf	sdoEstado, 3
	;inicializar parte alta del PC
	movlw	high(pdoRx12)
	movwf	PCLATH
	;obtener los objetos que estan mapeados en este PDO
	eepromLeer	eepromPdo1M1
	movwf	sdoObjeto
	;saltar al bucle comun de pdoRx1 y pdoRx2
	goto	pdoRx12

pdoRx2	;salvar sdoObjeto
	movf	sdoObjeto,w
	movwf	pdoSdoObjeto

	;inicializar el puntero a spiBuf
	movlw	spiBufD0
	movwf	FSR
	;flags (PDO rx)
	bsf	sdoEstado, 2
	bcf	sdoEstado, 3
	;inicializar parte alta del PC 
	movlw	high(pdoRx12)
	movwf	PCLATH
	;obtener los objetos que estan mapeados en este PDO
	eepromLeer	eepromPdo2M1
	movwf	sdoObjeto

pdoRx12	;¿ era el anterior el ultimo objeto mapeado (255)?
	incf	sdoObjeto, w
	btfsc	zero			
	goto 	pdoIsrFin	; si -> fin
				; no -> sigue adelante
	goto	pdoSaltoAObjetos

pdoRxFin
	eepromLeerS		; incrementar puntero a EEPROM y leer
	movwf	sdoObjeto
	goto	pdoRx12

	GLOBAL	pdoRxFin

;<<<< pdoTx1 y PdoTx2 >>>>

pdoTx1	;salvar sdoObjeto
	movf	sdoObjeto,w
	movwf	pdoSdoObjeto

	;apuntar al primer objeto que esta mapeado en este PDO
	eepromPuntero	(eepromPdo3M1 - 1)
	;formar mensaje
	call	pdoFormarMensaje
	
	;volcar el buffer al MCP y enviarlo
	spiEscribirBuffer	TXB1DLC
	spiEscribirF	TXB1DLC, pdoNumBytes
	spiRts	b'00000010'
	goto	pdoIsrFin

pdoTx2	;salvar sdoObjeto
	movf	sdoObjeto,w
	movwf	pdoSdoObjeto

	;apuntar al primer objeto que esta mapeado en este PDO
	eepromPuntero	(eepromPdo4M1 - 1)
	;formar mensaje
	call	pdoFormarMensaje
	
	;volcar el buffer al MCP y enviarlo
	spiEscribirBuffer	TXB2DLC
	spiEscribirF	TXB2DLC, pdoNumBytes
	spiRts	b'00000100'
	goto	pdoIsrFin

;<<<< pdoSYNC >>>>

pdoSYNC	
	;salvar sdoObjeto
	movf	sdoObjeto,w
	movwf	pdoSdoObjeto

	;borrar flags
	bcf	pdoFlags, 1
	bcf	pdoFlags, 2

pdoSYNC_PDOTX1
	;es valido este PDO
	btfsc	pdoVALIDRTR, 6
	goto	pdoSYNC_PDOTX2		; no
	
	;formar mensaje y volcarlo al buffer
	eepromPuntero (eepromPdo3M1 - 1)
	call	pdoFormarMensaje

	call	pdoEsperarTx1
	spiEscribirBuffer	TXB1DLC
	spiEscribirF	TXB1DLC, pdoNumBytes

	;determinar tipo de transmision
	;- tipo 0 ??
	movf	pdoTipoTx1, f
	btfss	zero
	goto	pdoSYNC_11 	; no
				; si
	bcf	pdoFlags, 1	
	btfss	pdoFlags, 0	; hay que enviarlo ??
	goto	pdoSYNC_11 	; no
	bsf	pdoFlags, 1	; si

	goto	pdoSYNC_PDOTX2
	
	;- tipo 1..240 ??
pdoSYNC_11
	decf	pdoTipoTx1, w
	sublw	d'240'
	btfss	carry		; carry = 1 -> se envia tras x SYNCs
				;         0 -> tipo tx no es 1..240
	goto	pdoSYNC_PDOTX2

	decf	pdoContSync1, f ; decrementar contador de SYNC
	btfss	zero		; zero = 1 -> toca enviar mensaje
	goto	pdoSYNC_PDOTX2	;        0 -> no ...

	bsf	pdoFlags, 1
	movf	pdoTipoTx1, w	; inicializar contador de SYNCs
	movwf	pdoContSync1

pdoSYNC_PDOTX2
	;es valido este PDO
	btfsc	pdoVALIDRTR, 7
	goto	pdoSYNC_FIN		; no

	;formar mensaje y volcarlo al buffer
	eepromPuntero (eepromPdo4M1 - 1)
	call	pdoFormarMensaje
	spiEscribirBuffer	TXB2DLC
	spiEscribirF	TXB2DLC, pdoNumBytes

	;determinar tipo de transmision
	;- tipo 0 ??
	movf	pdoTipoTx2, f
	btfss	zero
	goto	pdoSYNC_21 	; no
				; si
	bcf	pdoFlags, 2	
	btfss	pdoFlags, 0	; hay que enviarlo ??
	goto	pdoSYNC_21 	; no
	bsf	pdoFlags, 2	; si

	goto	pdoSYNC_FIN

	;- tipo 1..240 ??
pdoSYNC_21
	decf	pdoTipoTx2, w
	sublw	d'240'
	btfss	carry		; carry = 1 -> se envia tras x SYNCs
				;         0 -> tipo tx no es 1..240
	goto	pdoSYNC_FIN

	decf	pdoContSync2, f ; decrementar contador de SYNC
	btfss	zero		; zero = 1 -> toca enviar mensaje
	goto	pdoSYNC_FIN	;        0 -> no ...

	bsf	pdoFlags, 2	; poner flag a 1
	movf	pdoTipoTx2, w	; inicializar contador de SYNCs
	movwf	pdoContSync2
	
pdoSYNC_FIN
	;enviar PDOs respetando prioridad
	movlw	b'00000110'	
	andwf	pdoFlags
	spiRtsF	pdoFlags
		
	; fin del tratamiento del SYNC
	goto	pdoIsrFin
	
;<<<< pdoSaltoAObjetos >>>>

pdoSaltoAObjetos
	movlw	high(appVectores)
	movwf	PCLATH
	
	;el primer objeto en appVectores tiene un offset de 12
	movlw	d'12'
	addwf	sdoObjeto, w

	;pero apunta al objeto numeroObjetosSistema
	addlw	(0xff - numeroObjetosSistema + 0x01)

	;ya tenemos el offset correcto a partir de appVectores
	; y saltamos
	movwf	PCL

;<<<< pdoIsrFin >>>>

pdoIsrFin
	;restaurar sdoObjeto
	movf	pdoSdoObjeto,w
	movwf	sdoObjeto

	movlw	high(isrFin)
	movwf	PCLATH
	goto	isrFin
	
	GLOBAL 	pdoRx1, pdoRx2, pdoTx1, pdoTx2, pdoSYNC, pdoSaltoAObjetos

	END
