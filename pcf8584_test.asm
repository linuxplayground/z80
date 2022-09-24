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

    ORG		$8000

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
	
	; Test delay to allow PCF8584 to sort itself out
	LD		BC,$0200
	CALL	PAUSE_LOOP

	; Transmit
	CALL	i2c_bus_rdy	; Wait for I2C bus ready

	; set 'slave address'
	LD		A,$40		; (20 shifted to Write = 40) - PCF8574 Slave.
	OUT		(I2C_DAT),A ; Set 40H as slave address
	LD		A,$C5
	OUT		(I2C_CSR),A ; Load C5H into S1 register, making PCF8584 generate
						; 'START' condition and clocks out the slave address
						; and the clock pulse for the slave acknowledgement.
						; Next byte(s) sent to S0 register will be
						; immediately transfferred over the I2C-bus.
	
	CALL 	i2c_rdy 	; Wait for the Tx/Rx to complete
	LD		A,$aa 		; test byte pattern 1
	OUT 	(I2C_DAT),A

	CALL 	i2c_rdy 	; Wait for the Tx/Rx to complete
	LD		A,$55 		; test byte pattern 2
	OUT		(I2C_DAT),A
	
	CALL 	i2c_rdy 	; Wait for the Tx/Rx to complete
	LD    	A,$46		; test byte pattern 3
	OUT		(I2C_DAT),A
	
	CALL 	i2c_rdy 	; Wait for the Tx/Rx to complete
	LD		A,$00
	OUT		(I2C_DAT),A ; Send dummy byte - otherwise stop condition is
						; not sent.
	LD		A,$C3
	OUT		(I2C_CSR),A	; Send 'STOP signal to PCF8584

	RET

    INCLUDE "lib_pcf8584.asm"