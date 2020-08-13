del *.o 

mpasm /e- /l- /q+ /x- /c+ /p16f873 /o+ spi.asm
mpasm /e- /l- /q+ /x- /c+ /p16f873 /o+ eeprom.asm
mpasm /e- /l- /q+ /x- /c+ /p16f873 /o+ isr.asm
mpasm /e- /l- /q+ /x- /c+ /p16f873 /o+ nmt_20.asm
mpasm /e- /l- /q+ /x- /c+ /p16f873 /o+ pdo.asm
mpasm /e- /l- /q+ /x- /c+ /p16f873 /o+ sdo.asm

mplib /c CANopen_20.lib spi.o eeprom.o isr.o nmt_20.o sdo.o pdo.o 
