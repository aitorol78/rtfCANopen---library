
               University of the Bask Country

This project is still under development, although it already
works fine well, most errors has been corrected.

This is the first release, CANopen1.0

List of files:
	APP.ASM		--> template file to write the application code
	OBJETOS.ASM	--> template file to write the application code
	CABECERA.INC	--> is included in APP.ASM
	CANOPEN.H	--> is included in APP.ASM
	CANOPEN.LIB	--> CANopen library to be included in MPLAB projects
	CANOPEN.LKR	--> linker file, to be included in MPLAB projects
	CANOPEN6.LKR	--> linker file, (if you use the 16F876 instead of the 16F873)
	README.TXT	--> this file

	[DOC]
	Descripcion libreria CANopen para PIC.doc
	Descripcion del hardware de los nodos.doc

	[FONTS]
	LIB.BAT		--> compile *.asm files and make library
	LIB6.BAT	--> same as LIB.BAT, for PIC16F876 
	LIB20.BAT	--> same as LIB.BAT, for PIC16F873 with 20MHz Xtal
	PIC16F873.INC	--> register definition PIC16F873 (WREN definition corrected)
	PIC16F876.INC	--> register definition PIC16F876
	EEPROM.ASM
	EEPROM.H
	ISR.ASM
	ISR.H
	NMT.ASM
	NMT20.ASM
	NMT.H
	PDO.ASM
	PDO.H
	SDO.ASM
	SDO.H
	SPI.ASM
	SPI.H
	MCP2510.H
	EXT.H
	