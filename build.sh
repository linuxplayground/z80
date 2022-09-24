rm -f *.bin
#z80asm -o pcf8584_test.bin pcf8584_test.asm && bin2hex.py --offset=0x8000 pcf8584_test.bin
z80asm -o lcd.bin pcf8584_lcd.asm && bin2hex.py --offset=0x8000 lcd.bin
