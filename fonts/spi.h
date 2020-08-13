; SPI.H

; macros, subrutinas y variables para acceder a los registros del MCP2510
;
	nolist
	
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


; == Include y Define ===============================================

	list
#include<mcp2510.h>
	nolist

#define SPI
	
#define	spiBanco STATUS,RP0
#define	spiCs	PORTB,1

; == Extern =========================================================
	
	; variables
	EXTERN	spiBuf, spiBufCTRL, spiBufSIDH, spiBufSIDL, spiBufD0
	EXTERN  spiBufD1, spiBufD2, spiBufD3, spiBufD4, spiBufD5
	EXTERN  spiBufD6, spiBufD7, spiTemp1

	; subrutinas
	EXTERN	spiOutput, spiDelayReset, spiWriteBuffer

; == Macros =========================================================

;<<<< spiInicModulo >>>>

spiInicModulo	macro
	bsf	spiBanco
	bcf	TRISC,3		; clk (es una salida)
	bcf	TRISC,5		; sdo (salida tambien)
	bcf	TRISB,1		; /cs (otra salida)
	bsf	TRISC,4		; sdi (una entrada)
	bcf 	spiBanco

	clrf	SSPCON
	movlw	0x30		; SPI master, clk=Fosc/4
	movwf	SSPCON		; clk=1
	endm

;<<<< spiReset >>>>

spiReset	macro
	bcf	spiCs		; pin /cs del MCP = 0
	movlw	b'11000000'	; codigo instruccion reset
	call	spiOutput	; enviarlo
	bsf	spiCs
	call	spiDelayReset	; esperar 
		endm


;<<<< spiEscribir >>>>

spiEscribir	macro	registro, valor
	bcf	spiCs
	movlw	b'00000010'	; instruccion escribir
	call	spiOutput
	movlw	registro	; registro a escribir
	call	spiOutput
	movlw	valor		; valor a escribir
	call	spiOutput
	bsf	spiCs
	endm


;<<<< spiLeer >>>>

spiLeer	macro	registro
	bcf	spiCs
	movlw	b'00000011'	; instrucion leer
	call 	spiOutput
	movlw	registro	; registro a leer
	call	spiOutput
	call	spiOutput	; enviar algo/recibir el contenido del registro
	bsf	spiCs
	endm

;<<<< spiModBit >>>>

spiModBit macro	registro, mascara, valor
	bcf	spiCs
	movlw	b'00000101'	; instruccion modificar bit
	call	spiOutput
	movlw	registro
	call	spiOutput
	movlw	mascara
	call	spiOutput
	movlw	valor
	call	spiOutput
	bsf	spiCs
	endm

;<<<< spiModBitF >>>>

spiModBitF	 macro	registro, mascara, file
	bcf	spiCs
	movlw	b'00000101'	; instruccion modificar bit
	call	spiOutput
	movlw	registro
	call	spiOutput
	movlw	mascara
	call	spiOutput
	movf	file, w
	call	spiOutput
	bsf	spiCs
	endm

;<<<< spiEscribirF >>>>
; toma el valor de un registro (F)

spiEscribirF	macro	registro, file
	bcf	spiCs
	movlw	b'00000010'	; instruccion escribir
	call	spiOutput
	movlw	registro	; registro a escribir
	call	spiOutput
	movf	file, W		; valor a escribir
	call	spiOutput
	bsf	spiCs
	endm

;<<<< spiStatus >>>>

spiStatus	macro
	bcf	spiCs
	movlw	b'10100000'	; instruccion leer estado
	call	spiOutput
	call	spiOutput
	bsf	spiCs
	endm

;<<<< spiRts >>>>

spiRts	macro	mensaje
	bcf	spiCs
	movlw	b'10000000' | (mensaje & b'00000111')
	call	spiOutput
	bsf	spiCs
	endm

;<<<< spiRtsF >>>>

spiRtsF	macro	file
	bcf	spiCs
	movlw	b'10000000'
	iorwf	file, w
	call	spiOutput
	bsf	spiCs
	endm

;<<<< spiLeerBuffer >>>>
; buffer = RXB0CTRL | RXB1CTRL

spiLeerBuffer	macro	 buffer
	bcf	spiCs
	movlw	b'00000011'
	call	spiOutput
	movlw	buffer
	call	spiOutput
	call	spiOutput	; leer RXBxCTRL
       if buffer == RXB0CTRL
	andlw	b'11111001'	; borrar los bits de BUKT
       endif
	movwf	spiBufCTRL
	call	spiOutput	; leer RXBxSIDH
	movwf	spiBufSIDH
	call	spiOutput	; leer RXBxSIDL
	andlw	0xf0		; aqui se mete el DLC
	movwf	spiBufSIDL
	call	spiOutput	; leer RXBxEID8
	call	spiOutput	; leer RXBxEID0
	call	spiOutput	; leer RXBxDLC
	andlw	0x0f
	iorwf	spiBufSIDL, f
	call	spiOutput	; leer RXBxD0
	movwf	spiBufD0
	call	spiOutput	; leer RXBxD1
	movwf	spiBufD1
	call	spiOutput	; leer RXBxD2
	movwf	spiBufD2
	call	spiOutput	; leer RXBxD3
	movwf	spiBufD3
	call	spiOutput	; leer RXBxD4
	movwf	spiBufD4
	call	spiOutput	; leer RXBxD5
	movwf	spiBufD5
	call	spiOutput	; leer RXBxD6
	movwf	spiBufD6
	call	spiOutput	; leer RXBxD7
	movwf	spiBufD7
	bsf	spiCs
	endm	

;<<<< spiEscribirBuffer >>>>
; buffer = TXB0DLC | TXB1DLC | TXB2DLC

spiEscribirBuffer	macro	buffer
	movlw	buffer
	movwf	spiTemp1
	call	spiWriteBuffer
	endm
			
	list
