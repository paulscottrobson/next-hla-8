; *********************************************************************************
; *********************************************************************************
;
;		File:		divide.asm
;		Purpose:	16 bit unsigned divide
;		Date : 		13th January 2018
;		Author:		paul@robsons.org.uk
;
; *********************************************************************************
; *********************************************************************************


EXTERN_SysDivide()
	call 	DIVDivideMod16
	ex 		de,hl
	ret

EXTERN_SysModulus()
	call 	DIVDivideMod16
	ret

; *********************************************************************************
;
;			Calculates DE / HL. On exit DE = result, HL = remainder
;
; *********************************************************************************

DIVDivideMod16:
	push 	bc
	ld 		b,d 				; DE 
	ld 		c,e
	ex 		de,hl
	ld 		hl,0
	ld 		a,b
	ld 		b,8
Div16_Loop1:
	rla
	adc 	hl,hl
	sbc 	hl,de
	jr 		nc,Div16_NoAdd1
	add 	hl,de
Div16_NoAdd1:
	djnz 	Div16_Loop1
	rla
	cpl
	ld 		b,a
	ld 		a,c
	ld 		c,b
	ld 		b,8
Div16_Loop2:
	rla
	adc 	hl,hl
	sbc 	hl,de
	jr 		nc,Div16_NoAdd2
	add 	hl,de
Div16_NoAdd2:
	djnz 	Div16_Loop2
	rla
	cpl
	ld 		d,c
	ld 		e,a
	pop 	bc
	ret
		
		