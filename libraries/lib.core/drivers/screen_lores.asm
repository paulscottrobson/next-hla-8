; *********************************************************************************
; *********************************************************************************
;
;		File:		screen_lores.asm
;		Purpose:	LowRes console interface, sprites enabled.
;		Date : 		13th January 2019
;		Author:		paul@robsons.org.uk
;
; *********************************************************************************
; *********************************************************************************

; *********************************************************************************
;
;								Clear LowRes Display.
;
; *********************************************************************************

GFXInitialiseLowRes:
		push 	af
		push 	bc
		push 	de

		db 		$ED,$91,$15,$83						; Enable LowRes and enable Sprites
		xor 	a 									; layer 2 off.
		ld 		bc,$123B 							; out to layer 2 port
		out 	(c),a

		ld 		hl,$4000 							; erase the bank to $00 
		ld 		de,$6000
LowClearScreen: 									; assume default palette :)
		xor 	a
		ld 		(hl),a
		ld 		(de),a
		inc 	hl
		inc 	de
		ld 		a,h
		cp 		$58
		jr		nz,LowClearScreen
		xor 	a
		out 	($FE),a
		pop 	de
		pop 	bc
		pop 	af
		ld 		hl,$0C10 							; resolution is 16x12 chars
		ld 		de,GFXPrintCharacterLowRes
		ret
;
;		Print Character E Colour D @ HL
;
GFXPrintCharacterLowRes:
		push 	af
		push 	bc
		push 	de
		push 	hl
		push 	ix

		ld 		b,e 								; save character in B
		ld 		a,e
		and 	$7F
		cp 		32
		jr 		c,__LPExit

		add 	hl,hl
		add 	hl,hl
		ld	 	a,h 								; check in range 192*4 = 768
		cp 		3
		jr 		nc,__LPExit

		ld 		a,d 								; only lower 3 bits of colour
		and 	7
		ld 		c,a 								; C is foreground

		push 	hl
		ld 		a,b 								; get char back
		ld 		b,0 								; B = no flip colour.
		bit 	7,a
		jr 		z,__LowNotReverse 					; but 7 set, flip is $FF
		dec 	b
__LowNotReverse:
		and 	$7F 								; offset from space
		sub 	$20
		ld 		l,a 								; put into HL
		ld 		h,0
		add 	hl,hl 								; x 8
		add 	hl,hl
		add 	hl,hl

		push 	hl 									; transfer to IX
		pop 	ix

		push 	bc 									; add the font base to it.
		ld 		bc,(SIFontBase)
		add 	ix,bc
		pop 	bc
		pop 	hl
		ex 		de,hl
		ld 		a,e 								; put DE => HL
		and 	192 								; these are part of Y
		ld 		l,a  								; Y multiplied by 4 then 32 = 128
		ld 		h,d		
		add 	hl,hl
		add 	hl,hl
		add 	hl,hl
		add 	hl,hl
		set 	6,h 								; put into $4000 range

		ld 		a,15*4 								; mask for X, which has been premultiplied.
		and 	e 									; and with E, gives X position
		add 	a,a 								; now multiplied by 8.
		ld 		e,a 								; DE is x offset.
		ld 		d,0  

		add 	hl,de
		ld 		a,h
		cp 		$58 								; need to be shifted to 2nd chunk ?
		jr 		c,__LowNotLower2
		ld 		de,$0800
		add 	hl,de
__LowNotLower2:
		ld 		e,8 								; do 8 rows
__LowOuter:
		push 	hl 									; save start
		ld 		d,8 								; do 8 columns
		ld 		a,(ix+0) 							; get the bit pattern
		xor 	b
		inc 	ix
__LowLoop:
		ld 		(hl),0 								; background
		add 	a,a 								; shift pattern left
		jr 		nc,__LowNotSet
		ld 		(hl),c 								; if MSB was set, overwrite with fgr
__LowNotSet:
		inc 	l
		dec 	d 									; do a row
		jr 		nz,	__LowLoop
		pop 	hl 									; restore, go 256 bytes down.
		push 	de
		ld 		de,128
		add 	hl,de
		pop 	de
		dec 	e 									; do 8 rows
		jr 		nz,__LowOuter	
__LPExit:
		pop 	ix
		pop 	hl
		pop 	de
		pop 	bc
		pop 	af
		ret

