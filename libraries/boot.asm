; ***************************************************************************************
; ***************************************************************************************
;
;  Name :   kernel.asm
;  Author : Paul Robson (paul@robsons.org.uk)
;  Date :   13th January 2019
;  Purpose : Machine Forth Kernel
;
; ***************************************************************************************
; ***************************************************************************************

;
;  Page allocation. These need to match up with those given in the page table
;  in data.asm
;
DictionaryPage = $20         ; dictionary page
FirstCodePage = $22         ; first code page.
;
;  Memory allocated from the Unused space in $4000-$7FFF
;
StackTop = $7EFC          ;      -$7EFC Top of stack

	org  $8000         ; $8000 boot.
	jr   Boot
	org  $8004         ; $8004 address of sysinfo
	dw   SystemInformation

Boot: ld   sp,StackTop       ; reset Z80 Stack
	di           ; disable interrupts
	db   $ED,$91,7,2       ; set turbo port (7) to 2 (14Mhz speed)
	ld   a,1         ; blue border
	out  ($FE),a
	ld   a,FirstCodePage      ; get the page to start
	call  PAGEInitialise
	ld   a,(BootPage)      ; switch to boot page.
	call  PAGEInitialise
	ld   hl,(BootAddress)     ; start address
	jp   (hl)

; **** EXTERN_SysHalt() ****
IMPORT_53_79_73_48_61_6c_74_28_30

StopDefault:
	jp   StopDefault

; ***************************************************************************************
; ***************************************************************************************
;
;  Name :   data.asm
;  Author : Paul Robson (paul@robsons.org.uk)
;  Date :   5th January 2019
;  Purpose : Data area
;
; ***************************************************************************************
; ***************************************************************************************

; ***************************************************************************************
;
;        System Information
;
; ***************************************************************************************

SystemInformation:

Here:            ; +0  Here
	dw   FreeMemory
HerePage:            ; +2 Here.Page
	db   FirstCodePage,0
BootAddress:          ; +4  Boot Address
	dw   StopDefault
BootPage:           ; +6  Boot Page
	db   FirstCodePage,0
NextFreePage:           ; +8  Next available code page (2 8k pages/page)
	db   FirstCodePage+2,0,0,0
DisplayInfo:           ; +12  Display information
	dw   DisplayInformation,0

; ***************************************************************************************
;
;        Display system information
;
; ***************************************************************************************

DisplayInformation:

SIScreenWidth:           ; +0  screen width
	db   0,0,0,0
SIScreenHeight:          ; +4  screen height
	db   0,0,0,0
SIScreenMode:          ; +8  current mode
	db   0,0,0,0
SIFontBase:           ; +12  font in use
	dw   AlternateFont
SIScreenDriver:          ; +16  Screen Driver
	dw   0

; ***************************************************************************************
;
;         Other data and buffers
;
; ***************************************************************************************

__PAGEStackPointer:         ; stack used for switching pages
	dw   0
__PAGEStackBase:
	ds   16

; *********************************************************************************
; *********************************************************************************
;
;  File:  screen48k.asm
;  Purpose: Hardware interface to Spectrum display, standard but with
;     sprites enabled.
;  Date :   13th January 2019
;  Author:  paul@robsons.org.uk
;
; *********************************************************************************
; *********************************************************************************

; *********************************************************************************
;
;      Call the SetMode for the Spectrum 48k
;
; *********************************************************************************

GFXInitialise48k:
	push  af          ; save registers
	push  bc

	ld   bc,$123B        ; Layer 2 access port
	ld   a,0         ; disable Layer 2
	out  (c),a
	db   $ED,$91,$15,$3      ; Disable LowRes but enable Sprites

	ld   hl,$4000        ; clear pixel memory
__cs1: ld   (hl),0
	inc  hl
	ld   a,h
	cp   $58
	jr   nz,__cs1
__cs2: ld   (hl),$47       ; clear attribute memory
	inc  hl
	ld   a,h
	cp   $5B
	jr   nz,__cs2
	xor  a          ; border off
	out  ($FE),a
	pop  bc
	pop  af
	ld   hl,$1820        ; H = 24,L = 32, screen extent
	ld   de,GFXPrintCharacter48k
	ret

; *********************************************************************************
;
;    Write a character E on the screen at HL, in colour D
;
; *********************************************************************************

GFXPrintCharacter48k:
	push  af          ; save registers
	push  bc
	push  de
	push  hl

	ld   b,e         ; character in B
	ld   a,h         ; check range.
	cp   3
	jr   nc,__ZXWCExit
;
;  work out attribute position
;
	push  hl          ; save position.
	ld   a,h
	add  $58
	ld   h,a

	ld   a,d         ; get current colour
	and  7           ; mask 0..2
	or   $40          ; make bright
	ld   (hl),a         ; store it.
	pop  hl
;
;  calculate screen position => HL
;
	push  de
	ex   de,hl
	ld   l,e         ; Y5 Y4 Y3 X4 X3 X2 X1 X0
	ld   a,d
	and  3
	add  a,a
	add  a,a
	add  a,a
	or   $40
	ld   h,a
	pop  de
;
;  char# 32-127 to font address => DE
;
	push  hl
	ld   a,b         ; get character
	and  $7F         ; bits 0-6 only.
	sub  32
	ld   l,a         ; put in HL
	ld   h,0
	add  hl,hl         ; x 8
	add  hl,hl
	add  hl,hl
	ld   de,(SIFontBase)      ; add the font base.
	add  hl,de
	ex   de,hl         ; put in DE (font address)
	pop  hl
;
;  copy font data to screen position.
;
	ld   a,b
	ld   b,8         ; copy 8 characters
	ld   c,0         ; XOR value 0
	bit  7,a         ; is the character reversed
	jr   z,__ZXWCCopy
	dec  c          ; C is the XOR mask now $FF
__ZXWCCopy:
	ld   a,(de)        ; get font data
	xor  c          ; xor with reverse
	ld   (hl),a         ; write back
	inc  h          ; bump pointers
	inc  de
	djnz  __ZXWCCopy        ; do B times.
__ZXWCExit:
	pop  hl          ; restore and exit
	pop  de
	pop  bc
	pop  af
	ret
; *********************************************************************************
; *********************************************************************************
;
;  File:  screen_layer2.asm
;  Purpose: Layer 2 console interface, sprites enabled, no shadow.
;  Date :   13th January 2019
;  Author:  paul@robsons.org.uk
;
; *********************************************************************************
; *********************************************************************************

; *********************************************************************************
;
;        Clear Layer 2 Display.
;
; *********************************************************************************


GFXInitialiseLayer2:
	push  af
	push  bc
	push  de
	db   $ED,$91,$15,$3      ; Disable LowRes but enable Sprites

	ld   e,2         ; 3 banks to erase
L2PClear:
	ld   a,e         ; put bank number in bits 6/7
	rrc  a
	rrc  a
	or   2+1         ; shadow on, visible, enable write paging
	ld   bc,$123B        ; out to layer 2 port
	out  (c),a
	ld   hl,$4000        ; erase the bank to $00
L2PClearBank:           ; assume default palette :)
	dec  hl
	ld   (hl),$00
	ld   a,h
	or   l
	jr  nz,L2PClearBank
	dec  e
	jp   p,L2PClear

	xor  a
	out  ($FE),a

	pop  de
	pop  bc
	pop  af
	ld   hl,$1820        ; still 32 x 24
	ld   de,GFXPrintCharacterLayer2
	ret
;
;  Print Character E, colour D, position HL
;
GFXPrintCharacterLayer2:
	push  af
	push  bc
	push  de
	push  hl
	push  ix

	ld   b,e         ; save A temporarily
	ld   a,b
	and  $7F
	cp   32
	jr   c,__L2Exit        ; check char in range
	ld   a,h
	cp   3
	jr   nc,__L2Exit       ; check position in range
	ld   a,b

	push  af
	xor  a          ; convert colour in C to palette index
	bit  0,d         ; (assumes standard palette)
	jr   z,__L2Not1
	or   $03
__L2Not1:
	bit  2,d
	jr   z,__L2Not2
	or   $1C
__L2Not2:
	bit  1,d
	jr   z,__L2Not3
	or   $C0
__L2Not3:
	ld   c,a         ; C is foreground
	ld   b,0         ; B is xor flipper, initially zero
	pop  af          ; restore char

	push  hl
	bit  7,a         ; adjust background bit on bit 7
	jr   z,__L2NotCursor
	ld   b,$FF         ; light grey is cursor
__L2NotCursor:
	and  $7F         ; offset from space
	sub  $20
	ld   l,a         ; put into HL
	ld   h,0
	add  hl,hl         ; x 8
	add  hl,hl
	add  hl,hl

	push  hl          ; transfer to IX
	pop  ix
	pop  hl

	push  bc          ; add the font base to it.
	ld   bc,(SIFontBase)
	add  ix,bc
	pop  bc
	;
	;  figure out the correct bank.
	;
	push  bc
	ld   a,h         ; this is the page number.
	rrc  a
	rrc  a
	and  $C0         ; in bits 6 & 7
	or   $03         ; shadow on, visible, enable write pagin.
	ld   bc,$123B        ; out to layer 2 port
	out  (c),a
	pop  bc
	;
	;   now figure out position in bank
	;
	ex   de,hl
	ld   l,e
	ld   h,0
	add  hl,hl
	add  hl,hl
	add  hl,hl
	sla  h
	sla  h
	sla  h

	ld   e,8         ; do 8 rows
__L2Outer:
	push  hl          ; save start
	ld   d,8         ; do 8 columns
	ld   a,(ix+0)        ; get the bit pattern
	xor  b          ; maybe flip it ?
	inc  ix
__L2Loop:
	ld   (hl),0         ; background
	add  a,a         ; shift pattern left
	jr   nc,__L2NotSet
	ld   (hl),c         ; if MSB was set, overwrite with fgr
__L2NotSet:
	inc  hl
	dec  d          ; do a row
	jr   nz, __L2Loop
	pop  hl          ; restore, go 256 bytes down.
	inc  h
	dec  e          ; do 8 rows
	jr   nz,__L2Outer
__L2Exit:
	pop  ix
	pop  hl
	pop  de
	pop  bc
	pop  af
	ret
; *********************************************************************************
; *********************************************************************************
;
;  File:  screen_lores.asm
;  Purpose: LowRes console interface, sprites enabled.
;  Date :   13th January 2019
;  Author:  paul@robsons.org.uk
;
; *********************************************************************************
; *********************************************************************************

; *********************************************************************************
;
;        Clear LowRes Display.
;
; *********************************************************************************

GFXInitialiseLowRes:
	push  af
	push  bc
	push  de

	db   $ED,$91,$15,$83      ; Enable LowRes and enable Sprites
	xor  a          ; layer 2 off.
	ld   bc,$123B        ; out to layer 2 port
	out  (c),a

	ld   hl,$4000        ; erase the bank to $00
	ld   de,$6000
LowClearScreen:          ; assume default palette :)
	xor  a
	ld   (hl),a
	ld   (de),a
	inc  hl
	inc  de
	ld   a,h
	cp   $58
	jr  nz,LowClearScreen
	xor  a
	out  ($FE),a
	pop  de
	pop  bc
	pop  af
	ld   hl,$0C10        ; resolution is 16x12 chars
	ld   de,GFXPrintCharacterLowRes
	ret
;
;  Print Character E Colour D @ HL
;
GFXPrintCharacterLowRes:
	push  af
	push  bc
	push  de
	push  hl
	push  ix

	ld   b,e         ; save character in B
	ld   a,e
	and  $7F
	cp   32
	jr   c,__LPExit

	add  hl,hl
	add  hl,hl
	ld   a,h         ; check in range 192*4 = 768
	cp   3
	jr   nc,__LPExit

	ld   a,d         ; only lower 3 bits of colour
	and  7
	ld   c,a         ; C is foreground

	push  hl
	ld   a,b         ; get char back
	ld   b,0         ; B = no flip colour.
	bit  7,a
	jr   z,__LowNotReverse      ; but 7 set, flip is $FF
	dec  b
__LowNotReverse:
	and  $7F         ; offset from space
	sub  $20
	ld   l,a         ; put into HL
	ld   h,0
	add  hl,hl         ; x 8
	add  hl,hl
	add  hl,hl

	push  hl          ; transfer to IX
	pop  ix

	push  bc          ; add the font base to it.
	ld   bc,(SIFontBase)
	add  ix,bc
	pop  bc
	pop  hl
	ex   de,hl
	ld   a,e         ; put DE => HL
	and  192         ; these are part of Y
	ld   l,a          ; Y multiplied by 4 then 32 = 128
	ld   h,d
	add  hl,hl
	add  hl,hl
	add  hl,hl
	add  hl,hl
	set  6,h         ; put into $4000 range

	ld   a,15*4         ; mask for X, which has been premultiplied.
	and  e          ; and with E, gives X position
	add  a,a         ; now multiplied by 8.
	ld   e,a         ; DE is x offset.
	ld   d,0

	add  hl,de
	ld   a,h
	cp   $58         ; need to be shifted to 2nd chunk ?
	jr   c,__LowNotLower2
	ld   de,$0800
	add  hl,de
__LowNotLower2:
	ld   e,8         ; do 8 rows
__LowOuter:
	push  hl          ; save start
	ld   d,8         ; do 8 columns
	ld   a,(ix+0)        ; get the bit pattern
	xor  b
	inc  ix
__LowLoop:
	ld   (hl),0         ; background
	add  a,a         ; shift pattern left
	jr   nc,__LowNotSet
	ld   (hl),c         ; if MSB was set, overwrite with fgr
__LowNotSet:
	inc  l
	dec  d          ; do a row
	jr   nz, __LowLoop
	pop  hl          ; restore, go 256 bytes down.
	push  de
	ld   de,128
	add  hl,de
	pop  de
	dec  e          ; do 8 rows
	jr   nz,__LowOuter
__LPExit:
	pop  ix
	pop  hl
	pop  de
	pop  bc
	pop  af
	ret

; *********************************************************************************
; *********************************************************************************
;
;  File:  graphics.asm
;  Purpose: General screen I/O routines
;  Date :   13th January 2019
;  Author:  paul@robsons.org.uk
;
; *********************************************************************************
; *********************************************************************************

; *********************************************************************************
;
;        Set Graphics Mode to L
;
; *********************************************************************************

; **** EXTERN_GfxSetMode(screenMode) ****
IMPORT_47_66_78_53_65_74_4d_6f_64_65_28_31

	push  bc
	push  de
	push  hl
	ld   a,l         ; save new mode.
	ld   (SIScreenMode),a
	dec  l          ; L = 1 mode layer2
	jr   z,__GFXLayer2
	dec  l
	jr   z,__GFXLowRes       ; L = 2 mode lowres

	call  GFXInitialise48k     ; L = 0 or anything else, 48k mode.
	jr   __GFXConfigure

__GFXLayer2:
	call  GFXInitialiseLayer2
	jr   __GFXConfigure

__GFXLowRes:
	call  GFXInitialiseLowRes

__GFXConfigure:
	ld   a,l         ; save screen size
	ld   (SIScreenWidth),a
	ld   a,h
	ld   (SIScreenHeight),a
	ex   de,hl         ; save driver
	ld   (SIScreenDriver),hl

	pop  hl
	pop  de
	pop  bc
	ret

; *********************************************************************************
;
;  Write character D (colour) E (character) to position HL.
;
; *********************************************************************************

; **** EXTERN_GfxWrite(position,character) ****
IMPORT_47_66_78_57_72_69_74_65_28_32

GFX_Write:
	push  af
	push  bc
	push  de
	push  hl
	ld   bc,__GFXWCExit
	push  bc
	ld   bc,(SIScreenDriver)
	push  bc
	ret
__GFXWCExit:
	pop  hl
	pop  de
	pop  bc
	pop  af
	ret

; *********************************************************************************
;
;      Write hex word DE at position HL
;
; *********************************************************************************

; **** EXTERN_GfxWriteHex(position,value) ****
IMPORT_47_66_78_57_72_69_74_65_48_65_78_28_32

	ld   a,5
GFXWriteHexWordA:
	push  bc
	push  de
	push  hl
	ld   c,a
	ld   a,d
	push  de
	call  __GFXWHByte
	pop  de
	ld   a,e
	call __GFXWHByte
	pop  hl
	pop  de
	pop  bc
	ret

__GFXWHByte:
	push  af
	rrc  a
	rrc  a
	rrc  a
	rrc  a
	call  __GFXWHNibble
	pop  af
__GFXWHNibble:
	ld   d,c
	and  15
	cp   10
	jr   c,__GFXWHDigit
	add  a,7
__GFXWHDigit:
	add  a,48
	ld   e,a
	call  GFX_Write
	inc  hl
	ret

; *********************************************************************************
; *********************************************************************************
;
;  File:  binary.asm
;  Purpose: 16 bit binary functions
;  Date :   13th January 2018
;  Author:  paul@robsons.org.uk
;
; *********************************************************************************
; *********************************************************************************

; **** EXTERN_SysAnd() ****
IMPORT_53_79_73_41_6e_64_28_30

	ld   a,h
	and  d
	ld   h,a
	ld   a,l
	and  e
	ld   l,a
	ret


; **** EXTERN_SysOr() ****
IMPORT_53_79_73_4f_72_28_30

	ld   a,h
	or   d
	ld   h,a
	ld   a,l
	or   e
	ld   l,a
	ret


; **** EXTERN_SysXor() ****
IMPORT_53_79_73_58_6f_72_28_30

	ld   a,h
	xor  d
	ld   h,a
	ld   a,l
	xor  e
	ld   l,a
	ret
; *********************************************************************************
; *********************************************************************************
;
;  File:  divide.asm
;  Purpose: 16 bit unsigned divide
;  Date :   13th January 2018
;  Author:  paul@robsons.org.uk
;
; *********************************************************************************
; *********************************************************************************


; **** EXTERN_SysDivide() ****
IMPORT_53_79_73_44_69_76_69_64_65_28_30
	call  DIVDivideMod16
	ex   de,hl
	ret

; **** EXTERN_SysModulus() ****
IMPORT_53_79_73_4d_6f_64_75_6c_75_73_28_30
	call  DIVDivideMod16
	ret

; *********************************************************************************
;
;   Calculates DE / HL. On exit DE = result, HL = remainder
;
; *********************************************************************************

DIVDivideMod16:
	push  bc
	ld   b,d     ; DE
	ld   c,e
	ex   de,hl
	ld   hl,0
	ld   a,b
	ld   b,8
Div16_Loop1:
	rla
	adc  hl,hl
	sbc  hl,de
	jr   nc,Div16_NoAdd1
	add  hl,de
Div16_NoAdd1:
	djnz  Div16_Loop1
	rla
	cpl
	ld   b,a
	ld   a,c
	ld   c,b
	ld   b,8
Div16_Loop2:
	rla
	adc  hl,hl
	sbc  hl,de
	jr   nc,Div16_NoAdd2
	add  hl,de
Div16_NoAdd2:
	djnz  Div16_Loop2
	rla
	cpl
	ld   d,c
	ld   e,a
	pop  bc
	ret



AlternateFont:
	db 0,0,0,0,0,0,0,0,12,30,30,12,12,0,12,0,54,54,0,0,0,0,0,0,54,54,127,54,127,54,54,0,24,62,96,60,6,124,24,0,0,99,102,12,24,51,99,0,28,54,28,59,110,102,59,0,48,48,96,0,0,0,0,0,12,24,48,48,48,24,12,0,48,24,12,12,12,24,48,0,0,51,30,127,30,51,0,0,0,24,24,126,24,24,0,0,0,0,0,0,0,24,24,48,0,0,0,126,0,0,0,0,0,0,0,0,0,24,24,0,3,6,12,24,48,96,64,0,62,99,103,111,123,115,62,0,24,56,24,24,24,24,126,0,60,102,6,28,48,102,126,0,60,102,6,28,6,102,60,0,14,30,54,102,127,6,15,0,126,96,124,6,6,102,60,0,28,48,96,124,102,102,60,0,126,102,6,12,24,24,24,0,60,102,102,60,102,102,60,0,60,102,102,62,6,12,56,0,0,24,24,0,0,24,24,0,0,24,24,0,0,24,24,48,12,24,48,96,48,24,12,0,0,0,126,0,0,126,0,0,48,24,12,6,12,24,48,0,60,102,6,12,24,0,24,0,62,99,111,111,111,96,60,0,24,60,102,102,126,102,102,0,126,51,51,62,51,51,126,0,30,51,96,96,96,51,30,0,124,54,51,51,51,54,124,0,127,49,52,60,52,49,127,0,127,49,52,60,52,48,120,0,30,51,96,96,103,51,31,0,102,102,102,126,102,102,102,0,60,24,24,24,24,24,60,0,15,6,6,6,102,102,60,0,115,51,54,60,54,51,115,0,120,48,48,48,49,51,127,0,99,119,127,127,107,99,99,0,99,115,123,111,103,99,99,0,28,54,99,99,99,54,28,0,126,51,51,62,48,48,120,0,60,102,102,102,110,60,14,0,126,51,51,62,54,51,115,0,60,102,112,56,14,102,60,0,126,90,24,24,24,24,60,0,102,102,102,102,102,102,126,0,102,102,102,102,102,60,24,0,99,99,99,107,127,119,99,0,99,99,54,28,28,54,99,0,102,102,102,60,24,24,60,0,127,99,70,12,25,51,127,0,60,48,48,48,48,48,60,0,96,48,24,12,6,3,1,0,60,12,12,12,12,12,60,0,8,28,54,99,0,0,0,0,0,0,0,0,0,0,0,127,24,24,12,0,0,0,0,0,0,0,60,6,62,102,59,0,112,48,48,62,51,51,110,0,0,0,60,102,96,102,60,0,14,6,6,62,102,102,59,0,0,0,60,102,126,96,60,0,28,54,48,120,48,48,120,0,0,0,59,102,102,62,6,124,112,48,54,59,51,51,115,0,24,0,56,24,24,24,60,0,6,0,6,6,6,102,102,60,112,48,51,54,60,54,115,0,56,24,24,24,24,24,60,0,0,0,102,127,127,107,99,0,0,0,124,102,102,102,102,0,0,0,60,102,102,102,60,0,0,0,110,51,51,62,48,120,0,0,59,102,102,62,6,15,0,0,110,59,51,48,120,0,0,0,62,96,60,6,124,0,8,24,62,24,24,26,12,0,0,0,102,102,102,102,59,0,0,0,102,102,102,60,24,0,0,0,99,107,127,127,54,0,0,0,99,54,28,54,99,0,0,0,102,102,102,62,6,124,0,0,126,76,24,50,126,0,14,24,24,112,24,24,14,0,12,12,12,0,12,12,12,0,112,24,24,14,24,24,112,0,59,110,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; *********************************************************************************
; *********************************************************************************
;
;  File:  keyboard.asm
;  Purpose: Spectrum Keyboard Interface
;  Date :   27th December 2018
;  Author:  paul@robsons.org.uk
;
; *********************************************************************************
; *********************************************************************************

; *********************************************************************************
;
;     Read the keyboard, store in the address in P1
;
; *********************************************************************************

; **** EXTERN_SysReadKeyboard(address) ****
IMPORT_53_79_73_52_65_61_64_4b_65_79_62_6f_61_72_64_28_31

	call  IOScanKeyboard
	ld   (hl),a
	inc  hl
	ld   (hl),$00
	ret

; *********************************************************************************
;
;   Scan the keyboard, return currently pressed key code in A
;
; *********************************************************************************

IOScanKeyboard:
	push  bc
	push  de
	push  hl

	ld   hl,__kr_no_shift_table     ; firstly identify shift state.

	ld   c,$FE         ; check CAPS SHIFT (emulator : left shift)
	ld   b,$FE
	in   a,(c)
	bit  0,a
	jr   nz,__kr1
	ld   hl,__kr_shift_table
	jr   __kr2
__kr1:
	ld   b,$7F         ; check SYMBOL SHIFT (emulator : right shift)
	in   a,(c)
	bit  1,a
	jr   nz,__kr2
	ld   hl,__kr_symbol_shift_table
__kr2:

	ld   e,$FE         ; scan pattern.
__kr3: ld   a,e         ; work out the mask, so we don't detect shift keys
	ld   d,$1E         ; $FE row, don't check the least significant bit.
	cp   $FE
	jr   z,___kr4
	ld   d,$01D         ; $7F row, don't check the 2nd least significant bit
	cp   $7F
	jr   z,___kr4
	ld   d,$01F         ; check all bits.
___kr4:
	ld   b,e         ; scan the keyboard
	ld   c,$FE
	in   a,(c)
	cpl           ; make that active high.
	and  d           ; and with check value.
	jr   nz,__kr_keypressed      ; exit loop if key pressed.

	inc  hl          ; next set of keyboard characters
	inc  hl
	inc  hl
	inc  hl
	inc  hl

	ld   a,e         ; get pattern
	add  a,a         ; shift left
	or   1          ; set bit 1.
	ld   e,a

	cp   $FF         ; finished when all 1's.
	jr   nz,__kr3
	xor  a
	jr   __kr_exit        ; no key found, return with zero.
;
__kr_keypressed:
	inc  hl          ; shift right until carry set
	rra
	jr   nc,__kr_keypressed
	dec  hl          ; undo the last inc hl
	ld   a,(hl)         ; get the character number.
__kr_exit:
	pop  hl
	pop  de
	pop  bc
	ret

; *********************************************************************************
;        Keyboard Mapping Tables
; *********************************************************************************
;
; $FEFE-$7FFE scan, bit 0-4, active low
;
; 3:Abort (Shift+Q) 8:Backspace 13:Return
; 27:Break 32-127: Std ASCII all L/C
;
__kr_no_shift_table:
	db   0,  'z','x','c','v',   'a','s','d','f','g'
	db   'q','w','e','r','t',   '1','2','3','4','5'
	db   '0','9','8','7','6',   'p','o','i','u','y'
	db   13, 'l','k','j','h',   ' ', 0, 'm','n','b'

__kr_shift_table:
	db    0, ':', 0,  '?','/',   '~','|','\','{','}'
	db    3,  0,  0  ,'<','>',   '!','@','#','$','%'
	db   '_',')','(',"'",'&',   '"',';', 0, ']','['
	db   27, '=','+','-','^',   ' ', 0, '.',',','*'

__kr_symbol_shift_table:
	db   0,  ':',0  ,'?','/',   '~','|','\','{','}'
	db   3,  0,  0  ,'<','>',   16,17,18,19,20
	db   8, ')',23,  22, 21,    '"',';', 0, ']','['
	db   27, '=','+','-','^',   ' ', 0, '.',',','*'
; *********************************************************************************
; *********************************************************************************
;
;  File:  multiply.asm
;  Purpose: 16 bit unsigned multiply
;  Date :   13th January 2018
;  Author:  paul@robsons.org.uk
;
; *********************************************************************************
; *********************************************************************************

; *********************************************************************************
;
;        Does HL = HL * DE
;
; *********************************************************************************

; **** EXTERN_SysMultiply() ****
IMPORT_53_79_73_4d_75_6c_74_69_70_6c_79_28_30

	push  bc
	push  de
	ld   b,h        ; get multipliers in DE/BC
	ld   c,l
	ld   hl,0        ; zero total
__Core__Mult_Loop:
	bit  0,c        ; lsb of shifter is non-zero
	jr   z,__Core__Mult_Shift
	add  hl,de        ; add adder to total
__Core__Mult_Shift:
	srl  b         ; shift BC right.
	rr   c
	ex   de,hl        ; shift DE left
	add  hl,hl
	ex   de,hl
	ld   a,b        ; loop back if BC is nonzero
	or   c
	jr   nz,__Core__Mult_Loop
	pop  de
	pop  bc
	ret
; ***************************************************************************************
; ***************************************************************************************
;
;  Name :   paging.asm
;  Author : paul@robsons.org.uk
;  Date :   13th January 2018
;  Purpose : Paging Manager
;
; ***************************************************************************************
; ***************************************************************************************

; ********************************************************************************************************
;
;          Initialise Paging, set current to A
;
; ********************************************************************************************************

PAGEInitialise:
	push  hl
	db   $ED,$92,$56       ; switch to page A
	inc  a
	db   $ED,$92,$57
	dec  a
	ex   af,af'         ; put page in A'
	ld   hl,__PAGEStackBase      ; reset the page stack
	ld   (__PAGEStackPointer),hl
	pop  hl
	ret

; ********************************************************************************************************
;
;          Switch to a new page A
;
; ********************************************************************************************************

PAGESwitch:
	push  af
	push  hl

	push  af          ; save A on stack
	ld   hl,(__PAGEStackPointer)    ; put A' on the stack, the current page
	ex   af,af'
	ld   (hl),a
	inc  hl
	ld   (__PAGEStackPointer),hl

	pop  af          ; restore new A
	db   $ED,$92,$56       ; switch to page A
	inc  a
	db   $ED,$92,$57
	dec  a
	ex   af,af'         ; put page in A'

	pop  hl
	pop  af
	ret

; ********************************************************************************************************
;
;          Return to the previous page
;
; ********************************************************************************************************

PAGERestore:
	push  af
	push  hl
	ld   hl,(__PAGEStackPointer)    ; pop the old page off
	dec  hl
	ld   a,(hl)
	ld   (__PAGEStackPointer),hl
	db   $ED,$92,$56       ; switch to page A
	inc  a
	db   $ED,$92,$57
	dec  a
	ex   af,af'         ; update A'
	pop  hl
	pop  af
	ret

FreeMemory:
	org  $C000
	db   17
	db   $22
	dw   IMPORT_47_66_78_53_65_74_4d_6f_64_65_28_31
	db   12
	db   "gfxsetmode(1"

	db   15
	db   $22
	dw   IMPORT_47_66_78_57_72_69_74_65_28_32
	db   10
	db   "gfxwrite(2"

	db   18
	db   $22
	dw   IMPORT_47_66_78_57_72_69_74_65_48_65_78_28_32
	db   13
	db   "gfxwritehex(2"

	db   13
	db   $22
	dw   IMPORT_53_79_73_41_6e_64_28_30
	db   8
	db   "sysand(0"

	db   16
	db   $22
	dw   IMPORT_53_79_73_44_69_76_69_64_65_28_30
	db   11
	db   "sysdivide(0"

	db   14
	db   $22
	dw   IMPORT_53_79_73_48_61_6c_74_28_30
	db   9
	db   "syshalt(0"

	db   17
	db   $22
	dw   IMPORT_53_79_73_4d_6f_64_75_6c_75_73_28_30
	db   12
	db   "sysmodulus(0"

	db   18
	db   $22
	dw   IMPORT_53_79_73_4d_75_6c_74_69_70_6c_79_28_30
	db   13
	db   "sysmultiply(0"

	db   12
	db   $22
	dw   IMPORT_53_79_73_4f_72_28_30
	db   7
	db   "sysor(0"

	db   22
	db   $22
	dw   IMPORT_53_79_73_52_65_61_64_4b_65_79_62_6f_61_72_64_28_31
	db   17
	db   "sysreadkeyboard(1"

	db   13
	db   $22
	dw   IMPORT_53_79_73_58_6f_72_28_30
	db   8
	db   "sysxor(0"

	db 	0
