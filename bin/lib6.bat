del *.o

mpasm /e- /l- /q+ /x- /c+ /p16f876 /o+ spi.asm
mpasm /e- /l- /q+ /x- /c+ /p16f876 /o+ eeprom.asm
mpasm /e- /l- /q+ /x- /c+ /p16f876 /o+ isr.asm
mpasm /e- /l- /q+ /x- /c+ /p16f876 /o+ nmt.asm
mpasm /e- /l- /q+ /x- /c+ /p16f876 /o+ pdo.asm
mpasm /e- /l- /q+ /x- /c+ /p16f876 /o+ sdo.asm

mplib /c CANopen6.lib spi.o eeprom.o isr.o nmt.o sdo.o pdo.o 
