; PDO.H

	nolist
; rutinas que se encargan de procesar los PDOs
;
; el archivo pdo.asm hay que añadirlo al proyecto
; este archivo, pdo.h, hay que incluirlo en los archivos que hagan
; referencia a rutinas o variables pdoXXX

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

; == Extern =========================================================

	EXTERN 	pdoRx1, pdoRx2, pdoTx1, pdoTx2, pdoSYNC
	EXTERN	pdoContSync1, pdoContSync2
	EXTERN  pdoTipoTx1, pdoTipoTx2
	EXTERN	pdoSaltoAObjetos
	EXTERN	pdoRxFin, pdoTxFin
	EXTERN  pdoNumBytes, pdoVALIDRTR
	EXTERN  pdoPrioridadTx
	EXTERN  pdoFlags
	EXTERN	pdoInicio

	list
