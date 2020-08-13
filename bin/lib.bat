del *.o 

mpasm /e- /l- /q+ /x- /c+ /p16f873 /o+ spi.asm
mpasm /e- /l- /q+ /x- /c+ /p16f873 /o+ eeprom.asm
mpasm /e- /l- /q+ /x- /c+ /p16f873 /o+ isr.asm
mpasm /e- /l- /q+ /x- /c+ /p16f873 /o+ nmt.asm
mpasm /e- /l- /q+ /x- /c+ /p16f873 /o+ pdo.asm
mpasm /e- /l- /q+ /x- /c+ /p16f873 /o+ sdo.asm

mplib /c CANopen.lib spi.o eeprom.o isr.o nmt.o sdo.o pdo.o 
