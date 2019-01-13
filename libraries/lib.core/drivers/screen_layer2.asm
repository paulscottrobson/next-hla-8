; *********************************************************************************
; *********************************************************************************
;
;		File:		screen_layer2.asm
;		Purpose:	Layer 2 console interface, sprites enabled, no shadow.
;		Date : 		13th January 2019
;		Author:		paul@robsons.org.uk
;
; *********************************************************************************
; *********************************************************************************

; *********************************************************************************
;
;								Clear Layer 2 Display.
;
; *********************************************************************************


GFXInitialiseLayer2:
		push 	af
		push 	bc
		push 	de
		db 		$ED,$91,$15,$3						; Disable LowRes but enable Sprites

		ld 		e,2 								; 3 banks to erase
L2PClear:
		ld 		a,e 								; put bank number in bits 6/7
		rrc 	a
		rrc 	a
		or 		2+1 								; shadow on, visible, enable write paging
		ld 		bc,$123B 							; out to layer 2 port
		out 	(c),a
		ld 		hl,$4000 							; erase the bank to $00 
L2PClearBank: 										; assume default palette :)
		dec 	hl
		ld 		(hl),$00
		ld 		a,h
		or 		l
		jr		nz,L2PClearBank
		dec 	e
		jp 		p,L2PClear

		xor 	a
		out 	($FE),a

		pop 	de
		pop 	bc
		pop 	af
		ld 		hl,$1820 							; still 32 x 24 	
		ld 		de,GFXPrintCharacterLayer2
		ret
;
;		Print Character E, colour D, position HL
;
GFXPrintCharacterLayer2:
		push 	af
		push 	bc
		push 	de
		push 	hl
		push 	ix

		ld 		b,e 								; save A temporarily
		ld 		a,b
		and 	$7F
		cp 		32
		jr 		c,__L2Exit 							; check char in range
		ld 		a,h
		cp 		3
		jr 		nc,__L2Exit 						; check position in range
		ld 		a,b

		push 	af 	
		xor 	a 									; convert colour in C to palette index
		bit 	0,d 								; (assumes standard palette)
		jr 		z,__L2Not1
		or 		$03
__L2Not1:
		bit 	2,d
		jr 		z,__L2Not2
		or 		$1C
__L2Not2:
		bit 	1,d
		jr 		z,__L2Not3
		or 		$C0
__L2Not3:
		ld 		c,a 								; C is foreground
		ld 		b,0									; B is xor flipper, initially zero
		pop 	af 									; restore char

		push 	hl
		bit 	7,a 								; adjust background bit on bit 7
		jr 		z,__L2NotCursor
		ld 		b,$FF 								; light grey is cursor
__L2NotCursor:
		and 	$7F 								; offset from space
		sub 	$20
		ld 		l,a 								; put into HL
		ld 		h,0
		add 	hl,hl 								; x 8
		add 	hl,hl
		add 	hl,hl

		push 	hl 									; transfer to IX
		pop 	ix
		pop 	hl

		push 	bc 									; add the font base to it.
		ld 		bc,(SIFontBase)
		add 	ix,bc
		pop 	bc
		;
		;		figure out the correct bank.
		;
		push 	bc
		ld  	a,h 								; this is the page number.
		rrc 	a
		rrc 	a
		and 	$C0 								; in bits 6 & 7
		or 		$03 								; shadow on, visible, enable write pagin.
		ld 		bc,$123B 							; out to layer 2 port
		out 	(c),a
		pop 	bc
		;
		; 		now figure out position in bank
		;
		ex 		de,hl
		ld 		l,e
		ld 		h,0
		add 	hl,hl 								
		add 	hl,hl
		add 	hl,hl
		sla 	h
		sla 	h
		sla 	h

		ld 		e,8 								; do 8 rows
__L2Outer:
		push 	hl 									; save start
		ld 		d,8 								; do 8 columns
		ld 		a,(ix+0) 							; get the bit pattern
		xor 	b 									; maybe flip it ?
		inc 	ix
__L2Loop:
		ld 		(hl),0 								; background
		add 	a,a 								; shift pattern left
		jr 		nc,__L2NotSet
		ld 		(hl),c 								; if MSB was set, overwrite with fgr
__L2NotSet:
		inc 	hl
		dec 	d 									; do a row
		jr 		nz,	__L2Loop
		pop 	hl 									; restore, go 256 bytes down.
		inc 	h
		dec 	e 									; do 8 rows
		jr 		nz,__L2Outer	
__L2Exit:
		pop 	ix
		pop 	hl
		pop 	de
		pop 	bc
		pop 	af
		ret
