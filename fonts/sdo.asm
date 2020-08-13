; SDO.ASM 

; Manejo de los sdo
;
; este archivo, sdo.asm, hay que añadirlo al proyecto
; el archivo sdo.h hay que incluirlo en los archivos que hagan
; referencia a rutinas sdoXXX

; Aitor Olarra
; 30-7-00 y 9-8-00
; 2-10-00 los sdoSubirXXX, sdoBajarXXX
; 24-10-00 unificar sdoSubir y sdoBajar

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

; == include y define =====================================================
;

#include<p16f873.inc>
#include<spi.h>
#include<isr.h>
#include<ext.h>
#include<eeprom.h>
#include<pdo.h>
#include<nmt.h>

#define banco	STATUS,RP0
#define	zero	STATUS,Z
#define	carry	STATUS,C
#define toggle	sdoEstado,6
#define SDO_PDO	sdoEstado,3
#define rx_tx	sdoEstado,2
#define bajar_subir	sdoEstado,2 

#define numeroObjetosSistema	0x1f ; (31 en decimal)

; == variables ============================================================
;

sdoData	UDATA
sdoEstado   res 1
sdoObjeto   res 1
sdoPuntero  res 1
sdoNumBytes res 1
sdoBuffer   res 0x15	; 0x15 = 21 = 3*7
sdoSubIndex res 1
sdoTemp1    res 1
sdoTemp2    res 1
sdoTemp3    res 1

	GLOBAL	sdoObjeto, sdoBuffer, sdoEstado, sdoSubIndex, sdoNumBytes

;Significado de sdoEstado
;-bit<7> 	=> 0 se llama a sdoBajar tras una bajada expedita
; 	    	   1                                     no expedita
;-bit<6>	=> valor del bit 'toggle' que se espera    
;-bits<0..1>	=> 0 estado actual ENTRANDO
;		   1		   SUBIENDO	
;		   2               BAJANDO
;                  3 (no utilizado)
;-bits<2..3>	=> 0 PDO tx
;		   1 PDO rx
;		   2 SDO subir
;		   3 SDO bajar
;-resto bits 	=> (no utilizado)

;== subrutinas ===========================================================

sdoCode	CODE

sdoInicio
	; estado = ENTRANDO
	clrf	sdoEstado
	return

	GLOBAL	sdoInicio

;== codigo ===============================================================
;

;<<<< sdoEntrada >>>>
;

sdoEntrada
	; ¿ estado actual == ENTRANDO | SUBIENDO | BAJANDO ?
	movlw	high(sdoEntrada)
	movwf	PCLATH
	movf	sdoEstado, w
	andlw	0x03
	addwf	PCL, f
	goto	sdoEntrando	; ENTRANDO = 0
	goto	sdoSubiendo	; SUBIENDO = 1
	goto	sdoBajando	; BAJANDO  = 2
	nop			; 3 no es nada y no deberia aparecer

	GLOBAL sdoEntrada

;<<<< sdoEntrando >>>>

sdoEntrando
	;buscar objeto en tabla (en funcion del Index/SubIndex)	
		
	;inicializar sdoObjeto
	clrf	sdoObjeto
	goto	sdoE2		; para evitar 'apuntar al siguiente objeto'
				; la primera vez

sdoE1	;apuntar al siguiente objeto 
	incf	sdoObjeto, f

	;comprobar que el anterior no ha sido el último
	movlw	high(appVectores)
	movwf	PCLATH
	call	(appVectores + 8)	; appNumeroObjetos (definidos en la aplicacion)
	addlw	numeroObjetosSistema
	subwf	sdoObjeto, w
	movlw	high(sdoEntrando)
	movwf	PCLATH
	btfss	carry
	goto	sdoE2		; todavía quedan objetos
	
	;objeto no existe -> entrar codigos de error y enviar
	; un 'Abort SDO Segment'
	movlw	6
	movwf	spiBufD7
	movlw	2	
	movwf	spiBufD6
	clrf	spiBufD5
	clrf	spiBufD4
	goto	sdoAbortar
		
sdoE2	;obtener IndexHigh de sdoObjeto y comparar
	movlw	high(appSdoTablaIndexHigh)
	movwf	PCLATH
	call	appSdoTablaIndexHigh
	subwf	spiBufD2, w
	movlw	high(sdoE1)
	movwf	PCLATH
	btfss	zero		; coinciden??
	goto	sdoE1		; no
				; si
	;obtener IndexLow de sdoObjeto y comparar
	movlw	high(appSdoTablaIndexLow)
	movwf	PCLATH
	call	appSdoTablaIndexLow
	subwf	spiBufD1, w
	movlw	high(sdoE1)
	movwf	PCLATH
	btfss	zero		; coinciden??
	goto	sdoE1		; no
				; si
	;obtener SubIndex de sdoObjeto y comparar
	movlw	high(appSdoTablaSubIndex)
	movwf	PCLATH
	call	appSdoTablaSubIndex	
	movwf	sdoTemp1
	subwf	spiBufD3, w
	movlw	high(sdoE1)
	movwf	PCLATH
	btfsc	zero		; coinciden??
	goto	sdoE3		; si
				; no

	btfss	sdoTemp1, 7	; admite multiples subindices??
	goto	sdoE1		; no
				; si
	bcf	sdoTemp1, 7	
	movf	spiBufD3, w
	subwf	sdoTemp1, w
	btfss	carry		; admite hasta el subindice solicitado??
	goto	sdoE1		; no
				; si

	movf	spiBufD3, w	; actualizar sdoSubIndex
	movwf	sdoSubIndex
sdoE3
	; (tenemos el numero de objeto)
	; ¿ comando == IniciarSubida | IniciarBajada ?
	
	; probar Iniciar subida
	movf	spiBufD0,w
	andlw	0xe0
	sublw	0x40
	btfsc	zero
	goto	sdoIniciarSubida
	
	; probar Iniciar bajada
	movf	spiBufD0,w
	andlw	0xe0
	sublw	0x20
	btfsc	zero
	goto	sdoIniciarBajada

	;comando incorrecto -> entrar codigos de error y enviar 
	; mensaje 'Abort SDO Segment' 
	movlw	5
	movwf	spiBufD7
	movlw	4
	movwf	spiBufD6
	clrf	spiBufD5
	movlw	1
	movwf	spiBufD4
	goto	sdoAbortar

;<<<< sdoIniciarSubida >>>>

sdoIniciarSubida
	;enviar confirmacion y numero de bytes
	movlw	b'01000001'
	movwf	spiBufD0

	movlw	high(appSdoTablaPropiedades)
	movwf	PCLATH
	call	appSdoTablaPropiedades
	andlw	0x3f
	movwf	spiBufD4		
	movwf	sdoNumBytes		;sdoNumBytes <- numero de bytes

	movlw	high(sdoIniciarSubida)	;restaurar PCLATH
	movwf	PCLATH

	movlw	8
	movwf	spiBufSIDL
	spiEscribirBuffer	TXB0DLC	
	spiRts	1

	;inicializar sdoPuntero
	clrf	sdoPuntero

	;entrar siguiente estado 
	movlw	1		; SUBIENDO = 1
	movwf	sdoEstado

	;'toggle' <- 0 
	bcf	toggle
	
	;preparar sdoBuffer
	; flags (SDO subir)
	bcf	sdoEstado, 2
	bsf	sdoEstado, 3
	goto	sdoSubirObjetos

;<<<< sdoIniciarBajada >>>>

sdoIniciarBajada
	; ¿ se puede escribir este objeto ?
	movlw 	high(appSdoTablaPropiedades)
	movwf	PCLATH
	call	appSdoTablaPropiedades
	andlw	0x80
	movlw	high(sdoIniciarBajada)
	movwf	PCLATH
	btfsc	zero		; Prop = 0  => se puede escribir
	goto	sdoIB1		; seguir adelante

	;no se puede escribir -> entrar codigos de error y enviar
	; mensaje 'Abort SDO Segment'
	movlw	6
	movwf	spiBufD7
	movlw	1
	movwf	spiBufD6
	clrf	spiBufD5
	movlw	2
	movwf	spiBufD4
	goto	sdoAbortar

sdoIB1	; ¿ expedito ?
	btfsc	spiBufD0, 1
	goto	sdoIB2		; si
				; no
	
	; no es expedito:
	; entrar siguiente estado
	movlw	2		; BAJANDO = 2
	movwf	sdoEstado
	
	; salvar numero de bytes si esta indicado
	movf	spiBufD4, w	
	movwf	sdoNumBytes
	btfss	spiBufD0, 0
	clrf	sdoNumBytes

	;inicializar puntero a sdoBuffer	
	clrf	sdoPuntero

	;inicializar bit 'toggle'
	bcf	toggle
	

sdoIB_Fin
	; enviar mensaje de confirmacion y salir
	movlw	b'01100000'	; confirmacion de iniciar bajada
	movwf	spiBufD0
	clrf	spiBufD4
	clrf	spiBufD5
	clrf	spiBufD6
	clrf	spiBufD7
	movlw	8
	movwf	spiBufSIDL
	spiEscribirBuffer TXB0DLC	
	spiRts	1

	goto	sdoIsrFin

sdoIB2	; es expedito: 
	; salvar Buffer
	movf	spiBufD4, w
	movwf	sdoBuffer
	movf	spiBufD5, w
	movwf	sdoBuffer+1
	movf	spiBufD6, w
	movwf	sdoBuffer+2
	movf	spiBufD7, w
	movwf	sdoBuffer+3
	
	; salvar numero de bytes
	rrf	spiBufD0, f
	rrf	spiBufD0, w
	andlw	0x03
	movwf	sdoNumBytes

	;marcar que se llama a sdoObjetoXXX tras una bajada expedita
	bcf	sdoEstado, 7
	
	;volcar sdoBuffer a registros del PIC
	;flags ->(SDO bajar)
	bsf	sdoEstado, 2
	bsf	sdoEstado, 3
	goto	sdoBajarObjetos

;<<<< sdoSubiendo >>>>

sdoSubiendo
	; ¿ comando == SubirSegmento ?
	movf	spiBufD0, w
	andlw	0xe0
	sublw	0x60
	btfsc	zero	
	goto	sdoS1	; si
	
	; ¿ comando == IniciarSubida ?
	movf	spiBufD0, w
	andlw	0xe0
	sublw	0x40
	btfsc	zero	
	goto	sdoS3	; si

	;comando incorrecto -> entrar codigos de error y enviar 
	; mensaje 'Abort SDO Segment' 
	movlw	5
	movwf	spiBufD7
	movlw	4
	movwf	spiBufD6
	clrf	spiBufD5
	movlw	1
	movwf	spiBufD4
	goto	sdoAbortar

sdoS1	;comprobar bit 'toggle'
	clrf	sdoTemp1	;copiar bit 'toggle' a sdoTemp1<4>
	btfsc	toggle
	bsf	sdoTemp1, 4	
	
	movlw	0x10		;quedarnos con el bit 'toggle' del mensaje
	andwf	spiBufD0, w	
	
	xorwf	sdoTemp1	;compararlos
	btfsc	zero		
	goto	sdoS6 		; son iguales 

	;bit 'toggle' incorrecto -> entrar codigos de error y enviar 
	; mensaje 'Abort SDO Segment' 
	movlw	5
	movwf	spiBufD7
	movlw	3
	movwf	spiBufD6
	clrf	spiBufD5
	clrf	spiBufD4
	goto	sdoAbortar

sdoS6	;actualizar bit 'toggle' para el siguiente segmento
	movlw	b'01000000'
	xorwf	sdoEstado, f
	
	;inicializar FSR
	movf	sdoPuntero, w
	addlw	sdoBuffer	
	movwf	FSR		; FSR = Base(sdoBuffer) + Despl(sdoPuntero)
	bcf	STATUS, IRP	; bancos 0 y 1 
	
	;formar mensaje
	movf	INDF, w		; leer sdoBuffer.sdoPuntero
	movwf	spiBufD1	; dejarlo en spiBufXXX
	incf	FSR, f		; apuntar al siguiente byte
	movf	INDF, w		; leer sdoBuffer.sdoPuntero
	movwf	spiBufD2	; dejarlo en spiBufXXX
	incf	FSR, f		; apuntar al siguiente byte
	movf	INDF, w		; leer sdoBuffer.sdoPuntero
	movwf	spiBufD3	; dejarlo en spiBufXXX
	incf	FSR, f		; apuntar al siguiente byte
	movf	INDF, w		; leer sdoBuffer.sdoPuntero
	movwf	spiBufD4	; dejarlo en spiBufXXX
	incf	FSR, f		; apuntar al siguiente byte
	movf	INDF, w		; leer sdoBuffer.sdoPuntero
	movwf	spiBufD5	; dejarlo en spiBufXXX
	incf	FSR, f		; apuntar al siguiente byte
	movf	INDF, w		; leer sdoBuffer.sdoPuntero
	movwf	spiBufD6	; dejarlo en spiBufXXX
	incf	FSR, f		; apuntar al siguiente byte
	movf	INDF, w		; leer sdoBuffer.sdoPuntero
	movwf	spiBufD7	; dejarlo en spiBufXXX

	;actualizar sdoPuntero 
	movf	sdoPuntero, w
	addlw	7
	movwf	sdoPuntero

	;byte 0 del mensaje
	movf	spiBufD0, w	
	andlw	b'00010000'	; mantener el bit 'toggle'
	movwf	spiBufD0
	
	;comprobar si se trata del ultimo segmento
	movf	sdoPuntero, w
	subwf	sdoNumBytes, w	; w = sdoNumBytes - sdoPuntero
	btfsc	carry
	goto	sdoS2			; no -> a sdoS2
					; si ->

	;poner a cero los bytes de sdoBuffer que
	;contienen datos espurios
	movwf	sdoNumBytes	
	
	movlw	spiBufD7	;apuntar final del buffer spiBuf
	movwf	FSR

sdoS4	movf	sdoNumBytes, f
	btfsc	zero	
	goto	sdoS5
	clrf	INDF
	incf	sdoNumBytes, f
	decf	FSR, f
	goto	sdoS4

sdoS5	;bit <0> de spiBufD0 = 1
	bsf	spiBufD0, 0

	;entrar siguiente estado
	clrf	sdoEstado		; estado = ENTRANDO

sdoS2	;volcar el buffer al MCP y enviar mensaje
	movlw	8
	movwf	spiBufSIDL
	spiEscribirBuffer TXB0DLC
	spiRts	1
	goto	sdoIsrFin

sdoS3	;entrar estado ENTRANDO y saltar a sdoEntrada
	clrf	sdoEstado
	goto	sdoEntrada

;<<<< sdoBajando >>>>

sdoBajando
	; ¿ comando == Bajar Segmento ?
	movf	spiBufD0, w
	andlw	0xe0
	sublw	0x00
	btfsc	zero	
	goto	sdoB1	; si
	
	; ¿ comando == Iniciar Bajada ?
	movf	spiBufD0, w
	andlw	0xe0
	sublw	0x20
	btfsc	zero	
	goto	sdoB2	; si

	;comando incorrecto -> entrar codigos de error y enviar 
	; mensaje 'Abort SDO Segment' 
	movlw	5
	movwf	spiBufD7
	movlw	4
	movwf	spiBufD6
	clrf	spiBufD5
	movlw	1
	movwf	spiBufD4
	goto	sdoAbortar

sdoB1	;comprobar bit 'toggle'
	clrf	sdoTemp1	;copiar bit 'toggle' a sdoTemp1<4>
	btfsc	toggle
	bsf	sdoTemp1, 4	
	
	movlw	0x10		;quedarnos con el bit 'toggle' del mensaje
	andwf	spiBufD0, w	
	
	xorwf	sdoTemp1	;compararlos
	btfsc	zero		
	goto	sdoB3 		; son iguales 

	;bit 'toggle' incorrecto -> entrar codigos de error y enviar 
	; mensaje 'Abort SDO Segment' 
	movlw	5
	movwf	spiBufD7
	movlw	3
	movwf	spiBufD6
	clrf	spiBufD5
	clrf	spiBufD4
	goto	sdoAbortar

sdoB3	;actualizar bit 'toggle' para el siguiente segmento
	movlw	b'01000000'
	xorwf	sdoEstado, f

	;inicializar el registro FSR
	movf	sdoPuntero, w
	addlw	sdoBuffer
	movwf	FSR
	bcf	STATUS,IRP	; bancos 0 y 1

	;volcar spiBufXXX -> sdoBuffer
	movf	spiBufD1, w
	movwf	INDF
	incf	FSR, f
	movf	spiBufD2, w
	movwf	INDF
	incf	FSR, f
	movf	spiBufD3, w
	movwf	INDF
	incf	FSR, f
	movf	spiBufD4, w
	movwf	INDF
	incf	FSR, f
	movf	spiBufD5, w
	movwf	INDF
	incf	FSR, f
	movf	spiBufD6, w
	movwf	INDF
	incf	FSR, f
	movf	spiBufD7, w
	movwf	INDF
	
	;actualizar sdoPuntero
	movf	sdoPuntero, w
	addlw	7
	movwf	sdoPuntero

	;comprobar si se trata del ultimo segmento
	btfss	spiBufD0, 0
	goto	sdoB_Fin	; no -> no llamar a sdoBajarXXX
				; si -> 
	;entrar siguiente estado
	clrf	sdoEstado

	;volcar sdoBuffer a registros del PIC
	;marca para distingir si se llama a los sdoObjetoXXX tras una bajada expedita o no
	bsf	sdoEstado, 7
				
	;flags ->(SDO bajar)
	bsf	sdoEstado, 2
	bsf	sdoEstado, 3
	goto	sdoBajarObjetos

sdoB_Fin
	;enviar confirmacion
	movf	spiBufD0, w
	andlw	b'00010000'	; mantener bit 'toggle'
	iorlw	b'00100000'	
	movwf	spiBufD0
	
	clrf	spiBufD1
	clrf	spiBufD2
	clrf	spiBufD3
	clrf	spiBufD4
	clrf	spiBufD5
	clrf	spiBufD6
	clrf	spiBufD7
	movlw	8
	movwf	spiBufSIDL
	spiEscribirBuffer TXB0DLC
	spiRts	1
	
	;y salir de la rutina del SDO
	goto	sdoIsrFin

sdoB2	;entrar estado ENTRANDO y saltar a sdoEntrando
	clrf	sdoEstado
	goto	sdoEntrada

;<<<< sdoAbortar >>>>

sdoAbortar
	;siguiente estado = ENTRANDO
	clrf	sdoEstado

	;enviar mensaje
	movlw	8
	movwf	spiBufSIDL
	movlw	0x80
	movwf	spiBufD0
	spiEscribirBuffer	TXB0DLC
	spiRts	1

	;fin
	goto	sdoIsrFin

;<<<< sdoIsrFin >>>>

sdoIsrFin
	movlw	high(isrFin)
	movwf	PCLATH
	goto	isrFin

;<<<< sdoBajarFin >>>>
;los sdoBajarXXX saltan aqui si no ha habido errores
; en caso contrario saldran a traves de sdoAbortar

;si la bajada a sido expedita sdoEstado<7> = 0 y  se debe salir por sdoIB_Fin
;             no                             1                      sdoB_Fin

sdoBajarFin
	;¿sdoEstado<7> == 1 ?
	btfsc	sdoEstado, 7
	goto	sdoB_Fin	;si -> sdoB_Fin
	goto	sdoIB_Fin	;no    sdoIB_Fin

	GLOBAL	sdoBajarFin

;<<<< sdoSubirObjetos >>>>

sdoSubirObjetos
	;si el objeto esta definido en la aplicacion
	; en vez de en el sistema se llega a él a
	; traves de pdoSaltoAObjetos.
	movlw	numeroObjetosSistema
	subwf	sdoObjeto, w
	btfsc	carry
	goto	pdoSaltoAObjetos

	movlw	high(sdoSubirObjetos)
	movwf	PCLATH
	movf	sdoObjeto, w
	addwf	PCL, f
	goto	sdoSubir0
	goto	sdoSubir1
	goto	sdoSubir2
	goto	sdoSubir3
	goto	sdoSubir4
	goto	sdoSubir5
	goto	sdoSubir6
	goto	sdoSubir7
	goto	sdoSubir8
	goto	sdoSubir9
	goto	sdoSubir10
	goto	sdoSubir11
	goto	sdoSubir12
	goto	sdoSubir13
	goto	sdoSubir14
	goto	sdoSubir15
	goto	sdoSubir16
	goto	sdoSubir17
	goto	sdoSubir18
	goto	sdoSubir19
	goto	sdoSubir20
	goto	sdoSubir21
	goto	sdoSubir22
	goto	sdoSubir23
	goto	sdoSubir24
	goto	sdoSubir25
	nop
	nop
	nop
	nop
	nop	; sdoSubir30 (en total 32-1 = 31 objetos) 

;<<<< sdoBajarObjetos >>>>
nop	; estos nop estan aqui para evitar
nop	; que la tabla de saltos siguiente
nop	; (sdoBajarObjetos) quede situada en 
nop	; dos bloques de 256 bytes diferentes
nop	
nop
nop

sdoBajarObjetos
	;si el objeto esta definido en la aplicacion
	; en vez de en el sistema se llega a él a
	; traves de pdoSaltoAObjetos.
	movlw	numeroObjetosSistema
	subwf	sdoObjeto, w
	btfsc	carry
	goto	pdoSaltoAObjetos

	movlw	high(sdoBajarObjetos)
	movwf	PCLATH
	movf	sdoObjeto, w
	addwf	PCL, f
	goto	sdoBajar0
	goto	sdoBajar1
	goto	sdoBajar2
	goto	sdoBajar3
	goto	sdoBajar4
	goto	sdoBajar5
	goto	sdoBajar6
	goto	sdoBajar7
	goto	sdoBajar8
	goto	sdoBajar9
	goto	sdoBajar10
	goto	sdoBajar11
	goto	sdoBajar12
	goto	sdoBajar13
	goto	sdoBajar14
	goto	sdoBajar15
	goto	sdoBajar16
	goto	sdoBajar17
	goto	sdoBajar18
	goto	sdoBajar19
	goto	sdoBajar20
	goto	sdoBajar21
	goto	sdoBajar22
	goto	sdoBajar23
	goto	sdoBajar24
	goto	sdoBajar25
	nop
	nop
	nop
	nop
	nop	; sdoBajar30 (en total 32-1 = 31 objetos) 


;<<<< sdoSubirXXX >>>>
;volcar al buffer sdoBuffer los bytes a enviar
; no cambiar sdoPuntero ni sdoNumBytes
;alguno de estos llamaran appSdoSubirXXX


sdoSubir0	;device type (Tipo Dispositivo, TD)
	movlw	sdoBuffer
	movwf	FSR
	clrf	sdoTemp1
sdoSSTD1
	movlw	high(appVectores)
	movwf	PCLATH
	movf 	sdoTemp1,w	; puntero a tabla al acumulador
	call	(appVectores+5) ;leer tabla
	movwf	sdoTemp2	;salvar lectura
	movlw	high(sdoSubir2)
	movwf	PCLATH
	movf	sdoTemp2,w	;restaurar lectura
	xorlw	0x0a		;comprobar si es \n
	btfsc	STATUS,Z
	goto	sdoIsrFin	; si es \n => fin
				; no es \n => continuar
	movf	sdoTemp2,w	; volcar lectura al w
	movwf	INDF		; mover al buffer
	incf	FSR,f		; apuntar al sigiente reg del buffer
	incf	sdoTemp1,f	; incrementar puntero a tabla 
	goto	sdoSSTD1	; seguir con la siguiente entrada en la tabla
	
sdoSubir1	;error register
	eepromLeer	eepromErrorRegister
	movwf	sdoBuffer
	goto	sdoIsrFin

sdoSubir2	;nombre dispositivo
	movlw	sdoBuffer
	movwf	FSR
	clrf	sdoTemp1
sdoSSND1
	movlw	high(appVectores)
	movwf	PCLATH
	movf 	sdoTemp1,w	; puntero a tabla al acumulador
	call	(appVectores+7) ;leer tabla
	movwf	sdoTemp2	;salvar lectura
	movlw	high(sdoSubir2)
	movwf	PCLATH
	movf	sdoTemp2,w	;restaurar lectura
	xorlw	0x0a		;comprobar si es \n
	btfsc	STATUS,Z
	goto	sdoIsrFin	; si es \n => fin
				; no es \n => continuar
	movf	sdoTemp2,w	; volcar lectura al w
	movwf	INDF		; mover al buffer
	incf	FSR,f		; apuntar al sigiente reg del buffer
	incf	sdoTemp1,f	; incrementar puntero a tabla 
	goto	sdoSSND1	; seguir con la siguiente entrada en la tabla

sdoSubir3	;version software
	movlw	sdoBuffer
	movwf	FSR
	clrf	sdoTemp1
sdoSSVS1
	movlw	high(appVectores)
	movwf	PCLATH
	movf 	sdoTemp1,w	; puntero a tabla al acumulador
	call	(appVectores+6) ;leer tabla
	movwf	sdoTemp2	;salvar lectura
	movlw	high(sdoSubir2)
	movwf	PCLATH
	movf	sdoTemp2,w	;restaurar lectura
	xorlw	0x0a		;comprobar si es \n
	btfsc	STATUS,Z
	goto	sdoIsrFin	; si es \n => fin
				; no es \n => continuar
	movf	sdoTemp2,w	; volcar lectura al w
	movwf	INDF		; mover al buffer
	incf	FSR,f		; apuntar al sigiente reg del buffer
	incf	sdoTemp1,f	; incrementar puntero a tabla 
	goto	sdoSSVS1	; seguir con la siguiente entrada en la tabla
		
sdoSubir4	;PDO1RX_Comm
sdoSubir6	;PDO2RX_Comm
	movlw	0x01
	movwf	sdoBuffer
	goto 	sdoIsrFin

sdoSubir12	;PDO3RX_Comm
sdoSubir15	;PDO4RX_Comm
	movlw	0x02
	movwf	sdoBuffer
	goto 	sdoIsrFin

sdoSubir5	; COB-ID del PDO1
	;registros de la EEPROM en los que se encuentran (IDH) y (IDL)
	movlw	eepromPdo1IDH
	movwf	sdoTemp2
	; mascara para VALID y RTR
	movlw	0x11
	movwf	sdoTemp1

	;saltar a la rutina común 
	goto	sdoSubir_COBID

sdoSubir7	; COB-ID del PDO2
	movlw	eepromPdo2IDH
	movwf	sdoTemp2
	movlw	0x22
	movwf	sdoTemp1

	goto	sdoSubir_COBID

sdoSubir13	; COB-ID del PDO3
	movlw	eepromPdo3IDH
	movwf	sdoTemp2
	movlw	0x44
	movwf	sdoTemp1

	goto	sdoSubir_COBID

sdoSubir16	; COB-ID del PDO4
	movlw	eepromPdo4IDH
	movwf	sdoTemp2
	movlw	0x88
	movwf	sdoTemp1

	goto	sdoSubir_COBID

sdoSubir_COBID
	;mover (PDO valid / PDO not valid) y (RTR allowed / no RTR allowed) a sdoBuffer
	clrf	(sdoBuffer + 3)
	eepromLeer	eepromVALIDRTR	; XXXXYYYY
	andwf	sdoTemp1, f		; 00X000Y0
	movlw	0x0f
	andwf	sdoTemp1, w		; 000000Y0
	btfsc	zero					
	bsf	(sdoBuffer + 3), 6
	movlw	0xf0
	andwf	sdoTemp1, w		; 00X00000
	btfsc	zero
	bsf	(sdoBuffer + 3), 7	

	;mover (IDH), (IDL) a sdoTemp1 y sdoTemp2
	eepromLeerF	sdoTemp2	;apunta a IDH
	movwf		sdoTemp2	
	eepromLeerS			;apunta a IDL
	movwf		sdoTemp1

	;sdoBuffer byte
	; 0->bits<0..7>   1->bits<8..15>   2->bits<16..23>   3->bits<24..31>
		
	;bits<16..23> siempre 0 (solo ID de 11 bit)
	clrf	sdoBuffer+2

	;bits<0..7> y bits<8..15>
	movlw	0xe0
	andwf	sdoTemp1,f	; quedarme con los bits del ID
	
	;AITOR
	;bcf	carry		; comenzar a desplazar los bits
	;btfsc	sdoTemp1, 7
	;bsf	carry
	bcf	carry
	rlf	sdoTemp1,f
	;AITOR
	
	rlf	sdoTemp2, f	
	rlf	sdoTemp1, f
	rlf	sdoTemp2, f	
	rlf	sdoTemp1, f
	rlf	sdoTemp2, f	
	rlf	sdoTemp1, f
		
	movf	sdoTemp1, w	; dejar los bits<0..10> del ID
	movwf	sdoBuffer+1	; en sdoBuffer
	movf	sdoTemp2, w
	movwf	sdoBuffer

	goto 	sdoIsrFin

sdoSubir8	;PDO1_Mapping
	;primer registro del mapping del PDO1
	movlw	eepromPdo1M1
	movwf	sdoTemp1
	
	;saltar a la rutina compartida
	goto	sdoSubir_8_17_32_41

sdoSubir10	;PDO2_Mapping
	;primer registro del mapping del PDO2
	movlw	eepromPdo2M1
	movwf	sdoTemp1

	goto	sdoSubir_8_17_32_41
	
sdoSubir18	;PDO3_Mapping
	;primer registro del mapping del PDO2
	movlw	eepromPdo3M1
	movwf	sdoTemp1

	goto	sdoSubir_8_17_32_41

sdoSubir20	;PDO4_Mapping
	;primer registro del mapping del PDO2
	movlw	eepromPdo4M1
	movwf	sdoTemp1

	goto	sdoSubir_8_17_32_41

sdoSubir_8_17_32_41
	;contar cuantos registros de la EEPROM a partir de eepromPdoXM0 
	; no contienen un 0xff (un 0xff significa que ya no hay más objetos
	; mapeados)

	clrf	sdoTemp2		;inicializar contador
	eepromLeerF	sdoTemp1	;sdoTemp1 contiene la direccion
	btfsc	zero			; de eepromPdoXM1 
	goto	sdoSubir_8_Fin

sdoSubir_8_Bucle
	incf	sdoTemp2, f
	eepromLeerS	
	addlw	1
	btfss	zero
	goto	sdoSubir_8_Bucle

sdoSubir_8_Fin
	movf	sdoTemp2, w
	movwf	sdoBuffer

	goto	sdoIsrFin

sdoSubir9	;objetos mapeados del PDO1
	;base del mapeo en la eeprom
	movlw	(eepromPdo1M1-1)
	;offset
	addwf	sdoSubIndex, w	; sdoSubIndex=0 => (w <- eepromPdo1M1)
	movwf	sdoTemp1

	;saltar a la rutina compartida
	goto	sdoSubir_Mapping

sdoSubir11	;objetos mapeados del PDO2
	;base del mapeo en la eeprom
	movlw	(eepromPdo2M1-1)
	;offset
	addwf	sdoSubIndex, w	; sdoSubIndex=0 => (w <- eepromPdo2M1)
	movwf	sdoTemp1

	;saltar a la rutina compartida
	goto	sdoSubir_Mapping

sdoSubir19	;objetos mapeados del PDO3
	;base del mapeo en la eeprom
	movlw	(eepromPdo3M1-1)
	;offset
	addwf	sdoSubIndex, w	; sdoSubIndex=0 => (w <- eepromPdo3M1)
	movwf	sdoTemp1

	;saltar a la rutina compartida
	goto	sdoSubir_Mapping

sdoSubir21	;objetos mapeados del PDO4
	;base del mapeo en la eeprom
	movlw	(eepromPdo4M1-1)
	;offset
	addwf	sdoSubIndex, w	; sdoSubIndex=0 => (w <- eepromPdo4M1)
	movwf	sdoTemp1

	;saltar a la rutina compartida
	goto	sdoSubir_Mapping

sdoSubir_Mapping
	;salvar sdoObjeto en sdoTemp2 y 
	;y dejar contenido de la posicion sdoTemp1 
	;de la EEPROM en sdoObjeto
	movf	sdoObjeto, w
	movwf	sdoTemp2
	
	;obtener objeto mapeado
	eepromLeerF	sdoTemp1
	movwf	sdoObjeto

	;obtener IndexHigh, IndexLow, SubIndex
	; y dejarlos en sdoBuffer
	movlw	high(appSdoTablaIndexHigh)
	movwf	PCLATH
	call	appSdoTablaIndexHigh
	movwf	sdoBuffer+3

	movlw	high(appSdoTablaIndexLow)
	movwf	PCLATH
	call	appSdoTablaIndexLow
	movwf	sdoBuffer+2

	movlw	high(appSdoTablaSubIndex)
	movwf	PCLATH
	call	appSdoTablaSubIndex
	movwf	sdoBuffer+1

	;obtener longitud en bytes, pasarlo a bits
	; y dejarlo en sdoBuffer
	movlw	high(appSdoTablaPropiedades)
	movwf	PCLATH
	call	appSdoTablaPropiedades
	movwf	sdoTemp1

	movlw	0x3f		; quedarme con el numero de bytes
	andwf	sdoTemp1, f

	rlf	sdoTemp1, f	; pasarlo a bits
	rlf	sdoTemp1, f
	rlf	sdoTemp1, w

	movwf	sdoBuffer	;y dejarlo en sdoBuffer
	
	;restaurar sdoObjeto
	movf	sdoTemp2, w
	movwf	sdoObjeto

	;fin
	movlw	high(sdoIsrFin)
	movwf	PCLATH
	goto	sdoIsrFin
	
sdoSubir14	; tx_type de PDO3
	;registro en el que se encuentra el tx_type
	movlw	eepromPdo3TxType
	;saltar a la rutina compartida
	goto	sdoSubir_TxType

sdoSubir17	; tx_type de PDO4
	movlw	eepromPdo4TxType
	goto	sdoSubir_TxType

sdoSubir_TxType
	;obtener el tx_type
	movwf	sdoTemp1
	eepromLeerF	sdoTemp1
	
	;dejarlo en el sdoBuffer y fin
	movwf	sdoBuffer

	goto	sdoIsrFin
	
sdoSubir22	;download program data
sdoSubir24	;program control
	;un único programa 
	movlw	1
	movwf	sdoBuffer
	goto	sdoIsrFin
	
sdoSubir23	;download program data - program number 1
	;no se puede leer el programa
	goto	sdoIsrFin
	
sdoSubir25	;program control - program number 1
	;obtener el flag de programa cargado
	eepromLeer eepromProgramFlag
	movwf	sdoBuffer
	goto	sdoIsrFin	
	
;<<<< sdoBajarXXX >>>>
;volcar del buffer sdoBuffer los bytes recibidos
; a los registros que los utilizan
; no cambiar sdoPuntero ni sdoNumBytes
;alguno de estos llamaran appSdoBajarXXX

sdoBajar0	;device type				
sdoBajar1	;error register				
sdoBajar2	;nombre dispositivo		
sdoBajar3	;version software
sdoBajar4	;PDO1RX (Communication parameters)
sdoBajar6	;PDO2RX (Communication parameters)
sdoBajar12	;PDO1TX = PDO3 (Communication parameters)
sdoBajar15	;PDO1TX = PDO4 (Communication parameters)
sdoBajar22	;download program data
sdoBajar24	;program control
sdoBajar25	;program control - program number 1


sdoBajar_0_1_2_3_4_6_12_15_22
	;estos objetos no se pueden escribir =>
	; entrar codigos de error y enviar
	; un 'Abort SDO Segment'
	movlw	6
	movwf	spiBufD7
	movlw	1	
	movwf	spiBufD6
	clrf	spiBufD5
	movlw	2
	movwf	spiBufD4
	goto	sdoAbortar	

sdoBajar5	;COB-ID de PDO1
	;inicializar puntero a EEPROM y mascara para VALIDRTR
	eepromPuntero	(eepromPdo1IDH - 1)
	movlw	0x11
	movwf	sdoTemp3
	;saltar a rutina compartida
	goto	sdoBajar_COBID

sdoBajar7	;COB-ID de PDO2
	eepromPuntero	(eepromPdo2IDH - 1)
	movlw	0x22
	movwf	sdoTemp3
	goto	sdoBajar_COBID

sdoBajar13	;COB-ID de PDO3
	eepromPuntero	(eepromPdo3IDH - 1)
	movlw	0x44
	movwf	sdoTemp3
	goto	sdoBajar_COBID

sdoBajar16	;COB-ID de PDO4
	eepromPuntero	(eepromPdo4IDH - 1)
	movlw	0x88
	movwf	sdoTemp3
	goto	sdoBajar_COBID

sdoBajar_COBID
	;sdoBuffer byte
	; 0->bits<0..7>   1->bits<8..15>   2->bits<16..23>   3->bits<24..31>

	;volcar bits<0..15> a sdoTemp1 y sdoTemp2
	movf	sdoBuffer, w
	movwf	sdoTemp1	
	movf	sdoBuffer+1, w
	movwf	sdoTemp2
	
	;desplazarlos para dejarlos en eepromPdoXIDH y eepromPdoXIDL
	rlf	sdoTemp1, f
	rlf	sdoTemp2, f
	movlw	0x0f
	andwf	sdoTemp2, f
	movlw	0xf0
	andwf	sdoTemp1, w
	iorwf	sdoTemp2, f
	swapf	sdoTemp2, f
	swapf	sdoTemp1, f
	movlw	0xe0
	andwf	sdoTemp1, f	
		
	;volcar sdoTemp1 y sdoTemp2 a la EEPROM
	eepromEscribirSF sdoTemp2
	eepromEscribirSF sdoTemp1

	;bits ?VALID y ?RTR 
	movlw	0x00
	;-?VALID, bit<>
	btfsc	(sdoBuffer+3), 7		
	iorlw	0xf0			; XXXX0000
	;-?RTR
	btfsc	(sdoBuffer+3), 6		
	iorlw	0x0f			; XXXXYYYY
	;-pasarlo a eepromVALIDRTR			
	andwf	sdoTemp3, w	; PDO2 -> 00X000Y0	;si aqui X o Y estan a 1 
	movwf	sdoTemp2				; en VALIDRTR deben estar a 0
	;AITOR
	;comf	sdoTemp3, f
	;eepromLeer	eepromVALIDRTR	; zzzzzzzz
	;andwf	sdoTemp3, w		; zz0zzz0z
	;iorwf	sdoTemp2, f		; zzXzzzYz
	;eepromEscribirF eepromVALIDRTR, sdoTemp2
	
	eepromLeer	eepromVALIDRTR	; zzzzzzzz
	iorwf	sdoTemp3, w		; zz1zzz1z
	xorwf	sdoTemp2, f		; zz/Xzzz/Yz		
	eepromEscribirF eepromVALIDRTR, sdoTemp2
	;AITOR

	;actualizar filtros del MCP
	movlw	high(nmtMcpConfiguracion)
	movwf	PCLATH
	call	nmtMcpConfiguracion
	call	nmtFiltro2
	call	nmtFiltro3
	call	nmtFiltro4TxBuffer1
	call	nmtFiltro5TxBuffer2
	call	nmtMcpNormal

	;actualizar pdoVALIDRTR
	call	nmtVALIDRTR

	;establecer prioridades entre los PDO de tx
	movlw	high(pdoPrioridadTx)
	movwf	PCLATH
	call	pdoPrioridadTx

	;fin
	movlw	high(sdoBajarFin)
	movwf	PCLATH
	goto	sdoBajarFin
	
sdoBajar8	; PDO1_Mapping
	;inicializar puntero a EEPROM
	eepromPuntero	(eepromPdo1M1 - 1)

	;saltar a la rutina compartida
	goto	sdoBajar_8_10_18_20

sdoBajar10	; PDO2_Mapping
	eepromPuntero	(eepromPdo2M1 - 1)
	goto	sdoBajar_8_10_18_20

sdoBajar18	; PDO3_Mapping
	eepromPuntero	(eepromPdo3M1 - 1)
	goto	sdoBajar_8_10_18_20

sdoBajar20	; PDO4_Mapping
	eepromPuntero	(eepromPdo4M1 - 1)
	goto	sdoBajar_8_10_18_20

sdoBajar_8_10_18_20
	;rellena el espacio de la EEPROM correspondiente al mapeo de objetos
	; con tantos '0x1f' como objetos a mapear y tras ellos con un '0xff'
	;antes de entrar en esta rutina hay que inicializar EEADR con (eepromPDOxM1 - 1)
	;por ejemplo: 3 objetos a mapear en PDO2
	; eepromPDO2M1 <- 0x1f	 \
	; eepromPDO2M2 <- 0x1f   |- 3 objetos a mapear
	; eepromPDO2M3 <- 0x1f	 /
	; eepromPDO2M4 <- 0xff
	; eepromPDO2M5 <- ?
	; eepromPDO2M6 <- ?
	; eepromPDO2M7 <- ?
	; eepromPDO2M8 <- ?
	
	;volcar sdoBuffer a sdoTemp1
	movf	sdoBuffer, w
	movwf	sdoTemp1
		
	;si indica más de 8 => 8
	movlw	9
	subwf	sdoTemp1, w
	movlw	8
	btfsc	carry
	movwf	sdoTemp1

	;inicializar con 0x1f los PdoxMy que se van a utilizar en el mapeo
	movf	sdoTemp1, f
	btfsc	zero
	goto	sdoBajar_8_Seguir

sdoBajar_8_Bucle
	;inicializar registros con el codigo del primerObjetoMapeable
	eepromEscribirS	0x1f
	;control del bucle
	decfsz	sdoTemp1, f
	goto	sdoBajar_8_Bucle

sdoBajar_8_Seguir
	;escribir un 0xff en la EEPROM
	eepromEscribirS	0xff
		
	;fin
	goto	sdoBajarFin

sdoBajar9	;objetos mapeados de PDO1
	;base del mapeo en la eeprom
	movlw	(eepromPdo1M1 - 2)
	;offset
	addwf	sdoSubIndex, w

	;salto a la rutina compartida
	goto	sdoBajar_Mapping

sdoBajar11	;objetos mapeados de PDO2
	;base del mapeo en la eeprom
	movlw	(eepromPdo2M1 - 2)
	;offset
	addwf	sdoSubIndex, w

	;salto a la rutina compartida
	goto	sdoBajar_Mapping

sdoBajar19	;objetos mapeados de PDO3
	;base del mapeo en la eeprom
	movlw	(eepromPdo3M1 - 2)
	;offset
	addwf	sdoSubIndex, w

	;salto a la rutina compartida
	goto	sdoBajar_Mapping

sdoBajar21	;objetos mapeados de PDO4
	;base del mapeo en la eeprom
	movlw	(eepromPdo4M1 - 2)
	;offset
	addwf	sdoSubIndex, w

	;salto a la rutina compartida
	goto	sdoBajar_Mapping
	
sdoBajar_Mapping
	;inicializar el puntero a la EEPROM
	movwf	sdoTemp1
	eepromPunteroF	sdoTemp1

	;buscar objeto en tabla (en funcion del Index/SubIndex)	
		
	;salvar sdoObjeto en sdoTemp2 e inicializar sdoObjeto
	movf	sdoObjeto, w
	movwf	sdoTemp2
	clrf	sdoObjeto
	goto	sdoBajar_Mapping_2 	;para evitar 'apuntar al siguiente objeto'
					; la primera vez

sdoBajar_Mapping_1	
	;apuntar al siguiente objeto 
	incf	sdoObjeto, f

	;comprobar que el anterior no ha sido el último
	movlw	high(appVectores)
	movwf	PCLATH
	call	(appVectores + 8)	; appNumeroObjetos (definidos en la aplicacion)
	addlw	numeroObjetosSistema
	subwf	sdoObjeto, w
	movlw	high(sdoBajar_Mapping)
	movwf	PCLATH
	btfss	carry
	goto	sdoBajar_Mapping_2		; todavía quedan objetos
	
	;objeto no existe -> entrar codigos de error y enviar
	; un 'Abort SDO Segment'
	movlw	6
	movwf	spiBufD7
	movlw	2
	movwf	spiBufD6
	clrf	spiBufD5
	clrf	spiBufD4
	goto	sdoAbortar
		
sdoBajar_Mapping_2
	;obtener IndexLow de sdoObjeto y comparar
	movlw	high(appSdoTablaIndexLow)
	movwf	PCLATH
	call	appSdoTablaIndexLow
	subwf	(sdoBuffer + 2), w
	movlw	high(sdoBajar_Mapping_1)
	movwf	PCLATH
	btfss	zero			;coinciden??
	goto	sdoBajar_Mapping_1	; no
					; si
	;obtener IndexHigh de sdoObjeto y comparar
	movlw	high(appSdoTablaIndexHigh)
	movwf	PCLATH
	call	appSdoTablaIndexHigh
	subwf	(sdoBuffer + 3), w
	movlw	high(sdoBajar_Mapping_1)
	movwf	PCLATH
	btfss	zero			;coinciden??
	goto	sdoBajar_Mapping_1	; no
					; si
	;obtener SubIndex de sdoObjeto y comparar
	movlw	high(appSdoTablaSubIndex)
	movwf	PCLATH
	call	appSdoTablaSubIndex
	subwf	(sdoBuffer + 1), w
	movlw	high(sdoBajar_Mapping_1)
	movwf	PCLATH
	btfss	zero			;coinciden??
	goto	sdoBajar_Mapping_1	; no
					; si
	
	; (tenemos el numero de objeto)

	;¿Se puede mapear el objeto en un PDO?
	movlw	high(appSdoTablaPropiedades)
	movwf	PCLATH
	call	appSdoTablaPropiedades
	movwf	sdoTemp2			;para comprobar si el objeto se puede escribir
	andlw	0x40

	movlw	high(sdoBajar_Mapping_1)
	movwf	PCLATH

	btfsc	zero	
	goto	sdoBajar_Mapping_3

	;objeto no mapeable -> entrar codigos de error y enviar
	; un 'Abort SDO Segment'
	movlw	6
	movwf	spiBufD7
	movlw	4
	movwf	spiBufD6
	clrf	spiBufD5
	movlw	0x41
	movwf	spiBufD4
	goto	sdoAbortar

sdoBajar_Mapping_3
	;en sdoTemp1 tenemos (eepromPuntero-1) y en sdoTemp2 las prop. del objeto
	; si eepromPuntero < eepromPDO3SIDH -> estamos mapeando un PDO de recepcion
	; si ademas el objeto no se puede escribir -> error
	movlw	eepromPdo3IDH
	subwf	sdoTemp1,w
	btfsc	carry
	goto	sdoBajar_Mapping_4	; se trata de un PDO de tx -> no hay problemas
	
	btfss	sdoTemp2, 7
	goto	sdoBajar_Mapping_4	; se puede escribir

	;objeto no se puede escribir -> entrar codigos de error y enviar
	; un 'Abort SDO Segment'
	movlw	6
	movwf	spiBufD7
	movlw	4
	movwf	spiBufD6
	clrf 	spiBufD5
	movlw	0x41
	movwf	spiBufD4
	goto	sdoAbortar

sdoBajar_Mapping_4
	; (todo bien)
	;escribir en EEPROM el objeto a mapear
	eepromEscribirSF	sdoObjeto
	
	;restaurar contenido de sdoObjeto
	movf	sdoTemp2, w
	movwf	sdoObjeto

	;fin
	goto	sdoBajarFin

sdoBajar14	; tx_type de PDO3
	;obtener el tx-type, actualizar pdoContSync1 y escribirlo en la EEPROM
	movf	sdoBuffer, w
	movwf	pdoContSync1
	movwf	pdoTipoTx1
	eepromEscribirF	eepromPdo3TxType, pdoContSync1

	;fin
	goto	sdoBajarFin

sdoBajar17	; tx_type de PDO4
	;obtener el tx-type,actualizar pdoContSync2 y escribirlo en la EEPROM
	movf	sdoBuffer, w
	movwf	pdoContSync2
	movwf	pdoTipoTx2
	eepromEscribirF	eepromPdo4TxType, pdoContSync2

	;fin
	goto	sdoBajarFin
	
sdoBajar23	; donwload program data - program number 1
	; comprobar checksum
	movf	sdoBuffer, w	; cargar numero de bytes a programar
	addlw	4		; bytes BBAAAATT
	movwf	sdoTemp1	; cuenta de bytes a sumar
	movlw	sdoBuffer	; inicializar puntero a sdoBuffer
	movwf	FSR		;
	movlw	0		; inicializar suma a cero
sdoBajar23_1	
	addwf	INDF, w		; sumar byte
	incf	FSR		; apuntar al siguiente byte
	decfsz	sdoTemp1	; control del bucle
	goto	sdoBajar23_1
	
	xorlw	0xff		; complementar la suma
	movwf	sdoTemp1	
	incf	sdoTemp1, w	; incrementarla en uno
	
	xorwf	INDF, w		; compararla con el checksum recibido
	btfsc	zero		; si zero == 1 => todo bien
	goto	sdoBajar23_3
	
sdoBajar23_2
	;parametro no valido
	movlw	6
	movwf	spiBufD7
	movlw	9
	movwf	spiBufD6
	clrf 	spiBufD5
	clrf	spiBufD4
	goto	sdoAbortar
	
sdoBajar23_3
	;si numero de bytes de datos == 0 =>
	; no programar pero si actualizar flag de programa cargado
	movf	sdoBuffer, f	; poner flags segun este registro
	btfsc	zero		; si esta a cero
	goto	sdoBajar23_6	; saltar el codigo de programacion

	;comprobar si la direccion a escribir es valida
	; rango valido: (0x700 a 0x7ff) y (0xc00 )
	bcf	carry		;dividir la direccion entre 2
	rrf	sdoBuffer+1,f	; (para pasar de direccionamiento 
	rrf	sdoBuffer+2,f	; de bytes a dir. de palabras)
	movlw	0x07		; hacer la comprobacion
	subwf	sdoBuffer+1, w
	btfsc	zero	
	goto	sdoBajar23_4	;bien -> continuar
	movlw	0x0c
	subwf	sdoBuffer+1, w
	btfsc	carry
	goto	sdoBajar23_4	;bien -> continuar
	goto	sdoBajar23_2	;mal -> parametro no valido
	
sdoBajar23_4
	;borrar flag de programa cargado
	; eepromProgramFlag
	eepromEscribir	eepromProgramFlag, 0x00
	
	;programar
	;inicializar puntero a memoria de programa
	movlw	(sdoBuffer+1)	; puntero a sdoBuffer.ADDR(lsb)
	movwf	FSR
	bsf	STATUS,RP1	; Banco 2
	movf 	INDF,w		; LSB de la direccion 
	movwf 	EEADRH		; 
	incf	FSR, f		; puntero a sdoBuffer.ADDR(msb)
	movf	INDF,w		; MSB de la direccion
	movwf	EEADR		;
	bcf	STATUS,RP1	; banco 0
	
	;inicializar cuenta de palabras a escribir
	bcf	carry
	rrf	sdoBuffer, w	; dividir entre dos los bytes => palabras
	movwf	sdoTemp1	
	
	;inicializar puntero a sdoBuffer
	movlw	(sdoBuffer+4)
	movwf	FSR
	
	;mediante el modulo EEPROM acceder a la memoria de programa
	bsf	STATUS,RP0	; banco 3
	bsf	STATUS,RP1	;
	bsf	EECON1,EEPGD	; acceder a la memoria de programa
	
sdoBajar23_5
	;escribir una palabra
	bsf	STATUS,RP1
	bcf	STATUS,RP0	; banco 2
	movf	INDF, w		; tomar LSB de la palabra
	movwf	EEDATA		; dejarla en registro de escritura
	incf	FSR, f		; apuntar al siguiente byte
	movf	INDF, w		; tomar MSB de la palabra
	movwf	EEDATH		; dejarla en registro de escritura
	incf	FSR, f		; apuntar al siguiente byte
	call	eepromTerminarEscribir	; escribir la palabra
	
	;preparar siguiente escritura
	bsf	STATUS,RP1	; banco 2
	incf	EEADR, f	; incrementar direccion a escribir
	btfsc	carry		; 
	incf	EEADRH, f	;
	
	;control del bucle
	bcf	STATUS,RP1	; banco 0
	decfsz	sdoTemp1
	goto	sdoBajar23_5
	
	;mediante el modulo EEPROM acceder los datos
	bsf	STATUS,RP0	; banco 3
	bsf	STATUS,RP1	;
	bcf	EECON1,EEPGD	; acceder los datos
	bcf	STATUS,RP0	; banco 0
	bcf	STATUS,RP1	;	

sdoBajar23_6
	;se trata del ultimo bloque a programar
	;si es asi, poner flag de programa cargado a uno
	movf	sdoBuffer+3, f	; poner flags segun este byte
	btfsc	zero		; zero == 1 => no es el ultimo bloque
	goto	sdoBajarFin	; 
	eepromEscribir eepromProgramFlag, 0x01
	goto	sdoBajarFin	; 	

	END
