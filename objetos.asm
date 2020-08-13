;OBJETOS.ASM

;Este archivo contiene las tablas que definen las entradas al 
; diccionario de objetos de CANopen.

;Aitor Olarra
;24-10-00

;== Include y define ==================================

#include<p16f873.inc>
#define OBJETOS
#include<canopen.h>

#define	RO 0x80		; Read Only, en appSdoTablaPropiedades
#define RW 0x00		; Read/Write, ...
#define	NO_MAP 0x40	; no se puede mapear, en appSdoTablaPropiedades
#define	SI_MAP 0x00	; si se puede mapear, ...

;== Tablas ============================================

appTablas1	CODE

;<<<< appSdoTablaIndexHigh >>>>
;los appSdoTablaXXX definen los objetos del diccionario de objetos
;de CANopen que están implementados y sus características:
; - indice, 256*IndexHigh + IndexLow
; - subíndice, SubIndex
; - si se pueden escribir, Propiedades<7>=0 -> se puede escribir
;					  1 -> no se puede escribir
; - si se pueden mapear,   Propiedades<6>=0 -> se puede mapear
;					  1 -> no se puede mapear 
; - numero de bytes, Propiedades<6..0>

; Organización: el indice, subindice o propiedades de un objeto se 
; obtienen escribiendo en la vble sdoObjeto el número de objeto, 
; comprendido entre 0 y NumeroDeObjetos , y llamando a la función 
; correspondiente.

appSdoTablaIndexHigh
	movf	sdoObjeto, w
	addwf	PCL, f

	;objetos del 'sistema' (NO CAMBIAR)
	retlw	0x10	;  0   device type				
	retlw	0x10	;  1   error register				
	retlw	0x10	;  2   nombre dispositivo			
	retlw	0x10	;  3   version software
	retlw	0x14	;  4   PDO1RX (Communication parameters)
	retlw	0x14	;  5    COB-ID
	retlw	0x14	;  6   PDO2RX (Communication parameters)
	retlw	0x14	;  7    COB-ID
	retlw	0x16	;  8   PDO1RX (Mapping parameters)
	retlw	0x16	;  9    objetos mapeados
	retlw	0x16	; 10   PDO2RX (Mapping parameters)
	retlw	0x16	; 11    objetos mapeados
	retlw	0x18	; 12   PDO1TX (Communication parameters)
	retlw	0x18	; 13    COB-ID
	retlw	0x18	; 14    tipo tx
	retlw	0x18	; 15   PDO2TX (Communication parameters)
	retlw	0x18	; 16    COB-ID
	retlw	0x18	; 17    tipo tx
	retlw	0x1a	; 18   PDO1TX (Mapping parameters)
	retlw	0x1a	; 19    objetos mapeados
	retlw	0x1a	; 20   PDO2TX (Mapping parameters)
	retlw	0x1a	; 21    objetos mapeados
	retlw   0x1f	; 22   Download program data
	retlw   0x1f	; 23    program number 1
	retlw   0x1f	; 24   Program control
	retlw   0x1f	; 25 	program number 1
	retlw   0x10	; 26 RESERVADO	
	retlw   0x10	; 27 RESERVADO	
	retlw   0x10	; 28 RESERVADO	
	retlw   0x10	; 29 RESERVADO	
	retlw   0x10	; 30 RESERVADO	

	;resto de objetos, específicos de la aplicación (MODIFICABLE)
	retlw	0x20	; 31   IR1

appTablas2	CODE

;<<<< appSdoTablaIndexLow >>>>

appSdoTablaIndexLow
	movf	sdoObjeto, w
	addwf	PCL, f

	;objetos del 'sistema' (NO CAMBIAR)
	retlw	0x00	;device type				
	retlw	0x01	;error register				
	retlw	0x08	;nombre dispositivo			
	retlw	0x0a	;version software
	retlw	0x00	;PDO1RX (Communication parameters)
	retlw	0x00	; COB-ID
	retlw	0x01	;PDO2RX (Communication parameters)
	retlw	0x01	; COB-ID
	retlw	0x00	;PDO1RX (Mapping parameters)
	retlw	0x00	; objetos mapeados
	retlw	0x01	;PDO2RX (Mapping parameters)
	retlw	0x01	; objetos mapeados
	retlw	0x00	;PDO1TX (Communication parameters)
	retlw	0x00	; COB-ID
	retlw	0x00	; tipo tx
	retlw	0x01	;PDO2TX (Communication parameters)
	retlw	0x01	; COB-ID
	retlw	0x01	; tipo tx
	retlw	0x00	;PDO1TX (Mapping parameters)
	retlw	0x00	; objetos mapeados
	retlw	0x01	;PDO2TX (Mapping parameters)
	retlw	0x01	; objetos mapeados
	retlw   0x50	;Download program data
	retlw   0x50	; program number 1	
	retlw   0x51	;Program control
	retlw   0x51	; program number 1
	retlw   0x00	; 26 RESERVADO	
	retlw   0x00	; 27 RESERVADO	
	retlw   0x00	; 28 RESERVADO	
	retlw   0x00	; 29 RESERVADO	
	retlw   0x00	; 30 RESERVADO	
	
	;resto de objetos, específicos de la aplicación
	retlw	0x00	;   IR1

appTablas3	CODE

;<<<< appSdoTablaSubIndex >>>>

appSdoTablaSubIndex
	movf	sdoObjeto, w
	addwf	PCL, f

	;objetos del 'sistema' (NO CAMBIAR)
	retlw	0x00	;device type				
	retlw	0x00	;error register				
	retlw	0x00	;nombre dispositivo			
	retlw	0x00	;version software
	retlw	0x00	;PDO1RX (Communication parameters)
	retlw	0x01	; COB-ID
	retlw	0x00	;PDO2RX (Communication parameters)
	retlw	0x01	; COB-ID
	retlw	0x00	;PDO1RX (Mapping parameters)
	retlw	0x88    ; objetos mapeados
	retlw	0x00	;PDO2RX (Mapping parameters)
	retlw	0x88	; objetos mapeados
	retlw	0x00	;PDO1TX (Communication parameters)
	retlw	0x01	; COB-ID
	retlw	0x02	; tipo tx
	retlw	0x00	;PDO2TX (Communication parameters)
	retlw	0x01	; COB-ID
	retlw	0x02	; tipo tx
	retlw	0x00	;PDO1TX (Mapping parameters)
	retlw	0x88	; objetos mapeados
	retlw	0x00	;PDO2TX (Mapping parameters)
	retlw	0x88	; objetos mapeados
	retlw   0x00	;Download program data
	retlw   0x01	; program number 1
	retlw   0x00	;Program control
	retlw   0x01	; program number 1
	retlw   0x00	; 26 RESERVADO	
	retlw   0x00	; 27 RESERVADO	
	retlw   0x00	; 28 RESERVADO	
	retlw   0x00	; 29 RESERVADO	
	retlw   0x00	; 30 RESERVADO	
	
	;resto de objetos, específicos de la aplicación
	retlw	0x00	;   IR1

appTablas4	CODE

;<<<< appSdoTablaPropiedades >>>>

appSdoTablaPropiedades
	movf	sdoObjeto, w
	addwf	PCL, f

	;objetos del 'sistema' (NO CAMBIAR)
	retlw	RO | NO_MAP | 0x04	;device type				
	retlw	RO | NO_MAP | 0x01	;error register				
	retlw	RO | NO_MAP | 0x0c	;nombre dispositivo	(CAMBIAR)		
	retlw	RO | NO_MAP | 0x04	;version software	(CAMBIAR)
	retlw	RO | NO_MAP | 0x01	;PDO1RX (Communication parameters)
	retlw	RW | NO_MAP | 0x04	; COB-ID
	retlw	RO | NO_MAP | 0x01	;PDO2RX (Communication parameters)
	retlw	RW | NO_MAP | 0x04	; COB-ID
	retlw	RW | NO_MAP | 0x01	;PDO1RX (Mapping parameters)
	retlw	RW | NO_MAP | 0x04	; objetos mapeados
	retlw	RW | NO_MAP | 0x01	;PDO2RX (Mapping parameters)
	retlw	RW | NO_MAP | 0x04	; objetos mapeados
	retlw	RO | NO_MAP | 0x02	;PDO1TX (Communication parameters)
	retlw	RW | NO_MAP | 0x04	; COB-ID
	retlw	RW | NO_MAP | 0x01	; tipo tx
	retlw	RO | NO_MAP | 0x02	;PDO2TX (Communication parameters)
	retlw	RW | NO_MAP | 0x04	; COB-ID
	retlw	RW | NO_MAP | 0x01	; tipo tx
	retlw	RW | NO_MAP | 0x01	;PDO1TX (Mapping parameters)
	retlw	RW | NO_MAP | 0x04	; objetos mapeados
	retlw	RW | NO_MAP | 0x01	;PDO2TX (Mapping parameters)
	retlw	RW | NO_MAP | 0x04	; objetos mapeados
	retlw	RO | NO_MAP | 0x01	;Download program data
	retlw	RW | NO_MAP | 0x00	; program number 1 (num_bytes = 0 está bien)
	retlw	RO | NO_MAP | 0x01	;Program control
	retlw	RO | NO_MAP | 0x01	; program number 1
	retlw	RO | NO_MAP | 0x04	; 27 RESERVADO 
	retlw	RO | NO_MAP | 0x04	; 28 RESERVADO 
	retlw	RO | NO_MAP | 0x04	; 29 RESERVADO 
	retlw	RO | NO_MAP | 0x04	; 30 RESERVADO 
	retlw	RO | NO_MAP | 0x04	; 31 RESERVADO 
	
	;resto de objetos, específicos de la aplicación (MODIFICABLE)
	retlw	RO | SI_MAP | 0x04	;  
	

	GLOBAL appSdoTablaIndexHigh, appSdoTablaIndexLow, appSdoTablaSubIndex
	GLOBAL appSdoTablaPropiedades

	END
