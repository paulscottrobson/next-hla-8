; ***************************************************************************************
; ***************************************************************************************
;
;		Name : 		data.asm
;		Author :	Paul Robson (paul@robsons.org.uk)
;		Date : 		5th January 2019
;		Purpose :	Data area
;
; ***************************************************************************************
; ***************************************************************************************

; ***************************************************************************************
;
;								System Information
;
; ***************************************************************************************

SystemInformation:

Here:												; +0 	Here 
		dw 		FreeMemory
HerePage: 											; +2	Here.Page
		db 		FirstCodePage,0
BootAddress:										; +4 	Boot Address
		dw 		StopDefault
BootPage:											; +6 	Boot Page
		db 		FirstCodePage,0
NextFreePage: 										; +8 	Next available code page (2 8k pages/page)
		db 		FirstCodePage+2,0,0,0
DisplayInfo: 										; +12 	Display information
		dw 		DisplayInformation,0

; ***************************************************************************************
;
;							 Display system information
;
; ***************************************************************************************

DisplayInformation:

SIScreenWidth: 										; +0 	screen width
		db 		0,0,0,0	
SIScreenHeight:										; +4 	screen height
		db 		0,0,0,0
SIScreenMode:										; +8 	current mode
		db 		0,0,0,0
SIFontBase:											; +12 	font in use
		dw 		AlternateFont
SIScreenDriver:										; +16 	Screen Driver
		dw 		0	

; ***************************************************************************************
;
;								 Other data and buffers
;
; ***************************************************************************************

__PAGEStackPointer: 								; stack used for switching pages
		dw 		0
__PAGEStackBase:
		ds 		16
		