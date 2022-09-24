;------------------------------------------------------------------------------
; i2c_init
;
; Initialise the PCF8584 I2C interface
; Created from Fig.5 PCF8584 Initialization Sequence, page 15 of PCF8584 datasheet.
;------------------------------------------------------------------------------
i2c_init:
    PUSH	AF
    PUSH	BC
    LD		A,I2C_PIN
    OUT		(I2C_CSR),A	; Load 80H into S1 register (soft reset - PIN HIGH)
    LD		A,55H
    OUT		(I2C_DAT),A	; Load 55H into S0' register (AAh slave address due to bit offset in S0)
    LD		A,0A0H
    OUT		(I2C_CSR),A	; Load A0H into S1 register to access S2 Clock Register
    LD		A,18H
    OUT		(I2C_DAT),A	; Load 18H into S2 register (clock control - 8 MHz, 90 KHz)
    LD		A,0C1H		; which should give 45 KHz I2C speed due to 4 MHz system clock.
    OUT		(I2C_CSR),A	; Load C1H into S1 register; enable serial interace,
                        ; set I2C bus idle, SDA & SCL HIGH. Next RD/WR operation will
                        ; be to/from data transfer register S0 if A0 = LOW.
    LD		BC,$f000
    CALL	PAUSE_LOOP	; 0.5 second delay to synchronise BB-bit
    POP		BC
    POP		AF
    RET

;------------------------------------------------------------------------------
; i2c_bus_rdy
;
; Waits until the I2C bus is free before RETurning
;------------------------------------------------------------------------------
i2c_bus_rdy:
    PUSH	AF
i2c_blp:
    IN		A,(I2C_CSR)	; Read byte from S1 register
    BIT		0,A			; Is bus free? (S1 ~BB=1?)
    JR		Z,i2c_blp	; 	No - loop
i2cblpex:
    POP		AF
    RET

;------------------------------------------------------------------------------
; i2c_rdy
;
; Waits until the PCF8584 signals a byte transmission/reception is complete.
;------------------------------------------------------------------------------
i2c_rdy:
    PUSH	AF
i2c_rlp:
    IN		A,(I2C_CSR)	; Read byte from S1 register
    BIT		7,A			; Is Tx/Rx complete? (S1 PIN=0?)
    JR		NZ,i2c_rlp	; 	No - loop
i2crlpex:
    POP		AF
    RET

;---------------------------------------------------------------------------
; Send a start condition and address for read or write operation.
; Carry is 1 for write, 0 for read.
; Clobbers A
;---------------------------------------------------------------------------
i2c_start:
    LD      A,LCD_ADDR
    RLCA
    OUT     (I2C_DAT),A
    LD      A,$C5
    OUT     (I2C_CSR),A
    RET
;---------------------------------------------------------------------------
; Send a stop condition, includes dummy byte.
; Clobbers A
;---------------------------------------------------------------------------
i2c_stop:
    CALL 	i2c_rdy 	; Wait for the Tx/Rx to complete
    LD		A,$00
    OUT		(I2C_DAT),A ; Send dummy byte - otherwise stop condition is
                        ; not sent.
    LD		A,$C3
    OUT		(I2C_CSR),A	; Send 'STOP signal to PCF8584
    RET

;------------------------------------------------------------------------------				 
; PAUSE_LOOP
;
; Timer function
;
; 16-bit (BC) decrement counter, performing 4xNEG loop until BC
; reaches zero.
;
; 61 T-states in loop = 15.25uS per loop @ 4 MHz - near enough
; a second delay for 65,535 iterations.
;
; Set iteration count in BC before calling this function.
; Destroys: BC
;------------------------------------------------------------------------------
PAUSE_LOOP:
    PUSH	AF							; 11 T-states
pau_lp:
    NEG									; 8 T-states
    NEG									; 8 T-states
    NEG									; 8 T-states
    NEG									; 8 T-states
    DEC		BC							; 6 T-states
    LD		A,C							; 9 T-states
    OR		B							; 4 T-states
    JP		NZ,pau_lp					; 10 T-states
    POP		AF							; 10 T-states
    RET									; Pause complete, RETurn