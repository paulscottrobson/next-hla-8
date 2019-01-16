; ***************************************************************************************
; ***************************************************************************************
;
;		Name : 		paging.asm
;		Author :	paul@robsons.org.uk
;		Date : 		13th January 2018
;		Purpose :	Paging Manager
;
; ***************************************************************************************
; ***************************************************************************************

; ********************************************************************************************************
;
; 									Initialise Paging, set current to A
;
; ********************************************************************************************************

PAGEInitialise:
		push 	hl
		db 		$ED,$92,$56							; switch to page A
		inc 	a
		db 		$ED,$92,$57
		dec 	a
		ex 		af,af' 								; put page in A'
		ld 		hl,__PAGEStackBase 					; reset the page stack
		ld 		(__PAGEStackPointer),hl
		pop 	hl
		ret

; ********************************************************************************************************
;
;										Switch to a new page A
;
; ********************************************************************************************************

PAGESwitch:
		push 	af
		push 	hl

		push 	af 									; save A on stack
		ld 		hl,(__PAGEStackPointer) 			; put A' on the stack, the current page
		ex 		af,af'
		ld 		(hl),a
		inc 	hl
		ld 		(__PAGEStackPointer),hl

		pop 	af 									; restore new A
		db 		$ED,$92,$56							; switch to page A
		inc 	a
		db 		$ED,$92,$57
		dec 	a
		ex 		af,af' 								; put page in A'

		pop 	hl
		pop 	af
		ret

; ********************************************************************************************************
;
;										Return to the previous page
;
; ********************************************************************************************************

PAGERestore:
		push 	af
		push 	hl
		ld 		hl,(__PAGEStackPointer) 			; pop the old page off
		dec 	hl
		ld 		a,(hl)
		ld 		(__PAGEStackPointer),hl
		db 		$ED,$92,$56							; switch to page A
		inc 	a
		db 		$ED,$92,$57
		dec 	a
		ex 		af,af' 								; update A'
		pop 	hl
		pop 	af
		ret
				