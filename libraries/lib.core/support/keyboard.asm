; *********************************************************************************
; *********************************************************************************
;
;		File:		keyboard.asm
;		Purpose:	Spectrum Keyboard Interface
;		Date : 		27th December 2018
;		Author:		paul@robsons.org.uk
;
; *********************************************************************************
; *********************************************************************************

; *********************************************************************************
;
;					Read the keyboard, store in the address in P1
;
; *********************************************************************************

EXTERN_SysReadKeyboard(address)

		call 	IOScanKeyboard
		ld 		(hl),a
		inc 	hl
		ld 		(hl),$00
		ret

; *********************************************************************************
;
;			Scan the keyboard, return currently pressed key code in A
;
; *********************************************************************************
	
IOScanKeyboard:
		push 	bc
		push 	de
		push 	hl

		ld 		hl,__kr_no_shift_table 				; firstly identify shift state.

		ld 		c,$FE 								; check CAPS SHIFT (emulator : left shift)
		ld 		b,$FE
		in 		a,(c)
		bit 	0,a
		jr 		nz,__kr1
		ld 		hl,__kr_shift_table
		jr 		__kr2
__kr1:
		ld 		b,$7F 								; check SYMBOL SHIFT (emulator : right shift)
		in 		a,(c)
		bit 	1,a
		jr 		nz,__kr2
		ld 		hl,__kr_symbol_shift_table
__kr2:

		ld 		e,$FE 								; scan pattern.
__kr3:	ld 		a,e 								; work out the mask, so we don't detect shift keys
		ld 		d,$1E 								; $FE row, don't check the least significant bit.
		cp 		$FE
		jr 		z,___kr4
		ld 		d,$01D 								; $7F row, don't check the 2nd least significant bit
		cp 		$7F
		jr 		z,___kr4
		ld 		d,$01F 								; check all bits.
___kr4:
		ld 		b,e 								; scan the keyboard
		ld 		c,$FE
		in 		a,(c)
		cpl 										; make that active high.
		and 	d  									; and with check value.
		jr 		nz,__kr_keypressed 					; exit loop if key pressed.

		inc 	hl 									; next set of keyboard characters
		inc 	hl
		inc 	hl
		inc 	hl
		inc 	hl

		ld 		a,e 								; get pattern
		add 	a,a 								; shift left
		or 		1 									; set bit 1.
		ld 		e,a

		cp 		$FF 								; finished when all 1's.
		jr 		nz,__kr3 
		xor 	a
		jr 		__kr_exit 							; no key found, return with zero.
;
__kr_keypressed:
		inc 	hl  								; shift right until carry set
		rra
		jr 		nc,__kr_keypressed
		dec 	hl 									; undo the last inc hl
		ld 		a,(hl) 								; get the character number.
__kr_exit:
		pop 	hl
		pop 	de
		pop 	bc
		ret

; *********************************************************************************
;	 						Keyboard Mapping Tables
; *********************************************************************************
;
;	$FEFE-$7FFE scan, bit 0-4, active low
;
;	3:Abort (Shift+Q) 8:Backspace 13:Return 
;	27:Break 32-127: Std ASCII all L/C
;
__kr_no_shift_table:
		db 		0,  'z','x','c','v',			'a','s','d','f','g'
		db 		'q','w','e','r','t',			'1','2','3','4','5'
		db 		'0','9','8','7','6',			'p','o','i','u','y'
		db 		13, 'l','k','j','h',			' ', 0, 'm','n','b'

__kr_shift_table:
		db 		 0, ':', 0,  '?','/',			'~','|','\','{','}'
		db 		 3,  0,  0  ,'<','>',			'!','@','#','$','%'
		db 		'_',')','(',"'",'&',			'"',';', 0, ']','['
		db 		27, '=','+','-','^',			' ', 0, '.',',','*'

__kr_symbol_shift_table:
		db 		0,  ':',0  ,'?','/',			'~','|','\','{','}'
		db 		3,  0,  0  ,'<','>',			16,17,18,19,20
		db 		8, ')',23,  22, 21,				'"',';', 0, ']','['
		db 		27, '=','+','-','^',			' ', 0, '.',',','*'
