lcd_init:
    ; Test delay to allow PCF8584 to sort itself out
    ; LD		BC,$0200
    ; CALL	PAUSE_LOOP

    ; init LCD into 4 bit mode

    CALL	i2c_bus_rdy	; Wait for I2C bus ready

    LD      A,%11000100 ; func set 8 bits long
    CALL    send_lcd_write_8bit
    LD      A,%11000000 ; func set 8 bits long enable
    CALL    send_lcd_write_8bit
    LD      A,%11000100 ; func set 8 bits long
    CALL    send_lcd_write_8bit
    LD      A,%11000000 ; func set 8 bits long enable
    CALL    send_lcd_write_8bit  

    LD      BC,$0100
    CALL    PAUSE_LOOP  ; pause after each instruction

    LD      A,%11000100 ; func set 8 bits long
    CALL    send_lcd_write_8bit
    LD      A,%11000000 ; func set 8 bits long enable
    CALL    send_lcd_write_8bit  

    LD      A,%00100100 ; func set to 4 bit mode
    CALL    send_lcd_write_8bit
    LD      A,%00100000 ; func set to 4 bit mode enable
    CALL    send_lcd_write_8bit

    LD      A,%00101000 ; 2 lines, 8x5 font
    CALL    send_lcd_write_4bit_instruction

    LD      A,%00001000 ; turn display off
    CALL    send_lcd_write_4bit_instruction

    LD      A,%00000001 ; clear display
    CALL    send_lcd_write_4bit_instruction

    LD      A,%00000010 ; incrment cursor, do not shift display
    CALL    send_lcd_write_4bit_instruction

    LD      A,%00001110 ; turn display on
    CALL    send_lcd_write_4bit_instruction

    RET

send_lcd_message:
    LD      A,(HL)
    OR      A
    JP      Z,.send_lcd_message_done
    CALL    send_lcd_write_4bit_char
    INC     HL
    JP      send_lcd_message
.send_lcd_message_done:
    RET

send_lcd_write_8bit:
    PUSH    AF
    SCF                 ; set carry flag - write mode
    CALL    i2c_start
    CALL 	i2c_rdy 	; Wait for the previous Tx/Rx to complete
    POP     AF
    OUT 	(I2C_DAT),A
    CALL    i2c_stop
    RET

send_lcd_write_4bit_instruction:
    PUSH    AF          ; store the whole byte
    AND     %11110000   ; mask out bottom nibble
    PUSH    AF          ; save the top nibble
    OR      LCD_EN|LCD_BT
    CALL    send_lcd_write_8bit
    POP     AF          ; pull the top nibble
    OR      LCD_BT
    CALL    send_lcd_write_8bit
    ; high nibble done
    POP     AF          ; pull the whole byte
    SLA     A
    SLA     A
    SLA     A
    SLA     A           ; move the bottom nibble into the top nibble
    PUSH    AF          ; store the now top nibble
    OR      LCD_EN|LCD_BT
    CALL    send_lcd_write_8bit
    POP     AF          ; pull the top nibble
    OR      LCD_BT
    CALL    send_lcd_write_8bit

    LD      BC,$0100
    CALL    PAUSE_LOOP  ; do a small delay.
    RET

send_lcd_write_4bit_char:
    PUSH    AF          ; store the whole byte
    AND     %11110000   ; mask out bottom nibble
    PUSH    AF          ; save the top nibble
    OR      LCD_RS|LCD_EN|LCD_BT
    CALL    send_lcd_write_8bit
    POP     AF          ; pull the top nibble
    OR      LCD_RS|LCD_BT
    CALL    send_lcd_write_8bit
    ; high nibble done
    POP     AF          ; pull the whole byte
    SLA     A
    SLA     A
    SLA     A
    SLA     A           ; move the bottom nibble into the top nibble
    PUSH    AF          ; store the now top nibble
    OR      LCD_RS|LCD_EN|LCD_BT
    CALL    send_lcd_write_8bit
    POP     AF          ; pull the top nibble
    OR      LCD_RS|LCD_BT
    CALL    send_lcd_write_8bit

    LD      BC,$0100
    CALL    PAUSE_LOOP  ; do a small delay.
    RET