; APP.ASM

; Aitor Olarra
; 27-2-01

;=============================== Include ========
#include<p16f873.inc>
#include<canopen.h>

;=============================== Define =========

#define numeroObjetos 0
#define tipoDispositivo "\x00\x00\x00\x00"
#define versionSoftware	""	; ejemplo "VER_SOFT_0.4"
#define nombreDispositivo ""	; ejemplo "IR_BUMPER"

;=============================== Variables ======

appData	UDATA



;=============================== Codigo =========
appCode	CODE
	
#include<cabecera.inc>

;<<<< appReset >>>>
appReset
	;termina en 
	return

;<<<< appIsr >>>>
appIsr
	;termina en 
appIsrFin
	movlw	high(isrFin)
	movwf	PCLATH
	goto	isrFin

;<<<< appEntrada >>>>
appEntrada
	;es un bucle infinito
	goto	appEntrada
	
;<<<< appParar >>>>
appParar
	;termina en
	return

;<<<< appPdoTablaPorDefecto >>>>

appPdoTablaPorDefecto
	addwf	PCL, f
	
	; PDO1 de recepcion
	retlw	0x40		;IDH	(no cambiar)
	retlw	0x00		;IDL	(no cambiar)
	retlw	0x00		;TxType	(no cambiar)
	retlw	0xff		;el mapping (appObjeto0 -> 0x1f)
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff		; res	(no cambiar)
	
	; PDO2 de recepcion
	retlw	0x60		;IDH	(no cambiar)
	retlw	0x00		;IDL	(no cambiar)
	retlw	0x00		;TxType	(no cambiar)
	retlw	0xff		;el mapping (appObjeto0 -> 0x1f)
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff		; res	(no cambiar)

	; PDO1 de transmision
	retlw	0x30		;IDH	(no cambiar)
	retlw	0x00		;IDL	(no cambiar)
	retlw	0x00		;TxType
	retlw	0xff		;el mapping (appObjeto0 -> 0x1f)
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff		; res	(no cambiar)
	
	; PDO2 de transmision
	retlw	0x50		;IDH	(no cambiar)
	retlw	0x00		;IDL	(no cambiar)
	retlw	0x00		;TxType
	retlw	0xff		;el mapping (appObjeto0 -> 0x1f)
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff
	retlw	0xff		; res	(no cambiar)

	;VALIDRTR
	retlw	NO_RX1 | NO_RX2 | NO_TX1 | NO_TX2

;<<<< appObjetos >>>>
;appObjetoM4	0, RO, appFlags, 0, Sharp_IR0, Sharp_IR1, Sharp_IR2, Sharp_IR3
;appObjetoM4	1, RO, appFlags, 0, appBuf, appBuf+1, appBuf+2, appBuf+3
;appObjetoM1	0, RO, appFlags, 0, Sharp_IR0
;appObjetoM1	1, RO, appFlags, 0, appBuf

;*************************************************************


	END
