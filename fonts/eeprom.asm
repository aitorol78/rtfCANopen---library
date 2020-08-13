; EEPROM.ASM

; Aitor Olarra
; 21-9-00

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


;== Variables =============================================

eepVar	UDATA
eepromTemp1

;== Include y defines =====================================

#include<p16f873.inc>

#define bancol	STATUS,RP0
#define bancoh	STATUS,RP1


;== Subrutinas ============================================

eepCode	CODE

;<<<< eepromTerminarEscribir >>>>

eepromTerminarEscribir
	bsf 	STATUS, RP0 	; Bank 3
	bsf 	EECON1, WREN 	; Enable write

	;deshabilitar interrupciones
	movf	INTCON, w
	movwf	eepromTemp1
	bcf	INTCON, GIE

	movlw 	0X55
	movwf 	EECON2 		; Write 55h
	movlw 	0XAA		;
	movwf 	EECON2 		; Write AAh
	bsf 	EECON1, WR 	; Set WR bit to begin write
	
	;restaurar interrupciones
	btfsc	eepromTemp1, 7
	bsf	INTCON, GIE

	;esperar a que finalice la escritura
	bcf 	STATUS, RP0
	bcf 	STATUS, RP1	; banco 0

eepromTE
	btfss	PIR2, EEIF
	goto	eepromTE
	bcf	PIR2, EEIF
	
	bsf 	STATUS, RP0
	bsf 	STATUS, RP1	; banco 3

	bcf 	EECON1, WREN 	; Disable writes
	bcf 	STATUS, RP0
	bcf 	STATUS, RP1	; banco 0

	return
	
;<<<< eepromTerminarLeer >>>>	
eepromTerminarLeer
	bsf 	bancol  	; Banco 3
	bcf 	EECON1, EEPGD	; memoria de DATOS
	bsf 	EECON1, RD	; leer eeprom 
	bcf 	bancol  	; Banco 2
	movf 	EEDATA, W 	; W = EEDATA
	bcf 	bancoh		; banco 0
	
	return
	
	GLOBAL 	eepromTerminarEscribir, eepromTerminarLeer

;== CODIGO REPETIDO EN PAGINA 1 =================

eepCode2 CODE

;<<<< eepromTerminarEscribir_p1 >>>>

eepromTerminarEscribir_p1
	bsf 	STATUS, RP0 	; Bank 3
	bsf 	EECON1, WREN 	; Enable write

	;deshabilitar interrupciones
	movf	INTCON, w
	movwf	eepromTemp1
	bcf	INTCON, GIE

	movlw 	0X55
	movwf 	EECON2 		; Write 55h
	movlw 	0XAA		;
	movwf 	EECON2 		; Write AAh
	bsf 	EECON1, WR 	; Set WR bit to begin write
	
	;restaurar interrupciones
	btfsc	eepromTemp1, 7
	bsf	INTCON, GIE

	;esperar a que finalice la escritura
	bcf 	STATUS, RP0
	bcf 	STATUS, RP1	; banco 0

eepromTE_p1
	btfss	PIR2, EEIF
	goto	eepromTE_p1
	bcf	PIR2, EEIF
	
	bsf 	STATUS, RP0
	bsf 	STATUS, RP1	; banco 3

	bcf 	EECON1, WREN 	; Disable writes
	bcf 	STATUS, RP0
	bcf 	STATUS, RP1	; banco 0

	return
	
;<<<< eepromTerminarLeer_p1 >>>>	
eepromTerminarLeer_p1
	bsf 	bancol  	; Banco 3
	bcf 	EECON1, EEPGD	; memoria de DATOS
	bsf 	EECON1, RD	; leer eeprom 
	bcf 	bancol  	; Banco 2
	movf 	EEDATA, W 	; W = EEDATA
	bcf 	bancoh		; banco 0
	
	return
	
	END
