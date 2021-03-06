
MCAND_HI	EQU	0x00	; high byte of multiplicand (top nibble=0000)
MCAND_LO	EQU	0x42	; low byte of multiplicand 

BCAND_HI	EQU	0x50	; the mcand must be shifted left four bits for
BCAND_LO	EQU	0x51	; booths alg. The code does this automatically
				; and stores the result here

BCAND2X_HI	EQU	0x52	; the mcand must be shifted left four bits for
BCAND2X_LO	EQU	0x53	; booths alg. The code does this automatically

MLIER_HI	EQU	0x00	; high byte of multiplier (top nibble=0000)
MLIER_LO	EQU	0x02	; low byte of multiplier

; Because we're multiplying two 12-bit numbers, the product will fit in a 24-bit
; (3 byte) sum
PR_HI		EQU	R2	; high byte of product storage location
PR_MID		EQU	R1	; mid byte of product sotrage location
PR_LO		EQU	B	; low byte of product storage location

; 3-BIT BOOTH'S ALGORITHM
BOOTHS3:
	MOV	R0,	#12		; this works for up to 12 bits
	MOV	R7,	#0x04		; We need to shift mcand left four bits
	MOV	BCAND_LO,	#MCAND_LO	; load mcand into shifted spots
	MOV	BCAND_HI,	#MCAND_HI
	MOV	PR_HI, 	#0		; clear high byte of output
	MOV	PR_MID,	#MLIER_HI	; move multiplier into low 12b
	MOV	PR_LO, 	#MLIER_LO
SHIFT:
	MOV	C,	F0
	MOV	A,	BCAND_LO	; load low-byte
	RLC	A			; shift left
	MOV	BCAND_LO,	A	; put low byte back
	MOV	A,	BCAND_HI	; load high byte
	RLC	A			; rotate left
	MOV	BCAND_HI,	A	; put high byte back
	DJNZ	R7,	SHIFT		; keep shifting until zero
					; over four bits; this is its counter
	MOV	A,	BCAND_LO
	CLR	C
	RLC	A			; multiply low mcand by 2
	MOV	BCAND2X_LO,	A	; store it for the 2x multiplication
	MOV	A,	BCAND_HI
	RLC	A
	MOV	BCAND2X_HI,	A
B_LOOP:
	MOV 	A,	PR_LO		; pull low byte into accumulator
	RLC	A			; rotate carry into bit 0
	ANL	A,	#0x07		; mask just the last three bits
	JZ	B3_SHFT			; just shift if 000
	CJNE	A,	#0x01,	NOT1 
	SJMP	ADD1X
NOT1:	CJNE	A,	#0x02,	NOT2 
	SJMP	ADD1X
NOT2:	CJNE	A,	#0x03,	NOT3 
	SJMP	ADD2X
NOT3:	CJNE	A,	#0x04,	NOT4
	SJMP	SUB2X
NOT4:	CJNE	A,	#0x05,	NOT5 
	SJMP	SUB1X
NOT5:	CJNE	A,	#0X06,	B3_SHFT 
	SJMP	SUB1X		
	
ADD2X:
	MOV	A,	PR_MID		; move mid byte to accumulator
	ADD	A,	BCAND2X_LO	; add low byte of multiplicand
	MOV	PR_MID,	A		; put the sum back in to product
	MOV	A,	PR_HI		; move high byte to accumulator
	ADDC	A,	BCAND2X_HI	; add high byte w/ carry
	MOV	PR_HI, A
	SJMP	B3_SHFT
ADD1X:	
	MOV	A,	PR_MID		; move mid byte to accumulator
	ADD	A,	BCAND_LO	; add low byte of multiplicand
	MOV	PR_MID,	A		; put the sum back in to product
	MOV	A,	PR_HI		; move high byte to accumulator
	ADDC	A,	BCAND_HI	; add high byte w/ carry	
	MOV	PR_HI, A
	SJMP	B3_SHFT
SUB2X:
	SUBB	A,	BCAND2X_LO	; sub low byte of multiplicand
	MOV	PR_MID,	A		; put the sum back in to product
	MOV	A,	PR_HI		; move high byte to accumulator
	SUBB	A,	BCAND2X_HI	; add high byte w/ carry
	MOV	PR_HI,	A
	SJMP	B3_SHFT		
SUB1X:
	SUBB	A,	BCAND_LO	; sub low byte of multiplicand
	MOV	PR_MID,	A		; put the sum back in to product
	MOV	A,	PR_HI		; move high byte to accumulator
	SUBB	A,	BCAND_HI	; add high byte w/ carry
	MOV	PR_HI,	A
	SJMP	B3_SHFT	
B3_SHFT:
	MOV	A,	PR_HI
	RLC	A
	MOV	F0,	C		; figure out the leftmost bit to copy it
	RRC	A
	MOV	C,	F0
	RRC	A			; shift high byte right
	MOV	PR_HI,	A		; put it in product register
	MOV	A,	PR_MID		; load in middle byte
	RRC	A			; shift mid byte right
	MOV	PR_MID,	A		; put it in product register
	MOV	A,	PR_LO		; load in low byte
	RRC	A			; shift low byte right
	MOV	PR_LO,	A		; put it in product register

	MOV	A,	PR_HI		; shift again
	RLC	A
	MOV	F0,	C		; figure out the leftmost bit to copy it
	RRC	A
	MOV	C,	F0
	RRC	A			; shift high byte right
	MOV	PR_HI,	A		; put it in product register
	MOV	A,	PR_MID		; load in middle byte
	RRC	A			; shift mid byte right
	MOV	PR_MID,	A		; put it in product register
	MOV	A,	PR_LO		; load in low byte
	RRC	A			; shift low byte right
	MOV	PR_LO,	A		; put it in product register
	DJNZ	R0,	B_LOOP		; keep looping for every bit in mlier
	END

; 2-BIT BOOTH'S ALGORITHM
BOOTHS:
	MOV	R7,	#0x04		; We need to shift mcand left four bits
	MOV	BCAND_LO,	#MCAND_LO	; load mcand into shifted spots
	MOV	BCAND_HI,	#MCAND_HI
SHIFT:
	MOV	C,	F0
	MOV	A,	BCAND_LO	; load low-byte
	RLC	A			; shift left
	MOV	BCAND_LO,	A	; put low byte back
	MOV	A,	BCAND_HI	; load high byte
	RLC	A			; rotate left
	MOV	BCAND_HI,	A	; put high byte back
	DJNZ	R7,	SHIFT		; keep shifting until zero
					; over four bits; this is its counter
	MOV	PR_HI, 	#0		; clear high byte of output
	MOV	PR_MID,	#MLIER_HI	; move multiplier into low 12b
	MOV	PR_LO, 	#MLIER_LO
	MOV	R0,	#12		; this works for up to 12 bits
	CLR	C
B_LOOP:
	MOV 	A,	PR_LO		; pull low byte into accumulator
	RLC	A			; rotate carry into bit 0
	ANL	A,	#0x03		; mask just the last two bits
	JNB	P,	B_SHIFT		; if 00 or 11 (even parity=0) just shift
	RRC	A
	JC	B_NOSUB			; if 01 add instead of subtracting
	MOV	A,	PR_MID		; move mid byte to accumulator

	CLR C	
	SUBB	A,	BCAND_LO	; sub low byte of multiplicand
	MOV	PR_MID,	A		; put the sum back in to product
	MOV	A,	PR_HI		; move high byte to accumulator
	SUBB	A,	BCAND_HI	; add high byte w/ carry
	MOV	PR_HI,	A
	SJMP	B_SHIFT			; don't clear the carry
B_NOSUB:	
	MOV	A,	PR_MID		; move mid byte to accumulator
	ADD	A,	BCAND_LO	; add low byte of multiplicand
	MOV	PR_MID,	A		; put the sum back in to product
	MOV	A,	PR_HI		; move high byte to accumulator
	ADDC	A,	BCAND_HI	; add high byte w/ carry
	MOV	PR_HI,	A
B_SHIFT:
	MOV	A,	PR_HI
	RLC	A
	MOV	F0,	C
	RRC	A
	MOV	C,	F0
	RRC	A			; shift high byte right
	MOV	PR_HI,	A		; put it in product register
	MOV	A,	PR_MID		; load in middle byte
	RRC	A			; shift mid byte right
	MOV	PR_MID,	A		; put it in product register
	MOV	A,	PR_LO		; load in low byte
	RRC	A			; shift low byte right
	MOV	PR_LO,	A		; put it in product register
	DJNZ	R0,	B_LOOP		; keep looping for every bit in mlier
	END

;ADD-AND-SHIFT
BASIC:
	MOV	R7,	#0x04		; We need to shift mcand left four bits
	MOV	BCAND_LO,	#MCAND_LO	; load mcand into shifted spots
	MOV	BCAND_HI,	#MCAND_HI
SHIFT:
	CLR 	C			; clear the carry
	MOV	A,	BCAND_LO	; load low-byte
	RLC	A			; shift left
	MOV	BCAND_LO,	A	; put low byte back
	MOV	A,	BCAND_HI	; load high byte
	RLC	A			; rotate left
	MOV	BCAND_HI,	A	; put high byte back
	DJNZ	R7,	SHIFT		; keep shifting until zero
					; over four bits; this is its counter
	MOV	PR_HI, 	#0		; clear high byte of output
	MOV	PR_MID,	#MLIER_HI	; move multiplier into low 12b
	MOV	PR_LO, 	#MLIER_LO
	MOV	R0,	#12		; this works for up to 12 bits
LOOP:
	JNB	PR_LO.0,	B_NOADD		; skip adding if zero

	MOV	A,	PR_MID		; move mid byte to accumulator
	ADD	A,	BCAND_LO	; add low byte of multiplicand
	MOV	PR_MID,	A		; put the sum back in to product
	MOV	A,	PR_HI		; move high byte to accumulator
	ADDC	A,	BCAND_HI	; add high byte w/ carry
	SJMP	B_NOCLR			; don't clear the carry
NOADD:
	CLR C
	MOV	A,	PR_HI		; load high product byte to accumulator
NOCLR:
	RRC	A			; shift high byte right
	MOV	PR_HI,	A		; put it in product register
	MOV	A,	PR_MID		; load in middle byte
	RRC	A			; shift mid byte right
	MOV	PR_MID,	A		; put it in product register
	MOV	A,	PR_LO		; load in low byte
	RRC	A			; shift low byte right
	MOV	PR_LO,	A		; put it in product register
	DJNZ	R0,	B_LOOP		; keep looping for every bit in mlier

