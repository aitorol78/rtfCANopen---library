; ISR.ASM

; rutinas de servicio de interrupcion (para generar codigo objeto)
;
; este archivo, isr.asm,  hay que añadirlo al proyecto

; Aitor Olarra 
; 27-7-00

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

; == Include y Define ==================================================

#include<p16f873.inc>
#include<pdo.h>
#include<sdo.h>
#include<spi.h>
#include<nmt.h>
#include<ext.h>

#define zero	STATUS,Z
#define carry	STATUS,C
#define banco   STATUS,RP0
#define bancoh  STATUS,RP1

; == variables =========================================================

isrData	UDATA
w_temp		res 1
status_temp	res 1
fsr_temp	res 1
pclath_temp	res 1
isrTemp1	res 1

	GLOBAL	w_temp, status_temp, fsr_temp, pclath_temp

; == codigo ============================================================

resVect CODE			;localizado en el vector de reset
	movlw 	high(resInicio)
	movwf	PCLATH
	goto	resInicio

intVect	CODE			;localizado en el vector de interrupción.
	; salvar contexto
	movwf	w_temp
	swapf	STATUS,W
	movwf	status_temp
	movf	FSR, w
	movwf	fsr_temp
	movf	PCLATH, w
	movwf	pclath_temp
	movlw 	high(isr)
	movwf	PCLATH
	goto	isr

resCode	CODE

; <<<< resInicio >>>>

resInicio
	;inicializar la aplicacion
	movlw	high(appVectores)
	movwf	PCLATH
	call	(appVectores + 0)	; appReset

	;inicializar servidor SDO
	movlw	high(sdoInicio)
	movwf	PCLATH
	call	sdoInicio	

	;inicializar las comunicaciones y entrar estado preoperacional
	movlw	high(nmtInicio)
	movwf	PCLATH
	call	nmtInicio
	goto	nmtPreOperacional
	
	

isrCode	CODE 			

;<<<< isr >>>>
; rutina de servicio de interrupciones

isr	; descubrir fuente de interrupcion

	btfsc	INTCON, INTF	; pin /INT
	goto	isrInt
	
	;... (tratamiento de otras interrupciones)
	movlw	high(appVectores)
	movwf	PCLATH
	goto	(appVectores + 1)	; appIsr

isrFin	
	;restaurar contexto y salir de la rutina de interrupcion
	movf	pclath_temp, w
	movwf	PCLATH
	movf	fsr_temp, w
	movwf	FSR
	swapf	status_temp, w
	movwf	STATUS
	swapf	w_temp, f 
	swapf	w_temp, w
	retfie
	

isrInt	; descubrir que buffer ha recibido el mensaje
	spiStatus
	movwf	isrTemp1
	btfsc 	isrTemp1,1	; si este bit esta a 1 -> buffer_1
				; si no buffer_0
	goto	isrInt1

isrInt0 ; buffer_0
	; volcar el buffer_0 a la RAM del PIC
	spiLeerBuffer RXB0CTRL

	; librar el buffer_0
	spiModBit	CANINTF, b'00000001', 0x00
	; borrar flag de interrupcion
	bcf	INTCON, INTF

	; descubrir que mensaje ha llegado ( NMT | SYNC | SDO | nada)
	; (para diferenciar filtro0 de filtro1 no se puede utilizar el bit 
	; FILHIT de RXB0CTRL) errata document -> 8. Module: Receive Buffer 0
	btfsc	spiBufSIDH, 7	; si este bit esta a 1 -> SDO | nada
				; sino -> SYNC | NMT
	goto	isrSdoNada	;(aquí se decide si SDO o nada)
	btfsc	spiBufSIDH, 4	; si este bit esta a 1 -> SYNC
				; sino -> NMT
	goto	isrPdoSYNC
	goto	isrNmtEntrada 

isrInt1 ; buffer_1
	; volcar el buffer_1 a la RAM del PIC
	spiLeerBuffer RXB1CTRL

	; librar el buffer_1
	spiModBit	CANINTF, b'00000010', 0x00
	; borrar flag de interrupcion
	bcf	INTCON, INTF

	; nmtEstado == OPERACIONAL ?
	btfss	nmtEstado, 0
	goto	isrFin	

	; sí

	; descubrir que mensaje ha llegado
	movf	spiBufCTRL, w
	andlw	0x07		; tengo el codigo del filtro 
	addwf	PCL, f
	nop			; filtro 0 (no es posible)
	nop			; filtro 1 (no es posible)
	goto	isrPdoRx1		; filtro 2
	goto	isrPdoRx2		; filtro 3
	goto	isrPdoTx1		; filtro 4
	goto	isrPdoTx2		; filtro 5

	GLOBAL isr, isrFin
		
;<<<< isr<saltosAOtrosModulos> >>>>
; saltos a la rutina <subrutina> despues de actualizar PCLATH

isrSdoNada
	; se trata de un SDO?
	btfsc	spiBufSIDH, 4	; si este bit esta a 1 -> no
				; 		     0    si
	goto	isrFin	
	
	; sí es un SDO, pero nmtEstado <> PARADO ?
	btfsc	nmtEstado, 2
	goto	isrFin	
	
	; sí 
	movlw	high(sdoEntrada)
	movwf	PCLATH
	goto	sdoEntrada

isrPdoSYNC
	; nmtEstado == OPERACIONAL ?
	btfss	nmtEstado, 0
	goto	isrFin	

	; sí
	movlw	high(pdoSYNC)
	movwf	PCLATH
	goto	pdoSYNC

isrNmtEntrada
	movlw	high(nmtEntrada)
	movwf	PCLATH
	goto	nmtEntrada

isrPdoRx1
	;comprobar que este PDO es valido
	btfsc	pdoVALIDRTR, 4
	goto	isrFin

	movlw	high(pdoRx1)	
	movwf	PCLATH
	goto	pdoRx1

isrPdoRx2
	;comprobar que este PDO es valido
	btfsc	pdoVALIDRTR, 5
	goto	isrFin

	movlw	high(pdoRx2)	
	movwf	PCLATH
	goto	pdoRx2

isrPdoTx1
	;comprobar que este PDO es valido
	btfsc	pdoVALIDRTR, 6
	goto	isrFin
	;comprobar que este PDO soporta RTR
	btfsc	pdoVALIDRTR, 2
	goto	isrFin

	movlw	high(pdoTx1)	
	movwf	PCLATH
	goto	pdoTx1

isrPdoTx2
	;comprobar que este PDO es valido
	btfsc	pdoVALIDRTR, 7
	goto	isrFin
	;comprobar que este PDO soporta RTR
	btfsc	pdoVALIDRTR, 3
	goto	isrFin

	movlw	high(pdoTx2)
	movwf	PCLATH
	goto	pdoTx2

	END
