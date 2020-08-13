; CABECERA.INC

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

nolist

; incluir tras la declaración 
;
;	appCode CODE
;
; en el archivo app.asm

#define NO_RX1 b'00010011'
#define NO_RX2 b'00100011'
#define NO_TX1 b'01000111'
#define NO_TX2 b'10001011'
#define SI_RX1 0x03
#define SI_RX2 0x03
#define SI_TX1 0x03
#define SI_TX2 0x03

variable cuenta
cuenta set d'31'
while cuenta <= (d'31'+numeroObjetos-1)
radix dec
   objeto#v(cuenta) equ #v(cuenta)
radix hex
   cuenta++
endw


;==== MACROS =====

#define RW 0x01
#define RO 0x00

;<<<< appObjetoM1 >>>>
appObjetoM1	macro numObjeto, tipo, flagReg, flagBit, file1

; numObjeto -> para generar etiqueta appObjeto<numObjeto>, p.e. appObjeto0
; tipo -> RO | RW , si RO no se genera codigo que escribe el registro
; file1 -> registro que implementa el objeto
; flag -> bit que implementa el flag de nuevo dato. 

appObjeto#v(numObjeto)
 ;se trata de manejar un PDO o un SDO??
 btfsc	sdoEstado, 3	;bit a 0 => PDO
 goto	appObjeto#v(numObjeto)_SDO
	
appObjeto#v(numObjeto)_PDO
 ;se ha recibido un PDO o hay que enviarlo
 btfsc	sdoEstado, 2	;bit a 0 => hay que enviarlo
 goto	appObjeto#v(numObjeto)_PDO_recibir	

appObjeto#v(numObjeto)_PDO_enviar
	;volcar el valor del objeto al buffer al que apunta el FSR
	; y actualizar FSR
	movf	file1, w
	movwf	INDF	
	incf	FSR, f
		
	btfsc	flagReg, flagBit
	bsf	pdoFlags,0
	bcf	flagReg, flagBit

	;terminar en 
	movlw	high(pdoTxFin)
	movwf	PCLATH
	goto	pdoTxFin

appObjeto#v(numObjeto)_PDO_recibir
IF tipo
	;tomar el valor del objeto desde el buffer al que apunta FSR
	; y actualizar FSR
	movf	INDF, w
	movwf	file1
	incf	FSR, f

	;terminar en 
	movlw	high(pdoRxFin)
	movwf	PCLATH
	goto	pdoRxFin
ENDIF

		
appObjeto#v(numObjeto)_SDO
 ;se está subiendo o bajando el objeto
 btfsc	sdoEstado, 2	;bit a 0 => se está subiendo
 goto	appObjeto#v(numObjeto)_SDO_bajar

appObjeto#v(numObjeto)_SDO_subir
	;volcar el valor del objeto a sdoBuffer
	movf	file1, w	 
	movwf	sdoBuffer 	
	
	;terminar en
	goto	appIsrFin
	
appObjeto#v(numObjeto)_SDO_bajar
IF tipo
	;volcar el valor del objeto desde sdoBuffer
	movf	sdoBuffer, w	
	movwf   file1	
	
	;terminar en 
	movlw	high(sdoBajarFin)
	movwf	PCLATH
	goto	sdoBajarFin
ENDIF

	ENDM
	
	
;<<<< appObjetoM2 >>>>

appObjetoM2	macro numObjeto, tipo, flagReg, flagBit, file1, file2

; numObjeto -> para generar etiqueta appObjeto<numObjeto>, p.e. appObjeto0
; tipo -> RO | RW , si RO no se genera codigo que escribe el registro
; file1 -> registros que implementan el objeto
; file2 ->
; flag -> bit que implementa el flag de nuevo dato. 

appObjeto#v(numObjeto)
 ;se trata de manejar un PDO o un SDO??
 btfsc	sdoEstado, 3	;bit a 0 => PDO
 goto	appObjeto#v(numObjeto)_SDO
	
appObjeto#v(numObjeto)_PDO
 ;se ha recibido un PDO o hay que enviarlo
 btfsc	sdoEstado, 2	;bit a 0 => hay que enviarlo
 goto	appObjeto#v(numObjeto)_PDO_recibir	

appObjeto#v(numObjeto)_PDO_enviar
	;volcar el valor del objeto al buffer al que apunta el FSR
	; y actualizar FSR
	movf	file1, w
	movwf	INDF	
	incf	FSR, f
	movf	file2, w
	movwf	INDF	
	incf	FSR, f
		
	btfsc	flagReg, flagBit
	bsf	pdoFlags,0
	bcf	flagReg, flagBit

	;terminar en 
	movlw	high(pdoTxFin)
	movwf	PCLATH
	goto	pdoTxFin

appObjeto#v(numObjeto)_PDO_recibir
IF tipo
	;tomar el valor del objeto desde el buffer al que apunta FSR
	; y actualizar FSR
	movf	INDF, w
	movwf	file1
	incf	FSR, f
	movf	INDF, w
	movwf	file2
	incf	FSR, f	

	;terminar en 
	movlw	high(pdoRxFin)
	movwf	PCLATH
	goto	pdoRxFin
ENDIF

		
appObjeto#v(numObjeto)_SDO
 ;se está subiendo o bajando el objeto
 btfsc	sdoEstado, 2	;bit a 0 => se está subiendo
 goto	appObjeto#v(numObjeto)_SDO_bajar

appObjeto#v(numObjeto)_SDO_subir
	;volcar el valor del objeto a sdoBuffer
	movf	file1, w	 
	movwf	sdoBuffer 	
	movf	file2, w	 
	movwf	sdoBuffer+1	
	
	;terminar en
	goto	appIsrFin
	
appObjeto#v(numObjeto)_SDO_bajar
IF tipo
	;volcar el valor del objeto desde sdoBuffer
	movf	sdoBuffer, w	
	movwf   file1	
	movf	sdoBuffer+1, w	
	movwf   file2
	
	;terminar en 
	movlw	high(sdoBajarFin)
	movwf	PCLATH
	goto	sdoBajarFin
ENDIF

	ENDM

;<<<< appObjetoM4 >>>>

appObjetoM4	macro numObjeto, tipo, flagReg, flagBit, file1, file2, file3, file4

; numObjeto -> para generar etiqueta appObjeto<numObjeto>, p.e. appObjeto0
; tipo -> RO | RW , si RO no se genera codigo que escribe el registro
; file1 -> registros que implementan el objeto
; ...
; file4 ->
; flag -> bit que implementa el flag de nuevo dato. 

appObjeto#v(numObjeto)
 ;se trata de manejar un PDO o un SDO??
 btfsc	sdoEstado, 3	;bit a 0 => PDO
 goto	appObjeto#v(numObjeto)_SDO
	
appObjeto#v(numObjeto)_PDO
 ;se ha recibido un PDO o hay que enviarlo
 btfsc	sdoEstado, 2	;bit a 0 => hay que enviarlo
 goto	appObjeto#v(numObjeto)_PDO_recibir	

appObjeto#v(numObjeto)_PDO_enviar
	;volcar el valor del objeto al buffer al que apunta el FSR
	; y actualizar FSR
	movf	file1, w
	movwf	INDF	
	incf	FSR, f
	movf	file2, w
	movwf	INDF	
	incf	FSR, f
	movf	file3, w
	movwf	INDF	
	incf	FSR, f
	movf	file4, w
	movwf	INDF	
	incf	FSR, f
		
	btfsc	flagReg, flagBit
	bsf	pdoFlags,0
	bcf	flagReg, flagBit

	;terminar en 
	movlw	high(pdoTxFin)
	movwf	PCLATH
	goto	pdoTxFin

appObjeto#v(numObjeto)_PDO_recibir
IF tipo
	;tomar el valor del objeto desde el buffer al que apunta FSR
	; y actualizar FSR
	movf	INDF, w
	movwf	file1
	incf	FSR, f
	movf	INDF, w
	movwf	file2
	incf	FSR, f	
	movf	INDF, w
	movwf	file3
	incf	FSR, f
	movf	INDF, w
	movwf	file4
	incf	FSR, f

	;terminar en 
	movlw	high(pdoRxFin)
	movwf	PCLATH
	goto	pdoRxFin
ENDIF

		
appObjeto#v(numObjeto)_SDO
 ;se está subiendo o bajando el objeto
 btfsc	sdoEstado, 2	;bit a 0 => se está subiendo
 goto	appObjeto#v(numObjeto)_SDO_bajar

appObjeto#v(numObjeto)_SDO_subir
	;volcar el valor del objeto a sdoBuffer
	movf	file1, w	 
	movwf	sdoBuffer 	
	movf	file2, w	 
	movwf	sdoBuffer+1 	
	movf	file3, w	 
	movwf	sdoBuffer+2	
	movf	file4, w	 
	movwf	sdoBuffer+3
	
	;terminar en
	goto	appIsrFin
	
appObjeto#v(numObjeto)_SDO_bajar
IF tipo
	;volcar el valor del objeto desde sdoBuffer
	movf	sdoBuffer, w	
	movwf   file1	
	movf	sdoBuffer+1, w	
	movwf   file2
	movf	sdoBuffer+2, w	
	movwf   file3	
	movf	sdoBuffer+3, w	
	movwf   file4
	
	;terminar en 
	movlw	high(sdoBajarFin)
	movwf	PCLATH
	goto	sdoBajarFin
ENDIF

	ENDM


; ==== HEAD ====


;<<<< appVectores>>>>
appVectores
	goto	appReset		; 0
	goto	appIsr			; 1
	goto	appEntrada		; 2
	goto	appPdoTablaPorDefecto	; 3
	nop				; 4
	goto appSdoSubirTipoDispositivo	  ; 5	
	goto appSdoSubirVersionSoftware	  ; 6
	goto appSdoSubirNombreDispositivo ; 7
	goto	appNumeroObjetos	; 8
	goto    appParar		; 9
	nop				;10	
	nop				;11

  variable cuenta
  cuenta set 0x1f
  while cuenta < 0x3E
   if cuenta <= (0x1f+numeroObjetos-1)
		goto	appObjeto#v(cuenta)
   else
   	nop
   endif
   cuenta++
  endw

	GLOBAL	appVectores

;<<<< >>>>
appNumeroObjetos
	retlw	numeroObjetos

;<<<< >>>>
appSdoSubirTipoDispositivo
	addwf	PCL, f		; saltar al offset indicado por el acumulador
	dt	tipoDispositivo, '\n'

;<<<< >>>>
appSdoSubirVersionSoftware
	addwf	PCL, f		; saltar al offset indicado por el acumulador
	dt	versionSoftware, '\n'

;<<<< >>>>	
appSdoSubirNombreDispositivo
	addwf	PCL,f		; saltar al offset indicado por el acumulador
	dt	nombreDispositivo, '\n'

list
