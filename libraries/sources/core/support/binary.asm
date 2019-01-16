; *********************************************************************************
; *********************************************************************************
;
;		File:		binary.asm
;		Purpose:	16 bit binary functions
;		Date : 		13th January 2018
;		Author:		paul@robsons.org.uk
;
; *********************************************************************************
; *********************************************************************************

EXTERN_SysAnd()
	
	ld 		a,h
	and 	d
	ld 		h,a
	ld 		a,l
	and 	e
	ld 		l,a
	ret


EXTERN_SysOr()
	
	ld 		a,h
	or 		d
	ld 		h,a
	ld 		a,l
	or 		e
	ld 		l,a
	ret


EXTERN_SysXor()
	
	ld 		a,h
	xor 	d
	ld 		h,a
	ld 		a,l
	xor 	e
	ld 		l,a
	ret
