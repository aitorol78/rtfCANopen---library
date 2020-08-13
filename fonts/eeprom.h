; EEPROM.H

	nolist

; definiciones de
; - macros para acceder a la eeprom
; - direcciones de datos en la eeprom

; Aitor Olarra
; 16-8-00

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

; == extern ==================================================

	EXTERN	eepromTerminarEscribir, eepromTerminarLeer

; == define ==================================================

#define	bancol	STATUS,RP0
#define bancoh	STATUS,RP1

; == macros ==================================================

;<<<< eepromLeer >>>>
; lee el registro de la eeprom y lo deja en el w

eepromLeer	macro	direccion
	bsf	bancoh
	bcf 	bancol		; Banco 2
	movlw 	direccion	; direccion del registro de la eeprom 
	movwf 	EEADR		;  a leer
	
	call	eepromTerminarLeer
	endm

;<<<< eepromLeerF >>>>

eepromLeerF	macro	registro
	movf	registro, w	; obtener direccion del registro a leer
	bsf	bancoh
	bcf 	bancol		; Banco 2
	movwf 	EEADR		; 

	call	eepromTerminarLeer
	endm

;<<<< eepromLeerPor2 >>>>
; lee el registro de la eeprom y lo deja en el w multiplicado por 2

eepromLeerPor2	macro	direccion
	bsf	bancoh
	bcf 	bancol		; Banco 2
	movlw 	direccion	; direccion del registro de la eeprom 
	movwf 	EEADR		;  a leer
	bsf 	bancol  	; Banco 3
	bcf 	EECON1, EEPGD	; memoria de DATOS
	bsf 	EECON1, RD	; leer eeprom 
	bcf 	bancol  	; Banco 2
	bcf	STATUS,C	; borrar el carry
	rlf 	EEDATA, W 	; W = EEDATA * 2
	bcf 	bancoh		; banco 0
	endm

;<<<< eepromLeerS >>>>
; Incrementa el puntero a la eeprom, lee el registro 
; y lo deja en el w 

eepromLeerS	macro	
	bsf	bancoh
	bcf 	bancol		; Banco 2
	incf 	EEADR, f	; incrementar registro a leer

	call	eepromTerminarLeer
	endm

;<<<< eepromLeerSPor2 >>>>
; Incrementa el puntero a la eeprom, lee el registro 
; y lo deja en el w multiplicado por 2

eepromLeerSPor2	macro	
	bsf	bancoh
	bcf 	bancol		; Banco 2
	incf 	EEADR, f	; incrementar registro a leer
	bsf 	bancol  	; Banco 3
	bcf 	EECON1, EEPGD	; memoria de DATOS
	bsf 	EECON1, RD	; leer eeprom 
	bcf 	bancol  	; Banco 2
	bcf	STATUS, C	; borrar el carry
	rlf 	EEDATA, W 	; W = EEDATA * 2
	bcf 	bancoh		; banco 0
	endm


;<<<< eepromEscribir >>>>

eepromEscribir	macro	direccion, valor
	bsf 	STATUS, RP1 	;
	bcf 	STATUS, RP0 	; Bank 2
	movlw	valor
	movwf 	EEDATA		; Data Memory Value to write
	movlw 	direccion	;
	movwf 	EEADR 		; Data Memory Address to write
	
	call	eepromTerminarEscribir
	endm

;<<<< eepromEscribirF >>>>

eepromEscribirF	macro	direccion, registro
	movf	registro, w	; tomar el contenido de registro
	bsf 	STATUS, RP1 	;
	bcf 	STATUS, RP0 	; Bank 2
	movwf 	EEDATA		; Data Memory Value to write
	movlw 	direccion	;
	movwf 	EEADR 		; Data Memory Address to write

	call	eepromTerminarEscribir
	endm

;<<<< eepromEscribirS >>>>
; Incrementa el puntero a la eeprom y escribe valor

eepromEscribirS	macro	valor
	movlw	valor		; tomar valor
	bsf 	STATUS, RP1 	;
	bcf 	STATUS, RP0 	; Bank 2
	movwf 	EEDATA		; Data Memory Value to write
	incf 	EEADR, f	; Data Memory Address to write

	call	eepromTerminarEscribir
	endm

;<<<< eepromEscribirSF >>>>
; Incrementa el puntero a la eeprom y escribe el contenido de registro

eepromEscribirSF	macro	registro
	movf	registro, w	; tomar el contenido de registro
	bsf 	STATUS, RP1 	;
	bcf 	STATUS, RP0 	; Bank 2
	movwf 	EEDATA		; Data Memory Value to write
	incf 	EEADR, f	; Data Memory Address to write

	call	eepromTerminarEscribir
	endm

;<<<< eepromPuntero >>>>
; Inicializa el registro EEADR con direccion

eepromPuntero	macro	direccion
	bsf	STATUS, RP1
	bcf	STATUS, RP0	; banco 2
	movlw	direccion
	movwf	EEADR		; inicializar direccion
	bcf	STATUS, RP1	; banco 0
	endm

;<<<< eepromPunteroF >>>>
; Inicializa el registro EEADR con el valor de registro

eepromPunteroF	macro	registro
	movf	registro, w
	bsf	STATUS, RP1
	bcf	STATUS, RP0	; banco 2
	movwf	EEADR		; inicializar direccion
	bcf	STATUS, RP1	; banco 0
	endm

;<<<< eepromPunteroInc >>>>
; Incrementa en uno el registro EEADR

eepromPunteroInc	macro
	bsf	STATUS, RP1
	bcf	STATUS, RP0	; banco 2
	incf	EEADR, f	; 
	bcf	STATUS, RP1	; banco 0
	endm

;<<<< eepromPunteroDec >>>>
; Decrementa en uno el registro EEADR

eepromPunteroDec	macro
	bsf	STATUS, RP1
	bcf	STATUS, RP0	; banco 2
	decf	EEADR, f	; 
	bcf	STATUS, RP1	; banco 0
	endm

; == Defines =========================================
; eepromPdoXIDH : bits<0..7> => bits<3..10> del ID
; eepromPdoXIDL : bits<5..7> => bits<0..2> del ID
; VALIDRTR : mirar variable pdoVALIDRTR
; eepromProgramFlag : 0x00 -> no hay programa cargado
; 		      0x01 -> si hay programa cargado


	cblock	0x00

  eepromPdo1IDH		;0x00
  eepromPdo1IDL		;0x01
  eepromPdo1TxType	;0x02
  eepromPdo1M1		;0x03
  eepromPdo1M2		;0x04
  eepromPdo1M3		;0x05
  eepromPdo1M4		;0x06
  eepromPdo1M5		;0x07
  eepromPdo1M6		;0x08
  eepromPdo1M7		;0x09
  eepromPdo1M8		;0x0a
  eepromPdo1Res		;0x0b

  eepromPdo2IDH		;0x0c
  eepromPdo2IDL		;0x0d
  eepromPdo2TxType	;0x0e
  eepromPdo2M1		;0x0f
  eepromPdo2M2		;0x10
  eepromPdo2M3		;0x11
  eepromPdo2M4		;0x12
  eepromPdo2M5		;0x13
  eepromPdo2M6		;0x14
  eepromPdo2M7		;0x15
  eepromPdo2M8		;0x16
  eepromPdo2Res		;0x17

  eepromPdo3IDH		;0x18
  eepromPdo3IDL		;0x19
  eepromPdo3TxType	;0x1a
  eepromPdo3M1		;0x1b
  eepromPdo3M2		;0x1c
  eepromPdo3M3		;0x1d
  eepromPdo3M4		;0x1e
  eepromPdo3M5		;0x1f
  eepromPdo3M6		;0x20
  eepromPdo3M7		;0x21
  eepromPdo3M8		;0x22
  eepromPdo3Res		;0x23

  eepromPdo4IDH		;0x24
  eepromPdo4IDL		;0x25
  eepromPdo4TxType	;0x26
  eepromPdo4M1		;0x27
  eepromPdo4M2		;0x28
  eepromPdo4M3		;0x29
  eepromPdo4M4		;0x2a
  eepromPdo4M5		;0x2b
  eepromPdo4M6		;0x2c
  eepromPdo4M7		;0x2d
  eepromPdo4M8		;0x2e
  eepromPdo4Res		;0x2f

  eepromVALIDRTR		;0x30	
  eepromErrorRegister	;0x31	
  eepromProgramFlag	;0x32
	endc
	
	list


