; SPI.ASM

; macros, subrutinas y variables para acceder a los registros del MCP2510
;
; es ../spi.04/spi.inc modificado para generar codigo objeto.
; 
; spi.h se incluye en el arcivo donde se utilizan las macros
; spi.asm se añade al proyecto como un archivo más 


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


; ==  Include y Define ========================================================

#include<p16f873.inc>

#define	spiBanco STATUS,RP0
#define	spiCs	PORTB,1

; == variables ======================================================

spiData	UDATA
spiTemp1	res 1
spiBuf		res 0
spiBufCTRL	res 1
spiBufSIDH	res 1
spiBufSIDL	res 1
spiBufD0	res 1
spiBufD1	res 1
spiBufD2	res 1
spiBufD3	res 1
spiBufD4	res 1
spiBufD5	res 1
spiBufD6	res 1
spiBufD7	res 1

	GLOBAL	spiBuf, spiBufCTRL, spiBufSIDH, spiBufSIDL, spiBufD0
	GLOBAL  spiBufD1, spiBufD2, spiBufD3, spiBufD4, spiBufD5
	GLOBAL  spiBufD6, spiBufD7, spiTemp1
	

; == codigo =========================================================

spiCode	CODE

;<<<< spiOutput >>>>

spiOutput
	bcf	spiBanco
	movwf	SSPBUF
spiOut1	bsf	spiBanco
	btfss	SSPSTAT,BF
	goto	spiOut1
	bcf	spiBanco
	movf	SSPBUF, w
	return

;<<<< spiDelayReset >>>>

spiDelayReset
	movlw	0x80	
	movwf	spiBuf
spiDR1	decf	spiBuf, f
	btfss	STATUS,Z
	goto	spiDR1
	return	
	
;<<<< spiWriteBuffer >>>>
; spiTemp1: buffer = TXB0DLC | TXB1DLC | TXB2DLC

spiWriteBuffer	
	bcf	spiCs
	movlw	b'00000010'
	call	spiOutput
	movf	spiTemp1, w
	call	spiOutput
	movf	spiBufSIDL, w
	andlw	0x0f
	call	spiOutput
	movf	spiBufD0, w
	call	spiOutput
	movf	spiBufD1, w
	call	spiOutput
	movf	spiBufD2, w
	call	spiOutput
	movf	spiBufD3, w
	call	spiOutput
	movf	spiBufD4, w
	call	spiOutput
	movf	spiBufD5, w
	call	spiOutput
	movf	spiBufD6, w
	call	spiOutput
	movf	spiBufD7, w
	call	spiOutput
	bsf	spiCs
	return

	GLOBAL	spiOutput, spiDelayReset, spiWriteBuffer

; == CODIGO REPETIDO EN PAGINA 1 ====================================

spiCode2	CODE

;<<<< spiOutput_p1 >>>>

spiOutput_p1
	bcf	spiBanco
	movwf	SSPBUF
spiOut1_p1
	bsf	spiBanco
	btfss	SSPSTAT,BF
	goto	spiOut1_p1
	bcf	spiBanco
	movf	SSPBUF, w
	return

;<<<< spiDelayReset_p1 >>>>

spiDelayReset_p1
	movlw	0x80	
	movwf	spiBuf
spiDR1_p1
	decf	spiBuf, f
	btfss	STATUS,Z
	goto	spiDR1_p1
	return	

	END


