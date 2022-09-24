;------------------------------------------------------------------------------
; I2C Addresses & Equates
;------------------------------------------------------------------------------
I2C_PIN:		EQU		%10000000
I2C_ESO:		EQU		%01000000

I2C_STO:		EQU		%00000001
I2C_ACK:		EQU		%00000001

I2C_DAT:		EQU		$40				; PCF8584 Data/S0 Register
I2C_CSR:		EQU		$41				; PCF8584 S1 & others

VIA_PORTB:		EQU		$20				; PORT B
VIA_DDRB:		EQU		$22				; VIA DDRB

I2C_RESET:		EQU     %01000000		; BIT 6 on PORTB will be used for
                                        ; the reset line on the PCF8584

LCD_ADDR:       EQU     $27
LCD_RS:         EQU     %00000001
LCD_RW:         EQU     %00000010
LCD_EN:         EQU     %00000100
LCD_BT:         EQU     %00001000

    ORG		    $8000
    ;ORG         $0100

I2C_TEST:
    ; Initialise VIA Port B - Set I2C_RESET line as output.
    LD		A,I2C_RESET
    OUT		(VIA_DDRB),A

    ; Perform reset on PCF8584
    LD		A,$00
    OUT		(VIA_PORTB),A ; Bring RESET LOW
    LD		BC,$0020
    CALL	PAUSE_LOOP
    LD		A,I2C_RESET
    OUT		(VIA_PORTB),A ; Bring RESET HIGH

    ; Initialise PCF8584
    CALL	i2c_init
    
    CALL    lcd_init

    LD      HL,message
    CALL    send_lcd_message

    RET

message:
            ;12345678901234567890
    DB      "Welcome to the LCD  "    ; line 1
    DB      "Here we use a PCF-  "    ; line 3
    DB      "on the RC2014 Pro.  "    ; line 2
    DB      "8584 to drive I2C.  "    ; line 4
    DB      0


    INCLUDE "lib_pcf8584.asm"
    INCLUDE "lib_pcf8584_lcd.asm"