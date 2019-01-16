; *********************************************************************************
; *********************************************************************************
;
;		File:		graphics.asm
;		Purpose:	General screen I/O routines
;		Date : 		13th January 2019
;		Author:		paul@robsons.org.uk
;
; *********************************************************************************
; *********************************************************************************
		
; *********************************************************************************
;
;								Set Graphics Mode to L
;
; *********************************************************************************

EXTERN_GfxSetMode(screenMode)

		push 	bc
		push 	de
		push 	hl
		ld 		a,l 								; save new mode.
		ld 		(SIScreenMode),a
		dec 	l 									; L = 1 mode layer2
		jr 		z,__GFXLayer2
		dec 	l
		jr 		z,__GFXLowRes 						; L = 2 mode lowres

		call 	GFXInitialise48k					; L = 0 or anything else, 48k mode.
		jr 		__GFXConfigure

__GFXLayer2:
		call 	GFXInitialiseLayer2
		jr 		__GFXConfigure

__GFXLowRes:
		call 	GFXInitialiseLowRes

__GFXConfigure:
		ld 		a,l 								; save screen size
		ld 		(SIScreenWidth),a
		ld 		a,h
		ld 		(SIScreenHeight),a
		ex 		de,hl 								; save driver
		ld 		(SIScreenDriver),hl

		pop 	hl
		pop 	de
		pop 	bc
		ret

; *********************************************************************************
;
;		Write character D (colour) E (character) to position HL.
;
; *********************************************************************************

EXTERN_GfxWrite(position,character)

GFX_Write:
		push 	af
		push 	bc
		push 	de
		push 	hl
		ld 		bc,__GFXWCExit
		push 	bc
		ld 		bc,(SIScreenDriver)
		push 	bc
		ret
__GFXWCExit:
		pop 	hl
		pop 	de
		pop 	bc
		pop 	af
		ret

; *********************************************************************************
;
;						Write hex word DE at position HL
;
; *********************************************************************************

EXTERN_GfxWriteHex(position,value)

		ld 		a,5
GFXWriteHexWordA:
		push 	bc
		push 	de
		push 	hl
		ld 		c,a
		ld 		a,d
		push 	de
		call 	__GFXWHByte
		pop 	de
		ld 		a,e
		call	__GFXWHByte
		pop 	hl
		pop 	de
		pop 	bc
		ret

__GFXWHByte:
		push 	af
		rrc 	a
		rrc		a
		rrc 	a
		rrc 	a
		call 	__GFXWHNibble
		pop 	af
__GFXWHNibble:
		ld 		d,c
		and 	15
		cp 		10
		jr 		c,__GFXWHDigit
		add		a,7
__GFXWHDigit:
		add 	a,48
		ld 		e,a
		call 	GFX_Write
		inc 	hl
		ret

