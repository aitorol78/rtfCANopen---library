; SDO.H


; rutinas que se encargan de procesar los SDOs
;
; el archivo sdo.asm hay que añadirlo al proyecto
; este archivo, sdo.h, hay que incluirlo en los archivos que hagan
; referencia a rutinas sdoXXX

	nolist

; Aitor Olarra
; 9-8-00

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

; == Extern =========================================================

	EXTERN	sdoObjeto, sdoEstado
	EXTERN 	sdoEntrada, sdoInicio
	EXTERN	sdoBajarFin
	EXTERN	sdoBuffer, sdoNumBytes
	
; == Define =========================================================

#define numeroObjetosSistema	0x1f ;(31 en decimal)

	list
