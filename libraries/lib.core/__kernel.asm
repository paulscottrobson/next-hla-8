; ***************************************************************************************
; ***************************************************************************************
;
;		Name : 		kernel.asm
;		Author :	Paul Robson (paul@robsons.org.uk)
;		Date : 		13th January 2019
;		Purpose :	Machine Forth Kernel
;
; ***************************************************************************************
; ***************************************************************************************

;
;		Page allocation. These need to match up with those given in the page table
;		in data.asm
;													
DictionaryPage = $20 								; dictionary page
FirstCodePage = $22 								; first code page.
;
;		Memory allocated from the Unused space in $4000-$7FFF
;
StackTop = $5FFE 									; $5B00-$5FFE stack

		org 	$8000 								; $8000 boot.
		jr 		Boot
		org 	$8004 								; $8004 address of sysinfo
		dw 		SystemInformation 

Boot:	ld 		sp,StackTop							; reset Z80 Stack
		di											; disable interrupts
		db 		$ED,$91,7,2							; set turbo port (7) to 2 (14Mhz speed)
		ld 		a,1 								; blue border
		out 	($FE),a		
		ld 		a,FirstCodePage 					; get the page to start
		call 	PAGEInitialise
		ld 		a,(BootPage)						; switch to boot page.
		call 	PAGEInitialise
		ld 		hl,(BootAddress)					; start address
		jp 		(hl)

EXTERN_SysHalt()

StopDefault:	
		jp 		StopDefault
		