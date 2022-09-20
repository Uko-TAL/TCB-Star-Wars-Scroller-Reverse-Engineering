; Disassemby of StarWars Demo from TCB Cuddly Demos
; Performed by Easy Rider 4
; And reverse engineered/commented by Uko from T.AL

	OUTPUT	TCB_STW2.TOS
	OPT	O-	; Necessary to avoid replacing absolute addresses to PC relative
			; Else it makes crash the relocation

BASE_ADR	equ	$AC00	; Address of the demo code after relocation
RELOC_ADR	equ	$7FD00	; Address to copy the relocation code
MUSIC_ADR	equ	$6E000	; Address of the music after relocation

VBL_CODE_ADR	equ	$AC04	; Address of the VBL code
TIMB_CODE_ADR	equ 	$ACC4	; Address of the Timer B code Part #1
TIMB_CODE3_ADR	equ 	$AD0E	; Address of the Timer B code Part #3

RASTER_FLAG	equ	$AC80	; Flag for rasters management
WIZZ_COLOR	equ	$AC82	; Current color of the Wizz Logo
VBL_INIT_PAL	equ	$AD34	; Palette set up at the VBL begin

DISTSCR_STEP	equ	$B49A	; Step number
DISTSCR_PAR8	equ	$B49C	; 0 or 1 multiplied by 8

MOVING_LOGO_X_OF1 equ	$BDCE	; First offset in X sequence
MOVING_LOGO_X_OF2 equ	$BDD0	; Second offset in X sequence
MOVING_LOGO_Y_OF1 equ	$BDD2	; First offset in Y sequence
MOVING_LOGO_Y_OF2 equ	$BDD4	; Second offset in Y sequence

CLEAR_LOGO_1	equ	$C636	; Address of buffer #1 for clearing moving logo
CLEAR_LOGO_2	equ	$C63A	; Address of buffer #2 for clearing moving logo

SWSC_TEXT_POS	equ	$CD9C	; Current position (index) in text
SWSC_CHAR_LINE4 equ	$CD9E	; Current line in font char multiplied by 4 (so going from 0 to 40, because there are 10 lines per char)

MOVING_LOGO_CHAR_ADR equ	$D028	; Address of the current char of the moving logo
MOVING_LOGO_FONT equ	$D02C	; Font of the moving logo

EXIT_KEY	equ	$D530	; Exit key
TIME_OUT_CNT	equ	$D532	; Time Out Counter for attract mode
LOG_BASE	equ	$D534	; Pointer to logical screen 
PHY_BASE	equ	$D538	; Pointer to physical screen
SWSC_BUF_POS	equ	$D540	; Current position in SWSC buffer
SWSC_BUF_MID	equ	$D544	; Middle of the SWSC Buffer
VBL_SYNC_FLAG	equ	$D548	; Flag to indicate a new VBL
SWSC_TEXT_LEN	equ	$D54A	; Length of the SWSC text
STARS_CLEAR_BUF1_ADR equ	$D552	; Address of Buffer #1 for clearing stars
STARS_CLEAR_BUF2_ADR equ	$D54E	; Address of Buffer #2 for clearing stars
SAV_A7	equ	$D556	
SWSC_TEXT	equ	$D55A	; Begin of the SWSC text
DISTSCR_TEXT	equ 	$ED24	; Distorted scroll text
DISTSCR_TEXT_L2	equ 	$F960	; Distorted scroll text len * 2
DISTSCR_TEXT_POS equ 	$F962	; Position in distorted scroll text
DISTSCR_CONV_TBL equ	$F85C	; Conversion table from ASCII char to font
DISTSCR_CHAR_ADR equ	$F95C	; Char address in font buffer

STACK_ADR	equ	$10292	; Same address than stars data but addressed using -(a7)
STARS_DATA	equ	$10292	; Stars Data (positions, ...)

DIST_FONT_SRC	equ	$1C16A	; Distorted font source data initially, then becomes the start of buffers
STAR_DATA_PTR	equ	$1C1BA	; Pointer to the current step in stars data sequence
SWSC_BUFFER	equ	$1E76A	; Starwars scroller buffer

DIST_FONT	equ	$708E0	; Distorted font relocation

TOP_RASTERS_TBL	equ	$2354A	; Rasters table for first half screen
WIZZ_LOGO	equ	$23614	; Union Wizz Coders Logo

SWSC_FONT_BUFF	equ	$28D32	; Buffer containing the SWSC font rescaled and X shifted
MOVING_LOGO_FONT_BUFF equ	$5B9B2	; Buffer containing the mask and the shifted moving logo font

BUF_RASTER_1	equ	$631B2	; Top rasters buffer #1
BUF_RASTER_2	equ	$63342	; Top rasters buffer #2

BUF_LINE_OFFSET	equ	$774B8	; Buffer containing screen line address offsets: 0,160,320,...
MOVING_LOGO_SHIFT_OFST equ	$777D8	; Offset between shifts in font

BUF_SCR_1	equ	$78300	; Screen buffer #1
BUF_SCR_2	equ	$66300	; Screen buffer #2



	TEXT
begin:
	clr.l	-(a7)
	move.w	#$20,-(a7)	; Super
	trap	#1
	move	#$2700,sr
	lea	BASE_ADR,a7	; Hardcoded address for relocation
	move	a7,usp
	lea	$8.w,a0	; Bus error
	move.w	#$4e73,(a0)	; RTE

	move.l	a0,$68.w	; Set rte to all vectors
	move.l	a0,$70.w
	move.l	a0,$114.w
	move.l	a0,$118.w
	move.l	a0,$11c.w
	move.l	a0,$120.w
	move.l	a0,$134.w
	move	#$2300,sr
	
	lea	reloc_loop(pc),a0
	lea	RELOC_ADR,a1	; Hardcoded address for relocation code
	move.w	#$ff,d0
cpy_reloc_loop:	move.w	(a0)+,(a1)+
	dbf	d0,cpy_reloc_loop
	jmp	RELOC_ADR	; Now launch the relocation code
reloc_loop:	lea	demo_start,a0
	lea	BASE_ADR,a1
	lea	zuend,a2
relocate2:	move.b	(a0)+,(a1)+
	cmpa.l	a0,a2
	bne.s	relocate2
	jmp	BASE_ADR

demo_start:
	; @ = BASE_ADR		$AC00
	bra	main
vbl_code:
	; @ = VBL_CODE_ADR	$AC04
	; The VBL only contain few of the demo code thaht is mainly executed in
	; a main loop (in main)
	; It triggers a flag to allow the main loop to synchronise with VBL
	; changes colors, and plays music
	
	; Synchronisation flag for main loop
	st	VBL_SYNC_FLAG	
	
	; Set init palette
	clr.w	$ffff8250.w
	movem.l	a0-a6/d0-d7,-(a7)
	movem.l	L_vbl_init_pal(pc),d0-d7
	movem.l	d0-d7,$ffff8240.w
	
	; Manage Wizz Coders Logo color
	move.w	L_wizz_color(pc),d0
	cmpi.w	#$40,d0
	bge.s	.vbl1
	lea	L_wizz_color_lst(pc),a0
	move.w	0(a0,d0.w),$ffff8242.w
.vbl1:	addq.w	#2,d0
	cmpi.w	#$190,d0
	blt.s	.vbl2
	moveq	#0,d0
.vbl2:	move.w	d0,WIZZ_COLOR

	; Music play
	jsr	MUSIC_ADR+4		; 11 scanlines = 5600 cycles
	movem.l	(a7)+,a0-a6/d0-d7
	
	; Rasters management
	not.w	RASTER_FLAG
	bmi.s	.vbl3
	lea	BUF_RASTER_1,a6
	bra.s	.vbl4
.vbl3:	lea	BUF_RASTER_2,a6

.vbl4:	; Set Timer B
	move.l	#TIMB_CODE_ADR,$120.l	; timb_code
	move.b	#0,$fffffa1b.w
	move.b	#2,$fffffa21.w	; 2 lines
	move.b	#8,$fffffa1b.w	; Event count mode
	rte

L_raster_flag	dc.b	0,0	; @ = RASTER_FLAG	$AD80
L_wizz_color:	dc.b	0,'V'	; @ = WIZZ_COLOR	$AD82 
L_wizz_color_lst:
	dc.b	1,0,3,$10,5,'0',6,'@'
	dc.b	7,'P',7,'P',7,'P',7,'P'
	dc.b	6,'@',6,'@',6,'@',6,'@'
	dc.b	5,'0',5,'0',5,'0',5,'0'
	dc.b	4,' ',4,' ',4,' ',4,' '
	dc.b	3,$10,3,$10,3,$10,3,$10
	dc.b	2,0,2,0,2,0,2,0
	dc.b	1,0,1,0,1,0,1,0

timb_code:	; @ TIMB_CODE_ADR = $ACC4
	; Rasters for first half screen
	move.w	(a6),$ffff8244.w
	move.w	(a6)+,$ffff8246.w
	bmi.s	timb_code_2
	rte


timb_code_2:	; Change rasters table for SW Scroller
	move.l	#TIMB_CODE3_ADR,$120.l
	move.b	#0,$fffffa1b.w
	move.b	#2,$fffffa21.w
	move.b	#8,$fffffa1b.w
	move.l	a6,-(a7)
	move.l	a0,-(a7)
	lea	SW_Scroll_Rasters_Table(pc),a0
	lea	$ffff8240.w,a6
	move.l	(a0)+,(a6)+
	move.l	(a0)+,(a6)+
	move.l	(a0)+,(a6)+
	move.l	(a0)+,(a6)+
	move.l	(a0)+,(a6)+
	move.l	(a0)+,(a6)+
	move.l	(a0)+,(a6)+
	move.l	(a0)+,(a6)+
	movea.l	(a7)+,a0
	movea.l	(a7)+,a6
	rte

timb_code_3:	; @ TIMB_CODE3_ADR = $AD0E
	; Rasters for SW Scroller part
	move.w	(a6)+,$ffff8248.w
	rte

	dc.b	0,0,7,'w',3,'!',3,'!'
	dc.b	5,'2',5,'2',6,'B',6,'B'
	dc.b	7,'S',7,'S',2,1,2,1
	dc.b	4,2,4,2,6,3,6,3
	
L_vbl_init_pal:	dcb.w	2		; @ = VBL_INIT_PAL	$AD34
	dc.b	0,3,0,3,2,'"',2,'"'
	dc.b	3,'3',3,'3',4,'D',4,'D'
	dc.b	5,'U',5,'U',6,'f',6,'f'
	dc.b	7,'w',7,'w'

SW_Scroll_Rasters_Table:	
	dc.b	0,0,5,'0',7,'R',5,0
	dc.b	2,'"',3,0,2,0,4,' '
	dc.b	4,'D',0,0,0,0,0,0
	dc.b	6,'f',0,0,0,0,0,0

compute_rasters_top:
	lea	TOP_RASTERS_TBL,a6
	lea	BUF_RASTER_1,a5
	lea	BUF_RASTER_2,a4
	move.l	#$c7,d0
.loop:	move.w	(a6)+,d1
	move.w	d1,d3
	andi.w	#$e000,d3
	move.w	d1,d2
	addi.w	#$100,d1
	lsr.w	#1,d1
	andi.w	#$777,d1
	or.w	d3,d1
	move.w	d1,(a5)+
	addi.w	#$11,d2
	lsr.w	#1,d2
	andi.w	#$777,d2
	or.w	d3,d2
	move.w	d2,(a4)+
	dbf	d0,.loop
	lea	BUF_RASTER_1,a5
	lea	BUF_RASTER_2,a4
	ori.w	#$8000,180(a4)
	ori.w	#$8000,180(a5)
	rts

save_vec:	move	#$2700,sr
	move.l	$70.l,$ae4c	; sav_vec_data
	move.b	$fffffa07.w,$ae54
	move.b	$fffffa09.w,$ae55
	move.b	$fffffa13.w,$ae56
	move.b	$fffffa15.w,$ae57
	move.l	$120.l,$ae50
	move	#$2300,sr
	rts

restore_vec:	move	#$2700,sr
	move.l	$ae4c,$70.l	; sav_vec_data
	move.b	$ae54,$fffffa07.w
	move.b	$ae55,$fffffa09.w
	move.b	$ae56,$fffffa13.w
	move.b	$ae57,$fffffa15.w
	move.l	$ae50,$120.l
	move	#$2300,sr
	rts

sav_vec_data:	dcb.w	6		; $AE4C
set_vec:	move	#$2700,sr
	move.l	#VBL_CODE_ADR,$70.l	; vbl_code
	move.b	#0,$fffffa09.w
	move.b	#0,$fffffa1b.w
	move.b	#1,$fffffa07.w
	move.b	#1,$fffffa13.w		; TEST: set to 0 to disable Timer B, 1 to enable
	move.b	#1,$fffffa21.w
	bclr	#3,$fffffa17.w
	move.l	#TIMB_CODE_ADR,$120.w	; timb_code
	move	#$2300,sr
	rts


draw_dist_scroller:
	addq.w	#1,DISTSCR_STEP
	cmpi.w	#$2a,DISTSCR_STEP	; 42 = 2*21 steps
	blt	.noResetStep
	clr.w	DISTSCR_STEP

.noResetStep:	move.w	L_DistScr_Step(pc),d0	; Get step
	move.w	d0,d1
	andi.w	#1,d0		; Io know if step is odd or even
	add.w	d0,d0
	add.w	d0,d0		; Mul by 4

	lea	L_DistScr_ParTable(pc),a1	; Get buffer address according to step parity
	movea.l	0(a1,d0.w),a1		; stored in a1
	add.w	d0,d0
	move.w	d0,DISTSCR_PAR8
	
	andi.w	#$fffe,d1
	add.w	d1,d1
	add.w	d1,d1
	adda.w	d1,a1		; now a1 points to a buffer per parity and per step
	tst.w	d0
	bne	.stepNotEven
	
	; Need to read a new char sprite
	move.w	DISTSCR_TEXT_POS,d0
	btst	#0,d0
	bne	.noReadChar

	lsr.w	#1,d0
	lea	L_distscr_text(pc),a0
	moveq	#0,d1
	move.b	0(a0,d0.w),d1		; Read char
	lea	L_DistSrc_Conv_Tbl(pc),a0	
	move.b	0(a0,d1.w),d1		; Use conversion table for char
	mulu	#$190,d1
	movea.l	#DIST_FONT,a0
	adda.w	d1,a0
	move.l	a0,DISTSCR_CHAR_ADR	; Get char address
	bra	.incTextPos
	
.noReadChar:	addi.l	#$c8,DISTSCR_CHAR_ADR

.incTextPos:	addq.w	#1,DISTSCR_TEXT_POS
	move.w	L_DistScr_Pos(pc),d0
	cmp.w	L_DistScr_L2(pc),d0
	blt	.stepNotEven
	clr.w	DISTSCR_TEXT_POS
	
.stepNotEven:	movea.l	L_DistScr_Char_Adr(pc),a0
	movea.l	a1,a2
	move.w	DISTSCR_PAR8,d2
	moveq	#$18,d1
	cmpi.w	#2,DISTSCR_STEP
	blt	l0018
l0017:	moveq	#0,d0
	move.w	(a0)+,d0
	lsl.l	d2,d0
	move.w	d0,8(a1)
	swap	d0
	or.w	d0,(a1)+
	moveq	#0,d0
	move.w	(a0)+,d0
	lsl.l	d2,d0
	move.w	d0,8(a1)
	swap	d0
	or.w	d0,(a1)+
	moveq	#0,d0
	move.w	(a0)+,d0
	lsl.l	d2,d0
	move.w	d0,8(a1)
	swap	d0
	or.w	d0,(a1)+
	move.l	-6(a1),162(a1)
	move.w	-2(a1),166(a1)
	addq.l	#2,a0
	lea	330(a1),a1
	dbf	d1,l0017
	bra	l0019
l0018:	move.l	168(a1),(a1)
	move.w	172(a1),4(a1)
	moveq	#0,d0
	move.w	(a0)+,d0
	lsl.l	d2,d0
	move.w	d0,8(a1)
	swap	d0
	or.w	d0,(a1)+
	moveq	#0,d0
	move.w	(a0)+,d0
	lsl.l	d2,d0
	move.w	d0,8(a1)
	swap	d0
	or.w	d0,(a1)+
	moveq	#0,d0
	move.w	(a0)+,d0
	lsl.l	d2,d0
	move.w	d0,8(a1)
	swap	d0
	or.w	d0,(a1)+
	move.l	-6(a1),162(a1)
	move.w	-2(a1),166(a1)
	addq.l	#2,a0
	lea	330(a1),a1
	dbf	d1,l0018
l0019:	lea	16(a2),a0
	lea	DIST_FONT_SRC,a2
	adda.w	l0024(pc),a2
	movea.l	l0098(pc),a4
	cmpi.w	#$ffff,(a4)
	bne	l001b
	movea.l	l0099(pc),a3
	cmpi.l	#$ffffffff,(a3)
	bne	l001a
	lea	l009a(pc),a3
l001a:	movea.l	(a3)+,a4
	move.l	a3,$f968
l001b:	move.w	l0027(pc),$b4b8
	move.w	(a4)+,$b4b6
	move.l	a4,$f964
	lea	BUF_LINE_OFFSET,a3
	move.w	(a2),$b4ba
	move.w	l0027(pc),d0
	sub.w	l0028(pc),d0
	addi.w	#$64,d0
	add.w	d0,d0
	add.w	d0,d0
	move.l	0(a3,d0.w),d0
	subi.l	#$3e80,d0
	addq.l	#8,d0
	move.w	d0,(a2)
	move.w	d0,40(a2)
	addq.w	#2,$b4a6
	cmpi.w	#$28,$b4a6
	blt	l001c
	clr.w	$b4a6
l001c:	addq.l	#2,a2
	adda.l	L_Log_Base(pc),a1
	move.l	d0,-(a7)
	movea.l	l0025(pc),a1
	adda.w	l0029(pc),a1
	subq.l	#8,a1
	move.l	a1,$b4ae
	move.l	(a7)+,d0
	adda.l	L_Log_Base(pc),a1
	addq.l	#2,a1
	movea.l	l0026(pc),a4
	adda.l	L_Log_Base(pc),a4
	move.l	l0025(pc),$b4b2
	moveq	#0,d4
	addq.l	#8,a0
	addq.l	#8,a1
	moveq	#8,d3
l001d:	cmpa.l	a4,a1
	blt.s	l001e
	move.l	d4,4000(a1)
	move.w	d4,4004(a1)
	move.l	d4,4160(a1)
	move.w	d4,4164(a1)
	move.l	d4,-1600(a1)
	move.w	d4,-1596(a1)
	move.l	d4,-1440(a1)
	move.w	d4,-1436(a1)
	move.l	d4,-1280(a1)
	move.w	d4,-1276(a1)
	move.l	d4,-1120(a1)
	move.w	d4,-1116(a1)
	move.l	d4,-960(a1)
	move.w	d4,-956(a1)
	move.l	d4,-800(a1)
	move.w	d4,-796(a1)
	move.l	d4,-640(a1)
	move.w	d4,-636(a1)
	move.l	d4,-480(a1)
	move.w	d4,-476(a1)
	move.l	d4,-320(a1)
	move.w	d4,-316(a1)
	move.l	d4,-160(a1)
	move.w	d4,-156(a1)
	bra	l001f
l001e:	move.l	d4,-320(a1)
	move.w	d4,-316(a1)
	move.l	d4,-160(a1)
	move.w	d4,-156(a1)
	move.l	d4,4000(a1)
	move.w	d4,4004(a1)
	move.l	d4,4160(a1)
	move.w	d4,4164(a1)
	move.l	d4,4320(a1)
	move.w	d4,4324(a1)
	move.l	d4,4480(a1)
	move.w	d4,4484(a1)
	move.l	d4,4640(a1)
	move.w	d4,4644(a1)
	move.l	d4,4800(a1)
	move.w	d4,4804(a1)
	move.l	d4,4960(a1)
	move.w	d4,4964(a1)
	move.l	d4,5120(a1)
	move.w	d4,5124(a1)
	move.l	d4,5280(a1)
	move.w	d4,5284(a1)
	move.l	d4,5440(a1)
	move.w	d4,5444(a1)
l001f:	move.l	(a0),(a1)
	move.w	4(a0),4(a1)
	move.l	336(a0),160(a1)
	move.w	340(a0),164(a1)
	move.l	672(a0),320(a1)
	move.w	676(a0),324(a1)
	move.l	1008(a0),480(a1)
	move.w	1012(a0),484(a1)
	move.l	1344(a0),640(a1)
	move.w	1348(a0),644(a1)
	move.l	1680(a0),800(a1)
	move.w	1684(a0),804(a1)
	move.l	2016(a0),960(a1)
	move.w	2020(a0),964(a1)
	move.l	2352(a0),1120(a1)
	move.w	2356(a0),1124(a1)
	move.l	2688(a0),1280(a1)
	move.w	2692(a0),1284(a1)
	move.l	3024(a0),1440(a1)
	move.w	3028(a0),1444(a1)
	move.l	3360(a0),1600(a1)
	move.w	3364(a0),1604(a1)
	move.l	3696(a0),1760(a1)
	move.w	3700(a0),1764(a1)
	move.l	4032(a0),1920(a1)
	move.w	4036(a0),1924(a1)
	move.l	4368(a0),2080(a1)
	move.w	4372(a0),2084(a1)
	move.l	4704(a0),2240(a1)
	move.w	4708(a0),2244(a1)
	move.l	5040(a0),2400(a1)
	move.w	5044(a0),2404(a1)
	move.l	5376(a0),2560(a1)
	move.w	5380(a0),2564(a1)
	move.l	5712(a0),2720(a1)
	move.w	5716(a0),2724(a1)
	move.l	6048(a0),2880(a1)
	move.w	6052(a0),2884(a1)
	move.l	6384(a0),3040(a1)
	move.w	6388(a0),3044(a1)
	move.l	6720(a0),3200(a1)
	move.w	6724(a0),3204(a1)
	move.l	7056(a0),3360(a1)
	move.w	7060(a0),3364(a1)
	move.l	7392(a0),3520(a1)
	move.w	7396(a0),3524(a1)
	move.l	7728(a0),3680(a1)
	move.w	7732(a0),3684(a1)
	move.l	8064(a0),3840(a1)
	move.w	8068(a0),3844(a1)
	movea.l	a1,a4
	adda.w	(a2)+,a1
	cmpa.l	a4,a1
	blt.s	l0020
	move.l	d4,4000(a1)
	move.w	d4,4004(a1)
	move.l	d4,4160(a1)
	move.w	d4,4164(a1)
	move.l	d4,-1600(a1)
	move.w	d4,-1596(a1)
	move.l	d4,-1440(a1)
	move.w	d4,-1436(a1)
	move.l	d4,-1280(a1)
	move.w	d4,-1276(a1)
	move.l	d4,-1120(a1)
	move.w	d4,-1116(a1)
	move.l	d4,-960(a1)
	move.w	d4,-956(a1)
	move.l	d4,-800(a1)
	move.w	d4,-796(a1)
	move.l	d4,-640(a1)
	move.w	d4,-636(a1)
	move.l	d4,-480(a1)
	move.w	d4,-476(a1)
	move.l	d4,-320(a1)
	move.w	d4,-316(a1)
	move.l	d4,-160(a1)
	move.w	d4,-156(a1)
	bra	l0021
l0020:	move.l	d4,-320(a1)
	move.w	d4,-316(a1)
	move.l	d4,-160(a1)
	move.w	d4,-156(a1)
	move.l	d4,4000(a1)
	move.w	d4,4004(a1)
	move.l	d4,4160(a1)
	move.w	d4,4164(a1)
	move.l	d4,4320(a1)
	move.w	d4,4324(a1)
	move.l	d4,4480(a1)
	move.w	d4,4484(a1)
	move.l	d4,4640(a1)
	move.w	d4,4644(a1)
	move.l	d4,4800(a1)
	move.w	d4,4804(a1)
	move.l	d4,4960(a1)
	move.w	d4,4964(a1)
	move.l	d4,5120(a1)
	move.w	d4,5124(a1)
	move.l	d4,5280(a1)
	move.w	d4,5284(a1)
	move.l	d4,5440(a1)
	move.w	d4,5444(a1)
l0021:	move.l	8(a0),(a1)
	move.w	12(a0),4(a1)
	move.l	344(a0),160(a1)
	move.w	348(a0),164(a1)
	move.l	680(a0),320(a1)
	move.w	684(a0),324(a1)
	move.l	1016(a0),480(a1)
	move.w	1020(a0),484(a1)
	move.l	1352(a0),640(a1)
	move.w	1356(a0),644(a1)
	move.l	1688(a0),800(a1)
	move.w	1692(a0),804(a1)
	move.l	2024(a0),960(a1)
	move.w	2028(a0),964(a1)
	move.l	2360(a0),1120(a1)
	move.w	2364(a0),1124(a1)
	move.l	2696(a0),1280(a1)
	move.w	2700(a0),1284(a1)
	move.l	3032(a0),1440(a1)
	move.w	3036(a0),1444(a1)
	move.l	3368(a0),1600(a1)
	move.w	3372(a0),1604(a1)
	move.l	3704(a0),1760(a1)
	move.w	3708(a0),1764(a1)
	move.l	4040(a0),1920(a1)
	move.w	4044(a0),1924(a1)
	move.l	4376(a0),2080(a1)
	move.w	4380(a0),2084(a1)
	move.l	4712(a0),2240(a1)
	move.w	4716(a0),2244(a1)
	move.l	5048(a0),2400(a1)
	move.w	5052(a0),2404(a1)
	move.l	5384(a0),2560(a1)
	move.w	5388(a0),2564(a1)
	move.l	5720(a0),2720(a1)
	move.w	5724(a0),2724(a1)
	move.l	6056(a0),2880(a1)
	move.w	6060(a0),2884(a1)
	move.l	6392(a0),3040(a1)
	move.w	6396(a0),3044(a1)
	move.l	6728(a0),3200(a1)
	move.w	6732(a0),3204(a1)
	move.l	7064(a0),3360(a1)
	move.w	7068(a0),3364(a1)
	move.l	7400(a0),3520(a1)
	move.w	7404(a0),3524(a1)
	move.l	7736(a0),3680(a1)
	move.w	7740(a0),3684(a1)
	move.l	8072(a0),3840(a1)
	move.w	8076(a0),3844(a1)
	movea.l	a1,a4
	adda.w	(a2)+,a1
	lea	16(a0),a0
	dbf	d3,l001d
	rts

L_DistScr_Step:	dcb.w	1		; @ = DISTSCR_STEP	$B49A
	dcb.w	1		; @ = DISTSCR_PAR8	$B49C
L_DistScr_ParTable:			; @ = $B49E
	dc.b	0,7,$53,$e0,0,1,$c6,$92	; 2 different buffer adresses according to PARity of step
l0024:	dcb.w	4		; @ = $B4A6
l0025:	dcb.w	2		; @ = $B4AE
l0026:	dcb.w	2		; @ = $B4B2
l0027:	dc.b	0,0		; @ = $B4B6
l0028:	dc.b	0,0		; @ = $B4B8
l0029:	dcb.w	2		; @ = $B4BA

clear_moving_logo:
	movea.l	clear_logo_adr2(pc),a0	; Get buffer containing the adresses of previously displayed chars
	moveq	#0,d0
	
	movea.l	(a0)+,a1	; Erase Char #1
	cmpa.l	#0,a1
	bmi	.exit
	move.l	d0,(a1)+
	move.w	d0,(a1)+
	move.l	d0,2(a1)
	move.w	d0,6(a1)
	move.l	d0,154(a1)
	move.w	d0,158(a1)
	move.l	d0,162(a1)
	move.w	d0,166(a1)
	move.l	d0,314(a1)
	move.w	d0,318(a1)
	move.l	d0,322(a1)
	move.w	d0,326(a1)
	move.l	d0,474(a1)
	move.w	d0,478(a1)
	move.l	d0,482(a1)
	move.w	d0,486(a1)
	move.l	d0,634(a1)
	move.w	d0,638(a1)
	move.l	d0,642(a1)
	move.w	d0,646(a1)
	move.l	d0,794(a1)
	move.w	d0,798(a1)
	move.l	d0,802(a1)
	move.w	d0,806(a1)
	move.l	d0,954(a1)
	move.w	d0,958(a1)
	move.l	d0,962(a1)
	move.w	d0,966(a1)
	move.l	d0,1114(a1)
	move.w	d0,1118(a1)
	move.l	d0,1122(a1)
	move.w	d0,1126(a1)
	move.l	d0,1274(a1)
	move.w	d0,1278(a1)
	move.l	d0,1282(a1)
	move.w	d0,1286(a1)
	move.l	d0,1434(a1)
	move.w	d0,1438(a1)
	move.l	d0,1442(a1)
	move.w	d0,1446(a1)
	
	REPT 7
	movea.l	(a0)+,a1	; Erase Char #i
	move.l	d0,(a1)+
	move.w	d0,(a1)+
	move.l	d0,2(a1)
	move.w	d0,6(a1)
	move.l	d0,154(a1)
	move.w	d0,158(a1)
	move.l	d0,162(a1)
	move.w	d0,166(a1)
	move.l	d0,314(a1)
	move.w	d0,318(a1)
	move.l	d0,322(a1)
	move.w	d0,326(a1)
	move.l	d0,474(a1)
	move.w	d0,478(a1)
	move.l	d0,482(a1)
	move.w	d0,486(a1)
	move.l	d0,634(a1)
	move.w	d0,638(a1)
	move.l	d0,642(a1)
	move.w	d0,646(a1)
	move.l	d0,794(a1)
	move.w	d0,798(a1)
	move.l	d0,802(a1)
	move.w	d0,806(a1)
	move.l	d0,954(a1)
	move.w	d0,958(a1)
	move.l	d0,962(a1)
	move.w	d0,966(a1)
	move.l	d0,1114(a1)
	move.w	d0,1118(a1)
	move.l	d0,1122(a1)
	move.w	d0,1126(a1)
	move.l	d0,1274(a1)
	move.w	d0,1278(a1)
	move.l	d0,1282(a1)
	move.w	d0,1286(a1)
	move.l	d0,1434(a1)
	move.w	d0,1438(a1)
	move.l	d0,1442(a1)
	move.w	d0,1446(a1)
	ENDR
	
.exit:	rts

draw_moving_logo_letter:
	; d0 = X pos
	; d1 = Y pos
	; a1 = letter sprite address
	; a3 = clear buffer
	lea	BUF_LINE_OFFSET,a2
	add.w	d1,d1
	add.w	d1,d1
	movea.l	0(a2,d1.w),a0		; offset of screen line
	adda.l	L_Log_Base(pc),a0	; destination address
	
	move.w	d0,d1
	lsr.w	#1,d0
	andi.w	#$fff8,d0		; X offset
	adda.w	d0,a0
	
	move.l	a0,(a3)+		; Save address for further cleaning
	
	subq.l	#2,a0
	
	andi.w	#$f,d1		; Get the shifted sprite address
	add.w	d1,d1
	add.w	d1,d1
	lea	MOVING_LOGO_SHIFT_OFST,a2
	move.l	0(a2,d1.w),d1
	adda.l	d1,a1
	
	REPT 10	; 10 lines
	movem.l	(a0)+,d0-d3		; Get screen data
	and.w	(a1),d0		; Apply mask
	and.l	(a1)+,d1
	and.w	(a1),d2
	and.l	(a1)+,d3
	
	or.w	(a1)+,d0		; Or sprite
	or.l	(a1)+,d1
	or.w	(a1)+,d2
	or.l	(a1)+,d3
	movem.l	d0-d3,-(a0)		; Write screen
	lea	160(a0),a0		; Next screen line 
	ENDR
	
	rts

draw_moving_logo:
	; Switch clear buffers (double buffering)
	movea.l	clear_logo_adr2(pc),a3
	move.l	clear_logo_adr1(pc),CLEAR_LOGO_2
	move.l	a3,CLEAR_LOGO_1
	
	lea	L_moving_logo_char_addr(pc),a2	; Sprite address per letter
	lea	L_moving_logo_x_seq(pc),a4	; X position sequence
	lea	L_moving_logo_y_seq(pc),a5	; Y position sequence
	
	; Move in sequences and save new positions
	move.w	L_moving_logo_X_of1(pc),d4
	move.w	L_moving_logo_X_of2(pc),d5
	move.w	L_moving_logo_Y_of1(pc),d6
	move.w	L_moving_logo_Y_of2(pc),d7
	addi.w	#3,d4
	addi.w	#4,d5
	addi.w	#2,d6
	addi.w	#5,d7
	andi.w	#$1ff,d4
	andi.w	#$1ff,d5
	andi.w	#$1ff,d6
	andi.w	#$1ff,d7
	move.w	d4,MOVING_LOGO_X_OF1
	move.w	d5,MOVING_LOGO_X_OF2
	move.w	d6,MOVING_LOGO_Y_OF1
	move.w	d7,MOVING_LOGO_Y_OF2
	add.w	d4,d4
	add.w	d5,d5
	add.w	d6,d6
	add.w	d7,d7	
	
	; UNION
	REPT 5
	movea.l	(a2)+,a1	; Get sprite address for current letter
	move.w	0(a4,d4.w),d0
	asr.w	#1,d0
	add.w	0(a4,d5.w),d0
	addi.w	#$98,d0	; Add X pos 152
	move.w	0(a5,d6.w),d1
	asr.w	#1,d1
	add.w	0(a5,d7.w),d1
	addi.w	#$9b,d1	; Add Screen Line #155
	move.l	a2,-(a7)
	bsr	draw_moving_logo_letter
	movea.l	(a7)+,a2
	addi.w	#$1e,d4
	addi.w	#$12,d5
	addi.w	#$1a,d6
	addi.w	#$e,d7
	andi.w	#$3ff,d4
	andi.w	#$3ff,d5
	andi.w	#$3ff,d6
	andi.w	#$3ff,d7
	ENDR
	
	; SPACE	
	addi.w	#$1e,d4
	addi.w	#$12,d5
	addi.w	#$1a,d6
	addi.w	#$e,d7
	andi.w	#$3ff,d4
	andi.w	#$3ff,d5
	andi.w	#$3ff,d6
	andi.w	#$3ff,d7
	
	; THE
	REPT 3
	movea.l	(a2)+,a1
	move.w	0(a4,d4.w),d0
	asr.w	#1,d0
	add.w	0(a4,d5.w),d0
	addi.w	#$98,d0
	move.w	0(a5,d6.w),d1
	asr.w	#1,d1
	add.w	0(a5,d7.w),d1
	addi.w	#$9b,d1
	move.l	a2,-(a7)
	bsr	draw_moving_logo_letter
	movea.l	(a7)+,a2
	addi.w	#$1e,d4
	addi.w	#$12,d5
	addi.w	#$1a,d6
	addi.w	#$e,d7
	andi.w	#$3ff,d4
	andi.w	#$3ff,d5
	andi.w	#$3ff,d6
	andi.w	#$3ff,d7
	ENDR
		
	rts

L_moving_logo_X_of1:	; @ = MOVING_LOGO_X_OF1	$BDCE
	dc.b	0,0
L_moving_logo_X_of2:	; @ = MOVING_LOGO_X_OF2	$BDD0
	dc.b	0,0
L_moving_logo_Y_of1:	; @ = MOVING_LOGO_Y_OF1	$BDD2
	dc.b	0,0
L_moving_logo_Y_of2:	; @ = MOVING_LOGO_Y_OF2	$BDD4
	dc.b	0,0

L_moving_logo_char_addr:	; points to addresses in MOVING_LOGO_FONT_BUFF ($5B9B2)
	dc.b	0,5,$eb,$b2,0,6,4,$b2
	dc.b	0,5,$f8,'2',0,5,$eb,$b2
	dc.b	0,5,$df,'2',0,5,$d2,$b2
	dc.b	0,5,$c6,'2',0,5,$b9,$b2
	
L_moving_logo_x_seq:
	dc.b	0,'I',0,'J',0,'K',0,'L'
	dc.b	0,'M',0,'M',0,'N',0,'O'
	dc.b	0,'P',0,'Q',0,'R',0,'S'
	dc.b	0,'T',0,'U',0,'V',0,'W'
	dc.b	0,'X',0,'Y',0,'Z',0,'['
	dc.b	0,'[',0,'\',0,']',0,'^'
	dc.b	0,'_',0,'_',0,'`',0,'a'
	dc.b	0,'a',0,'b',0,'b',0,'c'
	dc.b	0,'c',0,'c',0,'d',0,'d'
	dc.b	0,'d',0,'d',0,'d',0,'d'
	dc.b	0,'d',0,'c',0,'c',0,'c'
	dc.b	0,'b',0,'b',0,'a',0,'`'
	dc.b	0,'_',0,'_',0,'^',0,'\'
	dc.b	0,'[',0,'Z',0,'Y',0,'W'
	dc.b	0,'V',0,'T',0,'R',0,'Q'
	dc.b	0,'O',0,'M',0,'K',0,'I'
	dc.b	0,'G',0,'D',0,'B',0,'@'
	dc.b	0,'=',0,';',0,'8',0,'6'
	dc.b	0,'3',0,'1',0,'.',0,'+'
	dc.b	0,')',0,'&',0,'#',0,' '
	dc.b	0,$1d,0,$1b,0,$18,0,$15
	dc.b	0,$12,0,$f,0,$d,0,$a
	dc.b	0,7,0,4,0,1,$ff,$ff
	dc.b	$ff,$fc,$ff,$f9,$ff,$f7,$ff,$f4
	dc.b	$ff,$f2,$ff,$ef,$ff,$ed,$ff,$ea
	dc.b	$ff,$e8,$ff,$e6,$ff,$e3,$ff,$e1
	dc.b	$ff,$df,$ff,$dd,$ff,$db,$ff,$d9
	dc.b	$ff,$d7,$ff,$d5,$ff,$d3,$ff,$d1
	dc.b	$ff,$d0,$ff,$ce,$ff,$cc,$ff,$cb
	dc.b	$ff,$c9,$ff,$c8,$ff,$c6,$ff,$c5
	dc.b	$ff,$c4,$ff,$c2,$ff,$c1,$ff,$c0
	dc.b	$ff,$bf,$ff,$be,$ff,$bd,$ff,$bc
	dc.b	$ff,$bb,$ff,$ba,$ff,$b9,$ff,$b8
	dc.b	$ff,$b8,$ff,$b7,$ff,$b6,$ff,$b6
	dc.b	$ff,$b5,$ff,$b5,$ff,$b4,$ff,$b3
	dc.b	$ff,$b3,$ff,$b3,$ff,$b2,$ff,$b2
	dc.b	$ff,$b1,$ff,$b1,$ff,$b1,$ff,$b1
	dc.b	$ff,$b0,$ff,$b0,$ff,$b0,$ff,$b0
	dc.b	$ff,$b0,$ff,$b0,$ff,$af,$ff,$af
	dc.b	$ff,$af,$ff,$af,$ff,$af,$ff,$af
	dc.b	$ff,$af,$ff,$af,$ff,$af,$ff,$b0
	dc.b	$ff,$b0,$ff,$b0,$ff,$b0,$ff,$b0
	dc.b	$ff,$b0,$ff,$b1,$ff,$b1,$ff,$b1
	dc.b	$ff,$b1,$ff,$b1,$ff,$b2,$ff,$b2
	dc.b	$ff,$b2,$ff,$b3,$ff,$b3,$ff,$b3
	dc.b	$ff,$b4,$ff,$b4,$ff,$b4,$ff,$b5
	dc.b	$ff,$b5,$ff,$b5,$ff,$b6,$ff,$b6
	dc.b	$ff,$b7,$ff,$b7,$ff,$b8,$ff,$b8
	dc.b	$ff,$b8,$ff,$b9,$ff,$b9,$ff,$ba
	dc.b	$ff,$ba,$ff,$bb,$ff,$bb,$ff,$bc
	dc.b	$ff,$bc,$ff,$bc,$ff,$bd,$ff,$bd
	dc.b	$ff,$be,$ff,$be,$ff,$be,$ff,$bf
	dc.b	$ff,$bf,$ff,$c0,$ff,$c0,$ff,$c0
	dc.b	$ff,$c1,$ff,$c1,$ff,$c1,$ff,$c1
	dc.b	$ff,$c2,$ff,$c2,$ff,$c2,$ff,$c2
	dc.b	$ff,$c2,$ff,$c3,$ff,$c3,$ff,$c3
	dc.b	$ff,$c3,$ff,$c3,$ff,$c3,$ff,$c3
	dc.b	$ff,$c3,$ff,$c3,$ff,$c3,$ff,$c3
	dc.b	$ff,$c2,$ff,$c2,$ff,$c2,$ff,$c2
	dc.b	$ff,$c2,$ff,$c1,$ff,$c1,$ff,$c1
	dc.b	$ff,$c0,$ff,$c0,$ff,$bf,$ff,$bf
	dc.b	$ff,$be,$ff,$be,$ff,$bd,$ff,$bd
	dc.b	$ff,$bc,$ff,$bb,$ff,$bb,$ff,$ba
	dc.b	$ff,$b9,$ff,$b8,$ff,$b8,$ff,$b7
	dc.b	$ff,$b6,$ff,$b5,$ff,$b4,$ff,$b3
	dc.b	$ff,$b2,$ff,$b2,$ff,$b1,$ff,$b0
	dc.b	$ff,$af,$ff,$ae,$ff,$ad,$ff,$ac
	dc.b	$ff,$ab,$ff,$aa,$ff,$a9,$ff,$a8
	dc.b	$ff,$a7,$ff,$a6,$ff,$a5,$ff,$a4
	dc.b	$ff,$a4,$ff,$a3,$ff,$a2,$ff,$a1
	dc.b	$ff,$a0,$ff,$a0,$ff,$9f,$ff,$9e
	dc.b	$ff,$9e,$ff,$9d,$ff,$9d,$ff,$9c
	dc.b	$ff,$9c,$ff,$9c,$ff,$9b,$ff,$9b
	dc.b	$ff,$9b,$ff,$9b,$ff,$9b,$ff,$9b
	dc.b	$ff,$9b,$ff,$9c,$ff,$9c,$ff,$9c
	dc.b	$ff,$9d,$ff,$9d,$ff,$9e,$ff,$9f
	dc.b	$ff,$a0,$ff,$a0,$ff,$a1,$ff,$a3
	dc.b	$ff,$a4,$ff,$a5,$ff,$a6,$ff,$a8
	dc.b	$ff,$a9,$ff,$ab,$ff,$ad,$ff,$ae
	dc.b	$ff,$b0,$ff,$b2,$ff,$b4,$ff,$b6
	dc.b	$ff,$b8,$ff,$bb,$ff,$bd,$ff,$bf
	dc.b	$ff,$c2,$ff,$c4,$ff,$c7,$ff,$c9
	dc.b	$ff,$cc,$ff,$ce,$ff,$d1,$ff,$d4
	dc.b	$ff,$d6,$ff,$d9,$ff,$dc,$ff,$df
	dc.b	$ff,$e2,$ff,$e4,$ff,$e7,$ff,$ea
	dc.b	$ff,$ed,$ff,$f0,$ff,$f2,$ff,$f5
	dc.b	$ff,$f8,$ff,$fb,$ff,$fe,0,0
	dc.b	0,3,0,6,0,8,0,$b
	dc.b	0,$d,0,$10,0,$12,0,$15
	dc.b	0,$17,0,$19,0,$1c,0,$1e
	dc.b	0,' ',0,'"',0,'$',0,'&'
	dc.b	0,'(',0,'*',0,',',0,'.'
	dc.b	0,'/',0,'1',0,'3',0,'4'
	dc.b	0,'6',0,'7',0,'9',0,':'
	dc.b	0,';',0,'=',0,'>',0,'?'
	dc.b	0,'@',0,'A',0,'B',0,'C'
	dc.b	0,'D',0,'E',0,'F',0,'G'
	dc.b	0,'G',0,'H',0,'I',0,'I'
	dc.b	0,'J',0,'J',0,'K',0,'L'
	dc.b	0,'L',0,'L',0,'M',0,'M'
	dc.b	0,'N',0,'N',0,'N',0,'N'
	dc.b	0,'O',0,'O',0,'O',0,'O'
	dc.b	0,'O',0,'O',0,'P',0,'P'
	dc.b	0,'P',0,'P',0,'P',0,'P'
	dc.b	0,'P',0,'P',0,'P',0,'O'
	dc.b	0,'O',0,'O',0,'O',0,'O'
	dc.b	0,'O',0,'N',0,'N',0,'N'
	dc.b	0,'N',0,'N',0,'M',0,'M'
	dc.b	0,'M',0,'L',0,'L',0,'L'
	dc.b	0,'K',0,'K',0,'K',0,'J'
	dc.b	0,'J',0,'J',0,'I',0,'I'
	dc.b	0,'H',0,'H',0,'G',0,'G'
	dc.b	0,'G',0,'F',0,'F',0,'E'
	dc.b	0,'E',0,'D',0,'D',0,'C'
	dc.b	0,'C',0,'C',0,'B',0,'B'
	dc.b	0,'A',0,'A',0,'A',0,'@'
	dc.b	0,'@',0,'?',0,'?',0,'?'
	dc.b	0,'>',0,'>',0,'>',0,'>'
	dc.b	0,'=',0,'=',0,'=',0,'='
	dc.b	0,'=',0,'<',0,'<',0,'<'
	dc.b	0,'<',0,'<',0,'<',0,'<'
	dc.b	0,'<',0,'<',0,'<',0,'<'
	dc.b	0,'=',0,'=',0,'=',0,'='
	dc.b	0,'=',0,'>',0,'>',0,'>'
	dc.b	0,'?',0,'?',0,'@',0,'@'
	dc.b	0,'A',0,'A',0,'B',0,'B'
	dc.b	0,'C',0,'D',0,'D',0,'E'
	dc.b	0,'F',0,'G',0,'G',0,'H'

L_moving_logo_y_seq:
	dc.b	0,$c,0,$c,0,$c,0,$d
	dc.b	0,$d,0,$d,0,$e,0,$e
	dc.b	0,$e,0,$e,0,$f,0,$f
	dc.b	0,$f,0,$10,0,$10,0,$11
	dc.b	0,$11,0,$11,0,$12,0,$12
	dc.b	0,$12,0,$13,0,$13,0,$13
	dc.b	0,$14,0,$14,0,$14,0,$14
	dc.b	0,$15,0,$15,0,$15,0,$15
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$15
	dc.b	0,$15,0,$15,0,$15,0,$14
	dc.b	0,$14,0,$14,0,$13,0,$13
	dc.b	0,$12,0,$11,0,$11,0,$10
	dc.b	0,$10,0,$f,0,$e,0,$d
	dc.b	0,$c,0,$c,0,$b,0,$a
	dc.b	0,9,0,8,0,7,0,6
	dc.b	0,5,0,4,0,3,0,2
	dc.b	0,1,0,0,$ff,$ff,$ff,$fe
	dc.b	$ff,$fd,$ff,$fc,$ff,$fb,$ff,$fa
	dc.b	$ff,$f9,$ff,$f9,$ff,$f8,$ff,$f7
	dc.b	$ff,$f6,$ff,$f5,$ff,$f4,$ff,$f4
	dc.b	$ff,$f3,$ff,$f2,$ff,$f1,$ff,$f1
	dc.b	$ff,$f0,$ff,$ef,$ff,$ef,$ff,$ee
	dc.b	$ff,$ee,$ff,$ed,$ff,$ed,$ff,$ed
	dc.b	$ff,$ec,$ff,$ec,$ff,$eb,$ff,$eb
	dc.b	$ff,$eb,$ff,$eb,$ff,$ea,$ff,$ea
	dc.b	$ff,$ea,$ff,$ea,$ff,$ea,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$ea,$ff,$ea,$ff,$ea
	dc.b	$ff,$ea,$ff,$ea,$ff,$ea,$ff,$ea
	dc.b	$ff,$ea,$ff,$eb,$ff,$eb,$ff,$eb
	dc.b	$ff,$eb,$ff,$eb,$ff,$ec,$ff,$ec
	dc.b	$ff,$ec,$ff,$ec,$ff,$ec,$ff,$ed
	dc.b	$ff,$ed,$ff,$ed,$ff,$ed,$ff,$ee
	dc.b	$ff,$ee,$ff,$ee,$ff,$ee,$ff,$ef
	dc.b	$ff,$ef,$ff,$ef,$ff,$f0,$ff,$f0
	dc.b	$ff,$f0,$ff,$f0,$ff,$f1,$ff,$f1
	dc.b	$ff,$f1,$ff,$f1,$ff,$f2,$ff,$f2
	dc.b	$ff,$f2,$ff,$f2,$ff,$f3,$ff,$f3
	dc.b	$ff,$f3,$ff,$f3,$ff,$f3,$ff,$f4
	dc.b	$ff,$f4,$ff,$f4,$ff,$f4,$ff,$f4
	dc.b	$ff,$f4,$ff,$f5,$ff,$f5,$ff,$f5
	dc.b	$ff,$f5,$ff,$f5,$ff,$f5,$ff,$f5
	dc.b	$ff,$f5,$ff,$f5,$ff,$f5,$ff,$f5
	dc.b	$ff,$f5,$ff,$f5,$ff,$f5,$ff,$f5
	dc.b	$ff,$f4,$ff,$f4,$ff,$f4,$ff,$f4
	dc.b	$ff,$f4,$ff,$f4,$ff,$f3,$ff,$f3
	dc.b	$ff,$f3,$ff,$f3,$ff,$f3,$ff,$f2
	dc.b	$ff,$f2,$ff,$f2,$ff,$f1,$ff,$f1
	dc.b	$ff,$f1,$ff,$f1,$ff,$f0,$ff,$f0
	dc.b	$ff,$f0,$ff,$ef,$ff,$ef,$ff,$ee
	dc.b	$ff,$ee,$ff,$ee,$ff,$ed,$ff,$ed
	dc.b	$ff,$ed,$ff,$ec,$ff,$ec,$ff,$ec
	dc.b	$ff,$eb,$ff,$eb,$ff,$eb,$ff,$eb
	dc.b	$ff,$ea,$ff,$ea,$ff,$ea,$ff,$ea
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$e9
	dc.b	$ff,$e9,$ff,$e9,$ff,$e9,$ff,$ea
	dc.b	$ff,$ea,$ff,$ea,$ff,$ea,$ff,$eb
	dc.b	$ff,$eb,$ff,$eb,$ff,$ec,$ff,$ec
	dc.b	$ff,$ed,$ff,$ee,$ff,$ee,$ff,$ef
	dc.b	$ff,$ef,$ff,$f0,$ff,$f1,$ff,$f2
	dc.b	$ff,$f3,$ff,$f3,$ff,$f4,$ff,$f5
	dc.b	$ff,$f6,$ff,$f7,$ff,$f8,$ff,$f9
	dc.b	$ff,$fa,$ff,$fb,$ff,$fc,$ff,$fd
	dc.b	$ff,$fe,$ff,$ff,0,0,0,1
	dc.b	0,2,0,3,0,4,0,5
	dc.b	0,6,0,6,0,7,0,8
	dc.b	0,9,0,$a,0,$b,0,$b
	dc.b	0,$c,0,$d,0,$e,0,$e
	dc.b	0,$f,0,$10,0,$10,0,$11
	dc.b	0,$11,0,$12,0,$12,0,$12
	dc.b	0,$13,0,$13,0,$14,0,$14
	dc.b	0,$14,0,$14,0,$15,0,$15
	dc.b	0,$15,0,$15,0,$15,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$16,0,$16,0,$16
	dc.b	0,$16,0,$15,0,$15,0,$15
	dc.b	0,$15,0,$15,0,$15,0,$15
	dc.b	0,$15,0,$14,0,$14,0,$14
	dc.b	0,$14,0,$14,0,$13,0,$13
	dc.b	0,$13,0,$13,0,$13,0,$12
	dc.b	0,$12,0,$12,0,$12,0,$11
	dc.b	0,$11,0,$11,0,$11,0,$10
	dc.b	0,$10,0,$10,0,$f,0,$f
	dc.b	0,$f,0,$f,0,$e,0,$e
	dc.b	0,$e,0,$e,0,$d,0,$d
	dc.b	0,$d,0,$d,0,$c,0,$c
	dc.b	0,$c,0,$c,0,$c,0,$b
	dc.b	0,$b,0,$b,0,$b,0,$b
	dc.b	0,$b,0,$a,0,$a,0,$a
	dc.b	0,$a,0,$a,0,$a,0,$a
	dc.b	0,$a,0,$a,0,$a,0,$a
	dc.b	0,$a,0,$a,0,$a,0,$a
	dc.b	0,$b,0,$b,0,$b,0,$b
	dc.b	0,$b,0,$b,0,$c,0,$c

L_clear_logo_buf1:	; @ = $C5F6
	dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
L_clear_logo_buf2:	; @ = $C616
	dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

clear_logo_adr1:	; @ = CLEAR_LOGO_1	$C636
	dc.b	0,0,$c5,$f6	; address already initialized to L_clear_logo_buf1
clear_logo_adr2:	; @ = CLEAR_LOGO_2	$C63A
	dc.b	0,0,$c6,$16	; address already initialized to L_clear_logo_buf2


clear_stars:	; Clears the previously displayed stars
	; Get the addresses saved during the display and put 0
	; Requires a double buffering
	
	; Swap buffer
	movea.l	L_stars_clear_buf1_adr(pc),a0
	move.l	L_stars_clear_buf2_adr(pc),STARS_CLEAR_BUF1_ADR
	move.l	a0,STARS_CLEAR_BUF2_ADR
	
	movea.l	L_Log_Base(pc),a1
	addq.l	#4,a1	; 3rd bitplan
	moveq	#0,d4
	
	; Unrolled loop ;) for 100 stars
	REPT 100
	move.w	(a0)+,d1
	move.l	d4,0(a1,d1.w)
	ENDR
	
	move.w	#0,$ffff8240.w	; For measuring CPU time ?
	rts

draw_stars:	movea.l	L_stars_clear_buf2_adr(pc),a4	; Buffer to save addresses of stars for clearing at next iteration
	lea	STAR_DATA_PTR,a3
	
	movea.l	L_Log_Base(pc),a1
	addq.l	#4,a1	; 3rd bitplan
	
	moveq	#$13,d0	; 20 * 5 = 100 stars (partially unrolled loop)
	
.loop:	movea.l	(a3),a5	; Data address in sequence for current star
	move.w	(a5)+,d1	; Get delta screen address
	bmi.s	.star1_rewind	; End of sequence for current star ?
.star1:	move.l	(a5)+,d2	; 2 bitplane data (several possible colors for stars) for current star
	or.l	d2,0(a1,d1.w)	; Display star
	move.w	d1,(a4)+	; Save the delta screen address in buffer for clearing at next iteration
	move.l	a5,(a3)	; Save new data address in sequence for current star
	
	movea.l	8(a3),a5	; Next star, same process
	move.w	(a5)+,d1
	bmi.s	.star2_rewind
.star2:	move.l	(a5)+,d2
	or.l	d2,0(a1,d1.w)
	move.w	d1,(a4)+
	move.l	a5,8(a3)
	
	movea.l	16(a3),a5	; Next star, same process
	move.w	(a5)+,d1
	bmi.s	.star3_rewind
.star3:	move.l	(a5)+,d2
	or.l	d2,0(a1,d1.w)
	move.w	d1,(a4)+
	move.l	a5,16(a3)
	
	movea.l	24(a3),a5	; Next star, same process
	move.w	(a5)+,d1
	bmi.s	.star4_rewind
.star4:	move.l	(a5)+,d2
	or.l	d2,0(a1,d1.w)
	move.w	d1,(a4)+
	move.l	a5,24(a3)
	
	movea.l	32(a3),a5	; Next star, same process
	move.w	(a5)+,d1
	bmi.s	.star5_rewind
.star5:	move.l	(a5)+,d2
	or.l	d2,0(a1,d1.w)
	move.w	d1,(a4)+
	move.l	a5,32(a3)
	
	lea	40(a3),a3
	dbf	d0,.loop
	rts
	
.star1_rewind:	movea.l	4(a3),a5	; Get the backuped begin address
	move.w	(a5)+,d1	; set it back
	bra.s	.star1
.star2_rewind:	movea.l	12(a3),a5
	move.w	(a5)+,d1
	bra.s	.star2
.star3_rewind:	movea.l	20(a3),a5
	move.w	(a5)+,d1
	bra.s	.star3
.star4_rewind:	movea.l	28(a3),a5
	move.w	(a5)+,d1
	bra.s	.star4
.star5_rewind:	movea.l	36(a3),a5
	move.w	(a5)+,d1
	bra.s	.star5



draw_SWSC:	bsr	fill_SWSC_buffer_line

	movea.l	L_Log_Base(pc),a0
	lea	18724(a0),a0		; Line #117, 3rd bitplan
	
	lea	SWSC_BUFFER,a5
	lea	swsc_X_size_table(pc),a3
	lea	swsc_Y_table(pc),a4
	adda.l	L_SWSC_Buf_Pos(pc),a5	; Set to current position in buffer
	
	moveq	#$51,d1		; 82 lines
.loopLine:	move.l	(a5)+,d3		; d3 = char address in font
	bmi	.emptyLine		; if -1, empty line
	
	movea.l	d3,a1		; a1 = char address in font
	adda.w	(a3)+,a0		; horizontal screen jump to word where the char will be displayed		
	adda.w	(a3)+,a1		; Select char size and X preshift to be used for display
	move.w	(a1)+,d0		; Read the first 16 pixels
	or.w	d0,(a0)		; OR with previous char (because chars are shifted across columns)
	move.w	(a1),d0		; Then read the next 16 pixels	
	or.w	d0,8(a0)		; And OR again to screen
	
	; Do the same thing for the next 11 chars 
	REPT 11
	adda.w	(a3)+,a0
	movea.l	(a5)+,a1
	adda.w	(a3)+,a1
	move.w	(a1)+,d0
	or.w	d0,(a0)
	move.w	(a1),d0
	or.w	d0,8(a0)
	ENDR 
	
.nextLine:	adda.w	(a4)+,a5		; Select the next line in buffer to be displayed
	dbf	d1,.loopLine
	rts

.emptyLine:	; Empty line, display nothing
	; Only update pointers
	lea	44(a5),a5	; Next line in buffer (4*12)
	adda.w	(a3),a0	; Perform X jumps on screen address
	adda.w	4(a3),a0
	adda.w	8(a3),a0
	adda.w	12(a3),a0
	adda.w	16(a3),a0
	adda.w	20(a3),a0
	adda.w	24(a3),a0
	adda.w	28(a3),a0
	adda.w	32(a3),a0
	adda.w	36(a3),a0
	adda.w	40(a3),a0
	adda.w	44(a3),a0
	lea	48(a3),a3
	bra	.nextLine

clear_SWSC:	; Cleans the previous displayed SWSC per sections
	moveq	#0,d1
	movea.l	L_Log_Base(pc),a0
	lea	18724(a0),a0	; Line 118 of screen + 2nd bitplan
	
	lea	56(a0),a0
	moveq	#$a,d0
.loop1:	move.w	d1,(a0)
	move.w	d1,8(a0)
	move.w	d1,16(a0)
	move.w	d1,24(a0)
	move.w	d1,32(a0)
	move.w	d1,40(a0)	; 96 pixel for first section
	lea	160(a0),a0
	dbf	d0,.loop1
	
	lea	-8(a0),a0
	moveq	#$a,d0
.loop2:	move.w	d1,(a0)
	move.w	d1,8(a0)
	move.w	d1,16(a0)
	move.w	d1,24(a0)
	move.w	d1,32(a0)
	move.w	d1,40(a0)
	move.w	d1,48(a0)
	move.w	d1,56(a0)
	lea	160(a0),a0
	dbf	d0,.loop2
	
	lea	-8(a0),a0
	moveq	#$b,d0
.loop3:	move.w	d1,(a0)
	move.w	d1,8(a0)
	move.w	d1,16(a0)
	move.w	d1,24(a0)
	move.w	d1,32(a0)
	move.w	d1,40(a0)
	move.w	d1,48(a0)
	move.w	d1,56(a0)
	move.w	d1,64(a0)
	move.w	d1,72(a0)
	lea	160(a0),a0
	dbf	d0,.loop3
	
	lea	-8(a0),a0
	moveq	#$b,d0
.loop4:	move.w	d1,(a0)
	move.w	d1,8(a0)
	move.w	d1,16(a0)
	move.w	d1,24(a0)
	move.w	d1,32(a0)
	move.w	d1,40(a0)
	move.w	d1,48(a0)
	move.w	d1,56(a0)
	move.w	d1,64(a0)
	move.w	d1,72(a0)
	move.w	d1,80(a0)
	move.w	d1,88(a0)
	lea	160(a0),a0
	dbf	d0,.loop4
	
	lea	-8(a0),a0
	moveq	#3,d0
.loop5:	move.w	d1,(a0)
	move.w	d1,8(a0)
	move.w	d1,16(a0)
	move.w	d1,24(a0)
	move.w	d1,32(a0)
	move.w	d1,40(a0)
	move.w	d1,48(a0)
	move.w	d1,56(a0)
	move.w	d1,64(a0)
	move.w	d1,72(a0)
	move.w	d1,80(a0)
	move.w	d1,88(a0)
	move.w	d1,96(a0)
	lea	160(a0),a0
	dbf	d0,.loop5
	
	moveq	#7,d0
.loop6:	move.w	d1,(a0)
	move.w	d1,8(a0)
	move.w	d1,16(a0)
	move.w	d1,24(a0)
	move.w	d1,32(a0)
	move.w	d1,40(a0)
	move.w	d1,48(a0)
	move.w	d1,56(a0)
	move.w	d1,64(a0)
	move.w	d1,72(a0)
	move.w	d1,80(a0)
	move.w	d1,88(a0)
	move.w	d1,96(a0)
	move.w	d1,104(a0)
	lea	160(a0),a0
	dbf	d0,.loop6
	
	lea	-8(a0),a0
	moveq	#$b,d0
.loop7:	move.w	d1,(a0)
	move.w	d1,8(a0)
	move.w	d1,16(a0)
	move.w	d1,24(a0)
	move.w	d1,32(a0)
	move.w	d1,40(a0)
	move.w	d1,48(a0)
	move.w	d1,56(a0)
	move.w	d1,64(a0)
	move.w	d1,72(a0)
	move.w	d1,80(a0)
	move.w	d1,88(a0)
	move.w	d1,96(a0)
	move.w	d1,104(a0)
	move.w	d1,112(a0)
	move.w	d1,120(a0)
	lea	160(a0),a0
	dbf	d0,.loop7
	
	lea	-8(a0),a0
	moveq	#$b,d0
.loop8:	move.w	d1,(a0)
	move.w	d1,8(a0)
	move.w	d1,16(a0)
	move.w	d1,24(a0)
	move.w	d1,32(a0)
	move.w	d1,40(a0)
	move.w	d1,48(a0)
	move.w	d1,56(a0)
	move.w	d1,64(a0)
	move.w	d1,72(a0)
	move.w	d1,80(a0)
	move.w	d1,88(a0)
	move.w	d1,96(a0)
	move.w	d1,104(a0)
	move.w	d1,112(a0)
	move.w	d1,120(a0)
	move.w	d1,128(a0)
	move.w	d1,136(a0)	; 288 pixels at max
	lea	160(a0),a0
	dbf	d0,.loop8
	rts

fill_SWSC_buffer_line:
	; Fill an intermediate buffer line before displaying to screen
	; this buffer contains a "non projected view" of the scrolltext containing the addresses of the font char lines (and not the bitmap itself)
	move.l	L_SWSC_Buf_Pos(pc),d3	; Current position (offset) in buffer
	move.l	SWSC_BUF_POS,d2		; Move.l d3,d2 would have been the same...
	addi.l	#$30,d2		; Next line (12 chars  * 4 bytes = $30) 
	cmp.l	L_SWSC_Buf_Mid(pc),d2	; Get middle of buffer
	blt	.setPos		; Current pos is higher the middle ?
	sub.l	L_SWSC_Buf_Mid(pc),d2	; Go back !
.setPos:	move.l	d2,SWSC_BUF_POS

	lea	SWSC_BUFFER,a5		; a5 = begin of buffer
	lea	21120(a5),a4		; a4 = middle of buffer
	lea	SWSC_FONT_BUFF,a0	; a0 = begin of the rescaled/X-shifted font
	lea	L_swsc_text(pc),a2	; a2 = begin of the text
	lea	swsc_Translation_Table(pc),a1	; a1 = text translation table (for chars without font items)
	move.w	L_Swsc_Text_Pos(pc),d4
	cmpi.b	#$ff,0(a2,d4.w)		; End of text
	bne	.noTextEnd
	clr.w	SWSC_TEXT_POS		; Go to begin of text

.noTextEnd:	cmpi.l	#$28,SWSC_CHAR_LINE4	; $28 = 40 = 4*10, so are we after the last line of the chars font ?
	blt	.readTextLine		; if no, read the text line
	
	moveq	#-1,d1		; if yes, then we insert empty lines for spacing
	move.l	d1,0(a5,d3.w)
	move.l	d1,0(a4,d3.w)
	move.l	d1,4(a5,d3.w)
	move.l	d1,4(a4,d3.w)
	move.l	d1,8(a5,d3.w)
	move.l	d1,8(a4,d3.w)
	move.l	d1,12(a5,d3.w)
	move.l	d1,12(a4,d3.w)
	move.l	d1,16(a5,d3.w)
	move.l	d1,16(a4,d3.w)
	move.l	d1,20(a5,d3.w)
	move.l	d1,20(a4,d3.w)
	move.l	d1,24(a5,d3.w)
	move.l	d1,24(a4,d3.w)
	move.l	d1,28(a5,d3.w)
	move.l	d1,28(a4,d3.w)
	move.l	d1,32(a5,d3.w)
	move.l	d1,32(a4,d3.w)
	move.l	d1,36(a5,d3.w)
	move.l	d1,36(a4,d3.w)
	move.l	d1,40(a5,d3.w)
	move.l	d1,40(a4,d3.w)
	move.l	d1,44(a5,d3.w)
	move.l	d1,44(a4,d3.w)
	addi.l	#$30,d3
	bra	.endLine
	
.readTextLine:	moveq	#$b,d7	; 12 chars per line
.nextChar:	moveq	#0,d1
	move.b	0(a2,d4.w),d1	; Get text char
	move.b	0(a1,d1.w),d1	; Translate it into Font char number (for chars without font)
	lea	swsc_char_to_fontaddr(pc),a3	; Then into address for char in font buffer
	lsl.w	#2,d1
	move.l	0(a3,d1.w),d1
	addi.l	#SWSC_FONT_BUFF,d1
	add.l	L_Swsc_Char_Line4(pc),d1
	move.l	d1,0(a5,d3.w)
	move.l	d1,0(a4,d3.w)
	addq.l	#4,d3
	addq.l	#1,d4
	dbf	d7,.nextChar
	
.endLine:	cmp.l	L_SWSC_Buf_Mid(pc),d3	; Manage buffer length (as at the begin of this sub-routine)
	blt	.setLineNumber
	sub.l	L_SWSC_Buf_Mid(pc),d3
	
.setLineNumber:	addq.l	#4,SWSC_CHAR_LINE4	; Next line (4 bytes per line)
	cmpi.l	#$48,SWSC_CHAR_LINE4	; Have we inserted also 10 lines of spaces ?
	blt	.exit
	subi.l	#$48,SWSC_CHAR_LINE4	; Yes, so we go back to line 0
	addi.w	#$c,SWSC_TEXT_POS	; And we go to next scroller line
.exit:	rts

L_Swsc_Text_Pos:
	dc.b	0,0	; @ = SWSC_TEXT_POS	$CD9C

L_Swsc_Char_Line4:
	dcb.w	2	; @ = SWSC_CHAR_LINE4	$CD9E
	dcb.w	2
	dc.b	0,'0'
swsc_char_to_fontaddr:
	dcb.w	3
	dc.b	' ',$80,0,0,'A',0,0,0
	dc.b	'a',$80,0,0,$82,0,0,0
	dc.b	$a2,$80,0,0,$c3,0,0,0
	dc.b	$e3,$80,0,1,4,0,0,1
	dc.b	'$',$80,0,1,'E',0,0,1
	dc.b	'e',$80,0,1,$86,0,0,1
	dc.b	$a6,$80,0,1,$c7,0,0,1
	dc.b	$e7,$80,0,2,8,0,0,2
	dc.b	'(',$80,0,2,'I',0,0,2
	dc.b	'i',$80,0,2,$8a,0,0,2
	dc.b	$aa,$80,0,2,$cb,0,0,2
	dc.b	$eb,$80,0,3,$c,0,0,3
	dc.b	',',$80,0,3,'M',0,0,3
	dc.b	'm',$80,0,3,$8e,0,0,3
	dc.b	$ae,$80

init_stars_seq:	lea	STAR_DATA_PTR,a0
	lea	STARS_DATA,a1
	move.l	a1,(a0)+	; start of data for Star #1
	move.l	a1,(a0)+	; backup for looping
	moveq	#$62,d0	; loop for the next 99 stars
.loop	cmpi.w	#$ffff,(a1)+	; Look for nex star data, '$ffff' is a delilmiter
	bne	.loop
	move.l	a1,(a0)+	; start of data for Star #i
	move.l	a1,(a0)+	; backup for looping
	dbf	d0,.loop
	rts

swsc_rescale_pixel:
	movem.l	d0-d3,-(a7)
	; d0 = pixel index
	; d1 = line number
	; d4 = currently processed pixel
	; a0 = source font address
	; a1 = rescale font address
	; The current routine is called for consecutive d4 pixel values, and selected d0 values
	; this is what allows the rescaling
	lsl.b	#1,d1	; 2 bytes per line in source data, so multiply per 2
	move.w	0(a0,d1.l),d2	; Get the 16 pixels of the char line. Memory done for each pixel... Not very efficient
	lsl.b	#1,d1	; 32 pixels (4 bytes) per line in destination data to handle X-shift , so multiply again per 2
	moveq	#$f,d3	; 16 pixels
	sub.b	d0,d3	; Reverse order for pixel index
	btst	d3,d2	; Is the pixel set in source ?
	bne	.srcPixelSet
	move.w	#$ffff,d0
	moveq	#$f,d3
	sub.b	d4,d3
	bclr	d3,d0
	and.w	d0,0(a1,d1.l)	; Clear pixel
	bra	.exit
.srcPixelSet:
	moveq	#0,d0
	moveq	#$f,d3
	sub.b	d4,d3
	bset	d3,d0
	or.w	d0,0(a1,d1.l)	; Set Pixel
.exit:	movem.l	(a7)+,d0-d3
	rts

swsc_rescale_shift_font:
	lea	swsc_font(pc),a0
	lea	SWSC_FONT_BUFF,a1
	moveq	#$1b,d6	; 28 chars (alphabet + dot and space). But it seems that J, Q and Z are missing in the font data.
			; This is managed later by a translation table
.nextChar:	moveq	#0,d4	; Currently processed pixel index
	moveq	#$c,d3	; 13 X-rescaling to be done
	lea	swsc_rescale_table(pc),a2 ; this table contains the list of "kept" pixels wen rescaling
.nextPixel:	move.b	(a2)+,d0	; d0 contains the index of a pixel to be kept
	tst.b	d0
	bmi	.nextSize	; no more pixels to be kept for this size
	moveq	#0,d1	; Current char line number
	moveq	#9,d5	; Char height = 10
.nextCharLine:	bsr	swsc_rescale_pixel
	addq.b	#1,d1	; Next line
	dbf	d5,.nextCharLine
	addq.l	#1,d4	; The current pixel index has been processed for all lines, we can process the next pixel
	bra	.nextPixel
.nextSize:	; Now process the X-shifting
	lea	40(a1),a3	; a3 = end of char in buffer
	moveq	#$e,d0	; 16 shifts to be done
	moveq	#1,d1	; Current shift number
.nextXShift:	moveq	#9,d7	; Char height = 10
.nextShiftedLine:	
	moveq	#0,d2
	move.w	(a1),d2	; Rescaled 16 pixels line
	swap	d2
	lsr.l	d1,d2	; Shift
	move.w	d2,2(a3)
	swap	d2
	move.w	d2,(a3)
	addq.l	#4,a3	; Next line
	addq.l	#4,a1
	dbf	d7,.nextShiftedLine
	addq.l	#1,d1	; Next shift number
	lea	-40(a1),a1
	dbf	d0,.nextXShift
	lea	640(a1),a1	; Go after all shifts
	moveq	#0,d4	
	dbf	d3,.nextPixel
	lea	20(a0),a0
	dbf	d6,.nextChar
	rts

clear_SWSC_buffers:
	movea.l	#SWSC_BUFFER,a1
	move.w	#$293f,d0	; 42 240 bytes = 880 lines of 12 chars of 4 bytes
	moveq	#-1,d1	; -1 for empty lines
.loop1	move.l	d1,(a1)+
	dbf	d0,.loop1
	movea.l	#SWSC_FONT_BUFF,a1	; 232 KBytes = 40 bytes * 16 shifts * 13 sizes * 28 chars
	move.w	#$e37f,d0
	moveq	#0,d1
.loop2	move.l	d1,(a1)+
	dbf	d0,.loop2
	rts

clear_screen_buffers:
	movea.l	#BUF_SCR_1,a0
	adda.l	#$7d00,a0
	moveq	#0,d1
	move.l	d1,d2
	move.l	d1,d3
	move.l	d1,d4
	move.l	d1,d5
	move.l	d1,d6
	move.l	d1,d7
	movea.l	d1,a1
	movea.l	d1,a2
	movea.l	d1,a3
	move.w	#$c7,d0
.loop1:	movem.l	a1-a3/d1-d7,-(a0)
	movem.l	a1-a3/d1-d7,-(a0)
	movem.l	a1-a3/d1-d7,-(a0)
	movem.l	a1-a3/d1-d7,-(a0)
	dbf	d0,.loop1
	movea.l	#BUF_SCR_2,a0
	adda.l	#$7d00,a0
	move.w	#$c7,d0
.loop2:	movem.l	a1-a3/d1-d7,-(a0)
	movem.l	a1-a3/d1-d7,-(a0)
	movem.l	a1-a3/d1-d7,-(a0)
	movem.l	a1-a3/d1-d7,-(a0)
	dbf	d0,.loop2
	rts

clear_buffers:	; Clear everything between the initial position of the distorted font data
	; up to the rasters buffer
	movea.l	#DIST_FONT_SRC,a0
	movea.l	#BUF_RASTER_1,a1
.loop1	clr.l	(a0)+
	cmpa.l	a1,a0
	blt.s	.loop1
	
	; Clear two buffers for distorted scroller
	; These buffer are pointed by L_DistScr_ParTable
	lea	$753e0,a0
	lea	$1c692,a1
	moveq	#0,d0
	move.w	#$834,d1 
.loop2	move.l	d0,(a0)+
	move.l	d0,(a1)+
	dbf	d1,.loop2
	rts

init_moving_logo:
	; Shift and compute mask of the letters of the moving logo
	lea	L_moving_logo_font(pc),a0
	lea	MOVING_LOGO_FONT_BUFF,a1
	moveq	#6,d0	; Nb chars
.nextChar:	moveq	#$f,d1	; Nb shifts
	moveq	#$10,d2	; Current shift
.nextShift:	lea	MOVING_LOGO_FONT,a0
	adda.l	MOVING_LOGO_CHAR_ADR,a0
	moveq	#9,d5	; Nb lines
.nextLine:	moveq	#0,d3
	move.w	(a0)+,d3
	lsl.l	d2,d3
	move.l	d3,d4
	move.w	d3,14(a1)
	swap	d3
	move.w	d3,8(a1)
	moveq	#0,d3
	move.w	(a0)+,d3
	lsl.l	d2,d3
	or.l	d3,d4
	move.w	d3,16(a1)
	swap	d3
	move.w	d3,10(a1)
	moveq	#0,d3
	move.w	(a0)+,d3
	lsl.l	d2,d3
	or.l	d3,d4
	move.w	d3,18(a1)
	swap	d3
	move.w	d3,12(a1)
	addq.l	#2,a0
	; Mask
	not.l	d4
	move.w	d4,4(a1)
	move.w	d4,6(a1)
	swap	d4
	move.w	d4,(a1)
	move.w	d4,2(a1)
	adda.l	#$14,a1
	dbf	d5,.nextLine
	subq.w	#1,d2
	dbf	d1,.nextShift
	addi.l	#$50,MOVING_LOGO_CHAR_ADR
	dbf	d0,.nextChar
	rts

	dcb.w	2		; @ = MOVING_LOGO_CHAR_ADR	$D028
L_moving_logo_font:			; @ = MOVING_LOGO_FONT	$D02C
	dc.b	$fc,'|',$e3,$8c,$e0,$c,0,0
	dc.b	$80,2,$7f,$fe,$7f,$fe,0,0
	dc.b	$ff,$ff,0,1,$7f,$ff,0,0
	dc.b	$ff,$ff,$ff,$fe,$80,0,0,0
	dc.b	$f3,$ff,$cc,$fe,$c0,$80,0,0
	dc.b	0,'@',0,$7f,0,'~',0,0
	dc.b	0,$7f,0,0,0,'>',0,0
	dc.b	0,$7f,0,'>',0,0,0,0
	dc.b	0,$7f,0,$7f,0,'A',0,0
	dc.b	0,'7',0,'+',0,'#',0,0
	dc.b	$fc,$1f,$cc,$1b,$cc,$1b,0,0
	dc.b	$84,$11,$fc,$1f,$fc,$1f,0,0
	dc.b	$fc,$1f,0,0,'x',$e,0,0
	dc.b	$ff,$7f,'~',$be,6,'0',0,0
	dc.b	$7f,$fe,$ff,$ff,0,0,0,0
	dc.b	0,0,$ff,$ff,$7f,$fe,0,0
	dc.b	$ff,$ff,0,0,$7f,$fe,0,0
	dc.b	$ff,'?~',$de,2,0,0,0
	dc.b	$fc,$1f,$fc,$1f,$84,$11,0,0
	dc.b	'l',$1f,'T',$1b,'D',$1b,0,0
	dc.b	'??8',$c7,'8',7,0,0
	dc.b	'@',1,$7f,$fe,$7f,$fe,0,0
	dc.b	$ff,$cf,$81,$b3,$ff,$83,0,0
	dc.b	$ff,$b0,$7f,'P',1,$10,0,0
	dc.b	$7f,$f0,$ff,$e0,0,0,0,0
	dc.b	1,$b0,$ff,'P',$7f,$10,0,0
	dc.b	$ff,0,0,0,'~',0,0,0
	dc.b	$ff,$ff,$ff,$83,$81,$83,0,0
	dc.b	$7f,$ff,$7f,$fe,'@',0,0,0
	dc.b	'??8',$c7,'8',7,0,0
	dc.b	$ee,'w',$d6,'k',$c6,'c',0,0
	dc.b	$82,'A',$fe,$7f,$fe,$7f,0,0
	dc.b	$fe,$7f,0,0,'|>',0,0
	dc.b	$fe,$7f,'|>',0,0,0,0
	dc.b	'~~',$fe,$7f,2,'@',0,0
	dc.b	$83,$c1,'~~~~',0,0
	dc.b	$ff,$ff,0,0,$7f,$fe,0,0
	dc.b	$ff,$ff,$ff,$ff,$80,1,0,0
	dc.b	$7f,$fe,$7f,$fe,'@',2,0,0
	dc.b	'>|1',$8c,'0',$c,0,0
	dc.b	'w',$9f,'I',$9b,'A',$9b,0,0
	dc.b	$80,'Q',$ff,$df,$ff,$df,0,0
	dc.b	$ff,$ff,0,0,$7f,$ce,0,0
	dc.b	$ff,$ff,$7f,$fe,0,$10,0,0
	dc.b	$7f,$fe,$ff,$ff,1,0,0,0
	dc.b	1,$80,$fe,$ff,'~',$fe,0,0
	dc.b	$fe,$7f,1,0,'~>',0,0
	dc.b	$ff,'?~',$1e,0,0,0,0
	dc.b	$ff,$1f,$ff,$1f,$81,$11,0,0
	dc.b	'g',$1f,'[',$1b,'C',$1b,0,0
	dc.b	$fc,'?',$e3,$c7,$e0,7,0,0
	dc.b	$80,1,$7f,$fe,$7f,$fe,0,0
	dc.b	$ff,$ff,0,0,$7f,$fe,0,0
	dc.b	$ff,$ff,$cf,$f3,$cc,'3',0,0
	dc.b	7,$e0,3,$c0,0,0,0,0
	dc.b	$fc,'?',$cf,$f3,$cf,$f3,0,0
	dc.b	$ff,$ff,$80,1,$ff,$ff,0,0
	dc.b	$ff,$ff,$7f,$fe,0,0,0,0
	dc.b	$ff,$ff,$ff,$ff,$80,1,0,0
	dc.b	'~~qŽp',$e,0,0
	dc.b	'|>s',$ce,'p',$e,0,0
	dc.b	$80,1,$ff,$ff,$ff,$ff,0,0
	dc.b	$ff,$ff,0,0,$7f,$fe,0,0
	dc.b	$ff,$ff,$7f,$fe,0,0,0,0
	dc.b	$7f,$fe,$ff,$ff,0,0,0,0
	dc.b	$80,1,$7f,$fe,$7f,$fe,0,0
	dc.b	$ff,$ff,0,0,$7f,$fe,0,0
	dc.b	$ff,$ff,$ff,$ff,$80,1,0,0
	dc.b	$7f,$fe,$7f,$fe,'@',2,0,0
	dc.b	'>|9',$9c,'8',$1c,0,0

prepare_scr_and_data:	; Back in black ;)
	moveq	#0,d0
	move.l	d0,d1
	move.l	d0,d2
	move.l	d0,d3
	move.l	d0,d4
	move.l	d0,d5
	move.l	d0,d6
	move.l	d0,d7
	movem.l	d0-d7,$ffff8240.w

	bsr	clear_buffers
	
	; Init screen pointers
	move.l	#BUF_SCR_1,LOG_BASE
	move.l	#BUF_SCR_2,PHY_BASE
	
	; Prepare Distorted scroller text data
	move.l	#$f85c,d0	; end of distorted scroll text
	subi.l	#DISTSCR_TEXT,d0
	lsl.l	#1,d0
	move.w	d0,DISTSCR_TEXT_L2
	clr.w	DISTSCR_TEXT_POS
	
	; Initialize buffers for clearing stars
	move.l	#$1c4de,STARS_CLEAR_BUF2_ADR
	move.l	#$1c5a8,STARS_CLEAR_BUF1_ADR
	
	; Additional inits for distorted scroller
	moveq	#0,d0
	movea.l	#DISTSCR_TEXT,a0
	move.b	(a0),d0		; Get first char		
	movea.l	#DISTSCR_CONV_TBL,a0
	move.b	0(a0,d0.w),d0		; Use conversion table to get sprite index
	lsl.l	#8,d0
	lsl.l	#1,d0
	addi.l	#DIST_FONT,d0
	move.l	d0,DISTSCR_CHAR_ADR	; Set the char sprite address
	
	move.w	#0,$b4a6
	move.l	#$1400,$b4aa
	
	; Moving logo: initialize a buffer with offsets between shifts in font
	lea	MOVING_LOGO_SHIFT_OFST,a0
	moveq	#0,d1
	moveq	#$f,d0
.loop1	move.l	d1,(a0)+
	addi.l	#$c8,d1
	dbf	d0,.loop1
	
	; Seems useless. Dead code ?
	lea	$77818,a0
	moveq	#0,d1
	moveq	#$b,d0
.loop2:	move.l	d1,(a0)+
	addi.l	#$f00,d1
	dbf	d0,.loop2
	
	; Fill a buffer with screen line address offsets : 0,160,320,...
	lea	BUF_LINE_OFFSET,a0
	moveq	#0,d1
	move.l	#$c7,d0	; 200 lines
.loop3	move.l	d1,(a0)+
	addi.l	#$a0,d1	; 160
	dbf	d0,.loop3
	
	; 
	lea	DIST_FONT_SRC,a0
	moveq	#8,d1
	move.w	#$27,d0
.loop4	move.w	d1,(a0)+
	dbf	d0,.loop4
	
	bsr	clear_SWSC_buffers
	bsr	init_stars_seq
	bsr	swsc_rescale_shift_font
	bsr	init_moving_logo

	bsr	save_vec
	
	movea.l	#$1c672,a0
	movem.l	$ff8240.l,a1/d6-d7/d0-d4
	movem.l	a1/d6-d7/d0-d4,(a0)
	movea.l	#VBL_INIT_PAL,a0
	movem.l	(a0),a1/d6-d7/d0-d4
	movem.l	a1/d6-d7/d0-d4,$ff8240.l
	
	bsr	set_vec
	
	clr.b	VBL_SYNC_FLAG
.wait_VBL	tst.b	VBL_SYNC_FLAG
	beq	.wait_VBL
	
	move.b	#0,$ffff8260.w
	move.b	#2,$ffff820a.w
	move.l	PHY_BASE,d0
	lsr.l	#8,d0
	move.b	d0,$ffff8203.w
	lsr.w	#8,d0
	move.b	d0,$ffff8201.w
	rts

copy_wizz_logo:	lea	WIZZ_LOGO,a0
	movea.l	#BUF_SCR_1,a1
	movea.l	#BUF_SCR_2,a2
	moveq	#$59,d0
.loop1:	moveq	#$13,d1
.loop2:	move.w	(a0),(a1)
	move.w	(a0)+,(a2)
	addq.l	#8,a1
	addq.l	#8,a2
	dbf	d1,.loop2
	dbf	d0,.loop1
	rts

demo_init:	; Relocate Distorted Font
	lea	DIST_FONT_SRC,a6
	lea	DIST_FONT,a5
	move.w	#$12bf,d0
.loopFont:	move.l	(a6)+,(a5)+
	dbf	d0,.loopFont
	
	; Relocate Music
	lea	$20c6a,a6
	lea	MUSIC_ADR,a5
	move.w	#$a37,d0
.loopMusic:	move.l	(a6)+,(a5)+
	dbf	d0,.loopMusic
	
	bsr	compute_rasters_top
	bsr	clear_screen_buffers
	bsr	copy_wizz_logo
	
	jsr	MUSIC_ADR	; music_init
	rts

main:	move.l	a7,SAV_A7
	movea.l	#STACK_ADR,a7 
	move	#$2700,sr
	
	bsr	demo_init
	bsr	prepare_scr_and_data
	
	; Set some data for SW Scroller
	move.l	#$d88a,d0	; End of SWSC text
	subi.l	#SWSC_TEXT,d0
	move.w	d0,SWSC_TEXT_LEN	; d0 =len of SWSC Text =  $330 = 816
	move.l	#$5280,SWSC_BUF_MID	; 21120 = middle of the 42240 bytes buffer
	
	; Sync with VBL
.nextVBL:	tst.b	VBL_SYNC_FLAG
	beq	.nextVBL
	clr.b	VBL_SYNC_FLAG
	
	; Set screen address
	move.l	L_Log_Base(pc),d0
	lsr.l	#8,d0
	move.b	d0,$ffff8203.w
	lsr.w	#8,d0
	move.b	d0,$ffff8201.w
	move.w	#0,$ffff8240.w
	
	; Following CPU times have been measured with Timer B disabled
	bsr	clear_SWSC		; Clear SWSC		: 26 scanlines = 13 312 cycles
	bsr	clear_stars		; Clear stars		:  6 scanlines =  3 072 cycles
	bsr	clear_moving_logo	; Clear Moving logo	:  9 scanlines =  4 608 cycles
	
	bsr	draw_dist_scroller	; Draw distorted scroller	: 70 scanlines = 35 840 cycles
	bsr	draw_stars		; Draw stars		: 19 scanlines =  9 728 cycles

	move.w	#0,$ffff8240.w	; To measure CPU time ?

	bsr	draw_SWSC		; Draw SWSC		: 71 scanlines = 36 352 cycles
	bsr	draw_moving_logo	; Draw Moving logo	: 36 scanlines = 18 432 cycles
	
	; Here, with timer B enabled, we are at scanline 176/200. So at 239/313. It remains almost 25% CPU left.
	
	; Double buffering
	move.l	L_Log_Base(pc),d0
	move.l	L_Phy_Base(pc),LOG_BASE
	move.l	d0,PHY_BASE
	
	tst.w	$b0.l	; Trap #12 -> Attract mode ?
	beq.s	.readKeyboard
	addq.w	#1,TIME_OUT_CNT
	cmpi.w	#$bb8,TIME_OUT_CNT	; 3000 frames -> 60 seconds
	bge	.quit
.readKeyboard:	move.b	$fffffc02.w,d0
	cmp.b	EXIT_KEY,d0		; Space pressed ?
	bne	.nextVBL
	move.b	#$b9,EXIT_KEY		; Space released ?
	cmpi.b	#$b9,d0
	bne	.nextVBL
.quit:	tst.b	VBL_SYNC_FLAG
	beq	.quit
	bsr	restore_vec
	movea.l	#$ff8240,a0
	movea.l	#$d510,a3
	movem.l	$d510,d0-d7
	movem.l	d0-d7,$ffff8240.w
	movea.l	SAV_A7,a7
	rts

	dcb.w	16	; @ = $D510
L_exit_key	dc.b	$39	; @ = EXIT_KEY		$D530
	dc.b	0,0,0
L_Log_Base:	dcb.w	2	; @ = LOG_BASE		$D534
L_Phy_Base:	dcb.w	2	; @ = PHY_BASE		$D538
	dcb.w	2	; $D53C
L_SWSC_Buf_Pos:	dcb.w	2	; @ = SWSC_BUF_POS	$D540
L_SWSC_Buf_Mid:	dcb.w	2	; @ = SWSC_BUF_MID	$D544
L_vbl_sync_flag:
	dcb.w	1	; @ = VBL_SYNC_FLAG	$D548
L_swsc_text_len	dcb.w	2	; @ = SWSC_TEXT_LEN	$D54A
L_stars_clear_buf2_adr
	dcb.w	2	; @ = STARS_CLEAR_BUF2_ADR	$D54E
L_stars_clear_buf1_adr:
	dcb.w	2	; @ = STARS_CLEAR_BUF1_ADR	$D552
L_sav_a7_lbl:	dcb.w	2	; @ = SAV_A7		$D556
L_swsc_text:	dc.b	'        '	; @ = SWSC_TEXT		$D55A
	dc.b	'     WEL'
	dc.b	'COME TO '
	dc.b	'THE STAR'
	dc.b	'WARS  SC'
	dc.b	'ROLLER  '
	dc.b	'        '
	dc.b	'     WRI'
	dc.b	'TTEN BY '
	dc.b	'    THE '
	dc.b	'       R'
	dc.b	'EALLY   '
	dc.b	' MEGAMIG'
	dc.b	'HTY  CAR'
	dc.b	'EBEARS! '
	dc.b	'    FROM'
	dc.b	'     THE'
	dc.b	'  UNION '
	dc.b	'        '
	dc.b	'    YOU '
	dc.b	'MUST NOT'
	dc.b	' FORGET '
	dc.b	'OUR  COP'
	dc.b	'Y PARTY '
	dc.b	'        '
	dc.b	'    YOU '
	dc.b	'CAN READ'
	dc.b	' WHERE  '
	dc.b	'AND WHEN'
	dc.b	' IT WILL'
	dc.b	' BE IN  '
	dc.b	'THE  MAI'
	dc.b	'N  MENU.'
	dc.b	'        '
	dc.b	'      CU'
	dc.b	'RRENT   '
	dc.b	'   MEMBE'
	dc.b	'R    STA'
	dc.b	'TUS  OF '
	dc.b	' THE  UN'
	dc.b	'ION     '
	dc.b	'        '
	dc.b	'    TEX '
	dc.b	'    DELT'
	dc.b	'A FORCE '
	dc.b	'  TNT CR'
	dc.b	'EW      '
	dc.b	'TCB     '
	dc.b	'LEV. SIX'
	dc.b	'TEEN REP'
	dc.b	'LICANTS '
	dc.b	' SOFTRUN'
	dc.b	'NER    G'
	dc.b	'ROUP    '
	dc.b	'        '
	dc.b	'      CR'
	dc.b	'EDITS   '
	dc.b	'        '
	dc.b	'        '
	dc.b	'THE     '
	dc.b	' CAREBEA'
	dc.b	'RS      '
	dc.b	'        '
	dc.b	' ALL COD'
	dc.b	'ING     '
	dc.b	'AND     '
	dc.b	'MATHEMAT'
	dc.b	'ICALCALC'
	dc.b	'ULATIONS'
	dc.b	'        '
	dc.b	'        '
	dc.b	'        '
	dc.b	'   TANIS'
	dc.b	'        '
	dc.b	'        '
	dc.b	'UNIONSPR'
	dc.b	'ITES    '
	dc.b	'        '
	dc.b	'        '
	dc.b	'    KNIG'
	dc.b	'HT HAWKS'
	dc.b	'   AMIGA'
	dc.b	'        '
	dc.b	'        '
	dc.b	'    FONT'
	dc.b	'        '
	dc.b	'        '
	dc.b	'        '
	dc.b	'      MA'
	dc.b	'D  MAX  '
	dc.b	'        '
	dc.b	'       M'
	dc.b	'USIC    '
	dc.b	'        '
	dc.b	'      MA'
	dc.b	'Y  THE  '
	dc.b	'  FORCE '
	dc.b	'BE    WI'
	dc.b	'TH YOU  '
	dc.b	'        '
	dc.b	'        '
	dc.b	'        '
	dc.b	$ff,$ff

swsc_Translation_Table:
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$17,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,0,1,2,3,4,5,6
	dc.b	7,8,$18,9,$a,$b,$c,$d
	dc.b	$e,$18,$f,$10,$11,$12,$13,$14
	dc.b	$15,$16,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18
	dc.b	$18,$18,$18,$18,$18,$18,$18,$18

swsc_rescale_table:	
	dc.b	0,1,2,3,4,5,6,7
	dc.b	8,9,$a,$b,$c,$d,$e,$f
	dc.b	$ff,0,1,2,3,4,5,6
	dc.b	8,9,$a,$b,$c,$d,$e,$f
	dc.b	$ff,0,1,2,4,5,6,7
	dc.b	8,9,$a,$c,$d,$e,$f,$ff
	dc.b	0,1,3,4,5,6,8,9
	dc.b	$a,$b,$d,$e,$f,$ff,0,2
	dc.b	3,4,6,7,8,$a,$b,$c
	dc.b	$e,$f,$ff,0,2,3,5,6
	dc.b	8,9,$b,$c,$e,$f,$ff,1
	dc.b	2,4,5,7,9,$a,$c,$d
	dc.b	$f,$ff,1,3,4,6,8,$a
	dc.b	$b,$d,$f,$ff,1,3,5,7
	dc.b	9,$b,$d,$f,$ff,1,4,6
	dc.b	8,$a,$d,$f,$ff,1,3,6
	dc.b	9,$b,$e,$ff,1,4,8,$b
	dc.b	$e,$ff,2,6,$a,$e,$ff,2
	dc.b	8,$d,$ff,4,$c,$ff,8,$ff
	
swsc_X_size_table:	; This table contains pairs of words.
		; There are 12 pairs per line (12 chars), and for the displayed 82 lines
		; Each pair is composed of:
		; - horizontal jump (delta screen address)
		; - offset in rescaled/X-shifted font to get the correct char size & X position
	dc.b	0,'8 ',8,0,8,$1e,'x'
	dc.b	0,0,$1f,'h',0,0,'"',$d8
	dc.b	0,8,$1e,$a0,0,0,$1f,$90
	dc.b	0,8,$1e,0,0,0,$1e,$f0
	dc.b	0,0,$1f,$e0,0,8,$1e,'('
	dc.b	0,0,$1f,$18,0,0,' ',8
	dc.b	0,$80,$1f,$e0,0,8,$1e,'P'
	dc.b	0,0,$1f,'@',0,0,' 0'
	dc.b	0,8,$1e,$a0,0,0,$1f,$90
	dc.b	0,8,$1e,0,0,0,$1e,$f0
	dc.b	0,0,$1f,$e0,0,8,$1e,'P'
	dc.b	0,0,$1f,'@',0,0,' 0'
	dc.b	0,$80,$1d,$10,0,8,$1e,'('
	dc.b	0,0,$1f,$18,0,0,' ',8
	dc.b	0,8,$1b,$f8,0,0,$1f,$90
	dc.b	0,8,$1e,0,0,0,$1e,$f0
	dc.b	0,0,' ',8,0,8,$1e,'x'
	dc.b	0,0,$1f,'h',0,0,$1d,$d8
	dc.b	0,$80,$1f,'h',0,0,$1d,$d8
	dc.b	0,8,$1e,$f0,0,0,$1d,'`'
	dc.b	0,8,$1e,'x',0,0,$1c,$e8
	dc.b	0,8,$1e,0,0,0,$1f,$18
	dc.b	0,0,' ',8,0,8,$1e,$a0
	dc.b	0,0,$1f,$90,0,8,$1e,'('
	dc.b	0,'x',$1f,'@',0,0,$1d,$b0
	dc.b	0,8,$1c,'H',0,0,$1f,$e0
	dc.b	0,8,$1e,'x',0,0,$1c,$e8
	dc.b	0,8,$1e,0,0,0,$1f,$18
	dc.b	0,0,$1d,$88,0,8,$1c,' '
	dc.b	0,0,$1f,$b8,0,8,$1e,'P'
	dc.b	0,'x',$1c,'p',0,0,$1d,$88
	dc.b	0,8,$1c,' ',0,0,$1d,'8'
	dc.b	0,8,$1b,$d0,0,0,$1c,$e8
	dc.b	0,8,$1b,$80,0,0,$1c,$98
	dc.b	0,0,$1d,$b0,0,8,$1e,$c8
	dc.b	0,0,$1f,$e0,0,8,$1e,'x'
	dc.b	0,'x',$1c,'H',0,0,$1d,'`'
	dc.b	0,8,$1b,$f8,0,0,$1d,$10
	dc.b	0,8,$1e,'P',0,0,$1c,$e8
	dc.b	0,8,$1b,$80,0,0,$1c,$98
	dc.b	0,0,$1d,$b0,0,8,$1e,$f0
	dc.b	0,0,' ',8,0,8,$1c,' '
	dc.b	0,'x',$1c,' ',0,0,$1d,'8'
	dc.b	0,8,$1b,$d0,0,0,$1d,$10
	dc.b	0,8,$1b,$a8,0,0,$1c,$e8
	dc.b	0,8,$1b,$80,0,0,$1c,$98
	dc.b	0,0,$1d,$d8,0,8,$1c,'p'
	dc.b	0,0,$1d,$b0,0,8,$1c,'H'
	dc.b	0,'x',$1b,$d0,0,0,$1d,$10
	dc.b	0,8,$19,'(',0,0,$1c,$e8
	dc.b	0,8,$1b,$a8,0,0,$1c,$c0
	dc.b	0,8,$1b,$80,0,0,$1c,$c0
	dc.b	0,0,$1d,$d8,0,8,$1c,$98
	dc.b	0,0,$1d,$d8,0,8,$1c,'p'
	dc.b	0,'x',$1b,$a8,0,0,$1c,$e8
	dc.b	0,8,$1b,$a8,0,0,$1a,'@'
	dc.b	0,8,$19,0,0,0,$1c,$c0
	dc.b	0,8,$1b,$80,0,0,$1c,$c0
	dc.b	0,8,$1b,$80,0,0,$1c,$c0
	dc.b	0,0,$1b,'X',0,8,$1c,$98
	dc.b	0,'x',$1b,$80,0,0,$1c,$c0
	dc.b	0,8,$1b,$80,0,0,$1c,$c0
	dc.b	0,8,$1b,$80,0,0,$1c,$c0
	dc.b	0,8,$1b,$80,0,0,$1c,$c0
	dc.b	0,8,$19,0,0,0,$1a,'@'
	dc.b	0,8,$19,0,0,0,$1a,'@'
	dc.b	0,'p',$1b,'0',0,8,$1c,$98
	dc.b	0,0,$1d,$d8,0,8,$1a,$18
	dc.b	0,0,$1b,'X',0,8,$1c,$c0
	dc.b	0,8,$19,0,0,0,$1a,'@'
	dc.b	0,8,$1b,$a8,0,0,$1c,$e8
	dc.b	0,8,$19,'(',0,0,$1a,'h'
	dc.b	0,'p',$1b,8,0,8,$19,$c8
	dc.b	0,0,$1b,'0',0,8,$19,$f0
	dc.b	0,0,$1b,'X',0,8,$1a,$18
	dc.b	0,8,$19,0,0,0,$1c,$e8
	dc.b	0,8,$19,'(',0,0,$1d,$10
	dc.b	0,8,$19,'P',0,0,$1d,'8'
	dc.b	0,'p',$1d,'`',0,8,$19,$a0
	dc.b	0,0,$1b,8,0,8,$19,$f0
	dc.b	0,0,$1d,$d8,0,8,$1a,$18
	dc.b	0,8,$19,0,0,0,$1a,'h'
	dc.b	0,8,$19,'(',0,0,$1a,$90
	dc.b	0,8,$19,'x',0,0,$1a,$e0
	dc.b	0,'p',$1a,$90,0,8,$19,'x'
	dc.b	0,0,$1a,$e0,0,8,$19,$c8
	dc.b	0,0,$1b,'0',0,8,$1a,$18
	dc.b	0,8,$19,0,0,0,$1a,'h'
	dc.b	0,8,$19,'P',0,0,$1a,$b8
	dc.b	0,8,$19,$a0,0,0,$1b,8
	dc.b	0,'p',$1a,'h',0,8,$19,'P'
	dc.b	0,0,$1a,$b8,0,8,$17,' '
	dc.b	0,0,$1b,'0',0,8,$1a,$18
	dc.b	0,8,$19,0,0,0,$1a,'h'
	dc.b	0,8,$16,$d0,0,0,$1a,$e0
	dc.b	0,8,$19,$c8,0,0,$1b,'0'
	dc.b	0,'p',$17,$98,0,8,$19,'('
	dc.b	0,0,$18,$10,0,8,$19,$a0
	dc.b	0,0,$1b,8,0,8,$1a,$18
	dc.b	0,8,$19,0,0,0,$17,$e8
	dc.b	0,8,$19,'x',0,0,$18,'`'
	dc.b	0,8,$19,$f0,0,0,$1b,'X'
	dc.b	0,'p',$17,'p',0,8,$19,0
	dc.b	0,0,$17,$e8,0,8,$19,'x'
	dc.b	0,0,$1b,8,0,8,$17,'p'
	dc.b	0,8,$19,0,0,0,$1a,$90
	dc.b	0,8,$16,$f8,0,0,$1b,8
	dc.b	0,8,$1a,$18,0,8,$16,$80
	dc.b	0,'h',$19,$c8,0,0,$1b,'X'
	dc.b	0,8,$1a,'h',0,8,$16,$d0
	dc.b	0,0,$18,'`',0,8,$17,'p'
	dc.b	0,8,$16,$80,0,0,$1a,$90
	dc.b	0,8,$19,$a0,0,0,$1b,'0'
	dc.b	0,8,$17,$98,0,8,$16,$a8
	dc.b	0,'h',$16,$f8,0,0,$1b,'0'
	dc.b	0,8,$1a,'@',0,8,$19,'P'
	dc.b	0,0,$18,'`',0,8,$17,'p'
	dc.b	0,8,$16,$80,0,0,$18,$10
	dc.b	0,8,$17,' ',0,0,$18,$b0
	dc.b	0,8,$17,$c0,0,8,$16,$d0
	dc.b	0,'h',$16,$d0,0,0,$18,'`'
	dc.b	0,8,$17,$98,0,8,$16,$a8
	dc.b	0,0,$18,'8',0,8,$17,'p'
	dc.b	0,8,$16,$80,0,0,$18,$10
	dc.b	0,8,$17,'H',0,0,$18,$d8
	dc.b	0,8,$17,$e8,0,8,$19,$a0
	dc.b	0,'h',$16,$a8,0,0,$18,'8'
	dc.b	0,8,$17,'p',0,8,$16,$80
	dc.b	0,0,$18,'8',0,8,$17,'H'
	dc.b	0,8,$16,$80,0,0,$18,'8'
	dc.b	0,8,$17,'H',0,8,$16,$80
	dc.b	0,0,$18,$10,0,8,$17,'H'
	dc.b	0,'`',$16,'X',0,8,$18,$10
	dc.b	0,8,$17,'H',0,8,$16,$80
	dc.b	0,0,$15,$90,0,8,$17,'H'
	dc.b	0,8,$16,$80,0,0,$18,'8'
	dc.b	0,8,$17,'p',0,8,$16,$80
	dc.b	0,0,$18,'8',0,8,$17,'p'
	dc.b	0,'`',$18,$b0,0,8,$17,$e8
	dc.b	0,8,$17,' ',0,0,$18,$d8
	dc.b	0,8,$18,$10,0,8,$17,'H'
	dc.b	0,8,$16,$80,0,0,$18,'8'
	dc.b	0,8,$17,'p',0,8,$16,$a8
	dc.b	0,0,$18,'`',0,8,$17,$98
	dc.b	0,'`',$18,$88,0,8,$17,$c0
	dc.b	0,8,$14,'x',0,0,$16,'0'
	dc.b	0,8,$18,$10,0,8,$17,'H'
	dc.b	0,8,$16,$80,0,0,$15,$b8
	dc.b	0,8,$14,$f0,0,8,$16,$d0
	dc.b	0,0,$18,$88,0,8,$15,'@'
	dc.b	0,'`',$15,$b8,0,8,$17,$98
	dc.b	0,8,$14,'P',0,0,$18,$b0
	dc.b	0,8,$15,'h',0,8,$17,'H'
	dc.b	0,8,$14,0,0,0,$15,$b8
	dc.b	0,8,$15,$18,0,8,$14,'P'
	dc.b	0,0,$18,$b0,0,8,$15,'h'
	dc.b	0,'`',$15,$90,0,8,$17,'p'
	dc.b	0,8,$14,'(',0,0,$16,8
	dc.b	0,8,$17,$e8,0,8,$14,$a0
	dc.b	0,8,$14,0,0,0,$18,'`'
	dc.b	0,8,$15,$18,0,8,$14,'x'
	dc.b	0,0,$18,$d8,0,8,$15,$90
	dc.b	0,'`',$15,'h',0,8,$17,'H'
	dc.b	0,8,$14,0,0,0,$15,$e0
	dc.b	0,8,$15,'@',0,8,$14,$a0
	dc.b	0,8,$14,0,0,0,$15,$e0
	dc.b	0,8,$15,'@',0,8,$14,$a0
	dc.b	0,8,$16,$80,0,0,$15,$b8
	dc.b	0,'`',$15,$18,0,8,$11,$f8
	dc.b	0,8,$14,0,0,0,$15,$e0
	dc.b	0,8,$15,'@',0,8,$14,$a0
	dc.b	0,8,$14,0,0,0,$15,$e0
	dc.b	0,8,$15,'@',0,8,$14,$a0
	dc.b	0,8,$11,$80,0,0,$16,8
	dc.b	0,'`',$14,$f0,0,8,$11,$d0
	dc.b	0,0,$16,'X',0,8,$15,$b8
	dc.b	0,8,$12,$98,0,8,$14,$a0
	dc.b	0,8,$14,0,0,0,$13,'`'
	dc.b	0,8,$15,'h',0,8,$14,$c8
	dc.b	0,8,$11,$a8,0,0,$16,'0'
	dc.b	0,'`',$14,$c8,0,8,$11,$a8
	dc.b	0,0,$16,'0',0,8,$13,$10
	dc.b	0,8,$15,$18,0,8,$11,$f8
	dc.b	0,8,$14,0,0,0,$16,8
	dc.b	0,8,$15,'h',0,8,$14,$f0
	dc.b	0,8,$11,$d0,0,0,$16,'X'
	dc.b	0,'`',$11,$f8,0,8,$11,$80
	dc.b	0,0,$16,8,0,8,$15,$90
	dc.b	0,8,$12,'p',0,8,$11,$f8
	dc.b	0,8,$11,$80,0,0,$16,8
	dc.b	0,8,$15,$90,0,8,$12,'p'
	dc.b	0,8,$11,$f8,0,8,$14,0
	dc.b	0,'X',$11,$d0,0,0,$13,$d8
	dc.b	0,8,$13,'`',0,8,$12,$e8
	dc.b	0,8,$12,'p',0,8,$11,$f8
	dc.b	0,8,$11,$80,0,0,$13,$88
	dc.b	0,8,$13,$10,0,8,$12,$98
	dc.b	0,8,$12,' ',0,8,$11,$a8
	dc.b	0,'X',$14,'(',0,0,$13,$b0
	dc.b	0,8,$13,'8',0,8,$12,$c0
	dc.b	0,8,$14,$f0,0,8,$11,$f8
	dc.b	0,8,$11,$80,0,0,$13,$88
	dc.b	0,8,$13,$10,0,8,$12,$c0
	dc.b	0,8,$12,'H',0,8,$11,$d0
	dc.b	0,'P',$13,$d8,0,8,$13,$88
	dc.b	0,8,$13,$10,0,8,$12,$c0
	dc.b	0,8,$12,'H',0,8,$11,$f8
	dc.b	0,8,$11,$80,0,0,$13,$88
	dc.b	0,8,$13,'8',0,8,$12,$c0
	dc.b	0,8,$12,'p',0,8,$11,$f8
	dc.b	0,'P',$13,$b0,0,8,$13,'`'
	dc.b	0,8,$12,$e8,0,8,$12,$98
	dc.b	0,8,$12,'H',0,8,$11,$d0
	dc.b	0,8,$11,$80,0,0,$13,$b0
	dc.b	0,8,$13,'8',0,8,$12,$e8
	dc.b	0,8,$12,$98,0,8,$f,$a0
	dc.b	0,'P',$13,$88,0,8,$10,$90
	dc.b	0,8,$10,'@',0,8,$f,$f0
	dc.b	0,8,$12,' ',0,8,$11,$d0
	dc.b	0,8,$11,$80,0,0,$13,$b0
	dc.b	0,8,$13,'`',0,8,$13,$10
	dc.b	0,8,$12,$c0,0,8,$12,'p'
	dc.b	0,'P',$10,$b8,0,8,$10,'h'
	dc.b	0,8,$10,$18,0,8,$12,'p'
	dc.b	0,8,$12,' ',0,8,$11,$d0
	dc.b	0,8,$11,$80,0,0,$11,'0'
	dc.b	0,8,$10,$e0,0,8,$10,$90
	dc.b	0,8,$12,$e8,0,8,$12,$98
	dc.b	0,'P',$13,$10,0,8,$10,'@'
	dc.b	0,8,$12,$98,0,8,$f,$c8
	dc.b	0,8,$f,'x',0,8,$11,$d0
	dc.b	0,8,$f,0,0,0,$11,'0'
	dc.b	0,8,$13,$88,0,8,$10,$b8
	dc.b	0,8,$10,'h',0,8,$12,$c0
	dc.b	0,'P',$12,$e8,0,8,$10,$18
	dc.b	0,8,$12,'p',0,8,$f,$a0
	dc.b	0,8,$f,'x',0,8,$f,'('
	dc.b	0,8,$f,0,0,0,$13,$d8
	dc.b	0,8,$11,8,0,8,$13,'`'
	dc.b	0,8,$10,$90,0,8,$10,'h'
	dc.b	0,'P',$10,$18,0,8,$f,$f0
	dc.b	0,8,$f,$c8,0,8,$12,' '
	dc.b	0,8,$f,'P',0,8,$f,'('
	dc.b	0,8,$f,0,0,0,$11,'X'
	dc.b	0,8,$13,$b0,0,8,$10,$e0
	dc.b	0,8,$10,$b8,0,8,$10,$90
	dc.b	0,'P',$f,$f0,0,8,$f,$c8
	dc.b	0,8,$f,$a0,0,8,$f,'x'
	dc.b	0,8,$f,'P',0,8,$f,'('
	dc.b	0,8,$f,0,0,0,$11,'X'
	dc.b	0,8,$11,'0',0,8,$11,8
	dc.b	0,8,$10,$e0,0,8,$10,$b8
	dc.b	0,'P',$d,' ',0,8,$f,$a0
	dc.b	0,8,$f,'x',0,8,$f,'P'
	dc.b	0,8,$c,$a8,0,8,$f,'('
	dc.b	0,8,$f,0,0,0,$11,'X'
	dc.b	0,8,$11,'X',0,8,$11,'0'
	dc.b	0,8,$11,8,0,8,$10,$e0
	dc.b	0,'P',$f,'x',0,8,$f,'x'
	dc.b	0,8,$f,'P',0,8,$f,'P'
	dc.b	0,8,$f,'(',0,8,$f,'('
	dc.b	0,8,$f,0,0,0,$e,$d8
	dc.b	0,8,$11,'X',0,8,$e,$b0
	dc.b	0,8,$11,'0',0,8,$e,$88
	dc.b	0,'P',$f,'P',0,8,$c,$a8
	dc.b	0,8,$c,$a8,0,8,$f,'('
	dc.b	0,8,$f,'(',0,8,$c,$80
	dc.b	0,8,$f,0,0,8,$f,0
	dc.b	0,0,$e,$d8,0,8,$e,$d8
	dc.b	0,8,$11,'X',0,8,$11,'X'
	dc.b	0,'P',$c,$80,0,8,$c,$80
	dc.b	0,8,$c,$80,0,8,$c,$80
	dc.b	0,8,$c,$80,0,8,$c,$80
	dc.b	0,8,$c,$80,0,8,$c,$80
	dc.b	0,8,$f,0,0,8,$f,0
	dc.b	0,8,$f,0,0,8,$f,0
	dc.b	0,'@',$e,$d8,0,8,$e,$d8
	dc.b	0,8,$e,$d8,0,$10,$f,0
	dc.b	0,8,$f,0,0,8,$c,$80
	dc.b	0,8,$c,$80,0,8,$c,$80
	dc.b	0,8,$c,$80,0,8,$c,$80
	dc.b	0,8,$f,'(',0,8,$c,$a8
	dc.b	0,'@',$e,$b0,0,8,$e,$b0
	dc.b	0,8,$11,'X',0,8,$e,$d8
	dc.b	0,8,$e,$d8,0,$10,$c,$80
	dc.b	0,8,$c,$80,0,8,$c,$80
	dc.b	0,8,$c,$a8,0,8,$c,$a8
	dc.b	0,8,$c,$a8,0,8,$c,$d0
	dc.b	0,'@',$e,'`',0,8,$e,$88
	dc.b	0,8,$e,$b0,0,8,$e,$b0
	dc.b	0,8,$e,$d8,0,8,$e,$d8
	dc.b	0,$10,$c,$80,0,8,$c,$a8
	dc.b	0,8,$c,$a8,0,8,$c,$d0
	dc.b	0,8,$c,$d0,0,8,$c,$f8
	dc.b	0,'@',$e,'8',0,8,$e,'`'
	dc.b	0,8,$e,$88,0,8,$e,$b0
	dc.b	0,8,$c,'0',0,8,$e,$d8
	dc.b	0,$10,$c,$80,0,8,$c,$a8
	dc.b	0,8,$c,$d0,0,8,$a,'P'
	dc.b	0,8,$a,'x',0,8,$d,' '
	dc.b	0,'@',$e,$10,0,8,$e,'8'
	dc.b	0,8,$e,'`',0,8,$e,$88
	dc.b	0,8,$e,$b0,0,8,$e,$d8
	dc.b	0,$10,$c,$80,0,8,$c,$a8
	dc.b	0,8,$c,$d0,0,8,$a,'x'
	dc.b	0,8,$a,$a0,0,8,$a,$c8
	dc.b	0,'@',$b,'@',0,8,$e,$10
	dc.b	0,8,$e,'8',0,8,$b,$e0
	dc.b	0,8,$c,8,0,8,$e,$d8
	dc.b	0,$10,$a,0,0,8,$a,'('
	dc.b	0,8,$c,$f8,0,8,$d,' '
	dc.b	0,8,$a,$c8,0,8,$a,$f0
	dc.b	0,'@',$b,$18,0,8,$d,$e8
	dc.b	0,8,$b,$90,0,8,$e,'`'
	dc.b	0,8,$c,8,0,8,$e,$d8
	dc.b	0,$10,$a,0,0,8,$a,'('
	dc.b	0,8,$a,'x',0,8,$a,$a0
	dc.b	0,8,$a,$f0,0,8,$b,$18
	dc.b	0,'@',$d,'p',0,8,$b,$18
	dc.b	0,8,$b,'h',0,8,$b,$b8
	dc.b	0,8,$e,$88,0,8,$c,'0'
	dc.b	0,$10,$a,0,0,8,$a,'P'
	dc.b	0,8,$a,'x',0,8,$a,$c8
	dc.b	0,8,$b,$18,0,8,$d,$e8
	dc.b	0,'@',$a,$a0,0,8,$a,$f0
	dc.b	0,8,$b,'@',0,8,$b,$90
	dc.b	0,8,$b,$e0,0,8,$c,'0'
	dc.b	0,$10,$a,0,0,8,$a,'P'
	dc.b	0,8,$a,$a0,0,8,$a,$f0
	dc.b	0,8,$b,'@',0,8,$b,$90
	dc.b	0,'@',$a,'x',0,8,$a,$c8
	dc.b	0,8,$b,$18,0,8,8,$e8
	dc.b	0,8,$b,$e0,0,8,$c,'0'
	dc.b	0,$10,$a,0,0,8,$a,'P'
	dc.b	0,8,$a,$a0,0,8,$b,$18
	dc.b	0,8,$b,'h',0,8,$b,$b8
	dc.b	0,'@',$a,'P',0,8,$a,$a0
	dc.b	0,8,8,'p',0,8,$b,'h'
	dc.b	0,8,$b,$b8,0,8,$c,'0'
	dc.b	0,$10,$a,0,0,8,7,$d0
	dc.b	0,8,$a,$c8,0,8,$b,$18
	dc.b	0,8,$b,$90,0,8,$b,$e0
	dc.b	0,'@',7,$80,0,8,$a,'x'
	dc.b	0,8,$a,$f0,0,8,8,$c0
	dc.b	0,8,$b,$b8,0,8,9,$88
	dc.b	0,$10,$a,0,0,8,$a,'x'
	dc.b	0,8,8,'H',0,8,$b,'@'
	dc.b	0,8,9,$10,0,8,$c,8
	dc.b	0,'8',9,$d8,0,$10,$a,'P'
	dc.b	0,8,$a,$c8,0,8,8,$98
	dc.b	0,8,9,$10,0,8,9,$88
	dc.b	0,$10,7,$80,0,8,$a,'x'
	dc.b	0,8,$a,$f0,0,8,$b,'h'
	dc.b	0,8,9,'8',0,8,9,$b0
	dc.b	0,'8',$c,'0',0,$10,$a,'('
	dc.b	0,8,$a,$a0,0,8,8,$98
	dc.b	0,8,9,$10,0,8,9,$88
	dc.b	0,$10,7,$80,0,8,7,$f8
	dc.b	0,8,8,'p',0,8,8,$e8
	dc.b	0,8,9,'`',0,8,9,$d8
	dc.b	0,'8',9,'`',0,$10,$a,0
	dc.b	0,8,7,$f8,0,8,8,'p'
	dc.b	0,8,8,$e8,0,8,9,$88
	dc.b	0,$10,7,$80,0,8,7,$f8
	dc.b	0,8,$b,$18,0,8,9,$10
	dc.b	0,8,9,$88,0,$10,7,$80
	dc.b	0,'0',9,'8',0,8,9,$b0
	dc.b	0,$10,7,$d0,0,8,8,'H'
	dc.b	0,8,8,$e8,0,8,9,'`'
	dc.b	0,$10,7,$80,0,8,8,' '
	dc.b	0,8,8,$98,0,8,9,'8'
	dc.b	0,8,9,$b0,0,$10,7,$d0
	dc.b	0,'0',9,$10,0,8,9,$88
	dc.b	0,$10,7,$a8,0,8,8,'H'
	dc.b	0,8,8,$e8,0,8,9,'`'
	dc.b	0,$10,7,$80,0,8,8,' '
	dc.b	0,8,6,$18,0,8,9,'8'
	dc.b	0,8,9,$d8,0,$10,7,$f8
	dc.b	0,'0',6,'@',0,8,9,'`'
	dc.b	0,$10,7,$80,0,8,8,' '
	dc.b	0,8,8,$c0,0,8,9,'`'
	dc.b	0,$10,7,$80,0,8,8,' '
	dc.b	0,8,8,$c0,0,8,9,'`'
	dc.b	0,$10,7,$80,0,8,8,' '
	dc.b	0,'0',8,$98,0,8,6,$b8
	dc.b	0,8,7,'X',0,$10,5,'x'
	dc.b	0,8,8,$c0,0,8,9,'`'
	dc.b	0,$10,7,$80,0,8,5,$a0
	dc.b	0,8,6,'@',0,8,9,$88
	dc.b	0,$10,7,$a8,0,8,8,'H'
	dc.b	0,'0',8,'p',0,8,6,$90
	dc.b	0,8,7,'0',0,$10,7,$f8
	dc.b	0,8,6,$18,0,8,9,'`'
	dc.b	0,$10,5,0,0,8,5,$a0
	dc.b	0,8,8,$e8,0,8,7,8
	dc.b	0,$10,7,$d0,0,8,5,$f0
	dc.b	0,'0',5,$a0,0,8,6,'h'
	dc.b	0,8,7,8,0,$10,5,'P'
	dc.b	0,8,8,$98,0,8,6,$b8
	dc.b	0,$10,5,0,0,8,8,'H'
	dc.b	0,8,6,'h',0,8,7,'0'
	dc.b	0,$10,7,$f8,0,8,6,$18
	dc.b	0,'0',5,'x',0,8,6,'@'
	dc.b	0,8,9,$88,0,$10,5,'('
	dc.b	0,8,5,$f0,0,8,6,$b8
	dc.b	0,$10,5,0,0,8,5,$c8
	dc.b	0,8,6,$90,0,8,9,$d8
	dc.b	0,$10,5,'x',0,8,6,'@'
	dc.b	0,'0',2,$a8,0,8,6,$18
	dc.b	0,8,6,$e0,0,$10,5,'('
	dc.b	0,8,5,$f0,0,8,6,$b8
	dc.b	0,$10,5,0,0,8,5,$c8
	dc.b	0,8,6,$90,0,8,7,'X'
	dc.b	0,$10,5,$a0,0,8,6,'h'
	dc.b	0,'0',5,0,0,8,3,'H'
	dc.b	0,8,6,$b8,0,$10,5,0
	dc.b	0,8,3,'H',0,8,6,$b8
	dc.b	0,$10,5,0,0,8,3,'H'
	dc.b	0,8,6,$b8,0,$10,5,0
	dc.b	0,8,5,$c8,0,8,6,$b8
	dc.b	0,'(',7,'X',0,$10,3,' '
	dc.b	0,8,6,$90,0,8,4,$d8
	dc.b	0,$10,5,$c8,0,8,4,$10
	dc.b	0,$10,5,0,0,8,5,$f0
	dc.b	0,8,6,$b8,0,$10,5,'('
	dc.b	0,8,5,$f0,0,8,6,$e0
	dc.b	0,'(',4,$88,0,$10,2,$f8
	dc.b	0,8,6,'h',0,8,7,'X'
	dc.b	0,$10,3,' ',0,8,4,$10
	dc.b	0,$10,2,$80,0,8,5,$f0
	dc.b	0,8,6,$e0,0,$10,2,$a8
	dc.b	0,8,3,$98,0,8,7,8
	dc.b	0,'(',4,'`',0,$10,2,$d0
	dc.b	0,8,3,$c0,0,8,4,$b0
	dc.b	0,$10,3,' ',0,8,4,$10
	dc.b	0,$10,2,$80,0,8,3,'p'
	dc.b	0,8,4,'`',0,$10,2,$d0
	dc.b	0,8,3,$c0,0,8,4,$b0
	dc.b	0,'(',4,'8',0,$10,2,$a8
	dc.b	0,8,3,$98,0,8,4,$88
	dc.b	0,$10,5,$a0,0,8,4,$10
	dc.b	0,$10,2,$80,0,8,3,'p'
	dc.b	0,8,4,'`',0,$10,5,'x'
	dc.b	0,8,3,$e8,0,8,4,$d8
	dc.b	0,'(',3,$e8,0,$10,2,$80
	dc.b	0,8,3,'p',0,8,4,$88
	dc.b	0,$10,2,$f8,0,8,4,$10
	dc.b	0,$10,2,$80,0,8,3,'p'
	dc.b	0,8,4,$88,0,$10,2,$f8
	dc.b	0,8,4,$10,0,$10,2,$80
	dc.b	0,' ',3,$c0,0,8,4,$d8
	dc.b	0,$10,3,'H',0,8,4,'`'
	dc.b	0,$10,2,$f8,0,8,3,$e8
	dc.b	0,$10,2,$80,0,8,3,$98
	dc.b	0,8,4,$88,0,$10,3,' '
	dc.b	0,8,4,'8',0,$10,2,$a8
	dc.b	0,' ',3,$98,0,8,4,$b0
	dc.b	0,$10,0,$a0,0,8,1,$b8
	dc.b	0,$10,2,$d0,0,8,3,$e8
	dc.b	0,$10,2,$80,0,8,3,$98
	dc.b	0,8,4,$b0,0,$10,3,'H'
	dc.b	0,8,4,'`',0,$10,0,'P'
	dc.b	0,' ',0,$c8,0,8,1,$e0
	dc.b	0,$10,3,' ',0,8,4,'8'
	dc.b	0,$10,2,$d0,0,8,3,$e8
	dc.b	0,$10,2,$80,0,8,1,$18
	dc.b	0,8,2,'0',0,$10,0,$c8
	dc.b	0,8,1,$e0,0,$10,3,' '
	dc.b	0,' ',0,$a0,0,8,1,$b8
	dc.b	0,$10,2,$f8,0,8,1,$90
	dc.b	0,$10,0,'(',0,8,3,$e8
	dc.b	0,$10,0,0,0,8,1,$18
	dc.b	0,8,4,$d8,0,$10,0,$f0
	dc.b	0,8,2,8,0,$10,3,'H'
	dc.b	0,' ',2,$f8,0,8,1,$90
	dc.b	0,$10,2,$d0,0,8,1,'h'
	dc.b	0,$10,0,'(',0,8,1,'@'
	dc.b	0,$10,0,0,0,8,3,$c0
	dc.b	0,8,2,'X',0,$10,3,$98
	dc.b	0,8,2,'0',0,$10,3,'p'
	dc.b	0,' ',0,'(',0,8,1,'h'
	dc.b	0,$10,0,'(',0,8,1,'h'
	dc.b	0,$10,0,0,0,8,1,'@'
	dc.b	0,$10,0,0,0,8,1,'@'
	dc.b	0,$10,2,$80,0,8,1,$18
	dc.b	0,8,2,'X',0,$10,1,$18
	dc.b	0,' ',0,0,0,8,1,'@'
	dc.b	0,$10,0,0,0,8,1,'@'
	dc.b	0,$10,0,0,0,8,1,'@'
	dc.b	0,$10,0,0,0,8,1,'@'
	dc.b	0,$10,0,0,0,8,1,'@'
	dc.b	0,$10,0,0,0,8,1,'@'
	dc.b	0,'8',7,$80,0,$10,5,'@'
	dc.b	0,8,7,0,0,$10,0,$80
	dc.b	0,8,6,'@',0,$10,4,0
	dc.b	0,8,5,$c0,0,8,7,$80
	dc.b	0,$10,1,0,0,8,6,$c0
	dc.b	0,'8',7,'@',0,$10,5,0
	dc.b	0,8,6,$c0,0,$10,4,$80
	dc.b	0,8,6,'@',0,$10,4,0
	dc.b	0,8,5,$c0,0,8,7,$80
	dc.b	0,$10,5,'@',0,8,3,0
	dc.b	0,'8',7,0,0,$10,4,$c0
	dc.b	0,8,2,$80,0,$10,0,'@'
	dc.b	0,8,6,'@',0,$10,0,0
	dc.b	0,8,1,$c0,0,8,7,$c0
	dc.b	0,$10,5,$80,0,8,3,'@'
	dc.b	0,'8',2,$80,0,$10,0,$80
	dc.b	0,8,2,'@',0,$10,0,'@'
	dc.b	0,8,2,0,0,$10,0,0
	dc.b	0,8,6,0,0,8,3,$c0
	dc.b	0,$10,5,$c0,0,8,3,$80
	dc.b	0,'8',2,'@',0,$10,0,'@'
	dc.b	0,8,2,'@',0,$10,0,0
	dc.b	0,8,2,0,0,$10,0,0
	dc.b	0,8,2,0,0,$10,4,0
	dc.b	0,8,1,$c0,0,8,3,$c0
	dc.b	0,'8',2,0,0,$10,0,0
	dc.b	0,8,2,0,0,$10,0,0
	dc.b	0,8,2,0,0,$10,0,0
	dc.b	0,8,2,0,0,$10,0,0
	dc.b	0,8,2,0,0,$10,0,0

swsc_Y_table:	; Because of the 3D projection, only some lines of the buffer are displayed on screen
	; This tables lists the jumps to be performed in buffer to go to the next displayed line
	dc.b	2,$d0,2,$a0,2,'p',2,'@'
	dc.b	2,'@',1,$e0,1,$e0,1,$b0
	dc.b	1,$b0,1,$80,1,$80,1,'P'
	dc.b	1,' ',1,'P',1,' ',0,$f0
	dc.b	1,' ',0,$f0,0,$f0,0,$c0
	dc.b	0,$c0,0,$c0,0,$c0,0,$c0
	dc.b	0,$c0,0,$90,0,$90,0,$90
	dc.b	0,$90,0,$90,0,'`',0,$90
	dc.b	0,'`',0,'`',0,'`',0,'`'
	dc.b	0,'`',0,'`',0,'`',0,'`'
	dc.b	0,'0',0,'`',0,'0',0,'0'
	dc.b	0,'`',0,'0',0,'0',0,'0'
	dc.b	0,'0',0,'0',0,'0',0,'0'
	dc.b	0,'0',0,'0',0,'0',0,0
	dc.b	0,'0',0,'0',0,0,0,'0'
	dc.b	0,0,0,'0',0,0,0,'0'
	dc.b	0,0,0,'0',0,0,0,0
	dc.b	0,0,0,'0',0,0,0,0
	dc.b	0,0,0,'0',0,0,0,0
	dcb.w	18

swsc_font:	; 16 x 10 font x 1 bitplane 
	; 25 characters: alphabet minus "J", "Q" anf "Z" plus dot and space
	dc.b	'?',$fc,$7f,$fe,$ff,$ff,$f8,$1f		; @ = $EB30
	dc.b	$f0,$f,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	$f0,$f,'`',6,$ff,$fc,$ff,$fe
	dc.b	$ff,$ff,$e0,$f,$ff,$fe,$ff,$fe
	dc.b	$e0,$f,$ff,$ff,$ff,$fe,$ff,$fc
	dc.b	'?',$fe,$7f,$ff,$ff,$ff,$f0,7
	dc.b	$e0,0,$e0,0,$f0,7,$ff,$ff
	dc.b	$7f,$ff,'?',$fe,$ff,$fc,$ff,$fe
	dc.b	$ff,$ff,$e0,$f,$e0,7,$e0,7
	dc.b	$e0,$f,$ff,$ff,$ff,$fe,$ff,$fc
	dc.b	$ff,$fe,$ff,$ff,$ff,$fe,$e0,0
	dc.b	$fe,0,$fe,0,$e0,0,$ff,$fe
	dc.b	$ff,$ff,$ff,$fe,$ff,$fe,$ff,$ff
	dc.b	$ff,$fe,$e0,0,$fe,0,$ff,0
	dc.b	$fe,0,$e0,0,$e0,0,'@',0
	dc.b	'?',$fe,$7f,$ff,$ff,$fe,$f0,0
	dc.b	$e0,'?',$e0,'?',$f0,7,$ff,$ff
	dc.b	$7f,$ff,'?',$fe,'`',6,$f0,$f
	dc.b	$f0,$f,$f0,$f,$ff,$ff,$ff,$ff
	dc.b	$f0,$f,$f0,$f,$f0,$f,'`',6
	dc.b	1,$80,3,$c0,3,$c0,3,$c0
	dc.b	3,$c0,3,$c0,3,$c0,3,$c0
	dc.b	3,$c0,1,$80,'0',$f,'x>'
	dc.b	'x',$f8,'{',$e0,$7f,$80,$7f,$80
	dc.b	'{',$e0,'x',$f8,'x>0',$f
	dc.b	'`',0,$f0,0,$f0,0,$f0,0
	dc.b	$f0,0,$f0,0,$f0,0,$ff,$fe
	dc.b	$ff,$ff,$7f,$fe,'p',$e,$f8,$1f
	dc.b	$fc,'?',$fe,$7f,$ff,$ff,$f7,$ef
	dc.b	$f3,$cf,$f1,$8f,$f0,$f,'`',6
	dc.b	'|',6,$fe,$f,$ff,$f,$ff,$8f
	dc.b	$f7,$cf,$f3,$ef,$f1,$ff,$f0,$ff
	dc.b	$f0,$7f,'`>?',$fc,$7f,$fe
	dc.b	$ff,$ff,$f0,$f,$e0,7,$e0,7
	dc.b	$f0,$f,$ff,$ff,$7f,$fe,'?',$fc
	dc.b	$ff,$fe,$ff,$ff,$ff,$ff,$f0,7
	dc.b	$ff,$ff,$ff,$ff,$ff,$fe,$f0,0
	dc.b	$f0,0
l0092	bra	l0092
	dc.b	$ff,$ff,$ff,$ff,$f0,7,$ff,$ff
	dc.b	$ff,$ff,$ff,$fe,$f0,$1f,$f0,$f
	dc.b	'`',6,'?',$fe,$7f,$ff,$ff,$fe
	dc.b	$e0,0,$ff,$fe,$7f,$ff,0,7
	dc.b	$7f,$ff,$ff,$fe,$7f,$fc,$7f,$fe
	dc.b	$ff,$ff,$7f,$fe,3,$c0,3,$c0
	dc.b	3,$c0,3,$c0,3,$c0,3,$c0
	dc.b	1,$80,'`',6,$f0,$f,$f0,$f
	dc.b	$f0,$f,$f0,$f,$f0,$f,$f8,$1f
	dc.b	$ff,$ff,$7f,$fe,'?',$fc,'`',6
	dc.b	$f0,$f,$f0,$f,$f0,$f,'x',$1e
	dc.b	'<<',$1e,'x',$f,$f0,7,$e0
	dc.b	3,$c0,'`',6,$f0,$f,$f0,$f
	dc.b	$f0,$f,$f1,$8f,$f3,$cf,$f7,$ef
	dc.b	$ff,$ff,'~~<<',$e0,7
	dc.b	$f8,$1f,$fe,$7f,$7f,$fe,$1f,$f8
	dc.b	$1f,$f8,$7f,$fe,$fe,$7f,$f8,$1f
	dc.b	$e0,7,'p',$e,'x',$1e,'<<'
	dc.b	$1e,'x',$f,$f0,7,$e0,3,$c0
	dc.b	3,$c0,3,$c0,1,$80,0,0
	dcb.w	5
	dc.b	'0',0,'x',0,'x',0,'0',0
	dcb.w	10
L_distscr_text:	dc.b	'        '	; @ = DISTSCR_TEXT	$ED24
	dc.b	'        '
	dc.b	'     TJA'
	dc.b	' ALLIHOP'
	dc.b	'A (THAT',$27
	dc.b	'S SWEDIS'
	dc.b	'H, JACKA'
	dc.b	'SS), HER'
	dc.b	'E COMES '
	dc.b	'THE CARE'
	dc.b	'BEARS AG'
	dc.b	'AIN, WIT'
	dc.b	'H ANOTHE'
	dc.b	'R INCRED'
	dc.b	'IBLE DEM'
	dc.b	'O-SCREEN'
	dc.b	', CALLED'
	dc.b	' THE STA'
	dc.b	'RWARS-SC'
	dc.b	'ROLLER. '
	dc.b	'YOU HAVE'
	dc.b	' PROBABL'
	dc.b	'Y ALREAD'
	dc.b	'Y FIGURE'
	dc.b	'D OUT WH'
	dc.b	'Y...    '
	dc.b	'   AS WE'
	dc.b	' WRITE T'
	dc.b	'HIS, WE',$27
	dc.b	'RE OUT I'
	dc.b	'N THE AR'
	dc.b	'CHIPELAG'
	dc.b	'OS OF ST'
	dc.b	'OCKHOLM,'
	dc.b	' WHERE A'
	dc.b	'N COOL H'
	dc.b	'AS A SMA'
	dc.b	'LL (VERY'
	dc.b	' SMALL) '
	dc.b	'COTTAGE.'
	dc.b	' EVERYBO'
	dc.b	'DY IS CO'
	dc.b	'MPLAININ'
	dc.b	'G ABOUT '
	dc.b	'THEIR AC'
	dc.b	'HING ARM'
	dc.b	'S AND BA'
	dc.b	'CKS.  LE'
	dc.b	'T',$27,'S EXPL'
	dc.b	'AIN WHAT'
	dc.b	' CAUSED '
	dc.b	'THESE UN'
	dc.b	'PLEASENT'
	dc.b	' PAINS  '
	dc.b	'    FIRS'
	dc.b	'T OF ALL'
	dc.b	', WE HAD'
	dc.b	' TO TRAV'
	dc.b	'EL BY TR'
	dc.b	'AIN FOR '
	dc.b	'ABOUT ON'
	dc.b	'E HOUR. '
	dc.b	'WE WENT '
	dc.b	'OFF THE '
	dc.b	'TRAIN IN'
	dc.b	' TUMBA, '
	dc.b	'WHERE WE'
	dc.b	' WERE SU'
	dc.b	'PPOSED T'
	dc.b	'O BUY SO'
	dc.b	'ME FOOD '
	dc.b	'AND COKE'
	dc.b	' BEFORE '
	dc.b	'WE GOT O'
	dc.b	'N A BUS '
	dc.b	'THAT WOU'
	dc.b	'LD DRIVE'
	dc.b	' US CLOS'
	dc.b	'ER TO AN'
	dc.b	' COOL',$27,'S '
	dc.b	'COTTAGE.'
	dc.b	'  BUT TH'
	dc.b	'ERE WAS '
	dc.b	'A BIG PR'
	dc.b	'OBLEM, W'
	dc.b	'E ONLY H'
	dc.b	'AD ABOUT'
	dc.b	' THREE M'
	dc.b	'INUTES B'
	dc.b	'EFORE TH'
	dc.b	'E BUS LE'
	dc.b	'FT, AND '
	dc.b	'THE NEXT'
	dc.b	' BUS WOU'
	dc.b	'LD COME '
	dc.b	'IN ABOUT'
	dc.b	' THREE A'
	dc.b	'ND A HAL'
	dc.b	'F HOUR, '
	dc.b	'SO WE DE'
	dc.b	'CIDED TO'
	dc.b	' GET ON '
	dc.b	'THIS BUS'
	dc.b	' AND GO '
	dc.b	'TO ANOTH'
	dc.b	'ER SMALL'
	dc.b	' STORE, '
	dc.b	'NEAR THE'
	dc.b	' COTTAGE'
	dc.b	'.   OF C'
	dc.b	'OURSE TH'
	dc.b	'AT STORE'
	dc.b	' WAS CLO'
	dc.b	'SED WHEN'
	dc.b	' WE GOT '
	dc.b	'THERE.  '
	dc.b	'OKAY, WE'
	dc.b	' GOT OFF'
	dc.b	' THE BUS'
	dc.b	' AND NOW'
	dc.b	' WE HAD '
	dc.b	'A FIVE K'
	dc.b	'ILOMETRE'
	dc.b	'S WALK T'
	dc.b	'O DO.   '
	dc.b	'REALLY N'
	dc.b	'ICE, WIT'
	dc.b	'H BAGS F'
	dc.b	'ILLED WI'
	dc.b	'TH COMPU'
	dc.b	'TERS, MO'
	dc.b	'NITORS, '
	dc.b	'CLOTHES '
	dc.b	'AND COKE'
	dc.b	'.    THE'
	dc.b	'RE WERE '
	dc.b	'EVEN MOR'
	dc.b	'E PROBLE'
	dc.b	'MS TO CO'
	dc.b	'ME, THE '
	dc.b	'HEAVIEST'
	dc.b	' BAG (WI'
	dc.b	'TH A WEI'
	dc.b	'GHT OF A'
	dc.b	'BOUT 50 '
	dc.b	'KILOGRAM'
	dc.b	'S) WAS D'
	dc.b	'ESTROYED'
	dc.b	', AND NO'
	dc.b	'W TANIS '
	dc.b	'AND A.D '
	dc.b	'HAD TO C'
	dc.b	'ARRY IT '
	dc.b	'ON THEIR'
	dc.b	' HEADS ('
	dc.b	'AND BACK'
	dc.b	'S).   FI'
	dc.b	'NALLY WE'
	dc.b	' REACHED'
	dc.b	' THE COT'
	dc.b	'TAGE, AF'
	dc.b	'TER ABOU'
	dc.b	'T ONE HO'
	dc.b	'UR',$27,'S WAL'
	dc.b	'K.    OU'
	dc.b	'R ARMS W'
	dc.b	'ERE ABOU'
	dc.b	'T TWO ME'
	dc.b	'TRES LON'
	dc.b	'GER THAN'
	dc.b	' THEY WE'
	dc.b	'RE THIS '
	dc.b	'MORNING.'
	dc.b	'  AFTER '
	dc.b	'THIS VER'
	dc.b	'Y INTERE'
	dc.b	'STING ST'
	dc.b	'ORY, YOU'
	dc.b	' CAN UND'
	dc.b	'ERSTAND '
	dc.b	'WHY OUR '
	dc.b	'ARMS ARE'
	dc.b	' ACHING!'
	dc.b	'!       '
	dc.b	' LET',$27,'S C'
	dc.b	'HANGE SU'
	dc.b	'BJECT...'
	dc.b	'     TOD'
	dc.b	'AY WE GO'
	dc.b	'T THE LO'
	dc.b	'ST BOYS '
	dc.b	'DEMO, WH'
	dc.b	'ICH WAS '
	dc.b	'QUITE GO'
	dc.b	'OD, BUT '
	dc.b	'NOT NEAR'
	dc.b	'LY AS GO'
	dc.b	'OD AS TH'
	dc.b	'IS ONE ('
	dc.b	'THIS IS '
	dc.b	'ACTUALLY'
	dc.b	' MORE TH'
	dc.b	'AN TEN T'
	dc.b	'IMES BET'
	dc.b	'TER).   '
	dc.b	'WE WERE '
	dc.b	'QUITE DI'
	dc.b	'STURBED '
	dc.b	'WHEN WE '
	dc.b	'SAW THEI'
	dc.b	'R TWIST-'
	dc.b	'SCROLLER'
	dc.b	', WHICH '
	dc.b	'LOOKED S'
	dc.b	'IMILAR T'
	dc.b	'O OUR DN'
	dc.b	'A-SCROLL'
	dc.b	'ER, BUT '
	dc.b	'OF COURS'
	dc.b	'E OURS I'
	dc.b	'S MUCH, '
	dc.b	'MUCH BET'
	dc.b	'TER, AND'
	dc.b	' I THINK'
	dc.b	' THAT WE'
	dc.b	' WROTE I'
	dc.b	'T BEFORE'
	dc.b	' THEY WR'
	dc.b	'OTE THEI'
	dc.b	'RS (WE W'
	dc.b	'ROTE IT '
	dc.b	'THREE MO'
	dc.b	'NTHS AGO'
	dc.b	').   THE'
	dc.b	'Y SAID T'
	dc.b	'HAT THEI'
	dc.b	'R DEMO W'
	dc.b	'AS THE B'
	dc.b	'EST "SIN'
	dc.b	'GLE-CREW'
	dc.b	'"-DEMO E'
	dc.b	'VER, WEL'
	dc.b	'L, OUR D'
	dc.b	'EMO IS A'
	dc.b	'LMOST A '
	dc.b	'"SINGLE-'
	dc.b	'CREW"-DE'
	dc.b	'MO, AND '
	dc.b	'IF YOU R'
	dc.b	'EMOVE TH'
	dc.b	'E GUEST '
	dc.b	'APPEARAN'
	dc.b	'CES, WE '
	dc.b	'STILL TH'
	dc.b	'INK THAT'
	dc.b	' OUR DEM'
	dc.b	'O IS AT '
	dc.b	'LEAST FI'
	dc.b	'VE TIMES'
	dc.b	' BETTER '
	dc.b	'THAN THE'
	dc.b	'IRS.   T'
	dc.b	'HE LOST '
	dc.b	'BOYS ALS'
	dc.b	'O WROTE '
	dc.b	'THAT THE'
	dc.b	'IR SOURC'
	dc.b	'E-CODE W'
	dc.b	'AS ABOUT'
	dc.b	' 230 KIL'
	dc.b	'OBYTES L'
	dc.b	'ONG, WE '
	dc.b	'COUNTED '
	dc.b	'HOW MUCH'
	dc.b	' MEMORY '
	dc.b	'OUR SOUR'
	dc.b	'CE-CODE '
	dc.b	'TOOK AND'
	dc.b	' IT WAS '
	dc.b	'ABOUT 14'
	dc.b	'00 KILOB'
	dc.b	'YTES LON'
	dc.b	'G!!!! AN'
	dc.b	'D IF YOU'
	dc.b	' WOULD P'
	dc.b	'RINT IT,'
	dc.b	' IT WOUL'
	dc.b	'D TAKE 6'
	dc.b	'50 A4-PA'
	dc.b	'GES.    '
	dc.b	' NOW YOU'
	dc.b	' PROBABL'
	dc.b	'Y THINK '
	dc.b	'THAT WE '
	dc.b	'ARE TALK'
	dc.b	'ING BIG.'
	dc.b	'   WELL,'
	dc.b	' WE KNOW'
	dc.b	' WE',$27,'RE N'
	dc.b	'OT EXACT'
	dc.b	'LY MODES'
	dc.b	'T, BUT W'
	dc.b	'E CAN',$27,'T '
	dc.b	'BE, COZ '
	dc.b	'NOBODY E'
	dc.b	'LSE IS. '
	dc.b	'YOU KNOW'
	dc.b	', WE HAV'
	dc.b	'E TO BE '
	dc.b	'THE BEST'
	dc.b	' IN EVER'
	dc.b	'YTHING, '
	dc.b	'INCLUDIN'
	dc.b	'G TALKIN'
	dc.b	'G BIG.  '
	dc.b	'   WE WO'
	dc.b	'N',$27,'T WRIT'
	dc.b	'E ANYTHI'
	dc.b	'NG MORE,'
	dc.b	' BECAUSE'
	dc.b	' THE ONL'
	dc.b	'Y THING '
	dc.b	'WE COULD'
	dc.b	' WRITE N'
	dc.b	'OW IS TH'
	dc.b	'E GREETI'
	dc.b	'NGS AND '
	dc.b	'WE HAVE '
	dc.b	'GREETING'
	dc.b	'S ENOUGH'
	dc.b	' IN THE '
	dc.b	'MAIN MEN'
	dc.b	'U...   B'
	dc.b	'YE, BYE '
	dc.b	'AND KEEP'
	dc.b	' ON HACK'
	dc.b	'ING.....'
	dc.b	'..    PU'
	dc.b	'SSELIMUS'
	dc.b	'S!!!    '
	dc.b	'TJA DAUU'
	dc.b	'!!  GOOD'
	dc.b	' NIGHT!!'
	dc.b	' (IT',$27,'S T'
	dc.b	'WO O',$27,'CLO'
	dc.b	'CK, BUT '
	dc.b	'THE NIGH'
	dc.b	'T IS STI'
	dc.b	'LL YOUNG'
	dc.b	') OKAY, '
	dc.b	'LET',$27,'S WR'
	dc.b	'AAAAAAAA'
	dc.b	'AAAAAAAA'
	dc.b	'AAAAAAZ!'
	dc.b	'!!!!!!!!'
	dc.b	'!       '
	dc.b	'        '
	dc.b	'        '
	dc.b	'        '

L_DistSrc_Conv_Tbl:
	dc.b	'////////'	; @ = DISTSCR_CONV_TBL	$F85C
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'/',$1a,'(////.'
	dc.b	')*//+,-/'
	dc.b	$1e,$1f,' !"#$%'
	dc.b	'&',$27,$1c,$1d,'///',$1b
	dc.b	'/',0,1,2,3,4,5,6
	dc.b	7,8,9,$a,$b,$c,$d,$e
	dc.b	$f,$10,$11,$12,$13,$14,$15,$16
	dc.b	$17,$18,$19,'/////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'
	dc.b	'////////'

L_DistScr_Char_Adr:		; @ = DISTSCR_CHAR_ADR	$F95C
	dcb.w	2
L_DistScr_L2:	dc.b	0,0	; @ = DISTSCR_TEXT_L2	$F960
L_DistScr_Pos:	dc.b	0,0	; @ = DISTSCR_TEXT_POS	$F962
l0098:	dc.b	0,0,$fa,$84
l0099:	dc.b	0,0,$f9,'l'
l009a:	dc.b	0,0,$fa,$84,0,0,$fa,$d6
	dc.b	0,0,$fb,'x',0,0,$fa,$d6
	dc.b	0,0,$fb,$f2,0,0,$fc,$be
	dc.b	0,0,$fc,$be,0,0,$fa,$84
	dc.b	0,0,$fc,$a8,0,0,$fc,$a8
	dc.b	0,0,$fa,$84,0,0,$ff,$82
	dc.b	0,0,$fb,$f2,0,0,$fa,$d6
	dc.b	0,0,$fe,$90,0,0,$fe,$90
	dc.b	0,0,$fa,$84,0,0,$fd,$9e
	dc.b	0,0,$fd,$9e,0,0,$fb,'x'
	dc.b	0,0,$fb,$f2,0,0,$fa,$d6
	dc.b	0,0,$fc,$e8,0,0,$fc,$e8
	dc.b	0,0,$fa,$d6,0,0,$fa,$84
	dc.b	0,1,0,'8',0,0,$fc,$be
	dc.b	0,0,$fc,$be,0,0,$fc,$be
	dc.b	0,0,$fc,$be,0,1,0,'8'
	dc.b	0,0,$fa,$84,0,0,$fa,$d6
	dc.b	0,0,$fb,$f2,0,0,$fc,$a8
	dc.b	0,0,$fc,$a8,0,0,$fc,$a8
	dc.b	0,0,$fc,$a8,0,0,$fa,$84
	dc.b	0,0,$fc,$e8,0,0,$fb,'x'
	dc.b	0,0,$fe,$90,0,0,$fd,$9e
	dc.b	0,0,$ff,$82,0,1,0,'8'
	dc.b	0,0,$fc,$be,0,0,$fc,$be
	dc.b	0,0,$fc,$be,0,0,$fc,$be
	dc.b	0,0,$fa,$84,0,0,$fa,$84
	dc.b	0,0,$fb,'x',0,1,0,'8'
	dc.b	0,0,$fa,$d6,0,0,$fb,$f2
	dc.b	0,0,$fa,$84,0,0,$fc,$e8
	dc.b	0,0,$fc,$e8,0,0,$fc,$e8
	dc.b	0,0,$fa,$84,0,1,0,'8'
	dc.b	0,0,$fc,$a8,0,0,$fe,$90
	dc.b	0,0,$fa,$84,0,0,$fa,$d6
	dc.b	0,0,$fc,$e8,0,0,$fa,$d6
	dc.b	0,0,$fc,$e8,$ff,$ff,$ff,$ff
	dcb.w	40
	dc.b	$ff,$ff,0,0,0,0,0,0
	dc.b	0,1,0,2,0,2,0,3
	dc.b	0,5,0,6,0,8,0,9
	dc.b	0,$b,0,$d,0,$f,0,$11
	dc.b	0,$13,0,$16,0,$18,0,$1b
	dc.b	0,$1d,0,' ',0,'"',0,'$'
	dc.b	0,$27,0,')',0,',',0,'.'
	dc.b	0,'0',0,'2',0,'4',0,'6'
	dc.b	0,'7',0,'9',0,':',0,'<'
	dc.b	0,'=',0,'=',0,'>',0,'?'
	dc.b	0,'?',0,'?',0,'?',0,'?'
	dc.b	0,'>',0,'=',0,'=',0,'<'
	dc.b	0,':',0,'9',0,'7',0,'6'
	dc.b	0,'4',0,'2',0,'0',0,'.'
	dc.b	0,',',0,')',0,$27,0,'$'
	dc.b	0,'"',0,' ',0,$1d,0,$1b
	dc.b	0,$18,0,$16,0,$13,0,$11
	dc.b	0,$f,0,$d,0,$b,0,9
	dc.b	0,8,0,6,0,5,0,3
	dc.b	0,2,0,2,0,1,0,0
	dc.b	0,0,$ff,$ff,0,0,0,0
	dcb.w	3
	dc.b	0,1,0,1,0,2,0,3
	dc.b	0,4,0,5,0,6,0,7
	dc.b	0,9,0,$a,0,$c,0,$e
	dc.b	0,$10,0,$11,0,$14,0,$16
	dc.b	0,$18,0,$1a,0,$1d,0,$1f
	dc.b	0,'"',0,'%',0,'(',0,'+'
	dc.b	0,'.',0,'1',0,'.',0,'+'
	dc.b	0,'(',0,'%',0,'"',0,$1f
	dc.b	0,$1d,0,$1a,0,$18,0,$16
	dc.b	0,$14,0,$11,0,$10,0,$e
	dc.b	0,$c,0,$a,0,9,0,7
	dc.b	0,6,0,5,0,4,0,3
	dc.b	0,2,0,1,0,1,0,0
	dcb.w	3
	dc.b	$ff,$ff,0,0,0,0,0,1
	dc.b	0,4,0,7,0,$b,0,$f
	dc.b	0,$14,0,$19,0,$1d,0,'"'
	dc.b	0,'&',0,'*',0,'-',0,'0'
	dc.b	0,'1',0,'2',0,'2',0,'2'
	dc.b	0,'0',0,'.',0,',',0,')'
	dc.b	0,'&',0,'#',0,'!',0,$1f
	dc.b	0,$1d,0,$1d,0,$1d,0,$1e
	dc.b	0,$1f,0,'"',0,'%',0,')'
	dc.b	0,'-',0,'2',0,'6',0,';'
	dc.b	0,'@',0,'D',0,'H',0,'K'
	dc.b	0,'N',0,'O',0,'P',0,'O'
	dc.b	0,'N',0,'K',0,'H',0,'D'
	dc.b	0,'@',0,';',0,'6',0,'2'
	dc.b	0,'-',0,')',0,'%',0,'"'
	dc.b	0,$1f,0,$1e,0,$1d,0,$1d
	dc.b	0,$1d,0,$1f,0,'!',0,'#'
	dc.b	0,'&',0,')',0,',',0,'.'
	dc.b	0,'0',0,'2',0,'2',0,'2'
	dc.b	0,'1',0,'0',0,'-',0,'*'
	dc.b	0,'&',0,'"',0,$1d,0,$19
	dc.b	0,$14,0,$f,0,$b,0,7
	dc.b	0,4,0,1,0,0,$ff,$ff
	dc.b	0,0,0,1,0,2,0,5
	dc.b	0,6,0,7,0,6,0,5
	dc.b	0,2,0,1,$ff,$ff,0,0
	dc.b	0,0,0,1,0,2,0,3
	dc.b	0,5,0,6,0,7,0,8
	dc.b	0,9,0,9,0,9,0,8
	dc.b	0,7,0,6,0,5,0,3
	dc.b	0,2,0,1,0,0,$ff,$ff
	dcb.w	2
	dc.b	0,1,0,2,0,3,0,4
	dc.b	0,6,0,8,0,$b,0,$d
	dc.b	0,$10,0,$13,0,$16,0,$19
	dc.b	0,$1b,0,$1e,0,'!',0,'#'
	dc.b	0,'&',0,'(',0,'*',0,','
	dc.b	0,'-',0,'.',0,'/',0,'/'
	dc.b	0,'/',0,'/',0,'/',0,'/'
	dc.b	0,'.',0,'-',0,',',0,'*'
	dc.b	0,')',0,'(',0,'&',0,'%'
	dc.b	0,'$',0,'#',0,'"',0,'!'
	dc.b	0,' ',0,$1f,0,$1f,0,$1f
	dc.b	0,$1f,0,$1f,0,' ',0,'!'
	dc.b	0,'"',0,'#',0,'$',0,'%'
	dc.b	0,'&',0,'(',0,')',0,'*'
	dc.b	0,',',0,'-',0,'.',0,'/'
	dc.b	0,'/',0,'/',0,'/',0,'/'
	dc.b	0,'/',0,'.',0,'-',0,','
	dc.b	0,'*',0,'(',0,'&',0,'#'
	dc.b	0,'!',0,$1e,0,$1b,0,$19
	dc.b	0,$16,0,$13,0,$10,0,$d
	dc.b	0,$b,0,8,0,6,0,4
	dc.b	0,3,0,2,0,1,0,0
	dc.b	$ff,$ff,0,0,0,0,0,1
	dc.b	0,3,0,5,0,8,0,$b
	dc.b	0,$e,0,$12,0,$15,0,$19
	dc.b	0,$1c,0,$1e,0,' ',0,'"'
	dc.b	0,'#',0,'#',0,'"',0,'"'
	dc.b	0,' ',0,$1e,0,$1c,0,$1a
	dc.b	0,$17,0,$15,0,$13,0,$11
	dc.b	0,$10,0,$f,0,$f,0,$10
	dc.b	0,$11,0,$12,0,$15,0,$18
	dc.b	0,$1b,0,$1f,0,'"',0,'&'
	dc.b	0,'*',0,'.',0,'1',0,'4'
	dc.b	0,'6',0,'8',0,'8',0,'9'
	dc.b	0,'8',0,'7',0,'6',0,'3'
	dc.b	0,'1',0,'.',0,'+',0,')'
	dc.b	0,'&',0,'$',0,'"',0,' '
	dc.b	0,$1f,0,$1f,0,$1f,0,' '
	dc.b	0,'"',0,'$',0,'&',0,')'
	dc.b	0,'+',0,'.',0,'1',0,'3'
	dc.b	0,'6',0,'7',0,'8',0,'9'
	dc.b	0,'8',0,'8',0,'6',0,'4'
	dc.b	0,'1',0,'.',0,'*',0,'&'
	dc.b	0,'"',0,$1f,0,$1b,0,$18
	dc.b	0,$15,0,$12,0,$11,0,$10
	dc.b	0,$f,0,$f,0,$10,0,$11
	dc.b	0,$13,0,$15,0,$17,0,$1a
	dc.b	0,$1c,0,$1e,0,' ',0,'"'
	dc.b	0,'"',0,'#',0,'#',0,'"'
	dc.b	0,' ',0,$1e,0,$1c,0,$19
	dc.b	0,$15,0,$12,0,$e,0,$b
	dc.b	0,8,0,5,0,3,0,1
	dc.b	0,0,$ff,$ff,0,0,0,0
	dc.b	0,0,0,1,0,2,0,3
	dc.b	0,4,0,5,0,6,0,8
	dc.b	0,9,0,$b,0,$d,0,$e
	dc.b	0,$10,0,$12,0,$14,0,$15
	dc.b	0,$17,0,$19,0,$1a,0,$1b
	dc.b	0,$1d,0,$1e,0,$1f,0,' '
	dc.b	0,'!',0,'"',0,'#',0,'#'
	dc.b	0,'$',0,'$',0,'%',0,'%'
	dc.b	0,'&',0,'&',0,'&',0,'&'
	dc.b	0,'&',0,$27,0,$27,0,$27
	dc.b	0,$27,0,$27,0,$27,0,$27
	dc.b	0,$27,0,$27,0,$27,0,$27
	dc.b	0,$27,0,$27,0,$27,0,$27
	dc.b	0,$27,0,$27,0,$27,0,$27
	dc.b	0,$27,0,$27,0,$27,0,$27
	dc.b	0,$27,0,$27,0,$27,0,$27
	dc.b	0,$27,0,$27,0,$27,0,$27
	dc.b	0,$27,0,$27,0,$27,0,$27
	dc.b	0,$27,0,$27,0,$27,0,$27
	dc.b	0,$27,0,$27,0,$27,0,$27
	dc.b	0,'&',0,'&',0,'&',0,'&'
	dc.b	0,'&',0,'%',0,'%',0,'$'
	dc.b	0,'$',0,'#',0,'#',0,'"'
	dc.b	0,'!',0,' ',0,$1f,0,$1e
	dc.b	0,$1d,0,$1b,0,$1a,0,$19
	dc.b	0,$17,0,$15,0,$14,0,$12
	dc.b	0,$10,0,$e,0,$d,0,$b
	dc.b	0,9,0,8,0,6,0,5
	dc.b	0,4,0,3,0,2,0,1
	dcb.w	2
	dc.b	$ff,$ff,0,0,0,0,0,1
	dc.b	0,4,0,7,0,$b,0,$f
	dc.b	0,$14,0,$19,0,$1d,0,'"'
	dc.b	0,'&',0,'*',0,'-',0,'0'
	dc.b	0,'1',0,'2',0,'2',0,'2'
	dc.b	0,'0',0,'.',0,',',0,')'
	dc.b	0,'&',0,'#',0,'!',0,$1f
	dc.b	0,$1d,0,$1d,0,$1d,0,$1e
	dc.b	0,$1f,0,'"',0,'%',0,')'
	dc.b	0,'-',0,'2',0,'6',0,';'
	dc.b	0,'@',0,'D',0,'H',0,'K'
	dc.b	0,'N',0,'O',0,'P',0,'O'
	dc.b	0,'N',0,'K',0,'H',0,'D'
	dc.b	0,'@',0,';',0,'6',0,'2'
	dc.b	0,'-',0,')',0,'%',0,'"'
	dc.b	0,$1f,0,$1e,0,$1d,0,$1d
	dc.b	0,$1d,0,$1f,0,'!',0,'#'
	dc.b	0,'&',0,')',0,',',0,'.'
	dc.b	0,'0',0,'2',0,'2',0,'2'
	dc.b	0,'1',0,'0',0,'-',0,'*'
	dc.b	0,'&',0,'"',0,$1d,0,$19
	dc.b	0,$14,0,$f,0,$b,0,7
	dc.b	0,4,0,1,0,0,$ff,$ff
	dcb.w	6
	dc.b	0,1,0,1,0,2,0,2
	dc.b	0,3,0,3,0,4,0,5
	dc.b	0,6,0,7,0,8,0,9
	dc.b	0,$a,0,$b,0,$c,0,$e
	dc.b	0,$f,0,$10,0,$12,0,$14
	dc.b	0,$15,0,$17,0,$19,0,$1a
	dc.b	0,$1c,0,$1e,0,' ',0,'"'
	dc.b	0,'$',0,$27,0,')',0,'+'
	dc.b	0,'.',0,'0',0,'3',0,'5'
	dc.b	0,'8',0,';',0,'=',0,'@'
	dc.b	0,'C',0,'F',0,'I',0,'L'
	dc.b	0,'P',0,'L',0,'I',0,'F'
	dc.b	0,'C',0,'@',0,'=',0,';'
	dc.b	0,'8',0,'5',0,'3',0,'0'
	dc.b	0,'.',0,'+',0,')',0,$27
	dc.b	0,'$',0,'"',0,' ',0,$1e
	dc.b	0,$1c,0,$1a,0,$19,0,$17
	dc.b	0,$15,0,$14,0,$12,0,$10
	dc.b	0,$f,0,$e,0,$c,0,$b
	dc.b	0,$a,0,9,0,8,0,7
	dc.b	0,6,0,5,0,4,0,3
	dc.b	0,3,0,2,0,2,0,1
	dc.b	0,1,0,0,0,0,0,0
	dcb.w	2
	dc.b	$ff,$ff,0,0,0,0,0,0
	
	dcb.w	197	; Stack space
L_stars_data:			; @ = STARS_DATA = STACK_ADR	$10292
	dc.b	'U',$e8,1,0,0,0,'U',$e8
	dc.b	1,0,0,0,'V',$88,1,0
	dc.b	0,0,'W(',0,$80,0,0
	dc.b	'W(',0,'@',0,0,'W',$c8
	dc.b	0,'@',0,0,'Xh',0,' '
	dc.b	0,0,'Xh',0,' ',0,0
	dc.b	'Y',8,0,$10,0,0,'Y',$a8
	dc.b	0,$10,0,0,'ZH',0,8
	dc.b	0,0,'ZH',0,4,0,0
	dc.b	'Z',$e8,0,4,0,0,'[',$88
	dc.b	0,2,0,0,'\(',0,1
	dc.b	0,0,'\(',0,1,0,0
	dc.b	'\',$d0,$80,0,0,0,']p'
	dc.b	'@',0,0,0,'^',$10,' ',0
	dc.b	0,0,'^',$b0,$10,0,0,0
	dc.b	'_P',8,0,0,0,'_P'
	dc.b	8,0,0,0,'_',$f0,4,0
	dc.b	0,0,'`',$90,2,0,0,0
	dc.b	'a0',1,0,0,0,'a',$d0
	dc.b	0,$80,0,0,'bp',0,' '
	dc.b	0,0,'c',$10,0,$10,0,0
	dc.b	'c',$b0,0,8,0,0,'dP'
	dc.b	0,4,0,0,'e',$90,0,2
	dc.b	0,0,'f8',$80,0,0,0
	dc.b	'f',$d8,'@',0,0,0,'gx'
	dc.b	' ',0,0,0,'h',$18,8,0
	dc.b	0,0,'iX',2,0,0,0
	dc.b	'i',$f8,0,0,1,0,'j',$98
	dc.b	0,0,0,'@k',$d8,0,0
	dc.b	0,$10,'m',$18,0,0,0,4
	dc.b	'm',$b8,0,0,0,1,'o',0
	dc.b	0,0,'@',0,'p@',0,0
	dc.b	$10,0,'p',$e0,0,0,2,0
	dc.b	'r ',0,0,0,$80,'t',0
	dc.b	0,0,0,$10,'u@',0,0
	dc.b	0,2,'v',$88,0,0,'@',0
	dc.b	'xh',0,0,8,0,'y',$a8
	dc.b	0,0,1,0,'{',$88,0,0
	dc.b	0,$10,$ff,$ff,'^',8,0,' '
	dc.b	0,0,'^',8,0,$10,0,0
	dc.b	'^',$a8,0,$10,0,0,'_H'
	dc.b	0,8,0,0,'_',$e8,0,4
	dc.b	0,0,'`',$88,0,2,0,0
	dc.b	'a(',0,1,0,0,'a',$c8
	dc.b	0,1,0,0,'bp',$80,0
	dc.b	0,0,'c',$10,'@',0,0,0
	dc.b	'c',$b0,' ',0,0,0,'d',$f0
	dc.b	$10,0,0,0,'e',$90,8,0
	dc.b	0,0,'f0',4,0,0,0
	dc.b	'f',$d0,2,0,0,0,'gp'
	dc.b	0,$80,0,0,'h',$b0,0,'@'
	dc.b	0,0,'iP',0,' ',0,0
	dc.b	'i',$f0,0,8,0,0,'k0'
	dc.b	0,4,0,0,'k',$d0,0,2
	dc.b	0,0,'m',$18,$80,0,0,0
	dc.b	'm',$b8,' ',0,0,0,'n',$f8
	dc.b	$10,0,0,0,'p8',4,0
	dc.b	0,0,'p',$d8,1,0,0,0
	dc.b	'r',$18,0,'@',0,0,'sX'
	dc.b	0,$10,0,0,'t',$98,0,4
	dc.b	0,0,'u',$d8,0,1,0,0
	dc.b	'w',$c0,' ',0,0,0,'y',0
	dc.b	8,0,0,0,'z',$e0,1,0
	dc.b	0,0,'| ',0,' ',0,0
	dc.b	$ff,$ff,'?h',0,$80,0,0
	dc.b	'?h',0,$80,0,0,'?h'
	dc.b	0,$80,0,0,'?h',0,$80
	dc.b	0,0,'?h',0,$80,0,0
	dc.b	'?h',0,$80,0,0,'?h'
	dc.b	0,$80,0,0,'@',8,0,$80
	dc.b	0,0,'@',8,0,$80,0,0
	dc.b	'@',8,0,$80,0,0,'@',8
	dc.b	0,$80,0,0,'@',8,0,$80
	dc.b	0,0,'@',8,0,$80,0,0
	dc.b	'@',8,0,$80,0,0,'@',$a8
	dc.b	0,$80,0,0,'@',$a8,0,$80
	dc.b	0,0,'@',$a8,0,$80,0,0
	dc.b	'@',$a8,0,$80,0,0,'@',$a8
	dc.b	0,$80,0,0,'@',$a8,0,$80
	dc.b	0,0,'AH',0,$80,0,0
	dc.b	'AH',0,$80,0,0,'AH'
	dc.b	0,$80,0,0,'AH',0,$80
	dc.b	0,0,'AH',0,$80,0,0
	dc.b	'AH',0,$80,0,0,'A',$e8
	dc.b	0,$80,0,0,'A',$e8,0,$80
	dc.b	0,0,'A',$e8,0,$80,0,0
	dc.b	'A',$e8,0,$80,0,0,'A',$e8
	dc.b	0,$80,0,0,'A',$e8,0,$80
	dc.b	0,0,'B',$88,0,$80,0,0
	dc.b	'B',$88,0,$80,0,0,'B',$88
	dc.b	0,$80,0,0,'B',$88,0,$80
	dc.b	0,0,'B',$88,0,0,0,$80
	dc.b	'C(',0,0,0,$80,'C('
	dc.b	0,0,0,$80,'C(',0,0
	dc.b	0,$80,'C(',0,0,0,$80
	dc.b	'C(',0,0,0,$80,'C('
	dc.b	0,0,0,$80,'C',$c8,0,0
	dc.b	0,$80,'C',$c8,0,0,0,$80
	dc.b	'C',$c8,0,0,0,$80,'C',$c8
	dc.b	0,0,0,$80,'Dh',0,0
	dc.b	0,$80,'Dh',0,0,0,$80
	dc.b	'Dh',0,0,0,$80,'Dh'
	dc.b	0,0,0,$80,'Dh',0,0
	dc.b	0,'@E',8,0,0,0,'@'
	dc.b	'E',8,0,0,0,'@E',8
	dc.b	0,0,0,'@E',8,0,0
	dc.b	0,'@E',$a8,0,0,0,'@'
	dc.b	'E',$a8,0,0,0,'@E',$a8
	dc.b	0,0,0,'@E',$a8,0,0
	dc.b	0,'@FH',0,0,0,'@'
	dc.b	'FH',0,0,0,'@FH'
	dc.b	0,0,0,' FH',0,0
	dc.b	0,' F',$e8,0,0,0,' '
	dc.b	'F',$e8,0,0,0,' F',$e8
	dc.b	0,0,0,' F',$e8,0,0
	dc.b	0,' G',$88,0,0,0,' '
	dc.b	'G',$88,0,0,0,$10,'G',$88
	dc.b	0,0,0,$10,'G',$88,0,0
	dc.b	0,$10,'H(',0,0,0,$10
	dc.b	'H(',0,0,0,$10,'H('
	dc.b	0,0,0,$10,'H',$c8,0,0
	dc.b	0,8,'H',$c8,0,8,0,8
	dc.b	'H',$c8,0,8,0,8,'Ih'
	dc.b	0,8,0,8,'Ih',0,8
	dc.b	0,8,'Ih',0,4,0,4
	dc.b	'J',8,0,4,0,4,'J',8
	dc.b	0,4,0,4,'J',8,0,4
	dc.b	0,4,'J',$a8,0,2,0,2
	dc.b	'J',$a8,0,2,0,2,'KH'
	dc.b	0,2,0,2,'KH',0,1
	dc.b	0,1,'KH',0,1,0,1
	dc.b	'K',$e8,0,1,0,1,'K',$e8
	dc.b	0,1,0,1,'L',$90,$80,0
	dc.b	$80,0,'L',$90,$80,0,$80,0
	dc.b	'M0@',0,'@',0,'M0'
	dc.b	'@',0,'@',0,'M',$d0,'@',0
	dc.b	'@',0,'M',$d0,' ',0,' ',0
	dc.b	'Np ',0,' ',0,'Np'
	dc.b	$10,0,$10,0,'O',$10,$10,0
	dc.b	$10,0,'O',$b0,8,0,8,0
	dc.b	'O',$b0,8,0,8,0,'PP'
	dc.b	4,0,4,0,'P',$f0,4,0
	dc.b	4,0,'P',$f0,2,0,2,0
	dc.b	'Q',$90,1,0,1,0,'R0'
	dc.b	0,$80,0,$80,'R',$d0,0,$80
	dc.b	0,$80,'Sp',0,'@',0,'@'
	dc.b	'T',$10,0,' ',0,' T',$b0
	dc.b	0,$10,0,$10,'UP',0,8
	dc.b	0,8,'U',$f0,0,4,0,4
	dc.b	'V',$90,0,2,0,2,'W0'
	dc.b	0,1,0,1,'Xx',$80,0
	dc.b	$80,0,'Y',$18,' ',0,' ',0
	dc.b	'ZX',$10,0,$10,0,'[',$98
	dc.b	4,0,4,0,'\8',1,0
	dc.b	1,0,'^',$18,0,'@',0,'@'
	dc.b	'_X',0,$10,0,$10,'a8'
	dc.b	0,2,0,2,'c @',0
	dc.b	'@',0,'e',0,8,0,8,0
	dc.b	'g',$80,1,0,1,0,'j',0
	dc.b	0,8,0,8,'m(',$80,0
	dc.b	$80,0,'p',$e8,2,0,2,0
	dc.b	'uH',0,4,0,4,'z',$f0
	dc.b	2,0,2,0,$ff,$ff,'4',$d0
	dc.b	'@',0,0,0,'4',$d0,$80,0
	dc.b	0,0,'4',$d0,$80,0,0,0
	dc.b	'40',$80,0,0,0,'40'
	dc.b	$80,0,0,0,'4(',0,1
	dc.b	0,0,'4(',0,1,0,0
	dc.b	'4(',0,1,0,0,'4('
	dc.b	0,1,0,0,'3',$88,0,2
	dc.b	0,0,'3',$88,0,2,0,0
	dc.b	'3',$88,0,2,0,0,'3',$88
	dc.b	0,2,0,0,'3',$88,0,4
	dc.b	0,0,'3',$88,0,4,0,0
	dc.b	'2',$e8,0,4,0,0,'2',$e8
	dc.b	0,8,0,0,'2',$e8,0,8
	dc.b	0,0,'2',$e8,0,8,0,0
	dc.b	'2',$e8,0,$10,0,0,'2H'
	dc.b	0,$10,0,0,'2H',0,$10
	dc.b	0,0,'2H',0,' ',0,0
	dc.b	'2H',0,' ',0,0,'2H'
	dc.b	0,'@',0,0,'2H',0,'@'
	dc.b	0,0,'1',$a8,0,'@',0,0
	dc.b	'1',$a8,0,$80,0,0,'1',$a8
	dc.b	0,$80,0,0,'1',$a8,1,0
	dc.b	0,0,'1',$a8,1,0,0,0
	dc.b	'1',$a8,2,0,0,0,'1',8
	dc.b	2,0,0,0,'1',8,4,0
	dc.b	0,0,'1',8,4,0,0,0
	dc.b	'1',8,8,0,0,0,'1',8
	dc.b	0,0,8,0,'0h',0,0
	dc.b	$10,0,'0h',0,0,$10,0
	dc.b	'0h',0,0,' ',0,'0h'
	dc.b	0,0,' ',0,'0h',0,0
	dc.b	'@',0,'0h',0,0,$80,0
	dc.b	'/',$c8,0,0,$80,0,'/',$c0
	dc.b	0,0,0,1,'/',$c0,0,0
	dc.b	0,2,'/',$c0,0,0,0,2
	dc.b	'/',$c0,0,0,0,4,'/ '
	dc.b	0,0,0,8,'/ ',0,0
	dc.b	0,$10,'/ ',0,0,0,$10
	dc.b	'/ ',0,0,0,' / '
	dc.b	0,0,0,'@/ ',0,0
	dc.b	0,$80,'.',$80,0,0,1,0
	dc.b	'.',$80,0,0,2,0,'.',$80
	dc.b	0,0,4,0,'.',$80,0,0
	dc.b	8,0,'-',$e0,0,0,$10,0
	dc.b	'-',$e0,0,0,' ',0,'-',$e0
	dc.b	0,0,$80,0,'-',$d8,0,0
	dc.b	0,1,'-',$d8,0,0,0,2
	dc.b	'-8',0,0,0,8,'-8'
	dc.b	0,0,0,$10,'-8',0,0
	dc.b	0,'@-8',0,0,0,$80
	dc.b	',',$98,0,0,2,0,',',$98
	dc.b	0,0,8,0,',',$98,0,0
	dc.b	' ',0,'+',$f8,0,0,$80,0
	dc.b	'+',$f0,0,0,0,4,'+',$f0
	dc.b	0,0,0,$10,'+P',0,0
	dc.b	0,$80,'+P',0,0,4,0
	dc.b	'*',$b0,0,0,' ',0,'*',$a8
	dc.b	0,1,0,1,'*',8,0,$10
	dc.b	0,$10,'*',8,1,0,1,0
	dc.b	')h ',0,' ',0,')`'
	dc.b	0,4,0,4,'(',$c0,1,0
	dc.b	1,0,'( @',0,'@',0
	dc.b	$27,'x',0,'@',0,'@&',$d8
	dc.b	'@',0,'@',0,'&0',1,0
	dc.b	1,0,'$',$e8,0,$10,0,$10
	dc.b	'#',$a0,0,4,0,4,$ff,$ff
	dc.b	'KH ',0,0,0,'KH'
	dc.b	' ',0,0,0,'K',$e8,' ',0
	dc.b	0,0,'K',$e8,' ',0,0,0
	dc.b	'L',$88,$10,0,0,0,'L',$88
	dc.b	$10,0,0,0,'M(',$10,0
	dc.b	0,0,'M(',$10,0,0,0
	dc.b	'M',$c8,$10,0,0,0,'M',$c8
	dc.b	8,0,0,0,'Nh',8,0
	dc.b	0,0,'Nh',8,0,0,0
	dc.b	'O',8,8,0,0,0,'O',$a8
	dc.b	4,0,0,0,'O',$a8,4,0
	dc.b	0,0,'PH',4,0,0,0
	dc.b	'PH',4,0,0,0,'P',$e8
	dc.b	2,0,0,0,'Q',$88,2,0
	dc.b	0,0,'Q',$88,2,0,0,0
	dc.b	'R(',1,0,0,0,'R',$c8
	dc.b	1,0,0,0,'R',$c8,1,0
	dc.b	0,0,'Sh',0,$80,0,0
	dc.b	'T',8,0,$80,0,0,'T',$a8
	dc.b	0,'@',0,0,'T',$a8,0,'@'
	dc.b	0,0,'UH',0,'@',0,0
	dc.b	'U',$e8,0,' ',0,0,'V',$88
	dc.b	0,' ',0,0,'W(',0,$10
	dc.b	0,0,'W',$c8,0,$10,0,0
	dc.b	'W',$c8,0,8,0,0,'Xh'
	dc.b	0,4,0,0,'Y',8,0,4
	dc.b	0,0,'Y',$a8,0,2,0,0
	dc.b	'ZH',0,0,0,1,'[',$88
	dc.b	0,0,0,1,'\0',0,0
	dc.b	$80,0,'\',$d0,0,0,'@',0
	dc.b	']p',0,0,' ',0,'^',$10
	dc.b	0,0,' ',0,'_P',0,0
	dc.b	$10,0,'_',$f0,0,0,8,0
	dc.b	'a0',0,0,4,0,'a',$d0
	dc.b	0,0,2,0,'c',$10,0,0
	dc.b	1,0,'dP',0,0,0,'@'
	dc.b	'd',$f0,0,0,0,' f0'
	dc.b	0,0,0,$10,'gp',0,0
	dc.b	0,4,'h',$b0,0,0,0,2
	dc.b	'j',$98,0,0,$80,0,'k',$d8
	dc.b	0,0,' ',0,'m',$b8,0,0
	dc.b	8,0,'o',$98,0,0,2,0
	dc.b	'qx',0,0,0,$80,'sX'
	dc.b	0,0,0,$10,'u',$d8,0,0
	dc.b	0,4,'x`',0,0,$80,0
	dc.b	'{',$80,0,0,8,0,$ff,$ff
	dc.b	'G',$88,'@',0,0,0,'H('
	dc.b	'@',0,0,0,'H( ',0
	dc.b	0,0,'H',$c8,' ',0,0,0
	dc.b	'H',$c8,' ',0,0,0,'H',$c8
	dc.b	' ',0,0,0,'Ih ',0
	dc.b	0,0,'Ih ',0,0,0
	dc.b	'Ih ',0,0,0,'J',8
	dc.b	$10,0,0,0,'J',8,$10,0
	dc.b	0,0,'J',$a8,$10,0,0,0
	dc.b	'J',$a8,$10,0,0,0,'J',$a8
	dc.b	$10,0,0,0,'KH',$10,0
	dc.b	0,0,'KH',8,0,0,0
	dc.b	'K',$e8,8,0,0,0,'K',$e8
	dc.b	8,0,0,0,'K',$e8,8,0
	dc.b	0,0,'L',$88,8,0,0,0
	dc.b	'L',$88,4,0,0,0,'M('
	dc.b	4,0,0,0,'M(',4,0
	dc.b	0,0,'M',$c8,4,0,0,0
	dc.b	'M',$c8,2,0,0,0,'M',$c8
	dc.b	2,0,0,0,'Nh',2,0
	dc.b	0,0,'Nh',1,0,0,0
	dc.b	'O',8,1,0,0,0,'O',8
	dc.b	1,0,0,0,'O',$a8,1,0
	dc.b	0,0,'O',$a8,0,$80,0,0
	dc.b	'PH',0,$80,0,0,'PH'
	dc.b	0,$80,0,0,'P',$e8,0,'@'
	dc.b	0,0,'P',$e8,0,'@',0,0
	dc.b	'Q',$88,0,0,0,' Q',$88
	dc.b	0,0,0,' R(',0,0
	dc.b	0,' R(',0,0,0,$10
	dc.b	'R',$c8,0,0,0,$10,'R',$c8
	dc.b	0,0,0,8,'Sh',0,0
	dc.b	0,8,'Sh',0,0,0,4
	dc.b	'T',8,0,0,0,4,'T',8
	dc.b	0,0,0,2,'T',$a8,0,0
	dc.b	0,2,'UH',0,0,0,1
	dc.b	'UH',0,0,0,1,'U',$f0
	dc.b	0,0,$80,0,'U',$f0,0,0
	dc.b	'@',0,'V',$90,0,0,'@',0
	dc.b	'W0',0,0,' ',0,'W0'
	dc.b	0,0,' ',0,'W',$d0,0,0
	dc.b	$10,0,'Xp',0,0,8,0
	dc.b	'Xp',0,0,4,0,'Y',$10
	dc.b	0,0,4,0,'Y',$b0,0,0
	dc.b	2,0,'Y',$b0,0,0,1,0
	dc.b	'ZP',0,0,0,$80,'Z',$f0
	dc.b	0,0,0,'@[',$90,0,0
	dc.b	0,' \0',0,0,0,$10
	dc.b	'\',$d0,0,0,0,8,'\',$d0
	dc.b	0,0,0,4,']p',0,0
	dc.b	0,2,'^',$10,0,0,0,1
	dc.b	'^',$b8,0,0,$80,0,'_X'
	dc.b	0,0,'@',0,'_',$f8,0,0
	dc.b	$10,0,'`',$98,0,0,8,0
	dc.b	'a8',0,0,4,0,'bx'
	dc.b	0,0,1,0,'c',$18,0,0
	dc.b	0,$80,'c',$b8,0,0,0,' '
	dc.b	'dX',0,8,0,8,'e',$98
	dc.b	0,2,0,2,'f@',$80,0
	dc.b	$80,0,'g',$80,' ',0,' ',0
	dc.b	'h',$c0,8,0,8,0,'i`'
	dc.b	2,0,2,0,'j',$a0,0,'@'
	dc.b	0,'@k',$e0,0,8,0,8
	dc.b	'm ',0,2,0,2,'o',8
	dc.b	' ',0,' ',0,'pH',4,0
	dc.b	4,0,'r(',0,'@',0,'@'
	dc.b	't',8,0,4,0,4,'u',$f0
	dc.b	'@',0,'@',0,'w',$d0,2,0
	dc.b	2,0,'zP',0,$10,0,$10
	dc.b	'|',$d8,'@',0,'@',0,$ff,$ff
	dc.b	'9( ',0,0,0,'9',$c8
	dc.b	' ',0,0,0,'9',$c8,'@',0
	dc.b	0,0,'9',$c8,'@',0,0,0
	dc.b	'9',$c8,'@',0,0,0,'9',$c8
	dc.b	'@',0,0,0,'9',$c8,$80,0
	dc.b	0,0,'9',$c8,$80,0,0,0
	dc.b	':h',$80,0,0,0,':h'
	dc.b	$80,0,0,0,':`',0,1
	dc.b	0,0,':`',0,1,0,0
	dc.b	':`',0,1,0,0,';',0
	dc.b	0,1,0,0,';',0,0,2
	dc.b	0,0,';',0,0,2,0,0
	dc.b	';',0,0,2,0,0,';',$a0
	dc.b	0,2,0,0,';',$a0,0,4
	dc.b	0,0,';',$a0,0,4,0,0
	dc.b	';',$a0,0,4,0,0,'<@'
	dc.b	0,4,0,0,'<@',0,8
	dc.b	0,0,'<@',0,8,0,0
	dc.b	'<@',0,8,0,0,'<',$e0
	dc.b	0,8,0,0,'<',$e0,0,8
	dc.b	0,0,'<',$e0,0,$10,0,0
	dc.b	'<',$e0,0,$10,0,0,'=',$80
	dc.b	0,$10,0,0,'=',$80,0,$10
	dc.b	0,0,'=',$80,0,' ',0,0
	dc.b	'> ',0,' ',0,0,'> '
	dc.b	0,' ',0,0,'> ',0,' '
	dc.b	0,0,'>',$c0,0,'@',0,0
	dc.b	'>',$c0,0,0,0,'@>',$c0
	dc.b	0,0,0,'@?`',0,0
	dc.b	0,'@?`',0,0,0,$80
	dc.b	'@',0,0,0,0,$80,'@',0
	dc.b	0,0,0,$80,'@',0,0,0
	dc.b	0,$80,'@',$a0,0,0,1,0
	dc.b	'@',$a0,0,0,1,0,'A@'
	dc.b	0,0,1,0,'A@',0,0
	dc.b	1,0,'A',$e0,0,0,2,0
	dc.b	'A',$e0,0,0,2,0,'B',$80
	dc.b	0,0,2,0,'B',$80,0,0
	dc.b	4,0,'C ',0,0,4,0
	dc.b	'C ',0,0,4,0,'C',$c0
	dc.b	0,0,4,0,'C',$c0,0,0
	dc.b	8,0,'D`',0,0,8,0
	dc.b	'D`',0,0,8,0,'E',0
	dc.b	0,0,8,0,'E',0,0,0
	dc.b	$10,0,'E',$a0,0,0,$10,0
	dc.b	'F@',0,0,$10,0,'F@'
	dc.b	0,0,$10,0,'F',$e0,0,0
	dc.b	' ',0,'G',$80,0,0,' ',0
	dc.b	'G',$80,0,0,' ',0,'H '
	dc.b	0,0,' ',0,'H',$c0,0,0
	dc.b	'@',0,'I`',0,0,'@',0
	dc.b	'J',0,0,0,'@',0,'J',0
	dc.b	0,0,$80,0,'J',$a0,0,0
	dc.b	$80,0,'K@',0,0,$80,0
	dc.b	'K',$e0,0,0,$80,0,'Lx'
	dc.b	0,0,0,1,'M',$18,0,0
	dc.b	0,1,'M',$b8,0,0,0,1
	unlk	a0
	ori.b	#2,d2
	jmp	2.w
	dc.b	0,2,'O',$98,0,2,0,2
	dc.b	'P8',0,4,0,4,'Qx'
	dc.b	0,4,0,4,'R',$18,0,4
	dc.b	0,4,'R',$b8,0,8,0,8
	dc.b	'S',$f8,0,8,0,8,'T',$98
	dc.b	0,8,0,8,'U',$d8,0,$10
	dc.b	0,$10,'Vx',0,$10,0,$10
	dc.b	'W',$b8,0,$10,0,$10,'X',$f8
	dc.b	0,' ',0,' Y',$98,0,' '
	dc.b	0,' Z',$d8,0,'@',0,'@'
	dc.b	'\',$18,0,'@',0,'@]',$f8
	dc.b	0,$80,0,$80,'_8',0,$80
	dc.b	0,$80,'`x',1,0,1,0
	dc.b	'bX',1,0,1,0,'d8'
	dc.b	2,0,2,0,'f',$18,4,0
	dc.b	4,0,'g',$f8,4,0,4,0
	dc.b	'jx',8,0,8,0,'lX'
	dc.b	$10,0,$10,0,'ox ',0
	dc.b	' ',0,'q',$f8,' ',0,' ',0
	dc.b	'u',$18,'@',0,'@',0,'x',$d8
	dc.b	$80,0,$80,0,'|',$90,0,2
	dc.b	0,2,$ff,$ff,'1',$a0,' ',0
	dc.b	0,0,'1',$a0,'@',0,0,0
	dc.b	'1',$a0,'@',0,0,0,'1',$a0
	dc.b	$80,0,0,0,'28',0,1
	dc.b	0,0,'28',0,1,0,0
	dc.b	'28',0,2,0,0,'2',$d8
	dc.b	0,2,0,0,'2',$d8,0,4
	dc.b	0,0,'2',$d8,0,8,0,0
	dc.b	'3x',0,8,0,0,'3x'
	dc.b	0,$10,0,0,'3x',0,' '
	dc.b	0,0,'4',$18,0,'@',0,0
	dc.b	'4',$18,0,'@',0,0,'4',$b8
	dc.b	0,$80,0,0,'4',$b8,1,0
	dc.b	0,0,'4',$b8,1,0,0,0
	dc.b	'5X',2,0,0,0,'5X'
	dc.b	4,0,0,0,'5',$f8,8,0
	dc.b	0,0,'5',$f8,8,0,0,0
	dc.b	'6',$98,$10,0,0,0,'78'
	dc.b	' ',0,0,0,'78@',0
	dc.b	0,0,'7',$d8,'@',0,0,0
	dc.b	'7',$d8,$80,0,0,0,'8p'
	dc.b	0,1,0,0,'9',$10,0,2
	dc.b	0,0,'9',$10,0,4,0,0
	dc.b	'9',$b0,0,4,0,0,':P'
	dc.b	0,8,0,0,':P',0,$10
	dc.b	0,0,':',$f0,0,' ',0,0
	dc.b	';',$90,0,'@',0,0,'<0'
	dc.b	0,$80,0,0,'<0',0,0
	dc.b	1,0,'<',$d0,0,0,2,0
	dc.b	'=p',0,0,4,0,'>',$10
	dc.b	0,0,8,0,'>',$b0,0,0
	dc.b	$10,0,'?P',0,0,' ',0
	dc.b	'?',$f0,0,0,'@',0,'@',$90
	dc.b	0,0,$80,0,'A(',0,0
	dc.b	0,1,'A',$c8,0,0,0,2
	dc.b	'Bh',0,0,0,4,'C',$a8
	dc.b	0,0,0,8,'DH',0,0
	dc.b	0,$10,'D',$e8,0,0,0,' '
	dc.b	'E',$88,0,0,0,'@F',$c8
	dc.b	0,0,1,0,'Gh',0,0
	dc.b	2,0,'H',$a8,0,0,4,0
	dc.b	'IH',0,0,$10,0,'J',$88
	dc.b	0,0,' ',0,'K',$c8,0,0
	dc.b	'@',0,'L`',0,0,0,1
	dc.b	'M',$a0,0,0,0,2,'N',$e0
	dc.b	0,0,0,8,'P ',0,0
	dc.b	0,$10,'Q`',0,0,0,'@'
	dc.b	'R',$a0,0,0,1,0,'T',$80
	dc.b	0,0,4,0,'U',$c0,0,0
	dc.b	$10,0,'W',0,0,0,' ',0
	dc.b	'X',$d8,0,0,0,1,'Z',$b8
	dc.b	0,0,0,4,'\',$98,0,0
	dc.b	0,$10,'^x',0,0,0,'@'
	dc.b	'`X',0,0,2,0,'b',$d8
	dc.b	0,0,8,0,'eX',0,0
	dc.b	'@',0,'g',$d0,0,0,0,2
	dc.b	'jP',0,0,0,$10,'mp'
	dc.b	0,0,1,0,'p',$90,8,0
	dc.b	8,0,'s',$b0,$80,0,$80,0
	dc.b	'wh',0,$10,0,$10,'{('
	dc.b	1,0,1,0,$ff,$ff,'R('
	dc.b	0,8,0,0,'R(',0,4
	dc.b	0,0,'R(',0,4,0,0
	dc.b	'R',$c8,0,2,0,0,'R',$c8
	dc.b	0,2,0,0,'R',$c8,0,1
	dc.b	0,0,'Sh',0,1,0,0
	dc.b	'Sp',$80,0,0,0,'T',$10
	dc.b	$80,0,0,0,'T',$10,'@',0
	dc.b	0,0,'T',$10,'@',0,0,0
	dc.b	'T',$b0,' ',0,0,0,'T',$b0
	dc.b	$10,0,0,0,'T',$b0,$10,0
	dc.b	0,0,'UP',8,0,0,0
	dc.b	'UP',8,0,0,0,'UP'
	dc.b	4,0,0,0,'U',$f0,2,0
	dc.b	0,0,'U',$f0,2,0,0,0
	dc.b	'U',$f0,1,0,0,0,'V',$90
	dc.b	0,$80,0,0,'V',$90,0,$80
	dc.b	0,0,'V',$90,0,'@',0,0
	dc.b	'V',$90,0,' ',0,0,'W0'
	dc.b	0,$10,0,0,'W0',0,$10
	dc.b	0,0,'W0',0,8,0,0
	dc.b	'W',$d0,0,4,0,0,'W',$d0
	dc.b	0,2,0,0,'W',$d0,0,1
	dc.b	0,0,'Xp',0,1,0,0
	dc.b	'Xx',$80,0,0,0,'Xx'
	dc.b	'@',0,0,0,'Y',$18,' ',0
	dc.b	0,0,'Y',$18,$10,0,0,0
	dc.b	'Y',$18,8,0,0,0,'Y',$18
	dc.b	0,0,4,0,'Y',$b8,0,0
	dc.b	2,0,'Y',$b8,0,0,1,0
	dc.b	'Y',$b8,0,0,0,$80,'ZX'
	dc.b	0,0,0,'@ZX',0,0
	dc.b	0,' ZX',0,0,0,$10
	dc.b	'Z',$f8,0,0,0,4,'Z',$f8
	dc.b	0,0,0,2,'Z',$f8,0,0
	dc.b	0,1,'[',0,0,0,$80,0
	dc.b	'[',$a0,0,0,' ',0,'[',$a0
	dc.b	0,0,$10,0,'[',$a0,0,0
	dc.b	8,0,'[',$a0,0,0,2,0
	dc.b	'\@',0,0,1,0,'\@'
	dc.b	0,0,0,'@\@',0,0
	dc.b	0,' \',$e0,0,0,0,8
	dc.b	'\',$e0,0,0,0,2,'\',$e0
	dc.b	0,0,0,1,'\',$e8,0,0
	dc.b	'@',0,']',$88,0,0,$10,0
	dc.b	']',$88,0,0,4,0,']',$88
	dc.b	0,0,1,0,']',$88,0,0
	dc.b	0,'@^(',0,0,0,$10
	dc.b	'^(',0,0,0,4,'^0'
	dc.b	0,0,$80,0,'^0',0,0
	dc.b	' ',0,'^',$d0,0,0,4,0
	dc.b	'^',$d0,0,0,1,0,'^',$d0
	dc.b	0,0,0,' ^',$d0,0,0
	dc.b	0,4,'_x',0,0,$80,0
	dc.b	'_x',0,0,8,0,'_x'
	dc.b	0,0,1,0,'`',$18,0,0
	dc.b	0,$10,'`',$18,0,0,0,1
	dc.b	'` ',0,0,$10,0,'` '
	dc.b	1,0,1,0,'`',$c0,0,8
	dc.b	0,8,'`',$c8,'@',0,'@',0
	dc.b	'`',$c8,2,0,2,0,'ah'
	dc.b	0,8,0,8,'ap',$10,0
	dc.b	$10,0,'ap',0,' ',0,' '
	dc.b	'b',$18,'@',0,'@',0,'b',$18
	dc.b	0,'@',0,'@',$ff,$ff,'H',$c8
	dc.b	0,' ',0,0,'H',$c8,0,' '
	dc.b	0,0,'H',$c8,0,' ',0,0
	dc.b	'Ih',0,' ',0,0,'Ih'
	dc.b	0,$10,0,0,'Ih',0,$10
	dc.b	0,0,'Ih',0,$10,0,0
	dc.b	'J',8,0,$10,0,0,'J',8
	dc.b	0,8,0,0,'J',8,0,8
	dc.b	0,0,'J',8,0,8,0,0
	dc.b	'J',$a8,0,8,0,0,'J',$a8
	dc.b	0,4,0,0,'J',$a8,0,4
	dc.b	0,0,'KH',0,4,0,0
	dc.b	'KH',0,4,0,0,'KH'
	dc.b	0,2,0,0,'KH',0,2
	dc.b	0,0,'K',$e8,0,2,0,0
	dc.b	'K',$e8,0,1,0,0,'K',$e8
	dc.b	0,1,0,0,'L',$88,0,1
	dc.b	0,0,'L',$90,$80,0,0,0
	dc.b	'L',$90,$80,0,0,0,'M0'
	dc.b	$80,0,0,0,'M0@',0
	dc.b	0,0,'M0@',0,0,0
	dc.b	'M',$d0,' ',0,0,0,'M',$d0
	dc.b	' ',0,0,0,'M',$d0,' ',0
	dc.b	0,0,'Np',$10,0,0,0
	dc.b	'Np',$10,0,0,0,'Np'
	dc.b	8,0,0,0,'O',$10,8,0
	dc.b	0,0,'O',$10,4,0,0,0
	dc.b	'O',$10,4,0,0,0,'O',$b0
	dc.b	0,0,2,0,'O',$b0,0,0
	dc.b	2,0,'O',$b0,0,0,1,0
	dc.b	'PP',0,0,1,0,'PP'
	dc.b	0,0,0,$80,'P',$f0,0,0
	dc.b	0,'@P',$f0,0,0,0,'@'
	dc.b	'P',$f0,0,0,0,' Q',$90
	dc.b	0,0,0,$10,'Q',$90,0,0
	dc.b	0,$10,'R0',0,0,0,8
	dc.b	'R0',0,0,0,4,'R',$d0
	dc.b	0,0,0,2,'R',$d0,0,0
	dc.b	0,2,'Sp',0,0,0,1
	dc.b	'Sx',0,0,$80,0,'T',$18
	dc.b	0,0,'@',0,'T',$18,0,0
	dc.b	' ',0,'T',$b8,0,0,$10,0
	dc.b	'T',$b8,0,0,8,0,'UX'
	dc.b	0,0,4,0,'UX',0,0
	dc.b	2,0,'U',$f8,0,0,0,$80
	dc.b	'V',$98,0,0,0,'@V',$98
	dc.b	0,0,0,' W8',0,0
	dc.b	0,8,'W',$d8,0,0,0,4
	dc.b	'Xx',0,0,0,1,'Y '
	dc.b	0,0,'@',0,'Y ',0,0
	dc.b	' ',0,'Y',$c0,0,0,8,0
	dc.b	'Z`',0,0,2,0,'[',$a0
	dc.b	0,0,0,'@\@',0,0
	dc.b	0,$10,'\',$e0,0,0,0,4
	dc.b	']',$88,0,0,$80,0,'^',$c8
	dc.b	0,0,$10,0,'_h',0,0
	dc.b	2,0,'`',$a8,0,0,0,' '
	dc.b	'a',$e8,0,0,0,2,'c0'
	dc.b	' ',0,' ',0,'dp',1,0
	dc.b	1,0,'e',$b0,0,8,0,8
	dc.b	'g',$98,' ',0,' ',0,'ix'
	dc.b	0,'@',0,'@l',0,'@',0
	dc.b	'@',0,'n',$80,0,' ',0,' '
	dc.b	'q',$a8,4,0,4,0,'up'
	dc.b	' ',0,' ',0,'y',$d8,'@',0
	dc.b	'@',0,$ff,$ff,'C',$c8,0,$10
	dc.b	0,0,'C',$c8,0,$10,0,0
	dc.b	'C',$c8,0,$10,0,0,'C',$c8
	dc.b	0,$10,0,0,'C',$c8,0,$10
	dc.b	0,0,'C',$c8,0,$10,0,0
	dc.b	'Dh',0,8,0,0,'Dh'
	dc.b	0,8,0,0,'Dh',0,8
	dc.b	0,0,'Dh',0,8,0,0
	dc.b	'Dh',0,8,0,0,'E',8
	dc.b	0,8,0,0,'E',8,0,8
	dc.b	0,0,'E',8,0,8,0,0
	dc.b	'E',8,0,8,0,0,'E',$a8
	dc.b	0,8,0,0,'E',$a8,0,4
	dc.b	0,0,'E',$a8,0,4,0,0
	dc.b	'E',$a8,0,4,0,0,'FH'
	dc.b	0,4,0,0,'FH',0,4
	dc.b	0,0,'FH',0,4,0,0
	dc.b	'FH',0,4,0,0,'F',$e8
	dc.b	0,2,0,0,'F',$e8,0,2
	dc.b	0,0,'F',$e8,0,2,0,0
	dc.b	'F',$e8,0,2,0,0,'G',$88
	dc.b	0,2,0,0,'G',$88,0,1
	dc.b	0,0,'G',$88,0,1,0,0
	dc.b	'H(',0,1,0,0,'H('
	dc.b	0,1,0,0,'H0',$80,0
	dc.b	0,0,'H',$d0,$80,0,0,0
	dc.b	'H',$d0,$80,0,0,0,'Ip'
	dc.b	$80,0,0,0,'Ip',0,0
	dc.b	'@',0,'Ip',0,0,'@',0
	dc.b	'J',$10,0,0,'@',0,'J',$10
	dc.b	0,0,' ',0,'J',$b0,0,0
	dc.b	' ',0,'J',$b0,0,0,' ',0
	dc.b	'KP',0,0,$10,0,'K',$f0
	dc.b	0,0,$10,0,'K',$f0,0,0
	dc.b	8,0,'L',$90,0,0,8,0
	dc.b	'M0',0,0,4,0,'M0'
	dc.b	0,0,4,0,'M',$d0,0,0
	dc.b	2,0,'Np',0,0,2,0
	dc.b	'O',$10,0,0,1,0,'O',$b0
	dc.b	0,0,0,$80,'PP',0,0
	dc.b	0,'@P',$f0,0,0,0,' '
	dc.b	'Q',$90,0,0,0,$10,'R0'
	dc.b	0,0,0,8,'Sp',0,0
	dc.b	0,4,'T',$10,0,0,0,2
	dc.b	'UP',0,0,0,1,'V',$98
	dc.b	0,0,'@',0,'W',$d8,0,0
	dc.b	$10,0,'Y',$b8,0,0,4,0
	dc.b	'[',$98,0,0,1,0,']x'
	dc.b	0,0,0,' _',$f8,0,0
	dc.b	0,4,'c ',0,0,'@',0
	dc.b	'f@',0,0,4,0,'j',$a0
	dc.b	0,0,0,$10,'pH',0,0
	dc.b	' ',0,'w',$c8,0,0,0,8
	dc.b	$ff,$ff,'A',$f8,0,' ',0,0
	dc.b	'A',$f8,0,' ',0,0,'AX'
	dc.b	0,$10,0,0,'AX',0,$10
	dc.b	0,0,'AX',0,$10,0,0
	dc.b	'@',$b8,0,8,0,0,'@',$b8
	dc.b	0,8,0,0,'@',$18,0,8
	dc.b	0,0,'@',$18,0,4,0,0
	dc.b	'?x',0,4,0,0,'?x'
	dc.b	0,4,0,0,'?x',0,2
	dc.b	0,0,'>',$d8,0,2,0,0
	dc.b	'>',$d8,0,2,0,0,'>8'
	dc.b	0,1,0,0,'>8',0,1
	dc.b	0,0,'=',$98,0,1,0,0
	dc.b	'=',$a0,$80,0,0,0,'=',0
	dc.b	$80,0,0,0,'<`',$80,0
	dc.b	0,0,'<`@',0,0,0
	dc.b	';',$c0,'@',0,0,0,';',$c0
	dc.b	'@',0,0,0,';  ',0
	dc.b	0,0,';  ',0,0,0
	dc.b	':',$80,' ',0,0,0,'9',$e0
	dc.b	$10,0,0,0,'9',$e0,$10,0
	dc.b	0,0,'9@',$10,0,0,0
	dc.b	'8',$a0,8,0,0,0,'8',$a0
	dc.b	8,0,0,0,'8',0,8,0
	dc.b	0,0,'7`',4,0,0,0
	dc.b	'6',$c0,4,0,0,0,'6',$c0
	dc.b	4,0,0,0,'6 ',2,0
	dc.b	0,0,'5',$80,0,0,2,0
	dc.b	'4',$e0,0,0,2,0,'4@'
	dc.b	0,0,1,0,'4@',0,0
	dc.b	1,0,'3',$a0,0,0,1,0
	dc.b	'3',0,0,0,0,$80,'2`'
	dc.b	0,0,0,$80,'1',$c0,0,0
	dc.b	0,$80,'1 ',0,0,0,'@'
	dc.b	'0',$80,0,0,0,'@/',$e0
	dc.b	0,0,0,'@/@',0,0
	dc.b	0,' .',$a0,0,0,0,' '
	dc.b	'-`',0,0,0,' ,',$c0
	dc.b	0,0,0,$10,', ',0,0
	dc.b	0,$10,'+',$80,0,0,0,$10
	dc.b	'*',$e0,0,0,0,8,')',$a0
	dc.b	0,0,0,8,')',0,0,0
	dc.b	0,8,$27,$c0,0,0,0,4
	dc.b	$27,' ',0,0,0,4,'%',$e0
	dc.b	0,0,0,2,'%@',0,0
	dc.b	0,2,'$',0,0,0,0,2
	dc.b	'"',$c0,0,0,0,1,'" '
	dc.b	0,0,0,1,' ',$e8,0,0
	dc.b	$80,0,$1f,$a8,0,0,$80,0
	dc.b	$1e,'h',0,0,$80,0,$1d,'('
	dc.b	0,0,'@',0,$1b,'H',0,0
	dc.b	'@',0,$1a,8,0,0,' ',0
	dc.b	$18,$c8,0,0,' ',0,$16,$e8
	dc.b	0,0,$10,0,$15,8,0,0
	dc.b	$10,0,$13,'(',0,0,8,0
	dc.b	$11,'H',0,0,8,0,$f,'h'
	dc.b	0,0,4,0,$d,$88,0,0
	dc.b	4,0,$b,8,2,0,2,0
	dc.b	8,$88,2,0,2,0,6,8
	dc.b	1,0,1,0,3,$88,0,$80
	dc.b	0,$80,0,'h',0,'@',0,'@'
	dc.b	$ff,$ff,'K',$f0,0,1,0,0
	dc.b	'K',$f0,0,1,0,0,'K',$f8
	dc.b	$80,0,0,0,'K',$f8,$80,0
	dc.b	0,0,'K',$f8,'@',0,0,0
	dc.b	'K',$f8,' ',0,0,0,'K',$f8
	dc.b	' ',0,0,0,'K',$f8,$10,0
	dc.b	0,0,'K',$f8,$10,0,0,0
	dc.b	'K',$f8,8,0,0,0,'K',$f8
	dc.b	4,0,0,0,'K',$f8,4,0
	dc.b	0,0,'K',$f8,2,0,0,0
	dc.b	'K',$f8,2,0,0,0,'K',$f8
	dc.b	1,0,0,0,'K',$f8,0,$80
	dc.b	0,0,'K',$f8,0,$80,0,0
	dc.b	'K',$f8,0,'@',0,0,'K',$f8
	dc.b	0,' ',0,0,'KX',0,$10
	dc.b	0,0,'KX',0,$10,0,0
	dc.b	'KX',0,8,0,0,'KX'
	dc.b	0,4,0,0,'KX',0,2
	dc.b	0,0,'KX',0,1,0,0
	dc.b	'K`',$80,0,0,0,'K`'
	dc.b	$80,0,0,0,'J',$c0,'@',0
	dc.b	0,0,'J',$c0,' ',0,0,0
	dc.b	'J',$c0,$10,0,0,0,'J',$c0
	dc.b	8,0,0,0,'J',$c0,4,0
	dc.b	0,0,'J ',2,0,0,0
	dc.b	'J ',1,0,0,0,'J '
	dc.b	0,$80,0,0,'J ',0,'@'
	dc.b	0,0,'I',$80,0,0,0,$10
	dc.b	'I',$80,0,0,0,8,'I',$80
	dc.b	0,0,0,4,'H',$e0,0,0
	dc.b	0,2,'H',$e8,0,0,$80,0
	dc.b	'HH',0,0,'@',0,'HH'
	dc.b	0,0,$10,0,'HH',0,0
	dc.b	8,0,'G',$a8,0,0,2,0
	dc.b	'G',$a8,0,0,1,0,'G',8
	dc.b	0,0,0,'@G',8,0,0
	dc.b	0,$10,'Fh',0,0,0,4
	dc.b	'E',$c8,0,0,0,1,'E',$d0
	dc.b	0,0,'@',0,'E0',0,0
	dc.b	$10,0,'D',$90,0,0,4,0
	dc.b	'C',$f0,0,0,0,$80,'C',$f0
	dc.b	0,0,0,' CP',0,0
	dc.b	0,4,'B',$b8,0,0,$80,0
	dc.b	'B',$18,0,0,$10,0,'@',$d8
	dc.b	0,0,1,0,'@8',0,0
	dc.b	0,' ?',$98,0,0,0,2
	dc.b	'>`',0,0,' ',0,'=',$c0
	dc.b	0,0,1,0,'<',$80,0,0
	dc.b	0,8,';H',0,0,' ',0
	dc.b	':',8,0,0,0,$80,'8('
	dc.b	0,0,0,1,'6P',0,0
	dc.b	2,0,'4p',0,0,0,1
	dc.b	'2',$98,0,0,0,'@',$ff,$ff
	dc.b	'A',$f8,$10,0,0,0,'A',$f8
	dc.b	$10,0,0,0,'AX',8,0
	dc.b	0,0,'AX',8,0,0,0
	dc.b	'AX',8,0,0,0,'@',$b8
	dc.b	8,0,0,0,'@',$b8,4,0
	dc.b	0,0,'@',$b8,4,0,0,0
	dc.b	'@',$b8,4,0,0,0,'@',$18
	dc.b	4,0,0,0,'@',$18,4,0
	dc.b	0,0,'@',$18,2,0,0,0
	dc.b	'?x',2,0,0,0,'?x'
	dc.b	2,0,0,0,'?x',2,0
	dc.b	0,0,'>',$d8,1,0,0,0
	dc.b	'>',$d8,1,0,0,0,'>',$d8
	dc.b	1,0,0,0,'>8',1,0
	dc.b	0,0,'>8',0,$80,0,0
	dc.b	'=',$98,0,$80,0,0,'=',$98
	dc.b	0,$80,0,0,'=',$98,0,$80
	dc.b	0,0,'<',$f8,0,$80,0,0
	dc.b	'<',$f8,0,'@',0,0,'<X'
	dc.b	0,'@',0,0,'<X',0,'@'
	dc.b	0,0,';',$b8,0,'@',0,0
	dc.b	';',$b8,0,'@',0,0,';',$b8
	dc.b	0,' ',0,0,';',$18,0,' '
	dc.b	0,0,';',$18,0,' ',0,0
	dc.b	':x',0,' ',0,0,':x'
	dc.b	0,' ',0,0,'9',$d8,0,$10
	dc.b	0,0,'9',$d8,0,$10,0,0
	dc.b	'98',0,0,0,$10,'98'
	dc.b	0,0,0,$10,'8',$98,0,0
	dc.b	0,$10,'7',$f8,0,0,0,8
	dc.b	'7',$f8,0,0,0,8,'7X'
	dc.b	0,0,0,8,'7X',0,0
	dc.b	0,8,'6',$b8,0,0,0,8
	dc.b	'6',$18,0,0,0,8,'6',$18
	dc.b	0,0,0,4,'5x',0,0
	dc.b	0,4,'5x',0,0,0,4
	dc.b	'4',$d8,0,0,0,4,'48'
	dc.b	0,0,0,4,'48',0,0
	dc.b	0,4,'3',$98,0,0,0,4
	dc.b	'2',$f8,0,0,0,2,'2X'
	dc.b	0,0,0,2,'2X',0,0
	dc.b	0,2,'1',$b8,0,0,0,2
	dc.b	'1',$18,0,0,0,2,'0x'
	dc.b	0,0,0,2,'/',$d8,0,0
	dc.b	0,2,'/',$d8,0,0,0,2
	dc.b	'/8',0,0,0,1,'.',$98
	dc.b	0,0,0,1,'-',$f8,0,0
	dc.b	0,1,'-X',0,0,0,1
	dc.b	',',$b8,0,0,0,1,',',$18
	dc.b	0,0,0,1,'+x',0,0
	dc.b	0,1,'*',$d8,0,0,0,1
	dc.b	'*8',0,0,0,1,')',$98
	dc.b	0,0,0,1,'(X',0,0
	dc.b	0,1,$27,$c0,0,0,$80,0
	dc.b	$27,' ',0,0,$80,0,'&',$80
	dc.b	0,0,$80,0,'%@',0,0
	dc.b	$80,0,'$',$a0,0,0,$80,0
	dc.b	'$',0,$80,0,$80,0,'"',$c0
	dc.b	$80,0,$80,0,'" ',$80,0
	dc.b	$80,0,' ',$e0,$80,0,$80,0
	dc.b	' @',$80,0,$80,0,$1f,0
	dc.b	$80,0,$80,0,$1d,$c0,$80,0
	dc.b	$80,0,$1c,$80,$80,0,$80,0
	dc.b	$1b,'@',$80,0,$80,0,$1a,0
	dc.b	$80,0,$80,0,$18,$c0,$80,0
	dc.b	$80,0,$17,'x',0,1,0,1
	dc.b	$16,'8',0,1,0,1,$14,'X'
	dc.b	0,1,0,1,$13,$18,0,1
	dc.b	0,1,$11,'8',0,1,0,1
	dc.b	$f,'X',0,1,0,1,$d,'x'
	dc.b	0,1,0,1,$b,$98,0,1
	dc.b	0,1,9,$18,0,2,0,2
	dc.b	6,$98,0,2,0,2,4,$18
	dc.b	0,2,0,2,1,$98,0,2
	dc.b	0,2,$ff,$ff,'/8@',0
	dc.b	0,0,'.',$98,'@',0,0,0
	dc.b	'-',$f8,'@',0,0,0,'-',$f8
	dc.b	'@',0,0,0,'-X@',0
	dc.b	0,0,',',$b8,'@',0,0,0
	dc.b	',',$18,$80,0,0,0,'+x'
	dc.b	$80,0,0,0,'+x',$80,0
	dc.b	0,0,'*',$d8,$80,0,0,0
	dc.b	'*8',$80,0,0,0,')',$98
	dc.b	$80,0,0,0,'(',$f0,0,1
	dc.b	0,0,'(P',0,1,0,0
	dc.b	$27,$b0,0,1,0,0,$27,$10
	dc.b	0,1,0,0,'&p',0,1
	dc.b	0,0,'%0',0,2,0,0
	dc.b	'$',$90,0,2,0,0,'#',$f0
	dc.b	0,2,0,0,'"',$b0,0,4
	dc.b	0,0,'"',$10,0,4,0,0
	dc.b	'!p',0,4,0,0,' 0'
	dc.b	0,8,0,0,$1e,$f0,0,8
	dc.b	0,0,$1e,'P',0,$10,0,0
	dc.b	$1d,$10,0,$10,0,0,$1b,$d0
	dc.b	0,' ',0,0,$1a,$90,0,' '
	dc.b	0,0,$19,'P',0,'@',0,0
	dc.b	$18,$10,0,'@',0,0,$16,'0'
	dc.b	0,$80,0,0,$14,$f0,1,0
	dc.b	0,0,$13,$10,1,0,0,0
	dc.b	$11,'0',2,0,0,0,$f,'P'
	dc.b	4,0,0,0,$c,$d0,0,0
	dc.b	8,0,$a,'P',0,0,$10,0
	dc.b	7,$d0,0,0,'@',0,5,'P'
	dc.b	0,0,$80,0,1,$88,0,0
	dc.b	0,1,$ff,$ff,'<P',0,$10
	dc.b	0,0,';',$b0,0,$10,0,0
	dc.b	';',$b0,0,$10,0,0,';',$b0
	dc.b	0,$10,0,0,';',$b0,0,$10
	dc.b	0,0,';',$10,0,$10,0,0
	dc.b	';',$10,0,$10,0,0,';',$10
	dc.b	0,$10,0,0,';',$10,0,$10
	dc.b	0,0,';',$10,0,8,0,0
	dc.b	':p',0,8,0,0,':p'
	dc.b	0,8,0,0,':p',0,8
	dc.b	0,0,':p',0,8,0,0
	dc.b	'9',$d0,0,8,0,0,'9',$d0
	dc.b	0,8,0,0,'9',$d0,0,8
	dc.b	0,0,'9',$d0,0,8,0,0
	dc.b	'90',0,$10,0,0,'90'
	dc.b	0,$10,0,0,'90',0,$10
	dc.b	0,0,'8',$90,0,$10,0,0
	dc.b	'8',$90,0,$10,0,0,'8',$90
	dc.b	0,$10,0,0,'8',$90,0,$10
	dc.b	0,0,'7',$f0,0,$10,0,0
	dc.b	'7',$f0,0,$10,0,0,'7',$f0
	dc.b	0,$10,0,0,'7P',0,$10
	dc.b	0,0,'7P',0,$10,0,0
	dc.b	'7P',0,$10,0,0,'7P'
	dc.b	0,$10,0,0,'6',$b0,0,$10
	dc.b	0,0,'6',$b0,0,$10,0,0
	dc.b	'6',$b0,0,$10,0,0,'6',$10
	dc.b	0,$10,0,0,'6',$10,0,0
	dc.b	0,$10,'6',$10,0,0,0,$10
	dc.b	'5p',0,0,0,' 5p'
	dc.b	0,0,0,' 5p',0,0
	dc.b	0,' 4',$d0,0,0,0,' '
	dc.b	'4',$d0,0,0,0,' 4',$d0
	dc.b	0,0,0,' 40',0,0
	dc.b	0,' 40',0,0,0,' '
	dc.b	'3',$90,0,0,0,' 3',$90
	dc.b	0,0,0,'@3',$90,0,0
	dc.b	0,'@2',$f0,0,0,0,'@'
	dc.b	'2',$f0,0,0,0,'@2P'
	dc.b	0,0,0,'@2P',0,0
	dc.b	0,'@2P',0,0,0,$80
	dc.b	'1',$b0,0,0,0,$80,'1',$b0
	dc.b	0,0,0,$80,'1',$10,0,0
	dc.b	0,$80,'1',$10,0,0,0,$80
	dc.b	'0p',0,0,1,0,'0p'
	dc.b	0,0,1,0,'/',$d0,0,0
	dc.b	1,0,'/',$d0,0,0,1,0
	dc.b	'/0',0,0,2,0,'/0'
	dc.b	0,0,2,0,'.',$90,0,0
	dc.b	2,0,'.',$90,0,0,2,0
	dc.b	'-',$f0,0,0,4,0,'-',$f0
	dc.b	0,0,4,0,'-P',0,0
	dc.b	4,0,'-P',0,0,8,0
	dc.b	',',$b0,0,0,8,0,',',$b0
	dc.b	0,0,$10,0,',',$10,0,0
	dc.b	$10,0,'+p',0,0,$10,0
	dc.b	'+p',0,0,' ',0,'*',$d0
	dc.b	0,0,' ',0,'*0@',0
	dc.b	'@',0,'*0@',0,'@',0
	dc.b	')',$90,$80,0,$80,0,'(',$f0
	dc.b	$80,0,$80,0,'(H',0,1
	dc.b	0,1,$27,$a8,0,1,0,1
	dc.b	$27,$a8,0,2,0,2,$27,8
	dc.b	0,2,0,2,'&h',0,4
	dc.b	0,4,'%',$c8,0,8,0,8
	dc.b	'%(',0,$10,0,$10,'$',$88
	dc.b	0,$10,0,$10,'#',$e8,0,' '
	dc.b	0,' "',$a8,0,'@',0,'@'
	dc.b	'"',8,0,$80,0,$80,'!h'
	dc.b	1,0,1,0,' ',$c8,2,0
	dc.b	2,0,$1f,$88,4,0,4,0
	dc.b	$1e,$e8,8,0,8,0,$1d,$a8
	dc.b	$10,0,$10,0,$1c,'h@',0
	dc.b	'@',0,$1b,$c8,$80,0,$80,0
	dc.b	$1a,$80,0,2,0,2,$19,'@'
	dc.b	0,4,0,4,$17,'`',0,$10
	dc.b	0,$10,$16,' ',0,'@',0,'@'
	dc.b	$14,'@',1,0,1,0,$12,'`'
	dc.b	4,0,4,0,$10,$80,' ',0
	dc.b	' ',0,$e,$98,0,1,0,1
	dc.b	$c,$18,0,8,0,8,9,$98
	dc.b	0,'@',0,'@',6,'x',4,0
	dc.b	4,0,2,$b8,$80,0,$80,0
	dc.b	$ff,$ff,'L',$90,0,'@',0,0
	dc.b	'L',$90,0,' ',0,0,'M0'
	dc.b	0,' ',0,0,'M0',0,$10
	dc.b	0,0,'M0',0,8,0,0
	dc.b	'M0',0,8,0,0,'M0'
	dc.b	0,4,0,0,'M0',0,4
	dc.b	0,0,'M',$d0,0,2,0,0
	dc.b	'M',$d0,0,2,0,0,'M',$d0
	dc.b	0,1,0,0,'M',$d8,$80,0
	dc.b	0,0,'M',$d8,$80,0,0,0
	dc.b	'M',$d8,'@',0,0,0,'M',$d8
	dc.b	' ',0,0,0,'Nx ',0
	dc.b	0,0,'Nx',$10,0,0,0
	dc.b	'Nx',8,0,0,0,'Nx'
	dc.b	4,0,0,0,'Nx',2,0
	dc.b	0,0,'Nx',2,0,0,0
	dc.b	'Nx',1,0,0,0,'O',$18
	dc.b	0,$80,0,0,'O',$18,0,'@'
	dc.b	0,0,'O',$18,0,' ',0,0
	dc.b	'O',$18,0,$10,0,0,'O',$18
	dc.b	0,8,0,0,'O',$18,0,4
	dc.b	0,0,'O',$18,0,2,0,0
	dc.b	'O',$18,0,1,0,0,'O',$c0
	dc.b	$80,0,0,0,'O',$c0,' ',0
	dc.b	0,0,'O',$c0,$10,0,0,0
	dc.b	'O',$c0,8,0,0,0,'O',$c0
	dc.b	2,0,0,0,'O',$c0,1,0
	dc.b	0,0,'O',$c0,0,0,0,'@'
	dc.b	'O',$c0,0,0,0,' P`'
	dc.b	0,0,0,8,'P`',0,0
	dc.b	0,2,'Ph',0,0,$80,0
	dc.b	'Ph',0,0,' ',0,'Ph'
	dc.b	0,0,8,0,'Ph',0,0
	dc.b	2,0,'Ph',0,0,0,$80
	dc.b	'Ph',0,0,0,$10,'Q',8
	dc.b	0,0,0,2,'Q',$10,0,0
	dc.b	'@',0,'Q',$10,0,0,8,0
	dc.b	'Q',$10,0,0,1,0,'Q',$10
	dc.b	0,0,0,$10,'Q',$10,0,0
	dc.b	0,1,'Q',$18,0,0,$10,0
	dc.b	'Q',$b8,0,0,0,$80,'Q',$b8
	dc.b	0,0,0,2,'Q',$c0,0,0
	dc.b	$10,0,'Q',$c0,0,0,0,' '
	dc.b	'Q',$c8,0,0,' ',0,'Rh'
	dc.b	0,0,0,' Rp',0,0
	dc.b	8,0,'Rp',0,0,0,1
	dc.b	'S',$18,0,0,0,4,$ff,$ff
	dc.b	'AX',$10,0,0,0,'AX'
	dc.b	$10,0,0,0,'AX',8,0
	dc.b	0,0,'@',$b8,8,0,0,0
	dc.b	'@',$b8,8,0,0,0,'@',$b8
	dc.b	4,0,0,0,'@',$b8,4,0
	dc.b	0,0,'@',$18,2,0,0,0
	dc.b	'@',$18,2,0,0,0,'@',$18
	dc.b	1,0,0,0,'?x',1,0
	dc.b	0,0,'?x',0,$80,0,0
	dc.b	'?x',0,$80,0,0,'>',$d8
	dc.b	0,'@',0,0,'>',$d8,0,' '
	dc.b	0,0,'>8',0,' ',0,0
	dc.b	'>8',0,$10,0,0,'>8'
	dc.b	0,8,0,0,'=',$98,0,8
	dc.b	0,0,'=',$98,0,4,0,0
	dc.b	'<',$f8,0,2,0,0,'<',$f8
	dc.b	0,1,0,0,'<X',0,1
	dc.b	0,0,';',$c0,$80,0,0,0
	dc.b	';',$c0,'@',0,0,0,'; '
	dc.b	' ',0,0,0,':',$80,$10,0
	dc.b	0,0,'9',$e0,8,0,0,0
	dc.b	'9',$e0,4,0,0,0,'9@'
	dc.b	2,0,0,0,'8',$a0,0,$80
	dc.b	0,0,'8',0,0,'@',0,0
	dc.b	'7`',0,$10,0,0,'6 '
	dc.b	0,8,0,0,'5',$80,0,2
	dc.b	0,0,'4',$e8,$80,0,0,0
	dc.b	'3',$a8,0,0,' ',0,'3',8
	dc.b	0,0,8,0,'1',$c8,0,0
	dc.b	2,0,'0',$88,0,0,0,'@'
	dc.b	'.',$a8,0,0,0,8,'-h'
	dc.b	0,0,0,1,'+',$90,0,0
	dc.b	$10,0,')',$b0,0,0,1,0
	dc.b	$27,'0',0,0,0,$10,'$',$b8
	dc.b	0,0,'@',0,'!',$98,0,0
	dc.b	1,0,$1d,$d8,0,0,0,1
	dc.b	$18,$e0,0,0,0,$80,$13,'H'
	dc.b	0,0,8,0,$c,'p',0,0
	dc.b	' ',0,3,$18,0,0,4,0
	dc.b	$ff,$ff,'P',$f8,$80,0,0,0
	dc.b	'P',$f8,$80,0,0,0,'Q',$98
	dc.b	'@',0,0,0,'Q',$98,' ',0
	dc.b	0,0,'Q',$98,' ',0,0,0
	dc.b	'Q',$98,$10,0,0,0,'Q',$98
	dc.b	8,0,0,0,'Q',$98,4,0
	dc.b	0,0,'Q',$98,4,0,0,0
	dc.b	'Q',$98,2,0,0,0,'R8'
	dc.b	1,0,0,0,'R8',0,$80
	dc.b	0,0,'R8',0,'@',0,0
	dc.b	'R8',0,' ',0,0,'R8'
	dc.b	0,$10,0,0,'R8',0,8
	dc.b	0,0,'R8',0,4,0,0
	dc.b	'R8',0,2,0,0,'R8'
	dc.b	0,1,0,0,'R@',$80,0
	dc.b	0,0,'R@@',0,0,0
	dc.b	'R@ ',0,0,0,'R@'
	dc.b	$10,0,0,0,'R@',8,0
	dc.b	0,0,'R@',4,0,0,0
	dc.b	'R@',1,0,0,0,'R',$e0
	dc.b	0,$80,0,0,'R',$e0,0,'@'
	dc.b	0,0,'R',$e0,0,$10,0,0
	dc.b	'R@',0,8,0,0,'R@'
	dc.b	0,2,0,0,'R@',0,1
	dc.b	0,0,'RH@',0,0,0
	dc.b	'RH ',0,0,0,'RH'
	dc.b	8,0,0,0,'RH',2,0
	dc.b	0,0,'RH',0,0,0,$80
	dc.b	'RH',0,0,0,' RH'
	dc.b	0,0,0,8,'RH',0,0
	dc.b	0,2,'RP',0,0,$80,0
	dc.b	'RP',0,0,' ',0,'Q',$b0
	dc.b	0,0,4,0,'Q',$b0,0,0
	dc.b	1,0,'Q',$b0,0,0,0,' '
	dc.b	'Q',$b0,0,0,0,4,'Q',$18
	dc.b	0,0,$80,0,'Q',$18,0,0
	dc.b	8,0,'Q',$18,0,0,1,0
	dc.b	'Q',$18,0,0,0,$10,'Px'
	dc.b	0,0,0,1,'P',$80,0,0
	dc.b	$10,0,'O',$e0,0,0,0,$80
	dc.b	'O',$e0,0,0,0,4,'OH'
	dc.b	0,0,' ',0,'OH',0,0
	dc.b	0,$80
	jsr	0(a0)
	dc.b	0,2,'N',$10,0,0,2,0
	dc.b	'Mp',0,0,0,2,'L',$d8
	dc.b	0,0,2,0,$ff,$ff,'J',$18
	dc.b	0,'@',0,0,'J',$18,0,' '
	dc.b	0,0,'J',$18,0,' ',0,0
	dc.b	'J',$18,0,$10,0,0,'J',$18
	dc.b	0,$10,0,0,'J',$18,0,8
	dc.b	0,0,'Ix',0,4,0,0
	dc.b	'Ix',0,4,0,0,'Ix'
	dc.b	0,2,0,0,'Ix',0,1
	dc.b	0,0,'H',$e0,$80,0,0,0
	dc.b	'H',$e0,$80,0,0,0,'H',$e0
	dc.b	'@',0,0,0,'H',$e0,' ',0
	dc.b	0,0,'H@',$10,0,0,0
	dc.b	'H@',$10,0,0,0,'H@'
	dc.b	8,0,0,0,'G',$a0,4,0
	dc.b	0,0,'G',$a0,2,0,0,0
	dc.b	'G',$a0,1,0,0,0,'G',0
	dc.b	0,$80,0,0,'G',0,0,'@'
	dc.b	0,0,'F`',0,'@',0,0
	dc.b	'F`',0,' ',0,0,'E',$c0
	dc.b	0,$10,0,0,'E',$c0,0,8
	dc.b	0,0,'E ',0,4,0,0
	dc.b	'E ',0,2,0,0,'D',$80
	dc.b	0,1,0,0,'D',$88,'@',0
	dc.b	0,0,'C',$e8,' ',0,0,0
	dc.b	'C',$e8,$10,0,0,0,'CH'
	dc.b	8,0,0,0,'B',$a8,4,0
	dc.b	0,0,'B',8,1,0,0,0
	dc.b	'B',8,0,$80,0,0,'Ah'
	dc.b	0,0,0,'@@',$c8,0,0
	dc.b	0,$10,'@(',0,0,0,8
	dc.b	'?',$88,0,0,0,2,'>',$e8
	dc.b	0,0,0,1,'>P',0,0
	dc.b	'@',0,'=',$b0,0,0,$10,0
	dc.b	'=',$10,0,0,4,0,'<p'
	dc.b	0,0,2,0,';',$d0,0,0
	dc.b	0,$80,':',$90,0,0,0,$10
	dc.b	'9',$f0,0,0,0,4,'9P'
	dc.b	0,0,0,1,'8',$18,0,0
	dc.b	' ',0,'6',$d8,0,0,8,0
	dc.b	'5',$98,0,0,1,0,'4',$f8
	dc.b	0,0,0,' 3',$18,0,0
	dc.b	0,4,'1',$e0,0,0,$80,0
	dc.b	'0',$a0,0,0,8,0,'.',$c0
	dc.b	0,0,0,$80,',',$e0,0,0
	dc.b	0,8,'+',8,0,0,'@',0
	dc.b	')(',0,0,2,0,'&',$a8
	dc.b	0,0,0,$10,'$0',0,0
	dc.b	'@',0,'!',$10,0,0,0,$80
	dc.b	$1d,$f0,0,0,0,1,$1a,$d8
	dc.b	0,0,0,$80,$ff,$ff,'.',$98
	dc.b	8,0,0,0,'.',$98,8,0
	dc.b	0,0,'-',$f8,8,0,0,0
	dc.b	'-',$f8,$10,0,0,0,'-X'
	dc.b	$10,0,0,0,',',$b8,$10,0
	dc.b	0,0,',',$b8,$10,0,0,0
	dc.b	',',$18,' ',0,0,0,'+x'
	dc.b	' ',0,0,0,'+x ',0
	dc.b	0,0,'*',$d8,' ',0,0,0
	dc.b	'*8@',0,0,0,'*8'
	dc.b	'@',0,0,0,')',$98,'@',0
	dc.b	0,0,'(',$f8,$80,0,0,0
	dc.b	'(',$f8,$80,0,0,0,'(X'
	dc.b	$80,0,0,0,$27,$b0,0,1
	dc.b	0,0,$27,$b0,0,1,0,0
	dc.b	$27,$10,0,1,0,0,'&p'
	dc.b	0,2,0,0,'%',$d0,0,2
	dc.b	0,0,'%',$d0,0,4,0,0
	dc.b	'%0',0,4,0,0,'$',$90
	dc.b	0,4,0,0,'#',$f0,0,8
	dc.b	0,0,'#P',0,8,0,0
	dc.b	'"',$b0,0,$10,0,0,'"',$b0
	dc.b	0,$10,0,0,'"',$10,0,' '
	dc.b	0,0,'!p',0,'@',0,0
	dc.b	' ',$d0,0,'@',0,0,' 0'
	dc.b	0,$80,0,0,$1f,$90,0,$80
	dc.b	0,0,$1e,$f0,1,0,0,0
	dc.b	$1e,'P',2,0,0,0,$1d,$b0
	dc.b	0,0,2,0,$1d,$10,0,0
	dc.b	4,0,$1c,'p',0,0,8,0
	dc.b	$1b,$d0,0,0,$10,0,$1b,'0'
	dc.b	0,0,$10,0,$1a,$90,0,0
	dc.b	' ',0,$19,$f0,0,0,'@',0
	dc.b	$19,'P',0,0,$80,0,$18,8
	dc.b	0,0,0,1,$17,'h',0,0
	dc.b	0,2,$16,$c8,0,0,0,4
	dc.b	$16,'(',0,0,0,8,$14,$e8
	dc.b	0,0,0,$10,$14,'H',0,0
	dc.b	0,' ',$13,8,0,0,0,$80
	dc.b	$12,'h',0,0,1,0,$11,'('
	dc.b	0,0,2,0,$10,$88,0,0
	dc.b	8,0,$f,'H',0,0,$10,0
	dc.b	$e,8,0,0,'@',0,$d,'h'
	dc.b	0,0,$80,0,$c,' ',0,0
	dc.b	0,2,$a,$e0,0,0,0,8
	dc.b	9,$a0,0,0,0,' ',7,$c0
	dc.b	0,0,0,$80,6,$80,0,0
	dc.b	2,0,5,'@',0,0,8,0
	dc.b	3,'`',0,0,' ',0,2,$18
	dc.b	0,0,0,1,0,'8',0,0
	dc.b	0,8,$ff,$ff,';',$a8,'@',0
	dc.b	0,0,'<H@',0,0,0
	dc.b	'<H@',0,0,0,'<H'
	dc.b	'@',0,0,0,'<H',$80,0
	dc.b	0,0,'<H',$80,0,0,0
	dc.b	'<',$e8,$80,0,0,0,'<',$e8
	dc.b	$80,0,0,0,'<',$e8,$80,0
	dc.b	0,0,'<',$e8,$80,0,0,0
	dc.b	'=',$80,0,1,0,0,'=',$80
	dc.b	0,1,0,0,'=',$80,0,1
	dc.b	0,0,'=',$80,0,1,0,0
	dc.b	'> ',0,1,0,0,'> '
	dc.b	0,1,0,0,'> ',0,1
	dc.b	0,0,'> ',0,2,0,0
	dc.b	'>',$c0,0,2,0,0,'>',$c0
	dc.b	0,2,0,0,'>',$c0,0,2
	dc.b	0,0,'>',$c0,0,2,0,0
	dc.b	'?`',0,2,0,0,'?`'
	dc.b	0,2,0,0,'?`',0,4
	dc.b	0,0,'@',0,0,4,0,0
	dc.b	'@',0,0,4,0,0,'@',0
	dc.b	0,4,0,0,'@',$a0,0,4
	dc.b	0,0,'@',$a0,0,4,0,0
	dc.b	'@',$a0,0,4,0,0,'A@'
	dc.b	0,4,0,0,'A@',0,8
	dc.b	0,0,'A@',0,8,0,0
	dc.b	'A',$e0,0,8,0,0,'A',$e0
	dc.b	0,8,0,0,'A',$e0,0,0
	dc.b	0,8,'B',$80,0,0,0,8
	dc.b	'B',$80,0,0,0,8,'B',$80
	dc.b	0,0,0,8,'C ',0,0
	dc.b	0,8,'C ',0,0,0,8
	dc.b	'C',$c0,0,0,0,$10,'C',$c0
	dc.b	0,0,0,$10,'C',$c0,0,0
	dc.b	0,$10,'D`',0,0,0,$10
	dc.b	'D`',0,0,0,$10,'E',0
	dc.b	0,0,0,$10,'E',0,0,0
	dc.b	0,$10,'E',$a0,0,0,0,$10
	dc.b	'E',$a0,0,0,0,$10,'E',$a0
	dc.b	0,0,0,$10,'F@',0,0
	dc.b	0,$10,'F@',0,0,0,$10
	dc.b	'F',$e0,0,0,0,$10,'F',$e0
	dc.b	0,0,0,$10,'G',$80,0,0
	dc.b	0,$10,'G',$80,0,0,0,$10
	dc.b	'H ',0,0,0,$10,'H '
	dc.b	0,0,0,$10,'H',$c0,0,0
	dc.b	0,$10,'H',$c0,0,0,0,$10
	dc.b	'I`',0,0,0,$10,'J',0
	dc.b	0,0,0,$10,'J',0,0,0
	dc.b	0,$10,'J',$a0,0,0,0,$10
	dc.b	'J',$a0,0,0,0,$10,'K@'
	dc.b	0,0,0,$10,'K',$e0,0,0
	dc.b	0,$10,'K',$e0,0,0,0,$10
	dc.b	'L',$80,0,0,0,$10,'M '
	dc.b	0,0,0,$10,'M ',0,0
	dc.b	0,$10,'M',$c0,0,0,0,$10
	dc.b	'N`',0,0,0,$10,'N`'
	dc.b	0,0,0,$10,'O',0,0,$10
	dc.b	0,$10,'O',$a0,0,$10,0,$10
	dc.b	'P@',0,$10,0,$10,'P',$e0
	dc.b	0,$10,0,$10,'P',$e0,0,$10
	dc.b	0,$10,'Q',$80,0,8,0,8
	dc.b	'R ',0,8,0,8,'R',$c0
	dc.b	0,8,0,8,'S`',0,8
	dc.b	0,8,'T',0,0,8,0,8
	dc.b	'T',$a0,0,8,0,8,'U@'
	dc.b	0,8,0,8
	scs	-(a0)
	ori.b	#4,d4
	addq.l	#3,d0
	ori.b	#4,d4
	subq.b	#3,-(a0)
	ori.b	#4,d4
	seq	d0
	ori.b	#4,d4
	subq.b	#4,d0
	ori.b	#2,d2
	subq.l	#4,-(a0)
	ori.b	#2,d2
	addq.w	#5,d0
	ori.b	#2,d2
	spl	-(a0)
	ori.b	#2,d2
	addq.b	#6,-(a0)
	ori.b	#1,d1
	sge	d0
	ori.b	#1,d1
	addq.b	#7,d0
	ori.b	#1,d1
	addq.l	#7,-32768(a0)
	or.b	d0,d0
	sle	-32768(a0)
	or.b	d0,d0
	bsr.s	.l009b
	dc.b	'@',0,'@',0,'bh@',0
	dc.b	'@',0,'c',8,' ',0,' ',0
	dc.b	'dH ',0,' ',0,'f('
	dc.b	$10,0,$10,0,'gh',$10,0
	dc.b	$10,0,'h',$a8,8,0,8,0
.l009b:	dc.b	'j',$88,4,0,4,0,'k',$c8
	dc.b	2,0,2,0,'m',$a8,2,0
	dc.b	2,0,'o',$88,1,0,1,0
	dc.b	'r',8,0,$80,0,$80,'s',$e8
	dc.b	0,'@',0,'@vh',0,' '
	dc.b	0,' x',$e8,0,8,0,8
	dc.b	'|',8,0,4,0,4,$ff,$ff
	dc.b	'>8',$80,0,0,0,'>8'
	dc.b	$80,0,0,0,'=',$98,'@',0
	dc.b	0,0,'=',$98,'@',0,0,0
	dc.b	'=',$98,'@',0,0,0,'<',$f8
	dc.b	'@',0,0,0,'<',$f8,'@',0
	dc.b	0,0,'<',$f8,'@',0,0,0
	dc.b	'<',$f8,'@',0,0,0,'<X'
	dc.b	'@',0,0,0,'<X@',0
	dc.b	0,0,'<X@',0,0,0
	dc.b	';',$b8,'@',0,0,0,';',$b8
	dc.b	'@',0,0,0,';',$b8,' ',0
	dc.b	0,0,';',$18,' ',0,0,0
	dc.b	';',$18,' ',0,0,0,';',$18
	dc.b	' ',0,0,0,':x ',0
	dc.b	0,0,':x ',0,0,0
	dc.b	':x ',0,0,0,'9',$d8
	dc.b	' ',0,0,0,'9',$d8,' ',0
	dc.b	0,0,'9',$d8,' ',0,0,0
	dc.b	'98 ',0,0,0,'98'
	dc.b	' ',0,0,0,'98 ',0
	dc.b	0,0,'8',$98,' ',0,0,0
	dc.b	'8',$98,' ',0,0,0,'7',$f8
	dc.b	' ',0,0,0,'7',$f8,' ',0
	dc.b	0,0,'7',$f8,' ',0,0,0
	dc.b	'7X ',0,0,0,'7X'
	dc.b	' ',0,0,0,'6',$b8,' ',0
	dc.b	0,0,'6',$b8,' ',0,0,0
	dc.b	'6',$b8,0,0,' ',0,'6',$18
	dc.b	0,0,' ',0,'6',$18,0,0
	dc.b	' ',0,'5x',0,0,' ',0
	dc.b	'5x',0,0,' ',0,'5x'
	dc.b	0,0,' ',0,'4',$d8,0,0
	dc.b	' ',0,'4',$d8,0,0,' ',0
	dc.b	'48',0,0,' ',0,'48'
	dc.b	0,0,'@',0,'3',$98,0,0
	dc.b	'@',0,'3',$98,0,0,'@',0
	dc.b	'2',$f8,0,0,'@',0,'2',$f8
	dc.b	0,0,'@',0,'2X',0,0
	dc.b	'@',0,'2X',0,0,'@',0
	dc.b	'1',$b8,0,0,'@',0,'1',$b8
	dc.b	0,0,'@',0,'1',$18,0,0
	dc.b	'@',0,'1',$18,0,0,$80,0
	dc.b	'0x',0,0,$80,0,'0x'
	dc.b	0,0,$80,0,'/',$d8,0,0
	dc.b	$80,0,'/',$d8,0,0,$80,0
	dc.b	'/8',0,0,$80,0,'/0'
	dc.b	0,0,0,1,'.',$90,0,0
	dc.b	0,1,'.',$90,0,0,0,1
	dc.b	'-',$f0,0,0,0,1,'-',$f0
	dc.b	0,0,0,2,'-P',0,0
	dc.b	0,2,',',$b0,0,0,0,2
	dc.b	',',$b0,0,0,0,2,',',$10
	dc.b	0,0,0,4,',',$10,0,0
	dc.b	0,4,'+p',0,0,0,4
	dc.b	'*',$d0,0,0,0,4,'*',$d0
	dc.b	0,0,0,8,'*0',0,0
	dc.b	0,8,')',$90,0,0,0,8
	dc.b	')',$90,0,$10,0,$10,'(',$f0
	dc.b	0,$10,0,$10,'(P',0,$10
	dc.b	0,$10,$27,$b0,0,' ',0,' '
	dc.b	$27,$b0,0,' ',0,' ',$27,$10
	dc.b	0,'@',0,'@&p',0,'@'
	dc.b	0,'@%',$d0,0,$80,0,$80
	dc.b	'%',$d0,0,$80,0,$80,'%0'
	dc.b	1,0,1,0,'$',$90,1,0
	dc.b	1,0,'#',$f0,2,0,2,0
	dc.b	'#P',2,0,2,0,'"',$b0
	dc.b	4,0,4,0,'"',$10,4,0
	dc.b	4,0,'!p',8,0,8,0
	dc.b	'!p',$10,0,$10,0,' ',$d0
	dc.b	$10,0,$10,0,$1f,$90,' ',0
	dc.b	' ',0,$1e,$f0,'@',0,'@',0
	dc.b	$1e,'P@',0,'@',0,$1d,$b0
	dc.b	$80,0,$80,0,$1d,8,0,1
	dc.b	0,1,$1c,'h',0,2,0,2
	dc.b	$1b,$c8,0,4,0,4,$1a,$88
	dc.b	0,8,0,8,$19,$e8,0,$10
	dc.b	0,$10,$19,'H',0,' ',0,' '
	dc.b	$18,8,0,'@',0,'@',$17,'h'
	dc.b	0,$80,0,$80,$16,'(',1,0
	dc.b	1,0,$14,$e8,4,0,4,0
	dc.b	$14,'H',8,0,8,0,$13,8
	dc.b	$10,0,$10,0,$11,$c8,'@',0
	dc.b	'@',0,$10,$80,0,1,0,1
	dc.b	$f,'@',0,2,0,2,$e,0
	dc.b	0,8,0,8,$c,' ',0,' '
	dc.b	0,' ',$a,$e0,0,$80,0,$80
	dc.b	9,0,2,0,2,0,7,' '
	dc.b	$10,0,$10,0,5,'@@',0
	dc.b	'@',0,3,'X',0,2,0,2
	dc.b	1,'x',0,$10,0,$10,$ff,$ff
	dc.b	'F',$f0,0,1,0,0,'F',$f8
	dc.b	$80,0,0,0,'F',$f8,$80,0
	dc.b	0,0,'F',$f8,'@',0,0,0
	dc.b	'FX@',0,0,0,'FX'
	dc.b	'@',0,0,0,'FX ',0
	dc.b	0,0,'FX ',0,0,0
	dc.b	'FX',$10,0,0,0,'FX'
	dc.b	$10,0,0,0,'E',$b8,$10,0
	dc.b	0,0,'E',$b8,8,0,0,0
	dc.b	'E',$b8,8,0,0,0,'E',$b8
	dc.b	4,0,0,0,'E',$b8,4,0
	dc.b	0,0,'E',$b8,2,0,0,0
	dc.b	'E',$18,2,0,0,0,'E',$18
	dc.b	2,0,0,0,'E',$18,1,0
	dc.b	0,0,'E',$18,1,0,0,0
	dc.b	'Dx',0,$80,0,0,'Dx'
	dc.b	0,$80,0,0,'Dx',0,'@'
	dc.b	0,0,'Dx',0,'@',0,0
	dc.b	'C',$d8,0,' ',0,0,'C',$d8
	dc.b	0,' ',0,0,'C',$d8,0,$10
	dc.b	0,0,'C8',0,$10,0,0
	dc.b	'C8',0,8,0,0,'C8'
	dc.b	0,8,0,0,'B',$98,0,4
	dc.b	0,0,'B',$98,0,2,0,0
	dc.b	'B',$98,0,2,0,0,'A',$f8
	dc.b	0,1,0,0,'A',$f8,0,1
	dc.b	0,0,'A`',$80,0,0,0
	dc.b	'A`',0,0,'@',0,'A`'
	dc.b	0,0,'@',0,'@',$c0,0,0
	dc.b	' ',0,'@',$c0,0,0,$10,0
	dc.b	'@ ',0,0,$10,0,'@ '
	dc.b	0,0,8,0,'?',$80,0,0
	dc.b	4,0,'>',$e0,0,0,4,0
	dc.b	'>',$e0,0,0,2,0,'>@'
	dc.b	0,0,1,0,'>@',0,0
	dc.b	0,$80,'=',$a0,0,0,0,$80
	dc.b	'=',0,0,0,0,'@<`'
	dc.b	0,0,0,' <`',0,0
	dc.b	0,$10,';',$c0,0,0,0,8
	dc.b	'; ',0,0,0,4,':',$80
	dc.b	0,0,0,2,'9',$e0,0,0
	dc.b	0,1,'9H',0,0,$80,0
	dc.b	'8',$a8,0,0,'@',0,'8',8
	dc.b	0,0,' ',0,'7h',0,0
	dc.b	$10,0,'6',$c8,0,0,4,0
	dc.b	'6(',0,0,2,0,'5',$88
	dc.b	0,0,1,0,'4H',0,0
	dc.b	0,'@3',$a8,0,0,0,' '
	dc.b	'2h',0,0,0,8,'1',$c8
	dc.b	0,0,0,2,'0',$88,0,0
	dc.b	0,1,'/P',0,0,'@',0
	dc.b	'.',$10,0,0,$10,0,',',$d0
	dc.b	0,0,4,0,'+',$90,0,0
	dc.b	0,$80,'*P',0,0,0,' '
	dc.b	'(p',0,0,0,4,'&',$98
	dc.b	0,0,$80,0,'$',$b8,0,0
	dc.b	$10,0,'"8',0,0,2,0
	dc.b	' X',0,' ',0,' ',$1d,'8'
	dc.b	0,2,0,2,$1a,$c0,$10,0
	dc.b	$10,0,$17,$a0,0,$80,0,$80
	dc.b	$13,$e0,0,2,0,2,$f,$88
	dc.b	8,0,8,0,$a,$88,0,8
	dc.b	0,8,5,$90,4,0,4,0
	dc.b	$ff,$ff,'J',$b0,2,0,0,0
	dc.b	'J',$b0,1,0,0,0,'J',$b0
	dc.b	1,0,0,0,'KP',0,$80
	dc.b	0,0,'KP',0,$80,0,0
	dc.b	'KP',0,'@',0,0,'KP'
	dc.b	0,'@',0,0,'KP',0,' '
	dc.b	0,0,'KP',0,' ',0,0
	dc.b	'K',$f0,0,$10,0,0,'K',$f0
	dc.b	0,$10,0,0,'K',$f0,0,8
	dc.b	0,0,'K',$f0,0,8,0,0
	dc.b	'K',$f0,0,4,0,0,'L',$90
	dc.b	0,4,0,0,'L',$90,0,2
	dc.b	0,0,'L',$90,0,1,0,0
	dc.b	'L',$90,0,1,0,0,'L',$98
	dc.b	$80,0,0,0,'M8@',0
	dc.b	0,0,'M8 ',0,0,0
	dc.b	'M8 ',0,0,0,'M8'
	dc.b	$10,0,0,0,'M',$d8,8,0
	dc.b	0,0,'M',$d8,4,0,0,0
	dc.b	'M',$d8,2,0,0,0,'M',$d8
	dc.b	1,0,0,0,'Nx',0,$80
	dc.b	0,0,'Nx',0,'@',0,0
	dc.b	'Nx',0,' ',0,0,'Nx'
	dc.b	0,$10,0,0,'O',$18,0,8
	dc.b	0,0,'O',$18,0,4,0,0
	dc.b	'O',$18,0,1,0,0,'O',$c0
	dc.b	$80,0,0,0,'O',$c0,'@',0
	dc.b	0,0,'O',$c0,0,0,$10,0
	dc.b	'P`',0,0,4,0,'P`'
	dc.b	0,0,2,0,'P`',0,0
	dc.b	0,$80,'Q',0,0,0,0,' '
	dc.b	'Q',0,0,0,0,8,'Q',$a0
	dc.b	0,0,0,1,'Q',$a8,0,0
	dc.b	'@',0,'RH',0,0,8,0
	dc.b	'RH',0,0,1,0,'R',$e8
	dc.b	0,0,0,' S',$88,0,0
	dc.b	0,2,'S',$90,0,0,'@',0
	dc.b	'T0',0,0,2,0,'T',$d0
	dc.b	0,0,0,$10,'Ux',0,0
	dc.b	$80,0,'V',$18,0,0,2,0
	dc.b	'V',$b8,0,0,0,4,'X',0
	dc.b	0,0,4,0,'Y@',0,0
	dc.b	0,1,'Z',$88,0,0,0,' '
	dc.b	'[',$d0,0,0,0,$80,']',$b8
	dc.b	0,0,0,$80,$ff,$ff,'<',$e8
	dc.b	'@',0,0,0,'<',$e8,'@',0
	dc.b	0,0,'<',$e8,'@',0,0,0
	dc.b	'<',$e8,'@',0,0,0,'=',$88
	dc.b	$80,0,0,0,'=',$88,$80,0
	dc.b	0,0,'=',$88,$80,0,0,0
	dc.b	'=',$88,$80,0,0,0,'=',$88
	dc.b	$80,0,0,0,'>(',$80,0
	dc.b	0,0,'> ',0,1,0,0
	dc.b	'> ',0,1,0,0,'> '
	dc.b	0,1,0,0,'>',$c0,0,1
	dc.b	0,0,'>',$c0,0,1,0,0
	dc.b	'>',$c0,0,1,0,0,'>',$c0
	dc.b	0,2,0,0,'?`',0,2
	dc.b	0,0,'?`',0,2,0,0
	dc.b	'?`',0,2,0,0,'@',0
	dc.b	0,2,0,0,'@',0,0,2
	dc.b	0,0,'@',0,0,4,0,0
	dc.b	'@',$a0,0,4,0,0,'@',$a0
	dc.b	0,4,0,0,'@',$a0,0,4
	dc.b	0,0,'A@',0,4,0,0
	dc.b	'A@',0,4,0,0,'A@'
	dc.b	0,8,0,0,'A',$e0,0,8
	dc.b	0,0,'A',$e0,0,8,0,0
	dc.b	'A',$e0,0,8,0,0,'B',$80
	dc.b	0,8,0,0,'B',$80,0,8
	dc.b	0,0,'C ',0,$10,0,0
	dc.b	'C ',0,$10,0,0,'C '
	dc.b	0,0,0,$10,'C',$c0,0,0
	dc.b	0,$10,'C',$c0,0,0,0,$10
	dc.b	'D`',0,0,0,$10,'D`'
	dc.b	0,0,0,$10,'E',0,0,0
	dc.b	0,' E',0,0,0,0,' '
	dc.b	'E',$a0,0,0,0,' E',$a0
	dc.b	0,0,0,' F@',0,0
	dc.b	0,' F@',0,0,0,' '
	dc.b	'F',$e0,0,0,0,' F',$e0
	dc.b	0,0,0,'@G',$80,0,0
	dc.b	0,'@G',$80,0,0,0,'@'
	dc.b	'H ',0,0,0,'@H',$c0
	dc.b	0,0,0,'@H',$c0,0,0
	dc.b	0,'@I`',0,0,0,'@'
	dc.b	'J',0,0,0,0,$80,'J',0
	dc.b	0,0,0,$80,'J',$a0,0,0
	dc.b	0,$80,'K@',0,0,0,$80
	dc.b	'K',$e0,0,0,0,$80,'L',$80
	dc.b	0,0,0,$80,'L',$80,0,0
	dc.b	0,$80,'M ',0,0,1,0
	dc.b	'M',$c0,0,0,1,0,'N`'
	dc.b	0,0,1,0,'O',0,0,0
	dc.b	1,0,'O',$a0,0,0,1,0
	dc.b	'P@',0,0,1,0,'P',$e0
	dc.b	0,0,1,0,'Q',$80,0,0
	dc.b	1,0,'R ',0,0,2,0
	dc.b	'S`',0,0,2,0,'T',0
	dc.b	0,0,2,0,'T',$a0,0,0
	dc.b	2,0,'U',$e0,0,0,2,0
	dc.b	'V',$80,0,0,2,0,'W',$c0
	dc.b	2,0,2,0,'X`',4,0
	dc.b	4,0,'Y',$a0,4,0,4,0
	dc.b	'Z',$e0,4,0,4,0,'\ '
	dc.b	4,0,4,0,']`',4,0
	dc.b	4,0,'^',$a0,4,0,4,0
	dc.b	'`',$80,4,0,4,0,'a',$c0
	dc.b	8,0,8,0,'c',$a0,8,0
	dc.b	8,0,'e',$80,8,0,8,0
	dc.b	'g`',8,0,8,0,'i',$e0
	dc.b	8,0,8,0,'l`',$10,0
	dc.b	$10,0,'n',$e0,$10,0,$10,0
	dc.b	'q`',$10,0,$10,0,'u '
	dc.b	$10,0,$10,0,'x@ ',0
	dc.b	' ',0,'|',$a0,' ',0,' ',0
	dc.b	$ff,$ff,'4',$c0,0,1,0,0
	dc.b	'4',$c0,0,1,0,0,'4',$c0
	dc.b	0,2,0,0,'4',$c0,0,2
	dc.b	0,0,'4',$c0,0,2,0,0
	dc.b	'5`',0,4,0,0,'5`'
	dc.b	0,4,0,0,'5`',0,4
	dc.b	0,0,'5`',0,8,0,0
	dc.b	'5`',0,8,0,0,'6',0
	dc.b	0,8,0,0,'6',0,0,$10
	dc.b	0,0,'6',0,0,$10,0,0
	dc.b	'6',0,0,' ',0,0,'6',$a0
	dc.b	0,' ',0,0,'6',$a0,0,' '
	dc.b	0,0,'6',$a0,0,'@',0,0
	dc.b	'6',$a0,0,'@',0,0,'7@'
	dc.b	0,'@',0,0,'7@',0,$80
	dc.b	0,0,'7@',0,$80,0,0
	dc.b	'7@',0,$80,0,0,'7',$e0
	dc.b	1,0,0,0,'7',$e0,1,0
	dc.b	0,0,'7',$e0,2,0,0,0
	dc.b	'8',$80,2,0,0,0,'8',$80
	dc.b	2,0,0,0,'8',$80,4,0
	dc.b	0,0,'9 ',4,0,0,0
	dc.b	'9 ',4,0,0,0,'9 '
	dc.b	8,0,0,0,'9',$c0,8,0
	dc.b	0,0,'9',$c0,8,0,0,0
	dc.b	'9',$c0,$10,0,0,0,':`'
	dc.b	$10,0,0,0,':` ',0
	dc.b	0,0,';',0,0,0,' ',0
	dc.b	';',0,0,0,' ',0,';',0
	dc.b	0,0,'@',0,';',$a0,0,0
	dc.b	'@',0,';',$a0,0,0,'@',0
	dc.b	'<@',0,0,$80,0,'<@'
	dc.b	0,0,$80,0,'<',$e0,0,0
	dc.b	$80,0,'<',$d8,0,0,0,1
	dc.b	'=x',0,0,0,1,'=x'
	dc.b	0,0,0,1,'>',$18,0,0
	dc.b	0,2,'>',$18,0,0,0,2
	dc.b	'>',$b8,0,0,0,2,'>',$b8
	dc.b	0,0,0,4,'?X',0,0
	dc.b	0,4,'?X',0,0,0,4
	dc.b	'?',$f8,0,0,0,8,'?',$f8
	dc.b	0,0,0,8,'@',$98,0,0
	dc.b	0,8,'A8',0,0,0,$10
	dc.b	'A8',0,0,0,$10,'A',$d8
	dc.b	0,0,0,$10,'Bx',0,0
	dc.b	0,' Bx',0,0,0,' '
	dc.b	'C',$18,0,0,0,' C',$b8
	dc.b	0,0,0,'@C',$b8,0,0
	dc.b	0,'@DX',0,0,0,'@'
	dc.b	'D',$f8,0,0,0,$80,'D',$f8
	dc.b	0,0,0,$80,'E',$98,0,0
	dc.b	0,$80,'F8',0,0,1,0
	dc.b	'F',$d8,0,0,1,0,'Gx'
	dc.b	0,0,1,0,'Gx',0,0
	dc.b	1,0,'H',$18,0,0,2,0
	dc.b	'H',$b8,0,0,2,0,'IX'
	dc.b	0,0,2,0,'I',$f8,0,0
	dc.b	4,0,'J',$98,4,0,4,0
	dc.b	'K8',4,0,4,0,'K',$d8
	dc.b	8,0,8,0,'Lx',8,0
	dc.b	8,0,'M',$18,8,0,8,0
	dc.b	'M',$b8,8,0,8,0
	unlk	a0
	move.b	d0,d0
	move.b	d0,d0
	jmp	$1000.w
	dc.b	$10,0,'O',$98,$10,0,$10,0
	dc.b	'P8',$10,0,$10,0,'P',$d8
	dc.b	' ',0,' ',0,'R',$18,' ',0
	dc.b	' ',0,'R',$b8,' ',0,' ',0
	dc.b	'SX ',0,' ',0
.l009c:	dc.b	'S',$f8,'@',0,'@',0,'U8'
	dc.b	'@',0,'@',0,'U',$d8,'@',0
	dc.b	'@',0,'W',$18,'@',0,'@',0
	dc.b	'W',$b8,$80,0,$80,0,'X',$f8
	dc.b	$80,0,$80,0,'Y',$98,$80,0
	dc.b	$80,0,'Z',$d8,$80,0,$80,0
	dc.b	'\',$10,0,1,0,1,'\',$b0
	dc.b	0,1,0,1,']',$f0,0,1
	dc.b	0,1,'_0',0,1,0,1
	dc.b	'`p',0,2,0,2
	bsr.s	.l009c
	dc.b	0,2,0,2,'b',$f0,0,2
	dc.b	0,2,'d0',0,2,0,2
	dc.b	'ep',0,2,0,2,'gP'
	dc.b	0,4,0,4,'h',$90,0,4
	dc.b	0,4,'jp',0,4,0,4
	dc.b	'k',$b0,0,4,0,4,'m',$90
	dc.b	0,4,0,4,'op',0,8
	dc.b	0,8,'qP',0,8,0,8
	dc.b	's0',0,8,0,8,'u',$b0
	dc.b	0,8,0,8,'w',$90,0,8
	dc.b	0,8,'z',$10,0,$10,0,$10
	dc.b	'|',$90,0,$10,0,$10,$ff,$ff
	dc.b	'F` ',0,0,0,'F`'
	dc.b	$10,0,0,0,'E',$c0,8,0
	dc.b	0,0,'E',$c0,8,0,0,0
	dc.b	'E ',4,0,0,0,'E '
	dc.b	2,0,0,0,'E ',1,0
	dc.b	0,0,'D',$80,0,$80,0,0
	dc.b	'D',$80,0,'@',0,0,'C',$e0
	dc.b	0,'@',0,0,'C',$e0,0,' '
	dc.b	0,0,'C@',0,$10,0,0
	dc.b	'C@',0,8,0,0,'B',$a0
	dc.b	0,4,0,0,'B',0,0,2
	dc.b	0,0,'B',0,0,1,0,0
	dc.b	'Ah',$80,0,0,0,'@',$c8
	dc.b	'@',0,0,0,'@',$c8,$10,0
	dc.b	0,0,'@(',8,0,0,0
	dc.b	'?',$88,4,0,0,0,'>',$e8
	dc.b	2,0,0,0,'>',$e8,1,0
	dc.b	0,0,'>H',0,'@',0,0
	dc.b	'=',$a8,0,' ',0,0,'=',8
	dc.b	0,8,0,0,'<h',0,4
	dc.b	0,0,';',$c8,0,1,0,0
	dc.b	':',$90,$80,0,0,0,'9',$f0
	dc.b	' ',0,0,0,'9P',8,0
	dc.b	0,0,'8',$b0,2,0,0,0
	dc.b	'7p',0,$80,0,0,'6',$d0
	dc.b	0,' ',0,0,'5',$90,0,8
	dc.b	0,0,'4P',0,2,0,0
	dc.b	'3',$18,0,0,'@',0,'1',$d8
	dc.b	0,0,$10,0,'0',$98,0,0
	dc.b	2,0,'/X',0,0,0,'@'
	dc.b	'.',$18,0,0,0,8,',@'
	dc.b	0,0,$80,0,'*`',0,0
	dc.b	$10,0,'(',$80,0,0,1,0
	dc.b	'&',$a0,0,0,0,8,'$('
	dc.b	0,0,'@',0,'!',$a8,0,0
	dc.b	2,0,$1e,$88,0,0,0,8
	dc.b	$1b,'p',0,0,$10,0,$17,$b0
	dc.b	0,0,0,' ',$13,$f8,0,0
	dc.b	' ',0,$e,$f8,0,0,0,8
	dc.b	$ff,$ff,'8',$90,0,'@',0,0
	dc.b	'8',$90,0,'@',0,0,'8',$90
	dc.b	0,'@',0,0,'7',$f0,0,'@'
	dc.b	0,0,'7',$f0,0,'@',0,0
	dc.b	'7',$f0,0,$80,0,0,'7',$f0
	dc.b	0,$80,0,0,'7P',0,$80
	dc.b	0,0,'7P',0,$80,0,0
	dc.b	'7P',0,$80,0,0,'7P'
	dc.b	0,$80,0,0,'7P',0,$80
	dc.b	0,0,'6',$b0,0,$80,0,0
	dc.b	'6',$b0,0,$80,0,0,'6',$b0
	dc.b	1,0,0,0,'6',$b0,1,0
	dc.b	0,0,'6',$10,1,0,0,0
	dc.b	'6',$10,1,0,0,0,'6',$10
	dc.b	1,0,0,0,'6',$10,1,0
	dc.b	0,0,'6',$10,1,0,0,0
	dc.b	'5p',2,0,0,0,'5p'
	dc.b	2,0,0,0,'5p',2,0
	dc.b	0,0,'5p',2,0,0,0
	dc.b	'4',$d0,2,0,0,0,'4',$d0
	dc.b	4,0,0,0,'4',$d0,4,0
	dc.b	0,0,'4',$d0,4,0,0,0
	dc.b	'40',4,0,0,0,'40'
	dc.b	4,0,0,0,'40',8,0
	dc.b	0,0,'40',8,0,0,0
	dc.b	'40',8,0,0,0,'3',$90
	dc.b	8,0,0,0,'3',$90,8,0
	dc.b	0,0,'3',$90,0,0,$10,0
	dc.b	'3',$90,0,0,$10,0,'2',$f0
	dc.b	0,0,$10,0,'2',$f0,0,0
	dc.b	$10,0,'2',$f0,0,0,' ',0
	dc.b	'2',$f0,0,0,' ',0,'2P'
	dc.b	0,0,' ',0,'2P',0,0
	dc.b	' ',0,'2P',0,0,'@',0
	dc.b	'2P',0,0,'@',0,'2P'
	dc.b	0,0,'@',0,'1',$b0,0,0
	dc.b	$80,0,'1',$b0,0,0,$80,0
	dc.b	'1',$b0,0,0,$80,0,'1',$a8
	dc.b	0,0,0,1,'1',8,0,0
	dc.b	0,1,'1',8,0,0,0,1
	dc.b	'1',8,0,0,0,2,'1',8
	dc.b	0,0,0,2,'0h',0,0
	dc.b	0,2,'0h',0,0,0,4
	dc.b	'0h',0,0,0,4,'0h'
	dc.b	0,0,0,8,'/',$c8,0,0
	dc.b	0,8,'/',$c8,0,0,0,8
	dc.b	'/',$c8,0,0,0,$10,'/',$c8
	dc.b	0,0,0,$10,'/(',0,0
	dc.b	0,' /(',0,0,0,' '
	dc.b	'/(',0,0,0,'@/('
	dc.b	0,0,0,'@.',$88,0,0
	dc.b	0,'@.',$88,0,0,0,$80
	dc.b	'.',$88,0,0,1,0,'.',$88
	dc.b	0,0,1,0,'.',$88,0,0
	dc.b	2,0,'-',$e8,0,0,2,0
	dc.b	'-',$e8,0,0,4,0,'-',$e8
	dc.b	0,0,4,0,'-',$e8,0,0
	dc.b	8,0,'-H',8,0,8,0
	dc.b	'-H',$10,0,$10,0,'-H'
	dc.b	' ',0,' ',0,'-H ',0
	dc.b	' ',0,',',$a8,'@',0,'@',0
	dc.b	',',$a8,$80,0,$80,0,',',$a0
	dc.b	0,1,0,1,',',0,0,1
	dc.b	0,1,',',0,0,2,0,2
	dc.b	',',0,0,4,0,4,',',0
	dc.b	0,8,0,8,'+`',0,$10
	dc.b	0,$10,'+`',0,$10,0,$10
	dc.b	'+`',0,' ',0,' +`'
	dc.b	0,'@',0,'@*',$c0,0,$80
	dc.b	0,$80,'*',$c0,1,0,1,0
	dc.b	'*',$c0,2,0,2,0,'* '
	dc.b	4,0,4,0,'* ',$10,0
	dc.b	$10,0,'*  ',0,' ',0
	dc.b	')',$80,'@',0,'@',0,')',$80
	dc.b	$80,0,$80,0,')x',0,2
	dc.b	0,2,'(',$d8,0,4,0,4
	dc.b	'(',$d8,0,$10,0,$10,'(',$d8
	dc.b	0,' ',0,' (8',0,$80
	dc.b	0,$80,'(8',2,0,2,0
	dc.b	$27,$98,4,0,4,0,$27,$98
	dc.b	$10,0,$10,0,'&',$f8,'@',0
	dc.b	'@',0,'&',$f0,0,1,0,1
	dc.b	'&P',0,8,0,8,'&P'
	dc.b	0,' ',0,' %',$b0,1,0
	dc.b	1,0,'%',$b0,8,0,8,0
	dc.b	'%',$10,'@',0,'@',0,'$h'
	dc.b	0,2,0,2,'$h',0,' '
	dc.b	0,' #',$c8,1,0,1,0
	dc.b	'#( ',0,' ',0,'"',$80
	dc.b	0,2,0,2,'!',$e0,0,'@'
	dc.b	0,'@!@',$10,0,$10,0
	dc.b	' ',$98,0,4,0,4,$1f,$f8
	dc.b	2,0,2,0,$1e,$b0,0,2
	dc.b	0,2,$1d,'p',4,0,4,0
	dc.b	$1c,'(',0,' ',0,' ',$1a,$e0
	dc.b	0,2,0,2,$19,0,$80,0
	dc.b	$80,0,$ff,$ff,'A`',0,' '
	dc.b	0,0,'@',$c0,0,$10,0,0
	dc.b	'@',$c0,0,$10,0,0,'@ '
	dc.b	0,8,0,0,'?',$80,0,4
	dc.b	0,0,'?',$80,0,2,0,0
	dc.b	'>',$e0,0,2,0,0,'>@'
	dc.b	0,1,0,0,'=',$a8,$80,0
	dc.b	0,0,'=',$a8,$80,0,0,0
	dc.b	'=',8,'@',0,0,0,'<h'
	dc.b	' ',0,0,0,';',$c8,$10,0
	dc.b	0,0,';(',$10,0,0,0
	dc.b	':',$88,8,0,0,0,'9',$e8
	dc.b	4,0,0,0,'9H',2,0
	dc.b	0,0,'8',$a8,2,0,0,0
	dc.b	'8',8,1,0,0,0,'7h'
	dc.b	0,$80,0,0,'6',$c8,0,'@'
	dc.b	0,0,'6(',0,' ',0,0
	dc.b	'5',$88,0,$10,0,0,'4',$e8
	dc.b	0,8,0,0,'3',$a8,0,4
	dc.b	0,0,'3',8,0,2,0,0
	dc.b	'2h',0,1,0,0,'10'
	dc.b	$80,0,0,0,'0',$90,'@',0
	dc.b	0,0,'/P ',0,0,0
	dc.b	'.',$b0,$10,0,0,0,'-p'
	dc.b	8,0,0,0,',0',4,0
	dc.b	0,0,'*',$f0,1,0,0,0
	dc.b	')',$b0,0,$80,0,0,'(p'
	dc.b	0,'@',0,0,$27,'0',0,0
	dc.b	0,' %',$f0,0,0,0,8
	dc.b	'$',$b0,0,0,0,4,'"',$d0
	dc.b	0,0,0,1,'!',$98,0,0
	dc.b	'@',0,$1f,$b8,0,0,' ',0
	dc.b	$1d,$d8,0,0,8,0,$1b,$f8
	dc.b	0,0,2,0,$1a,$18,0,0
	dc.b	0,$80,$17,$98,0,0,0,' '
	dc.b	$15,$18,0,0,0,8,$12,$98
	dc.b	0,0,0,1,$10,' ',0,0
	dc.b	'@',0,$d,$a0,0,0,8,0
	dc.b	$a,$80,0,0,1,0,6,$c0
	dc.b	0,0,0,' ',3,0,0,0
	dc.b	0,4,$ff,$ff,'6',$a8,2,0
	dc.b	0,0,'6',$a8,2,0,0,0
	dc.b	'6',$a8,4,0,0,0,'6',$a8
	dc.b	4,0,0,0,'6',$a8,4,0
	dc.b	0,0,'6',$a8,8,0,0,0
	dc.b	'6',$a8,8,0,0,0,'6',$a8
	dc.b	8,0,0,0,'6',$a8,$10,0
	dc.b	0,0,'6',$a8,$10,0,0,0
	dc.b	'6',$a8,' ',0,0,0,'6',$a8
	dc.b	' ',0,0,0,'6',$a8,' ',0
	dc.b	0,0,'6',$a8,'@',0,0,0
	dc.b	'6',$a8,'@',0,0,0,'6',$a8
	dc.b	$80,0,0,0,'6',$a8,$80,0
	dc.b	0,0,'6',$a0,0,1,0,0
	dc.b	'6',$a0,0,1,0,0,'6',$a0
	dc.b	0,2,0,0,'6',$a0,0,2
	dc.b	0,0,'6',$a0,0,4,0,0
	dc.b	'6',$a0,0,8,0,0,'6',$a0
	dc.b	0,8,0,0,'6',$a0,0,$10
	dc.b	0,0,'6',$a0,0,$10,0,0
	dc.b	'6',$a0,0,' ',0,0,'6',$a0
	dc.b	0,'@',0,0,'6',$a0,0,'@'
	dc.b	0,0,'6',$a0,0,$80,0,0
	dc.b	'6',$a0,1,0,0,0,'7@'
	dc.b	2,0,0,0,'7@',4,0
	dc.b	0,0,'7@',4,0,0,0
	dc.b	'7@',8,0,0,0,'7@'
	dc.b	$10,0,0,0,'7@',0,0
	dc.b	' ',0,'7@',0,0,'@',0
	dc.b	'7@',0,0,$80,0,'7',$d8
	dc.b	0,0,0,2,'7',$d8,0,0
	dc.b	0,4,'7',$d8,0,0,0,8
	dc.b	'7',$d8,0,0,0,' 8x'
	dc.b	0,0,0,'@8x',0,0
	dc.b	1,0,'8x',0,0,2,0
	dc.b	'8x',0,0,8,0,'9',$18
	dc.b	0,0,' ',0,'9',$18,0,0
	dc.b	$80,0,'9',$10,0,0,0,4
	dc.b	'9',$b0,0,0,0,$10,'9',$b0
	dc.b	0,0,0,$80,':P',0,0
	dc.b	4,0,':',$f0,0,0,' ',0
	dc.b	':',$e8,0,0,0,2,';',$88
	dc.b	0,0,0,' <(',0,0
	dc.b	4,0,'<',$c8,0,0,$80,0
	dc.b	'=`',0,0,0,' >',0
	dc.b	0,0,' ',0,'?8',0,0
	dc.b	0,' @x',0,0,$80,0
	dc.b	'A',$b0,0,0,$10,0,'C',$88
	dc.b	0,0,8,0,'F',0,0,0
	dc.b	$80,0,$ff,$ff,'1',$a8,$80,0
	dc.b	0,0,'1',0,0,1,0,0
	dc.b	'1',0,0,2,0,0,'1',0
	dc.b	0,2,0,0,'1',0,0,4
	dc.b	0,0,'1',0,0,8,0,0
	dc.b	'1',0,0,8,0,0,'1',0
	dc.b	0,$10,0,0,'1',0,0,' '
	dc.b	0,0,'1',0,0,' ',0,0
	dc.b	'1',0,0,'@',0,0,'1',0
	dc.b	0,$80,0,0,'1',0,1,0
	dc.b	0,0,'1',0,1,0,0,0
	dc.b	'1',0,2,0,0,0,'1',0
	dc.b	4,0,0,0,'1',0,8,0
	dc.b	0,0,'1',0,$10,0,0,0
	dc.b	'1',0,' ',0,0,0,'1',0
	dc.b	'@',0,0,0,'1',0,$80,0
	dc.b	0,0,'0',$f8,0,1,0,0
	dc.b	'0',$f8,0,2,0,0,'0',$f8
	dc.b	0,4,0,0,'0',$f8,0,8
	dc.b	0,0,'0',$f8,0,' ',0,0
	dc.b	'0',$f8,0,'@',0,0,'0',$f8
	dc.b	0,$80,0,0,'0',$f8,2,0
	dc.b	0,0,'0',$f8,4,0,0,0
	dc.b	'0',$f8,$10,0,0,0,'0',$f8
	dc.b	' ',0,0,0,'0',$f8,$80,0
	dc.b	0,0,'0',$f0,0,2,0,0
	dc.b	'1',$90,0,8,0,0,'1',$90
	dc.b	0,' ',0,0,'1',$90,0,0
	dc.b	0,$80,'1',$90,0,0,2,0
	dc.b	'1',$90,0,0,$10,0,'1',$90
	dc.b	0,0,'@',0,'2(',0,0
	dc.b	0,2,'2(',0,0,0,$10
	dc.b	'2(',0,0,1,0,'2',$c8
	dc.b	0,0,8,0,'2',$c8,0,0
	dc.b	$80,0,'2',$c0,0,0,0,$10
	dc.b	'3`',0,0,1,0,'3`'
	dc.b	0,0,'@',0,'3',$f8,0,0
	dc.b	0,8,'3',$f8,0,0,4,0
	dc.b	'4',$90,0,0,0,2,'50'
	dc.b	0,0,4,0,'5',$c8,0,0
	dc.b	0,$10,'6h',0,0,$80,0
	dc.b	'7',0,0,0,$10,0,$ff,$ff
	dc.b	'@',$a8,2,0,0,0,'@',$a8
	dc.b	2,0,0,0,'@',$a8,4,0
	dc.b	0,0,'@',$a8,4,0,0,0
	dc.b	'@',$a8,4,0,0,0,'AH'
	dc.b	4,0,0,0,'AH',4,0
	dc.b	0,0,'AH',4,0,0,0
	dc.b	'AH',4,0,0,0,'AH'
	dc.b	4,0,0,0,'A',$e8,4,0
	dc.b	0,0,'A',$e8,4,0,0,0
	dc.b	'A',$e8,4,0,0,0,'A',$e8
	dc.b	4,0,0,0,'B',$88,4,0
	dc.b	0,0,'B',$88,4,0,0,0
	dc.b	'B',$88,4,0,0,0,'B',$88
	dc.b	4,0,0,0,'B',$88,4,0
	dc.b	0,0,'C(',4,0,0,0
	dc.b	'C(',4,0,0,0,'C('
	dc.b	4,0,0,0,'C(',4,0
	dc.b	0,0,'C',$c8,4,0,0,0
	dc.b	'C',$c8,4,0,0,0,'C',$c8
	dc.b	4,0,0,0,'C',$c8,4,0
	dc.b	0,0,'Dh',4,0,0,0
	dc.b	'Dh',4,0,0,0,'Dh'
	dc.b	4,0,0,0,'Dh',2,0
	dc.b	0,0,'E',8,2,0,0,0
	dc.b	'E',8,2,0,0,0,'E',8
	dc.b	2,0,0,0,'E',$a8,2,0
	dc.b	0,0,'E',$a8,2,0,0,0
	dc.b	'E',$a8,0,0,2,0,'FH'
	dc.b	0,0,2,0,'FH',0,0
	dc.b	2,0,'FH',0,0,2,0
	dc.b	'FH',0,0,2,0,'F',$e8
	dc.b	0,0,2,0,'F',$e8,0,0
	dc.b	2,0,'F',$e8,0,0,2,0
	dc.b	'G',$88,0,0,2,0,'G',$88
	dc.b	0,0,1,0,'G',$88,0,0
	dc.b	1,0,'H(',0,0,1,0
	dc.b	'H(',0,0,1,0,'H',$c8
	dc.b	0,0,1,0,'H',$c8,0,0
	dc.b	1,0,'H',$c8,0,0,1,0
	dc.b	'Ih',0,0,1,0,'Ih'
	dc.b	0,0,0,$80,'J',8,0,0
	dc.b	0,$80,'J',8,0,0,0,$80
	dc.b	'J',8,0,0,0,$80,'J',$a8
	dc.b	0,0,0,$80,'J',$a8,0,0
	dc.b	0,$80,'KH',0,0,0,'@'
	dc.b	'KH',0,0,0,'@K',$e8
	dc.b	0,0,0,'@K',$e8,0,0
	dc.b	0,'@L',$88,0,0,0,'@'
	dc.b	'L',$88,0,0,0,' M('
	dc.b	0,0,0,' M(',0,0
	dc.b	0,' M',$c8,0,0,0,' '
	dc.b	'Nh',0,0,0,$10,'Nh'
	dc.b	0,0,0,$10,'O',8,0,0
	dc.b	0,$10,'O',8,0,0,0,8
	dc.b	'O',$a8,0,0,0,8,'PH'
	dc.b	0,0,0,8,'P',$e8,0,0
	dc.b	0,4,'P',$e8,0,0,0,4
	dc.b	'Q',$88,0,2,0,2,'R('
	dc.b	0,2,0,2,'R',$c8,0,2
	dc.b	0,2,'Sh',0,1,0,1
	dc.b	'T',$10,$80,0,$80,0,'T',$b0
	dc.b	$80,0,$80,0,'UP@',0
	dc.b	'@',0,'U',$f0,'@',0,'@',0
	dc.b	'V',$90,' ',0,' ',0,'W0'
	dc.b	$10,0,$10,0,'Xp',$10,0
	dc.b	$10,0,'Y',$10,8,0,8,0
	dc.b	'ZP',4,0,4,0,'Z',$f0
	dc.b	2,0,2,0,'\0',1,0
	dc.b	1,0
	subq.w	#6,-128(a0,d0.w)
	ori.l	#$5eb00040,d0
	ori.w	#$5ff0,d0
	ori.b	#$10,(a0)
	bsr.s	.l009d
	dc.b	0,8,0,8,'c',$10,0,4
	dc.b	0,4,'dP',0,1,0,1
	dc.b	'f',$d8,'@',0,'@',0,'h',$b8
	dc.b	$10,0,$10,0,'k8',4,0
	dc.b	4,0,'m',$b8,0,$80,0,$80
	dc.b	'p',$d8,0,$10,0,$10,'t',$98
.l009d:	dc.b	0,1,0,1,'x`',$10,0
	dc.b	$10,0,$ff,$ff,'<P',0,' '
	dc.b	0,0,'<P',0,' ',0,0
	dc.b	'<P',0,' ',0,0,'<P'
	dc.b	0,' ',0,0,';',$b0,0,' '
	dc.b	0,0,';',$b0,0,$10,0,0
	dc.b	';',$b0,0,$10,0,0,';',$b0
	dc.b	0,$10,0,0,';',$10,0,$10
	dc.b	0,0,';',$10,0,$10,0,0
	dc.b	';',$10,0,$10,0,0,';',$10
	dc.b	0,$10,0,0,':p',0,$10
	dc.b	0,0,':p',0,$10,0,0
	dc.b	':p',0,8,0,0,'9',$d0
	dc.b	0,8,0,0,'9',$d0,0,8
	dc.b	0,0,'9',$d0,0,8,0,0
	dc.b	'90',0,8,0,0,'90'
	dc.b	0,8,0,0,'90',0,8
	dc.b	0,0,'8',$90,0,4,0,0
	dc.b	'8',$90,0,4,0,0,'7',$f0
	dc.b	0,4,0,0,'7',$f0,0,4
	dc.b	0,0,'7P',0,4,0,0
	dc.b	'7P',0,4,0,0,'6',$b0
	dc.b	0,4,0,0,'6',$b0,0,2
	dc.b	0,0,'6',$10,0,2,0,0
	dc.b	'6',$10,0,2,0,0,'5p'
	dc.b	0,2,0,0,'4',$d0,0,2
	dc.b	0,0,'4',$d0,0,1,0,0
	dc.b	'40',0,1,0,0,'3',$90
	dc.b	0,1,0,0,'2',$f0,0,0
	dc.b	0,1,'2',$f0,0,0,0,1
	dc.b	'2X',0,0,$80,0,'1',$b8
	dc.b	0,0,$80,0,'1',$18,0,0
	dc.b	$80,0,'/',$d8,0,0,$80,0
	dc.b	'/8',0,0,'@',0,'.',$98
	dc.b	0,0,'@',0,'-X',0,0
	dc.b	' ',0,',',$b8,0,0,' ',0
	dc.b	'+x',0,0,' ',0,'*8'
	dc.b	0,0,$10,0,'(',$f8,0,0
	dc.b	$10,0,$27,$b8,0,0,8,0
	dc.b	'%',$d8,0,0,4,0,'#',$f8
	dc.b	0,0,4,0,'"',$18,0,0
	dc.b	2,0,$1f,$98,0,0,1,0
	dc.b	$1d,$18,0,0,0,$80,$19,$f8
	dc.b	0,0,0,'@',$16,'8',0,0
	dc.b	0,$10,$11,$d8,0,0,0,4
	dc.b	$b,$98,0,0,0,1,4,$c0
	dc.b	0,0,'@',0,$ff,$ff,'Dp'
	dc.b	0,'@',0,0,'Dp',0,'@'
	dc.b	0,0,'Dp',0,'@',0,0
	dc.b	'Dp',0,' ',0,0,'Dp'
	dc.b	0,' ',0,0,'Dp',0,' '
	dc.b	0,0,'Dp',0,' ',0,0
	dc.b	'Dp',0,$10,0,0,'Dp'
	dc.b	0,$10,0,0,'Dp',0,$10
	dc.b	0,0,'Dp',0,8,0,0
	dc.b	'Dp',0,8,0,0,'Dp'
	dc.b	0,8,0,0,'C',$d0,0,8
	dc.b	0,0,'C',$d0,0,4,0,0
	dc.b	'C',$d0,0,4,0,0,'C',$d0
	dc.b	0,4,0,0,'C',$d0,0,2
	dc.b	0,0,'C',$d0,0,2,0,0
	dc.b	'C',$d0,0,2,0,0,'C',$d0
	dc.b	0,1,0,0,'C',$d0,0,1
	dc.b	0,0,'C0',0,1,0,0
	dc.b	'C8',$80,0,0,0,'C8'
	dc.b	$80,0,0,0,'C8',$80,0
	dc.b	0,0,'C8@',0,0,0
	dc.b	'C8@',0,0,0,'C8'
	dc.b	'@',0,0,0,'B',$98,' ',0
	dc.b	0,0,'B',$98,' ',0,0,0
	dc.b	'B',$98,$10,0,0,0,'B',$98
	dc.b	$10,0,0,0,'B',$98,8,0
	dc.b	0,0,'A',$f8,8,0,0,0
	dc.b	'A',$f8,8,0,0,0,'A',$f8
	dc.b	0,0,4,0,'A',$f8,0,0
	dc.b	4,0,'AX',0,0,2,0
	dc.b	'AX',0,0,2,0,'AX'
	dc.b	0,0,1,0,'AX',0,0
	dc.b	1,0,'@',$b8,0,0,0,$80
	dc.b	'@',$b8,0,0,0,$80,'@',$b8
	dc.b	0,0,0,'@@',$18,0,0
	dc.b	0,'@@',$18,0,0,0,' '
	dc.b	'?x',0,0,0,$10,'?x'
	dc.b	0,0,0,$10,'?x',0,0
	dc.b	0,8,'>',$d8,0,0,0,4
	dc.b	'>',$d8,0,0,0,4,'>8'
	dc.b	0,0,0,2,'>8',0,0
	dc.b	0,1,'=',$a0,0,0,$80,0
	dc.b	'=',$a0,0,0,$80,0,'=',0
	dc.b	0,0,'@',0,'=',0,0,0
	dc.b	' ',0,'<`',0,0,$10,0
	dc.b	';',$c0,0,0,8,0,';',$c0
	dc.b	0,0,4,0,'; ',0,0
	dc.b	2,0,':',$80,0,0,1,0
	dc.b	'9',$e0,0,0,0,$80,'9@'
	dc.b	0,0,0,' 8',$a0,0,0
	dc.b	0,$10,'8',0,0,0,0,8
	dc.b	'7`',0,0,0,2,'6',$c0
	dc.b	0,0,0,1,'6(',0,0
	dc.b	'@',0,'4',$e8,0,0,$10,0
	dc.b	'4H',0,0,4,0,'3',8
	dc.b	0,0,1,0,'1',$c8,0,0
	dc.b	0,' 0',$88,0,0,0,8
	dc.b	'/H',0,0,0,1,'-p'
	dc.b	$10,0,$10,0,',0',2,0
	dc.b	2,0,'*P',0,' ',0,' '
	dc.b	$27,$d0,0,1,0,1,'%X'
	dc.b	8,0,8,0,'"8',0,' '
	dc.b	0,' ',$1f,' @',0,'@',0
	dc.b	$1a,$c0,0,' ',0,' ',$16,'h'
	dc.b	8,0,8,0,$10,'0',$80,0
	dc.b	$80,0,8,$b8,$80,0,$80,0
	dc.b	$ff,$ff,'Ip ',0,0,0
	dc.b	'Ip ',0,0,0,'Ip'
	dc.b	$10,0,0,0,'Ip',$10,0
	dc.b	0,0,'Ip',$10,0,0,0
	dc.b	'Ip',8,0,0,0,'Ip'
	dc.b	8,0,0,0,'Ip',8,0
	dc.b	0,0,'Ip',8,0,0,0
	dc.b	'Ip',4,0,0,0,'Ip'
	dc.b	4,0,0,0,'J',$10,4,0
	dc.b	0,0,'J',$10,2,0,0,0
	dc.b	'J',$10,2,0,0,0,'J',$10
	dc.b	2,0,0,0,'J',$10,1,0
	dc.b	0,0,'J',$10,1,0,0,0
	dc.b	'J',$10,1,0,0,0,'J',$10
	dc.b	0,$80,0,0,'J',$10,0,$80
	dc.b	0,0,'J',$10,0,'@',0,0
	dc.b	'J',$10,0,'@',0,0,'J',$10
	dc.b	0,'@',0,0,'J',$10,0,' '
	dc.b	0,0,'J',$10,0,' ',0,0
	dc.b	'J',$10,0,' ',0,0,'J',$10
	dc.b	0,$10,0,0,'J',$10,0,$10
	dc.b	0,0,'J',$10,0,$10,0,0
	dc.b	'J',$10,0,8,0,0,'J',$10
	dc.b	0,8,0,0,'Ip',0,4
	dc.b	0,0,'Ip',0,4,0,0
	dc.b	'Ip',0,4,0,0,'Ip'
	dc.b	0,2,0,0,'Ip',0,2
	dc.b	0,0,'Ip',0,0,0,1
	dc.b	'Ip',0,0,0,1,'Ix'
	dc.b	0,0,$80,0,'Ix',0,0
	dc.b	$80,0,'Ix',0,0,$80,0
	dc.b	'Ix',0,0,'@',0,'Ix'
	dc.b	0,0,'@',0,'H',$d8,0,0
	dc.b	' ',0,'H',$d8,0,0,' ',0
	dc.b	'H',$d8,0,0,$10,0,'H',$d8
	dc.b	0,0,$10,0,'H',$d8,0,0
	dc.b	$10,0,'H',$d8,0,0,8,0
	dc.b	'H',$d8,0,0,8,0,'H8'
	dc.b	0,0,4,0,'H8',0,0
	dc.b	4,0,'H8',0,0,2,0
	dc.b	'H8',0,0,2,0,'H8'
	dc.b	0,0,1,0,'G',$98,0,0
	dc.b	1,0,'G',$98,0,0,0,$80
	dc.b	'G',$98,0,0,0,$80,'G',$98
	dc.b	0,0,0,'@G',$98,0,0
	dc.b	0,'@F',$f8,0,0,0,' '
	dc.b	'F',$f8,0,0,0,' F',$f8
	dc.b	0,0,0,$10,'FX',0,0
	dc.b	0,$10,'FX',0,0,0,8
	dc.b	'FX',0,0,0,8,'FX'
	dc.b	0,0,0,4,'E',$b8,0,0
	dc.b	0,2,'E',$b8,0,0,0,2
	dc.b	'E',$b8,0,0,0,1,'E',$18
	dc.b	0,0,0,1,'E ',0,0
	dc.b	$80,0,'D',$80,0,0,$80,0
	dc.b	'D',$80,0,0,'@',0,'D',$80
	dc.b	0,0,' ',0,'C',$e0,0,0
	dc.b	' ',0,'C',$e0,$10,0,$10,0
	dc.b	'C@',8,0,8,0,'C@'
	dc.b	8,0,8,0,'B',$a0,4,0
	dc.b	4,0,'B',$a0,2,0,2,0
	dc.b	'B',0,2,0,2,0,'B',0
	dc.b	1,0,1,0,'A`',0,$80
	dc.b	0,$80,'A`',0,$80,0,$80
	dc.b	'@',$c0,0,'@',0,'@@',$c0
	dc.b	0,' ',0,' @ ',0,$10
	dc.b	0,$10,'?',$80,0,$10,0,$10
	dc.b	'?',$80,0,8,0,8,'>',$e0
	dc.b	0,4,0,4,'>@',0,2
	dc.b	0,2,'>@',0,1,0,1
	dc.b	'=',$a0,0,1,0,1,'=',8
	dc.b	$80,0,$80,0,'<h@',0
	dc.b	'@',0,';',$c8,' ',0,' ',0
	dc.b	';(',$10,0,$10,0,':',$88
	dc.b	8,0,8,0,':',$88,4,0
	dc.b	4,0,'9',$e8,2,0,2,0
	dc.b	'8',$a8,1,0,1,0,'8',8
	dc.b	0,$80,0,$80,'7h',0,'@'
	dc.b	0,'@6',$c8,0,' ',0,' '
	dc.b	'6(',0,8,0,8,'4',$e8
	dc.b	0,4,0,4,'4H',0,2
	dc.b	0,2,'3',$a8,0,1,0,1
	dc.b	'2p@',0,'@',0,'1',$d0
	dc.b	' ',0,' ',0,'0',$90,8,0
	dc.b	8,0,'/P',4,0,4,0
	dc.b	'.',$10,1,0,1,0,',',$d0
	dc.b	0,'@',0,'@+',$90,0,$10
	dc.b	0,$10,'*P',0,4,0,4
	dc.b	')',$10,0,1,0,1,$27,'8'
	dc.b	'@',0,'@',0,'%',$f8,$10,0
	dc.b	$10,0,'$',$18,2,0,2,0
	dc.b	'"8',0,$80,0,$80,$1f,$b8
	dc.b	0,$10,0,$10,$1d,$d8,0,2
	dc.b	0,2,$1b,'`@',0,'@',0
	dc.b	$18,$e0,4,0,4,0,$15,$c0
	dc.b	0,'@',0,'@',$12,$a0,0,4
	dc.b	0,4,$f,$88,' ',0,' ',0
	dc.b	$b,$c8,1,0,1,0,7,'h'
	dc.b	0,4,0,4,2,'p',$10,0
	dc.b	$10,0,$ff,$ff,'O ',0,1
	dc.b	0,0,'O(',$80,0,0,0
	dc.b	'N',$88,'@',0,0,0,'N',$88
	dc.b	$10,0,0,0,'M',$e8,8,0
	dc.b	0,0,'M',$e8,4,0,0,0
	dc.b	'MH',2,0,0,0,'MH'
	dc.b	1,0,0,0,'L',$a8,0,'@'
	dc.b	0,0,'L',$a8,0,' ',0,0
	dc.b	'L',8,0,$10,0,0,'L',8
	dc.b	0,4,0,0,'Kh',0,2
	dc.b	0,0,'J',$c8,0,1,0,0
	dc.b	'J',$d0,'@',0,0,0,'J0'
	dc.b	' ',0,0,0,'I',$90,8,0
	dc.b	0,0,'I',$90,4,0,0,0
	dc.b	'H',$f0,1,0,0,0,'HP'
	dc.b	0,'@',0,0,'G',$b0,0,' '
	dc.b	0,0,'G',$10,0,8,0,0
	dc.b	'Fp',0,2,0,0,'E',$d8
	dc.b	$80,0,0,0,'E8 ',0
	dc.b	0,0,'D',$98,8,0,0,0
	dc.b	'C',$f8,2,0,0,0,'CX'
	dc.b	0,$80,0,0,'B',$b8,0,' '
	dc.b	0,0,'Ax',0,8,0,0
	dc.b	'@',$d8,0,1,0,0,'?',$a0
	dc.b	'@',0,0,0,'?',0,8,0
	dc.b	0,0,'=',$c0,1,0,0,0
	dc.b	'= ',0,'@',0,0,';',$e0
	dc.b	0,8,0,0,':',$a8,0,0
	dc.b	$80,0,'9h',0,0,$10,0
	dc.b	'8(',0,0,2,0,'6H'
	dc.b	0,0,0,' 5',8,0,0
	dc.b	0,2,'30',0,0,' ',0
	dc.b	'1',$f0,0,0,2,0,'0',$10
	dc.b	0,0,0,$10,'.8',0,0
	dc.b	$80,0,'+',$b8,0,0,4,0
	dc.b	')8',0,0,0,$10,$ff,$ff
	dc.b	'>',$d0,$10,0,0,0,'>',$d0
	dc.b	$10,0,0,0,'>',$d0,8,0
	dc.b	0,0,'>',$d0,8,0,0,0
	dc.b	'>',$d0,8,0,0,0,'>',$d0
	dc.b	8,0,0,0,'>',$d0,8,0
	dc.b	0,0,'>0',8,0,0,0
	dc.b	'>0',8,0,0,0,'>0'
	dc.b	8,0,0,0,'>0',8,0
	dc.b	0,0,'>0',8,0,0,0
	dc.b	'>0',8,0,0,0,'>0'
	dc.b	8,0,0,0,'>0',8,0
	dc.b	0,0,'>0',8,0,0,0
	dc.b	'>0',8,0,0,0,'>0'
	dc.b	8,0,0,0,'>0',8,0
	dc.b	0,0,'>0',8,0,0,0
	dc.b	'>0',8,0,0,0,'=',$90
	dc.b	8,0,0,0,'=',$90,8,0
	dc.b	0,0,'=',$90,8,0,0,0
	dc.b	'=',$90,8,0,0,0,'=',$90
	dc.b	8,0,0,0,'=',$90,8,0
	dc.b	0,0,'=',$90,8,0,0,0
	dc.b	'=',$90,8,0,0,0,'=',$90
	dc.b	8,0,0,0,'=',$90,8,0
	dc.b	0,0,'=',$90,8,0,0,0
	dc.b	'<',$f0,8,0,0,0,'<',$f0
	dc.b	8,0,0,0,'<',$f0,8,0
	dc.b	0,0,'<',$f0,8,0,0,0
	dc.b	'<',$f0,0,0,8,0,'<',$f0
	dc.b	0,0,8,0,'<',$f0,0,0
	dc.b	8,0,'<',$f0,0,0,8,0
	dc.b	'<',$f0,0,0,8,0,'<',$f0
	dc.b	0,0,4,0,'<P',0,0
	dc.b	4,0,'<P',0,0,4,0
	dc.b	'<P',0,0,4,0,'<P'
	dc.b	0,0,4,0,'<P',0,0
	dc.b	4,0,'<P',0,0,4,0
	dc.b	'<P',0,0,4,0,'<P'
	dc.b	0,0,4,0,';',$b0,0,0
	dc.b	4,0,';',$b0,0,0,4,0
	dc.b	';',$b0,0,0,4,0,';',$b0
	dc.b	0,0,4,0,';',$b0,0,0
	dc.b	4,0,';',$b0,0,0,4,0
	dc.b	';',$b0,0,0,4,0,';',$10
	dc.b	0,0,4,0,';',$10,0,0
	dc.b	4,0,';',$10,0,0,8,0
	dc.b	';',$10,0,0,8,0,';',$10
	dc.b	0,0,8,0,';',$10,0,0
	dc.b	8,0,':p',0,0,8,0
	dc.b	':p',0,0,8,0,':p'
	dc.b	0,0,8,0,':p',0,0
	dc.b	8,0,':p',0,0,8,0
	dc.b	':p',0,0,8,0,'9',$d0
	dc.b	0,0,8,0,'9',$d0,0,0
	dc.b	8,0,'9',$d0,0,0,8,0
	dc.b	'9',$d0,0,0,8,0,'9',$d0
	dc.b	0,0,8,0,'90',0,0
	dc.b	8,0,'90',0,0,8,0
	dc.b	'90',8,0,8,0,'90'
	dc.b	8,0,8,0,'8',$90,8,0
	dc.b	8,0,'8',$90,8,0,8,0
	dc.b	'8',$90,8,0,8,0,'8',$90
	dc.b	8,0,8,0,'7',$f0,8,0
	dc.b	8,0,'7',$f0,8,0,8,0
	dc.b	'7',$f0,8,0,8,0,'7P'
	dc.b	$10,0,$10,0,'7P',$10,0
	dc.b	$10,0,'7P',$10,0,$10,0
	dc.b	'6',$b0,$10,0,$10,0,'6',$b0
	dc.b	$10,0,$10,0,'6',$b0,$10,0
	dc.b	$10,0,'6',$10,$10,0,$10,0
	dc.b	'6',$10,$10,0,$10,0,'5p'
	dc.b	$10,0,$10,0,'5p ',0
	dc.b	' ',0,'5p ',0,' ',0
	dc.b	'4',$d0,' ',0,' ',0,'40'
	dc.b	' ',0,' ',0,'40 ',0
	dc.b	' ',0,'3',$90,' ',0,' ',0
	dc.b	'3',$90,'@',0,'@',0,'2',$f0
	dc.b	'@',0,'@',0,'2P@',0
	dc.b	'@',0,'1',$b0,'@',0,'@',0
	dc.b	'1',$b0,$80,0,$80,0,'1',$10
	dc.b	$80,0,$80,0,'0p',$80,0
	dc.b	$80,0,'/',$c8,0,1,0,1
	dc.b	'/(',0,1,0,1,'-',$e8
	dc.b	0,1,0,1,'-H',0,2
	dc.b	0,2,',',8,0,2,0,2
	dc.b	'+h',0,4,0,4,'*('
	dc.b	0,8,0,8,'(H',0,$10
	dc.b	0,$10,$27,8,0,$10,0,$10
	dc.b	'%(',0,' ',0,' "',$a8
	dc.b	0,$80,0,$80,' (',1,0
	dc.b	1,0,$1d,8,4,0,4,0
	dc.b	$19,'H',$10,0,$10,0,$14,$e8
	dc.b	$80,0,$80,0,$e,0,0,4
	dc.b	0,4,5,$e0,0,$80,0,$80
	dc.b	$ff,$ff,'C(',0,$10,0,0
	dc.b	'C(',0,$10,0,0,'C',$c8
	dc.b	0,$10,0,0,'C',$c8,0,$10
	dc.b	0,0,'C',$c8,0,$10,0,0
	dc.b	'C',$c8,0,$10,0,0,'C',$c8
	dc.b	0,$10,0,0,'C',$c8,0,$10
	dc.b	0,0,'Dh',0,$10,0,0
	dc.b	'Dh',0,$10,0,0,'Dh'
	dc.b	0,$10,0,0,'Dh',0,8
	dc.b	0,0,'Dh',0,8,0,0
	dc.b	'Dh',0,8,0,0,'E',8
	dc.b	0,8,0,0,'E',8,0,8
	dc.b	0,0,'E',8,0,8,0,0
	dc.b	'E',8,0,8,0,0,'E',8
	dc.b	0,8,0,0,'E',$a8,0,8
	dc.b	0,0,'E',$a8,0,4,0,0
	dc.b	'E',$a8,0,4,0,0,'E',$a8
	dc.b	0,4,0,0,'E',$a8,0,4
	dc.b	0,0,'E',$a8,0,4,0,0
	dc.b	'FH',0,4,0,0,'FH'
	dc.b	0,2,0,0,'FH',0,2
	dc.b	0,0,'FH',0,2,0,0
	dc.b	'FH',0,2,0,0,'F',$e8
	dc.b	0,2,0,0,'F',$e8,0,2
	dc.b	0,0,'F',$e8,0,1,0,0
	dc.b	'F',$e8,0,1,0,0,'G',$88
	dc.b	0,1,0,0,'G',$88,0,1
	dc.b	0,0,'G',$88,0,0,0,1
	dc.b	'G',$90,0,0,$80,0,'G',$90
	dc.b	0,0,$80,0,'H0',0,0
	dc.b	$80,0,'H0',0,0,$80,0
	dc.b	'H0',0,0,'@',0,'H0'
	dc.b	0,0,'@',0,'H',$d0,0,0
	dc.b	'@',0,'H',$d0,0,0,' ',0
	dc.b	'H',$d0,0,0,' ',0,'Ip'
	dc.b	0,0,' ',0,'Ip',0,0
	dc.b	$10,0,'Ip',0,0,$10,0
	dc.b	'Ip',0,0,$10,0,'J',$10
	dc.b	0,0,8,0,'J',$10,0,0
	dc.b	8,0,'J',$10,0,0,8,0
	dc.b	'J',$b0,0,0,4,0,'J',$b0
	dc.b	0,0,4,0,'J',$b0,0,0
	dc.b	2,0,'KP',0,0,2,0
	dc.b	'KP',0,0,1,0,'KP'
	dc.b	0,0,1,0,'K',$f0,0,0
	dc.b	0,$80,'K',$f0,0,0,0,$80
	dc.b	'L',$90,0,0,0,'@L',$90
	dc.b	0,0,0,'@M0',0,0
	dc.b	0,' M0',0,0,0,$10
	dc.b	'M',$d0,0,0,0,$10,'M',$d0
	dc.b	0,0,0,8,'Np',0,0
	dc.b	0,4,'Np',0,0,0,2
	dc.b	'O',$10,0,0,0,2,'O',$10
	dc.b	0,0,0,1,'O',$b8,0,0
	dc.b	$80,0,'PX',0,0,'@',0
	dc.b	'P',$f8,0,0,$10,0,'P',$f8
	dc.b	0,0,8,0,'Q',$98,0,0
	dc.b	4,0,'R8',1,0,1,0
	dc.b	'R',$d8,0,$80,0,$80,'Sx'
	dc.b	0,' ',0,' T',$b8,0,8
	dc.b	0,8,'UX',0,2,0,2
	dc.b	'V',0,$80,0,$80,0,'W@'
	dc.b	' ',0,' ',0,'X',$80,4,0
	dc.b	4,0,'Y',$c0,0,$80,0,$80
	dc.b	'[',0,0,8,0,8,'\',$e8
	dc.b	$80,0,$80,0,'^',$c8,8,0
	dc.b	8,0,'`',$a8,0,' ',0,' '
	dc.b	'c',$d0,$80,0,$80,0,'f',$f0
	dc.b	0,$80,0,$80,'j',$b8,' ',0
	dc.b	' ',0,'o',$b8,0,2,0,2
	dc.b	'v',0,0,2,0,2,$ff,$ff
	dc.b	'E',$b8,0,8,0,0,'E',$b8
	dc.b	0,4,0,0,'E',$18,0,4
	dc.b	0,0,'E',$18,0,4,0,0
	dc.b	'E',$18,0,2,0,0,'Dx'
	dc.b	0,2,0,0,'Dx',0,1
	dc.b	0,0,'C',$d8,0,1,0,0
	dc.b	'C',$d8,0,1,0,0,'C@'
	dc.b	$80,0,0,0,'C@',$80,0
	dc.b	0,0,'C@@',0,0,0
	dc.b	'B',$a0,'@',0,0,0,'B',$a0
	dc.b	'@',0,0,0,'B',0,' ',0
	dc.b	0,0,'B',0,' ',0,0,0
	dc.b	'A`',$10,0,0,0,'A`'
	dc.b	$10,0,0,0,'@',$c0,8,0
	dc.b	0,0,'@',$c0,8,0,0,0
	dc.b	'@ ',8,0,0,0,'?',$80
	dc.b	4,0,0,0,'?',$80,4,0
	dc.b	0,0,'>',$e0,2,0,0,0
	dc.b	'>',$e0,2,0,0,0,'>@'
	dc.b	2,0,0,0,'>@',1,0
	dc.b	0,0,'=',$a0,1,0,0,0
	dc.b	'=',0,1,0,0,0,'=',0
	dc.b	0,$80,0,0,'<`',0,$80
	dc.b	0,0,';',$c0,0,'@',0,0
	dc.b	';',$c0,0,'@',0,0,'; '
	dc.b	0,'@',0,0,':',$80,0,' '
	dc.b	0,0,'9',$e0,0,' ',0,0
	dc.b	'9',$e0,0,0,0,$10,'9@'
	dc.b	0,0,0,$10,'8',$a0,0,0
	dc.b	0,$10,'8',0,0,0,0,8
	dc.b	'7`',0,0,0,8,'6',$c0
	dc.b	0,0,0,8,'6',$c0,0,0
	dc.b	0,4,'6 ',0,0,0,4
	dc.b	'5',$80,0,0,0,2,'4',$e0
	dc.b	0,0,0,2,'4@',0,0
	dc.b	0,2,'3',$a0,0,0,0,1
	dc.b	'3',0,0,0,0,1,'2`'
	dc.b	0,0,0,1,'1',$c8,0,0
	dc.b	$80,0,'1(',0,0,$80,0
	dc.b	'0',$88,0,0,$80,0,'/',$e8
	dc.b	0,0,'@',0,'/H',0,0
	dc.b	'@',0,'.',8,0,0,'@',0
	dc.b	'-h',0,0,' ',0,',',$c8
	dc.b	0,0,' ',0,',(',0,0
	dc.b	' ',0,'+',$88,0,0,$10,0
	dc.b	'*H',0,0,$10,0,')',$a8
	dc.b	0,0,$10,0,'(h',0,0
	dc.b	8,0,$27,$c8,0,0,8,0
	dc.b	$27,'(',0,0,8,0,'%',$e8
	dc.b	0,0,4,0,'%H',0,0
	dc.b	4,0,'$',8,0,0,4,0
	dc.b	'"',$c8,0,0,2,0,'"('
	dc.b	0,0,2,0,' ',$e8,0,0
	dc.b	2,0,$1f,$a8,0,0,1,0
	dc.b	$1e,'h',0,0,1,0,$1d,'('
	dc.b	0,0,1,0,$1b,$e8,0,0
	dc.b	0,$80,$1a,$a8,0,0,0,$80
	dc.b	$19,'h',0,$80,0,$80,$18,'('
	dc.b	0,$80,0,$80,$16,'H',0,'@'
	dc.b	0,'@',$15,8,0,'@',0,'@'
	dc.b	$13,'(',0,'@',0,'@',$11,$e8
	dc.b	0,' ',0,' ',$10,8,0,' '
	dc.b	0,' ',$e,'(',0,' ',0,' '
	dc.b	$c,'H',0,$10,0,$10,$a,'h'
	dc.b	0,$10,0,$10,8,$88,0,$10
	dc.b	0,$10,6,8,0,$10,0,$10
	dc.b	4,'(',0,8,0,8,1,$a8
	dc.b	0,8,0,8,$ff,$ff
	jmp	0(a0,d1.w)
	dc.b	0,0,'P0 ',0,0,0
	dc.b	'P',$d0,' ',0,0,0,'R',$10
	dc.b	'@',0,0,0,'R',$b0,$80,0
	dc.b	0,0,'S',$f0,$80,0,0,0
	dc.b	'U(',0,1,0,0,'Vh'
	dc.b	0,2,0,0,'W',8,0,4
	dc.b	0,0,'XH',0,4,0,0
	dc.b	'Y',$88,0,8,0,0,'Z',$c8
	dc.b	0,$10,0,0,'\',$a8,0,' '
	dc.b	0,0,']',$e8,0,'@',0,0
	dc.b	'_(',0,$80,0,0,'a',8
	dc.b	0,$80,0,0,'bH',1,0
	dc.b	0,0,'d(',2,0,0,0
	dc.b	'f',8,4,0,0,0,'gH'
	dc.b	8,0,0,0,'i(',$10,0
	dc.b	0,0,'k',$a8,' ',0,0,0
	dc.b	'm',$88,$80,0,0,0,'p',0
	dc.b	0,1,0,0,'q',$e0,0,2
	dc.b	0,0,'t`',0,4,0,0
	dc.b	'w',$80,0,$10,0,0,'z',0
	dc.b	0,' ',0,0,$ff,$ff,'/',$e0
	dc.b	'@',0,0,0,'/@@',0
	dc.b	0,0,'.',$a0,'@',0,0,0
	dc.b	'.',0,' ',0,0,0,'-`'
	dc.b	' ',0,0,0,',',$c0,' ',0
	dc.b	0,0,',  ',0,0,0
	dc.b	'*',$e0,$10,0,0,0,'*@'
	dc.b	$10,0,0,0,')',$a0,$10,0
	dc.b	0,0,'(`',8,0,0,0
	dc.b	$27,$c0,8,0,0,0,'&',$80
	dc.b	8,0,0,0,'%',$e0,4,0
	dc.b	0,0,'$',$a0,4,0,0,0
	dc.b	'#`',4,0,0,0,'"',$c0
	dc.b	2,0,0,0,'!',$80,2,0
	dc.b	0,0,' @',2,0,0,0
	dc.b	$1f,0,1,0,0,0,$1d,' '
	dc.b	1,0,0,0,$1b,$e0,0,$80
	dc.b	0,0,$1a,0,0,$80,0,0
	dc.b	$18,$c0,0,'@',0,0,$16,$e0
	dc.b	0,'@',0,0,$15,0,0,' '
	dc.b	0,0,$13,' ',0,' ',0,0
	dc.b	$10,$a0,0,$10,0,0,$e,' '
	dc.b	0,$10,0,0,$b,$a0,0,8
	dc.b	0,0,9,' ',0,4,0,0
	dc.b	6,0,0,2,0,0,2,'@'
	dc.b	0,2,0,0,$ff,$ff,'G',$88
	dc.b	$80,0,0,0,'G',$88,$80,0
	dc.b	0,0,'H(',$80,0,0,0
	dc.b	'H(',$80,0,0,0,'H',$c8
	dc.b	$80,0,0,0,'Ih',$80,0
	dc.b	0,0,'Ih',$80,0,0,0
	dc.b	'J',8,$80,0,0,0,'J',8
	dc.b	$80,0,0,0,'J',$a8,$80,0
	dc.b	0,0,'KH',$80,0,0,0
	dc.b	'KH',$80,0,0,0,'K',$e8
	dc.b	$80,0,0,0,'L',$88,$80,0
	dc.b	0,0,'L',$88,$80,0,0,0
	dc.b	'M(',$80,0,0,0,'M',$c8
	dc.b	$80,0,0,0,'Nh',$80,0
	dc.b	0,0,'O',8,$80,0,0,0
	dc.b	'O',$a8,$80,0,0,0,'PH'
	dc.b	$80,0,0,0,'P',$e8,$80,0
	dc.b	0,0,'Q',$88,$80,0,0,0
	dc.b	'R(',$80,0,0,0,'R',$c8
	dc.b	$80,0,0,0,'Sh',$80,0
	dc.b	0,0,'T',8,$80,0,0,0
	dc.b	'UH',$80,0,0,0,'U',$e8
	dc.b	'@',0,0,0,'W(@',0
	dc.b	0,0,'W',$c8,'@',0,0,0
	dc.b	'Y',8,'@',0,0,0,'ZH'
	dc.b	'@',0,0,0,'[',$88,'@',0
	dc.b	0,0,'\',$c8,'@',0,0,0
	dc.b	'^',8,' ',0,0,0,'_',$e8
	dc.b	0,0,' ',0,'a(',0,0
	dc.b	' ',0,'c',8,0,0,' ',0
	dc.b	'd',$e8,0,0,$10,0,'gh'
	dc.b	0,0,$10,0,'i',$e8,0,0
	dc.b	$10,0,'lh',0,0,8,0
	dc.b	'o',$88,0,0,8,0,'sH'
	dc.b	0,0,4,0,'w',8,0,0
	dc.b	4,0,'|',8,0,0,2,0
	dc.b	$ff,$ff,'7',$e8,0,'@',0,0
	dc.b	'7',$e8,0,'@',0,0,'7',$e8
	dc.b	0,'@',0,0,'7',$e8,0,'@'
	dc.b	0,0,'7',$e8,0,'@',0,0
	dc.b	'7',$e8,0,$80,0,0,'7',$e8
	dc.b	0,$80,0,0,'7',$e8,0,$80
	dc.b	0,0,'7',$e8,0,$80,0,0
	dc.b	'7',$e8,1,0,0,0,'7',$e8
	dc.b	1,0,0,0,'7',$e8,1,0
	dc.b	0,0,'7',$e8,1,0,0,0
	dc.b	'7',$e8,2,0,0,0,'7',$e8
	dc.b	2,0,0,0,'7',$e8,2,0
	dc.b	0,0,'7',$e8,2,0,0,0
	dc.b	'7',$e8,4,0,0,0,'7',$e8
	dc.b	4,0,0,0,'7',$e8,4,0
	dc.b	0,0,'8',$88,4,0,0,0
	dc.b	'8',$88,8,0,0,0,'8',$88
	dc.b	8,0,0,0,'8',$88,8,0
	dc.b	0,0,'8',$88,8,0,0,0
	dc.b	'8',$88,$10,0,0,0,'8',$88
	dc.b	$10,0,0,0,'8',$88,$10,0
	dc.b	0,0,'8',$88,$10,0,0,0
	dc.b	'8',$88,' ',0,0,0,'8',$88
	dc.b	' ',0,0,0,'9( ',0
	dc.b	0,0,'9(@',0,0,0
	dc.b	'9(@',0,0,0,'9('
	dc.b	'@',0,0,0,'9(@',0
	dc.b	0,0,'9(',0,0,$80,0
	dc.b	'9(',0,0,$80,0,'9',$c8
	dc.b	0,0,$80,0,'9',$c0,0,0
	dc.b	0,1,'9',$c0,0,0,0,1
	dc.b	'9',$c0,0,0,0,1,'9',$c0
	dc.b	0,0,0,1,'9',$c0,0,0
	dc.b	0,2,':`',0,0,0,2
	dc.b	':`',0,0,0,2,':`'
	dc.b	0,0,0,4,':`',0,0
	dc.b	0,4,';',0,0,0,0,4
	dc.b	';',0,0,0,0,8,';',0
	dc.b	0,0,0,8,';',0,0,0
	dc.b	0,8,';',0,0,0,0,$10
	dc.b	';',$a0,0,0,0,$10,';',$a0
	dc.b	0,0,0,$10,';',$a0,0,0
	dc.b	0,' <@',0,0,0,' '
	dc.b	'<@',0,0,0,' <@'
	dc.b	0,0,0,'@<@',0,0
	dc.b	0,'@<',$e0,0,0,0,$80
	dc.b	'<',$e0,0,0,0,$80,'<',$e0
	dc.b	0,0,0,$80,'=',$80,0,0
	dc.b	1,0,'=',$80,0,0,1,0
	dc.b	'=',$80,0,0,2,0,'> '
	dc.b	0,0,2,0,'> ',0,0
	dc.b	2,0,'>',$c0,0,0,4,0
	dc.b	'>',$c0,0,0,4,0,'?`'
	dc.b	0,0,8,0,'?`',0,0
	dc.b	8,0,'?`',0,0,$10,0
	dc.b	'@',0,0,0,$10,0,'@',0
	dc.b	0,0,$10,0,'@',$a0,0,0
	dc.b	' ',0,'@',$a0,' ',0,' ',0
	dc.b	'A@@',0,'@',0,'A',$e0
	dc.b	'@',0,'@',0,'A',$e0,$80,0
	dc.b	$80,0,'Bx',0,1,0,1
	dc.b	'Bx',0,1,0,1,'C',$18
	dc.b	0,2,0,2,'C',$b8,0,2
	dc.b	0,2,'DX',0,4,0,4
	dc.b	'DX',0,8,0,8,'D',$f8
	dc.b	0,8,0,8,'E',$98,0,$10
	dc.b	0,$10,'F8',0,' ',0,' '
	dc.b	'F',$d8,0,' ',0,' Gx'
	dc.b	0,'@',0,'@H',$18,0,$80
	dc.b	0,$80,'H',$b8,1,0,1,0
	dc.b	'IX',1,0,1,0,'I',$f8
	dc.b	2,0,2,0,'J',$98,4,0
	dc.b	4,0,'K8',8,0,8,0
	dc.b	'Lx',$10,0,$10,0,'M',$18
	move.l	d0,d0
	move.l	d0,d0
	unlk	a0
	or.b	d0,d0
	or.b	d0,d0
	jmp	1(a0,d0.w)
	dc.b	0,1,'P0',0,2,0,2
	dc.b	'Qp',0,4,0,4,'R',$b0
	dc.b	0,$10,0,$10,'S',$f0,0,' '
	dc.b	0,' U0',0,$80,0,$80
	dc.b	'W',$10,2,0,2,0,'X',$f0
	dc.b	8,0,8,0,'Z',$d0,' ',0
	dc.b	' ',0,'\',$b0,$80,0,$80,0
	dc.b	'_(',0,4,0,4,'a',$a8
	dc.b	0,' ',0,' d(',1,0
	dc.b	1,0,'gH',8,0,8,0
	dc.b	'k',8,$80,0,$80,0,'n',$c0
	dc.b	0,$10,0,$10,'s ',2,0
	dc.b	2,0,'x',$c0,$80,0,$80,0
	dc.b	$ff,$ff,'2',$e8,0,'@',0,0
	dc.b	'2',$e8,0,'@',0,0,'2',$e8
	dc.b	0,$80,0,0,'2',$e8,0,$80
	dc.b	0,0,'2H',1,0,0,0
	dc.b	'2H',1,0,0,0,'2H'
	dc.b	2,0,0,0,'2H',2,0
	dc.b	0,0,'2H',2,0,0,0
	dc.b	'1',$a8,4,0,0,0,'1',$a8
	dc.b	8,0,0,0,'1',$a8,8,0
	dc.b	0,0,'1',$a8,$10,0,0,0
	dc.b	'1',8,$10,0,0,0,'1',8
	dc.b	' ',0,0,0,'1',8,' ',0
	dc.b	0,0,'1',8,'@',0,0,0
	dc.b	'0h',$80,0,0,0,'0h'
	dc.b	$80,0,0,0,'0`',0,1
	dc.b	0,0,'0`',0,2,0,0
	dc.b	'/',$c0,0,4,0,0,'/',$c0
	dc.b	0,8,0,0,'/',$c0,0,8
	dc.b	0,0,'/',$c0,0,$10,0,0
	dc.b	'/ ',0,' ',0,0,'/ '
	dc.b	0,'@',0,0,'/ ',0,$80
	dc.b	0,0,'.',$80,1,0,0,0
	dc.b	'.',$80,4,0,0,0,'-',$e0
	dc.b	8,0,0,0,'-',$e0,$10,0
	dc.b	0,0,'-',$e0,'@',0,0,0
	dc.b	'-@',$80,0,0,0,'-8'
	dc.b	0,2,0,0,',',$98,0,4
	dc.b	0,0,',',$98,0,0,0,$10
	dc.b	'+',$f8,0,0,0,'@+X'
	dc.b	0,0,1,0,'+X',0,0
	dc.b	4,0,'*',$b8,0,0,' ',0
	dc.b	'*',$10,0,0,0,1,')p'
	dc.b	0,0,0,8,')p',0,0
	dc.b	0,'@(',$d0,0,0,4,0
	dc.b	$27,$90,0,0,'@',0,'&',$e8
	dc.b	0,0,0,4,'&H',0,0
	dc.b	0,$80,'%',8,0,0,' ',0
	dc.b	'#',$c0,0,0,0,$10,'"',$80
	dc.b	0,0,$10,0,' ',$98,0,0
	dc.b	0,'@',$1e,$b0,0,0,0,2
	dc.b	$1c,'0',0,0,$80,0,$19,$a0
	dc.b	0,0,0,2,$ff,$ff,'>@'
	dc.b	0,$80,0,0,'>@',0,$80
	dc.b	0,0,'=',$a0,0,'@',0,0
	dc.b	'=',0,0,'@',0,0,'=',0
	dc.b	0,' ',0,0,'<`',0,' '
	dc.b	0,0,';',$c0,0,$10,0,0
	dc.b	'; ',0,8,0,0,'; '
	dc.b	0,8,0,0,':',$80,0,4
	dc.b	0,0,'9',$e0,0,4,0,0
	dc.b	'9@',0,2,0,0,'8',$a0
	dc.b	0,2,0,0,'8',$a0,0,1
	dc.b	0,0,'8',0,0,1,0,0
	dc.b	'7h',$80,0,0,0,'6',$c8
	dc.b	$80,0,0,0,'6(@',0
	dc.b	0,0,'5',$88,' ',0,0,0
	dc.b	'4',$e8,' ',0,0,0,'4H'
	dc.b	$10,0,0,0,'3',8,$10,0
	dc.b	0,0,'2h',8,0,0,0
	dc.b	'1',$c8,4,0,0,0,'1('
	dc.b	4,0,0,0,'0',$88,2,0
	dc.b	0,0,'/H',1,0,0,0
	dc.b	'.',$a8,1,0,0,0,'.',8
	dc.b	0,$80,0,0,',',$c8,0,'@'
	dc.b	0,0,',(',0,'@',0,0
	dc.b	'*',$e8,0,' ',0,0,'*H'
	dc.b	0,$10,0,0,')',8,0,$10
	dc.b	0,0,$27,$c8,0,8,0,0
	dc.b	'&',$88,0,4,0,0,'%',$e8
	dc.b	0,0,0,2,'$',$a8,0,0
	dc.b	0,1,'#h',0,0,0,1
	dc.b	'"0',0,0,$80,0,' P'
	dc.b	0,0,'@',0,$1f,$10,0,0
	dc.b	' ',0,$1d,$d0,0,0,$10,0
	dc.b	$1b,$f0,0,0,8,0,$1a,$10
	dc.b	0,0,4,0,$18,$d0,0,0
	dc.b	2,0,$16,$f0,0,0,1,0
	dc.b	$14,'p',0,0,0,'@',$12,$90
	dc.b	0,0,0,' ',$10,$b0,0,0
	dc.b	0,$10,$e,'0',0,0,0,4
	dc.b	$b,$b0,0,0,0,2,9,'0'
	dc.b	0,0,0,1,6,$18,0,0
	dc.b	'@',0,2,$f8,0,0,$10,0
	dc.b	$ff,$ff,'J',$b0,1,0,0,0
	dc.b	'J',$b0,1,0,0,0,'J',$b0
	dc.b	0,$80,0,0,'J',$b0,0,$80
	dc.b	0,0,'J',$b0,0,$80,0,0
	dc.b	'J',$b0,0,'@',0,0,'J',$b0
	dc.b	0,'@',0,0,'J',$b0,0,'@'
	dc.b	0,0,'J',$b0,0,' ',0,0
	dc.b	'J',$b0,0,' ',0,0,'J',$b0
	dc.b	0,$10,0,0,'J',$10,0,$10
	dc.b	0,0,'J',$10,0,$10,0,0
	dc.b	'J',$10,0,8,0,0,'J',$10
	dc.b	0,8,0,0,'J',$10,0,8
	dc.b	0,0,'J',$10,0,4,0,0
	dc.b	'J',$10,0,4,0,0,'J',$10
	dc.b	0,2,0,0,'J',$10,0,2
	dc.b	0,0,'J',$10,0,2,0,0
	dc.b	'J',$10,0,1,0,0,'J',$10
	dc.b	0,1,0,0,'J',$18,$80,0
	dc.b	0,0,'J',$18,$80,0,0,0
	dc.b	'Ix@',0,0,0,'Ix'
	dc.b	'@',0,0,0,'Ix@',0
	dc.b	0,0,'Ix ',0,0,0
	dc.b	'Ix ',0,0,0,'Ix'
	dc.b	$10,0,0,0,'Ix',$10,0
	dc.b	0,0,'H',$d8,8,0,0,0
	dc.b	'H',$d8,8,0,0,0,'H',$d8
	dc.b	4,0,0,0,'H',$d8,4,0
	dc.b	0,0,'H',$d8,0,0,4,0
	dc.b	'H',$d8,0,0,2,0,'H8'
	dc.b	0,0,2,0,'H8',0,0
	dc.b	1,0,'H8',0,0,1,0
	dc.b	'H8',0,0,0,$80,'G',$98
	dc.b	0,0,0,$80,'G',$98,0,0
	dc.b	0,'@G',$98,0,0,0,'@'
	dc.b	'G',$98,0,0,0,' F',$f8
	dc.b	0,0,0,' F',$f8,0,0
	dc.b	0,$10,'F',$f8,0,0,0,$10
	dc.b	'FX',0,0,0,8,'FX'
	dc.b	0,0,0,8,'FX',0,0
	dc.b	0,4,'FX',0,0,0,4
	dc.b	'E',$b8,0,0,0,2,'E',$b8
	dc.b	0,0,0,2,'E',$18,0,0
	dc.b	0,1,'E',$18,0,0,0,1
	dc.b	'E ',0,0,$80,0,'D',$80
	dc.b	0,0,$80,0,'D',$80,0,0
	dc.b	'@',0,'C',$e0,0,0,'@',0
	dc.b	'C',$e0,0,0,' ',0,'C',$e0
	dc.b	0,0,' ',0,'C@',0,0
	dc.b	$10,0,'C@',0,0,8,0
	dc.b	'B',$a0,0,0,8,0,'B',$a0
	dc.b	0,0,4,0,'B',0,0,0
	dc.b	4,0,'B',0,0,0,2,0
	dc.b	'A`',0,0,2,0,'A`'
	dc.b	0,0,1,0,'@',$c0,0,0
	dc.b	0,$80,'@ ',0,0,0,$80
	dc.b	'@ ',0,0,0,'@?',$80
	dc.b	0,0,0,'@?',$80,0,0
	dc.b	0,' >',$e0,0,$10,0,$10
	dc.b	'>@',0,$10,0,$10,'=',$a0
	dc.b	0,8,0,8,'=',$a0,0,4
	dc.b	0,4,'=',0,0,4,0,4
	dc.b	'<`',0,2,0,2,';',$c0
	dc.b	0,1,0,1,';',$c0,0,1
	dc.b	0,1,';(',$80,0,$80,0
	dc.b	':',$88,'@',0,'@',0,'9',$e8
	dc.b	' ',0,' ',0,'9H ',0
	dc.b	' ',0,'8',$a8,$10,0,$10,0
	dc.b	'8',8,8,0,8,0,'7h'
	dc.b	4,0,4,0,'6',$c8,4,0
	dc.b	4,0,'6(',2,0,2,0
	dc.b	'5',$88,1,0,1,0,'4',$e8
	dc.b	0,$80,0,$80,'3',$a8,0,'@'
	dc.b	0,'@3',8,0,' ',0,' '
	dc.b	'2h',0,$10,0,$10,'1('
	dc.b	0,8,0,8,'0',$88,0,4
	dc.b	0,4,'/H',0,2,0,2
	dc.b	'.',$a8,0,1,0,1,'-p'
	dc.b	$80,0,$80,0,',',$d0,'@',0
	dc.b	'@',0,'+',$90,' ',0,' ',0
	dc.b	'*P',$10,0,$10,0,')',$10
	dc.b	8,0,8,0,$27,$d0,2,0
	dc.b	2,0,'&',$90,1,0,1,0
	dc.b	'%P',0,$80,0,$80,'#p'
	dc.b	0,' ',0,' "0',0,$10
	dc.b	0,$10,' P',0,4,0,4
	dc.b	$1e,'p',0,1,0,1,$1c,$98
	dc.b	$80,0,$80,0,$1a,$b8,' ',0
	dc.b	' ',0,$18,$d8,8,0,8,0
	dc.b	$16,'X',2,0,2,0,$14,'x'
	dc.b	0,'@',0,'@',$11,'X',0,$10
	dc.b	0,$10,$e,$d8,0,2,0,2
	dc.b	$b,$c0,$80,0,$80,0,8,$a0
	dc.b	$10,0,$10,0,4,$e0,1,0
	dc.b	1,0,1,' ',0,' ',0,' '
	dc.b	$ff,$ff,'E',$10,4,0,0,0
	dc.b	'E',$10,4,0,0,0,'E',$b0
	dc.b	4,0,0,0,'E',$b0,2,0
	dc.b	0,0,'E',$b0,2,0,0,0
	dc.b	'E',$b0,2,0,0,0,'E',$b0
	dc.b	1,0,0,0,'E',$b0,1,0
	dc.b	0,0,'E',$b0,1,0,0,0
	dc.b	'FP',0,$80,0,0,'FP'
	dc.b	0,$80,0,0,'FP',0,$80
	dc.b	0,0,'FP',0,'@',0,0
	dc.b	'FP',0,'@',0,0,'FP'
	dc.b	0,' ',0,0,'FP',0,' '
	dc.b	0,0,'F',$f0,0,$10,0,0
	dc.b	'F',$f0,0,$10,0,0,'F',$f0
	dc.b	0,8,0,0,'F',$f0,0,8
	dc.b	0,0,'F',$f0,0,4,0,0
	dc.b	'G',$90,0,2,0,0,'G',$90
	dc.b	0,2,0,0,'G',$90,0,1
	dc.b	0,0,'G',$98,$80,0,0,0
	dc.b	'H8@',0,0,0,'H8'
	dc.b	'@',0,0,0,'H8 ',0
	dc.b	0,0,'H',$d8,$10,0,0,0
	dc.b	'H',$d8,8,0,0,0,'H',$d8
	dc.b	2,0,0,0,'Ix',1,0
	dc.b	0,0,'Ix',0,$80,0,0
	dc.b	'J',$18,0,' ',0,0,'J',$18
	dc.b	0,8,0,0,'J',$b8,0,4
	dc.b	0,0,'J',$b8,0,0,0,1
	dc.b	'K`',0,0,' ',0,'L',0
	dc.b	0,0,8,0,'L',$a0,0,0
	dc.b	1,0,'M@',0,0,0,$10
	dc.b	'M',$e0,0,0,0,1,'N',$88
	dc.b	0,0,8,0,'O',$c8,0,0
	dc.b	0,'@Q',$10,0,0,$80,0
	dc.b	'RP',0,0,0,'@T',$d8
	dc.b	0,0,8,0,'W`',0,0
	dc.b	' ',0,'[(',0,0,1,0
	dc.b	'`',$d8,0,0,2,0,$ff,$ff
	dc.b	'1',$18,' ',0,0,0,'0x'
	dc.b	'@',0,0,0,'0x@',0
	dc.b	0,0,'/',$d8,'@',0,0,0
	dc.b	'/',$d8,'@',0,0,0,'/8'
	dc.b	'@',0,0,0,'/8@',0
	dc.b	0,0,'.',$98,$80,0,0,0
	dc.b	'-',$f8,$80,0,0,0,'-',$f8
	dc.b	$80,0,0,0,'-X',$80,0
	dc.b	0,0,'-P',0,1,0,0
	dc.b	',',$b0,0,1,0,0,',',$b0
	dc.b	0,1,0,0,',',$10,0,1
	dc.b	0,0,'+p',0,2,0,0
	dc.b	'+p',0,2,0,0,'*',$d0
	dc.b	0,2,0,0,'*',$d0,0,4
	dc.b	0,0,'*0',0,4,0,0
	dc.b	')',$90,0,4,0,0,')',$90
	dc.b	0,8,0,0,'(',$f0,0,8
	dc.b	0,0,'(',$f0,0,8,0,0
	dc.b	'(P',0,$10,0,0,$27,$b0
	dc.b	0,$10,0,0,$27,$10,0,' '
	dc.b	0,0,$27,$10,0,' ',0,0
	dc.b	'&p',0,'@',0,0,'%',$d0
	dc.b	0,'@',0,0,'%',$d0,0,$80
	dc.b	0,0,'%0',0,$80,0,0
	dc.b	'$',$90,1,0,0,0,'#',$f0
	dc.b	1,0,0,0,'#',$f0,2,0
	dc.b	0,0,'#P',2,0,0,0
	dc.b	'"',$b0,0,0,4,0,'"',$10
	dc.b	0,0,4,0,'!p',0,0
	dc.b	8,0,'!p',0,0,$10,0
	dc.b	' ',$d0,0,0,$10,0,' 0'
	dc.b	0,0,' ',0,$1f,$90,0,0
	dc.b	'@',0,$1e,$f0,0,0,$80,0
	dc.b	$1e,'P',0,0,$80,0,$1d,$a8
	dc.b	0,0,0,1,$1d,8,0,0
	dc.b	0,2,$1c,'h',0,0,0,4
	dc.b	$1b,$c8,0,0,0,8,$1b,'('
	dc.b	0,0,0,$10,$1a,$88,0,0
	dc.b	0,' ',$19,$e8,0,0,0,'@'
	dc.b	$19,'H',0,0,0,$80,$18,8
	dc.b	0,0,1,0,$17,'h',0,0
	dc.b	2,0,$16,$c8,0,0,4,0
	dc.b	$16,'(',0,0,$10,0,$14,$e8
	dc.b	0,0,' ',0,$14,'H',0,0
	dc.b	'@',0,$13,0,0,0,0,1
	dc.b	$12,'`',0,0,0,4,$11,' '
	dc.b	0,0,0,8,$10,$80,0,0
	dc.b	0,' ',$f,'@',0,0,0,$80
	dc.b	$e,0,0,0,2,0,$c,$c0
	dc.b	0,0,8,0,$b,$80,0,0
	dc.b	' ',0,$a,'@',0,0,$80,0
	dc.b	8,$f8,0,0,0,2,7,$18
	dc.b	0,0,0,$10,5,$d8,0,0
	dc.b	0,$80,3,$f8,0,0,2,0
	dc.b	2,$18,0,0,' ',0,0,'0'
	dc.b	0,0,0,1,$ff,$ff,'8x'
	dc.b	0,1,0,0,'9',$18,0,1
	dc.b	0,0,'9',$18,0,1,0,0
	dc.b	'9',$b8,0,2,0,0,'9',$b8
	dc.b	0,2,0,0,':X',0,4
	dc.b	0,0,':X',0,4,0,0
	dc.b	':',$f8,0,8,0,0,':',$f8
	dc.b	0,8,0,0,';',$98,0,8
	dc.b	0,0,';',$98,0,$10,0,0
	dc.b	'<8',0,$10,0,0,'<8'
	dc.b	0,' ',0,0,'<',$d8,0,' '
	dc.b	0,0,'<',$d8,0,' ',0,0
	dc.b	'=x',0,'@',0,0,'>',$18
	dc.b	0,'@',0,0,'>',$18,0,$80
	dc.b	0,0,'>',$b8,0,$80,0,0
	dc.b	'>',$b8,0,$80,0,0,'?X'
	dc.b	1,0,0,0,'?',$f8,1,0
	dc.b	0,0,'?',$f8,2,0,0,0
	dc.b	'@',$98,2,0,0,0,'A8'
	dc.b	2,0,0,0,'A8',4,0
	dc.b	0,0,'A',$d8,4,0,0,0
	dc.b	'Bx',8,0,0,0,'C',$18
	dc.b	8,0,0,0,'C',$18,8,0
	dc.b	0,0,'C',$b8,$10,0,0,0
	dc.b	'DX',$10,0,0,0,'D',$f8
	dc.b	$10,0,0,0,'E',$98,' ',0
	dc.b	0,0,'F8 ',0,0,0
	dc.b	'F8@',0,0,0,'F',$d8
	dc.b	0,0,'@',0,'Gx',0,0
	dc.b	'@',0,'H',$18,0,0,$80,0
	dc.b	'H',$b8,0,0,$80,0,'IX'
	dc.b	0,0,$80,0,'I',$f0,0,0
	dc.b	0,1,'J',$90,0,0,0,1
	dc.b	'K0',0,0,0,1,'K',$d0
	dc.b	0,0,0,2,'Lp',0,0
	dc.b	0,2,'M',$10,0,0,0,2
	dc.b	'NP',0,0,0,4
	jmp	0(a0,d0.w)
	dc.b	0,4,'O',$90,0,0,0,8
	dc.b	'P0',0,0,0,8,'P',$d0
	dc.b	0,0,0,8,'R',$10,0,0
	dc.b	0,$10,'R',$b0,0,0,0,$10
	dc.b	'SP',0,0,0,$10,'T',$90
	dc.b	0,0,0,$10,'U0',0,0
	dc.b	0,' Vp',0,0,0,' '
	dc.b	'W',$10,0,0,0,' XP'
	dc.b	0,0,0,'@X',$f0,0,0
	dc.b	0,'@Z0',0,0,0,'@'
	dc.b	'[p',0,0,0,$80,'\',$b0
	dc.b	0,0,0,$80,']P',0,0
	dc.b	0,$80,'^',$90,0,0,1,0
	dc.b	'_',$d0,0,0,1,0,'a',$10
	dc.b	0,0,1,0,'bP',0,0
	dc.b	1,0,'c',$90,0,0,2,0
	dc.b	'ep',0,0,2,0,'f',$b0
	dc.b	0,0,2,0,'g',$f0,0,0
	dc.b	4,0,'i',$d0,0,0,4,0
	dc.b	'k',$b0,0,0,4,0,'l',$f0
	dc.b	0,0,8,0,'n',$d0,8,0
	dc.b	8,0,'p',$b0,8,0,8,0
	dc.b	'r',$90,8,0,8,0,'tp'
	dc.b	$10,0,$10,0,'v',$f0,$10,0
	dc.b	$10,0,'x',$d0,$10,0,$10,0
	dc.b	'{P ',0,' ',0,$ff,$ff
	dc.b	'/0',8,0,0,0,'.',$90
	dc.b	$10,0,0,0,'.',$90,$10,0
	dc.b	0,0,'.',$90,$10,0,0,0
	dc.b	'.',$90,' ',0,0,0,'-',$f0
	dc.b	' ',0,0,0,'-',$f0,'@',0
	dc.b	0,0,'-',$f0,'@',0,0,0
	dc.b	'-P@',0,0,0,'-P'
	dc.b	$80,0,0,0,'-P',$80,0
	dc.b	0,0,'-H',0,1,0,0
	dc.b	',',$a8,0,1,0,0,',',$a8
	dc.b	0,2,0,0,',',$a8,0,2
	dc.b	0,0,',',$a8,0,4,0,0
	dc.b	',',$a8,0,4,0,0,',',8
	dc.b	0,4,0,0,',',8,0,8
	dc.b	0,0,',',8,0,8,0,0
	dc.b	',',8,0,$10,0,0,'+h'
	dc.b	0,$10,0,0,'+h',0,' '
	dc.b	0,0,'+h',0,'@',0,0
	dc.b	'+h',0,'@',0,0,'+h'
	dc.b	0,$80,0,0,'*',$c8,0,$80
	dc.b	0,0,'*',$c8,1,0,0,0
	dc.b	'*',$c8,1,0,0,0,'*',$c8
	dc.b	2,0,0,0,'*',$c8,4,0
	dc.b	0,0,'*(',4,0,0,0
	dc.b	'*(',8,0,0,0,'*('
	dc.b	8,0,0,0,'*(',$10,0
	dc.b	0,0,'*( ',0,0,0
	dc.b	'*(',0,0,' ',0,')',$88
	dc.b	0,0,'@',0,')',$88,0,0
	dc.b	$80,0,')',$80,0,0,0,1
	dc.b	')',$80,0,0,0,1,')',$80
	dc.b	0,0,0,2,')',$80,0,0
	dc.b	0,4,')',$80,0,0,0,4
	dc.b	'(',$e0,0,0,0,8,'(',$e0
	dc.b	0,0,0,$10,'(',$e0,0,0
	dc.b	0,' (',$e0,0,0,0,'@'
	dc.b	'(',$e0,0,0,0,$80,'(',$e0
	dc.b	0,0,0,$80,'(',$e0,0,0
	dc.b	1,0,'(',$e0,0,0,2,0
	dc.b	'(',$e0,0,0,4,0,'(',$e0
	dc.b	0,0,8,0,'(',$e0,0,0
	dc.b	$10,0,'(@',0,0,' ',0
	dc.b	'(@',0,0,'@',0,'(@'
	dc.b	0,0,$80,0,'(8',0,0
	dc.b	0,1,'(8',0,0,0,2
	dc.b	'(8',0,0,0,4,'(8'
	dc.b	0,0,0,8,'(8',0,0
	dc.b	0,$10,'(8',0,0,0,'@'
	dc.b	'(8',0,0,0,$80,'(8'
	dc.b	0,0,1,0,'(8',0,0
	dc.b	2,0,'(8',0,0,8,0
	dc.b	'(',$d8,0,0,$10,0,'(',$d8
	dc.b	0,0,' ',0,'(',$d8,0,0
	dc.b	$80,0,'(',$d0,0,0,0,1
	dc.b	'(',$d0,0,0,0,4,'(',$d0
	dc.b	0,0,0,8,'(',$d0,0,0
	dc.b	0,' (',$d0,0,0,0,'@'
	dc.b	'(',$d0,1,0,1,0,')p'
	dc.b	4,0,4,0,')p',$10,0
	dc.b	$10,0,')p@',0,'@',0
	dc.b	')h',0,1,0,1,')h'
	dc.b	0,4,0,4,'*',8,0,$10
	dc.b	0,$10,'*',8,0,'@',0,'@'
	dc.b	'*',8,1,0,1,0,'*',$a8
	dc.b	8,0,8,0,'*',$a8,' ',0
	dc.b	' ',0,'*',$a0,0,1,0,1
	dc.b	'+@',0,8,0,8,'+@'
	dc.b	0,'@',0,'@+',$e0,2,0
	dc.b	2,0,'+',$e0,$10,0,$10,0
	dc.b	',x',0,1,0,1,',x'
	dc.b	0,8,0,8,'-',$18,0,$80
	dc.b	0,$80,'-',$b8,8,0,8,0
	dc.b	'-',$b0,0,1,0,1,'.P'
	dc.b	0,$10,0,$10,'.',$f0,2,0
	dc.b	2,0,'/',$90,$80,0,$80,0
	dc.b	'0(',0,' ',0,' 0',$c8
	dc.b	8,0,8,0,'2',0,0,4
	dc.b	0,4,'2',$a0,4,0,4,0
	dc.b	$ff,$ff,'7',$f8,2,0,0,0
	dc.b	'7X',2,0,0,0,'7X'
	dc.b	2,0,0,0,'6',$b8,2,0
	dc.b	0,0,'6',$b8,2,0,0,0
	dc.b	'6',$18,2,0,0,0,'6',$18
	dc.b	2,0,0,0,'5x',2,0
	dc.b	0,0,'5x',2,0,0,0
	dc.b	'5x',2,0,0,0,'4',$d8
	dc.b	2,0,0,0,'4',$d8,2,0
	dc.b	0,0,'48',2,0,0,0
	dc.b	'48',2,0,0,0,'3',$98
	dc.b	2,0,0,0,'3',$98,2,0
	dc.b	0,0,'2',$f8,2,0,0,0
	dc.b	'2',$f8,4,0,0,0,'2X'
	dc.b	4,0,0,0,'1',$b8,4,0
	dc.b	0,0,'1',$b8,4,0,0,0
	dc.b	'1',$18,4,0,0,0,'1',$18
	dc.b	4,0,0,0,'0x',4,0
	dc.b	0,0,'0x',4,0,0,0
	dc.b	'/',$d8,4,0,0,0,'/',$d8
	dc.b	8,0,0,0,'/8',8,0
	dc.b	0,0,'.',$98,8,0,0,0
	dc.b	'.',$98,8,0,0,0,'-',$f8
	dc.b	8,0,0,0,'-',$f8,$10,0
	dc.b	0,0,'-X',$10,0,0,0
	dc.b	',',$b8,$10,0,0,0,',',$b8
	dc.b	$10,0,0,0,',',$18,$10,0
	dc.b	0,0,',',$18,0,0,' ',0
	dc.b	'+x',0,0,' ',0,'*',$d8
	dc.b	0,0,' ',0,'*',$d8,0,0
	dc.b	'@',0,'*8',0,0,'@',0
	dc.b	')',$98,0,0,'@',0,')',$98
	dc.b	0,0,'@',0,'(',$f8,0,0
	dc.b	$80,0,'(X',0,0,$80,0
	dc.b	'(X',0,0,$80,0,$27,$b0
	dc.b	0,0,0,1,$27,$10,0,0
	dc.b	0,1,'&p',0,0,0,2
	dc.b	'&p',0,0,0,2,'%',$d0
	dc.b	0,0,0,2,'%0',0,0
	dc.b	0,4,'$',$90,0,0,0,4
	dc.b	'$',$90,0,0,0,8,'#',$f0
	dc.b	0,0,0,8,'#P',0,0
	dc.b	0,$10,'"',$b0,0,0,0,$10
	dc.b	'"',$10,0,0,0,' !p'
	dc.b	0,0,0,' !p',0,0
	dc.b	0,'@ ',$d0,0,0,0,$80
	dc.b	' 0',0,0,0,$80,$1f,$90
	dc.b	0,0,1,0,$1e,$f0,0,0
	dc.b	2,0,$1e,'P',0,0,2,0
	dc.b	$1d,$b0,0,0,4,0,$1d,$10
	dc.b	0,0,8,0,$1c,'p',0,0
	dc.b	$10,0,$1b,$d0,0,0,$10,0
	dc.b	$1b,'0',0,0,' ',0,$1a,$90
	dc.b	0,0,'@',0,$19,$f0,0,0
	dc.b	$80,0,$19,'H',0,0,0,1
	dc.b	$18,$a8,0,0,0,2,$17,'h'
	dc.b	0,0,0,4,$16,$c8,0,0
	dc.b	0,8,$16,'(',0,$10,0,$10
	dc.b	$15,$88,0,' ',0,' ',$14,'H'
	dc.b	0,'@',0,'@',$13,$a8,0,$80
	dc.b	0,$80,$12,'h',2,0,2,0
	dc.b	$11,$c8,4,0,4,0,$10,$88
	dc.b	8,0,8,0,$f,$e8,' ',0
	dc.b	' ',0,$e,$a8,'@',0,'@',0
	dc.b	$e,0,0,1,0,1,$c,$c0
	dc.b	0,4,0,4,$b,$80,0,$10
	dc.b	0,$10,$a,'@',0,' ',0,' '
	dc.b	9,0,0,$80,0,$80,7,$c0
	dc.b	2,0,2,0,6,$80,$10,0
	dc.b	$10,0,4,$a0,'@',0,'@',0
	dc.b	3,'X',0,1,0,1,1,'x'
	dc.b	0,8,0,8,0,'8',0,'@'
	dc.b	0,'@',$ff,$ff,'#H ',0
	dc.b	0,0,'#H@',0,0,0
	dc.b	'"',$a8,$80,0,0,0,'"',$a8
	dc.b	$80,0,0,0,'"',$a0,0,1
	dc.b	0,0,'"',$a0,0,2,0,0
	dc.b	'"',0,0,4,0,0,'"',0
	dc.b	0,8,0,0,'"',0,0,$10
	dc.b	0,0,'!`',0,' ',0,0
	dc.b	'!`',0,'@',0,0,'!`'
	dc.b	0,$80,0,0,'!`',1,0
	dc.b	0,0,' ',$c0,2,0,0,0
	dc.b	' ',$c0,4,0,0,0,' ',$c0
	dc.b	$10,0,0,0,' ',$c0,' ',0
	dc.b	0,0,'  @',0,0,0
	dc.b	'  ',$80,0,0,0,' ',$18
	dc.b	0,1,0,0,' ',$18,0,4
	dc.b	0,0,' ',$18,0,8,0,0
	dc.b	$1f,'x',0,$10,0,0,$1f,'x'
	dc.b	0,'@',0,0,$1f,'x',0,$80
	dc.b	0,0,$1f,'x',2,0,0,0
	dc.b	$1e,$d8,4,0,0,0,$1e,$d8
	dc.b	$10,0,0,0,$1e,$d8,' ',0
	dc.b	0,0,$1e,$d8,$80,0,0,0
	dc.b	$1e,$d0,0,2,0,0,$1e,$d0
	dc.b	0,4,0,0,$1e,'0',0,$10
	dc.b	0,0,$1e,'0',0,'@',0,0
	dc.b	$1e,'0',1,0,0,0,$1e,'0'
	dc.b	4,0,0,0,$1e,'0',0,0
	dc.b	$10,0,$1e,'0',0,0,'@',0
	dc.b	$1e,'(',0,0,0,1,$1e,'('
	dc.b	0,0,0,4,$1d,$88,0,0
	dc.b	0,' ',$1d,$88,0,0,0,$80
	dc.b	$1d,$88,0,0,4,0,$1d,$88
	dc.b	0,0,$10,0,$1d,$88,0,0
	dc.b	$80,0,$1d,$80,0,0,0,4
	dc.b	$1d,$80,0,0,0,' ',$1d,$80
	dc.b	0,0,1,0,$1d,$80,0,0
	dc.b	$10,0,$1d,$80,0,0,$80,0
	dc.b	$1d,'x',0,0,0,8,$1d,'x'
	dc.b	0,0,0,$80,$1d,'x',0,0
	dc.b	8,0,$1d,'x',0,0,$80,0
	dc.b	$1d,'p',0,0,0,8,$1d,'p'
	dc.b	0,0,1,0,$1d,'p',0,0
	dc.b	' ',0,$1d,'h',0,0,0,8
	dc.b	$1e,8,0,0,2,0,$1e,8
	dc.b	0,0,$80,0,$1e,0,0,0
	dc.b	0,'@',$1e,0,0,0,' ',0
	dc.b	$ff,$ff,'/',$c0,8,0,0,0
	dc.b	'0`',8,0,0,0,'0`'
	dc.b	$10,0,0,0,'0` ',0
	dc.b	0,0,'0`@',0,0,0
	dc.b	'0`',$80,0,0,0,'0X'
	dc.b	0,1,0,0,'0X',0,1
	dc.b	0,0,'0X',0,2,0,0
	dc.b	'0',$f8,0,4,0,0,'0',$f8
	dc.b	0,8,0,0,'0',$f8,0,$10
	dc.b	0,0,'0',$f8,0,' ',0,0
	dc.b	'0',$f8,0,'@',0,0,'1',$98
	dc.b	0,$80,0,0,'1',$98,1,0
	dc.b	0,0,'1',$98,4,0,0,0
	dc.b	'1',$98,8,0,0,0,'28'
	dc.b	$10,0,0,0,'28 ',0
	dc.b	0,0,'28@',0,0,0
	dc.b	'2',$d0,0,1,0,0,'2',$d0
	dc.b	0,2,0,0,'2',$d0,0,8
	dc.b	0,0,'3p',0,$10,0,0
	dc.b	'3p',0,'@',0,0,'4',$10
	dc.b	0,$80,0,0,'4',$10,2,0
	dc.b	0,0,'4',$b0,8,0,0,0
	dc.b	'4',$b0,$10,0,0,0,'5P'
	dc.b	'@',0,0,0,'5H',0,1
	dc.b	0,0,'5',$e8,0,4,0,0
	dc.b	'6',$88,0,' ',0,0,'6',$88
	dc.b	0,$80,0,0,'7(',2,0
	dc.b	0,0,'7',$c8,0,0,$10,0
	dc.b	'8h',0,0,'@',0,'9',0
	dc.b	0,0,0,2,'9',$a0,0,0
	dc.b	0,$10,':@',0,0,1,0
	dc.b	':',$e0,0,0,8,0,';',$80
	dc.b	0,0,$80,0,'<',$b8,0,0
	dc.b	0,8,'=X',0,0,0,$80
	dc.b	'>',$98,0,0,$10,0,'?',$d0
	dc.b	0,0,0,2,'A',$10,0,0
	dc.b	0,$80,'BP',0,0,' ',0
	dc.b	'C',$88,0,0,0,$10,'Eh'
	dc.b	0,0,$10,0,'G@',0,0
	dc.b	0,$10,'I',$c0,0,0,'@',0
	dc.b	$ff,$ff,'1',8,8,0,0,0
	dc.b	'1',8,8,0,0,0,'1',8
	dc.b	$10,0,0,0,'1',8,$10,0
	dc.b	0,0,'1',8,' ',0,0,0
	dc.b	'1',8,' ',0,0,0,'1',8
	dc.b	'@',0,0,0,'1',8,'@',0
	dc.b	0,0,'1',8,$80,0,0,0
	dc.b	'1',8,$80,0,0,0,'1',0
	dc.b	0,1,0,0,'1',0,0,1
	dc.b	0,0,'1',0,0,2,0,0
	dc.b	'1',0,0,2,0,0,'1',0
	dc.b	0,4,0,0,'1',0,0,4
	dc.b	0,0,'1',$a0,0,8,0,0
	dc.b	'1',$a0,0,8,0,0,'1',$a0
	dc.b	0,$10,0,0,'1',$a0,0,$10
	dc.b	0,0,'1',$a0,0,' ',0,0
	dc.b	'1',$a0,0,' ',0,0,'1',$a0
	dc.b	0,'@',0,0,'1',$a0,0,'@'
	dc.b	0,0,'2@',0,$80,0,0
	dc.b	'2@',1,0,0,0,'2@'
	dc.b	1,0,0,0,'2@',2,0
	dc.b	0,0,'2@',2,0,0,0
	dc.b	'2@',4,0,0,0,'2',$e0
	dc.b	4,0,0,0,'2',$e0,8,0
	dc.b	0,0,'2',$e0,$10,0,0,0
	dc.b	'2',$e0,$10,0,0,0,'3',$80
	dc.b	' ',0,0,0,'3',$80,'@',0
	dc.b	0,0,'3',$80,0,0,'@',0
	dc.b	'3',$80,0,0,$80,0,'4 '
	dc.b	0,0,$80,0,'4',$18,0,0
	dc.b	0,1,'4',$18,0,0,0,2
	dc.b	'4',$b8,0,0,0,2,'4',$b8
	dc.b	0,0,0,4,'4',$b8,0,0
	dc.b	0,8,'5X',0,0,0,$10
	dc.b	'5X',0,0,0,$10,'5X'
	dc.b	0,0,0,' 5',$f8,0,0
	dc.b	0,'@5',$f8,0,0,0,$80
	dc.b	'6',$98,0,0,0,$80,'6',$98
	dc.b	0,0,1,0,'78',0,0
	dc.b	2,0,'78',0,0,4,0
	dc.b	'7',$d8,0,0,8,0,'7',$d8
	dc.b	0,0,8,0,'8x',0,0
	dc.b	$10,0,'8x',0,0,' ',0
	dc.b	'9',$18,0,0,'@',0,'9',$18
	dc.b	0,0,$80,0,'9',$b0,0,0
	dc.b	0,1,':P',0,0,0,2
	dc.b	':P',0,0,0,4,':',$f0
	dc.b	0,0,0,8,';',$90,0,0
	dc.b	0,$10,';',$90,0,0,0,' '
	dc.b	'<0',0,0,0,'@<',$d0
	dc.b	0,0,0,$80,'=p',0,0
	dc.b	1,0,'>',$10,0,0,2,0
	dc.b	'>',$b0,0,0,4,0,'?P'
	dc.b	0,0,$10,0,'?',$f0,0,0
	dc.b	' ',0,'@',$90,0,0,'@',0
	dc.b	'A0',0,0,$80,0,'A',$c8
	dc.b	0,0,0,2,'Bh',0,0
	dc.b	0,4,'C',8,0,$10,0,$10
	dc.b	'C',$a8,0,' ',0,' D',$e8
	dc.b	0,$80,0,$80,'E',$88,1,0
	dc.b	1,0,'F',$c8,4,0,4,0
	dc.b	'Gh',$10,0,$10,0,'H',$a8
	dc.b	'@',0,'@',0,'I',$e0,0,1
	dc.b	0,1,'J',$80,0,4,0,4
	dc.b	'K',$c0,0,$10,0,$10,'M',0
	dc.b	0,'@',0,'@N',$e0,1,0
	dc.b	1,0,'P ',8,0,8,0
	dc.b	'Q`@',0,'@',0,'S8'
	dc.b	0,1,0,1,'U',$18,0,8
	dc.b	0,8,'V',$f8,0,$80,0,$80
	dc.b	'X',$d8,4,0,4,0,'Z',$b8
	dc.b	'@',0,'@',0,']0',0,4
	dc.b	0,4,'_',$b0,0,'@',0,'@'
	dc.b	'b',$d0,8,0,8,0,'e',$e8
	dc.b	0,1,0,1,'i',8,0,' '
	dc.b	0,' l',$c8,8,0,8,0
	dc.b	'q ',0,4,0,4,'u',$80
	dc.b	4,0,4,0,$ff,$ff,'1',$10
	dc.b	0,' ',0,0,'0p',0,' '
	dc.b	0,0,'0p',0,' ',0,0
	dc.b	'0p',0,' ',0,0,'/',$d0
	dc.b	0,'@',0,0,'/',$d0,0,'@'
	dc.b	0,0,'/',$d0,0,'@',0,0
	dc.b	'/0',0,$80,0,0,'/0'
	dc.b	0,$80,0,0,'.',$90,0,$80
	dc.b	0,0,'.',$90,0,$80,0,0
	dc.b	'.',$90,1,0,0,0,'-',$f0
	dc.b	1,0,0,0,'-',$f0,2,0
	dc.b	0,0,'-',$f0,2,0,0,0
	dc.b	'-P',2,0,0,0,'-P'
	dc.b	4,0,0,0,'-P',4,0
	dc.b	0,0,',',$b0,4,0,0,0
	dc.b	',',$b0,8,0,0,0,',',$b0
	dc.b	8,0,0,0,',',$10,$10,0
	dc.b	0,0,',',$10,$10,0,0,0
	dc.b	',',$10,$10,0,0,0,'+p'
	dc.b	' ',0,0,0,'+p ',0
	dc.b	0,0,'*',$d0,'@',0,0,0
	dc.b	'*',$d0,'@',0,0,0,'*',$d0
	dc.b	$80,0,0,0,'*0',$80,0
	dc.b	0,0,'*(',0,1,0,0
	dc.b	'*(',0,1,0,0,')',$88
	dc.b	0,2,0,0,')',$88,0,2
	dc.b	0,0,')',$88,0,4,0,0
	dc.b	'(',$e8,0,4,0,0,'(',$e8
	dc.b	0,0,0,8,'(',$e8,0,0
	dc.b	0,$10,'(H',0,0,0,$10
	dc.b	'(H',0,0,0,' (H'
	dc.b	0,0,0,'@',$27,$a8,0,0
	dc.b	0,'@',$27,$a8,0,0,0,$80
	dc.b	$27,$a8,0,0,0,$80,$27,8
	dc.b	0,0,1,0,$27,8,0,0
	dc.b	2,0,$27,8,0,0,4,0
	dc.b	'&h',0,0,4,0,'&h'
	dc.b	0,0,8,0,'%',$c8,0,0
	dc.b	$10,0,'%',$c8,0,0,' ',0
	dc.b	'%',$c8,0,0,' ',0,'%('
	dc.b	0,0,'@',0,'%(',0,0
	dc.b	$80,0,'% ',0,0,0,1
	dc.b	'$',$80,0,0,0,2,'$',$80
	dc.b	0,0,0,4,'$',$80,0,0
	dc.b	0,8,'#',$e0,0,0,0,$10
	dc.b	'#',$e0,0,0,0,' #',$e0
	dc.b	0,0,0,'@#@',0,0
	dc.b	0,$80,'#@',0,0,1,0
	dc.b	'#@',0,0,2,0,'"',$a0
	dc.b	0,0,4,0,'"',$a0,0,0
	dc.b	8,0,'"',$a0,0,0,' ',0
	dc.b	'"',0,0,0,'@',0,'"',0
	dc.b	0,0,$80,0,'!',$f8,0,0
	dc.b	0,1,'!X',0,0,0,4
	dc.b	'!X',0,0,0,8,' ',$b8
	dc.b	0,0,0,'  ',$b8,0,0
	dc.b	0,'@ ',$b8,0,0,1,0
	dc.b	' ',$18,0,0,2,0,' ',$18
	dc.b	8,0,8,0,' ',$18,' ',0
	dc.b	' ',0,$1f,'x',$80,0,$80,0
	dc.b	$1f,'p',0,2,0,2,$1e,$d0
	dc.b	0,4,0,4,$1e,$d0,0,' '
	dc.b	0,' ',$1e,$d0,0,$80,0,$80
	dc.b	$1e,'0',2,0,2,0,$1e,'0'
	dc.b	8,0,8,0,$1d,$90,'@',0
	dc.b	'@',0,$1d,$88,0,1,0,1
	dc.b	$1c,$e8,0,8,0,8,$1c,$e8
	dc.b	0,'@',0,'@',$1c,'H',2,0
	dc.b	2,0,$1c,'H',$10,0,$10,0
	dc.b	$1b,$a0,0,1,0,1,$1b,$a0
	dc.b	0,8,0,8,$1b,0,0,$80
	dc.b	0,$80,$1a,'`',8,0,8,0
	dc.b	$1a,'`',$80,0,$80,0,$19,$b8
	dc.b	0,$10,0,$10,$19,$18,2,0
	dc.b	2,0,$19,$18,$80,0,$80,0
	dc.b	$18,'p',0,' ',0,' ',$17,$d0
	dc.b	8,0,8,0,$17,'(',0,4
	dc.b	0,4,$16,$88,4,0,4,0
	dc.b	$15,$e0,0,4,0,4,$15,'@'
	dc.b	$10,0,$10,0,$ff,$ff,'M',$d8
	dc.b	2,0,0,0,'M',$d8,2,0
	dc.b	0,0,'M',$d8,1,0,0,0
	dc.b	'M',$d8,0,$80,0,0,'M',$d8
	dc.b	0,$80,0,0,'M',$d8,0,'@'
	dc.b	0,0,'M',$d8,0,' ',0,0
	dc.b	'M',$d8,0,$10,0,0,'M',$d8
	dc.b	0,$10,0,0,'M8',0,8
	dc.b	0,0,'M8',0,4,0,0
	dc.b	'M8',0,2,0,0,'M8'
	dc.b	0,1,0,0,'M8',0,1
	dc.b	0,0,'M@',$80,0,0,0
	dc.b	'M@@',0,0,0,'L',$a0
	dc.b	' ',0,0,0,'L',$a0,$10,0
	dc.b	0,0,'L',$a0,8,0,0,0
	dc.b	'L',$a0,4,0,0,0,'L',$a0
	dc.b	2,0,0,0,'L',0,1,0
	dc.b	0,0,'L',0,0,$80,0,0
	dc.b	'L',0,0,'@',0,0,'L',0
	dc.b	0,' ',0,0,'K`',0,$10
	dc.b	0,0,'K`',0,8,0,0
	dc.b	'K`',0,2,0,0,'J',$c0
	dc.b	0,1,0,0,'J',$c8,$80,0
	dc.b	0,0,'J',$c8,'@',0,0,0
	dc.b	'J(',$10,0,0,0,'J('
	dc.b	8,0,0,0,'I',$88,4,0
	dc.b	0,0,'I',$88,1,0,0,0
	dc.b	'H',$e8,0,$80,0,0,'H',$e8
	dc.b	0,0,0,' HH',0,0
	dc.b	0,8,'HH',0,0,0,4
	dc.b	'G',$a8,0,0,0,1,'G',$10
	dc.b	0,0,'@',0,'G',$10,0,0
	dc.b	$10,0,'Fp',0,0,4,0
	dc.b	'E',$d0,0,0,1,0,'E0'
	dc.b	0,0,0,'@D',$90,0,0
	dc.b	0,8,'D',$90,0,0,0,2
	dc.b	'C',$f8,0,0,'@',0,'B',$b8
	dc.b	0,0,$10,0,'B',$18,0,0
	dc.b	2,0,'Ax',0,0,0,'@'
	dc.b	'@',$d8,0,0,0,8,'?',$a0
	dc.b	0,0,$80,0,'?',0,0,0
	dc.b	8,0,'=',$c0,0,0,0,$80
	dc.b	'= ',0,0,0,8,';',$e8
	dc.b	0,0,$80,0,':',$a8,0,0
	dc.b	4,0,'8',$c8,0,0,0,$10
	dc.b	'7',$90,0,0,'@',0,'5',$b0
	dc.b	0,0,1,0,'3',$d0,0,0
	dc.b	0,2,'1',$f8,0,0,2,0
	dc.b	'/x',0,0,0,1,$ff,$ff
	dc.b	'8',$80,0,' ',0,0,'9 '
	dc.b	0,' ',0,0,'9 ',0,'@'
	dc.b	0,0,'9 ',0,'@',0,0
	dc.b	'9 ',0,'@',0,0,'9',$c0
	dc.b	0,'@',0,0,'9',$c0,0,$80
	dc.b	0,0,'9',$c0,0,$80,0,0
	dc.b	':`',0,$80,0,0,':`'
	dc.b	1,0,0,0,':`',1,0
	dc.b	0,0,';',0,1,0,0,0
	dc.b	';',0,2,0,0,0,';',0
	dc.b	2,0,0,0,';',$a0,2,0
	dc.b	0,0,';',$a0,4,0,0,0
	dc.b	';',$a0,4,0,0,0,'<@'
	dc.b	4,0,0,0,'<@',8,0
	dc.b	0,0,'<',$e0,8,0,0,0
	dc.b	'<',$e0,8,0,0,0,'<',$e0
	dc.b	8,0,0,0,'=',$80,$10,0
	dc.b	0,0,'=',$80,$10,0,0,0
	dc.b	'> ',$10,0,0,0,'> '
	dc.b	' ',0,0,0,'>',$c0,' ',0
	dc.b	0,0,'>',$c0,' ',0,0,0
	dc.b	'?`@',0,0,0,'?`'
	dc.b	'@',0,0,0,'@',0,'@',0
	dc.b	0,0,'@',0,$80,0,0,0
	dc.b	'@',$a0,$80,0,0,0,'@',$a0
	dc.b	$80,0,0,0,'A@',$80,0
	dc.b	0,0,'A8',0,1,0,0
	dc.b	'A',$d8,0,0,0,1,'A',$d8
	dc.b	0,0,0,1,'Bx',0,0
	dc.b	0,2,'C',$18,0,0,0,2
	dc.b	'C',$18,0,0,0,2,'C',$b8
	dc.b	0,0,0,2,'C',$b8,0,0
	dc.b	0,4,'DX',0,0,0,4
	dc.b	'D',$f8,0,0,0,4,'D',$f8
	dc.b	0,0,0,8,'E',$98,0,0
	dc.b	0,8,'F8',0,0,0,8
	dc.b	'F',$d8,0,0,0,8,'F',$d8
	dc.b	0,0,0,$10,'Gx',0,0
	dc.b	0,$10,'H',$18,0,0,0,$10
	dc.b	'H',$b8,0,0,0,' IX'
	dc.b	0,0,0,' IX',0,0
	dc.b	0,' I',$f8,0,0,0,' '
	dc.b	'J',$98,0,0,0,'@K8'
	dc.b	0,0,0,'@K',$d8,0,0
	dc.b	0,'@Lx',0,0,0,'@'
	dc.b	'M',$18,0,0,0,$80,'M',$b8
	dc.b	0,0,0,$80
	unlk	a0
	ori.b	#$80,d0
	jmp	0.w
	dc.b	0,$80,'O',$98,0,0,1,0
	dc.b	'P8',0,0,1,0,'P',$d8
	dc.b	0,0,1,0,'R',$18,0,0
	dc.b	2,0,'R',$b8,0,0,2,0
	dc.b	'SX',0,0,2,0,'S',$f8
	dc.b	0,0,2,0,'U8',0,0
	dc.b	4,0,'U',$d8,0,0,4,0
	dc.b	'Vx',0,0,4,0,'W',$b8
	dc.b	0,0,4,0,'XX',0,0
	dc.b	8,0,'Y',$98,8,0,8,0
	dc.b	'Z',$d8,8,0,8,0,'[x'
	dc.b	8,0,8,0,'\',$b8,$10,0
	dc.b	$10,0,']',$f8,$10,0,$10,0
	dc.b	'_8',$10,0,$10,0,'`x'
	dc.b	$10,0,$10,0,'a',$b8,' ',0
	dc.b	' ',0,'b',$f8,' ',0,' ',0
	dc.b	'd',$d8,' ',0,' ',0,'f',$18
	dc.b	' ',0,' ',0,'g',$f8,'@',0
	dc.b	'@',0,'i8@',0,'@',0
	dc.b	'k',$18,'@',0,'@',0,'l',$f8
	dc.b	'@',0,'@',0,'n',$d8,$80,0
	dc.b	$80,0,'p',$b8,$80,0,$80,0
	dc.b	's8',$80,0,$80,0,'u',$b0
	dc.b	0,1,0,1,'x0',0,1
	dc.b	0,1,'z',$b0,0,1,0,1
	dc.b	$ff,$ff,'=',$90,1,0,0,0
	dc.b	'=',$90,1,0,0,0,'=',$90
	dc.b	1,0,0,0,'=',$90,1,0
	dc.b	0,0,'<',$f0,1,0,0,0
	dc.b	'<',$f0,1,0,0,0,'<',$f0
	dc.b	1,0,0,0,'<',$f0,1,0
	dc.b	0,0,'<',$f0,1,0,0,0
	dc.b	'<',$f0,1,0,0,0,'<',$f0
	dc.b	1,0,0,0,'<P',1,0
	dc.b	0,0,'<P',1,0,0,0
	dc.b	'<P',1,0,0,0,'<P'
	dc.b	1,0,0,0,'<P',1,0
	dc.b	0,0,'<P',1,0,0,0
	dc.b	';',$b0,1,0,0,0,';',$b0
	dc.b	1,0,0,0,';',$b0,1,0
	dc.b	0,0,';',$b0,1,0,0,0
	dc.b	';',$b0,1,0,0,0,';',$b0
	dc.b	1,0,0,0,';',$10,1,0
	dc.b	0,0,';',$10,1,0,0,0
	dc.b	';',$10,1,0,0,0,';',$10
	dc.b	1,0,0,0,';',$10,1,0
	dc.b	0,0,';',$10,1,0,0,0
	dc.b	':p',1,0,0,0,':p'
	dc.b	1,0,0,0,':p',1,0
	dc.b	0,0,':p',1,0,0,0
	dc.b	':p',1,0,0,0,':p'
	dc.b	1,0,0,0,'9',$d0,1,0
	dc.b	0,0,'9',$d0,0,0,1,0
	dc.b	'9',$d0,0,0,1,0,'9',$d0
	dc.b	0,0,1,0,'9',$d0,0,0
	dc.b	1,0,'90',0,0,1,0
	dc.b	'90',0,0,1,0,'90'
	dc.b	0,0,1,0,'90',0,0
	dc.b	1,0,'90',0,0,1,0
	dc.b	'8',$90,0,0,1,0,'8',$90
	dc.b	0,0,1,0,'8',$90,0,0
	dc.b	1,0,'8',$90,0,0,2,0
	dc.b	'7',$f0,0,0,2,0,'7',$f0
	dc.b	0,0,2,0,'7',$f0,0,0
	dc.b	2,0,'7',$f0,0,0,2,0
	dc.b	'7',$f0,0,0,2,0,'7P'
	dc.b	0,0,2,0,'7P',0,0
	dc.b	2,0,'7P',0,0,2,0
	dc.b	'7P',0,0,2,0,'6',$b0
	dc.b	0,0,4,0,'6',$b0,0,0
	dc.b	4,0,'6',$b0,0,0,4,0
	dc.b	'6',$b0,0,0,4,0,'6',$10
	dc.b	0,0,4,0,'6',$10,0,0
	dc.b	4,0,'6',$10,0,0,4,0
	dc.b	'6',$10,0,0,4,0,'5p'
	dc.b	0,0,8,0,'5p',0,0
	dc.b	8,0,'5p',0,0,8,0
	dc.b	'4',$d0,0,0,8,0,'4',$d0
	dc.b	0,0,8,0,'4',$d0,0,0
	dc.b	8,0,'4',$d0,0,0,$10,0
	dc.b	'40',0,0,$10,0,'40'
	dc.b	0,0,$10,0,'40',0,0
	dc.b	$10,0,'3',$90,$10,0,$10,0
	dc.b	'3',$90,' ',0,' ',0,'3',$90
	dc.b	' ',0,' ',0,'2',$f0,' ',0
	dc.b	' ',0,'2',$f0,' ',0,' ',0
	dc.b	'2',$f0,'@',0,'@',0,'2P'
	dc.b	'@',0,'@',0,'2P@',0
	dc.b	'@',0,'1',$b0,'@',0,'@',0
	dc.b	'1',$b0,$80,0,$80,0,'1',$b0
	dc.b	$80,0,$80,0,'1',$10,$80,0
	dc.b	$80,0,'1',8,0,1,0,1
	dc.b	'0h',0,1,0,1,'0h'
	dc.b	0,1,0,1,'/',$c8,0,2
	dc.b	0,2,'/',$c8,0,2,0,2
	dc.b	'/(',0,4,0,4,'/('
	dc.b	0,4,0,4,'.',$88,0,8
	dc.b	0,8,'.',$88,0,8,0,8
	dc.b	'-',$e8,0,$10,0,$10,'-',$e8
	dc.b	0,$10,0,$10,'-H',0,' '
	dc.b	0,' ,',$a8,0,' ',0,' '
	dc.b	',',$a8,0,'@',0,'@,',8
	dc.b	0,$80,0,$80,'+h',0,$80
	dc.b	0,$80,'*',$c8,1,0,1,0
	dc.b	'*(',2,0,2,0,'*('
	dc.b	2,0,2,0,')',$88,4,0
	dc.b	4,0,'(',$e8,8,0,8,0
	dc.b	'(H',$10,0,$10,0,$27,$a8
	dc.b	' ',0,' ',0,'&h@',0
	dc.b	'@',0,'%',$c0,0,1,0,1
	dc.b	'% ',0,2,0,2,'#',$e0
	dc.b	0,4,0,4,'#@',0,$10
	dc.b	0,$10,'"',0,0,'@',0,'@'
	dc.b	' ',$c0,0,$80,0,$80,$1f,$80
	dc.b	2,0,2,0,$1e,'@',$10,0
	dc.b	$10,0,$1c,'`@',0,'@',0
	dc.b	$1a,'x',0,2,0,2,$18,$98
	dc.b	0,$10,0,$10,$16,$b8,1,0
	dc.b	1,0,$13,$98,$10,0,$10,0
	dc.b	$11,$10,0,2,0,2,$d,'P'
	dc.b	0,'@',0,'@',8,$f0,' ',0
	dc.b	' ',0,3,$e8,0,' ',0,' '
	dc.b	$ff,$ff,'Ip',0,4,0,0
	dc.b	'Ip',0,2,0,0,'Ip'
	dc.b	0,2,0,0,'Ip',0,1
	dc.b	0,0,'Ip',0,1,0,0
	dc.b	'Ix',$80,0,0,0,'Ix'
	dc.b	$80,0,0,0,'Ix@',0
	dc.b	0,0,'Ix@',0,0,0
	dc.b	'Ix ',0,0,0,'Ix'
	dc.b	$10,0,0,0,'Ix',$10,0
	dc.b	0,0,'Ix',8,0,0,0
	dc.b	'Ix',4,0,0,0,'Ix'
	dc.b	4,0,0,0,'Ix',2,0
	dc.b	0,0,'Ix',1,0,0,0
	dc.b	'Ix',1,0,0,0,'Ix'
	dc.b	0,$80,0,0,'Ix',0,'@'
	dc.b	0,0,'Ix',0,' ',0,0
	dc.b	'Ix',0,$10,0,0,'Ix'
	dc.b	0,8,0,0,'Ix',0,4
	dc.b	0,0,'Ix',0,2,0,0
	dc.b	'Ix',0,1,0,0,'I',$80
	dc.b	$80,0,0,0,'H',$e0,'@',0
	dc.b	0,0,'H',$e0,' ',0,0,0
	dc.b	'H',$e0,$10,0,0,0,'H',$e0
	dc.b	8,0,0,0,'H',$e0,2,0
	dc.b	0,0,'H',$e0,1,0,0,0
	dc.b	'H',$e0,0,'@',0,0,'H',$e0
	dc.b	0,' ',0,0,'H',$e0,0,8
	dc.b	0,0,'H@',0,0,0,2
	dc.b	'HH',0,0,$80,0,'HH'
	dc.b	0,0,' ',0,'HH',0,0
	dc.b	8,0,'G',$a8,0,0,2,0
	dc.b	'G',$a8,0,0,0,'@G',$a8
	dc.b	0,0,0,$10,'G',$a8,0,0
	dc.b	0,2,'G',$10,0,0,' ',0
	dc.b	'G',$10,0,0,4,0,'Fp'
	dc.b	0,0,0,'@Fp',0,0
	dc.b	0,4,'E',$d8,0,0,' ',0
	dc.b	'E',$d8,0,0,1,0,'E8'
	dc.b	0,0,0,4,'D',$a0,0,0
	dc.b	8,0,'D',0,0,0,0,8
	dc.b	'Ch',0,0,4,0,'B',$d0
	dc.b	0,0,$80,0,'A',$90,0,0
	dc.b	0,8,'@X',0,0,0,8
	dc.b	$ff,$ff,'1',$10,0,8,0,0
	dc.b	'0p',0,8,0,0,'0p'
	dc.b	0,8,0,0,'/',$d0,0,8
	dc.b	0,0,'/',$d0,0,8,0,0
	dc.b	'/0',0,$10,0,0,'/0'
	dc.b	0,$10,0,0,'.',$90,0,$10
	dc.b	0,0,'.',$90,0,$10,0,0
	dc.b	'-',$f0,0,' ',0,0,'-',$f0
	dc.b	0,' ',0,0,'-P',0,' '
	dc.b	0,0,'-P',0,' ',0,0
	dc.b	',',$b0,0,'@',0,0,',',$b0
	dc.b	0,'@',0,0,',',$10,0,'@'
	dc.b	0,0,',',$10,0,$80,0,0
	dc.b	'+p',0,$80,0,0,'*',$d0
	dc.b	0,$80,0,0,'*',$d0,1,0
	dc.b	0,0,'*0',1,0,0,0
	dc.b	'*0',2,0,0,0,')',$90
	dc.b	2,0,0,0,'(',$f0,2,0
	dc.b	0,0,'(',$f0,4,0,0,0
	dc.b	'(P',4,0,0,0,$27,$b0
	dc.b	8,0,0,0,$27,$b0,8,0
	dc.b	0,0,$27,$10,$10,0,0,0
	dc.b	'&p',$10,0,0,0,'&p'
	dc.b	' ',0,0,0,'%',$d0,'@',0
	dc.b	0,0,'%0@',0,0,0
	dc.b	'$',$90,$80,0,0,0,'$',$90
	dc.b	$80,0,0,0,'#',$e8,0,1
	dc.b	0,0,'#H',0,0,0,2
	dc.b	'"',$a8,0,0,0,4,'"',8
	dc.b	0,0,0,4,'!h',0,0
	dc.b	0,8,' ',$c8,0,0,0,$10
	dc.b	' (',0,0,0,' ',$1f,$88
	dc.b	0,0,0,'@',$1e,$e8,0,0
	dc.b	0,$80,$1e,'H',0,0,0,$80
	dc.b	$1d,$a8,0,0,2,0,$1d,8
	dc.b	0,0,4,0,$1c,'h',0,0
	dc.b	8,0,$1b,$c8,0,0,$10,0
	dc.b	$1a,$88,0,0,' ',0,$19,$e8
	dc.b	0,0,'@',0,$19,'@',0,0
	dc.b	0,1,$18,0,0,0,0,2
	dc.b	$17,'`',0,0,0,8,$16,' '
	dc.b	0,0,0,$10,$14,$e0,0,0
	dc.b	0,'@',$14,'@',0,0,1,0
	dc.b	$13,0,0,0,4,0,$11,$c0
	dc.b	0,0,$10,0,$10,$80,0,0
	dc.b	'@',0,$e,$98,0,0,0,1
	dc.b	$d,'X',0,0,0,8,$b,'x'
	dc.b	0,0,0,'@',9,$98,0,0
	dc.b	2,0,7,$b8,0,0,$10,0
	dc.b	5,$d8,0,0,$80,0,3,'P'
	dc.b	0,0,0,8,0,$d0,0,0
	dc.b	0,$80,$ff,$ff,'0p',1,0
	dc.b	0,0,'0p',1,0,0,0
	dc.b	'0p',2,0,0,0,'0p'
	dc.b	2,0,0,0,'/',$d0,2,0
	dc.b	0,0,'/',$d0,4,0,0,0
	dc.b	'/',$d0,4,0,0,0,'/',$d0
	dc.b	4,0,0,0,'/0',8,0
	dc.b	0,0,'/0',8,0,0,0
	dc.b	'/0',8,0,0,0,'/0'
	dc.b	$10,0,0,0,'.',$90,$10,0
	dc.b	0,0,'.',$90,$10,0,0,0
	dc.b	'.',$90,' ',0,0,0,'.',$90
	dc.b	' ',0,0,0,'-',$f0,'@',0
	dc.b	0,0,'-',$f0,'@',0,0,0
	dc.b	'-',$f0,'@',0,0,0,'-',$f0
	dc.b	$80,0,0,0,'-P',$80,0
	dc.b	0,0,'-H',0,1,0,0
	dc.b	'-H',0,1,0,0,'-H'
	dc.b	0,2,0,0,',',$a8,0,2
	dc.b	0,0,',',$a8,0,2,0,0
	dc.b	',',$a8,0,4,0,0,',',$a8
	dc.b	0,4,0,0,',',$a8,0,8
	dc.b	0,0,',',8,0,8,0,0
	dc.b	',',8,0,$10,0,0,',',8
	dc.b	0,$10,0,0,',',8,0,' '
	dc.b	0,0,',',8,0,' ',0,0
	dc.b	',',8,0,'@',0,0,'+h'
	dc.b	0,'@',0,0,'+h',0,0
	dc.b	0,$80,'+h',0,0,1,0
	dc.b	'+h',0,0,1,0,'+h'
	dc.b	0,0,2,0,'+h',0,0
	dc.b	2,0,'*',$c8,0,0,4,0
	dc.b	'*',$c8,0,0,4,0,'*',$c8
	dc.b	0,0,8,0,'*',$c8,0,0
	dc.b	$10,0,'*',$c8,0,0,$10,0
	dc.b	'*',$c8,0,0,' ',0,'*',$c8
	dc.b	0,0,'@',0,'*(',0,0
	dc.b	'@',0,'*(',0,0,$80,0
	dc.b	'* ',0,0,0,1,'* '
	dc.b	0,0,0,1,'* ',0,0
	dc.b	0,2,'* ',0,0,0,4
	dc.b	'* ',0,0,0,4,'* '
	dc.b	0,0,0,8,'* ',0,0
	dc.b	0,$10,'* ',0,0,0,' '
	dc.b	'* ',0,0,0,' * '
	dc.b	0,0,0,'@* ',0,0
	dc.b	0,$80,')',$80,0,0,1,0
	dc.b	')',$80,0,0,2,0,')',$80
	dc.b	0,0,4,0,')',$80,0,0
	dc.b	4,0,')',$80,0,0,8,0
	dc.b	')',$80,0,0,$10,0,')',$80
	dc.b	0,0,' ',0,')',$80,0,0
	dc.b	'@',0,')',$80,0,0,$80,0
	dc.b	'*',$18,0,0,0,1,'*',$18
	dc.b	0,0,0,2,'*',$18,0,0
	dc.b	0,4,'*',$18,0,0,0,8
	dc.b	'*',$18,0,0,0,$10,'*',$18
	dc.b	0,0,0,' *',$18,0,'@'
	dc.b	0,'@*',$18,0,$80,0,$80
	dc.b	'*',$18,1,0,1,0,'*',$18
	dc.b	4,0,4,0,'*',$18,8,0
	dc.b	8,0,'*',$b8,$10,0,$10,0
	dc.b	'*',$b8,' ',0,' ',0,'*',$b8
	dc.b	$80,0,$80,0,'*',$b0,0,1
	dc.b	0,1,'*',$b0,0,2,0,2
	dc.b	'+P',0,8,0,8,'+P'
	dc.b	0,$10,0,$10,'+P',0,' '
	dc.b	0,' +P',0,$80,0,$80
	dc.b	'+',$f0,2,0,2,0,'+',$f0
	dc.b	4,0,4,0,'+',$f0,$10,0
	dc.b	$10,0,',',$90,'@',0,'@',0
	dc.b	',',$90,$80,0,$80,0,'-('
	dc.b	0,2,0,2,'-(',0,8
	dc.b	0,8,'-',$c8,0,' ',0,' '
	dc.b	'-',$c8,0,$80,0,$80,'.h'
	dc.b	2,0,2,0,'.h',8,0
	dc.b	8,0,'/',8,'@',0,'@',0
	dc.b	'/',0,0,1,0,1,'/',$a0
	dc.b	0,8,0,8,'0@',0,' '
	dc.b	0,' 0@',1,0,1,0
	dc.b	'0',$e0,8,0,8,0,'1',$80
	dc.b	'@',0,'@',0,'2',$18,0,2
	dc.b	0,2,'2',$b8,0,$10,0,$10
	dc.b	'3X',1,0,1,0,'3',$f8
	dc.b	$10,0,$10,0,'4',$90,0,1
	dc.b	0,1,'5',$d0,0,$10,0,$10
	dc.b	'6p',1,0,1,0,'7',$10
	dc.b	' ',0,' ',0,'8H',0,4
	dc.b	0,4,'9',$88,1,0,1,0
	dc.b	':',$c8,'@',0,'@',0,'<',0
	dc.b	0,' ',0,' =@',$10,0
	dc.b	$10,0,$ff,$ff,'C',$c0,0,1
	dc.b	0,0,'D`',0,1,0,0
	dc.b	'D`',0,1,0,0,'D`'
	dc.b	0,1,0,0,'E',0,0,1
	dc.b	0,0,'E',0,0,1,0,0
	dc.b	'E',0,0,1,0,0,'E',$a0
	dc.b	0,1,0,0,'E',$a0,0,1
	dc.b	0,0,'F@',0,1,0,0
	dc.b	'F@',0,1,0,0,'F@'
	dc.b	0,1,0,0,'F',$e8,$80,0
	dc.b	0,0,'F',$e8,$80,0,0,0
	dc.b	'F',$e8,$80,0,0,0,'G',$88
	dc.b	$80,0,0,0,'G',$88,$80,0
	dc.b	0,0,'H(',$80,0,0,0
	dc.b	'H(',$80,0,0,0,'H('
	dc.b	$80,0,0,0,'H',$c8,$80,0
	dc.b	0,0,'H',$c8,$80,0,0,0
	dc.b	'Ih',$80,0,0,0,'Ih'
	dc.b	$80,0,0,0,'J',8,$80,0
	dc.b	0,0,'J',8,'@',0,0,0
	dc.b	'J',8,'@',0,0,0,'J',$a8
	dc.b	'@',0,0,0,'J',$a8,'@',0
	dc.b	0,0,'KH@',0,0,0
	dc.b	'KH@',0,0,0,'K',$e8
	dc.b	'@',0,0,0,'K',$e8,' ',0
	dc.b	0,0,'L',$88,' ',0,0,0
	dc.b	'L',$88,' ',0,0,0,'M('
	dc.b	' ',0,0,0,'M(',0,0
	dc.b	' ',0,'M',$c8,0,0,$10,0
	dc.b	'M',$c8,0,0,$10,0,'Nh'
	dc.b	0,0,$10,0,'Nh',0,0
	dc.b	$10,0,'O',8,0,0,$10,0
	dc.b	'O',$a8,0,0,8,0,'O',$a8
	dc.b	0,0,8,0,'PH',0,0
	dc.b	8,0,'PH',0,0,4,0
	dc.b	'P',$e8,0,0,4,0,'P',$e8
	dc.b	0,0,4,0,'Q',$88,0,0
	dc.b	2,0,'R(',0,0,2,0
	dc.b	'R(',0,0,2,0,'R',$c8
	dc.b	0,0,1,0,'Sh',0,0
	dc.b	1,0,'Sh',0,0,1,0
	dc.b	'T',8,0,0,0,$80,'T',$a8
	dc.b	0,0,0,$80,'UH',0,0
	dc.b	0,'@UH',0,0,0,'@'
	dc.b	'U',$e8,0,0,0,'@V',$88
	dc.b	0,0,0,' W(',0,0
	dc.b	0,' W(',0,0,0,$10
	dc.b	'W',$c8,0,0,0,8,'Xh'
	dc.b	0,0,0,8,'Y',8,0,0
	dc.b	0,4,'Y',$a8,0,0,0,4
	dc.b	'ZH',0,0,0,2,'Z',$e8
	dc.b	0,0,0,1,'[',$88,0,0
	dc.b	0,1,'\0',0,0,$80,0
	dc.b	'\',$d0,0,0,'@',0,']p'
	dc.b	0,0,' ',0,'^',$10,0,0
	dc.b	$10,0,'_P',0,0,8,0
	dc.b	'_',$f0,0,0,8,0,'`',$90
	dc.b	0,0,4,0,'a',$d0,2,0
	dc.b	2,0,'bp',0,$80,0,$80
	dc.b	'c',$10,0,'@',0,'@dP'
	dc.b	0,' ',0,' e',$90,0,$10
	dc.b	0,$10,'f0',0,4,0,4
	dc.b	'gp',0,2,0,2,'h',$b8
	dc.b	$80,0,$80,0,'i',$f8,'@',0
	dc.b	'@',0,'k8',$10,0,$10,0
	dc.b	'm',$18,4,0,4,0,'nX'
	dc.b	1,0,1,0,'p8',0,'@'
	dc.b	0,'@r',$18,0,8,0,8
	dc.b	's',$f8,0,2,0,2,'u',$e0
	dc.b	'@',0,'@',0,'x`',8,0
	dc.b	8,0,'z',$e0,1,0,1,0
	dc.b	$ff,$ff,'3',$90,0,$80,0,0
	dc.b	'2',$f0,0,$80,0,0,'2',$f0
	dc.b	0,$80,0,0,'2',$f0,0,$80
	dc.b	0,0,'2P',0,$80,0,0
	dc.b	'2P',0,$80,0,0,'1',$b0
	dc.b	0,$80,0,0,'1',$b0,1,0
	dc.b	0,0,'1',$10,1,0,0,0
	dc.b	'1',$10,1,0,0,0,'0p'
	dc.b	1,0,0,0,'/',$d0,1,0
	dc.b	0,0,'/',$d0,2,0,0,0
	dc.b	'/0',2,0,0,0,'/0'
	dc.b	2,0,0,0,'.',$90,2,0
	dc.b	0,0,'-',$f0,4,0,0,0
	dc.b	'-',$f0,4,0,0,0,'-P'
	dc.b	4,0,0,0,',',$b0,8,0
	dc.b	0,0,',',$10,8,0,0,0
	dc.b	',',$10,8,0,0,0,'+p'
	dc.b	$10,0,0,0,'*',$d0,$10,0
	dc.b	0,0,'*0',$10,0,0,0
	dc.b	')',$90,' ',0,0,0,'(',$f0
	dc.b	' ',0,0,0,'(P@',0
	dc.b	0,0,$27,$b0,'@',0,0,0
	dc.b	'&p',$80,0,0,0,'%',$c8
	dc.b	0,1,0,0,'%(',0,1
	dc.b	0,0,'#',$e8,0,2,0,0
	dc.b	'#H',0,4,0,0,'"',8
	dc.b	0,4,0,0,'!h',0,8
	dc.b	0,0,' (',0,0,0,$10
	dc.b	$1e,$e8,0,0,0,' ',$1d,$a8
	dc.b	0,0,0,'@',$1b,$c8,0,0
	dc.b	0,$80,$1a,$88,0,0,2,0
	dc.b	$18,$a8,0,0,4,0,$16,$c8
	dc.b	0,0,$10,0,$14,'H',0,0
	dc.b	'@',0,$11,$c0,0,0,0,1
	dc.b	$f,'@',0,0,0,4,$c,' '
	dc.b	0,0,0,$10,8,'`',0,0
	dc.b	0,$80,4,$a0,0,0,8,0
	dc.b	$ff,$ff,'M',$c0,0,' ',0,0
	dc.b	'N`',0,' ',0,0,'N`'
	dc.b	0,' ',0,0,'O',0,0,' '
	dc.b	0,0,'O',$a0,0,' ',0,0
	dc.b	'O',$a0,0,$10,0,0,'P@'
	dc.b	0,$10,0,0,'P@',0,$10
	dc.b	0,0,'P',$e0,0,$10,0,0
	dc.b	'Q',$80,0,8,0,0,'Q',$80
	dc.b	0,8,0,0,'R ',0,8
	dc.b	0,0,'R ',0,4,0,0
	dc.b	'R',$c0,0,4,0,0,'S`'
	dc.b	0,4,0,0,'S`',0,2
	dc.b	0,0,'T',0,0,2,0,0
	dc.b	'T',0,0,2,0,0,'T',$a0
	dc.b	0,1,0,0,'U@',0,1
	dc.b	0,0,'U@',0,1,0,0
	dc.b	'U',$e8,$80,0,0,0,'V',$88
	dc.b	$80,0,0,0,'V',$88,'@',0
	dc.b	0,0,'W(@',0,0,0
	dc.b	'W',$c8,' ',0,0,0,'W',$c8
	dc.b	' ',0,0,0,'Xh',$10,0
	dc.b	0,0,'Y',8,$10,0,0,0
	dc.b	'Y',8,8,0,0,0,'Y',$a8
	dc.b	8,0,0,0,'ZH',4,0
	dc.b	0,0,'Z',$e8,4,0,0,0
	dc.b	'Z',$e8,2,0,0,0,'[',$88
	dc.b	1,0,0,0,'\(',1,0
	dc.b	0,0,'\(',0,0,0,$80
	dc.b	'\',$c8,0,0,0,'@]h'
	dc.b	0,0,0,'@^',8,0,0
	dc.b	0,' ^',$a8,0,0,0,$10
	dc.b	'^',$a8,0,0,0,$10,'_H'
	dc.b	0,0,0,8,'_',$e8,0,0
	dc.b	0,4,'`',$88,0,0,0,2
	dc.b	'a(',0,0,0,1,'a('
	dc.b	0,0,0,1,'a',$d0,0,0
	dc.b	$80,0,'bp',0,0,'@',0
	dc.b	'c',$10,0,0,' ',0,'c',$b0
	dc.b	0,0,$10,0,'dP',0,0
	dc.b	8,0,'d',$f0,0,0,4,0
	dc.b	'e',$90,0,0,2,0,'e',$90
	dc.b	0,0,1,0,'f0',0,0
	dc.b	0,'@f',$d0,0,0,0,' '
	dc.b	'gp',0,0,0,$10,'h',$10
	dc.b	0,0,0,8,'h',$b0,0,0
	dc.b	0,2,'iP',0,0,0,1
	dc.b	'j',$98,0,0,$80,0,'k8'
	dc.b	0,0,' ',0,'k',$d8,0,0
	dc.b	$10,0,'lx',0,0,4,0
	dc.b	'm',$18,0,0,2,0,'m',$b8
	dc.b	0,0,0,$80,'n',$f8,0,0
	dc.b	0,' o',$98,0,0,0,8
	dc.b	'p8',0,0,0,2,'p',$d8
	dc.b	0,0,0,1,'r ',0,0
	dc.b	' ',0,'r',$c0,0,0,8,0
	dc.b	't',0,0,0,2,0,'t',$a0
	dc.b	0,0,0,$80,'u',$e0,0,0
	dc.b	0,$10,'w ',0,4,0,4
	dc.b	'w',$c8,$80,0,$80,0,'y',8
	dc.b	$10,0,$10,0,'zH',2,0
	dc.b	2,0,'{',$88,0,'@',0,'@'
	dc.b	'|',$c8,0,4,0,4,$ff,$ff
	dc.b	'5',$80,'@',0,0,0,'4',$e0
	dc.b	'@',0,0,0,'4',$e0,'@',0
	dc.b	0,0,'4@@',0,0,0
	dc.b	'3',$a0,'@',0,0,0,'3',0
	dc.b	'@',0,0,0,'3',0,'@',0
	dc.b	0,0,'2`@',0,0,0
	dc.b	'1',$c0,'@',0,0,0,'1',$c0
	dc.b	'@',0,0,0,'1 @',0
	dc.b	0,0,'0',$80,'@',0,0,0
	dc.b	'/',$e0,'@',0,0,0,'/',$e0
	dc.b	'@',0,0,0,'/@@',0
	dc.b	0,0,'.',$a0,'@',0,0,0
	dc.b	'.',0,'@',0,0,0,'-`'
	dc.b	'@',0,0,0,'-`@',0
	dc.b	0,0,',',$c0,'@',0,0,0
	dc.b	', @',0,0,0,'+',$80
	dc.b	'@',0,0,0,'*',$e0,'@',0
	dc.b	0,0,'*@',$80,0,0,0
	dc.b	')',$a0,$80,0,0,0,')',0
	dc.b	$80,0,0,0,'(`',$80,0
	dc.b	0,0,$27,$c0,$80,0,0,0
	dc.b	$27,$c0,$80,0,0,0,$27,$18
	dc.b	0,1,0,0,'&x',0,1
	dc.b	0,0,'%',$d8,0,1,0,0
	dc.b	'%8',0,1,0,0,'#',$f8
	dc.b	0,1,0,0,'#X',0,2
	dc.b	0,0,'"',$b8,0,2,0,0
	dc.b	'"',$18,0,0,0,2,'!x'
	dc.b	0,0,0,2,' ',$d8,0,0
	dc.b	0,4,' 8',0,0,0,4
	dc.b	$1f,$98,0,0,0,4,$1e,'X'
	dc.b	0,0,0,8,$1d,$b8,0,0
	dc.b	0,8,$1d,$18,0,0,0,$10
	dc.b	$1c,'x',0,0,0,$10,$1b,'8'
	dc.b	0,0,0,$10,$1a,$98,0,0
	dc.b	0,' ',$19,$f8,0,0,0,' '
	dc.b	$18,$b8,0,0,0,'@',$18,$18
	dc.b	0,0,0,'@',$16,$d8,0,0
	dc.b	0,$80,$16,'8',0,0,1,0
	dc.b	$14,$f8,0,0,1,0,$14,'X'
	dc.b	0,0,2,0,$13,$18,0,0
	dc.b	2,0,$12,'x',0,0,4,0
	dc.b	$11,'8',0,0,8,0,$f,$f8
	dc.b	0,0,$10,0,$e,$b8,0,0
	dc.b	$10,0,$d,'x',0,0,' ',0
	dc.b	$c,'8',0,0,'@',0,$b,$98
	dc.b	0,0,$80,0,9,$b0,0,0
	dc.b	0,1,8,'p',0,0,0,2
	dc.b	7,'0',0,0,0,4,5,$f0
	dc.b	0,0,0,8,4,$b0,0,0
	dc.b	0,$10,2,$d0,0,0,0,'@'
	dc.b	1,$90,0,0,0,$80,$ff,$ff
	dc.b	'@',$a8,8,0,0,0,'@',$a8
	dc.b	8,0,0,0,'@',$a8,8,0
	dc.b	0,0,'@',$a8,8,0,0,0
	dc.b	'AH',8,0,0,0,'AH'
	dc.b	8,0,0,0,'AH',8,0
	dc.b	0,0,'AH',8,0,0,0
	dc.b	'A',$e8,$10,0,0,0,'A',$e8
	dc.b	$10,0,0,0,'A',$e8,$10,0
	dc.b	0,0,'A',$e8,$10,0,0,0
	dc.b	'B',$88,$10,0,0,0,'B',$88
	dc.b	$10,0,0,0,'B',$88,$10,0
	dc.b	0,0,'B',$88,$10,0,0,0
	dc.b	'C(',$10,0,0,0,'C('
	dc.b	$10,0,0,0,'C(',$10,0
	dc.b	0,0,'C(',$10,0,0,0
	dc.b	'C',$c8,$10,0,0,0,'C',$c8
	dc.b	$10,0,0,0,'C',$c8,$10,0
	dc.b	0,0,'Dh',$10,0,0,0
	dc.b	'Dh',$10,0,0,0,'Dh'
	dc.b	$10,0,0,0,'E',8,$10,0
	dc.b	0,0,'E',8,$10,0,0,0
	dc.b	'E',8,$10,0,0,0,'E',$a8
	dc.b	$10,0,0,0,'E',$a8,$10,0
	dc.b	0,0,'E',$a8,$10,0,0,0
	dc.b	'FH',$10,0,0,0,'FH'
	dc.b	$10,0,0,0,'F',$e8,$10,0
	dc.b	0,0,'F',$e8,$10,0,0,0
	dc.b	'F',$e8,0,0,$10,0,'G',$88
	dc.b	0,0,$10,0,'G',$88,0,0
	dc.b	$10,0,'H(',0,0,$10,0
	dc.b	'H(',0,0,$10,0,'H',$c8
	dc.b	0,0,$10,0,'H',$c8,0,0
	dc.b	$10,0,'Ih',0,0,$10,0
	dc.b	'Ih',0,0,$10,0,'J',8
	dc.b	0,0,$10,0,'J',8,0,0
	dc.b	$10,0,'J',$a8,0,0,$10,0
	dc.b	'J',$a8,0,0,8,0,'KH'
	dc.b	0,0,8,0,'KH',0,0
	dc.b	8,0,'K',$e8,0,0,8,0
	dc.b	'L',$88,0,0,8,0,'L',$88
	dc.b	0,0,8,0,'M(',0,0
	dc.b	8,0,'M',$c8,0,0,8,0
	dc.b	'M',$c8,0,0,8,0,'Nh'
	dc.b	0,0,4,0,'O',8,0,0
	dc.b	4,0,'O',$a8,0,0,4,0
	dc.b	'O',$a8,0,0,4,0,'PH'
	dc.b	0,0,4,0,'P',$e8,0,0
	dc.b	4,0,'Q',$88,0,0,2,0
	dc.b	'R(',0,0,2,0,'R',$c8
	dc.b	0,0,2,0,'Sh',0,0
	dc.b	2,0,'T',$a8,0,0,1,0
	dc.b	'UH',0,0,1,0,'U',$e8
	dc.b	0,0,1,0,'V',$88,0,0
	dc.b	0,$80,'W',$c8,0,0,0,$80
	dc.b	'Xh',0,0,0,$80,'Y',$a8
	dc.b	0,0,0,'@Z',$e8,0,0
	dc.b	0,'@\(',0,0,0,' '
	dc.b	']h',0,' ',0,' ^',$a8
	dc.b	0,$10,0,$10,'_',$e8,0,$10
	dc.b	0,$10,'a',$c8,0,8,0,8
	dc.b	'c',$a8,0,4,0,4,'e',$88
	dc.b	0,2,0,2,'gh',0,1
	dc.b	0,1,'i',$f0,$80,0,$80,0
	dc.b	'lp@',0,'@',0,'o',$90
	dc.b	' ',0,' ',0,'sP',8,0
	dc.b	8,0,'w',$10,2,0,2,0
	dc.b	'{p',0,$80,0,$80,$ff,$ff
	dc.b	'A',$e8,$10,0,0,0,'A',$e8
	dc.b	$10,0,0,0,'A',$e8,$10,0
	dc.b	0,0,'B',$88,$10,0,0,0
	dc.b	'B',$88,$10,0,0,0,'B',$88
	dc.b	$10,0,0,0,'B',$88,$10,0
	dc.b	0,0,'C(',$10,0,0,0
	dc.b	'C(',$10,0,0,0,'C('
	dc.b	$10,0,0,0,'C(',$10,0
	dc.b	0,0,'C',$c8,$10,0,0,0
	dc.b	'C',$c8,$10,0,0,0,'C',$c8
	dc.b	$10,0,0,0,'C',$c8,$10,0
	dc.b	0,0,'Dh',$10,0,0,0
	dc.b	'Dh',$10,0,0,0,'Dh'
	dc.b	$10,0,0,0,'Dh',$10,0
	dc.b	0,0,'E',8,$10,0,0,0
	dc.b	'E',8,$10,0,0,0,'E',8
	dc.b	$10,0,0,0,'E',$a8,8,0
	dc.b	0,0,'E',$a8,8,0,0,0
	dc.b	'E',$a8,8,0,0,0,'E',$a8
	dc.b	8,0,0,0,'FH',8,0
	dc.b	0,0,'FH',8,0,0,0
	dc.b	'FH',8,0,0,0,'F',$e8
	dc.b	8,0,0,0,'F',$e8,8,0
	dc.b	0,0,'F',$e8,8,0,0,0
	dc.b	'G',$88,8,0,0,0,'G',$88
	dc.b	4,0,0,0,'G',$88,4,0
	dc.b	0,0,'G',$88,4,0,0,0
	dc.b	'H(',0,0,4,0,'H('
	dc.b	0,0,4,0,'H(',0,0
	dc.b	4,0,'H',$c8,0,0,4,0
	dc.b	'H',$c8,0,0,4,0,'H',$c8
	dc.b	0,0,2,0,'Ih',0,0
	dc.b	2,0,'Ih',0,0,2,0
	dc.b	'Ih',0,0,2,0,'J',8
	dc.b	0,0,2,0,'J',8,0,0
	dc.b	1,0,'J',8,0,0,1,0
	dc.b	'J',$a8,0,0,1,0,'J',$a8
	dc.b	0,0,1,0,'KH',0,0
	dc.b	1,0,'KH',0,0,0,$80
	dc.b	'KH',0,0,0,$80,'K',$e8
	dc.b	0,0,0,$80,'K',$e8,0,0
	dc.b	0,$80,'K',$e8,0,0,0,'@'
	dc.b	'L',$88,0,0,0,'@L',$88
	dc.b	0,0,0,'@M(',0,0
	dc.b	0,'@M(',0,0,0,' '
	dc.b	'M(',0,0,0,' M',$c8
	dc.b	0,0,0,' M',$c8,0,0
	dc.b	0,$10,'Nh',0,0,0,$10
	dc.b	'Nh',0,0,0,$10,'Nh'
	dc.b	0,0,0,8,'O',8,0,0
	dc.b	0,8,'O',8,0,0,0,8
	dc.b	'O',$a8,0,0,0,4,'O',$a8
	dc.b	0,0,0,4,'PH',0,0
	dc.b	0,4,'PH',0,0,0,2
	dc.b	'P',$e8,0,0,0,2,'P',$e8
	dc.b	0,0,0,1,'Q',$88,0,0
	dc.b	0,1,'Q',$90,0,0,$80,0
	dc.b	'R0',$80,0,$80,0,'R0'
	dc.b	'@',0,'@',0,'R',$d0,'@',0
	dc.b	'@',0,'R',$d0,' ',0,' ',0
	dc.b	'Sp ',0,' ',0,'Sp'
	dc.b	$10,0,$10,0,'T',$10,8,0
	dc.b	8,0,'T',$10,8,0,8,0
	dc.b	'T',$b0,4,0,4,0,'UP'
	dc.b	4,0,4,0,'UP',2,0
	dc.b	2,0,'U',$f0,1,0,1,0
	dc.b	'U',$f0,0,$80,0,$80,'V',$90
	dc.b	0,$80,0,$80,'W0',0,'@'
	dc.b	0,'@W',$d0,0,' ',0,' '
	dc.b	'W',$d0,0,$10,0,$10,'Xp'
	dc.b	0,8,0,8,'Y',$10,0,4
	dc.b	0,4,'Y',$b0,0,2,0,2
	dc.b	'ZP',0,1,0,1,'ZX'
	dc.b	$80,0,$80,0,'Z',$f8,'@',0
	dc.b	'@',0,'[',$98,' ',0,' ',0
	dc.b	'\8',8,0,8,0,'\',$d8
	dc.b	4,0,4,0,']x',2,0
	dc.b	2,0,'^',$b8,0,$80,0,$80
	dc.b	'_X',0,' ',0,' _',$f8
	dc.b	0,$10,0,$10,'`',$98,0,4
	dc.b	0,4,'a',$d8,0,1,0,1
	dc.b	'b',$80,'@',0,'@',0,'c',$c0
	dc.b	$10,0,$10,0,'e',0,2,0
	dc.b	2,0,'f@',0,$80,0,$80
	dc.b	'g',$80,0,$10,0,$10,'h',$c0
	dc.b	0,2,0,2,'j',8,'@',0
	dc.b	'@',0,'kH',4,0,4,0
	dc.b	'm(',0,$80,0,$80,'o',8
	dc.b	0,4,0,4,'q',$90,'@',0
	dc.b	'@',0,'sp',1,0,1,0
	dc.b	'v',$90,0,4,0,4,'y',$18
	dc.b	$10,0,$10,0,'|',$d8,0,$10
	dc.b	0,$10,$ff,$ff,'Sx',0,8
	dc.b	0,0,'Sx',0,4,0,0
	dc.b	'Sx',0,2,0,0,'Sx'
	dc.b	0,1,0,0,'S',$80,$80,0
	dc.b	0,0,'S',$80,'@',0,0,0
	dc.b	'S',$80,' ',0,0,0,'S',$80
	dc.b	$10,0,0,0,'S',$80,4,0
	dc.b	0,0,'S',$80,2,0,0,0
	dc.b	'S',$80,1,0,0,0,'S',$80
	dc.b	0,$80,0,0,'S',$80,0,'@'
	dc.b	0,0,'S',$80,0,$10,0,0
	dc.b	'S',$80,0,8,0,0,'S',$80
	dc.b	0,4,0,0,'S',$80,0,1
	dc.b	0,0,'R',$e8,$80,0,0,0
	dc.b	'R',$e8,' ',0,0,0,'R',$e8
	dc.b	$10,0,0,0,'R',$e8,4,0
	dc.b	0,0,'R',$e8,1,0,0,0
	dc.b	'R',$e8,0,$80,0,0,'R',$e8
	dc.b	0,' ',0,0,'RH',0,8
	dc.b	0,0,'RH',0,2,0,0
	dc.b	'RP',$80,0,0,0,'RP'
	dc.b	' ',0,0,0,'Q',$b0,8,0
	dc.b	0,0,'Q',$b0,1,0,0,0
	dc.b	'Q',$b0,0,'@',0,0,'Q',$10
	dc.b	0,$10,0,0,'Q',$10,0,2
	dc.b	0,0,'Px@',0,0,0
	dc.b	'Px',8,0,0,0,'Px'
	dc.b	1,0,0,0,'O',$d8,0,0
	dc.b	0,' O8',0,0,0,4
	dc.b	'O@',0,0,'@',0,'N',$a0
	dc.b	0,0,4,0,'N',0,0,0
	dc.b	0,'@N',0,0,0,0,4
	dc.b	'Mh',0,0,' ',0,'L',$c8
	dc.b	0,0,1,0,'L(',0,0
	dc.b	0,4,'K',$90,0,0,$10,0
	dc.b	'J',$f0,0,0,0,'@I',$b8
	dc.b	0,0,$80,0,'I',$18,0,0
	dc.b	0,$80,$ff,$ff,$27,8,0,8
	dc.b	0,0,$27,8,0,8,0,0
	dc.b	'&h',0,$10,0,0,'&h'
	dc.b	0,' ',0,0,'&h',0,'@'
	dc.b	0,0,'%',$c8,0,'@',0,0
	dc.b	'%',$c8,0,$80,0,0,'%('
	dc.b	1,0,0,0,'%(',1,0
	dc.b	0,0,'$',$88,2,0,0,0
	dc.b	'$',$88,4,0,0,0,'#',$e8
	dc.b	8,0,0,0,'#',$e8,$10,0
	dc.b	0,0,'#H ',0,0,0
	dc.b	'#H ',0,0,0,'"',$a8
	dc.b	'@',0,0,0,'"',$a8,$80,0
	dc.b	0,0,'"',0,0,1,0,0
	dc.b	'"',0,0,2,0,0,'!`'
	dc.b	0,4,0,0,'!`',0,8
	dc.b	0,0,' ',$c0,0,' ',0,0
	dc.b	' ',$c0,0,'@',0,0,'  '
	dc.b	0,$80,0,0,'  ',1,0
	dc.b	0,0,$1f,$80,2,0,0,0
	dc.b	$1f,$80,8,0,0,0,$1e,$e0
	dc.b	$10,0,0,0,$1e,'@ ',0
	dc.b	0,0,$1e,'@',$80,0,0,0
	dc.b	$1d,$98,0,1,0,0,$1d,$98
	dc.b	0,4,0,0,$1c,$f8,0,$10
	dc.b	0,0,$1c,'X',0,' ',0,0
	dc.b	$1c,'X',0,$80,0,0,$1b,$b8
	dc.b	2,0,0,0,$1b,$18,0,0
	dc.b	8,0,$1a,'x',0,0,' ',0
	dc.b	$1a,'x',0,0,$80,0,$19,$d0
	dc.b	0,0,0,2,$19,'0',0,0
	dc.b	0,$10,$18,$90,0,0,0,'@'
	dc.b	$17,$f0,0,0,2,0,$17,'P'
	dc.b	0,0,8,0,$16,$b0,0,0
	dc.b	'@',0,$16,8,0,0,0,2
	dc.b	$15,'h',0,0,0,$10,$14,$c8
	dc.b	0,0,1,0,$14,'(',0,0
	dc.b	$10,0,$13,$80,0,0,0,1
	dc.b	$12,'@',0,0,0,$10,$11,$a0
	dc.b	0,0,1,0,$10,'`',0,0
	dc.b	' ',0,$f,$18,0,0,0,4
	dc.b	$e,'x',0,0,1,0,$d,'8'
	dc.b	0,0,$80,0,$b,$f0,0,0
	dc.b	0,' ',$a,$10,0,0,' ',0
	dc.b	8,$c8,0,0,0,' ',6,$e8
	dc.b	0,0,$80,0,5,0,0,0
	dc.b	2,0,$ff,$ff,'E',$10,0,' '
	dc.b	0,0,'Dp',0,' ',0,0
	dc.b	'Dp',0,' ',0,0,'Dp'
	dc.b	0,$10,0,0,'Dp',0,$10
	dc.b	0,0,'Dp',0,$10,0,0
	dc.b	'Dp',0,$10,0,0,'Dp'
	dc.b	0,8,0,0,'Dp',0,8
	dc.b	0,0,'Dp',0,8,0,0
	dc.b	'C',$d0,0,8,0,0,'C',$d0
	dc.b	0,4,0,0,'C',$d0,0,4
	dc.b	0,0,'C',$d0,0,4,0,0
	dc.b	'C',$d0,0,4,0,0,'C',$d0
	dc.b	0,2,0,0,'C',$d0,0,2
	dc.b	0,0,'C',$d0,0,2,0,0
	dc.b	'C0',0,2,0,0,'C0'
	dc.b	0,1,0,0,'C0',0,1
	dc.b	0,0,'C0',0,1,0,0
	dc.b	'C0',0,1,0,0,'B',$98
	dc.b	$80,0,0,0,'B',$98,$80,0
	dc.b	0,0,'B',$98,$80,0,0,0
	dc.b	'B',$98,$80,0,0,0,'B',$98
	dc.b	'@',0,0,0,'A',$f8,'@',0
	dc.b	0,0,'A',$f8,'@',0,0,0
	dc.b	'A',$f8,' ',0,0,0,'A',$f8
	dc.b	' ',0,0,0,'A',$f8,' ',0
	dc.b	0,0,'AX ',0,0,0
	dc.b	'AX',$10,0,0,0,'AX'
	dc.b	$10,0,0,0,'AX',0,0
	dc.b	$10,0,'@',$b8,0,0,8,0
	dc.b	'@',$b8,0,0,8,0,'@',$b8
	dc.b	0,0,8,0,'@',$18,0,0
	dc.b	8,0,'@',$18,0,0,4,0
	dc.b	'@',$18,0,0,4,0,'@',$18
	dc.b	0,0,4,0,'?x',0,0
	dc.b	2,0,'?x',0,0,2,0
	dc.b	'?x',0,0,2,0,'>',$d8
	dc.b	0,0,2,0,'>',$d8,0,0
	dc.b	1,0,'>8',0,0,1,0
	dc.b	'>8',0,0,1,0,'>8'
	dc.b	0,0,0,$80,'=',$98,0,0
	dc.b	0,$80,'=',$98,0,0,0,$80
	dc.b	'<',$f8,0,0,0,'@<',$f8
	dc.b	0,0,0,'@<',$f8,0,0
	dc.b	0,'@<X',0,0,0,' '
	dc.b	'<X',0,0,0,' ;',$b8
	dc.b	0,0,0,' ;',$b8,0,0
	dc.b	0,$10,';',$18,0,0,0,$10
	dc.b	';',$18,0,0,0,$10,':x'
	dc.b	0,0,0,8,':x',0,0
	dc.b	0,8,'9',$d8,0,0,0,8
	dc.b	'98',0,0,0,4,'98'
	dc.b	0,0,0,4,'8',$98,0,0
	dc.b	0,4,'8',$98,0,0,0,2
	dc.b	'7',$f8,0,0,0,2,'7X'
	dc.b	0,0,0,1,'7X',0,0
	dc.b	0,1,'6',$b8,0,0,0,1
	dc.b	'6 ',0,0,$80,0,'5',$80
	dc.b	0,0,$80,0,'4',$e0,'@',0
	dc.b	'@',0,'4',$e0,'@',0,'@',0
	dc.b	'4@ ',0,' ',0,'3',$a0
	dc.b	' ',0,' ',0,'3',0,' ',0
	dc.b	' ',0,'2`',$10,0,$10,0
	dc.b	'1',$c0,$10,0,$10,0,'1 '
	dc.b	8,0,8,0,'0',$80,8,0
	dc.b	8,0,'/',$e0,4,0,4,0
	dc.b	'.',$a0,2,0,2,0,'.',0
	dc.b	2,0,2,0,'-`',1,0
	dc.b	1,0,', ',1,0,1,0
	dc.b	'+',$80,0,$80,0,$80,'*@'
	dc.b	0,'@',0,'@)',$a0,0,'@'
	dc.b	0,'@(`',0,' ',0,' '
	dc.b	$27,' ',0,$10,0,$10,'%',$e0
	dc.b	0,8,0,8,'$',$a0,0,4
	dc.b	0,4,'#`',0,4,0,4
	dc.b	'" ',0,2,0,2,' @'
	dc.b	0,1,0,1,$1f,8,'@',0
	dc.b	'@',0,$1d,'( ',0,' ',0
	dc.b	$1b,'H',$10,0,$10,0,$19,'h'
	dc.b	8,0,8,0,$16,$e8,2,0
	dc.b	2,0,$14,'h',1,0,1,0
	dc.b	$11,$e8,0,'@',0,'@',$e,$c8
	dc.b	0,$10,0,$10,$b,8,0,4
	dc.b	0,4,7,$e8,0,1,0,1
	dc.b	3,$90,' ',0,' ',0,$ff,$ff
	dc.b	'C(',0,8,0,0,'C('
	dc.b	0,8,0,0,'C(',0,8
	dc.b	0,0,'C(',0,8,0,0
	dc.b	'C(',0,8,0,0,'C',$c8
	dc.b	0,8,0,0,'C',$c8,0,4
	dc.b	0,0,'C',$c8,0,4,0,0
	dc.b	'C',$c8,0,4,0,0,'C',$c8
	dc.b	0,4,0,0,'C',$c8,0,4
	dc.b	0,0,'C',$c8,0,4,0,0
	dc.b	'Dh',0,4,0,0,'Dh'
	dc.b	0,4,0,0,'Dh',0,4
	dc.b	0,0,'Dh',0,2,0,0
	dc.b	'Dh',0,2,0,0,'Dh'
	dc.b	0,2,0,0,'E',8,0,2
	dc.b	0,0,'E',8,0,2,0,0
	dc.b	'E',8,0,2,0,0,'E',8
	dc.b	0,2,0,0,'E',8,0,1
	dc.b	0,0,'E',$a8,0,1,0,0
	dc.b	'E',$a8,0,1,0,0,'E',$a8
	dc.b	0,1,0,0,'E',$a8,0,1
	dc.b	0,0,'E',$a8,0,1,0,0
	dc.b	'E',$b0,$80,0,0,0,'FP'
	dc.b	$80,0,0,0,'FP',$80,0
	dc.b	0,0,'FP',$80,0,0,0
	dc.b	'FP',$80,0,0,0,'F',$f0
	dc.b	'@',0,0,0,'F',$f0,'@',0
	dc.b	0,0,'F',$f0,'@',0,0,0
	dc.b	'F',$f0,0,0,'@',0,'F',$f0
	dc.b	0,0,' ',0,'G',$90,0,0
	dc.b	' ',0,'G',$90,0,0,' ',0
	dc.b	'G',$90,0,0,' ',0,'G',$90
	dc.b	0,0,$10,0,'H0',0,0
	dc.b	$10,0,'H0',0,0,$10,0
	dc.b	'H0',0,0,8,0,'H',$d0
	dc.b	0,0,8,0,'H',$d0,0,0
	dc.b	8,0,'H',$d0,0,0,4,0
	dc.b	'Ip',0,0,4,0,'Ip'
	dc.b	0,0,2,0,'Ip',0,0
	dc.b	2,0,'J',$10,0,0,2,0
	dc.b	'J',$10,0,0,1,0,'J',$b0
	dc.b	0,0,1,0,'J',$b0,0,0
	dc.b	0,$80,'J',$b0,0,0,0,'@'
	dc.b	'KP',0,0,0,'@KP'
	dc.b	0,0,0,' K',$f0,0,0
	dc.b	0,$10,'L',$90,0,0,0,$10
	dc.b	'L',$90,0,0,0,8,'M0'
	dc.b	0,0,0,4,'M0',0,0
	dc.b	0,2,'M',$d0,0,0,0,1
	dc.b	'Nx',0,0,$80,0,'O',$18
	dc.b	0,0,'@',0,'O',$b8,0,0
	dc.b	' ',0,'PX',0,0,8,0
	dc.b	'P',$f8,0,0,4,0,'Q',$98
	dc.b	0,0,1,0,'R',$d8,0,0
	dc.b	0,'@Sx',0,0,0,$10
	dc.b	'T',$b8,0,0,0,4,'V',0
	dc.b	0,0,$80,0,'W@',0,0
	dc.b	$10,0,'Y ',0,0,2,0
	dc.b	'[',0,0,' ',0,' \',$e0
	dc.b	0,1,0,1,'`',8,4,0
	dc.b	4,0,'c(',0,8,0,8
	dc.b	'g',$90,2,0,2,0,'m8'
	dc.b	' ',0,' ',0,'t',$c0,' ',0
	dc.b	' ',0,$ff,$ff,'<P',0,2
	dc.b	0,0,'<P',0,2,0,0
	dc.b	'<P',0,2,0,0,';',$b0
	dc.b	0,2,0,0,';',$b0,0,2
	dc.b	0,0,';',$b0,0,2,0,0
	dc.b	';',$10,0,2,0,0,';',$10
	dc.b	0,2,0,0,';',$10,0,2
	dc.b	0,0,';',$10,0,2,0,0
	dc.b	':p',0,2,0,0,':p'
	dc.b	0,2,0,0,':p',0,2
	dc.b	0,0,':p',0,2,0,0
	dc.b	'9',$d0,0,2,0,0,'9',$d0
	dc.b	0,2,0,0,'9',$d0,0,1
	dc.b	0,0,'90',0,1,0,0
	dc.b	'90',0,1,0,0,'90'
	dc.b	0,1,0,0,'8',$90,0,2
	dc.b	0,0,'8',$90,0,2,0,0
	dc.b	'8',$90,0,2,0,0,'7',$f0
	dc.b	0,2,0,0,'7',$f0,0,2
	dc.b	0,0,'7',$f0,0,2,0,0
	dc.b	'7P',0,2,0,0,'7P'
	dc.b	0,2,0,0,'7P',0,2
	dc.b	0,0,'6',$b0,0,2,0,0
	dc.b	'6',$b0,0,2,0,0,'6',$b0
	dc.b	0,2,0,0,'6',$10,0,2
	dc.b	0,0,'6',$10,0,2,0,0
	dc.b	'6',$10,0,2,0,0,'5p'
	dc.b	0,2,0,0,'5p',0,0
	dc.b	0,2,'4',$d0,0,0,0,2
	dc.b	'4',$d0,0,0,0,2,'4',$d0
	dc.b	0,0,0,2,'40',0,0
	dc.b	0,4,'40',0,0,0,4
	dc.b	'40',0,0,0,4,'3',$90
	dc.b	0,0,0,4,'3',$90,0,0
	dc.b	0,4,'2',$f0,0,0,0,4
	dc.b	'2',$f0,0,0,0,4,'2P'
	dc.b	0,0,0,4,'2P',0,0
	dc.b	0,8,'2P',0,0,0,8
	dc.b	'1',$b0,0,0,0,8,'1',$b0
	dc.b	0,0,0,8,'1',$10,0,0
	dc.b	0,8,'1',$10,0,0,0,8
	dc.b	'0p',0,0,0,$10,'0p'
	dc.b	0,0,0,$10,'/',$d0,0,0
	dc.b	0,$10,'/',$d0,0,0,0,$10
	dc.b	'/0',0,0,0,' /0'
	dc.b	0,0,0,' .',$90,0,0
	dc.b	0,' .',$90,0,0,0,' '
	dc.b	'-',$f0,0,0,0,'@-',$f0
	dc.b	0,0,0,'@-P',0,0
	dc.b	0,'@-P',0,0,0,'@'
	dc.b	',',$b0,0,0,0,$80,',',$b0
	dc.b	0,0,0,$80,',',$10,0,0
	dc.b	0,$80,',',$10,0,0,1,0
	dc.b	'+p',0,0,1,0,'*',$d0
	dc.b	0,0,1,0,'*',$d0,0,0
	dc.b	2,0,'*0',0,0,2,0
	dc.b	')',$90,0,0,4,0,')',$90
	dc.b	0,0,4,0,'(',$f0,4,0
	dc.b	4,0,'(P',8,0,8,0
	dc.b	'(P',8,0,8,0,$27,$b0
	dc.b	$10,0,$10,0,$27,$10,$10,0
	dc.b	$10,0,'&p ',0,' ',0
	dc.b	'&p@',0,'@',0,'%',$d0
	dc.b	'@',0,'@',0,'%0',$80,0
	dc.b	$80,0,'$',$90,$80,0,$80,0
	dc.b	'#',$e8,0,1,0,1,'#H'
	dc.b	0,2,0,2,'"',$a8,0,2
	dc.b	0,2,'"',8,0,4,0,4
	dc.b	'!h',0,8,0,8,' ',$c8
	dc.b	0,$10,0,$10,' (',0,' '
	dc.b	0,' ',$1f,$88,0,'@',0,'@'
	dc.b	$1e,$e8,0,$80,0,$80,$1e,'H'
	dc.b	1,0,1,0,$1d,$a8,2,0
	dc.b	2,0,$1c,'h',4,0,4,0
	dc.b	$1b,$c8,8,0,8,0,$1a,$88
	dc.b	$10,0,$10,0,$19,$e8,' ',0
	dc.b	' ',0,$18,$a8,$80,0,$80,0
	dc.b	$18,0,0,1,0,1,$16,$c0
	dc.b	0,4,0,4,$15,$80,0,8
	dc.b	0,8,$14,'@',0,' ',0,' '
	dc.b	$13,0,0,$80,0,$80,$11,$c0
	dc.b	2,0,2,0,$f,$e0,8,0
	dc.b	8,0,$e,0,'@',0,'@',0
	dc.b	$c,$b8,0,1,0,1,$a,$d8
	dc.b	0,8,0,8,8,'X',0,'@'
	dc.b	0,'@',5,$d8,4,0,4,0
	dc.b	3,'X ',0,' ',0,0,$d0
	dc.b	0,2,0,2,$ff,$ff,'@',0
	dc.b	1,0,0,0,'@',$a0,1,0
	dc.b	0,0,'@',$a0,2,0,0,0
	dc.b	'A@',2,0,0,0,'A@'
	dc.b	2,0,0,0,'A',$e0,2,0
	dc.b	0,0,'A',$e0,2,0,0,0
	dc.b	'A',$e0,4,0,0,0,'B',$80
	dc.b	4,0,0,0,'B',$80,4,0
	dc.b	0,0,'C ',4,0,0,0
	dc.b	'C ',4,0,0,0,'C',$c0
	dc.b	4,0,0,0,'C',$c0,8,0
	dc.b	0,0,'D`',8,0,0,0
	dc.b	'E',0,8,0,0,0,'E',0
	dc.b	8,0,0,0,'E',$a0,8,0
	dc.b	0,0,'E',$a0,8,0,0,0
	dc.b	'F@',$10,0,0,0,'F@'
	dc.b	$10,0,0,0,'F',$e0,$10,0
	dc.b	0,0,'G',$80,$10,0,0,0
	dc.b	'G',$80,$10,0,0,0,'H '
	dc.b	$10,0,0,0,'H',$c0,$10,0
	dc.b	0,0,'H',$c0,$10,0,0,0
	dc.b	'I` ',0,0,0,'J',0
	dc.b	' ',0,0,0,'J',0,' ',0
	dc.b	0,0,'J',$a0,' ',0,0,0
	dc.b	'K@ ',0,0,0,'K@'
	dc.b	' ',0,0,0,'K',$e0,' ',0
	dc.b	0,0,'L',$80,' ',0,0,0
	dc.b	'M  ',0,0,0,'M',$c0
	dc.b	0,0,' ',0,'M',$c0,0,0
	dc.b	' ',0,'N`',0,0,' ',0
	dc.b	'O',0,0,0,' ',0,'O',$a0
	dc.b	0,0,'@',0,'P@',0,0
	dc.b	'@',0,'P',$e0,0,0,'@',0
	dc.b	'Q',$80,0,0,'@',0,'R '
	dc.b	0,0,'@',0,'R',$c0,0,0
	dc.b	'@',0,'S`',0,0,'@',0
	dc.b	'T',0,0,0,'@',0,'T',$a0
	dc.b	0,0,'@',0,'U@',0,0
	dc.b	'@',0,'U',$e0,0,0,'@',0
	dc.b	'W ',0,0,'@',0,'W',$c0
	dc.b	0,0,'@',0,'X`',0,0
	dc.b	'@',0,'Y',$a0,0,0,' ',0
	dc.b	'Z@',0,0,' ',0,'Z',$e0
	dc.b	0,0,' ',0,'\ ',0,0
	dc.b	' ',0,'\',$c0,0,0,' ',0
	dc.b	'^',0,0,0,' ',0,'_@'
	dc.b	0,0,' ',0,'_',$e0,0,0
	dc.b	' ',0,'a ',0,0,' ',0
	dc.b	'b`',0,0,$10,0,'c',$a0
	dc.b	0,0,$10,0,'d',$e0,0,0
	dc.b	$10,0,'f ',0,0,$10,0
	dc.b	'g`',0,0,$10,0,'h',$a0
	dc.b	0,0,8,0,'j',$80,0,0
	dc.b	8,0,'k',$c0,0,0,8,0
	dc.b	'm',$a0,0,0,4,0,'o',$80
	dc.b	0,0,4,0,'q`',0,0
	dc.b	4,0,'s@',0,0,2,0
	dc.b	'u',$c0,0,0,2,0,'w',$a0
	dc.b	1,0,1,0,'z ',1,0
	dc.b	1,0,'|',$a0,0,$80,0,$80
	dc.b	$ff,$ff,'G',$88,0,1,0,0
	dc.b	'G',$88,0,1,0,0,'G',$88
	dc.b	0,1,0,0,'G',$90,$80,0
	dc.b	0,0,'G',$90,$80,0,0,0
	dc.b	'H0',$80,0,0,0,'H0'
	dc.b	$80,0,0,0,'H0@',0
	dc.b	0,0,'H0@',0,0,0
	dc.b	'H0@',0,0,0,'H',$d0
	dc.b	'@',0,0,0,'H',$d0,' ',0
	dc.b	0,0,'H',$d0,' ',0,0,0
	dc.b	'H',$d0,' ',0,0,0,'H',$d0
	dc.b	$10,0,0,0,'Ip',$10,0
	dc.b	0,0,'Ip',$10,0,0,0
	dc.b	'Ip',8,0,0,0,'Ip'
	dc.b	8,0,0,0,'Ip',8,0
	dc.b	0,0,'J',$10,4,0,0,0
	dc.b	'J',$10,4,0,0,0,'J',$10
	dc.b	4,0,0,0,'J',$10,2,0
	dc.b	0,0,'J',$10,2,0,0,0
	dc.b	'J',$b0,1,0,0,0,'J',$b0
	dc.b	1,0,0,0,'J',$b0,1,0
	dc.b	0,0,'J',$b0,0,$80,0,0
	dc.b	'KP',0,$80,0,0,'KP'
	dc.b	0,'@',0,0,'KP',0,'@'
	dc.b	0,0,'KP',0,' ',0,0
	dc.b	'KP',0,' ',0,0,'K',$f0
	dc.b	0,$10,0,0,'K',$f0,0,$10
	dc.b	0,0,'K',$f0,0,0,0,8
	dc.b	'K',$f0,0,0,0,4,'L',$90
	dc.b	0,0,0,4,'L',$90,0,0
	dc.b	0,2,'L',$90,0,0,0,1
	dc.b	'M0',0,0,0,1,'M8'
	dc.b	0,0,$80,0,'M8',0,0
	dc.b	'@',0,'M',$d8,0,0,' ',0
	dc.b	'M',$d8,0,0,$10,0,'M',$d8
	dc.b	0,0,8,0,'Nx',0,0
	dc.b	8,0,'Nx',0,0,4,0
	dc.b	'Nx',0,0,1,0,'O',$18
	dc.b	0,0,0,$80,'O',$18,0,0
	dc.b	0,'@O',$b8,0,0,0,' '
	dc.b	'O',$b8,0,0,0,$10,'O',$b8
	dc.b	0,0,0,4,'PX',0,0
	dc.b	0,2,'P`',0,0,$80,0
	dc.b	'Q',0,0,0,'@',0,'Q',$a0
	dc.b	0,0,$10,0,'Q',$a0,0,0
	dc.b	4,0,'R@',0,0,1,0
	dc.b	'R',$e0,0,0,0,' S',$80
	dc.b	0,0,0,8,'S',$80,0,0
	dc.b	0,1,'T(',0,0,' ',0
	dc.b	'T',$c8,0,0,4,0,'V',8
	dc.b	0,0,0,'@V',$a8,0,0
	dc.b	0,4,'WP',0,0,' ',0
	dc.b	'X',$90,0,0,1,0,'Y',$d0
	dc.b	0,0,0,4,'[',$18,0,0
	dc.b	8,0,'\',$f8,0,0,0,8
	dc.b	'^',$e0,0,0,4,0,'`',$c8
	dc.b	0,0,'@',0,'c',$e8,0,0
	dc.b	0,1,'g',$18,' ',0,' ',0
	dc.b	$ff,$ff,'4',$c8,8,0,0,0
	dc.b	'4',$c8,$10,0,0,0,'4',$c8
	dc.b	$10,0,0,0,'4',$c8,$10,0
	dc.b	0,0,'4',$c8,' ',0,0,0
	dc.b	'4',$c8,' ',0,0,0,'4',$c8
	dc.b	' ',0,0,0,'4',$c8,'@',0
	dc.b	0,0,'5h@',0,0,0
	dc.b	'5h@',0,0,0,'5h'
	dc.b	$80,0,0,0,'5h',$80,0
	dc.b	0,0,'5`',0,1,0,0
	dc.b	'5`',0,1,0,0,'5`'
	dc.b	0,1,0,0,'5`',0,2
	dc.b	0,0,'5`',0,2,0,0
	dc.b	'6',0,0,4,0,0,'6',0
	dc.b	0,4,0,0,'6',0,0,4
	dc.b	0,0,'6',0,0,8,0,0
	dc.b	'6',0,0,8,0,0,'6',0
	dc.b	0,$10,0,0,'6',$a0,0,$10
	dc.b	0,0,'6',$a0,0,$10,0,0
	dc.b	'6',$a0,0,' ',0,0,'6',$a0
	dc.b	0,' ',0,0,'6',$a0,0,'@'
	dc.b	0,0,'7@',0,'@',0,0
	dc.b	'7@',0,$80,0,0,'7@'
	dc.b	0,$80,0,0,'7@',0,$80
	dc.b	0,0,'7',$e0,1,0,0,0
	dc.b	'7',$e0,1,0,0,0,'7',$e0
	dc.b	2,0,0,0,'7',$e0,2,0
	dc.b	0,0,'8',$80,0,0,4,0
	dc.b	'8',$80,0,0,4,0,'8',$80
	dc.b	0,0,8,0,'9 ',0,0
	dc.b	8,0,'9 ',0,0,$10,0
	dc.b	'9 ',0,0,$10,0,'9',$c0
	dc.b	0,0,' ',0,'9',$c0,0,0
	dc.b	' ',0,'9',$c0,0,0,'@',0
	dc.b	':`',0,0,'@',0,':`'
	dc.b	0,0,$80,0,';',0,0,0
	dc.b	$80,0,':',$f8,0,0,0,1
	dc.b	':',$f8,0,0,0,1,';',$98
	dc.b	0,0,0,2,';',$98,0,0
	dc.b	0,4,'<8',0,0,0,4
	dc.b	'<8',0,0,0,8,'<',$d8
	dc.b	0,0,0,8,'<',$d8,0,0
	dc.b	0,$10,'=x',0,0,0,$10
	dc.b	'=x',0,0,0,' >',$18
	dc.b	0,0,0,'@>',$b8,0,0
	dc.b	0,'@>',$b8,0,0,0,$80
	dc.b	'?X',0,0,1,0,'?',$f8
	dc.b	0,0,1,0,'?',$f8,0,0
	dc.b	2,0,'@',$98,0,0,4,0
	dc.b	'A8',0,0,8,0,'A8'
	dc.b	0,0,8,0,'A',$d8,0,0
	dc.b	$10,0,'Bx',0,0,' ',0
	dc.b	'C',$18,0,0,'@',0,'C',$b8
	dc.b	0,0,'@',0,'DX',0,0
	dc.b	$80,0,'D',$f0,0,0,0,1
	dc.b	'E',$90,0,0,0,2,'F0'
	dc.b	0,0,0,4,'F',$d0,0,0
	dc.b	0,8,'Gp',0,$10,0,$10
	dc.b	'H',$10,0,' ',0,' H',$b0
	dc.b	0,'@',0,'@I',$f0,0,$80
	dc.b	0,$80,'J',$90,1,0,1,0
	dc.b	'K',$d0,2,0,2,0,'Lp'
	dc.b	8,0,8,0,'M',$b0,$10,0
	dc.b	$10,0,'NP ',0,' ',0
	dc.b	'O',$90,$80,0,$80,0,'P',$c8
	dc.b	0,1,0,1,'R',8,0,4
	dc.b	0,4,'SH',0,$10,0,$10
	dc.b	'T',$88,0,' ',0,' Vh'
	dc.b	0,$80,0,$80,'W',$a8,2,0
	dc.b	2,0,'Y',$88,8,0,8,0
	dc.b	'[h ',0,' ',0,']@'
	dc.b	0,1,0,1,'_',$c0,0,4
	dc.b	0,4,'a',$a0,0,' ',0,' '
	dc.b	'd ',1,0,1,0,'g@'
	dc.b	$10,0,$10,0,'j`',$80,0
	dc.b	$80,0,'mx',0,8,0,8
	dc.b	'q8',1,0,1,0,'u',$98
	dc.b	' ',0,' ',0,'y',$f0,0,4
	dc.b	0,4,$ff,$ff,'E',$b8,0,$80
	dc.b	0,0,'E',$b8,0,$80,0,0
	dc.b	'E',$b8,0,$80,0,0,'E',$18
	dc.b	0,'@',0,0,'E',$18,0,'@'
	dc.b	0,0,'E',$18,0,'@',0,0
	dc.b	'Dx',0,' ',0,0,'Dx'
	dc.b	0,' ',0,0,'Dx',0,' '
	dc.b	0,0,'C',$d8,0,$10,0,0
	dc.b	'C',$d8,0,$10,0,0,'C8'
	dc.b	0,8,0,0,'C8',0,8
	dc.b	0,0,'C8',0,8,0,0
	dc.b	'B',$98,0,4,0,0,'B',$98
	dc.b	0,4,0,0,'A',$f8,0,4
	dc.b	0,0,'A',$f8,0,2,0,0
	dc.b	'A',$f8,0,2,0,0,'AX'
	dc.b	0,2,0,0,'AX',0,1
	dc.b	0,0,'@',$b8,0,1,0,0
	dc.b	'@',$b8,0,1,0,0,'@',$18
	dc.b	0,1,0,0,'@ ',$80,0
	dc.b	0,0,'?',$80,$80,0,0,0
	dc.b	'?',$80,$80,0,0,0,'>',$e0
	dc.b	'@',0,0,0,'>',$e0,'@',0
	dc.b	0,0,'>@@',0,0,0
	dc.b	'>@ ',0,0,0,'=',$a0
	dc.b	' ',0,0,0,'=',$a0,' ',0
	dc.b	0,0,'=',0,$10,0,0,0
	dc.b	'=',0,$10,0,0,0,'<`'
	dc.b	$10,0,0,0,';',$c0,0,0
	dc.b	$10,0,';',$c0,0,0,8,0
	dc.b	'; ',0,0,8,0,':',$80
	dc.b	0,0,8,0,':',$80,0,0
	dc.b	8,0,'9',$e0,0,0,4,0
	dc.b	'9',$e0,0,0,4,0,'9@'
	dc.b	0,0,4,0,'8',$a0,0,0
	dc.b	2,0,'8',0,0,0,2,0
	dc.b	'8',0,0,0,2,0,'7`'
	dc.b	0,0,2,0,'6',$c0,0,0
	dc.b	1,0,'6',$c0,0,0,1,0
	dc.b	'6 ',0,0,1,0,'5',$80
	dc.b	0,0,1,0,'4',$e0,0,0
	dc.b	1,0,'4@',0,0,0,$80
	dc.b	'4@',0,0,0,$80,'3',$a0
	dc.b	0,0,0,$80,'3',0,0,0
	dc.b	0,$80,'2`',0,0,0,$80
	dc.b	'1',$c0,0,0,0,'@1 '
	dc.b	0,0,0,'@0',$80,0,0
	dc.b	0,'@/',$e0,0,0,0,'@'
	dc.b	'/@',0,0,0,'@.',$a0
	dc.b	0,0,0,'@.',0,0,0
	dc.b	0,' -`',0,0,0,' '
	dc.b	',',$c0,0,0,0,' , '
	dc.b	0,0,0,' +',$80,0,0
	dc.b	0,' *',$e0,0,0,0,' '
	dc.b	'*@',0,0,0,' )',$a0
	dc.b	0,0,0,' )',0,0,0
	dc.b	0,$10,$27,$c0,0,0,0,$10
	dc.b	$27,' ',0,0,0,$10,'&',$80
	dc.b	0,0,0,$10,'%',$e0,0,$10
	dc.b	0,$10,'$',$a0,0,$10,0,$10
	dc.b	'$',0,0,$10,0,$10,'#`'
	dc.b	0,$10,0,$10,'" ',0,$10
	dc.b	0,$10,'!',$80,0,$10,0,$10
	dc.b	' @',0,$10,0,$10,$1f,$a0
	dc.b	0,$10,0,$10,$1e,'`',0,$10
	dc.b	0,$10,$1d,' ',0,$10,0,$10
	dc.b	$1c,$80,0,$10,0,$10,$1b,'@'
	dc.b	0,$10,0,$10,$1a,0,0,$10
	dc.b	0,$10,$18,$c0,0,$10,0,$10
	dc.b	$18,' ',0,$10,0,$10,$16,$e0
	dc.b	0,' ',0,' ',$15,$a0,0,' '
	dc.b	0,' ',$13,$c0,0,' ',0,' '
	dc.b	$12,$80,0,' ',0,' ',$11,'@'
	dc.b	0,' ',0,' ',$10,0,0,' '
	dc.b	0,' ',$e,' ',0,'@',0,'@'
	dc.b	$c,$e0,0,'@',0,'@',$b,0
	dc.b	0,'@',0,'@',9,' ',0,'@'
	dc.b	0,'@',7,$e0,0,$80,0,$80
	dc.b	6,0,0,$80,0,$80,3,$80
	dc.b	0,$80,0,$80,1,$a0,1,0
	dc.b	1,0,$ff,$ff,'5H',0,8
	dc.b	0,0,'5H',0,' ',0,0
	dc.b	'5',$e8,0,'@',0,0,'6',$88
	dc.b	1,0,0,0,'7(',2,0
	dc.b	0,0,'7',$c8,8,0,0,0
	dc.b	'8h ',0,0,0,'9',8
	dc.b	'@',0,0,0,'9',$a0,0,1
	dc.b	0,0,':@',0,4,0,0
	dc.b	':',$e0,0,$10,0,0,'< '
	dc.b	0,'@',0,0,'<',$c0,1,0
	dc.b	0,0,'=`',4,0,0,0
	dc.b	'>',$a0,$10,0,0,0,'?@'
	dc.b	$80,0,0,0,'@x',0,2
	dc.b	0,0,'A',$b8,0,8,0,0
	dc.b	'BX',0,'@',0,0,'C',$98
	dc.b	2,0,0,0,'D',$d8,$10,0
	dc.b	0,0,'F',$18,$80,0,0,0
	dc.b	'GP',0,4,0,0,'I0'
	dc.b	0,' ',0,0,'Jp',1,0
	dc.b	0,0,'LP',$10,0,0,0
	dc.b	'M',$88,0,1,0,0,'Oh'
	dc.b	0,$10,0,0,'Q',$e8,2,0
	dc.b	0,0,'S',$c8,' ',0,0,0
	dc.b	'V@',0,4,0,0,'X',$c0
	dc.b	1,0,0,0,'[@@',0
	dc.b	0,0,$ff,$ff,'@',$a8,$10,0
	dc.b	0,0,'@',$a8,$10,0,0,0
	dc.b	'@',$a8,$10,0,0,0,'AH'
	dc.b	$10,0,0,0,'AH',$10,0
	dc.b	0,0,'AH',$10,0,0,0
	dc.b	'AH',$10,0,0,0,'A',$e8
	dc.b	$10,0,0,0,'A',$e8,$10,0
	dc.b	0,0,'A',$e8,$10,0,0,0
	dc.b	'A',$e8,$10,0,0,0,'B',$88
	dc.b	$10,0,0,0,'B',$88,$10,0
	dc.b	0,0,'B',$88,$10,0,0,0
	dc.b	'B',$88,$10,0,0,0,'C('
	dc.b	$10,0,0,0,'C(',$10,0
	dc.b	0,0,'C(',$10,0,0,0
	dc.b	'C(',$10,0,0,0,'C',$c8
	dc.b	$10,0,0,0,'C',$c8,$10,0
	dc.b	0,0,'C',$c8,$10,0,0,0
	dc.b	'Dh',$10,0,0,0,'Dh'
	dc.b	$10,0,0,0,'Dh',$10,0
	dc.b	0,0,'Dh',$10,0,0,0
	dc.b	'E',8,$10,0,0,0,'E',8
	dc.b	$10,0,0,0,'E',8,$10,0
	dc.b	0,0,'E',$a8,$10,0,0,0
	dc.b	'E',$a8,$10,0,0,0,'E',$a8
	dc.b	$10,0,0,0,'FH',$10,0
	dc.b	0,0,'FH',$10,0,0,0
	dc.b	'FH',$10,0,0,0,'F',$e8
	dc.b	$10,0,0,0,'F',$e8,0,0
	dc.b	$10,0,'F',$e8,0,0,8,0
	dc.b	'G',$88,0,0,8,0,'G',$88
	dc.b	0,0,8,0,'G',$88,0,0
	dc.b	8,0,'H(',0,0,8,0
	dc.b	'H(',0,0,8,0,'H('
	dc.b	0,0,8,0,'H',$c8,0,0
	dc.b	8,0,'H',$c8,0,0,8,0
	dc.b	'H',$c8,0,0,4,0,'Ih'
	dc.b	0,0,4,0,'Ih',0,0
	dc.b	4,0,'J',8,0,0,4,0
	dc.b	'J',8,0,0,4,0,'J',8
	dc.b	0,0,4,0,'J',$a8,0,0
	dc.b	4,0,'J',$a8,0,0,2,0
	dc.b	'KH',0,0,2,0,'KH'
	dc.b	0,0,2,0,'K',$e8,0,0
	dc.b	2,0,'K',$e8,0,0,2,0
	dc.b	'K',$e8,0,0,1,0,'L',$88
	dc.b	0,0,1,0,'L',$88,0,0
	dc.b	1,0,'M(',0,0,1,0
	dc.b	'M(',0,0,0,$80,'M',$c8
	dc.b	0,0,0,$80,'M',$c8,0,0
	dc.b	0,$80,'Nh',0,0,0,$80
	dc.b	'Nh',0,0,0,'@O',8
	dc.b	0,0,0,'@O',8,0,0
	dc.b	0,'@O',$a8,0,0,0,' '
	dc.b	'PH',0,0,0,' PH'
	dc.b	0,0,0,' P',$e8,0,0
	dc.b	0,$10,'P',$e8,0,0,0,$10
	dc.b	'Q',$88,0,0,0,$10,'R('
	dc.b	0,0,0,8,'R(',0,8
	dc.b	0,8,'R',$c8,0,4,0,4
	dc.b	'Sh',0,4,0,4,'Sh'
	dc.b	0,2,0,2,'T',8,0,2
	dc.b	0,2,'T',$a8,0,1,0,1
	dc.b	'UH',0,1,0,1,'UP'
	dc.b	$80,0,$80,0,'U',$f0,$80,0
	dc.b	$80,0,'V',$90,'@',0,'@',0
	dc.b	'W0 ',0,' ',0,'W',$d0
	dc.b	' ',0,' ',0,'Xp',$10,0
	dc.b	$10,0,'Y',$10,8,0,8,0
	dc.b	'Y',$b0,4,0,4,0,'ZP'
	dc.b	4,0,4,0,'Z',$f0,2,0
	dc.b	2,0,'[',$90,1,0,1,0
	dc.b	'\',$d0,0,$80,0,$80,']p'
	dc.b	0,'@',0,'@^',$10,0,' '
	dc.b	0,' _P',0,8,0,8
	dc.b	'`',$90,0,4,0,4,'a0'
	dc.b	0,2,0,2,'bx',$80,0
	dc.b	$80,0,'c',$b8,'@',0,'@',0
	dc.b	'd',$f8,$10,0,$10,0,'f8'
	dc.b	4,0,4,0,'gx',1,0
	dc.b	1,0,'iX',0,'@',0,'@'
	dc.b	'k8',0,$10,0,$10,'m',$18
	dc.b	0,4,0,4,'o',0,$80,0
	dc.b	$80,0,'q',$80,$10,0,$10,0
	dc.b	't',0,1,0,1,0,'v',$80
	dc.b	0,' ',0,' y',$a0,0,1
	dc.b	0,1,$ff,$ff,'@',$a8,0,8
	dc.b	0,0,'@',$a8,0,8,0,0
	dc.b	'@',$a8,0,8,0,0,'@',$a8
	dc.b	0,8,0,0,'AH',0,8
	dc.b	0,0,'AH',0,8,0,0
	dc.b	'AH',0,8,0,0,'AH'
	dc.b	0,8,0,0,'AH',0,8
	dc.b	0,0,'AH',0,8,0,0
	dc.b	'AH',0,8,0,0,'AH'
	dc.b	0,8,0,0,'AH',0,8
	dc.b	0,0,'AH',0,8,0,0
	dc.b	'AH',0,8,0,0,'A',$e8
	dc.b	0,8,0,0,'A',$e8,0,8
	dc.b	0,0,'A',$e8,0,8,0,0
	dc.b	'A',$e8,0,8,0,0,'A',$e8
	dc.b	0,8,0,0,'A',$e8,0,8
	dc.b	0,0,'A',$e8,0,4,0,0
	dc.b	'A',$e8,0,4,0,0,'A',$e8
	dc.b	0,4,0,0,'A',$e8,0,4
	dc.b	0,0,'A',$e8,0,4,0,0
	dc.b	'B',$88,0,4,0,0,'B',$88
	dc.b	0,4,0,0,'B',$88,0,4
	dc.b	0,0,'B',$88,0,4,0,0
	dc.b	'B',$88,0,4,0,0,'B',$88
	dc.b	0,4,0,0,'B',$88,0,4
	dc.b	0,0,'B',$88,0,4,0,0
	dc.b	'B',$88,0,2,0,0,'B',$88
	dc.b	0,2,0,0,'C(',0,0
	dc.b	0,2,'C(',0,0,0,2
	dc.b	'C(',0,0,0,2,'C('
	dc.b	0,0,0,2,'C(',0,0
	dc.b	0,2,'C(',0,0,0,2
	dc.b	'C(',0,0,0,2,'C('
	dc.b	0,0,0,2,'C(',0,0
	dc.b	0,1,'C(',0,0,0,1
	dc.b	'C',$c8,0,0,0,1,'C',$c8
	dc.b	0,0,0,1,'C',$c8,0,0
	dc.b	0,1,'C',$c8,0,0,0,1
	dc.b	'C',$c8,0,0,0,1,'C',$c8
	dc.b	0,0,0,1,'C',$c8,0,0
	dc.b	0,1,'C',$d0,0,0,$80,0
	dc.b	'C',$d0,0,0,$80,0,'C',$d0
	dc.b	0,0,$80,0,'Dp',0,0
	dc.b	$80,0,'Dp',0,0,$80,0
	dc.b	'Dp',0,0,$80,0,'Dp'
	dc.b	0,0,'@',0,'Dp',0,0
	dc.b	'@',0,'Dp',0,0,'@',0
	dc.b	'Dp',0,0,'@',0,'Dp'
	dc.b	0,0,'@',0,'Dp',0,0
	dc.b	'@',0,'Dp',0,0,' ',0
	dc.b	'E',$10,0,0,' ',0,'E',$10
	dc.b	0,0,' ',0,'E',$10,0,0
	dc.b	' ',0,'E',$10,0,0,' ',0
	dc.b	'E',$10,0,0,$10,0,'E',$10
	dc.b	0,0,$10,0,'E',$10,0,0
	dc.b	$10,0,'E',$10,0,0,$10,0
	dc.b	'E',$10,0,0,$10,0,'E',$10
	dc.b	0,0,8,0,'E',$b0,8,0
	dc.b	8,0,'E',$b0,8,0,8,0
	dc.b	'E',$b0,8,0,8,0,'E',$b0
	dc.b	4,0,4,0,'E',$b0,4,0
	dc.b	4,0,'E',$b0,4,0,4,0
	dc.b	'E',$b0,4,0,4,0,'E',$b0
	dc.b	2,0,2,0,'E',$b0,2,0
	dc.b	2,0,'FP',2,0,2,0
	dc.b	'FP',1,0,1,0,'FP'
	dc.b	1,0,1,0,'FP',1,0
	dc.b	1,0,'FP',0,$80,0,$80
	dc.b	'FP',0,$80,0,$80,'FP'
	dc.b	0,'@',0,'@FP',0,'@'
	dc.b	0,'@F',$f0,0,'@',0,'@'
	dc.b	'F',$f0,0,' ',0,' F',$f0
	dc.b	0,' ',0,' F',$f0,0,$10
	dc.b	0,$10,'F',$f0,0,$10,0,$10
	dc.b	'F',$f0,0,8,0,8,'F',$f0
	dc.b	0,8,0,8,'G',$90,0,4
	dc.b	0,4,'G',$90,0,4,0,4
	dc.b	'G',$90,0,2,0,2,'G',$90
	dc.b	0,1,0,1,'G',$90,0,1
	dc.b	0,1,'G',$98,$80,0,$80,0
	dc.b	'H8@',0,'@',0,'H8'
	dc.b	'@',0,'@',0,'H8 ',0
	dc.b	' ',0,'H8',$10,0,$10,0
	dc.b	'H8',8,0,8,0,'H',$d8
	dc.b	4,0,4,0,'H',$d8,2,0
	dc.b	2,0,'H',$d8,1,0,1,0
	dc.b	'Ix',0,'@',0,'@Ix'
	dc.b	0,' ',0,' Ix',0,$10
	dc.b	0,$10,'J',$18,0,4,0,4
	dc.b	'J',$18,0,1,0,1,'J '
	dc.b	'@',0,'@',0,'J',$c0,$10,0
	dc.b	$10,0,'J',$c0,4,0,4,0
	dc.b	'K`',1,0,1,0,'L',0
	dc.b	0,' ',0,' L',0,0,2
	dc.b	0,2,'L',$a8,'@',0,'@',0
	dc.b	'MH',2,0,2,0,'M',$e8
	dc.b	0,$10,0,$10
	jsr	(a0)
	dc.b	'@',0,'@',0,'O',$d0,0,$80
	dc.b	0,$80,'Q',$18,'@',0,'@',0
	dc.b	'RX',0,8,0,8,'T@'
	dc.b	0,' ',0,' V',$c8,0,2
	dc.b	0,2,'Z',$98,0,' ',0,' '
	dc.b	$ff,$ff,'<P',$80,0,0,0
	dc.b	';',$b0,$80,0,0,0,';',$b0
	dc.b	$80,0,0,0,';',$b0,$80,0
	dc.b	0,0,';',$b0,$80,0,0,0
	dc.b	';',$b0,$80,0,0,0,';',$b0
	dc.b	$80,0,0,0,';',$b0,$80,0
	dc.b	0,0,';',$b0,$80,0,0,0
	dc.b	';',$b0,$80,0,0,0,';',$a8
	dc.b	0,1,0,0,';',$a8,0,1
	dc.b	0,0,';',$a8,0,1,0,0
	dc.b	';',$a8,0,1,0,0,';',$a8
	dc.b	0,1,0,0,';',$a8,0,1
	dc.b	0,0,';',$a8,0,1,0,0
	dc.b	';',$a8,0,1,0,0,';',$a8
	dc.b	0,1,0,0,';',$a8,0,1
	dc.b	0,0,';',$a8,0,1,0,0
	dc.b	';',$a8,0,1,0,0,';',$a8
	dc.b	0,1,0,0,';',$a8,0,2
	dc.b	0,0,';',$a8,0,2,0,0
	dc.b	';',$a8,0,2,0,0,';',$a8
	dc.b	0,2,0,0,';',$a8,0,2
	dc.b	0,0,';',$a8,0,2,0,0
	dc.b	';',$a8,0,2,0,0,';',$a8
	dc.b	0,2,0,0,';',8,0,2
	dc.b	0,0,';',8,0,2,0,0
	dc.b	';',8,0,2,0,0,';',8
	dc.b	0,4,0,0,';',8,0,4
	dc.b	0,0,';',8,0,0,0,4
	dc.b	';',8,0,0,0,4,';',8
	dc.b	0,0,0,4,';',8,0,0
	dc.b	0,4,';',8,0,0,0,4
	dc.b	';',8,0,0,0,4,';',8
	dc.b	0,0,0,4,';',8,0,0
	dc.b	0,8,';',8,0,0,0,8
	dc.b	';',8,0,0,0,8,';',8
	dc.b	0,0,0,8,';',8,0,0
	dc.b	0,8,';',8,0,0,0,8
	dc.b	';',8,0,0,0,8,';',8
	dc.b	0,0,0,8,';',8,0,0
	dc.b	0,$10,';',8,0,0,0,$10
	dc.b	';',8,0,0,0,$10,';',8
	dc.b	0,0,0,$10,';',8,0,0
	dc.b	0,$10,';',8,0,0,0,$10
	dc.b	';',8,0,0,0,$10,';',8
	dc.b	0,0,0,' ;',8,0,0
	dc.b	0,' ;',8,0,0,0,' '
	dc.b	';',8,0,0,0,' ;',8
	dc.b	0,0,0,' ;',8,0,0
	dc.b	0,' ;',8,0,0,0,' '
	dc.b	';',8,0,0,0,'@;',8
	dc.b	0,0,0,'@;',8,0,0
	dc.b	0,'@;',8,0,0,0,'@'
	dc.b	';',8,0,0,0,'@;',8
	dc.b	0,0,0,$80,';',8,0,0
	dc.b	0,$80,';',8,0,0,0,$80
	dc.b	';',8,0,0,0,$80,';',$a8
	dc.b	0,0,0,$80,';',$a8,0,0
	dc.b	1,0,';',$a8,1,0,1,0
	dc.b	';',$a8,1,0,1,0,';',$a8
	dc.b	1,0,1,0,';',$a8,2,0
	dc.b	2,0,';',$a8,2,0,2,0
	dc.b	';',$a8,2,0,2,0,';',$a8
	dc.b	2,0,2,0,';',$a8,4,0
	dc.b	4,0,';',$a8,4,0,4,0
	dc.b	';',$a8,4,0,4,0,';',$a8
	dc.b	8,0,8,0,';',$a8,8,0
	dc.b	8,0,';',$a8,8,0,8,0
	dc.b	';',$a8,$10,0,$10,0,';',$a8
	dc.b	$10,0,$10,0,'<H',$10,0
	dc.b	$10,0,'<H ',0,' ',0
	dc.b	'<H ',0,' ',0,'<H'
	dc.b	'@',0,'@',0,'<H@',0
	dc.b	'@',0,'<H',$80,0,$80,0
	dc.b	'<H',$80,0,$80,0,'<@'
	dc.b	0,1,0,1,'<',$e0,0,1
	dc.b	0,1,'<',$e0,0,2,0,2
	dc.b	'<',$e0,0,2,0,2,'<',$e0
	dc.b	0,4,0,4,'<',$e0,0,8
	dc.b	0,8,'=',$80,0,$10,0,$10
	dc.b	'=',$80,0,$10,0,$10,'=',$80
	dc.b	0,' ',0,' > ',0,'@'
	dc.b	0,'@> ',0,$80,0,$80
	dc.b	'> ',2,0,2,0,'>',$c0
	dc.b	4,0,4,0,'>',$c0,8,0
	dc.b	8,0,'?` ',0,' ',0
	dc.b	'?`@',0,'@',0,'?',$f8
	dc.b	0,1,0,1,'?',$f8,0,4
	dc.b	0,4,'@',$98,0,' ',0,' '
	dc.b	'A8',1,0,1,0,'A',$d8
	dc.b	8,0,8,0,'Bx',$80,0
	dc.b	$80,0,'C',$b0,0,8,0,8
	dc.b	'D',$f0,2,0,2,0,'F('
	dc.b	0,1,0,1,'H',8,2,0
	dc.b	2,0,'J',$80,0,' ',0,' '
	dc.b	'N8',0,'@',0,'@S0'
	dc.b	$80,0,$80,0,$ff,$ff,'B',$88
	dc.b	0,2,0,0,'B',$88,0,2
	dc.b	0,0,'B',$88,0,2,0,0
	dc.b	'B',$88,0,2,0,0,'B',$88
	dc.b	0,2,0,0,'B',$88,0,2
	dc.b	0,0,'B',$88,0,1,0,0
	dc.b	'B',$88,0,1,0,0,'C('
	dc.b	0,1,0,0,'C(',0,1
	dc.b	0,0,'C(',0,1,0,0
	dc.b	'C(',0,1,0,0,'C('
	dc.b	0,1,0,0,'C(',0,1
	dc.b	0,0,'C(',0,1,0,0
	dc.b	'C0',$80,0,0,0,'C0'
	dc.b	$80,0,0,0,'C0',$80,0
	dc.b	0,0,'C0',$80,0,0,0
	dc.b	'C0',$80,0,0,0,'C0'
	dc.b	$80,0,0,0,'C0',$80,0
	dc.b	0,0,'C0',$80,0,0,0
	dc.b	'C',$d0,'@',0,0,0,'C',$d0
	dc.b	'@',0,0,0,'C',$d0,'@',0
	dc.b	0,0,'C',$d0,'@',0,0,0
	dc.b	'C',$d0,'@',0,0,0,'C',$d0
	dc.b	'@',0,0,0,'C',$d0,'@',0
	dc.b	0,0,'C',$d0,' ',0,0,0
	dc.b	'C',$d0,' ',0,0,0,'C',$d0
	dc.b	' ',0,0,0,'C',$d0,' ',0
	dc.b	0,0,'C',$d0,' ',0,0,0
	dc.b	'C',$d0,' ',0,0,0,'C',$d0
	dc.b	0,0,$10,0,'C',$d0,0,0
	dc.b	$10,0,'C',$d0,0,0,$10,0
	dc.b	'C',$d0,0,0,$10,0,'C',$d0
	dc.b	0,0,$10,0,'C',$d0,0,0
	dc.b	$10,0,'C',$d0,0,0,8,0
	dc.b	'C',$d0,0,0,8,0,'Dp'
	dc.b	0,0,8,0,'Dp',0,0
	dc.b	8,0,'Dp',0,0,8,0
	dc.b	'Dp',0,0,4,0,'Dp'
	dc.b	0,0,4,0,'Dp',0,0
	dc.b	4,0,'Dp',0,0,4,0
	dc.b	'Dp',0,0,4,0,'Dp'
	dc.b	0,0,2,0,'Dp',0,0
	dc.b	2,0,'Dp',0,0,2,0
	dc.b	'Dp',0,0,2,0,'Dp'
	dc.b	0,0,1,0,'Dp',0,0
	dc.b	1,0,'Dp',0,0,1,0
	dc.b	'Dp',0,0,1,0,'Dp'
	dc.b	0,0,0,$80,'Dp',0,0
	dc.b	0,$80,'Dp',0,0,0,$80
	dc.b	'Dp',0,0,0,$80,'Dp'
	dc.b	0,0,0,'@Dp',0,0
	dc.b	0,'@Dp',0,0,0,'@'
	dc.b	'Dp',0,0,0,' Dp'
	dc.b	0,0,0,' Dp',0,0
	dc.b	0,' Dp',0,0,0,$10
	dc.b	'Dp',0,0,0,$10,'Dp'
	dc.b	0,0,0,$10,'Dp',0,0
	dc.b	0,8,'Dp',0,0,0,8
	dc.b	'Dp',0,0,0,8,'Dp'
	dc.b	0,4,0,4,'Dp',0,4
	dc.b	0,4,'Dp',0,2,0,2
	dc.b	'C',$d0,0,2,0,2,'C',$d0
	dc.b	0,2,0,2,'C',$d0,0,1
	dc.b	0,1,'C',$d0,0,1,0,1
	dc.b	'C',$d8,$80,0,$80,0,'C',$d8
	dc.b	$80,0,$80,0,'C',$d8,'@',0
	dc.b	'@',0,'C',$d8,'@',0,'@',0
	dc.b	'C',$d8,' ',0,' ',0,'C',$d8
	dc.b	$10,0,$10,0,'C',$d8,$10,0
	dc.b	$10,0,'C',$d8,8,0,8,0
	dc.b	'C',$d8,8,0,8,0,'C8'
	dc.b	4,0,4,0,'C8',2,0
	dc.b	2,0,'C8',1,0,1,0
	dc.b	'C8',1,0,1,0,'C8'
	dc.b	0,$80,0,$80,'C8',0,'@'
	dc.b	0,'@B',$98,0,' ',0,' '
	dc.b	'B',$98,0,$10,0,$10,'B',$98
	dc.b	0,8,0,8,'B',$98,0,4
	dc.b	0,4,'A',$f8,0,2,0,2
	dc.b	'A',$f8,0,1,0,1,'B',0
	dc.b	'@',0,'@',0,'B',0,' ',0
	dc.b	' ',0,'A`',8,0,8,0
	dc.b	'A`',4,0,4,0,'@',$c0
	dc.b	1,0,1,0,'@',$c0,0,'@'
	dc.b	0,'@@ ',0,$10,0,$10
	dc.b	'@ ',0,2,0,2,'?',$88
	dc.b	'@',0,'@',0,'?',$88,8,0
	dc.b	8,0,'>',$e8,1,0,1,0
	dc.b	'>H',0,$10,0,$10,'=',$a8
	dc.b	0,1,0,1,'=',$10,8,0
	dc.b	8,0,';',$d0,0,' ',0,' '
	dc.b	':',$98,'@',0,'@',0,'9X'
	dc.b	0,'@',0,'@8 ',$10,0
	dc.b	$10,0,'6H',$80,0,$80,0
	dc.b	'3',$d0,'@',0,'@',0,'0',$18
	dc.b	0,$80,0,$80,$ff,$ff,'4',$c0
	dc.b	0,2,0,0,'4',$c0,0,2
	dc.b	0,0,'4',$c0,0,2,0,0
	dc.b	'4',$c0,0,4,0,0,'5`'
	dc.b	0,4,0,0,'5`',0,8
	dc.b	0,0,'5`',0,8,0,0
	dc.b	'5`',0,$10,0,0,'5`'
	dc.b	0,$10,0,0,'5`',0,' '
	dc.b	0,0,'5`',0,' ',0,0
	dc.b	'6',0,0,'@',0,0,'6',0
	dc.b	0,'@',0,0,'6',0,0,'@'
	dc.b	0,0,'6',0,0,$80,0,0
	dc.b	'6',0,0,$80,0,0,'6',$a0
	dc.b	1,0,0,0,'6',$a0,1,0
	dc.b	0,0,'6',$a0,2,0,0,0
	dc.b	'6',$a0,2,0,0,0,'7@'
	dc.b	4,0,0,0,'7@',8,0
	dc.b	0,0,'7@',8,0,0,0
	dc.b	'7@',$10,0,0,0,'7',$e0
	dc.b	$10,0,0,0,'7',$e0,' ',0
	dc.b	0,0,'7',$e0,' ',0,0,0
	dc.b	'8',$80,'@',0,0,0,'8',$80
	dc.b	$80,0,0,0,'8',$80,$80,0
	dc.b	0,0,'9',$18,0,1,0,0
	dc.b	'9',$18,0,1,0,0,'9',$b8
	dc.b	0,2,0,0,'9',$b8,0,4
	dc.b	0,0,'9',$b8,0,4,0,0
	dc.b	':X',0,8,0,0,':X'
	dc.b	0,0,0,$10,':',$f8,0,0
	dc.b	0,$10,':',$f8,0,0,0,' '
	dc.b	';',$98,0,0,0,'@;',$98
	dc.b	0,0,0,$80,'<8',0,0
	dc.b	0,$80,'<8',0,0,1,0
	dc.b	'<',$d8,0,0,2,0,'=x'
	dc.b	0,0,4,0,'=x',0,0
	dc.b	8,0,'>',$18,0,0,8,0
	dc.b	'>',$b8,0,0,$10,0,'>',$b8
	dc.b	0,0,' ',0,'?X',0,0
	dc.b	'@',0,'?',$f8,0,0,$80,0
	dc.b	'@',$90,0,0,0,1,'A0'
	dc.b	0,0,0,2,'A0',0,0
	dc.b	0,4,'A',$d0,0,0,0,8
	dc.b	'Bp',0,0,0,' C',$10
	dc.b	0,0,0,'@C',$b0,0,0
	dc.b	0,$80,'D',$f0,0,0,1,0
	dc.b	'E',$90,0,0,4,0,'F0'
	dc.b	0,0,8,0,'F',$d0,0,0
	dc.b	$10,0,'H',$10,0,0,'@',0
	dc.b	'H',$a8,0,0,0,1,'I',$e8
	dc.b	0,0,0,2,'J',$88,0,0
	dc.b	0,8,'K',$c8,0,0,0,' '
	dc.b	'M',8,0,0,0,$80,'NH'
	dc.b	0,0,2,0,'O',$88,0,0
	dc.b	8,0,'P',$c8,0,0,'@',0
	dc.b	'R',$a0,0,0,0,1,'S',$e0
	dc.b	0,0,0,8,'U',$c0,0,0
	dc.b	0,'@W',$a0,0,0,2,0
	dc.b	'Z ',0,0,$10,0,'[',$f8
	dc.b	0,1,0,1,'^x',0,$10
	dc.b	0,$10,'a',$98,2,0,2,0
	dc.b	'd',$b8,'@',0,'@',0,'g',$d0
	dc.b	0,8,0,8,'k',$90,4,0
	dc.b	4,0,'o',$e8,0,2,0,2
	dc.b	't',$e8,2,0,2,0,'z',$80
	dc.b	0,4,0,4,$ff,$ff,'T',$a0
	dc.b	2,0,0,0,'U@',1,0
	dc.b	0,0,'U',$e0,1,0,0,0
	dc.b	'V',$80,1,0,0,0,'W '
	dc.b	1,0,0,0,'W',$c0,1,0
	dc.b	0,0,'X`',0,$80,0,0
	dc.b	'Y',0,0,$80,0,0,'Y',$a0
	dc.b	0,$80,0,0,'Z@',0,$80
	dc.b	0,0,'[',$80,0,'@',0,0
	dc.b	'\ ',0,'@',0,0,'\',$c0
	dc.b	0,'@',0,0,'^',0,0,' '
	dc.b	0,0,'^',$a0,0,' ',0,0
	dc.b	'_@',0,' ',0,0,'`',$80
	dc.b	0,$10,0,0,'a ',0,$10
	dc.b	0,0,'b`',0,$10,0,0
	dc.b	'c',$a0,0,8,0,0,'d@'
	dc.b	0,8,0,0,'e',$80,0,4
	dc.b	0,0,'f',$c0,0,2,0,0
	dc.b	'h',0,0,2,0,0,'i@'
	dc.b	0,1,0,0,'j',$80,0,1
	dc.b	0,0,'k',$c8,$80,0,0,0
	dc.b	'm',8,'@',0,0,0,'n',$e8
	dc.b	' ',0,0,0,'p( ',0
	dc.b	0,0,'r',8,$10,0,0,0
	dc.b	's',$e8,8,0,0,0,'u',$c8
	dc.b	4,0,0,0,'w',$a8,2,0
	dc.b	0,0,'y',$88,0,$80,0,0
	dc.b	'|',8,0,'@',0,0,$ff,$ff
	dc.b	'J',$b0,4,0,0,0,'KP'
	dc.b	2,0,0,0,'KP',2,0
	dc.b	0,0,'KP',1,0,0,0
	dc.b	'KP',1,0,0,0,'KP'
	dc.b	1,0,0,0,'KP',0,$80
	dc.b	0,0,'KP',0,$80,0,0
	dc.b	'KP',0,'@',0,0,'K',$f0
	dc.b	0,'@',0,0,'K',$f0,0,' '
	dc.b	0,0,'K',$f0,0,' ',0,0
	dc.b	'K',$f0,0,$10,0,0,'K',$f0
	dc.b	0,$10,0,0,'K',$f0,0,8
	dc.b	0,0,'K',$f0,0,8,0,0
	dc.b	'K',$f0,0,4,0,0,'K',$f0
	dc.b	0,4,0,0,'K',$f0,0,2
	dc.b	0,0,'L',$90,0,2,0,0
	dc.b	'L',$90,0,1,0,0,'L',$90
	dc.b	0,1,0,0,'L',$98,$80,0
	dc.b	0,0,'L',$98,'@',0,0,0
	dc.b	'L',$98,'@',0,0,0,'L',$98
	dc.b	' ',0,0,0,'L',$98,' ',0
	dc.b	0,0,'L',$98,$10,0,0,0
	dc.b	'L',$98,8,0,0,0,'L',$98
	dc.b	8,0,0,0,'L',$98,4,0
	dc.b	0,0,'L',$98,2,0,0,0
	dc.b	'L',$98,1,0,0,0,'L',$98
	dc.b	1,0,0,0,'L',$98,0,$80
	dc.b	0,0,'L',$98,0,'@',0,0
	dc.b	'L',$98,0,0,0,' L',$98
	dc.b	0,0,0,$10,'L',$98,0,0
	dc.b	0,8,'L',$98,0,0,0,4
	dc.b	'L',$98,0,0,0,2,'L',$98
	dc.b	0,0,0,1,'L',$a0,0,0
	dc.b	$80,0,'L',$a0,0,0,'@',0
	dc.b	'L',$a0,0,0,' ',0,'L',$a0
	dc.b	0,0,$10,0,'L',$a0,0,0
	dc.b	8,0,'L',$a0,0,0,4,0
	dc.b	'L',$a0,0,0,1,0,'L',$a0
	dc.b	0,0,0,$80,'L',$a0,0,0
	dc.b	0,'@L',$a0,0,0,0,$10
	dc.b	'L',$a0,0,0,0,8,'L',$a0
	dc.b	0,0,0,2,'L',$a8,0,0
	dc.b	$80,0,'L',$a8,0,0,' ',0
	dc.b	'L',8,0,0,$10,0,'L',8
	dc.b	0,0,4,0,'L',8,0,0
	dc.b	1,0,'L',8,0,0,0,' '
	dc.b	'L',8,0,0,0,8,'Kh'
	dc.b	0,0,0,1,'Kp',0,0
	dc.b	'@',0,'Kp',0,0,8,0
	dc.b	'Kp',0,0,1,0,'J',$d0
	dc.b	0,0,0,$10,'J',$d0,0,0
	dc.b	0,2,'J',$d8,0,0,' ',0
	dc.b	'J8',0,0,2,0,'J8'
	dc.b	0,0,0,$10,'I',$a0,0,0
	dc.b	$80,0,'I',0,0,0,2,0
	dc.b	'I',0,0,0,0,8,'Hh'
	dc.b	0,0,$10,0,'G',$c8,0,0
	dc.b	0,$10,'G0',0,0,4,0
	dc.b	'F',$90,0,1,0,1,'EX'
	dc.b	0,8,0,8,$ff,$ff,'2',$f0
	dc.b	0,$80,0,0,'2',$f0,1,0
	dc.b	0,0,'2P',1,0,0,0
	dc.b	'2P',1,0,0,0,'2P'
	dc.b	1,0,0,0,'2P',2,0
	dc.b	0,0,'1',$b0,2,0,0,0
	dc.b	'1',$b0,2,0,0,0,'1',$b0
	dc.b	2,0,0,0,'1',$b0,4,0
	dc.b	0,0,'1',$10,4,0,0,0
	dc.b	'1',$10,4,0,0,0,'1',$10
	dc.b	8,0,0,0,'0p',8,0
	dc.b	0,0,'0p',8,0,0,0
	dc.b	'0p',$10,0,0,0,'0p'
	dc.b	$10,0,0,0,'/',$d0,$10,0
	dc.b	0,0,'/',$d0,' ',0,0,0
	dc.b	'/',$d0,' ',0,0,0,'/',$d0
	dc.b	' ',0,0,0,'/0@',0
	dc.b	0,0,'/0@',0,0,0
	dc.b	'/0@',0,0,0,'/0'
	dc.b	$80,0,0,0,'.',$90,$80,0
	dc.b	0,0,'.',$90,$80,0,0,0
	dc.b	'.',$88,0,1,0,0,'.',$88
	dc.b	0,1,0,0,'-',$e8,0,2
	dc.b	0,0,'-',$e8,0,2,0,0
	dc.b	'-',$e8,0,4,0,0,'-',$e8
	dc.b	0,4,0,0,'-H',0,4
	dc.b	0,0,'-H',0,8,0,0
	dc.b	'-H',0,8,0,0,'-H'
	dc.b	0,0,0,$10,',',$a8,0,0
	dc.b	0,$10,',',$a8,0,0,0,' '
	dc.b	',',$a8,0,0,0,' ,',$a8
	dc.b	0,0,0,'@,',8,0,0
	dc.b	0,'@,',8,0,0,0,$80
	dc.b	',',8,0,0,1,0,',',8
	dc.b	0,0,1,0,'+h',0,0
	dc.b	2,0,'+h',0,0,2,0
	dc.b	'+h',0,0,4,0,'+h'
	dc.b	0,0,8,0,'*',$c8,0,0
	dc.b	8,0,'*',$c8,0,0,$10,0
	dc.b	'*',$c8,0,0,' ',0,'*',$c8
	dc.b	0,0,' ',0,'*',$c8,0,0
	dc.b	'@',0,'*(',0,0,$80,0
	dc.b	'*(',0,0,$80,0,'* '
	dc.b	0,0,0,1,'* ',0,0
	dc.b	0,2,'* ',0,0,0,4
	dc.b	')',$80,0,0,0,4,')',$80
	dc.b	0,0,0,8,')',$80,0,0
	dc.b	0,$10,')',$80,0,0,0,' '
	dc.b	')',$80,0,0,0,'@(',$e0
	dc.b	0,0,0,$80,'(',$e0,0,0
	dc.b	1,0,'(',$e0,0,0,2,0
	dc.b	'(',$e0,0,0,4,0,'(',$e0
	dc.b	0,0,8,0,'(@',0,0
	dc.b	$10,0,'(@',0,0,' ',0
	dc.b	'(@',0,0,'@',0,'(@'
	dc.b	0,0,$80,0,'(8',0,0
	dc.b	0,1,'(8',0,0,0,2
	dc.b	$27,$98,0,0,0,4,$27,$98
	dc.b	0,$10,0,$10,$27,$98,0,' '
	dc.b	0,' ',$27,$98,0,'@',0,'@'
	dc.b	$27,$98,1,0,1,0,$27,$98
	dc.b	2,0,2,0,'&',$f8,8,0
	dc.b	8,0,'&',$f8,$10,0,$10,0
	dc.b	'&',$f8,'@',0,'@',0,'&',$f0
	dc.b	0,1,0,1,'&',$f0,0,4
	dc.b	0,4,'&',$f0,0,8,0,8
	dc.b	'&',$f0,0,' ',0,' &P'
	dc.b	0,$80,0,$80,'&P',4,0
	dc.b	4,0,'&P',$10,0,$10,0
	dc.b	'&P@',0,'@',0,'&H'
	dc.b	0,2,0,2,'&H',0,8
	dc.b	0,8,'&H',0,'@',0,'@'
	dc.b	'&H',2,0,2,0,'%',$a8
	dc.b	$10,0,$10,0,'%',$a8,$80,0
	dc.b	$80,0,'%',$a0,0,8,0,8
	dc.b	'%',$a0,0,$80,0,$80,'%',$a0
	dc.b	8,0,8,0,'%',$a0,$80,0
	dc.b	$80,0,'%',$98,0,$10,0,$10
	dc.b	'%',$98,2,0,2,0,'%',$98
	dc.b	'@',0,'@',0,'$',$f0,0,$10
	dc.b	0,$10,'$',$f0,8,0,8,0
	dc.b	'$',$e8,0,4,0,4,'$',$e8
	dc.b	8,0,8,0,'$',$e0,0,$10
	dc.b	0,$10,'$',$e0,'@',0,'@',0
	dc.b	$ff,$ff,'H8',2,0,0,0
	dc.b	'H8',2,0,0,0,'H8'
	dc.b	1,0,0,0,'H8',1,0
	dc.b	0,0,'H8',0,$80,0,0
	dc.b	'G',$98,0,$80,0,0,'G',$98
	dc.b	0,'@',0,0,'G',$98,0,' '
	dc.b	0,0,'G',$98,0,' ',0,0
	dc.b	'G',$98,0,$10,0,0,'F',$f8
	dc.b	0,$10,0,0,'F',$f8,0,8
	dc.b	0,0,'F',$f8,0,4,0,0
	dc.b	'F',$f8,0,4,0,0,'FX'
	dc.b	0,2,0,0,'FX',0,1
	dc.b	0,0,'FX',0,1,0,0
	dc.b	'E',$c0,$80,0,0,0,'E',$c0
	dc.b	'@',0,0,0,'E',$c0,'@',0
	dc.b	0,0,'E  ',0,0,0
	dc.b	'E ',$10,0,0,0,'E '
	dc.b	8,0,0,0,'D',$80,4,0
	dc.b	0,0,'D',$80,4,0,0,0
	dc.b	'C',$e0,2,0,0,0,'C',$e0
	dc.b	1,0,0,0,'C@',0,$80
	dc.b	0,0,'C@',0,'@',0,0
	dc.b	'B',$a0,0,' ',0,0,'B',$a0
	dc.b	0,$10,0,0,'B',0,0,8
	dc.b	0,0,'B',0,0,4,0,0
	dc.b	'A`',0,2,0,0,'@',$c0
	dc.b	0,1,0,0,'@',$c8,$80,0
	dc.b	0,0,'@(',0,0,'@',0
	dc.b	'?',$88,0,0,$10,0,'?',$88
	dc.b	0,0,8,0,'>',$e8,0,0
	dc.b	4,0,'>H',0,0,1,0
	dc.b	'=',$a8,0,0,0,$80,'=',8
	dc.b	0,0,0,' <h',0,0
	dc.b	0,$10,';',$c8,0,0,0,4
	dc.b	';(',0,0,0,1,':',$90
	dc.b	0,0,$80,0,'9P',0,0
	dc.b	' ',0,'8',$b0,0,0,8,0
	dc.b	'8',$10,0,0,2,0,'6',$d0
	dc.b	0,0,0,'@5',$90,0,0
	dc.b	0,$10,'4',$f0,0,0,0,2
	dc.b	'3',$b8,0,0,$80,0,'2x'
	dc.b	0,0,$10,0,'18',0,0
	dc.b	1,0,'/X',0,0,0,' '
	dc.b	'.',$18,0,0,0,2,',@'
	dc.b	0,0,' ',0,'*`',0,0
	dc.b	2,0,$27,$e0,0,0,0,$10
	dc.b	'%h',0,0,'@',0,'"',$e8
	dc.b	0,0,1,0,$1f,$c8,0,0
	dc.b	0,2,$1c,$b0,0,0,4,0
	dc.b	$18,$f0,0,0,0,2,$13,$f8
	dc.b	0,0,0,$80,$ff,$ff,'<',$f0
	dc.b	1,0,0,0,'<',$f0,1,0
	dc.b	0,0,'<',$f0,1,0,0,0
	dc.b	'<P',1,0,0,0,'<P'
	dc.b	1,0,0,0,'<P',1,0
	dc.b	0,0,'<P',1,0,0,0
	dc.b	'<P',0,$80,0,0,'<P'
	dc.b	0,$80,0,0,'<P',0,$80
	dc.b	0,0,';',$b0,0,$80,0,0
	dc.b	';',$b0,0,$80,0,0,';',$b0
	dc.b	0,$80,0,0,';',$b0,0,$80
	dc.b	0,0,';',$b0,0,$80,0,0
	dc.b	';',$b0,0,$80,0,0,';',$10
	dc.b	0,$80,0,0,';',$10,0,$80
	dc.b	0,0,';',$10,0,$80,0,0
	dc.b	';',$10,0,$80,0,0,';',$10
	dc.b	0,$80,0,0,':p',0,$80
	dc.b	0,0,':p',1,0,0,0
	dc.b	':p',1,0,0,0,':p'
	dc.b	1,0,0,0,':p',1,0
	dc.b	0,0,'9',$d0,1,0,0,0
	dc.b	'9',$d0,1,0,0,0,'9',$d0
	dc.b	1,0,0,0,'9',$d0,1,0
	dc.b	0,0,'9',$d0,1,0,0,0
	dc.b	'90',1,0,0,0,'90'
	dc.b	1,0,0,0,'90',1,0
	dc.b	0,0,'90',1,0,0,0
	dc.b	'90',1,0,0,0,'8',$90
	dc.b	0,0,1,0,'8',$90,0,0
	dc.b	1,0,'8',$90,0,0,1,0
	dc.b	'8',$90,0,0,1,0,'7',$f0
	dc.b	0,0,1,0,'7',$f0,0,0
	dc.b	1,0,'7',$f0,0,0,1,0
	dc.b	'7',$f0,0,0,1,0,'7P'
	dc.b	0,0,2,0,'7P',0,0
	dc.b	2,0,'7P',0,0,2,0
	dc.b	'7P',0,0,2,0,'6',$b0
	dc.b	0,0,2,0,'6',$b0,0,0
	dc.b	2,0,'6',$b0,0,0,2,0
	dc.b	'6',$10,0,0,2,0,'6',$10
	dc.b	0,0,2,0,'6',$10,0,0
	dc.b	2,0,'6',$10,0,0,4,0
	dc.b	'5p',0,0,4,0,'5p'
	dc.b	0,0,4,0,'5p',0,0
	dc.b	4,0,'4',$d0,0,0,4,0
	dc.b	'4',$d0,0,0,4,0,'4',$d0
	dc.b	0,0,4,0,'40',0,0
	dc.b	8,0,'40',0,0,8,0
	dc.b	'40',0,0,8,0,'3',$90
	dc.b	0,0,8,0,'3',$90,0,0
	dc.b	8,0,'2',$f0,0,0,$10,0
	dc.b	'2',$f0,0,0,$10,0,'2',$f0
	dc.b	0,0,$10,0,'2P',0,0
	dc.b	$10,0,'2P',0,0,$10,0
	dc.b	'1',$b0,0,0,' ',0,'1',$b0
	dc.b	0,0,' ',0,'1',$10,0,0
	dc.b	' ',0,'1',$10,0,0,'@',0
	dc.b	'0p',0,0,'@',0,'0p'
	dc.b	'@',0,'@',0,'/',$d0,'@',0
	dc.b	'@',0,'/',$d0,$80,0,$80,0
	dc.b	'/0',$80,0,$80,0,'.',$88
	dc.b	0,1,0,1,'.',$88,0,1
	dc.b	0,1,'-',$e8,0,1,0,1
	dc.b	'-H',0,2,0,2,'-H'
	dc.b	0,2,0,2,',',$a8,0,4
	dc.b	0,4,',',8,0,4,0,4
	dc.b	'+h',0,8,0,8,'*',$c8
	dc.b	0,$10,0,$10,'*(',0,$10
	dc.b	0,$10,')',$88,0,' ',0,' '
	dc.b	'(',$e8,0,'@',0,'@(H'
	dc.b	0,'@',0,'@',$27,$a8,0,$80
	dc.b	0,$80,$27,8,1,0,1,0
	dc.b	'%',$c8,2,0,2,0,'%('
	dc.b	4,0,4,0,'#',$e8,8,0
	dc.b	8,0,'"',$a8,' ',0,' ',0
	dc.b	'!h@',0,'@',0,' ('
	dc.b	$80,0,$80,0,$1e,$e0,0,2
	dc.b	0,2,$1d,0,0,8,0,8
	dc.b	$1b,' ',0,' ',0,' ',$19,'@'
	dc.b	0,$80,0,$80,$16,$c0,4,0
	dc.b	4,0,$14,'@ ',0,' ',0
	dc.b	$11,$18,0,2,0,2,$d,'X'
	dc.b	0,' ',0,' ',8,$f8,4,0
	dc.b	4,0,3,$f0,0,1,0,1
	dc.b	$ff,$ff,$27,$b0,0,' ',0,0
	dc.b	$27,$10,0,' ',0,0,'&p'
	dc.b	0,' ',0,0,'&p',0,'@'
	dc.b	0,0,'%',$d0,0,'@',0,0
	dc.b	'%0',0,$80,0,0,'%0'
	dc.b	1,0,0,0,'$',$90,1,0
	dc.b	0,0,'#',$f0,2,0,0,0
	dc.b	'#',$f0,2,0,0,0,'#P'
	dc.b	4,0,0,0,'"',$b0,4,0
	dc.b	0,0,'"',$b0,8,0,0,0
	dc.b	'"',$10,$10,0,0,0,'!p'
	dc.b	$10,0,0,0,'!p ',0
	dc.b	0,0,' ',$d0,'@',0,0,0
	dc.b	' 0@',0,0,0,$1f,$90
	dc.b	$80,0,0,0,$1f,$88,0,1
	dc.b	0,0,$1e,$e8,0,2,0,0
	dc.b	$1e,'H',0,4,0,0,$1d,$a8
	dc.b	0,8,0,0,$1d,8,0,8
	dc.b	0,0,$1c,'h',0,$10,0,0
	dc.b	$1c,'h',0,' ',0,0,$1b,$c8
	dc.b	0,'@',0,0,$1b,'(',0,$80
	dc.b	0,0,$1a,$88,1,0,0,0
	dc.b	$19,$e8,2,0,0,0,$19,'H'
	dc.b	8,0,0,0,$18,$a8,$10,0
	dc.b	0,0,$18,8,' ',0,0,0
	dc.b	$17,'h@',0,0,0,$16,$c8
	dc.b	$80,0,0,0,$16,' ',0,2
	dc.b	0,0,$15,$80,0,0,0,4
	dc.b	$14,$e0,0,0,0,$10,$13,$a0
	dc.b	0,0,0,' ',$13,0,0,0
	dc.b	0,$80,$12,'`',0,0,1,0
	dc.b	$11,$c0,0,0,4,0,$10,$80
	dc.b	0,0,$10,0,$f,$e0,0,0
	dc.b	'@',0,$e,$98,0,0,0,1
	dc.b	$d,$f8,0,0,0,4,$c,$b8
	dc.b	0,0,0,$10,$c,$18,0,0
	dc.b	0,$80,$a,$d8,0,0,2,0
	dc.b	9,$98,0,0,$10,0,8,'X'
	dc.b	0,0,'@',0,7,$10,0,0
	dc.b	0,2,5,$d0,0,0,0,$10
	dc.b	4,$90,0,0,1,0,3,'P'
	dc.b	0,0,8,0,1,'p',0,0
	dc.b	$80,0,$ff,$ff,'$',0,0,'@'
	dc.b	0,0,'#`',0,'@',0,0
	dc.b	'"',$c0,0,'@',0,0,'!',$80
	dc.b	0,'@',0,0,' ',$e0,0,'@'
	dc.b	0,0,$1f,$a0,0,'@',0,0
	dc.b	$1f,0,0,'@',0,0,$1d,$c0
	dc.b	0,$80,0,0,$1c,$80,0,$80
	dc.b	0,0,$1b,$e0,0,$80,0,0
	dc.b	$1a,$a0,0,$80,0,0,$19,'`'
	dc.b	0,$80,0,0,$18,' ',0,$80
	dc.b	0,0,$17,$80,0,$80,0,0
	dc.b	$16,'@',0,$80,0,0,$15,0
	dc.b	1,0,0,0,$13,' ',1,0
	dc.b	0,0,$11,$e0,1,0,0,0
	dc.b	$10,$a0,1,0,0,0,$f,'`'
	dc.b	1,0,0,0,$d,$80,2,0
	dc.b	0,0,$c,'@',2,0,0,0
	dc.b	$a,'`',2,0,0,0,8,$80
	dc.b	4,0,0,0,6,$a0,4,0
	dc.b	0,0,4,$c0,8,0,0,0
	dc.b	2,$e0,8,0,0,0,1,0
	dc.b	$10,0,0,0,$ff,$ff,';',$b0
	dc.b	' ',0,0,0,';',$b0,'@',0
	dc.b	0,0,';',$b0,'@',0,0,0
	dc.b	';',$10,'@',0,0,0,';',$10
	dc.b	'@',0,0,0,';',$10,'@',0
	dc.b	0,0,';',$10,'@',0,0,0
	dc.b	';',$10,'@',0,0,0,';',$10
	dc.b	'@',0,0,0,';',$10,'@',0
	dc.b	0,0,';',$10,'@',0,0,0
	dc.b	';',$10,'@',0,0,0,';',$10
	dc.b	'@',0,0,0,';',$10,'@',0
	dc.b	0,0,';',$10,'@',0,0,0
	dc.b	':p',$80,0,0,0,':p'
	dc.b	$80,0,0,0,':p',$80,0
	dc.b	0,0,':p',$80,0,0,0
	dc.b	':p',$80,0,0,0,':p'
	dc.b	$80,0,0,0,':p',$80,0
	dc.b	0,0,':p',$80,0,0,0
	dc.b	':p',$80,0,0,0,':p'
	dc.b	$80,0,0,0,'9',$d0,$80,0
	dc.b	0,0,'9',$c8,0,1,0,0
	dc.b	'9',$c8,0,1,0,0,'9',$c8
	dc.b	0,1,0,0,'9',$c8,0,1
	dc.b	0,0,'9',$c8,0,1,0,0
	dc.b	'9',$c8,0,1,0,0,'9',$c8
	dc.b	0,1,0,0,'9',$c8,0,1
	dc.b	0,0,'9',$c8,0,2,0,0
	dc.b	'9(',0,2,0,0,'9('
	dc.b	0,0,0,2,'9(',0,0
	dc.b	0,2,'9(',0,0,0,2
	dc.b	'9(',0,0,0,2,'9('
	dc.b	0,0,0,4,'9(',0,0
	dc.b	0,4,'9(',0,0,0,4
	dc.b	'9(',0,0,0,4,'8',$88
	dc.b	0,0,0,4,'8',$88,0,0
	dc.b	0,4,'8',$88,0,0,0,8
	dc.b	'8',$88,0,0,0,8,'8',$88
	dc.b	0,0,0,8,'8',$88,0,0
	dc.b	0,8,'8',$88,0,0,0,$10
	dc.b	'8',$88,0,0,0,$10,'7',$e8
	dc.b	0,0,0,$10,'7',$e8,0,0
	dc.b	0,$10,'7',$e8,0,0,0,' '
	dc.b	'7',$e8,0,0,0,' 7',$e8
	dc.b	0,0,0,' 7',$e8,0,0
	dc.b	0,' 7H',0,0,0,'@'
	dc.b	'7H',0,0,0,'@7H'
	dc.b	0,0,0,'@7H',0,0
	dc.b	0,$80,'7H',0,0,0,$80
	dc.b	'6',$a8,0,0,1,0,'6',$a8
	dc.b	0,0,1,0,'6',$a8,0,0
	dc.b	1,0,'6',$a8,0,0,2,0
	dc.b	'6',$a8,0,0,2,0,'6',8
	dc.b	0,0,4,0,'6',8,0,0
	dc.b	8,0,'6',8,0,0,8,0
	dc.b	'5h',0,0,$10,0,'5h'
	dc.b	0,0,$10,0,'5h',0,0
	dc.b	' ',0,'4',$c8,0,0,'@',0
	dc.b	'4',$c8,0,0,$80,0,'4',$c0
	dc.b	0,1,0,1,'4 ',0,2
	dc.b	0,2,'4 ',0,4,0,4
	dc.b	'3',$80,0,8,0,8,'2',$e0
	dc.b	0,$10,0,$10,'2',$e0,0,'@'
	dc.b	0,'@2@',1,0,1,0
	dc.b	'1',$a0,2,0,2,0,'1',0
	dc.b	$10,0,$10,0,'0`@',0
	dc.b	'@',0,'/',$b8,0,2,0,2
	dc.b	'.x',0,$10,0,$10,'-',$d8
	dc.b	1,0,1,0,',',$98,' ',0
	dc.b	' ',0,'*',$b0,0,4,0,4
	dc.b	'(',$d0,4,0,4,0,'&H'
	dc.b	0,8,0,8,'"',$80,0,1
	dc.b	0,1,$1d,'x',0,4,0,4
	dc.b	$15,'P@',0,'@',0,$ff,$ff
	dc.b	'\',$d8,'@',0,0,0,']x'
	dc.b	' ',0,0,0,']x',$10,0
	dc.b	0,0,']x',8,0,0,0
	dc.b	'^',$18,4,0,0,0,'^',$18
	dc.b	1,0,0,0,'^',$b8,0,$80
	dc.b	0,0,'^',$b8,0,'@',0,0
	dc.b	'_X',0,' ',0,0,'_X'
	dc.b	0,8,0,0,'_X',0,4
	dc.b	0,0,'_',$f8,0,2,0,0
	dc.b	'`',0,$80,0,0,0,'`',$a0
	dc.b	'@',0,0,0,'`',$a0,$10,0
	dc.b	0,0,'a@',8,0,0,0
	dc.b	'a@',2,0,0,0,'a',$e0
	dc.b	1,0,0,0,'a',$e0,0,'@'
	dc.b	0,0,'b',$80,0,$10,0,0
	dc.b	'b',$80,0,8,0,0,'c '
	dc.b	0,2,0,0,'c(',$80,0
	dc.b	0,0,'c',$c8,' ',0,0,0
	dc.b	'c',$c8,8,0,0,0,'dh'
	dc.b	1,0,0,0,'dh',0,'@'
	dc.b	0,0,'e',8,0,$10,0,0
	dc.b	'e',8,0,2,0,0,'e',$b0
	dc.b	$80,0,0,0,'e',$b0,$10,0
	dc.b	0,0,'fP',2,0,0,0
	dc.b	'fP',0,'@',0,0,'f',$f0
	dc.b	0,8,0,0,'g',$90,0,1
	dc.b	0,0,'g',$98,' ',0,0,0
	dc.b	'h8',0,0,2,0,'h',$d8
	dc.b	0,0,0,' h',$d8,0,0
	dc.b	0,2,'i',$80,0,0,' ',0
	dc.b	'j ',0,0,1,0,'j',$c0
	dc.b	0,0,0,$10,'kh',0,0
	dc.b	'@',0,'l',8,0,0,2,0
	dc.b	'l',$a8,0,0,0,8,'mP'
	dc.b	0,0,$10,0,'m',$f0,0,0
	dc.b	0,' n',$98,0,0,'@',0
	dc.b	'o',$d8,0,0,0,' ',$ff,$ff
	dc.b	'B',$88,'@',0,0,0,'B',$88
	dc.b	'@',0,0,0,'B',$88,'@',0
	dc.b	0,0,'B',$88,'@',0,0,0
	dc.b	'C(@',0,0,0,'C('
	dc.b	'@',0,0,0,'C(@',0
	dc.b	0,0,'C',$c8,'@',0,0,0
	dc.b	'C',$c8,'@',0,0,0,'C',$c8
	dc.b	'@',0,0,0,'Dh@',0
	dc.b	0,0,'Dh@',0,0,0
	dc.b	'Dh@',0,0,0,'Dh'
	dc.b	'@',0,0,0,'E',8,'@',0
	dc.b	0,0,'E',8,'@',0,0,0
	dc.b	'E',8,'@',0,0,0,'E',$a8
	dc.b	'@',0,0,0,'E',$a8,'@',0
	dc.b	0,0,'E',$a8,'@',0,0,0
	dc.b	'FH@',0,0,0,'FH'
	dc.b	'@',0,0,0,'FH@',0
	dc.b	0,0,'F',$e8,'@',0,0,0
	dc.b	'F',$e8,' ',0,0,0,'F',$e8
	dc.b	' ',0,0,0,'G',$88,' ',0
	dc.b	0,0,'G',$88,' ',0,0,0
	dc.b	'H( ',0,0,0,'H('
	dc.b	' ',0,0,0,'H( ',0
	dc.b	0,0,'H',$c8,' ',0,0,0
	dc.b	'H',$c8,' ',0,0,0,'H',$c8
	dc.b	' ',0,0,0,'Ih',$10,0
	dc.b	0,0,'Ih',$10,0,0,0
	dc.b	'J',8,0,0,$10,0,'J',8
	dc.b	0,0,$10,0,'J',8,0,0
	dc.b	$10,0,'J',$a8,0,0,$10,0
	dc.b	'J',$a8,0,0,8,0,'KH'
	dc.b	0,0,8,0,'KH',0,0
	dc.b	8,0,'K',$e8,0,0,8,0
	dc.b	'K',$e8,0,0,8,0,'K',$e8
	dc.b	0,0,8,0,'L',$88,0,0
	dc.b	4,0,'L',$88,0,0,4,0
	dc.b	'M(',0,0,4,0,'M('
	dc.b	0,0,4,0,'M',$c8,0,0
	dc.b	2,0,'M',$c8,0,0,2,0
	dc.b	'Nh',0,0,2,0,'Nh'
	dc.b	0,0,2,0,'O',8,0,0
	dc.b	1,0,'O',8,0,0,1,0
	dc.b	'O',$a8,0,0,1,0,'O',$a8
	dc.b	0,0,0,$80,'PH',0,0
	dc.b	0,$80,'PH',0,0,0,$80
	dc.b	'P',$e8,0,0,0,'@P',$e8
	dc.b	0,0,0,'@Q',$88,0,0
	dc.b	0,'@R(',0,0,0,' '
	dc.b	'R(',0,0,0,' R',$c8
	dc.b	0,0,0,$10,'R',$c8,0,0
	dc.b	0,$10,'Sh',0,0,0,$10
	dc.b	'T',8,0,0,0,8,'T',8
	dc.b	0,0,0,8,'T',$a8,0,0
	dc.b	0,4,'UH',0,0,0,4
	dc.b	'UH',0,0,0,2,'U',$e8
	dc.b	0,0,0,1,'V',$88,0,0
	dc.b	0,1,'V',$90,0,0,$80,0
	dc.b	'W0',$80,0,$80,0,'W',$d0
	dc.b	'@',0,'@',0,'Xp ',0
	dc.b	' ',0,'Y',$10,' ',0,' ',0
	dc.b	'Y',$b0,$10,0,$10,0,'Y',$b0
	dc.b	8,0,8,0,'ZP',4,0
	dc.b	4,0,'Z',$f0,2,0,2,0
	dc.b	'[',$90,2,0,2,0,'\0'
	dc.b	1,0,1,0,'\',$d0,0,$80
	dc.b	0,$80,']p',0,'@',0,'@'
	dc.b	'^',$b0,0,' ',0,' _P'
	dc.b	0,$10,0,$10,'_',$f0,0,4
	dc.b	0,4,'`',$90,0,2,0,2
	dc.b	'a',$d0,0,1,0,1,'bx'
	dc.b	'@',0,'@',0,'c',$b8,' ',0
	dc.b	' ',0,'dX',8,0,8,0
	dc.b	'e',$98,4,0,4,0,'f',$d8
	dc.b	1,0,1,0,'h',$18,0,'@'
	dc.b	0,'@iX',0,$10,0,$10
	dc.b	'j',$98,0,4,0,4,'k',$d8
	dc.b	0,1,0,1,'m',$c0,' ',0
	dc.b	' ',0,'o',0,4,0,4,0
	dc.b	'p',$e0,1,0,1,0,'r',$c0
	dc.b	0,$10,0,$10,'u@',0,2
	dc.b	0,2,'w( ',0,' ',0
	dc.b	'zH',2,0,2,0,'|',$c8
	dc.b	0,$10,0,$10,$ff,$ff,'B',$98
	dc.b	8,0,0,0,'B',$98,8,0
	dc.b	0,0,'B',$98,8,0,0,0
	dc.b	'A',$f8,4,0,0,0,'A',$f8
	dc.b	4,0,0,0,'A',$f8,4,0
	dc.b	0,0,'AX',2,0,0,0
	dc.b	'AX',2,0,0,0,'AX'
	dc.b	2,0,0,0,'@',$b8,2,0
	dc.b	0,0,'@',$b8,1,0,0,0
	dc.b	'@',$b8,1,0,0,0,'@',$18
	dc.b	1,0,0,0,'@',$18,1,0
	dc.b	0,0,'@',$18,0,$80,0,0
	dc.b	'?x',0,$80,0,0,'?x'
	dc.b	0,$80,0,0,'?x',0,$80
	dc.b	0,0,'>',$d8,0,'@',0,0
	dc.b	'>',$d8,0,'@',0,0,'>8'
	dc.b	0,'@',0,0,'>8',0,' '
	dc.b	0,0,'>8',0,' ',0,0
	dc.b	'=',$98,0,' ',0,0,'=',$98
	dc.b	0,' ',0,0,'<',$f8,0,$10
	dc.b	0,0,'<',$f8,0,$10,0,0
	dc.b	'<X',0,$10,0,0,'<X'
	dc.b	0,$10,0,0,';',$b8,0,8
	dc.b	0,0,';',$b8,0,8,0,0
	dc.b	';',$18,0,8,0,0,';',$18
	dc.b	0,8,0,0,':x',0,4
	dc.b	0,0,':x',0,4,0,0
	dc.b	'9',$d8,0,4,0,0,'9',$d8
	dc.b	0,0,0,4,'98',0,0
	dc.b	0,2,'98',0,0,0,2
	dc.b	'8',$98,0,0,0,2,'7',$f8
	dc.b	0,0,0,2,'7',$f8,0,0
	dc.b	0,2,'7X',0,0,0,1
	dc.b	'7X',0,0,0,1,'6',$b8
	dc.b	0,0,0,1,'6',$18,0,0
	dc.b	0,1,'5',$80,0,0,$80,0
	dc.b	'5',$80,0,0,$80,0,'4',$e0
	dc.b	0,0,$80,0,'4@',0,0
	dc.b	$80,0,'4@',0,0,$80,0
	dc.b	'3',$a0,0,0,'@',0,'3',0
	dc.b	0,0,'@',0,'2`',0,0
	dc.b	'@',0,'1',$c0,0,0,'@',0
	dc.b	'1 ',0,0,' ',0,'1 '
	dc.b	0,0,' ',0,'0',$80,0,0
	dc.b	' ',0,'/',$e0,0,0,' ',0
	dc.b	'/@',0,0,' ',0,'.',$a0
	dc.b	0,0,$10,0,'.',0,0,0
	dc.b	$10,0,'-`',0,0,$10,0
	dc.b	',',$c0,0,0,$10,0,', '
	dc.b	0,0,$10,0,'+',$80,0,0
	dc.b	8,0,'*@',0,0,8,0
	dc.b	')',$a0,0,0,8,0,')',0
	dc.b	0,0,8,0,'(`',0,0
	dc.b	8,0,$27,' ',0,0,8,0
	dc.b	'&',$80,0,0,4,0,'%@'
	dc.b	0,0,4,0,'$',$a0,0,0
	dc.b	4,0,'#`',0,0,4,0
	dc.b	'"',$c0,0,0,4,0,'!',$80
	dc.b	2,0,2,0,' @',2,0
	dc.b	2,0,$1f,$a0,2,0,2,0
	dc.b	$1e,'`',2,0,2,0,$1d,' '
	dc.b	2,0,2,0,$1b,$e0,2,0
	dc.b	2,0,$1a,$a0,1,0,1,0
	dc.b	$18,$c0,1,0,1,0,$17,$80
	dc.b	1,0,1,0,$15,$a0,1,0
	dc.b	1,0,$14,'`',1,0,1,0
	dc.b	$12,$80,1,0,1,0,$10,$a0
	dc.b	0,$80,0,$80,$e,$c0,0,$80
	dc.b	0,$80,$c,'@',0,$80,0,$80
	dc.b	$a,'`',0,$80,0,$80,7,$e0
	dc.b	0,$80,0,$80,5,'`',0,'@'
	dc.b	0,'@',2,'@',0,'@',0,'@'
	dc.b	$ff,$ff,'7P ',0,0,0
	dc.b	'7P ',0,0,0,'7P'
	dc.b	' ',0,0,0,'7P ',0
	dc.b	0,0,'7P ',0,0,0
	dc.b	'6',$b0,' ',0,0,0,'6',$b0
	dc.b	'@',0,0,0,'6',$b0,'@',0
	dc.b	0,0,'6',$b0,'@',0,0,0
	dc.b	'6',$b0,'@',0,0,0,'6',$10
	dc.b	'@',0,0,0,'6',$10,'@',0
	dc.b	0,0,'6',$10,$80,0,0,0
	dc.b	'6',$10,$80,0,0,0,'6',$10
	dc.b	$80,0,0,0,'5p',$80,0
	dc.b	0,0,'5h',0,1,0,0
	dc.b	'5h',0,1,0,0,'5h'
	dc.b	0,1,0,0,'5h',0,1
	dc.b	0,0,'4',$c8,0,1,0,0
	dc.b	'4',$c8,0,2,0,0,'4',$c8
	dc.b	0,2,0,0,'4',$c8,0,2
	dc.b	0,0,'4',$c8,0,4,0,0
	dc.b	'4(',0,4,0,0,'4('
	dc.b	0,4,0,0,'4(',0,4
	dc.b	0,0,'4(',0,8,0,0
	dc.b	'3',$88,0,8,0,0,'3',$88
	dc.b	0,8,0,0,'3',$88,0,$10
	dc.b	0,0,'3',$88,0,$10,0,0
	dc.b	'2',$e8,0,' ',0,0,'2',$e8
	dc.b	0,' ',0,0,'2',$e8,0,' '
	dc.b	0,0,'2H',0,0,0,'@'
	dc.b	'2H',0,0,0,'@2H'
	dc.b	0,0,0,$80,'2H',0,0
	dc.b	0,$80,'1',$a8,0,0,1,0
	dc.b	'1',$a8,0,0,1,0,'1',$a8
	dc.b	0,0,2,0,'1',8,0,0
	dc.b	2,0,'1',8,0,0,4,0
	dc.b	'0h',0,0,4,0,'0h'
	dc.b	0,0,8,0,'0h',0,0
	dc.b	$10,0,'/',$c8,0,0,$10,0
	dc.b	'/',$c8,0,0,' ',0,'/('
	dc.b	0,0,'@',0,'/(',0,0
	dc.b	$80,0,'.',$80,0,0,0,1
	dc.b	'.',$80,0,0,0,1,'-',$e0
	dc.b	0,0,0,2,'-',$e0,0,0
	dc.b	0,4,'-@',0,0,0,$10
	dc.b	',',$a0,0,0,0,' ,',$a0
	dc.b	0,0,0,'@,',0,0,0
	dc.b	0,$80,'+`',0,0,2,0
	dc.b	'*',$c0,0,0,4,0,'* '
	dc.b	0,0,$10,0,')',$80,0,0
	dc.b	'@',0,'(',$d8,0,0,0,1
	dc.b	'(8',0,0,0,4,$27,$98
	dc.b	0,0,0,$10,'&X',0,0
	dc.b	0,$80,'%',$b8,0,0,4,0
	dc.b	'$x',0,0,' ',0,'#0'
	dc.b	0,0,0,2,'!',$f0,0,0
	dc.b	0,'  ',$10,0,0,4,0
	dc.b	$1e,'(',0,0,0,1,$1b,$a8
	dc.b	0,0,0,$80,$19,'(',0,0
	dc.b	$80,0,$16,0,2,0,2,0
	dc.b	$11,$98,0,'@',0,'@',$b,$f0
	dc.b	0,'@',0,'@',5,8,$10,0
	dc.b	$10,0,$ff,$ff,'C0',0,$10
	dc.b	0,0,'C0',0,$10,0,0
	dc.b	'B',$90,0,8,0,0,'B',$90
	dc.b	0,8,0,0,'B',$90,0,8
	dc.b	0,0,'B',$90,0,4,0,0
	dc.b	'B',$90,0,4,0,0,'B',$90
	dc.b	0,4,0,0,'B',$90,0,4
	dc.b	0,0,'B',$90,0,2,0,0
	dc.b	'B',$90,0,2,0,0,'A',$f0
	dc.b	0,2,0,0,'A',$f0,0,1
	dc.b	0,0,'A',$f0,0,1,0,0
	dc.b	'A',$f0,0,1,0,0,'A',$f8
	dc.b	$80,0,0,0,'A',$f8,$80,0
	dc.b	0,0,'AX',$80,0,0,0
	dc.b	'AX@',0,0,0,'AX'
	dc.b	'@',0,0,0,'AX ',0
	dc.b	0,0,'AX ',0,0,0
	dc.b	'@',$b8,' ',0,0,0,'@',$b8
	dc.b	$10,0,0,0,'@',$b8,$10,0
	dc.b	0,0,'@',$b8,8,0,0,0
	dc.b	'@',$18,8,0,0,0,'@',$18
	dc.b	4,0,0,0,'@',$18,4,0
	dc.b	0,0,'@',$18,2,0,0,0
	dc.b	'?x',2,0,0,0,'?x'
	dc.b	1,0,0,0,'?x',1,0
	dc.b	0,0,'>',$d8,0,$80,0,0
	dc.b	'>',$d8,0,$80,0,0,'>',$d8
	dc.b	0,'@',0,0,'>8',0,0
	dc.b	0,' >8',0,0,0,' '
	dc.b	'=',$98,0,0,0,$10,'=',$98
	dc.b	0,0,0,8,'<',$f8,0,0
	dc.b	0,4,'<',$f8,0,0,0,4
	dc.b	'<X',0,0,0,2,'<X'
	dc.b	0,0,0,1,';',$c0,0,0
	dc.b	$80,0,'; ',0,0,'@',0
	dc.b	'; ',0,0,' ',0,':',$80
	dc.b	0,0,$10,0,'9',$e0,0,0
	dc.b	4,0,'9@',0,0,2,0
	dc.b	'8',$a0,0,0,1,0,'8',0
	dc.b	0,0,0,'@7`',0,0
	dc.b	0,' 6',$c0,0,0,0,8
	dc.b	'5',$80,0,0,0,2,'4',$e8
	dc.b	0,0,$80,0,'3',$a8,0,0
	dc.b	' ',0,'2h',0,0,4,0
	dc.b	'1(',0,0,0,$80,'/',$e8
	dc.b	0,0,0,$10,'.',$a8,0,0
	dc.b	0,2,',',$d0,0,0,' ',0
	dc.b	'*',$f0,0,0,1,0,'(p'
	dc.b	0,0,0,8,'%X',0,0
	dc.b	' ',0,'"8',0,0,0,' '
	dc.b	$1d,$e0,0,0,$10,0,$18,$e0
	dc.b	0,0,0,2,$12,$a8,0,0
	dc.b	0,8,9,$f0,0,0,0,1
	dc.b	$ff,$ff,'F8',0,$10,0,0
	dc.b	'F',$d8,0,$10,0,0,'Gx'
	dc.b	0,$10,0,0,'H',$18,0,$10
	dc.b	0,0,'H',$18,0,' ',0,0
	dc.b	'H',$b8,0,' ',0,0,'IX'
	dc.b	0,' ',0,0,'I',$f8,0,' '
	dc.b	0,0,'J',$98,0,' ',0,0
	dc.b	'K8',0,'@',0,0,'K8'
	dc.b	0,'@',0,0,'K',$d8,0,'@'
	dc.b	0,0,'Lx',0,'@',0,0
	dc.b	'M',$18,0,$80,0,0,'M',$b8
	dc.b	0,$80,0,0,'NX',0,$80
	dc.b	0,0
	jmp	$80.w
	dc.b	0,0,'O',$98,0,$80,0,0
	dc.b	'P8',1,0,0,0,'Qx'
	dc.b	1,0,0,0,'R',$18,1,0
	dc.b	0,0,'R',$b8,1,0,0,0
	dc.b	'SX',1,0,0,0,'S',$f8
	dc.b	1,0,0,0,'U8',2,0
	dc.b	0,0,'U',$d8,2,0,0,0
	dc.b	'Vx',2,0,0,0,'W',$b8
	dc.b	2,0,0,0,'XX',2,0
	dc.b	0,0,'Y',$98,2,0,0,0
	dc.b	'Z8',4,0,0,0,'[x'
	dc.b	4,0,0,0,'\',$18,4,0
	dc.b	0,0,']X',4,0,0,0
	dc.b	'^',$98,4,0,0,0,'_',$d8
	dc.b	4,0,0,0,'`x',0,0
	dc.b	4,0,'a',$b8,0,0,8,0
	dc.b	'b',$f8,0,0,8,0,'d',$d8
	dc.b	0,0,8,0,'f',$18,0,0
	dc.b	8,0,'gX',0,0,8,0
	dc.b	'i8',0,0,8,0,'jx'
	dc.b	0,0,8,0,'lX',0,0
	dc.b	8,0,'n8',0,0,8,0
	dc.b	'ox',0,0,8,0,'q',$f8
	dc.b	0,0,8,0,'s',$d8,0,0
	dc.b	8,0,'u',$b8,0,0,8,0
	dc.b	'x8',0,0,8,0,'z',$b8
	dc.b	0,0,8,0,$ff,$ff,'Xp'
	dc.b	$10,0,0,0,'Xp',8,0
	dc.b	0,0,'Y',$10,4,0,0,0
	dc.b	'Y',$b0,2,0,0,0,'Y',$b0
	dc.b	1,0,0,0,'ZP',1,0
	dc.b	0,0,'Z',$f0,0,$80,0,0
	dc.b	'[',$90,0,'@',0,0,'[',$90
	dc.b	0,' ',0,0,'\0',0,$10
	dc.b	0,0,'\',$d0,0,8,0,0
	dc.b	']p',0,4,0,0,'^',$10
	dc.b	0,2,0,0,'^',$b0,0,1
	dc.b	0,0,'_X@',0,0,0
	dc.b	'_X ',0,0,0,'_',$f8
	dc.b	$10,0,0,0,'a8',8,0
	dc.b	0,0,'a',$d8,2,0,0,0
	dc.b	'bx',1,0,0,0,'c',$18
	dc.b	0,'@',0,0,'c',$b8,0,$10
	dc.b	0,0,'dX',0,8,0,0
	dc.b	'e',$98,0,2,0,0,'f@'
	dc.b	$80,0,0,0,'g',$80,' ',0
	dc.b	0,0,'h ',8,0,0,0
	dc.b	'i`',1,0,0,0,'j',0
	dc.b	0,'@',0,0,'k@',0,8
	dc.b	0,0,'l',$80,0,1,0,0
	dc.b	'm',$c8,' ',0,0,0,'o',$a8
	dc.b	4,0,0,0,'p',$e8,0,$80
	dc.b	0,0,'r',$c8,0,8,0,0
	dc.b	't',$10,$80,0,0,0,'u',$f0
	dc.b	0,0,4,0,'xp',0,0
	dc.b	0,' zP',0,0,0,1
	dc.b	$ff,$ff,'<p',0,4,0,0
	dc.b	';',$d0,0,2,0,0,':',$98
	dc.b	$80,0,0,0,'9',$f8,' ',0
	dc.b	0,0,'9X',$10,0,0,0
	dc.b	'8',$18,4,0,0,0,'6',$d8
	dc.b	1,0,0,0,'68',0,$80
	dc.b	0,0,'4',$f8,0,' ',0,0
	dc.b	'3',$b8,0,8,0,0,'2x'
	dc.b	0,2,0,0,'1@',$80,0
	dc.b	0,0,'0',0,' ',0,0,0
	dc.b	'.',$c0,8,0,0,0,'-',$80
	dc.b	1,0,0,0,'+',$a0,0,'@'
	dc.b	0,0,'*`',0,8,0,0
	dc.b	'(',$80,0,2,0,0,'&',$a8
	dc.b	'@',0,0,0,'$',$c8,8,0
	dc.b	0,0,'"',$e8,1,0,0,0
	dc.b	' h',0,' ',0,0,$1e,$88
	dc.b	0,2,0,0,$1c,$10,'@',0
	dc.b	0,0,$19,$90,4,0,0,0
	dc.b	$16,'p',0,'@',0,0,$13,$f0
	dc.b	0,2,0,0,$10,'8 ',0
	dc.b	0,0,$d,$18,0,$80,0,0
	dc.b	9,'X',0,4,0,0,$ff,$ff
	dc.b	';',$a8,2,0,0,0,';',$a8
	dc.b	2,0,0,0,';',$a8,2,0
	dc.b	0,0,';',$a8,2,0,0,0
	dc.b	';',$a8,4,0,0,0,';',$a8
	dc.b	4,0,0,0,';',$a8,4,0
	dc.b	0,0,'<H',4,0,0,0
	dc.b	'<H',4,0,0,0,'<H'
	dc.b	4,0,0,0,'<H',8,0
	dc.b	0,0,'<H',8,0,0,0
	dc.b	'<H',8,0,0,0,'<H'
	dc.b	8,0,0,0,'<',$e8,8,0
	dc.b	0,0,'<',$e8,$10,0,0,0
	dc.b	'<',$e8,$10,0,0,0,'<',$e8
	dc.b	$10,0,0,0,'<',$e8,$10,0
	dc.b	0,0,'<',$e8,$10,0,0,0
	dc.b	'=',$88,' ',0,0,0,'=',$88
	dc.b	' ',0,0,0,'=',$88,' ',0
	dc.b	0,0,'=',$88,' ',0,0,0
	dc.b	'=',$88,' ',0,0,0,'>('
	dc.b	'@',0,0,0,'>(@',0
	dc.b	0,0,'>(@',0,0,0
	dc.b	'>(@',0,0,0,'>('
	dc.b	'@',0,0,0,'>',$c8,$80,0
	dc.b	0,0,'>',$c8,$80,0,0,0
	dc.b	'>',$c8,$80,0,0,0,'>',$c8
	dc.b	$80,0,0,0,'?`',0,1
	dc.b	0,0,'?`',0,1,0,0
	dc.b	'?`',0,0,0,1,'?`'
	dc.b	0,0,0,1,'@',0,0,0
	dc.b	0,2,'@',0,0,0,0,2
	dc.b	'@',0,0,0,0,2,'@',$a0
	dc.b	0,0,0,2,'@',$a0,0,0
	dc.b	0,4,'@',$a0,0,0,0,4
	dc.b	'A@',0,0,0,4,'A@'
	dc.b	0,0,0,8,'A',$e0,0,0
	dc.b	0,8,'A',$e0,0,0,0,8
	dc.b	'A',$e0,0,0,0,8,'B',$80
	dc.b	0,0,0,$10,'B',$80,0,0
	dc.b	0,$10,'C ',0,0,0,$10
	dc.b	'C ',0,0,0,' C',$c0
	dc.b	0,0,0,' C',$c0,0,0
	dc.b	0,'@D`',0,0,0,'@'
	dc.b	'E',0,0,0,0,'@E',0
	dc.b	0,0,0,$80,'E',$a0,0,0
	dc.b	0,$80,'F@',0,0,1,0
	dc.b	'F@',0,0,1,0,'F',$e0
	dc.b	0,0,2,0,'G',$80,0,0
	dc.b	2,0,'H ',0,0,4,0
	dc.b	'H',$c0,0,0,4,0,'I`'
	dc.b	0,0,8,0,'J',0,0,0
	dc.b	$10,0,'J',$a0,0,0,$10,0
	dc.b	'K@',0,0,' ',0,'K',$e0
	dc.b	0,0,'@',0,'L',$80,0,0
	dc.b	$80,0,'M',$c0,0,0,$80,0
	dc.b	'NX',0,0,0,1,'O',$98
	dc.b	0,0,0,2,'P',$d8,0,0
	dc.b	0,4,'R',$18,0,0,0,$10
	dc.b	'SX',0,' ',0,' T',$98
	dc.b	0,'@',0,'@Vx',1,0
	dc.b	1,0,'XX',4,0,4,0
	dc.b	'Z8',$10,0,$10,0,'\',$b8
	dc.b	'@',0,'@',0,'_0',0,1
	dc.b	0,1,'bP',0,8,0,8
	dc.b	'f',$10,0,'@',0,'@jp'
	dc.b	4,0,4,0,'op',$80,0
	dc.b	$80,0,'u',8,0,' ',0,' '
	dc.b	$ff,$ff,0,0
	
L_dist_font:	dc.b	0,0,0,0		; @ = DIST_FONT_SRC		$1C16A
	dcb.w	14
	dc.b	0,1,0,1,0,0,0,0
	dc.b	0,3,0,2,0,1,0,0
	dc.b	0,5,0,6,0,3,0,0
	dc.b	0,8,0,$f,0,7,0,0
	dc.b	0,$1f,0,$1f,0,$f,0,0
	dc.b	0,'?',0,'>',0,$1e,0,0
	dc.b	0,$7f,0,'|',0,'<',0,0
	dc.b	0,$bf,0,$f8,0,'x',0,0
	dc.b	1,'?',1,$f0,0,$f0,0,0
	dc.b	3,'?',2,$e0,1,$e0,0,0
	dc.b	7,'?',4,$c0,3,$c0,0,0
	dc.b	$b,$ff,$c,0,7,$80,0,0
	dc.b	$13,$ff,$1c,0,$f,0,0,0
	dc.b	'#',$ff,'<',0,$1e,0,0,0
	dc.b	's',$fc,'L',$c,'<',3,0,0
	dc.b	$9f,$e7,$e0,$1f,'x',0,0,0
	dc.b	$8f,$c1,'p?',$f0,0,0,0
	dc.b	$7f,$80,0,'x',$e0,0,0,0
	dc.b	$8c,0,$bc,$f0,'C',0,0,0
	dc.b	6,0,'~`',$81,$80,0,0
	dc.b	3,0,$ff,0,0,$c0,0,0
	dc.b	0,$d0,$17,$18,$f,$e0,0,0
	dc.b	'6',$88,'/',$c,$1f,$f0,0,0
	dc.b	'N',$bc,$7f,4,'?',$f8,0,0
	dc.b	$87,$fc,$fc,$c,'|0',0,0
	dc.b	$ef,$f8,$10,$1e,$f0,0,0,0
	dc.b	$ff,$f0,0,$e,$e0,0,0,0
	dc.b	$ff,$f2,0,$e,$c0,0,0,0
	dc.b	$7f,$f6,$80,$e,$80,0,0,0
	dc.b	$ff,$fe,0,$e,0,0,0,0
	dc.b	$f9,$fa,6,$a,0,4,0,0
	dc.b	$ff,$f0,$c,0,2,$e,0,0
	dc.b	$eb,$f4,$18,0,6,$e,0,0
	dc.b	$c1,$f4,'>',0,6,$e,0,0
	dc.b	$95,$f0,'z',0,$e,$e,0,0
	dc.b	$f,$fa,$d0,$a,'>',4,0,0
	dc.b	$ff,$fe,0,$e,0,0,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	3,$f2,2,$e,$fc,0,0,0
	dc.b	$f,$f0,$c,$e,$f2,0,0,0
	dc.b	$bd,$f0,$ba,$e,'F',0,0,0
	dc.b	$b,$f0,6,$e,$e,0,0,0
	dc.b	7,$e0,$b,$ee,$c,$10,0,0
	dc.b	$c,'p',7,$f6,8,8,0,0
	dc.b	8,'0',$f,$f2,0,$c,0,0
	dc.b	'r',$13,$fc,$f,$ff,$ff,0,0
	dc.b	';3|',$f,$ff,$ff,0,0
	dc.b	$1d,$f4,'>',$f,$ff,$ff,0,0
	dc.b	$9f,$ff,$80,0,'`',0,0,0
	dc.b	$df,$ff,$c0,0,' ',0,0,0
	dc.b	$ff,$ff,$e0,0,0,0,0,0
	dc.b	$9f,$ff,$80,0,'`',0,0,0
	dc.b	$1f,$ff,0,0,$e0,0,0,0
	dc.b	$e0,0,$ff,$ff,0,0,0,0
	dc.b	$e7,$8d,'`~',$9f,$ff,0,0
	dc.b	$df,$ff,0,0,$e0,0,0,0
	dc.b	$ff,$ff,0,0,$e0,0,0,0
	dc.b	$bf,$ff,'@',0,$e0,0,0,0
	dc.b	$1f,$ff,$e0,0,$e0,0,0,0
	dc.b	'_',$ff,$e0,0,$e0,0,0,0
	dc.b	$ff,$1c,$e0,$ff,$e0,0,0,0
	dc.b	$ff,$cf,$e0,'?',$e0,$ff,0,0
	dc.b	'_',$ff,$e0,0,$e0,0,0,0
	dc.b	$1f,$ff,$e0,0,$e0,0,0,0
	dc.b	$1f,$ff,$e0,0,$e0,0,0,0
	dc.b	$bf,$ff,'@',0,$e0,0,0,0
	dc.b	$ff,$ff,0,0,$e0,0,0,0
	dc.b	$de,$1f,'?',$ff,$c0,0,0,0
	dc.b	$b3,$f,'s',$ff,$8c,0,0,0
	dc.b	'a',$86,$e1,$fe,$1e,1,0,0
	dc.b	$9c,$c0,$e0,$18,$ff,$e0,0,0
	dc.b	's',$98,$80,'l',$ff,$f0,0,0
	dc.b	'w4',$80,$c4,$ff,$f8,0,0
	dc.b	$ff,$ec,0,$e,0,'0',0,0
	dc.b	$ff,$fe,0,$1e,0,0,0,0
	dc.b	$ff,$f8,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	3,$f0,$fe,$e,0,0,0,0
	dc.b	'k',$f0,$1c,$e,$fe,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$e0,0,$1e,0,0,0,0
	dc.b	$ff,$cc,0,'<',0,0,0,0
	dc.b	$ff,$e6,0,6,0,$18,0,0
	dc.b	$ff,$fc,0,$e,0,0,0,0
	dc.b	1,$f0,$fe,$e,0,0,0,0
	dc.b	'9',$f0,$c6,$e,$fe,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f8,0,$e,0,0,0,0
	dc.b	$ff,$fe,0,$1e,0,0,0,0
	dc.b	$ff,$e4,0,'&',0,$18,0,0
	dc.b	$e0,'4',$ff,$f4,0,8,0,0
	dc.b	'<',$18,'?',$fc,$c0,0,0,0
	dc.b	7,$80,7,$f0,$f8,0,0,0
	dc.b	7,$19,$c,7,3,$ff,0,0
	dc.b	$17,$93,'<',$f,$f,$ff,0,0
	dc.b	'-',$b9,'~',7,$1f,$ff,0,0
	dc.b	'M',$ff,'~',0,'>',0,0,0
	dc.b	$27,$ff,$f8,0,'x',0,0,0
	dc.b	$bf,$ff,$f0,0,'p',0,0,0
	dc.b	$cf,$ff,'0',0,$f0,0,0,0
	dc.b	$7f,$ff,0,0,$e0,0,0,0
	dc.b	$7f,$83,0,$7f,$e0,0,0,0
	dc.b	'?',$c,0,$fc,$e0,3,0,0
	dc.b	'?',3,0,$ff,$e0,0,0,0
	dc.b	$9f,0,0,$e0,$e0,0,0,0
	dc.b	'_',0,$80,$e0,$e0,0,0,0
	dc.b	'?`',$c0,$f0,$e0,0,0,0
	dc.b	$df,$c8,$e0,$c7,$e0,'?',0,0
	dc.b	$ff,$98,$e0,$87,$e0,$7f,0,0
	dc.b	$df,$bc,$e0,3,$e0,$7f,0,0
	dc.b	$1f,$ff,$e0,0,$e0,0,0,0
	dc.b	$bf,$ff,'@',0,$f0,0,0,0
	dc.b	$ef,$ff,$80,0,'p',0,0,0
	dc.b	'O',$ff,$80,0,'x',0,0,0
	dc.b	'S',$ff,'L',0,'>',0,0,0
	dc.b	'$',$8f,'x',$ff,$1f,0,0,0
	dc.b	$19,'01',$f0,$e,$f,0,0
	dc.b	2,$e0,7,$e0,0,$1f,0,0
	dc.b	$c6,$9e,$f8,'~',$ff,$fc,0,0
	dc.b	$cc,$bc,$f0,'~',$ff,$f8,0,0
	dc.b	$99,'x',$e0,$fe,$ff,$f0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$fe,0,$e,0,0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$cf,0,$ff,$e,0,$f0,0,0
	dc.b	'a',$c0,$7f,$c6,$80,'8',0,0
	dc.b	$80,$e0,$ff,$e2,0,$1c,0,0
	dcb.w	12
	dc.b	'a',$c8,$fe,'<',$ff,$fe,0,0
	dc.b	$f3,$90,$fc,'z',$ff,$fc,0,0
	dc.b	'r ',$fd,$f6,$ff,$f8,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$fc,0,$c,0,2,0,0
	dc.b	$ff,$f0,0,0,0,$e,0,0
	dc.b	0,8,$ff,$f8,0,6,0,0
	dc.b	$e0,4,$ff,$fc,0,2,0,0
	dc.b	'8',2,'?',$fe,$c0,0,0,0
	dc.b	$f7,'>',$f,$c1,$ff,$ff,0,0
	dc.b	$f3,'<',$8f,$c3,$7f,$ff,0,0
	dc.b	$fa,'<',$c7,$c3,'?',$ff,0,0
	dc.b	$7f,$ff,'`',0,$80,0,0,0
	dc.b	'?',$ff,' ',0,$c0,0,0,0
	dc.b	'?',$ff,' ',0,$c0,0,0,0
	dc.b	$9f,$ff,0,0,$e0,0,0,0
	dc.b	$df,$ff,0,0,$e0,0,0,0
	dc.b	$df,0,0,$ff,$e0,0,0,0
	dc.b	$df,$80,0,$ff,$e0,0,0,0
	dc.b	'?',$c3,$c0,$ff,$e0,0,0,0
	dc.b	'_',$e0,$e0,$e0,$e0,0,0,0
	dc.b	'_',$80,$e0,$e0,$e0,0,0,0
	dc.b	$ff,0,$e0,$e0,$e0,0,0,0
	dc.b	$ff,'2',$e0,$ef,$e0,$1f,0,0
	dc.b	$df,'w',$e0,$cf,$e0,'?',0,0
	dc.b	'_',$cf,$e0,$bf,$e0,$7f,0,0
	dc.b	'?',$ff,$c0,0,$e0,0,0,0
	dc.b	$ff,$ff,0,0,$e0,0,0,0
	dc.b	$df,$ff,' ',0,$e0,0,0,0
	dc.b	$bf,$ff,'`',0,$e0,0,0,0
	dc.b	'_',$ff,$e0,0,$e0,0,0,0
	dc.b	$86,1,$df,$ff,$e0,0,0,0
	dc.b	$f,$83,$bf,$ff,$c0,0,0,0
	dc.b	$11,$f6,'q',$fe,$8e,1,0,0
	dc.b	'y@',$fe,'`',$ff,$80,0,0
	dc.b	'q',$b0,$fe,'X',$ff,$e0,0,0
	dc.b	'c',$e8,$fc,'x',$ff,$f0,0,0
	dc.b	$ff,'X',0,$e4,0,$f8,0,0
	dc.b	$ff,$f4,0,4,0,'8',0,0
	dc.b	$ff,$ec,0,$c,0,$10,0,0
	dc.b	$ff,$f8,0,$1e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$f,$f2,$fc,$e,0,0,0,0
	dc.b	$f9,$f6,$fa,$e,6,0,0,0
	dc.b	$13,$f8,$16,8,$ee,6,0,0
	dc.b	7,$f8,$e,8,$e,6,0,0
	dc.b	7,$f8,$e,8,$e,6,0,0
	dc.b	$b,$f8,6,8,$e,6,0,0
	dc.b	'm',$fa,$82,$a,$fe,4,0,0
	dc.b	'e',$f6,$82,$e,$fe,0,0,0
	dc.b	$13,$f4,$e0,$e,$fc,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$e0,0,$1e,0,0,0,0
	dc.b	$ff,$f0,0,$1c,0,0,0,0
	dc.b	$ff,$d8,0,$1c,0,' ',0,0
	dc.b	$ff,$c8,0,$cc,0,'0',0,0
	dc.b	$e0,$e0,$ff,$e8,0,$10,0,0
	dc.b	'8',$e0,'?',$f0,$c0,0,0,0
	dc.b	$c,0,$f,$c0,$f0,0,0,0
	dc.b	7,$ef,$c,$1f,3,$ff,0,0
	dc.b	$17,$f7,'<',$f,$f,$ff,0,0
	dc.b	'-',$f9,'~',7,$1f,$ff,0,0
	dc.b	'M',$ff,'~',0,'>',0,0,0
	dc.b	$27,$ff,$f8,0,'x',0,0,0
	dc.b	$bf,$ff,$f0,0,'p',0,0,0
	dc.b	$cf,$ff,'0',0,$f0,0,0,0
	dc.b	$7f,$ff,0,0,$e0,0,0,0
	dc.b	$7f,$80,0,$7f,$e0,0,0,0
	dc.b	'?<',0,$7f,$e0,$ff,0,0
	dc.b	'?',$ff,0,0,$e0,0,0,0
	dc.b	$9f,$ff,0,0,$e0,0,0,0
	dc.b	'_',$ff,$80,0,$e0,0,0,0
	dc.b	'?',$ff,$c0,0,$e0,0,0,0
	dc.b	$df,$ff,$e0,0,$e0,0,0,0
	dc.b	$ff,0,$e0,$ff,$e0,0,0,0
	dc.b	$df,$a7,$e0,$1f,$e0,$7f,0,0
	dc.b	$1f,$ff,$e0,0,$e0,0,0,0
	dc.b	$bf,$ff,'@',0,$f0,0,0,0
	dc.b	$ef,$ff,$80,0,'p',0,0,0
	dc.b	'O',$ff,$80,0,'x',0,0,0
	dc.b	'S',$ff,'L',0,'>',0,0,0
	dc.b	'$#x',$ff,$1f,0,0,0
	dc.b	$19,'f1',$fe,$e,1,0,0
	dc.b	2,$ec,7,$fc,0,3,0,0
	dc.b	'fr',$81,$fe,$ff,$fc,0,0
	dc.b	'&',$e4,$c1,$fe,$ff,$f8,0,0
	dc.b	$ad,$c8,$c3,$fe,$ff,$f0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$f8,0,8,0,6,0,0
	dc.b	$ff,$f0,0,0,0,$e,0,0
	dc.b	$ff,$fe,0,$e,0,0,0,0
	dc.b	0,0,$ff,$fe,0,0,0,0
	dc.b	$af,' ',$1f,$ce,$ff,$f0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$fe,0,$e,0,0,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	0,0,$ff,$fe,0,0,0,0
	dc.b	'8',$e6,$c7,$e,$ff,$f0,0,0
	dc.b	$ff,$fe,0,$e,0,0,0,0
	dc.b	$ff,$fc,0,$e,0,0,0,0
	dc.b	$ff,$f8,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	'F0~>',$81,$c0,0,0
	dc.b	'g',$18,$7f,$1e,$80,$e0,0,0
	dc.b	'g',$8c,$7f,$8e,$80,'p',0,0
	dc.b	7,$19,$c,7,3,$ff,0,0
	dc.b	$17,$93,'<',$f,$f,$ff,0,0
	dc.b	'-',$b9,'~',7,$1f,$ff,0,0
	dc.b	'M',$ff,'~',0,'>',0,0,0
	dc.b	$27,$ff,$f8,0,'x',0,0,0
	dc.b	$bf,$ff,$f0,0,'p',0,0,0
	dc.b	$cf,$ff,'0',0,$f0,0,0,0
	dc.b	$7f,$ff,0,0,$e0,0,0,0
	dc.b	$1f,$83,0,$7f,$e0,0,0,0
	dc.b	$9f,$b3,0,$cf,$e0,$7f,0,0
	dc.b	$9f,$ff,0,0,$e0,0,0,0
	dc.b	$df,$ff,0,0,$e0,0,0,0
	dc.b	'_',$ff,$80,0,$e0,0,0,0
	dc.b	'?',$ff,$c0,0,$e0,0,0,0
	dc.b	$9f,$ff,$e0,0,$e0,0,0,0
	dc.b	$ff,$80,$e0,$ff,$e0,0,0,0
	dc.b	$ff,'A',$e0,$7f,$e0,$80,0,0
	dc.b	$9f,'#',$e0,'?',$e0,$c0,0,0
	dc.b	'?',$80,$c0,$80,$e0,'`',0,0
	dc.b	'_',$c0,$80,$c0,$e0,' ',0,0
	dc.b	$df,'`',0,$e0,$e0,0,0,0
	dc.b	$9f,' ',0,$e0,$e0,0,0,0
	dc.b	$a1,0,'?',$e0,$c0,0,0,0
	dc.b	'C',$80,$7f,$e0,$80,0,0,0
	dc.b	$87,$c0,$ff,$e0,0,0,0,0
	dc.b	$c6,$9e,$f8,'~',$ff,$fc,0,0
	dc.b	$cc,$bc,$f0,'~',$ff,$f8,0,0
	dc.b	$99,'x',$e0,$fe,$ff,$f0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$fe,0,$e,0,0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$e0,$c,$ff,$fe,0,0,0,0
	dc.b	$f3,$88,$fc,'~',$ff,$f0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f8,0,$e,0,0,0,0
	dc.b	$ff,$fc,0,$e,0,0,0,0
	dc.b	$ff,$f4,0,6,0,8,0,0
	dc.b	$ff,$f6,0,6,0,8,0,0
	dc.b	'x',2,$ff,$f2,0,$c,0,0
	dc.b	$cc,0,$cf,$f8,'0',6,0,0
	dc.b	6,0,7,$fc,$f8,2,0,0
	dcb.w	28
	dc.b	7,$ef,$c,$1f,3,$ff,0,0
	dc.b	$17,$f7,'<',$f,$f,$ff,0,0
	dc.b	'-',$f9,'~',7,$1f,$ff,0,0
	dc.b	'M',$ff,'~',0,'>',0,0,0
	dc.b	$27,$ff,$f8,0,'x',0,0,0
	dc.b	$bf,$ff,$f0,0,'p',0,0,0
	dc.b	$cf,$ff,'0',0,$f0,0,0,0
	dc.b	$7f,$ff,0,0,$e0,0,0,0
	dc.b	$7f,$c0,0,$7f,$e0,0,0,0
	dc.b	'?',$de,0,$df,$e0,'?',0,0
	dc.b	'?',$ef,0,$c0,$e0,'0',0,0
	dc.b	$9f,$7f,0,$c0,$e0,'0',0,0
	dc.b	'__',$80,$e0,$e0,'0',0,0
	dc.b	'?/',$c0,$f0,$e0,'0',0,0
	dc.b	$df,'?',$e0,$f0,$e0,'0',0,0
	dc.b	$ff,' ',$e0,$ef,$e0,'0',0,0
	dc.b	$df,$87,$e0,$7f,$e0,$7f,0,0
	dc.b	$1f,$ff,$e0,0,$e0,0,0,0
	dc.b	$bf,$ff,'@',0,$f0,0,0,0
	dc.b	$ef,$ff,$80,0,'p',0,0,0
	dc.b	'O',$ff,$80,0,'x',0,0,0
	dc.b	'S',$ff,'L',0,'>',0,0,0
	dc.b	'$',$d,'x',$fd,$1f,2,0,0
	dc.b	$19,'81',$f8,$e,7,0,0
	dc.b	2,'p',7,$f0,0,$f,0,0
	dc.b	'fr',$81,$fe,$ff,$fc,0,0
	dc.b	'&',$e4,$c1,$fe,$ff,$f8,0,0
	dc.b	$ad,$c8,$c3,$fe,$ff,$f0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$f8,0,8,0,6,0,0
	dc.b	$ff,$f0,0,0,0,$e,0,0
	dc.b	$ff,$fe,0,$e,0,0,0,0
	dc.b	'?',0,$ff,$fe,0,0,0,0
	dc.b	'9',$ca,$c7,$ee,$ff,$f0,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$fc,0,$c,0,2,0,0
	dc.b	$ff,$f8,0,8,0,6,0,0
	dc.b	$ff,$f0,0,0,0,$e,0,0
	dc.b	$ff,$f8,0,8,0,6,0,0
	dc.b	$f9,$fc,$fe,$c,0,2,0,0
	dc.b	$b3,$fc,$cc,$c,$fe,2,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$8f,0,$ff,$e,0,$f0,0,0
	dc.b	$c3,$c0,$ff,$c6,0,'8',0,0
	dc.b	'a',$e0,$7f,$e2,$80,$1c,0,0
	dc.b	$f7,$a0,$f,$e0,$ff,$c0,0,0
	dc.b	$f3,'@',$8f,$e0,$7f,$80,0,0
	dc.b	$fa,$a0,$c7,$e0,'?',0,0,0
	dc.b	$7f,'@`',$c0,$80,' ',0,0
	dc.b	'?',$80,' ',$80,$c0,'`',0,0
	dc.b	'?',$c0,' ',$c0,$c0,' ',0,0
	dc.b	$9f,'`',0,$e0,$e0,0,0,0
	dc.b	$df,'3',0,$ef,$e0,$1f,0,0
	dc.b	$df,'o',0,$df,$e0,'?',0,0
	dc.b	$df,$e7,0,$9f,$e0,$7f,0,0
	dc.b	'?',$ff,$c0,0,$e0,0,0,0
	dc.b	'_',$ff,$e0,0,$e0,0,0,0
	dc.b	'_',$ff,$e0,0,$e0,0,0,0
	dc.b	$ff,$ff,$e0,0,$e0,0,0,0
	dc.b	$ff,$ff,$e0,0,$e0,0,0,0
	dc.b	$df,$1c,$e0,$fc,$e0,3,0,0
	dc.b	'_',7,$e0,$ff,$e0,0,0,0
	dc.b	'?',$81,$c0,$ff,$e0,0,0,0
	dc.b	$ff,$c0,0,$e0,$e0,0,0,0
	dc.b	$df,'` `',$e0,$80,0,0
	dc.b	$bf,' ` ',$e0,$c0,0,0
	dc.b	'_ ',$e0,' ',$e0,$c0,0,0
	dc.b	$86,0,$df,$80,$e0,'`',0,0
	dc.b	$f,0,$bf,$c0,$c0,' ',0,0
	dc.b	$11,$80,'q',$e0,$8e,0,0,0
	dc.b	6,$f2,$f,2,$f,$fc,0,0
	dc.b	$b,'d',7,$86,$f,$f8,0,0
	dc.b	$d,'H',3,$8e,$f,$f0,0,0
	dc.b	7,$f0,8,$e,$e,0,0,0
	dc.b	3,$f0,$c,$e,$e,0,0,0
	dc.b	9,$f0,$e,$e,$e,0,0,0
	dc.b	$f,$f2,$e,$e,$e,0,0,0
	dc.b	'g',$f6,$86,$e,$fe,0,0,0
	dc.b	'c',$fe,$82,$e,$fe,0,0,0
	dc.b	$b9,$fa,$c0,$a,$fe,4,0,0
	dc.b	$ff,$f0,0,0,0,$e,0,0
	dc.b	$ff,$f4,0,0,0,$e,0,0
	dc.b	$ff,$f4,0,0,0,$e,0,0
	dc.b	$ff,$f0,0,0,0,$e,0,0
	dc.b	$ff,$fa,0,$a,0,4,0,0
	dc.b	3,$fe,2,$e,$fc,0,0,0
	dc.b	$f,$f6,$c,$e,$f2,0,0,0
	dc.b	$bd,$f2,$ba,$e,'F',0,0,0
	dc.b	$b,$f2,6,$e,$e,0,0,0
	dc.b	$f,$f0,$e,$e,$e,0,0,0
	dc.b	$d,$f0,$e,$e,$e,0,0,0
	dc.b	$b,$f0,$c,$e,$e,0,0,0
	dc.b	7,$e0,$b,$ee,$c,$10,0,0
	dc.b	$c,'p',7,$f6,8,8,0,0
	dc.b	8,'0',$f,$f2,0,$c,0,0
	dc.b	0,$14,0,'8',0,'?',0,0
	dc.b	0,$a,0,$1c,0,'?',0,0
	dc.b	0,2,0,$c,0,'?',0,0
	dc.b	0,$27,0,' ',0,$18,0,0
	dc.b	0,'7',0,'0',0,8,0,0
	dc.b	0,'?',0,'8',0,0,0,0
	dc.b	0,$f,0,8,0,'0',0,0
	dc.b	0,7,0,0,0,'8',0,0
	dc.b	0,$17,0,0,0,'8',0,0
	dc.b	0,'?',0,0,0,'8',0,0
	dc.b	0,'?',0,0,0,'8',0,0
	dc.b	0,'/',0,$10,0,'8',0,0
	dc.b	0,7,0,'8',0,'8',0,0
	dc.b	0,$17,0,'8',0,'8',0,0
	dc.b	0,'?',0,'8',0,'8',0,0
	dc.b	0,'?',0,'8',0,'8',0,0
	dc.b	0,$17,0,'8',0,'8',0,0
	dc.b	0,7,0,'8',0,'8',0,0
	dc.b	0,7,0,'8',0,'8',0,0
	dc.b	0,'/',0,$10,0,'8',0,0
	dc.b	0,'?',0,0,0,'8',0,0
	dc.b	0,'?',0,0,0,'8',0,0
	dc.b	0,'7',0,$f,0,'0',0,0
	dc.b	0,',',0,$1c,0,'#',0,0
	dc.b	0,$18,0,'8',0,7,0,0
	dc.b	'H',0,'8',0,$f0,0,0,0
	dc.b	$d0,0,'8',0,$e0,0,0,0
	dc.b	$a0,0,'x',0,$c0,0,0,0
	dc.b	$c0,0,'8',0,0,0,0,0
	dc.b	$c0,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$d8,0,'8',0,0,0,0,0
	dc.b	$f0,0,'0',0,8,0,0,0
	dc.b	$e0,0,' ',0,$18,0,0,0
	dc.b	$e0,0,' ',0,$18,0,0,0
	dc.b	$e0,0,' ',0,$18,0,0,0
	dc.b	$e0,0,' ',0,$18,0,0,0
	dc.b	$e0,0,' ',0,$18,0,0,0
	dc.b	$f0,0,'0',0,8,0,0,0
	dc.b	$f0,0,'0',0,8,0,0,0
	dc.b	$d8,0,'8',0,0,0,0,0
	dc.b	$d8,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$c0,0,'8',0,0,0,0,0
	dc.b	$c0,0,'8',0,0,0,0,0
	dc.b	$80,0,$f8,0,0,0,0,0
	dc.b	$c0,0,$f8,0,0,0,0,0
	dc.b	'`',0,'x',0,$80,0,0,0
	dcb.w	44
	dc.b	$f7,$a0,$f,$e0,$ff,$c0,0,0
	dc.b	$f3,'@',$8f,$e0,$7f,$80,0,0
	dc.b	'z',$a0,'G',$e0,$bf,0,0,0
	dc.b	$bf,$d0,' ',$cf,$c0,'?',0,0
	dc.b	$df,$80,0,$9f,$e0,$7f,0,0
	dc.b	'?',$fc,$c0,'C',$e0,'?',0,0
	dc.b	$1f,$ff,$e0,0,$e0,0,0,0
	dc.b	$bf,$ff,'@',0,$f0,0,0,0
	dc.b	$ef,$ff,$80,0,'p',0,0,0
	dc.b	'O',$ff,$80,0,'x',0,0,0
	dc.b	'S',$ff,'L',0,'>',0,0,0
	dc.b	'$',$f,'x',$ff,$1f,0,0,0
	dc.b	$19,'01',$f0,$e,$f,0,0
	dc.b	2,'`',7,$e0,0,$1f,0,0
	dc.b	5,$12,$e,$e,$f,$fc,0,0
	dc.b	2,$b4,7,$e,$f,$f8,0,0
	dc.b	0,$a8,3,$1e,$f,$f0,0,0
	dc.b	9,$f0,8,$e,6,0,0,0
	dc.b	$d,$f0,$c,$e,2,0,0,0
	dc.b	$f,$f2,$e,$e,0,0,0,0
	dc.b	3,$f6,2,$e,$c,0,0,0
	dc.b	1,$fc,0,$c,$e,2,0,0
	dc.b	5,$f8,0,8,$e,6,0,0
	dc.b	$f,$f8,0,8,$e,6,0,0
	dc.b	$f,$f8,0,8,$e,6,0,0
	dc.b	$b,$f8,4,8,$e,6,0,0
	dc.b	1,$f8,$e,8,$e,6,0,0
	dc.b	$b,$f8,6,8,$e,6,0,0
	dc.b	'm',$fa,$82,$a,$fe,4,0,0
	dc.b	'e',$f6,$82,$e,$fe,0,0,0
	dc.b	$13,$f4,$e0,$e,$fc,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$e0,0,$1e,0,0,0,0
	dc.b	$ff,$f0,0,$1c,0,0,0,0
	dc.b	$ff,$d8,0,$1c,0,' ',0,0
	dc.b	$ff,$c8,0,$c8,0,'0',0,0
	dc.b	$e0,$e0,$ff,$e8,0,$10,0,0
	dc.b	'8',$e0,'?',$f0,$c0,0,0,0
	dc.b	$c,0,$f,$c0,$f0,0,0,0
	dc.b	$f7,$a0,$f,$e0,$ff,$c0,0,0
	dc.b	$f3,'@',$8f,$e0,$7f,$80,0,0
	dc.b	$fa,$a0,$c7,$e0,'?',0,0,0
	dc.b	$7f,'@`',$c0,$80,' ',0,0
	dc.b	'?',$80,' ',$80,$c0,'`',0,0
	dc.b	'?',$c0,' ',$c0,$c0,' ',0,0
	dc.b	$9f,'`',0,$e0,$e0,0,0,0
	dc.b	$df,'3',0,$ef,$e0,$1f,0,0
	dc.b	$df,'o',0,$df,$e0,'?',0,0
	dc.b	$df,$e7,0,$9f,$e0,$7f,0,0
	dc.b	'?',$ff,$c0,0,$e0,0,0,0
	dc.b	'_',$ff,$e0,0,$e0,0,0,0
	dc.b	'_',$ff,$e0,0,$e0,0,0,0
	dc.b	$ff,$ff,$e0,0,$e0,0,0,0
	dc.b	$ff,$ff,$e0,0,$e0,0,0,0
	dc.b	$df,$1c,$e0,$fc,$e0,3,0,0
	dc.b	'_',7,$e0,$ff,$e0,0,0,0
	dc.b	'?',$81,$c0,$ff,$e0,0,0,0
	dc.b	$ff,$c0,0,$e0,$e0,0,0,0
	dc.b	$df,'` `',$e0,$80,0,0
	dc.b	$bf,' ` ',$e0,$c0,0,0
	dc.b	'_ ',$e0,' ',$e0,$c0,0,0
	dc.b	$86,0,$df,$80,$e0,'`',0,0
	dc.b	$f,0,$bf,$c0,$c0,' ',0,0
	dc.b	$11,$80,'q',$e0,$8e,0,0,0
	dc.b	$e,'8',7,$c6,$f,$fe,0,0
	dc.b	$f,'r',$b,$8e,7,$fc,0,0
	dc.b	$f,'d',$d,$9e,3,$f8,0,0
	dc.b	7,$f8,6,$e,8,0,0,0
	dc.b	3,$f2,$12,$e,$c,0,0,0
	dc.b	1,$f6,' ',$e,$1e,0,0,0
	dc.b	'S',$fe,'@',$e,'<',0,0,0
	dc.b	';',$fe,$c0,$1e,$fc,0,0,0
	dc.b	$bf,$e0,$c0,2,$f8,$1c,0,0
	dc.b	$1f,$c4,$e0,4,$e0,'8',0,0
	dc.b	$ff,$e8,0,'l',0,$10,0,0
	dc.b	$ff,$f0,0,$f8,0,0,0,0
	dc.b	$ff,'`',1,$10,0,$e0,0,0
	dc.b	$ff,$e0,0,$f8,0,$f0,0,0
	dc.b	$ff,$b0,0,'|',0,'x',0,0
	dc.b	'?',$c8,' 0',$c0,'<',0,0
	dc.b	'w',$fc,'x',2,$80,$1c,0,0
	dc.b	$eb,$f2,$f8,2,4,$1c,0,0
	dc.b	$1b,$f2,'x',2,4,$c,0,0
	dc.b	$17,$f6,'0',6,$e,8,0,0
	dc.b	$d,$fe,$12,$e,$e,0,0,0
	dc.b	9,$f2,6,$e,$e,0,0,0
	dc.b	3,$d8,$f,$ce,$e,'0',0,0
	dc.b	$f,$9c,$f,$86,$c,'x',0,0
	dc.b	$f,$1e,$f,2,8,$fc,0,0
	dc.b	'Q ',$e0,$e0,$ff,$c0,0,0
	dc.b	'+@p',$e0,$ff,$80,0,0
	dc.b	$a,$80,'1',$e0,$ff,0,0,0
	dc.b	$9f,0,$80,$e0,'`',0,0,0
	dc.b	$df,' ',$c0,$e0,' ',0,0,0
	dc.b	$ff,'`',$e0,$e0,0,0,0,0
	dc.b	'?',$e0,' ',$e0,$c0,0,0,0
	dc.b	$1f,$a0,0,$a0,$e0,'@',0,0
	dc.b	'_ ',0,' ',$e0,$c0,0,0
	dc.b	$ff,' ',0,' ',$e0,$c0,0,0
	dc.b	$ff,'`',0,'`',$e0,$80,0,0
	dc.b	$bf,$c0,'@',$e0,$e0,0,0,0
	dc.b	$1f,$80,$e0,$e0,$e0,0,0,0
	dc.b	'_ ',$e0,$e0,$e0,0,0,0
	dc.b	'_C',$e0,$f3,$e0,'<',0,0
	dc.b	$1f,$88,$e0,$f0,$e0,$7f,0,0
	dc.b	$1f,$1c,$e0,$e0,$e0,$ff,0,0
	dc.b	$9f,$ff,'`',0,$e0,0,0,0
	dc.b	$ff,$ff,0,0,$e0,0,0,0
	dc.b	$df,$ff,' ',0,$e0,0,0,0
	dc.b	$9f,$ff,'`',0,$f0,0,0,0
	dc.b	$b7,$ff,$c0,0,'x',0,0,0
	dc.b	'v9',$87,$f8,'x',7,0,0
	dc.b	'D',$c,'G',$fc,'8',3,0,0
	dc.b	$1c,4,'?',$fc,0,3,0,0
	dcb.w	56
	dc.b	$f8,$e0,$f8,$1c,7,$fe,0,0
	dc.b	$e1,$80,$e0,'z',$1f,$fc,0,0
	dc.b	$f,2,0,$f6,$ff,$f8,0,0
	dc.b	$ff,$f4,0,$c,0,2,0,0
	dc.b	$ff,$fc,0,$c,0,2,0,0
	dc.b	$ff,$fc,0,$c,0,2,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	$e6,'8',6,$e,$f9,$f0,0,0
	dc.b	$9f,$9c,$1f,$86,$e0,'x',0,0
	dc.b	'0',$ce,'?',$c2,$c0,'<',0,0
	dc.b	6,'l',4,$e,3,$f0,0,0
	dc.b	$1e,'N',$10,$e,$f,$f1,0,0
	dc.b	'#]<',$1f,$1f,$e0,0,0
	dc.b	'C',$fd,'|',7,'>',0,0,0
	dc.b	'g',$ff,$18,1,'x',0,0,0
	dc.b	$bf,$ff,$80,0,'p',0,0,0
	dc.b	$f,$ff,0,0,$f0,0,0,0
	dc.b	$1f,$ff,0,0,$e0,0,0,0
	dc.b	'_',$8f,0,0,$e0,'p',0,0
	dc.b	$ff,$cf,0,$c0,$e0,'8',0,0
	dc.b	$ff,$7f,0,$e0,$e0,$18,0,0
	dc.b	$bf,'?@',$e0,$e0,$18,0,0
	dc.b	$1f,$8f,$e0,$f0,$e0,$18,0,0
	dc.b	'_',$c7,$e0,$f8,$e0,$18,0,0
	dc.b	$ff,$d7,$e0,$f8,$e0,$18,0,0
	dc.b	$ff,$7f,$e0,$f8,$e0,$18,0,0
	dc.b	'_',$7f,$e0,$f8,$e0,$18,0,0
	dc.b	$1f,'7',$e0,$f8,$e0,$18,0,0
	dc.b	$1f,$27,$e0,$f8,$e0,$18,0,0
	dc.b	$bf,$27,'@',$f8,$e0,$18,0,0
	dc.b	$ff,$f,0,$f0,$e0,$18,0,0
	dc.b	$ff,$1f,0,$e0,$e0,$18,0,0
	dc.b	$de,$11,'?',$e7,$c0,$18,0,0
	dc.b	$b3,3,'s',$ef,$8c,$10,0,0
	dc.b	'a',$87,$e1,$ff,$1e,0,0,0
	dc.b	'#@',$bc,'@',$7f,$80,0,0
	dc.b	'30',$fc,$10,$ff,$e0,0,0
	dc.b	$b6,'Hx8',$ff,$f0,0,0
	dc.b	$bf,'X@$',$c0,$f8,0,0
	dc.b	$ff,$e4,0,4,0,'8',0,0
	dc.b	$ff,$fc,0,$1c,0,0,0,0
	dc.b	$ff,$fc,0,$1e,0,0,0,0
	dc.b	$ff,$f8,0,$e,0,0,0,0
	dc.b	$e3,$f0,0,$e,$1c,0,0,0
	dc.b	$f7,$f2,'0',$e,$e,0,0,0
	dc.b	$c1,$f2,'>',$e,6,0,0,0
	dc.b	$c9,$f6,'>',$e,6,0,0,0
	dc.b	$db,$f6,'>',$e,6,0,0,0
	dc.b	$ff,$f6,'>',$e,6,0,0,0
	dc.b	$ef,$f6,'.',$e,$16,0,0,0
	dc.b	$ef,$f6,'.',$e,$16,0,0,0
	dc.b	$eb,$f6,'.',$e,$16,0,0,0
	dc.b	$e9,$f6,'.',$e,$16,0,0,0
	dc.b	$eb,$f6,'.',$e,$16,0,0,0
	dc.b	$ff,$f6,'>',$e,6,0,0,0
	dc.b	$dd,$f2,'>',$e,6,0,0,0
	dc.b	$db,$f2,'<',$e,6,0,0,0
	dc.b	$f,$e0,';',$ee,$c4,$10,0,0
	dc.b	$84,'p',$9f,$f6,'`',8,0,0
	dc.b	$c0,'0',$cf,$f2,'0',$c,0,0
	dc.b	0,$f0,8,$18,7,$e0,0,0
	dc.b	$1e,$80,'0t',$f,$f8,0,0
	dc.b	'#',8,'|',$f2,$1f,$fc,0,0
	dc.b	'Y',$dc,'~!>>',0,0
	dc.b	'_',$ff,$b8,1,'x',$e,0,0
	dc.b	$cf,$fc,$b0,0,'p',7,0,0
	dc.b	$ef,$fc,$10,0,$f0,3,0,0
	dc.b	'?',$fe,0,0,$e0,1,0,0
	dc.b	$1f,$ff,0,0,$e0,0,0,0
	dc.b	$df,$ff,0,0,$e0,0,0,0
	dc.b	$ff,'?',0,0,$e0,$c0,0,0
	dc.b	$bf,$9f,'@',$80,$e0,'`',0,0
	dc.b	$1f,$8f,$e0,$80,$e0,'p',0,0
	dc.b	'_',$cf,$e0,$c0,$e0,'8',0,0
	dc.b	$ff,$cf,$e0,$c0,$e0,'<',0,0
	dc.b	$ff,'m',$e0,$e2,$e0,$1e,0,0
	dc.b	'_x',$e0,$f7,$e0,$f,0,0
	dc.b	$1f,'(',$e0,$ef,$e0,7,0,0
	dc.b	$1f,'%',$e0,$e6,$e0,3,0,0
	dc.b	$bf,'#@',$e2,$e0,1,0,0
	dc.b	$ff,1,0,$e1,$e0,0,0,0
	dc.b	$ff,0,0,$e0,$e0,0,0,0
	dc.b	$de,0,'?',$e0,$c0,0,0,0
	dc.b	$b3,0,'s',$e0,$8c,0,0,0
	dc.b	'a',$80,$e1,$e0,$1e,0,0,0
	dc.b	5,$12,$e,$e,$f,$fc,0,0
	dc.b	2,$b4,7,$e,$f,$f8,0,0
	dc.b	8,$a8,$b,$1e,7,$f0,0,0
	dc.b	$d,$f0,$c,$e,2,0,0,0
	dc.b	7,$f0,$86,$e,8,0,0,0
	dc.b	$8b,$f2,$c2,$e,$c,0,0,0
	dc.b	$c9,$f6,$e0,$e,$e,0,0,0
	dc.b	$e5,$fc,$f8,$c,$e,2,0,0
	dc.b	$d3,$f8,$dc,8,'.',6,0,0
	dc.b	$c3,$f8,'D',8,'>',6,0,0
	dc.b	$c9,$f8,$e,8,'6',6,0,0
	dc.b	$e9,$f8,$a,8,$16,6,0,0
	dc.b	$fd,$f8,$e,8,2,6,0,0
	dc.b	$fd,$fc,4,$c,2,2,0,0
	dc.b	$ff,$fe,0,$e,0,0,0,0
	dc.b	$ff,$fe,0,$e,0,0,0,0
	dc.b	$ff,$f4,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,$80,0,0,0
	dc.b	$ff,$e0,0,$1e,$c0,0,0,0
	dc.b	$ff,$f0,0,$1c,$e0,0,0,0
	dc.b	$cf,$d8,0,$1c,$f0,' ',0,0
	dc.b	$cf,$c8,$8c,$cc,'p0',0,0
	dc.b	'X',$e0,'_',$e8,' ',$10,0,0
	dc.b	$10,$e0,'?',$f0,0,0,0,0
	dc.b	0,'@',$f,$e0,0,0,0,0
	dc.b	7,$1e,$c,1,3,$ff,0,0
	dc.b	$17,$9c,'<',3,$f,$ff,0,0
	dc.b	'-',$bc,'~',3,$1f,$ff,0,0
	dc.b	'M',$ff,'~',0,'>',0,0,0
	dc.b	$27,$ff,$f8,0,'x',0,0,0
	dc.b	$bf,$ff,$f0,0,'p',0,0,0
	dc.b	$cf,$ff,'0',0,$f0,0,0,0
	dc.b	$7f,$ff,0,0,$e0,0,0,0
	dc.b	$7f,$80,0,$7f,$e0,0,0,0
	dc.b	'?',0,0,$ff,$e0,0,0,0
	dc.b	'?',3,0,$ff,$e0,0,0,0
	dc.b	$9f,0,0,$e0,$e0,0,0,0
	dc.b	'_',0,$80,$e0,$e0,0,0,0
	dc.b	'?`',$c0,$e0,$e0,0,0,0
	dc.b	$df,$c2,$e0,$cf,$e0,'?',0,0
	dc.b	$ff,$97,$e0,$8f,$e0,$7f,0,0
	dc.b	$df,$bf,$e0,$f,$e0,$7f,0,0
	dc.b	$1f,$ff,$e0,0,$e0,0,0,0
	dc.b	$bf,$ff,'@',0,$f0,0,0,0
	dc.b	$ef,$ff,$80,0,'p',0,0,0
	dc.b	'O',$ff,$80,0,'x',0,0,0
	dc.b	'S',$ff,'L',0,'>',0,0,0
	dc.b	'$',$e1,'x',$ff,$1f,0,0,0
	dc.b	$19,'?1',$bf,$e,'@',0,0
	dc.b	2,$8e,7,$8e,0,'q',0,0
	dc.b	'y@',$fe,'`',$ff,$80,0,0
	dc.b	'q',$b0,$fe,'X',$ff,$e0,0,0
	dc.b	'c',$e8,$fc,'x',$ff,$f0,0,0
	dc.b	$ff,'X',0,$e4,0,$f8,0,0
	dc.b	$ff,$f4,0,4,0,'8',0,0
	dc.b	$ff,$ec,0,$c,0,$10,0,0
	dc.b	$ff,$f8,0,$1e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$f,$f2,$fc,$e,0,0,0,0
	dc.b	$f9,$f6,$fa,$e,6,0,0,0
	dc.b	$13,$f8,$16,8,$ee,6,0,0
	dc.b	7,$f8,$e,8,$e,6,0,0
	dc.b	7,$f8,$e,8,$e,6,0,0
	dc.b	$b,$f8,6,8,$e,6,0,0
	dc.b	'm',$fa,$82,$a,$fe,4,0,0
	dc.b	'e',$f6,$82,$e,$fe,0,0,0
	dc.b	$13,$f4,$e0,$e,$fc,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$e0,0,$1e,0,0,0,0
	dc.b	$ff,$f0,0,$1c,0,0,0,0
	dc.b	$ff,$d8,0,$1c,0,' ',0,0
	dc.b	$ff,$c8,0,$cc,0,'0',0,0
	dc.b	$e0,$e0,$ff,$e8,0,$10,0,0
	dc.b	'8',$e0,'?',$f0,$c0,0,0,0
	dc.b	$c,0,$f,$c0,$f0,0,0,0
	dc.b	'r',$13,$fc,$f,$ff,$ff,0,0
	dc.b	';3|',$f,$ff,$ff,0,0
	dc.b	$1d,$f4,'>',$f,$ff,$ff,0,0
	dc.b	$9f,$ff,$80,0,'`',0,0,0
	dc.b	$df,$ff,$c0,0,' ',0,0,0
	dc.b	$ff,$ff,$e0,0,0,0,0,0
	dc.b	$9f,$ff,$80,0,'`',0,0,0
	dc.b	$1f,$ff,0,0,$e0,0,0,0
	dc.b	$e0,0,$ff,$ff,0,0,0,0
	dc.b	$e7,$8d,'`~',$9f,$ff,0,0
	dc.b	$df,$ff,0,0,$e0,0,0,0
	dc.b	$ff,$ff,0,0,$e0,0,0,0
	dc.b	$bf,$ff,'@',0,$e0,0,0,0
	dc.b	$1f,$ff,$e0,0,$e0,0,0,0
	dc.b	'_',$ff,$e0,0,$e0,0,0,0
	dc.b	$ff,$80,$e0,$ff,$e0,0,0,0
	dc.b	'_C',$e0,$7f,$e0,$80,0,0
	dc.b	$1f,'&',$e0,'>',$e0,$c1,0,0
	dc.b	$1f,$80,$e0,$80,$e0,'`',0,0
	dc.b	$bf,$80,'@',$80,$e0,'`',0,0
	dc.b	$ff,$c0,0,$c0,$e0,' ',0,0
	dc.b	$ff,'`',0,$e0,$e0,0,0,0
	dc.b	$de,' ?',$e0,$c0,0,0,0
	dc.b	$b3,0,'s',$e0,$8c,0,0,0
	dc.b	'a',$80,$e1,$e0,$1e,0,0,0
	dc.b	$9c,$c0,$e0,$10,$ff,$e0,0,0
	dc.b	's',$98,$80,'l',$ff,$f0,0,0
	dc.b	'w4',$80,$c4,$ff,$f8,0,0
	dc.b	$ff,$ec,0,$e,0,'0',0,0
	dc.b	$ff,$fe,0,$1e,0,0,0,0
	dc.b	$ff,$f8,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	3,$f0,$fe,$e,0,0,0,0
	dc.b	'k',$f0,$1c,$e,$fe,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f8,0,$e,0,0,0,0
	dc.b	$ff,$fe,0,$1e,0,0,0,0
	dc.b	$ff,$e4,0,'&',0,$18,0,0
	dc.b	$f8,'4',$ff,$f4,0,8,0,0
	dc.b	$8e,$18,$8f,$fc,'p',0,0,0
	dc.b	3,$80,3,$f0,$fc,0,0,0
	dcb.w	28
	dc.b	7,$1e,$c,1,3,$ff,0,0
	dc.b	$17,$94,'<',$b,$f,$ff,0,0
	dc.b	'-',$bc,'~',3,$1f,$ff,0,0
	dc.b	'M',$ff,'~',0,'>',0,0,0
	dc.b	$27,$ff,$f8,0,'x',0,0,0
	dc.b	$bf,$ff,$f0,0,'p',0,0,0
	dc.b	$cf,$ff,'0',0,$f0,0,0,0
	dc.b	$7f,$ff,0,0,$e0,0,0,0
	dc.b	$7f,$80,0,$7f,$e0,0,0,0
	dc.b	'?',0,0,$ff,$e0,0,0,0
	dc.b	'?',3,0,$ff,$e0,0,0,0
	dc.b	$9f,0,0,$e0,$e0,0,0,0
	dc.b	'_',0,$80,$e0,$e0,0,0,0
	dc.b	'?`',$c0,$e0,$e0,0,0,0
	dc.b	$df,$c8,$e0,$c7,$e0,'?',0,0
	dc.b	$ff,$98,$e0,$87,$e0,$7f,0,0
	dc.b	$df,$bc,$e0,3,$e0,$7f,0,0
	dc.b	$1f,$ff,$e0,0,$e0,0,0,0
	dc.b	$bf,$ff,'@',0,$f0,0,0,0
	dc.b	$ef,$ff,$80,0,'p',0,0,0
	dc.b	'O',$ff,$80,0,'x',0,0,0
	dc.b	'S',$ff,'L',0,'>',0,0,0
	dc.b	'$',$b9,'x',$f8,$1f,7,0,0
	dc.b	$19,$c,'1',$fc,$e,3,0,0
	dc.b	3,$84,7,$fc,0,3,0,0
	dc.b	'y@',$fe,'`',$ff,$80,0,0
	dc.b	'q',$b0,$fe,'X',$ff,$e0,0,0
	dc.b	'c',$e8,$fc,'x',$ff,$f0,0,0
	dc.b	$ff,'X',0,$e4,0,$f8,0,0
	dc.b	$ff,$f4,0,4,0,'8',0,0
	dc.b	$ff,$ec,0,$c,0,$10,0,0
	dc.b	$ff,$f8,0,$1e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$f,$f2,$fc,$e,0,0,0,0
	dc.b	$f9,$f6,$fa,$e,6,0,0,0
	dc.b	$13,$f8,$16,8,$ee,6,0,0
	dc.b	7,$f8,$e,8,$e,6,0,0
	dc.b	7,$fc,$e,$c,$e,2,0,0
	dc.b	$b,$f6,6,$e,$e,0,0,0
	dc.b	'm',$f2,$f2,$e,$fe,0,0,0
	dc.b	$f5,$f8,$f9,$f2,$fe,$c,0,0
	dc.b	'a',$c2,$ff,$f6,$ff,$f8,0,0
	dc.b	$ff,$f4,0,$c,0,2,0,0
	dc.b	$ff,$fc,0,$c,0,2,0,0
	dc.b	$ff,$fc,0,$c,0,2,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	$e6,'8',6,$e,$f9,$f0,0,0
	dc.b	$9f,$9c,$1f,$86,$e0,'x',0,0
	dc.b	'0',$ce,'?',$c2,$c0,'<',0,0
	dc.b	'r',$13,$fc,$f,$ff,$ff,0,0
	dc.b	';3|',$f,$ff,$ff,0,0
	dc.b	$1d,$f4,'>',$f,$ff,$ff,0,0
	dc.b	$9f,$ff,$80,0,'`',0,0,0
	dc.b	$df,$ff,$c0,0,' ',0,0,0
	dc.b	$ff,$ff,$e0,0,0,0,0,0
	dc.b	$9f,$ff,$80,0,'`',0,0,0
	dc.b	$1f,$ff,0,0,$e0,0,0,0
	dc.b	$e0,0,$ff,$ff,0,0,0,0
	dc.b	$e7,$8d,'`~',$9f,$ff,0,0
	dc.b	$df,$ff,0,0,$e0,0,0,0
	dc.b	$7f,$ff,$80,0,$e0,0,0,0
	dc.b	'?',$ff,$c0,0,$e0,0,0,0
	dc.b	'_',$ff,$e0,0,$e0,0,0,0
	dc.b	$df,$ff,$e0,0,$e0,0,0,0
	dc.b	$df,$1c,$e0,$fc,$e0,3,0,0
	dc.b	'_',7,$e0,$ff,$e0,0,0,0
	dc.b	$1f,$81,$e0,$ff,$e0,0,0,0
	dc.b	$bf,$c0,'@',$e0,$e0,0,0,0
	dc.b	$df,'` `',$e0,$80,0,0
	dc.b	$bf,' ` ',$e0,$c0,0,0
	dc.b	'_ ',$e0,' ',$e0,$c0,0,0
	dc.b	$86,0,$df,$80,$e0,'`',0,0
	dc.b	$f,0,$bf,$c0,$c0,' ',0,0
	dc.b	$11,$80,'q',$e0,$8e,0,0,0
	dc.b	$9c,$c0,$e0,$10,$ff,$e0,0,0
	dc.b	's',$98,$80,'l',$ff,$f0,0,0
	dc.b	'w4',$80,$c4,$ff,$f8,0,0
	dc.b	$ff,$ec,0,$e,0,'0',0,0
	dc.b	$ff,$fe,0,$1e,0,0,0,0
	dc.b	$ff,$f8,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	3,$f0,$fe,$e,0,0,0,0
	dc.b	'k',$f0,$1c,$e,$fe,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f8,0,$e,0,0,0,0
	dc.b	$ff,$fe,0,$1e,0,0,0,0
	dc.b	$ff,$ec,0,' ',0,$1c,0,0
	dc.b	'?',$fe,0,0,$f8,$1e,0,0
	dc.b	$1b,$f2,4,0,$fc,$e,0,0
	dc.b	$91,$f8,$8e,8,'~',6,0,0
	dc.b	$b,$fc,6,$c,$e,2,0,0
	dc.b	$f,$f6,$e,$e,$e,0,0,0
	dc.b	$d,$f2,$e,$e,$e,0,0,0
	dc.b	$b,$f0,$c,$e,$e,0,0,0
	dc.b	7,$e0,$b,$ee,$c,$10,0,0
	dc.b	$c,'p',7,$f6,8,8,0,0
	dc.b	8,'0',$f,$f2,0,$c,0,0
	dc.b	$18,'o0',$1f,$f,$ff,0,0
	dc.b	'lwP',$f,'?',$ff,0,0
	dc.b	't9',$b8,7,$7f,$ff,0,0
	dc.b	$b7,$ff,$f8,0,'x',0,0,0
	dc.b	$cf,$ff,'0',0,$f0,0,0,0
	dc.b	$ff,$ff,0,0,$e0,0,0,0
	dc.b	$7f,$ff,0,0,$e0,0,0,0
	dc.b	$9f,$ff,$80,0,'`',0,0,0
	dc.b	$df,'@',$c0,$7f,' ',$80,0,0
	dc.b	$9f,$cc,$80,'?`',$ff,0,0
	dc.b	'?',$ff,0,0,$e0,0,0,0
	dc.b	$ff,$ff,0,0,$e0,0,0,0
	dc.b	$9f,$ff,'`',0,$e0,0,0,0
	dc.b	$af,$ff,$c0,0,'p',0,0,0
	dc.b	'_',$ff,$18,0,'`',0,0,0
	dc.b	$dc,$c0,'l',$ff,$f3,0,0,0
	dc.b	$f1,$99,'>',7,$ff,$ff,0,0
	dc.b	$ff,$ff,0,0,$e0,0,0,0
	dc.b	'?',$ff,$c0,0,$e0,0,0,0
	dc.b	$9f,$ff,$e0,0,$e0,0,0,0
	dc.b	$ff,$ff,$e0,0,$e0,0,0,0
	dc.b	$df,$ff,$e0,0,$e0,0,0,0
	dc.b	$a9,$b9,$f9,$f8,$c6,7,0,0
	dc.b	'S',$c,$f3,$fc,$8c,3,0,0
	dc.b	$a6,4,$e7,$fc,$18,3,0,0
	dc.b	'fr',$81,$fe,$ff,$fc,0,0
	dc.b	'&',$e4,$c1,$fe,$ff,$f8,0,0
	dc.b	$ad,$c8,$c3,$fe,$ff,$f0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$f8,0,8,0,6,0,0
	dc.b	$ff,$f0,0,0,0,$e,0,0
	dc.b	$ff,$fe,0,$e,0,0,0,0
	dc.b	'<',$e,$ff,$fe,0,0,0,0
	dc.b	$e0,$ee,0,$16,$ff,$f8,0,0
	dc.b	$ff,$d8,0,'<',0,'<',0,0
	dc.b	$ff,$f6,0,$18,0,$1e,0,0
	dc.b	$ff,$fc,0,0,0,$e,0,0
	dc.b	$ff,$f2,0,2,0,$c,0,0
	dc.b	$ff,$fe,0,$e,0,0,0,0
	dc.b	$1d,$f0,$fc,$e,2,0,0,0
	dc.b	$b1,$f0,$c0,$e,$fe,0,0,0
	dc.b	$ff,$f8,0,$e,0,0,0,0
	dc.b	$ff,$fc,0,$e,0,0,0,0
	dc.b	$ff,$fe,0,$e,0,0,0,0
	dc.b	$ff,$e6,0,6,0,$18,0,0
	dc.b	$ff,$d0,0,2,0,'<',0,0
	dc.b	$e6,'<',6,4,$f9,$f8,0,0
	dc.b	$9f,$90,$1f,$84,$e0,'x',0,0
	dc.b	'0',$d0,'?',$d8,$c0,' ',0,0
	dc.b	'r',$13,$fc,$f,$ff,$ff,0,0
	dc.b	';3|',$f,$ff,$ff,0,0
	dc.b	$1d,$f4,'>',$f,$ff,$ff,0,0
	dc.b	$9f,$ff,$80,0,'`',0,0,0
	dc.b	$df,$ff,$c0,0,' ',0,0,0
	dc.b	$ff,$ff,$e0,0,0,0,0,0
	dc.b	$9f,$ff,$80,0,'`',0,0,0
	dc.b	'?',$ff,0,0,$e0,0,0,0
	dc.b	$c3,'7',$1f,'0',$e0,$c8,0,0
	dc.b	$8c,'g<h',$c3,$98,0,0
	dc.b	$11,$cf,'q',$d8,'Ž8',0,0
	dc.b	0,$1f,0,'8',0,'8',0,0
	dc.b	0,'7',0,'8',0,'8',0,0
	dc.b	0,$27,0,'8',0,'8',0,0
	dc.b	0,$f,0,'8',0,'8',0,0
	dc.b	0,$1f,0,'8',0,'8',0,0
	dc.b	0,'?',0,'8',0,'8',0,0
	dc.b	0,$17,0,'8',0,'8',0,0
	dc.b	0,7,0,'8',0,'8',0,0
	dc.b	0,'/',0,$10,0,'8',0,0
	dc.b	0,'?',0,0,0,'8',0,0
	dc.b	0,'?',0,0,0,'8',0,0
	dc.b	0,'7',0,$f,0,'0',0,0
	dc.b	0,',',0,$1c,0,'#',0,0
	dc.b	0,$18,0,'8',0,7,0,0
	dc.b	$9c,$e0,$e0,$1c,$ff,$fe,0,0
	dc.b	'q',$80,$80,'z',$ff,$fc,0,0
	dc.b	'w',2,$80,$f6,$ff,$f8,0,0
	dc.b	$ff,$f4,0,$c,0,2,0,0
	dc.b	$ff,$fc,0,$c,0,2,0,0
	dc.b	$ff,$fc,0,$c,0,2,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	$ee,'8>',$e,1,$f0,0,0
	dc.b	$d7,$9c,$1f,$86,' x',0,0
	dc.b	$c8,$ce,$f,$c2,'0<',0,0
	dc.b	$e0,0,' ',0,$18,0,0,0
	dc.b	$e0,0,' ',0,$18,0,0,0
	dc.b	$f0,0,'0',0,8,0,0,0
	dc.b	$f0,0,'0',0,8,0,0,0
	dc.b	$d8,0,'8',0,0,0,0,0
	dc.b	$d8,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$c0,0,'8',0,0,0,0,0
	dc.b	$c0,0,'8',0,0,0,0,0
	dc.b	$80,0,$f8,0,0,0,0,0
	dc.b	$c0,0,$f8,0,0,0,0,0
	dc.b	'`',0,'x',0,$80,0,0,0
	dc.b	'Q ',$e0,$e0,$ff,$c0,0,0
	dc.b	'+@p',$e0,$ff,$80,0,0
	dc.b	$a,$80,'1',$e0,$ff,0,0,0
	dc.b	$9f,0,$80,$e0,'`',0,0,0
	dc.b	$df,0,$c0,$e0,' ',0,0,0
	dc.b	$ff,' ',$e0,$e0,0,0,0,0
	dc.b	'?` ',$e0,$c0,0,0,0
	dc.b	$1f,$c0,0,$c0,$e0,' ',0,0
	dc.b	'_',$80,0,$80,$e0,'`',0,0
	dc.b	$ff,$80,0,$80,$e0,'`',0,0
	dc.b	$ff,$80,0,$80,$e0,'`',0,0
	dc.b	$bf,$80,'@',$80,$e0,'`',0,0
	dc.b	$1f,$80,$e0,$80,$e0,'`',0,0
	dc.b	'_',$c0,$e0,$c0,$e0,' ',0,0
	dc.b	$ff,$95,$e0,$8e,$e0,$7f,0,0
	dc.b	$ff,',',0,$1f,$e0,$ff,0,0
	dc.b	$ff,$de,0,'?',$e0,$7f,0,0
	dc.b	$1f,$ff,$e0,0,$e0,0,0,0
	dc.b	$bf,$ff,'@',0,$f0,0,0,0
	dc.b	$ef,$ff,$80,0,'p',0,0,0
	dc.b	'O',$ff,$80,0,'x',0,0,0
	dc.b	'S',$ff,'L',0,'>',0,0,0
	dc.b	'$',$f,'x',$ff,$1f,0,0,0
	dc.b	$19,'01',$f0,$e,$f,0,0
	dc.b	2,'`',7,$e0,0,$1f,0,0
	dc.b	6,$f2,$f,2,$f,$fc,0,0
	dc.b	$b,'d',7,$86,$f,$f8,0,0
	dc.b	$d,'H',3,$8e,$f,$f0,0,0
	dc.b	7,$f0,8,$e,$e,0,0,0
	dc.b	3,$f0,$c,$e,$e,0,0,0
	dc.b	9,$f0,$e,$e,$e,0,0,0
	dc.b	$f,$f2,$e,$e,$e,0,0,0
	dc.b	$f,$f6,$e,$e,$e,0,0,0
	dc.b	9,$fe,$e,$e,$e,0,0,0
	dc.b	1,$fa,$e,$a,$e,4,0,0
	dc.b	3,$f0,$c,0,$e,$e,0,0
	dc.b	$f,$f4,0,0,$e,$e,0,0
	dc.b	1,$f4,0,0,$e,$e,0,0
	dc.b	9,$f0,0,0,$e,$e,0,0
	dc.b	$a5,$fa,$18,$a,$fe,4,0,0
	dc.b	$93,$fe,$c,$e,$fe,0,0,0
	dc.b	$93,$f6,$c,$e,$fc,0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	$ff,$e0,0,$1e,0,0,0,0
	dc.b	$ff,$f0,0,$1e,0,0,0,0
	dc.b	$ff,$d8,0,$1c,0,' ',0,0
	dc.b	$ff,$c8,0,$cc,0,'0',0,0
	dc.b	0,$e0,$ff,$e8,0,$10,0,0
	dc.b	$e0,'`',$ff,$f0,0,0,0,0
	dc.b	'8',0,'?',$c0,$c0,0,0,0
	dc.b	'Q ',$e0,$e0,$ff,$c0,0,0
	dc.b	'+@p',$e0,$ff,$80,0,0
	dc.b	$a,$80,'1',$e0,$ff,0,0,0
	dc.b	$9f,0,$80,$e0,'`',0,0,0
	dc.b	$df,0,$c0,$e0,' ',0,0,0
	dc.b	$ff,'!',$e0,$e1,0,0,0,0
	dc.b	'?b ',$e3,$c0,1,0,0
	dc.b	$1f,$c5,0,$c7,$e0,'#',0,0
	dc.b	'_',$8a,0,$8f,$e0,'g',0,0
	dc.b	$ff,$99,0,$96,$e0,'o',0,0
	dc.b	$ff,$83,0,$9c,$e0,'~',0,0
	dc.b	$bf,$b7,'@',$98,$e0,'|',0,0
	dc.b	$1f,$97,$e0,$b8,$e0,'x',0,0
	dc.b	'_',$ef,$e0,$b0,$e0,'p',0,0
	dc.b	$ff,$bf,$e0,$e0,$e0,'`',0,0
	dc.b	$ff,'?',$e0,'@',$e0,$c0,0,0
	dc.b	'_',$fe,$e0,1,$e0,0,0,0
	dc.b	$1f,$fc,$e0,3,$e0,0,0,0
	dc.b	$bf,$f8,'@',7,$e0,0,0,0
	dc.b	$ff,$f0,0,$f,$e0,0,0,0
	dc.b	'O',$f8,0,$1e,$f0,0,0,0
	dc.b	$1f,$bc,$98,'<`@',0,0
	dc.b	's',$18,$7f,$18,0,$e0,0,0
	dc.b	'!',$10,$7f,$10,0,$e0,0,0
	dc.b	1,$c0,$1f,$e0,0,0,0,0
	dc.b	9,'$',$e,$1c,7,$fe,0,0
	dc.b	$1a,$c8,$13,':',$f,$fc,0,0
	dc.b	'9',$12,'!',$f6,$1f,$f8,0,0
	dc.b	'K',$fe,'p',$e,'<',0,0,0
	dc.b	$af,$e2,$f0,$1e,'x',0,0,0
	dc.b	'_',$c0,$e0,'<',$f0,0,0,0
	dc.b	$df,$80,$e0,'x',$e0,0,0,0
	dc.b	$bf,0,$c0,$f0,$c0,0,0,0
	dc.b	'~',0,$81,$e0,$80,0,0,0
	dc.b	$fc,0,3,$c0,0,0,0,0
	dc.b	$f9,$80,7,$80,0,0,0,0
	dc.b	$f7,0,$f,$80,0,0,0,0
	dc.b	$fc,0,$1d,0,2,0,0,0
	dc.b	$f0,0,'2',0,$c,0,0,0
	dc.b	$e0,0,'d',0,$18,0,0,0
	dc.b	'@',0,$c8,0,'0',0,0,0
	dc.b	$c0,0,$d0,0,' ',0,0,0
	dc.b	$c0,0,$e0,0,0,0,0,0
	dc.b	$80,0,$c0,0,0,0,0,0
	dcb.w	24
	dc.b	$f7,$aa,$f,$fc,$ff,$df,0,0
	dc.b	$f3,'E',$8f,$ee,$7f,$9f,0,0
	dc.b	$fa,$a2,$c7,$e7,'?',$1f,0,0
	dc.b	$7f,'W`',$c0,$80,'8',0,0
	dc.b	'?',$9f,' ',$80,$c0,'x',0,0
	dc.b	'?',$8f,' ',$90,$c0,'x',0,0
	dc.b	$1f,$87,0,$98,$e0,'x',0,0
	dc.b	'_',$9f,0,$98,$e0,'x',0,0
	dc.b	$df,$bf,0,$b8,$e0,'X',0,0
	dc.b	$df,$ff,0,$f8,$e0,$18,0,0
	dc.b	'_',$df,$80,$f8,$e0,$18,0,0
	dc.b	$7f,$97,$80,$f8,$e0,$18,0,0
	dc.b	'?',7,$c0,$f8,$e0,$18,0,0
	dc.b	$1f,$27,$e0,$f8,$e0,$18,0,0
	dc.b	$df,'G',$e0,$d8,$e0,'8',0,0
	dc.b	$ff,$b7,$e0,$88,$e0,'x',0,0
	dc.b	$df,$ff,$e0,0,$e0,'p',0,0
	dc.b	$1f,$ff,$e0,0,$e0,0,0,0
	dc.b	$bf,$ff,'@',0,$f0,0,0,0
	dc.b	$ef,$ff,$80,0,'p',0,0,0
	dc.b	$f,$fe,$80,1,'x',0,0,0
	dc.b	'S',$f9,'L',7,'>',0,0,0
	dc.b	'4',$e1,'h',$ff,$1f,0,0,0
	dc.b	$19,'31',$be,$e,'A',0,0
	dc.b	6,$98,$f,$9c,0,'`',0,0
	dc.b	$9e,$f2,'w',2,$ff,$fc,0,0
	dc.b	$b3,'dg',$86,$ff,$f8,0,0
	dc.b	'mH',$cb,$8e,$f7,$f0,0,0
	dc.b	$cb,$f0,$c,$e,'6',0,0,0
	dc.b	$dd,$f0,$1e,$e,'&',0,0,0
	dc.b	$ff,$f0,'>',$e,6,0,0,0
	dc.b	$f3,$f2,'>',$e,6,0,0,0
	dc.b	$e1,$f6,'>',$e,6,0,0,0
	dc.b	$c5,$fe,':',$e,6,0,0,0
	dc.b	$c5,$fa,':',$a,6,4,0,0
	dc.b	$e5,$f0,':',0,6,$e,0,0
	dc.b	$e3,$f4,'>',0,6,$e,0,0
	dc.b	$f7,$f4,'>',0,6,$e,0,0
	dc.b	$fd,$f0,'>',0,6,$e,0,0
	dc.b	$d1,$fa,$16,$a,'.',4,0,0
	dc.b	$c9,$fe,6,$e,'>',0,0,0
	dc.b	$ff,$f6,0,$e,$1c,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$e0,0,$1e,0,0,0,0
	dc.b	$ff,$f0,0,$1e,0,0,0,0
	dc.b	$ff,$d8,0,$1c,0,' ',0,0
	dc.b	$ff,$c8,0,$cc,$c0,'0',0,0
	dc.b	$98,$e0,$1f,$e8,$e0,$10,0,0
	dc.b	$b8,$e0,'?',$f0,$c0,0,0,0
	dc.b	'|',0,$ff,$c0,0,0,0,0
	dc.b	$f7,$a0,$f,$e0,$ff,$c0,0,0
	dc.b	$f3,'@',$8f,$e0,$7f,$80,0,0
	dc.b	$fa,$a0,$c7,$e0,'?',0,0,0
	dc.b	$7f,'@`',$c0,$80,' ',0,0
	dc.b	'?',$80,' ',$90,$c0,'`',0,0
	dc.b	'?',$c0,' ',$c8,$c0,'0',0,0
	dc.b	$9f,$cc,0,'D',$e0,'8',0,0
	dc.b	'_',$93,' ',$f,$f0,$7f,0,0
	dc.b	$9f,$f3,$e0,$f,'p?',0,0
	dc.b	'g',$f3,$80,$f,'x',$f,0,0
	dc.b	'O',$ff,'L',0,'0',0,0,0
	dc.b	$1f,$ff,'~',0,0,0,0,0
	dc.b	$b,$ff,'3',0,$c,0,0,0
	dc.b	'3',$ff,',',0,$1e,0,0,0
	dc.b	'S',$ff,'|',0,'<',0,0,0
	dc.b	$7f,$f8,$b8,8,'x',7,0,0
	dc.b	$bf,$cf,$f0,'?p',0,0,0
	dc.b	$8f,$c1,'p',$7f,$f0,0,0,0
	dc.b	'?',$e0,$c0,'x',$e0,0,0,0
	dc.b	'_',$e0,$80,$f0,$e0,0,0,0
	dc.b	$df,'`',0,$e0,$e0,0,0,0
	dc.b	$9f,' ',0,$e0,$e0,0,0,0
	dc.b	$a1,0,'?',$e0,$c0,0,0,0
	dc.b	'C',$80,$7f,$e0,$80,0,0,0
	dc.b	$87,$c0,$ff,$e0,0,0,0,0
	dc.b	$e,'8',7,$c6,$f,$fe,0,0
	dc.b	$f,'r',$b,$8e,7,$fc,0,0
	dc.b	$f,'d',$d,$9e,3,$f8,0,0
	dc.b	7,$f8,6,$e,8,0,0,0
	dc.b	$13,$f2,$12,$e,$c,0,0,0
	dc.b	'!',$f6,' ',$e,$1e,0,0,0
	dc.b	's',$fe,'@',$e,'<',0,0,0
	dc.b	';',$fe,$c0,$1e,$fc,0,0,0
	dc.b	$bf,$e0,$c0,2,$f8,$1c,0,0
	dc.b	$1f,$c4,$e0,4,$e0,'8',0,0
	dc.b	$ff,$e8,0,'l',0,$10,0,0
	dc.b	$ff,$f0,0,$f8,0,0,0,0
	dc.b	$ff,'p',1,$10,0,$e0,0,0
	dc.b	$ff,$e8,0,$f8,0,$f0,0,0
	dc.b	$ff,$bc,0,'t',0,'x',0,0
	dc.b	'?',$cc,' 0',$c0,'<',0,0
	dc.b	'w',$fe,'x',2,$80,$1c,0,0
	dc.b	$eb,$f0,$f8,0,4,$1e,0,0
	dc.b	$1b,$f2,'8',2,4,$c,0,0
	dc.b	$17,$f6,$10,6,$e,8,0,0
	dc.b	$d,$fe,$12,$e,$e,0,0,0
	dc.b	9,$f2,6,$e,$e,0,0,0
	dc.b	3,$d8,$f,$ce,$e,'0',0,0
	dc.b	$f,$9c,$f,$86,$c,'x',0,0
	dc.b	$f,$1e,$f,2,8,$fc,0,0
	dc.b	$f7,$a0,$f,$e0,$ff,$c0,0,0
	dc.b	$f3,'@',$8f,$e0,$7f,$80,0,0
	dc.b	$fa,$a0,$c7,$e0,'?',0,0,0
	dc.b	$7f,'@`',$c0,$80,' ',0,0
	dc.b	'?',$80,' ',$90,$c0,'`',0,0
	dc.b	'?',$d0,' ',$d8,$c0,' ',0,0
	dc.b	$9f,$c0,0,'D',$e0,'8',0,0
	dc.b	'_” ',$b,$f0,$7f,0,0
	dc.b	$9f,$f3,$e0,$f,'p?',0,0
	dc.b	'g',$f3,0,$f,'x',$f,0,0
	dc.b	'O',$ff,'L',0,'0',0,0,0
	dc.b	'?',$ff,'>',0,0,0,0,0
	dc.b	$1b,$ff,'3',0,$c,0,0,0
	dc.b	8,$ff,$18,$c0,7,0,0,0
	dc.b	5,$97,$d,$f0,2,8,0,0
	dc.b	1,'/',3,$e8,0,$18,0,0
	dc.b	0,'_',0,$d8,0,'8',0,0
	dc.b	0,'7',0,'x',0,'8',0,0
	dc.b	0,$27,0,'8',0,'8',0,0
	dc.b	0,7,0,'8',0,'8',0,0
	dc.b	0,$f,0,'0',0,'8',0,0
	dc.b	0,'?',0,0,0,'8',0,0
	dc.b	0,'7',0,$f,0,'0',0,0
	dc.b	0,',',0,$1c,0,'#',0,0
	dc.b	0,$18,0,'8',0,7,0,0
	dc.b	$e,'8',7,$c6,$f,$fe,0,0
	dc.b	$f,'r',$b,$8e,7,$fc,0,0
	dc.b	$f,'d',$d,$9e,3,$f8,0,0
	dc.b	7,$f8,6,$e,8,0,0,0
	dc.b	3,$f2,$12,$e,$c,0,0,0
	dc.b	$11,$f6,$10,$e,$e,0,0,0
	dc.b	3,$fe,'@',$e,'<',0,0,0
	dc.b	$bb,$fe,'@',$1e,$fc,0,0,0
	dc.b	$bf,$e0,$c0,2,$f8,$1c,0,0
	dc.b	$1f,$c0,$e0,0,$e0,'<',0,0
	dc.b	$ff,$e4,0,'d',0,$18,0,0
	dc.b	$ff,$f8,0,$fc,0,0,0,0
	dc.b	$fe,'p',1,$f8,0,0,0,0
	dc.b	$ff,0,7,$f0,0,0,0,0
	dc.b	$e3,$80,'?',$e0,0,0,0,0
	dc.b	$d1,0,$1f,$80,' ',0,0,0
	dc.b	$c8,0,$e,0,'0',0,0,0
	dc.b	$e0,0,' ',0,$18,0,0,0
	dc.b	$f0,0,'0',0,8,0,0,0
	dc.b	$d0,0,'0',0,8,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$80,0,$f8,0,0,0,0,0
	dc.b	$c0,0,$f8,0,0,0,0,0
	dc.b	'`',0,'x',0,$80,0,0,0
	dc.b	'r',$13,$fc,$f,$ff,$ff,0,0
	dc.b	';3|',$f,$ff,$ff,0,0
	dc.b	$1d,$f4,'>',$f,$ff,$ff,0,0
	dc.b	$9f,$ff,$80,0,'`',0,0,0
	dc.b	$df,$ff,$c0,0,' ',0,0,0
	dc.b	$ff,$ff,$e0,0,0,0,0,0
	dc.b	$9f,$ff,$80,0,'`',0,0,0
	dc.b	'?',$ff,0,0,$e0,0,0,0
	dc.b	$c3,$f0,$1f,$ff,$e0,0,0,0
	dc.b	$87,$c0,'?',$fe,$c0,1,0,0
	dc.b	$1f,'!',$7f,$e2,$80,$1e,0,0
	dc.b	4,'?',4,0,3,$f8,0,0
	dc.b	$1b,$ff,$14,0,$f,$e0,0,0
	dc.b	'1',$ff,'.',0,$1f,$80,0,0
	dc.b	'Y',$ff,'~',0,'>',0,0,0
	dc.b	$ff,$ff,$b8,0,'x',0,0,0
	dc.b	$bf,$fd,'p',3,$f0,0,0,0
	dc.b	$9f,$ff,'`',0,$e0,0,0,0
	dc.b	$ff,$ff,0,0,$e0,0,0,0
	dc.b	$ff,$ff,0,0,$e0,0,0,0
	dc.b	$df,$ff,0,0,$e0,0,0,0
	dc.b	$9f,$ff,0,0,$e0,0,0,0
	dc.b	$a7,'9?',$f8,$c0,7,0,0
	dc.b	'N',$c,$7f,$fc,$80,3,0,0
	dc.b	$9f,4,$ff,$fc,0,3,0,0
	dc.b	$9c,$9e,$e0,'~',$ff,$fc,0,0
	dc.b	'r',$bc,$80,'~',$ff,$f8,0,0
	dc.b	'wx',$80,$fe,$ff,$f0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$f8,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	'?',$f8,$e0,$e,0,0,0,0
	dc.b	$7f,$ee,0,$e,$80,$10,0,0
	dc.b	$ff,$e4,0,'&',0,$18,0,0
	dc.b	$ff,'h',0,$ec,0,$10,0,0
	dc.b	$fc,'0',3,$f8,0,0,0,0
	dc.b	$f0,0,$f,$f0,0,0,0,0
	dc.b	$c7,'L?<',0,$fe,0,0
	dc.b	'w',$18,$f0,$fa,$f,$fc,0,0
	dc.b	'<r',3,$f6,$ff,$f8,0,0
	dc.b	$ff,$f4,0,$c,0,2,0,0
	dc.b	$ff,$fc,0,$c,0,2,0,0
	dc.b	$ff,$fc,0,$c,0,2,0,0
	dc.b	$ff,$f6,0,$e,0,0,0,0
	dc.b	$ff,$f2,0,$e,0,0,0,0
	dc.b	$e6,'8',6,$e,$f9,$f0,0,0
	dc.b	$9f,$9c,$1f,$86,$e0,'x',0,0
	dc.b	'0',$ce,'?',$c2,$c0,'<',0,0
	dc.b	0,$14,0,'8',0,'?',0,0
	dc.b	0,$a,0,$1c,0,'?',0,0
	dc.b	0,2,0,$c,0,'?',0,0
	dc.b	0,$27,0,' ',0,$18,0,0
	dc.b	0,$17,0,$10,0,'(',0,0
	dc.b	0,$f,0,8,0,'0',0,0
	dc.b	0,$27,0,0,0,'8',0,0
	dc.b	0,'7',0,0,0,'8',0,0
	dc.b	0,$f,0,'0',0,'8',0,0
	dc.b	0,7,0,'8',0,'8',0,0
	dc.b	0,$f,0,'0',0,'8',0,0
	dc.b	0,'?',0,0,0,'8',0,0
	dc.b	0,$f,0,0,0,'8',0,0
	dc.b	0,$1f,0,0,0,'8',0,0
	dc.b	0,'7',0,0,0,'8',0,0
	dc.b	0,'(',0,$f,0,'0',0,0
	dc.b	0,$e,0,$1f,0,'?',0,0
	dc.b	0,$f,0,0,0,'8',0,0
	dc.b	0,'7',0,0,0,'8',0,0
	dc.b	0,'?',0,0,0,'8',0,0
	dc.b	0,7,0,'8',0,'8',0,0
	dc.b	0,$f,0,'0',0,'8',0,0
	dc.b	0,$17,0,'/',0,'0',0,0
	dc.b	0,',',0,$1c,0,'#',0,0
	dc.b	0,$18,0,'8',0,7,0,0
	dc.b	'H',0,'8',0,$f0,0,0,0
	dc.b	$d0,0,'8',0,$e0,0,0,0
	dc.b	$a0,0,'x',0,$c0,0,0,0
	dc.b	$c0,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$d8,0,'8',0,0,0,0,0
	dc.b	$f0,0,'0',0,8,0,0,0
	dc.b	$e0,0,' ',0,$18,0,0,0
	dc.b	$e0,0,' ',0,$18,0,0,0
	dc.b	$e0,0,' ',0,$18,0,0,0
	dc.b	$f0,0,'0',0,8,0,0,0
	dc.b	$d8,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$c0,0,'8',0,0,0,0,0
	dc.b	$c0,0,'8',0,0,0,0,0
	dc.b	'`',0,$f8,0,0,0,0,0
	dc.b	$c0,0,'(',0,$f0,0,0,0
	dc.b	$c0,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$f8,0,'8',0,0,0,0,0
	dc.b	$f8,0,'8',0,0,0,0,0
	dc.b	$d8,0,$18,0,' ',0,0,0
	dc.b	$88,0,$e8,0,$10,0,0,0
	dc.b	$c0,0,$f0,0,8,0,0,0
	dc.b	'`',0,'x',0,$80,0,0,0
	dc.b	'r',$13,$fc,$f,$ff,$ff,0,0
	dc.b	';3|',$f,$ff,$ff,0,0
	dc.b	$1d,$f4,'>',$f,$ff,$ff,0,0
	dc.b	$9f,$ff,$80,0,'`',0,0,0
	dc.b	$df,$ff,$c0,0,' ',0,0,0
	dc.b	$ff,$ff,$e0,0,0,0,0,0
	dc.b	$9f,$ff,$80,0,'`',0,0,0
	dc.b	'?',$ff,0,0,$e0,0,0,0
	dc.b	$c3,$f,$1f,$f,$e0,$f0,0,0
	dc.b	$8c,$16,'<',$11,$c3,$ef,0,0
	dc.b	$11,$e5,'q',$ee,$8e,$1e,0,0
	dc.b	0,$13,0,$c,0,'<',0,0
	dc.b	0,$1f,0,0,0,'8',0,0
	dc.b	0,$1f,0,0,0,'8',0,0
	dc.b	0,'7',0,0,0,'8',0,0
	dc.b	0,'(',0,$f,0,'0',0,0
	dc.b	0,$e,0,$1f,0,'?',0,0
	dc.b	0,$f,0,0,0,'8',0,0
	dc.b	0,'7',0,0,0,'8',0,0
	dc.b	0,'?',0,0,0,'8',0,0
	dc.b	0,7,0,'8',0,'8',0,0
	dc.b	0,$f,0,'0',0,'8',0,0
	dc.b	0,$17,0,'/',0,'0',0,0
	dc.b	0,',',0,$1c,0,'#',0,0
	dc.b	0,$18,0,'8',0,7,0,0
	dc.b	$9c,$c0,$e0,' ',$ff,$e0,0,0
	dc.b	's',$98,$80,'`',$ff,$f8,0,0
	dc.b	'w0',$80,$c0,$ff,$fc,0,0
	dc.b	$ff,$ec,0,$c,0,'0',0,0
	dc.b	$ff,$fe,0,$1e,0,0,0,0
	dc.b	$ff,$f8,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$83,$f0,$fe,$e,0,0,0,0
	dc.b	'+',$f0,$dc,$e,$fe,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f0,0,$e,0,0,0,0
	dc.b	$ff,$f8,0,$e,0,0,0,0
	dc.b	$ff,$fe,0,$1e,0,0,0,0
	dc.b	$ff,$e4,0,'&',0,$18,0,0
	dc.b	'`4',$ff,$f4,0,8,0,0
	dc.b	$c6,$18,'/',$fc,$f0,0,0,0
	dc.b	$c3,$80,';',$f0,4,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$f8,0,'8',0,0,0,0,0
	dc.b	$f8,0,'8',0,0,0,0,0
	dc.b	$d8,0,$18,0,' ',0,0,0
	dc.b	$88,0,$e8,0,$10,0,0,0
	dc.b	$c0,0,$f0,0,8,0,0,0
	dc.b	'`',0,'x',0,$80,0,0,0
	dcb.w	16
	dc.b	5,$12,$e,$e,$f,$fc,0,0
	dc.b	2,$b4,7,$e,$f,$f8,0,0
	dc.b	0,$a8,3,$1e,$f,$f0,0,0
	dc.b	9,$f0,8,$e,6,0,0,0
	dc.b	$f,$f2,$e,$e,0,0,0,0
	dc.b	$f,$f6,$e,$e,0,0,0,0
	dc.b	1,$f6,0,$e,$e,0,0,0
	dc.b	$d,$f2,0,$e,$e,0,0,0
	dc.b	$a,$18,3,$fe,$c,0,0,0
	dc.b	3,$b0,7,$ca,$f,$fc,0,0
	dc.b	3,$f0,0,$e,$e,0,0,0
	dc.b	$d,$f2,0,$e,$e,0,0,0
	dc.b	$f,$fe,0,$e,$e,0,0,0
	dc.b	1,$fe,$e,$e,$e,0,0,0
	dc.b	3,$f6,$c,6,$e,8,0,0
	dc.b	5,$e2,$b,$fa,$c,4,0,0
	dc.b	$b,'0',7,'<',8,$c2,0,0
	dc.b	6,$18,$e,$1e,1,$e0,0,0
	dcb.w	128
	dc.b	5,$12,$e,$e,$f,$fc,0,0
	dc.b	2,$b4,7,$e,$f,$f8,0,0
	dc.b	0,$a8,3,$1e,$f,$f0,0,0
	dc.b	9,$f0,8,$e,6,0,0,0
	dc.b	$f,$f2,$e,$e,0,0,0,0
	dc.b	$f,$f6,$e,$e,0,0,0,0
	dc.b	1,$f6,0,$e,$e,0,0,0
	dc.b	$d,$f2,0,$e,$e,0,0,0
	dc.b	$a,$18,3,$fe,$c,0,0,0
	dc.b	3,$b0,7,$ca,$f,$fc,0,0
	dc.b	3,$f0,0,$e,$e,0,0,0
	dc.b	$d,$f2,0,$e,$e,0,0,0
	dc.b	$f,$f6,0,$e,$e,0,0,0
	dc.b	1,$fe,$e,$e,$e,0,0,0
	dc.b	3,$fe,$c,$e,$e,0,0,0
	dc.b	5,$f6,$b,$8e,$c,0,0,0
	dc.b	$a,$f2,6,$1e,9,0,0,0
	dc.b	5,$f8,$c,'>',2,0,0,0
	dc.b	9,$d8,$b,$fc,4,0,0,0
	dc.b	2,'`',6,'x',9,$80,0,0
	dc.b	4,' ',$c,'0',3,$c0,0,0
	dcb.w	100
	dc.b	3,$8e,6,1,1,$ff,0,0
	dc.b	$b,$cc,$1e,3,7,$ff,0,0
	dc.b	$16,$dc,'?',3,$f,$ff,0,0
	dc.b	'&',$ff,'?',0,$1f,0,0,0
	dc.b	$13,$ff,'|',0,'<',0,0,0
	dc.b	'_',$ff,'x',0,'8',0,0,0
	dc.b	'g',$ff,$18,0,'x',0,0,0
	dc.b	'?',$ff,0,0,'p',0,0,0
	dc.b	'?',$c0,0,'?p',0,0,0
	dc.b	$1f,$80,0,$7f,'p',0,0,0
	dc.b	$1f,$83,0,$7f,'p',0,0,0
	dc.b	'O',$80,0,'pp',0,0,0
	dc.b	'/',$80,'@pp',0,0,0
	dc.b	$1f,$b0,'`pp',0,0,0
	dc.b	'o',$ea,'pgp',$1f,0,0
	dc.b	$7f,$d7,'pOp?',0,0
	dc.b	'o',$ff,'p',$f,'p?',0,0
	dc.b	$f,$ff,'p',0,'p',0,0,0
	dc.b	'_',$ff,' ',0,'x',0,0,0
	dc.b	'w',$ff,'@',0,'8',0,0,0
	dc.b	$27,$ff,'@',0,'<',0,0,0
	dc.b	')',$ff,'&',0,$1f,0,0,0
	dc.b	$12,'q<',$7f,$f,$80,0,0
	dc.b	$c,$9f,$18,$df,7,' ',0,0
	dc.b	1,'N',3,$ce,0,'1',0,0
	dc.b	'r',$80,$fc,$c0,$ff,0,0,0
	dc.b	'c`',$fc,$b0,$ff,$c0,0,0
	dc.b	'g',$d0,$f8,$f0,$ff,$e0,0,0
	dc.b	$fe,$b0,1,$c8,1,$f0,0,0
	dc.b	$ff,$e8,0,8,0,'p',0,0
	dc.b	$ff,$d8,0,$18,0,' ',0,0
	dc.b	$ff,$f0,0,'<',0,0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	$1f,$e4,$f8,$1c,0,0,0,0
	dc.b	$f3,$ec,$f4,$1c,$c,0,0,0
	dc.b	7,$f0,$c,$10,$fc,$c,0,0
	dc.b	$f,$f0,$1c,$10,$1c,$c,0,0
	dc.b	$f,$f0,$1c,$10,$1c,$c,0,0
	dc.b	$17,$f0,$c,$10,$1c,$c,0,0
	dc.b	'[',$f4,$84,$14,$fc,8,0,0
	dc.b	'k',$ec,$84,$1c,$fc,0,0,0
	dc.b	7,$e8,$e0,$1c,$f8,0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	$ff,$c0,0,'<',0,0,0,0
	dc.b	$ff,$e0,0,'8',0,0,0,0
	dc.b	$ff,$b0,0,'8',0,'@',0,0
	dc.b	$ff,$90,1,$98,0,'`',0,0
	dc.b	$e1,$c0,$ff,$d0,0,' ',0,0
	dc.b	'1',$c0,'?',$e0,$c0,0,0,0
	dc.b	$18,0,$1f,$80,$e0,0,0,0
	dc.b	1,$c5,3,$f9,3,$fe,0,0
	dc.b	0,$e6,1,$f9,3,$ff,0,0
	dc.b	0,'o',0,$f1,3,$ff,0,0
	dc.b	2,'}',2,3,1,$83,0,0
	dc.b	3,$7f,3,0,0,$80,0,0
	dc.b	3,$ff,3,$80,0,0,0,0
	dc.b	2,$7f,2,0,1,$80,0,0
	dc.b	0,$ff,0,0,3,$80,0,0
	dc.b	3,$1f,0,'p',3,$80,0,0
	dc.b	2,$27,0,$e8,3,$18,0,0
	dc.b	0,'W',1,$c8,2,'8',0,0
	dc.b	0,'/',0,$18,0,'8',0,0
	dc.b	0,$1f,0,'8',0,'8',0,0
	dc.b	0,'?',0,'8',0,'8',0,0
	dc.b	0,'7',0,'8',0,'8',0,0
	dc.b	0,$27,0,'8',0,'8',0,0
	dc.b	0,7,0,'8',0,'8',0,0
	dc.b	0,7,0,'8',0,'8',0,0
	dc.b	0,7,0,'8',0,'8',0,0
	dc.b	0,'/',0,$10,0,'8',0,0
	dc.b	0,'?',0,0,0,'8',0,0
	dc.b	0,'?',0,0,0,'8',0,0
	dc.b	0,'7',0,$f,0,'0',0,0
	dc.b	0,',',0,$1c,0,'#',0,0
	dc.b	0,$18,0,'8',0,7,0,0
	dc.b	0,0,$80,0,0,0,0,0
	dc.b	$c0,0,'`',0,$80,0,0,0
	dc.b	$a0,0,$e0,0,$c0,0,0,0
	dc.b	'`',0,$90,0,$e0,0,0,0
	dc.b	$d0,0,$10,0,$e0,0,0,0
	dc.b	$b0,0,'0',0,'@',0,0,0
	dc.b	$e0,0,'x',0,0,0,0,0
	dc.b	$c0,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$d8,0,'8',0,0,0,0,0
	dc.b	$e0,0,' ',0,$18,0,0,0
	dc.b	$e0,0,' ',0,$18,0,0,0
	dc.b	$e0,0,' ',0,$18,0,0,0
	dc.b	$f0,0,'0',0,8,0,0,0
	dc.b	$f0,0,'0',0,8,0,0,0
	dc.b	$d8,0,'8',0,0,0,0,0
	dc.b	$d8,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$c0,0,'8',0,0,0,0,0
	dc.b	$c0,0,'8',0,0,0,0,0
	dc.b	$80,0,$f8,0,0,0,0,0
	dc.b	$c0,0,$f8,0,0,0,0,0
	dc.b	'`',0,'x',0,$80,0,0,0
	dc.b	'9',7,'~',$f,$7f,$ff,0,0
	dc.b	$1d,$96,'>',$f,$7f,$ff,0,0
	dc.b	$e,$f8,$1f,$f,$7f,$ff,0,0
	dc.b	'O',$ff,'@',0,'0',0,0,0
	dc.b	'o',$ff,'`',0,$10,0,0,0
	dc.b	$7f,$ff,'p',0,0,0,0,0
	dc.b	'O',$ff,'@',0,'0',0,0,0
	dc.b	$f,$ff,0,0,'p',0,0,0
	dc.b	'p',0,$7f,$ff,0,0,0,0
	dc.b	$16,$1a,'0|',$f,$ff,0,0
	dc.b	$13,$ff,'\',0,'<',0,0,0
	dc.b	'_',$ff,'x',0,'8',0,0,0
	dc.b	'O',$ff,'0',0,'p',0,0,0
	dc.b	$7f,$ff,0,0,'p',0,0,0
	dc.b	'?',$ff,0,0,'p',0,0,0
	dc.b	$f,$ff,0,$7f,'p',0,0,0
	dc.b	$1f,$c6,0,'8p',$7f,0,0
	dc.b	'?',$ff,0,0,'p',0,0,0
	dc.b	'o',$ff,$10,0,'p',0,0,0
	dc.b	'O',$ff,'0',0,'p',0,0,0
	dc.b	$1f,$ff,'p',0,'p',0,0,0
	dc.b	'/',$ff,'p',0,'p',0,0,0
	dc.b	'C3o',$f0,'p',$f,0,0
	dc.b	7,$d9,'_',$f8,'`',7,0,0
	dc.b	8,$c8,'8',$f8,'G',7,0,0
	dc.b	'9',$80,$c0,' ',$ff,$c0,0,0
	dc.b	$e7,'0',0,$d8,$ff,$e0,0,0
	dc.b	$ee,'h',1,$88,$ff,$f0,0,0
	dc.b	$ff,$d8,0,$1c,0,'`',0,0
	dc.b	$ff,$fc,0,'<',0,0,0,0
	dc.b	$ff,$f0,0,$1c,0,0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	$ff,$e4,0,$1c,0,0,0,0
	dc.b	7,$ec,$fc,$1c,0,0,0,0
	dc.b	$d7,$ec,'8',$1c,$fc,0,0,0
	dc.b	$ff,$e4,0,$1c,0,0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	$ff,$f0,0,$1c,0,0,0,0
	dc.b	$ff,$f8,0,'<',0,0,0,0
	dc.b	$ff,$c0,0,'H',0,'0',0,0
	dc.b	0,$e0,$ff,$e4,0,$18,0,0
	dc.b	4,$84,3,$ec,$ff,$f0,0,0
	dc.b	$ff,$e8,0,$18,0,4,0,0
	dc.b	$ff,$f8,0,$18,0,4,0,0
	dc.b	$ff,$f8,0,$18,0,4,0,0
	dc.b	$ff,$ec,0,$1c,0,0,0,0
	dc.b	$ff,$e4,0,$1c,0,0,0,0
	dc.b	$cc,'p',$c,$1c,$f3,$e0,0,0
	dc.b	'?8?',$c,$c0,$f0,0,0
	dc.b	'a',$9c,$7f,$84,$80,'x',0,0
	dc.b	'9',9,'~',7,$7f,$ff,0,0
	dc.b	$1d,$99,'>',7,$7f,$ff,0,0
	dc.b	$e,$fa,$1f,7,$7f,$ff,0,0
	dc.b	'O',$ff,'@',0,'0',0,0,0
	dc.b	'o',$ff,'`',0,$10,0,0,0
	dc.b	$7f,$ff,'p',0,0,0,0,0
	dc.b	'O',$ff,'@',0,'0',0,0,0
	dc.b	$f,$ff,0,0,'p',0,0,0
	dc.b	'p',$1f,$7f,$ff,0,0,0,0
	dc.b	's',$c6,'0?O',$ff,0,0
	dc.b	'o',$ff,0,0,'p',0,0,0
	dc.b	$1f,$ff,'`',0,'p',0,0,0
	dc.b	'o',$ff,'p',0,'p',0,0,0
	dc.b	$1f,$ff,'`',0,'p',0,0,0
	dc.b	'o',$ff,0,0,'p',0,0,0
	dc.b	'>`>',$7f,'A',$80,0,0
	dc.b	'h',$cc,$1f,3,$7f,$ff,0,0
	dc.b	$7f,$ff,0,0,'p',0,0,0
	dc.b	$1f,$ff,'`',0,'p',0,0,0
	dc.b	'O',$ff,'p',0,'p',0,0,0
	dc.b	$7f,$ff,'p',0,'p',0,0,0
	dc.b	'o',$ff,'p',0,'p',0,0,0
	dc.b	'T',$dc,'|',$fc,'c',3,0,0
	dc.b	')',$86,'y',$fe,'F',1,0,0
	dc.b	'S',2,'s',$fe,$c,1,0,0
	dc.b	$ce,$80,$f0,$c0,$ff,0,0,0
	dc.b	$bb,'`',$c0,$b0,$ff,$c0,0,0
	dc.b	'#',$d0,$c0,$f0,$ff,$e0,0,0
	dc.b	$fe,$b0,1,$c8,1,$f0,0,0
	dc.b	$ff,$e8,0,8,0,'p',0,0
	dc.b	$ff,$d8,0,$18,0,' ',0,0
	dc.b	$ff,$f0,0,'<',0,0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	$e7,$e4,$f8,$1c,0,0,0,0
	dc.b	$b3,$ec,8,$1c,$fc,0,0,0
	dc.b	$ff,$f0,0,$10,0,$c,0,0
	dc.b	$ff,$f0,0,$10,0,$c,0,0
	dc.b	$ff,$f0,0,$10,0,$c,0,0
	dc.b	$ff,$f0,0,$10,0,$c,0,0
	dc.b	$ff,$f4,0,$14,0,8,0,0
	dc.b	$f,$ec,$fc,$1c,0,0,0,0
	dc.b	$db,$e8,$e0,$1c,$fc,0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	$ff,$c0,0,'<',0,0,0,0
	dc.b	$ff,$e0,0,'8',0,0,0,0
	dc.b	$ff,$b0,0,'8',0,'@',0,0
	dc.b	$ff,$90,1,$98,0,'`',0,0
	dc.b	$f3,$c0,3,$d0,$fc,' ',0,0
	dc.b	'M',$c0,$f,$e0,$f0,0,0,0
	dc.b	$18,0,$1f,$80,$e0,0,0,0
	dc.b	'7',$90,'x',$10,$7f,$e0,0,0
	dc.b	'[ <0',$7f,$c0,0,0
	dc.b	'j@',$1c,'p',$7f,$80,0,0
	dc.b	'?',$80,'@pp',0,0,0
	dc.b	$1f,$80,'`pp',0,0,0
	dc.b	'O',$80,'ppp',0,0,0
	dc.b	$1f,$b0,'`pp',0,0,0
	dc.b	'o',$e4,'pcp',$1f,0,0
	dc.b	$7f,$cc,'pCp?',0,0
	dc.b	'o',$de,'p',1,'p?',0,0
	dc.b	$f,$ff,'p',0,'p',0,0,0
	dc.b	'_',$ff,' ',0,'x',0,0,0
	dc.b	'w',$ff,'@',0,'8',0,0,0
	dc.b	$27,$ff,'@',0,'<',0,0,0
	dc.b	')',$ff,'&',0,$1f,0,0,0
	dc.b	$12,'F<~',$f,$81,0,0
	dc.b	$c,$98,$18,$f8,7,7,0,0
	dc.b	1,$f1,3,$f1,0,$e,0,0
	dcb.w	28
	dc.b	$d,$e4,$1e,4,$1f,$f8,0,0
	dc.b	$16,$c8,$f,$c,$1f,$f0,0,0
	dc.b	$1a,$90,7,$1c,$1f,$e0,0,0
	dc.b	$f,$e0,$10,$1c,$1c,0,0,0
	dc.b	7,$e0,$18,$1c,$1c,0,0,0
	dc.b	$13,$e0,$1c,$1c,$1c,0,0,0
	dc.b	$1f,$e4,$1c,$1c,$1c,0,0,0
	dc.b	'O',$ec,$8c,$1c,$fc,0,0,0
	dc.b	'g',$fc,$84,$1c,$fc,0,0,0
	dc.b	's',$f4,$80,$14,$fc,8,0,0
	dc.b	$ff,$e0,0,0,0,$1c,0,0
	dc.b	$ff,$e8,0,0,0,$1c,0,0
	dc.b	$ff,$e8,0,0,0,$1c,0,0
	dc.b	$ff,$e0,0,0,0,$1c,0,0
	dc.b	$ff,$f4,0,$14,0,8,0,0
	dc.b	7,$fc,4,$1c,$f8,0,0,0
	dc.b	$1f,$ec,$18,$1c,$e4,0,0,0
	dc.b	'{',$e4,'t',$1c,$8c,0,0,0
	dc.b	$17,$e4,$c,$1c,$1c,0,0,0
	dc.b	$1f,$e0,$1c,$1c,$1c,0,0,0
	dc.b	$1b,$e0,$1c,$1c,$1c,0,0,0
	dc.b	$17,$e0,$18,$1c,$1c,0,0,0
	dc.b	$f,$c0,$17,$dc,$18,' ',0,0
	dc.b	$18,$e0,$f,$ec,$10,$10,0,0
	dc.b	$10,'`',$1f,$e4,0,$18,0,0
	dc.b	'{',$9e,7,$e3,$7f,$ff,0,0
	dc.b	'yžG',$e3,'?',$ff,0,0
	dc.b	'}',$1f,'c',$e3,$1f,$ff,0,0
	dc.b	'?',$ff,'0',0,'@',0,0,0
	dc.b	$1f,$ff,$10,0,'`',0,0,0
	dc.b	'O',$ff,0,0,'p',0,0,0
	dc.b	$7f,$ff,0,0,'p',0,0,0
	dc.b	$1f,$ff,'`',0,'p',0,0,0
	dc.b	'o',$a0,'p?p@',0,0
	dc.b	$7f,$ed,'p',$1e,'p',$7f,0,0
	dc.b	'o',$ff,'p',0,'p',0,0,0
	dc.b	'_',$ff,'`',0,'p',0,0,0
	dc.b	'?',$ff,'@',0,'p',0,0,0
	dc.b	'O',$ff,0,0,'p',0,0,0
	dc.b	$f,$ff,0,0,'p',0,0,0
	dc.b	'p ',$7f,$ff,0,0,0,0
	dc.b	's',$c9,'0',7,'O',$ff,0,0
	dc.b	'o',$ff,0,0,'p',0,0,0
	dc.b	$1f,$ff,'`',0,'p',0,0,0
	dc.b	$f,$ff,'p',0,'p',0,0,0
	dc.b	'?',$ff,'p',0,'p',0,0,0
	dc.b	'o',$ff,'p',0,'p',0,0,0
	dc.b	'T',$d9,'|',$f8,'c',7,0,0
	dc.b	')',$8d,'y',$fc,'F',3,0,0
	dc.b	'S',4,'s',$fc,$c,3,0,0
	dc.b	$cc,$e4,3,$fc,$ff,$f8,0,0
	dc.b	'M',$c8,$83,$fc,$ff,$f0,0,0
	dc.b	'[',$90,$87,$fc,$ff,$e0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	$ff,$ec,0,$1c,0,0,0,0
	dc.b	$ff,$f0,0,$10,0,$c,0,0
	dc.b	$ff,$e0,0,0,0,$1c,0,0
	dc.b	$ff,$fc,0,$1c,0,0,0,0
	dc.b	'x',$c,$ff,$ec,0,$10,0,0
	dc.b	$c1,$c4,0,'4',$ff,$f8,0,0
	dc.b	$ff,$b0,0,'|',0,'x',0,0
	dc.b	$ff,$e8,0,'0',0,'<',0,0
	dc.b	$ff,$f8,0,0,0,$1c,0,0
	dc.b	$ff,$e4,0,4,0,$18,0,0
	dc.b	$ff,$fc,0,$1c,0,0,0,0
	dc.b	';',$e0,$f8,$1c,4,0,0,0
	dc.b	'c',$e0,$80,$1c,$fc,0,0,0
	dc.b	$ff,$f0,0,$1c,0,0,0,0
	dc.b	$ff,$f8,0,$1c,0,0,0,0
	dc.b	$ff,$fc,0,$1c,0,0,0,0
	dc.b	$ff,$cc,0,$c,0,'0',0,0
	dc.b	$ff,$a4,0,4,0,'x',0,0
	dc.b	$cc,'x',$c,$c,$f3,$f0,0,0
	dc.b	'? ?',8,$c0,$f0,0,0
	dc.b	'a',$a0,$7f,$b0,$80,'@',0,0
	dc.b	$c,'v',$18,$f,7,$ff,0,0
	dc.b	'&28',$f,$1f,$ff,0,0
	dc.b	$1a,$1b,'|',7,'?',$ff,0,0
	dc.b	'[',$ff,'|',0,'<',0,0,0
	dc.b	'g',$ff,$18,0,'x',0,0,0
	dc.b	$7f,$ff,0,0,'p',0,0,0
	dc.b	$7f,$ff,0,0,'p',0,0,0
	dc.b	'?',$ff,'@',0,'p',0,0,0
	dc.b	$f,$a0,'p?p@',0,0
	dc.b	'o',$ed,'p',$1e,'p',$7f,0,0
	dc.b	'o',$ff,'p',0,'p',0,0,0
	dc.b	'_',$ff,'`',0,'p',0,0,0
	dc.b	'?',$ff,'@',0,'p',0,0,0
	dc.b	'O',$ff,0,0,'p',0,0,0
	dc.b	$f,$ff,0,0,'p',0,0,0
	dc.b	$7f,$a0,'p',$7f,0,0,0,0
	dc.b	$1f,$c9,$10,7,'`',$7f,0,0
	dc.b	'O',$ff,0,0,'p',0,0,0
	dc.b	$7f,$ff,0,0,'p',0,0,0
	dc.b	$f,$ff,'p',0,'p',0,0,0
	dc.b	$17,$ff,'x',0,'x',0,0,0
	dc.b	'3',$ff,'<',0,'|',0,0,0
	dc.b	4,$d9,'x',$f8,'?',7,0,0
	dc.b	'9',$8d,'!',$fc,$1e,3,0,0
	dc.b	$b,4,$1b,$fc,4,3,0,0
	dc.b	$cc,$e4,3,$fc,$ff,$f8,0,0
	dc.b	'M',$c8,$83,$fc,$ff,$f0,0,0
	dc.b	'[',$90,$87,$fc,$ff,$e0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	$ff,$ec,0,$1c,0,0,0,0
	dc.b	$ff,$f0,0,$10,0,$c,0,0
	dc.b	$ff,$e0,0,0,0,$1c,0,0
	dc.b	$ff,$fc,0,$1c,0,0,0,0
	dc.b	'x',$c,$ff,$ec,0,$10,0,0
	dc.b	$c1,$c4,0,'4',$ff,$f8,0,0
	dc.b	$ff,$b0,0,'|',0,'x',0,0
	dc.b	$ff,$e8,0,'0',0,'<',0,0
	dc.b	$ff,$f8,0,0,0,$1c,0,0
	dc.b	$ff,$e4,0,4,0,$18,0,0
	dc.b	$ff,$fc,0,$1c,0,0,0,0
	dc.b	';',$e0,$f8,$1c,4,0,0,0
	dc.b	'c',$e0,$80,$1c,$fc,0,0,0
	dc.b	$ff,$f0,0,$1c,0,0,0,0
	dc.b	$ff,$f8,0,$1c,0,0,0,0
	dc.b	$ff,$fc,0,$1c,0,0,0,0
	dc.b	$ff,$cc,0,$c,0,'0',0,0
	dc.b	$ff,$a4,0,4,0,'x',0,0
	dc.b	$cc,'x',$c,$c,$f3,$f0,0,0
	dc.b	'? ?',8,$c0,$f0,0,0
	dc.b	'a',$a0,$7f,$b0,$80,'@',0,0
	dc.b	':',6,'|',1,$7f,$ff,0,0
	dc.b	$1b,$c,'<',3,$7f,$ff,0,0
	dc.b	$d,$f8,$1e,7,$7f,$ff,0,0
	dc.b	'O',$ff,'@',0,'0',0,0,0
	dc.b	'o',$ff,'`',0,$10,0,0,0
	dc.b	$7f,$ff,'p',0,0,0,0,0
	dc.b	'O',$ff,'@',0,'0',0,0,0
	dc.b	$1f,$ff,0,0,'p',0,0,0
	dc.b	'a',$f8,$f,$ff,'p',0,0,0
	dc.b	'G',$1c,$1f,$1f,'`',$e0,0,0
	dc.b	$c,$e,'<',$f,'C',$f0,0,0
	dcb.w	56
	dc.b	'"',$80,$fc,$c0,$ff,0,0,0
	dc.b	's`',$fc,$b0,$ff,$c0,0,0
	dc.b	$f7,$d0,$f8,$f0,$ff,$e0,0,0
	dc.b	$fe,$b0,1,$c8,1,$f0,0,0
	dc.b	$ff,$e8,0,8,0,'p',0,0
	dc.b	$ff,$d8,0,$1c,0,' ',0,0
	dc.b	$ff,$f8,0,'<',0,0,0,0
	dc.b	$ff,$fc,0,$1c,0,0,0,0
	dc.b	7,$f8,$f0,$18,8,4,0,0
	dc.b	$1b,$f0,$f4,$10,$c,$c,0,0
	dc.b	'+',$f0,$e4,$10,$1c,$c,0,0
	dc.b	$17,$f0,$c,$10,$1c,$c,0,0
	dc.b	$f,$f0,$1c,$10,$1c,$c,0,0
	dc.b	$1f,$f8,$1c,$18,$1c,4,0,0
	dc.b	$1b,$f8,$1c,$18,$1c,4,0,0
	dc.b	$13,$ec,$1c,$1c,$1c,0,0,0
	dc.b	3,$ec,$1c,$1c,$1c,0,0,0
	dc.b	3,$e4,$1c,$1c,$1c,0,0,0
	dc.b	3,$e4,$1c,$1c,$1c,0,0,0
	dc.b	$17,$e4,8,$1c,$1c,0,0,0
	dc.b	$1f,$e0,0,$1c,$1c,0,0,0
	dc.b	$1f,$e0,0,$1c,$1c,0,0,0
	dc.b	$1b,$c0,7,$fc,$18,0,0,0
	dc.b	$16,'`',$e,'|',$11,$80,0,0
	dc.b	$c,'0',$1c,'<',3,$c0,0,0
	dc.b	$c,'6',$18,$f,7,$ff,0,0
	dc.b	'&:8',7,$1f,$ff,0,0
	dc.b	$1a,$1d,'|',3,'?',$ff,0,0
	dc.b	'[',$ff,'|',0,'<',0,0,0
	dc.b	'g',$ff,$18,0,'x',0,0,0
	dc.b	'?',$ff,0,0,'p',0,0,0
	dc.b	$1f,$ff,0,0,'p',0,0,0
	dc.b	'O',$ff,'@',0,'0',0,0,0
	dc.b	'o',$a0,'`?',$10,'@',0,0
	dc.b	'O',$e7,'@',$1e,'0',$7f,0,0
	dc.b	$1f,$ff,0,0,'p',0,0,0
	dc.b	'w',$ff,'@',0,'8',0,0,0
	dc.b	$1f,$ff,0,0,'<',0,0,0
	dc.b	'_',$ff,'x',0,'8',0,0,0
	dc.b	$f,$ff,'0',0,'p',0,0,0
	dc.b	$7f,$a0,0,$7f,'p',0,0,0
	dc.b	$1f,$c8,0,7,'p',$7f,0,0
	dc.b	'O',$ff,0,0,'p',0,0,0
	dc.b	$7f,$ff,0,0,'p',0,0,0
	dc.b	$f,$ff,'p',0,'p',0,0,0
	dc.b	$17,$ff,'x',0,'x',0,0,0
	dc.b	'3',$ff,'<',0,'|',0,0,0
	dc.b	4,$dd,'x',$fd,'?',2,0,0
	dc.b	'9',$8c,'!',$fc,$1e,3,0,0
	dc.b	$b,$c,$1b,$fc,4,3,0,0
	dc.b	$b9,$80,'@ ',$ff,$c0,0,0
	dc.b	'g0',$80,$d8,$ff,$e0,0,0
	dc.b	'nh',$81,$88,$ff,$f0,0,0
	dc.b	$ff,$d8,0,$1c,0,'`',0,0
	dc.b	$ff,$fc,0,'<',0,0,0,0
	dc.b	$ff,$f0,0,$1c,0,0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	7,$e0,$fc,$1c,0,0,0,0
	dc.b	$d7,$e0,'8',$1c,$fc,0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	$ff,$c0,0,'<',0,0,0,0
	dc.b	$ff,$98,0,'x',0,0,0,0
	dc.b	$ff,$cc,0,$c,0,'0',0,0
	dc.b	$ff,$f8,0,$1c,0,0,0,0
	dc.b	3,$e0,$fc,$1c,0,0,0,0
	dc.b	's',$e0,$8c,$1c,$fc,0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	$ff,$f0,0,$1c,0,0,0,0
	dc.b	$ff,$fc,0,'<',0,0,0,0
	dc.b	$ff,$c8,0,'L',0,'0',0,0
	dc.b	$c0,'h',$ff,$e8,0,$10,0,0
	dc.b	'x0',$7f,$f8,$80,0,0,0
	dc.b	$f,0,$f,$e0,$f0,0,0,0
	dc.b	$c,'6',$18,$f,7,$ff,0,0
	dc.b	'&:8',7,$1f,$ff,0,0
	dc.b	$1a,$1d,'|',3,'?',$ff,0,0
	dc.b	'[',$ff,'|',0,'<',0,0,0
	dc.b	'g',$ff,$18,0,'x',0,0,0
	dc.b	'?',$ff,0,0,'p',0,0,0
	dc.b	$1f,$ff,0,0,'p',0,0,0
	dc.b	'O',$ff,'@',0,'0',0,0,0
	dc.b	'o',$a0,'`?',$10,'@',0,0
	dc.b	'O',$e7,'@',$1e,'0',$7f,0,0
	dc.b	$1f,$ff,0,0,'p',0,0,0
	dc.b	$7f,$ff,0,0,'p',0,0,0
	dc.b	$f,$ff,'p',0,'p',0,0,0
	dc.b	$17,$ff,'x',0,'x',0,0,0
	dc.b	'3',$ff,'<',0,'|',0,0,0
	dc.b	4,$f8,'x',$f8,'?',7,0,0
	dc.b	'9Ž!',$fe,$1e,1,0,0
	dc.b	$b,3,$1b,$ff,4,0,0,0
	dcb.w	28
	dc.b	$b9,$80,'@ ',$ff,$c0,0,0
	dc.b	'g0',$80,$d8,$ff,$e0,0,0
	dc.b	'nh',$81,$88,$ff,$f0,0,0
	dc.b	$ff,$d8,0,$1c,0,'`',0,0
	dc.b	$ff,$fc,0,'<',0,0,0,0
	dc.b	$ff,$f0,0,$1c,0,0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	$ff,$e0,0,$1c,0,0,0,0
	dc.b	7,$e4,$fc,$1c,0,0,0,0
	dc.b	$d7,$ec,'8',$1c,$fc,0,0,0
	dc.b	$ff,$fc,0,$1c,0,0,0,0
	dc.b	$ff,$f4,0,$14,0,8,0,0
	dc.b	$ff,$e0,0,0,0,$1c,0,0
	dc.b	$ff,$e8,0,0,0,$1c,0,0
	dc.b	$ff,$e8,0,0,0,$1c,0,0
	dc.b	7,$e0,4,0,$f8,$1c,0,0
	dc.b	$1f,$f4,$18,$14,$e4,8,0,0
	dc.b	'{',$fc,'t',$1c,$8c,0,0,0
	dc.b	$17,$ec,$c,$1c,$1c,0,0,0
	dc.b	$1f,$e4,$1c,$1c,$1c,0,0,0
	dc.b	$1b,$e4,$1c,$1c,$1c,0,0,0
	dc.b	$17,$e0,$18,$1c,$1c,0,0,0
	dc.b	$f,$c0,$17,$dc,$18,' ',0,0
	dc.b	$18,$e0,$f,$ec,$10,$10,0,0
	dc.b	$10,'`',$1f,$e4,0,$18,0,0
	dc.b	$b,$1f,$e,$f,$f,$fd,0,0
	dc.b	5,$bc,7,$e,$f,$f9,0,0
	dc.b	3,$b8,3,$1e,$f,$f1,0,0
	dc.b	9,$f1,8,$f,6,0,0,0
	dc.b	$f,$f3,$e,$f,0,0,0,0
	dc.b	$f,$f7,$e,$f,0,0,0,0
	dc.b	1,$f6,0,$e,$e,1,0,0
	dc.b	$d,$f7,0,$e,$e,1,0,0
	dc.b	$d,$f7,$b,$8f,$c,1,0,0
	dc.b	$a,$f3,6,$1e,9,1,0,0
	dc.b	5,$f8,$c,'?',2,0,0,0
	dc.b	9,$d9,$b,$fd,4,0,0,0
	dc.b	2,'`',6,'x',9,$81,0,0
	dc.b	4,' ',$c,'1',3,$c0,0,0
	dcb.w	44
	dc.b	'c',$c0,$c1,$c0,$ff,$80,0,0
	dc.b	$b7,$80,$e1,$c0,$ff,0,0,0
	dc.b	'w',0,'c',$c0,$fe,0,0,0
	dc.b	'>',0,1,$c0,$c0,0,0,0
	dc.b	$fe,'@',$c1,$c0,0,0,0,0
	dc.b	$fe,$c0,$c1,$c0,0,0,0,0
	dc.b	'>',$c0,1,$c0,$c0,0,0,0
	dc.b	$be,$c0,1,$c0,$c0,0,0,0
	dc.b	$be,$c0,'q',$c0,$80,0,0,0
	dc.b	'^@',$c3,$c0,' ',0,0,0
	dc.b	$bf,0,$87,$c0,'@',0,0,0
	dc.b	';',0,$7f,$80,$80,0,0,0
	dc.b	'L',0,$cf,0,'0',0,0,0
	dc.b	$84,0,$86,0,'x',0,0,0
	dcb.w	44
	dc.b	0,1,0,3,0,0,0,0
	dc.b	0,3,0,6,0,1,0,0
	dc.b	0,6,0,$c,0,3,0,0
	dc.b	0,$f,0,$c,0,7,0,0
	dc.b	0,$f,0,$16,0,$f,0,0
	dc.b	0,$13,0,$1e,0,$e,0,0
	dc.b	0,$19,0,$1e,0,$1e,0,0
	dc.b	0,$1f,0,',',0,$1c,0,0
	dc.b	0,'?',0,' ',0,$1c,0,0
	dc.b	0,$f,0,0,0,'<',0,0
	dc.b	0,7,0,0,0,'8',0,0
	dc.b	0,'?',0,'8',0,0,0,0
	dc.b	0,'7',0,'0',0,8,0,0
	dc.b	0,7,0,0,0,'8',0,0
	dc.b	0,$f,0,0,0,'8',0,0
	dc.b	0,'?',0,$c,0,'<',0,0
	dc.b	0,'3',0,'<',0,$1c,0,0
	dc.b	0,7,0,'<',0,$1c,0,0
	dc.b	0,$1f,0,8,0,$1e,0,0
	dc.b	0,$1d,0,$10,0,$e,0,0
	dc.b	0,0,0,$10,0,$f,0,0
	dc.b	0,9,0,8,0,7,0,0
	dc.b	0,7,0,$c,0,3,0,0
	dc.b	0,3,0,6,0,1,0,0
	dc.b	0,1,0,3,0,0,0,0
	dc.b	$fe,'@g',$80,$ff,$c0,0,0
	dc.b	'<',$80,'g@',$ff,$80,0,0
	dc.b	$18,0,'?',$c0,$fe,0,0,0
	dc.b	$7f,0,3,$c0,$80,0,0,0
	dc.b	$ff,0,7,$80,0,0,0,0
	dc.b	$fc,0,$d,0,2,0,0,0
	dc.b	$fa,0,$b,0,4,0,0,0
	dc.b	$f0,0,$12,0,$c,0,0,0
	dc.b	$f0,0,$10,0,$c,0,0,0
	dc.b	$f4,0,$14,0,8,0,0,0
	dc.b	$f8,0,'<',0,0,0,0,0
	dc.b	$f8,0,'8',0,0,0,0,0
	dc.b	$e8,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$d8,0,'<',0,0,0,0,0
	dc.b	$ec,0,$1c,0,0,0,0,0
	dc.b	$fc,0,$1e,0,0,0,0,0
	dc.b	$fa,0,$1a,0,4,0,0,0
	dc.b	$f0,0,1,0,$e,0,0,0
	dc.b	$f3,0,3,$80,$c,0,0,0
	dc.b	$ff,0,7,'@',0,$80,0,0
	dc.b	$fe,'@',2,'@',$81,$80,0,0
	dc.b	$e1,$80,'}',$c0,$c2,0,0,0
	dc.b	$c6,0,$fe,$c0,$81,0,0,0
	dc.b	$9c,0,$fc,'@',3,$80,0,0
	dc.b	9,$fe,7,$9f,$f,$fc,0,0
	dc.b	4,$f3,3,$9b,$f,$fc,0,0
	dc.b	8,'f',9,$f6,7,$f9,0,0
	dc.b	$c,$fc,$c,4,3,3,0,0
	dc.b	7,$fc,$c,0,3,$83,0,0
	dc.b	1,$ff,5,$80,3,$c1,0,0
	dc.b	0,$fe,2,0,1,$c1,0,0
	dc.b	1,$1f,1,0,0,$e0,0,0
	dc.b	0,$7f,1,'`',0,$80,0,0
	dc.b	0,$ff,0,$e0,0,0,0,0
	dc.b	0,$ef,0,$e0,0,$10,0,0
	dc.b	0,$f,0,$80,0,'p',0,0
	dc.b	0,$f,0,$80,0,'p',0,0
	dc.b	0,$ff,0,$80,0,'p',0,0
	dc.b	0,$7f,0,0,0,$f0,0,0
	dc.b	0,$ff,1,0,0,$e0,0,0
	dc.b	1,$ff,1,'`',0,$e0,0,0
	dc.b	0,$ff,2,'`',1,$e0,0,0
	dc.b	3,$ff,6,1,1,$c0,0,0
	dc.b	4,'~',$c,0,3,$c1,0,0
	dc.b	$e,'|',$e,0,1,$83,0,0
	dc.b	$b,$fc,3,4,$c,3,0,0
	dc.b	2,6,1,$fe,$e,1,0,0
	dc.b	$c,$f2,$f,$ff,0,0,0,0
	dc.b	9,$98,$f,$9e,0,'`',0,0
	dcb.w	5
	dc.b	$80,0,0,0,0,0,$80,0
	dc.b	$c0,0,0,0,0,0,'@',0
	dc.b	'@',0,$80,0,0,0,$80,0
	dc.b	' ',0,$c0,0,0,0,$e0,0
	dc.b	' ',0,$c0,0,0,0,$80,0
	dc.b	0,0,$e0,0,0,0,0,0
	dc.b	0,0,$e0,0,0,0,$80,0
	dc.b	$90,0,'`',0,0,0,$e0,0
	dc.b	$f0,0,0,0,0,0,$e0,0
	dc.b	'p',0,0,0,0,0,$80,0
	dc.b	'p',0,0,0,0,0,$80,0
	dc.b	'p',0,0,0,0,0,$80,0
	dc.b	'p',0,0,0,0,0,$80,0
	dc.b	'p',0,0,0,0,0,0,0
	dc.b	$f0,0,0,0,0,0,$80,0
	dc.b	$f0,0,0,0,0,0,$e0,0
	dc.b	$e0,0,0,0,0,0,$e0,0
	dc.b	$e0,0,0,0,0,0,$c0,0
	dc.b	$e0,0,0,0,0,0,'@',0
	dc.b	'@',0,$80,0,0,0,0,0
	dc.b	'@',0,$80,0,0,0,0,0
	dc.b	$80,0,0,0,0,0,0,0
	dcb.w	51
	dc.b	$b,$1e,$e,$e,$f,$fc,0,0
	dc.b	5,$bc,7,$e,$f,$f8,0,0
	dc.b	3,$b8,3,$1e,$f,$f0,0,0
	dc.b	9,$f0,8,$e,6,0,0,0
	dc.b	$f,$f2,$e,$e,0,0,0,0
	dc.b	$f,$f6,$e,$e,0,0,0,0
	dc.b	1,$f6,0,$e,$e,0,0,0
	dc.b	$d,$f6,0,$e,$e,0,0,0
	dc.b	$d,$f6,$b,$8e,$c,0,0,0
	dc.b	$a,$f2,6,$1e,9,0,0,0
	dc.b	5,$f8,$c,'>',2,0,0,0
	dc.b	9,$d8,$b,$fc,4,0,0,0
	dc.b	2,'`',6,'x',9,$80,0,0
	dc.b	4,' ',$c,'0',3,$c0,0,0
	dcb.w	128
	dc.b	'G',$e,'~',7,$7f,$ff,0,0
	dc.b	'#ž>',7,$7f,$ff,0,0
	dc.b	$11,$fd,$1f,7,$7f,$ff,0,0
	dc.b	'O',$ff,'@',0,'0',0,0,0
	dc.b	'o',$ff,'`',0,$10,0,0,0
	dc.b	$7f,$ff,'p',0,0,0,0,0
	dc.b	'O',$ff,'@',0,'0',0,0,0
	dc.b	$1f,$ff,0,0,'p',0,0,0
	dc.b	'a',$fc,$f,$fc,'p',3,0,0
	dc.b	'F',$c6,$1e,$fe,'a',1,0,0
	dc.b	8,$c2,'8',$fe,'G',1,0,0
	dcb.w	56
	dc.b	'}',$f8,$e0,'8',$ff,$fc,0,0
	dc.b	$f3,$f0,$80,$f4,$ff,$f8,0,0
	dc.b	$f7,$e4,$81,$ec,$ff,$f0,0,0
	dc.b	$ff,$e8,0,$18,0,4,0,0
	dc.b	$ff,$f8,0,$18,0,4,0,0
	dc.b	$ff,$f8,0,$18,0,4,0,0
	dc.b	$ff,$ec,0,$1c,0,0,0,0
	dc.b	$ff,$e4,0,$1c,0,0,0,0
	dc.b	$ec,'p',$c,$1c,$f3,$e0,0,0
	dc.b	$9f,'8',$1f,$c,$e0,$f0,0,0
	dc.b	'1',$9c,'?',$84,$c0,'x',0,0
	dcb.w	84
	dc.b	$b,$1e,$e,$e,$f,$fc,0,0
	dc.b	5,$bc,7,$e,$f,$f8,0,0
	dc.b	3,$b8,3,$1e,$f,$f0,0,0
	dc.b	9,$f0,8,$e,6,0,0,0
	dc.b	$f,$f2,$e,$e,0,0,0,0
	dc.b	$f,$f6,$e,$e,0,0,0,0
	dc.b	1,$f6,0,$e,$e,0,0,0
	dc.b	$d,$f2,0,$e,$e,0,0,0
	dc.b	$d,$e2,$b,$fa,$c,4,0,0
	dc.b	$b,'0',7,'<',8,$c2,0,0
	dc.b	6,$18,$e,$1e,1,$e0,0,0
	dcb.w	100
	dc.b	0,',',0,'8',0,'?',0,0
	dc.b	0,$16,0,$1c,0,'?',0,0
	dc.b	0,$e,0,$c,0,'?',0,0
	dc.b	0,$27,0,' ',0,$18,0,0
	dc.b	0,'?',0,'8',0,0,0,0
	dc.b	0,'?',0,'8',0,0,0,0
	dc.b	0,7,0,0,0,'8',0,0
	dc.b	0,'7',0,0,0,'8',0,0
	dc.b	0,'7',0,'.',0,'0',0,0
	dc.b	0,'+',0,$18,0,'$',0,0
	dc.b	0,$17,0,'0',0,8,0,0
	dc.b	0,$27,0,'/',0,$10,0,0
	dc.b	0,9,0,$19,0,'&',0,0
	dc.b	0,$10,0,'0',0,$f,0,0
	dcb.w	44
	dc.b	'x',0,'8',0,$f0,0,0,0
	dc.b	$f0,0,'8',0,$e0,0,0,0
	dc.b	$e0,0,'x',0,$c0,0,0,0
	dc.b	$c0,0,'8',0,0,0,0,0
	dc.b	$c8,0,'8',0,0,0,0,0
	dc.b	$d8,0,'8',0,0,0,0,0
	dc.b	$d8,0,'8',0,0,0,0,0
	dc.b	$d8,0,'8',0,0,0,0,0
	dc.b	$d8,0,'8',0,0,0,0,0
	dc.b	$c8,0,'x',0,0,0,0,0
	dc.b	$e0,0,$f8,0,0,0,0,0
	dc.b	'`',0,$f0,0,0,0,0,0
	dc.b	$80,0,$e0,0,0,0,0,0
	dc.b	$80,0,$c0,0,0,0,0,0
	dcb.w	244
	
; Music
MusicData:
	; ORG MUSIC_ADR
	bra	music_init	
	bra	music_play
l009e	tst.w	$6fd2c
	beq	l00a1
	clr.w	$6fd2c
	lea	$6fd2c,a0
	move.l	#$60000,d7
	subi.l	#$6fd2c,d7
	lea	16(a0),a1
	moveq	#$23,d6
l009f	sub.l	d7,(a1)+
	dbf	d6,l009f
	sub.l	d7,672(a0)
	sub.l	d7,768(a0)
	sub.l	d7,772(a0)
	sub.l	d7,776(a0)
	moveq	#$29,d6
	lea	1024(a0),a1
l00a0	sub.l	d7,(a1)+
	dbf	d6,l00a0
l00a1	rts

music_init:	bsr	l009e
	clr.l	d0
	jmp	$6fb2c
	dc.b	1,'/',1,'/',3,'/',$ff,1
	dc.b	'/',1,'(',1,' ',1,'(',1
	dc.b	'/',$ff,1,'/',2,'/',2,'/'
	dc.b	2,'/',3,'/',3,'/',3,'/'
	dc.b	3,'/',$ff,0,0,6,$e0,$c4
	dc.b	0,6,$e0,$d5,0,6,$e0,$dc
	dc.b	0,6,$e0,$e9,0,6,$e0,$fa
	dc.b	0,6,$e1,$b,0,6,$e1,'&'
	dc.b	0,6,$e1,')',0,6,$e1,','
	dc.b	0,6,$e1,'=',0,6,$e1,'J'
	dc.b	0,6,$e1,'M',0,6,$e1,'P'
	dc.b	0,6,$e1,'S',0,6,$e1,'V'
	dc.b	0,6,$e1,'Y',1,'/',2,'/'
	dc.b	3,'/',2,'/',1,'/',3,'/'
	dc.b	2,'/',2,'/',$ff,1,'/',2
	dc.b	'/',3,'/',$ff,1,'/',1,'/'
	dc.b	3,'/',2,'/',1,'(',1,'0'
	dc.b	$ff,1,'/',3,'/',1,'/',1
	dc.b	'/',3,'/',3,'/',3,'/',3
	dc.b	'/',$ff,1,'/',2,'/',3,'/'
	dc.b	2,'/',1,'/',3,'/',3,'/'
	dc.b	3,'/',$ff,1,'/',1,'/',1
	dc.b	'/',1,'/',1,'/',1,'/',1
	dc.b	'/',1,'/',1,'/',1,'/',1
	dc.b	'/',1,'/',1,'/',$ff,3,'/'
	dc.b	$ff,3,'/',$ff,1,'3',1,'3'
	dc.b	3,'/',3,'/',1,'2',1,'3'
	dc.b	1,'3',3,'3',$ff,3,'3',1
	dc.b	'3',3,'3',3,'3',3,'3',3
	dc.b	'3',$ff,3,'/',$ff,3,'/',$ff
	dc.b	3,'/',$ff,3,'/',$ff,3,'/'
	dc.b	$ff,3,'/',$ff,0,6,$e1,$9d
	dc.b	0,6,$e1,$b7,0,6,$e1,$c1
	dc.b	0,6,$e1,$d0,0,6,$e2,'Z'
	dc.b	0,6,$e2,$c8,0,6,$e3,$1a
	dc.b	0,6,$e3,' ',0,6,$e3,'&'
	dc.b	0,6,$e3,',',0,6,$e3,'2'
	dc.b	0,6,$e3,'8',0,6,$e3,'>'
	dc.b	0,6,$e3,'D',0,6,$e3,'J'
	dc.b	0,6,$e3,'P',4,1,2,0
	dc.b	0,2,3,0,0,3,4,0
	dc.b	0,4,5,0,0,3,4,0
	dc.b	0,2,3,0,0,$fe,5,1
	dc.b	2,0,0,2,3,0,0,$fe
	dc.b	8,1,2,0,0,3,4,0
	dc.b	0,$fe,$80,$80,0,0,$ff,3
	dc.b	$80,$80,0,0,$80,$80,0,0
	dc.b	$80,$80,$ff,0,$80,$80,$fe,0
	dc.b	$80,$80,$fd,0,$80,$80,$fc,0
	dc.b	$80,$80,$fc,0,$80,$80,$fb,0
	dc.b	$80,$80,$fa,0,$80,$80,$fa,0
	dc.b	$80,$80,$f9,0,$80,$80,$f9,0
	dc.b	$80,$80,$f8,0,$80,$80,$f8,0
	dc.b	$80,$80,$f9,0,$80,$80,$fa,0
	dc.b	$80,$80,$fb,0,$80,$80,$fc,0
	dc.b	$80,$80,$fd,0,$80,$80,$fe,0
	dc.b	$80,$80,$ff,0,$80,$80,0,0
	dc.b	$80,$80,$ff,0,$80,$80,$fe,0
	dc.b	$80,$80,$fd,0,$80,$80,$fc,0
	dc.b	$80,$80,$fb,0,$80,$80,$fa,0
	dc.b	$80,$80,$f9,0,$80,$80,$f8,0
	dc.b	$80,$80,$f7,0,$80,$80,$f6,0
	dc.b	$80,$80,$f5,0,$80,$80,$f4,0
	dc.b	$fe,3,0,0,0,0,1,2
	dc.b	0,0,2,3,0,0,3,4
	dc.b	0,0,4,5,0,0,5,6
	dc.b	0,0,6,7,0,0,7,8
	dc.b	0,0,8,9,0,0,9,$a
	dc.b	0,0,$a,$b,0,0,$b,$c
	dc.b	0,0,$c,$e,0,0,$d,$10
	dc.b	0,0,$e,$11,0,0,$f,$12
	dc.b	0,0,$10,$13,0,0,$11,$14
	dc.b	0,0,$12,$15,0,0,$13,$16
	dc.b	0,0,$14,$17,0,0,$15,$18
	dc.b	0,0,$16,$19,0,0,$17,' '
	dc.b	0,0,$18,'!',0,0,$19,'"'
	dc.b	0,0,' #',0,0,$ff,2
	dc.b	$80,$80,0,0,$80,$80,$ff,0
	dc.b	$80,$80,$fe,0,$80,$80,$fd,0
	dc.b	$80,$80,$fc,0,$80,$80,$fc,0
	dc.b	$80,$80,$fb,0,$80,$80,$fa,0
	dc.b	$80,$80,$fa,0,$80,$80,$f9,0
	dc.b	$80,$80,$f9,0,$80,$80,$f8,0
	dc.b	$80,$80,$f8,0,$80,$80,$f9,0
	dc.b	$80,$80,$fa,0,$80,$80,$fb,0
	dc.b	$80,$80,$fc,0,$80,$80,$fd,0
	dc.b	$80,$80,$fe,0,$80,$80,$ff,0
	dc.b	$fe,1,$80,$80,0,0,$ff,1
	dc.b	$80,$80,0,0,$ff,1,$80,$80
	dc.b	0,0,$ff,1,$80,$80,0,0
	dc.b	$ff,1,$80,$80,0,0,$ff,1
	dc.b	$80,$80,0,0,$ff,1,$80,$80
	dc.b	0,0,$ff,1,$80,$80,0,0
	dc.b	$ff,1,$80,$80,0,0,$ff,1
	dc.b	$80,$80,0,0,$ff,0,0,6
	dc.b	$e3,'k',0,6,$e3,'p',0,6
	dc.b	$e3,'u',0,6,$e3,'u',0,6
	dc.b	$e3,'u',1,$c,$c,0,$ff,1
	dc.b	$f4,$f4,$f4,$ff,1,$c,$f4,0
	dc.b	$ff,0,0,6,$e3,$bb,0,6
	dc.b	$e3,$c0,0,6,$e3,$c5,0,6
	dc.b	$e3,$ca,0,6,$e3,$cf,0,6
	dc.b	$e3,$d4,0,6,$e3,$d9,0,6
	dc.b	$e3,$de,0,6,$e3,$e3,0,6
	dc.b	$e3,$e8,0,6,$e3,$ee,0,6
	dc.b	$e3,$f3,0,6,$e3,$f8,0,6
	dc.b	$e3,$fd,0,6,$e4,2,0,6
	dc.b	$e4,7,1,'000',$ff,1
	dc.b	$13,$13,$13,$ff,1,'...'
	dc.b	$ff,1,$16,$16,$16,$ff,1,$14
	dc.b	$14,$14,$ff,1,$14,$14,$14,$ff
	dc.b	1,$14,$14,$14,$ff,1,$14,$14
	dc.b	$14,$ff,1,$1c,$1c,' ',$ff,1
	dc.b	$18,$19,$17,$12,$ff,1,$14,$14
	dc.b	$14,$ff,1,$14,$14,$14,$ff,1
	dc.b	$14,$14,$14,$ff,1,$14,$14,$14
	dc.b	$ff,1,$14,$14,$14,$ff,1,$14
	dc.b	$14,$14,$ff,0,0,0,0,0
	dc.b	0,0
l00a3	dc.b	$19,$f8,0,0,0,0,0,0
	dc.b	0,0,$e,$ee,$e,$17,$d,'M'
	dc.b	$c,$8e,$b,$d9,$b,'/',$a,$8e
	dc.b	9,$f7,9,'g',8,$e0,8,'a'
	dc.b	7,$e8,7,'w',7,$b,6,$a6
	dc.b	6,'G',5,$ec,5,$97,5,'G'
	dc.b	4,$fb,4,$b3,4,'p',4,'0'
	dc.b	3,$f4,3,$bb,3,$85,3,'S'
	dc.b	3,'#',2,$f6,2,$cb,2,$a3
	dc.b	2,'}',2,'Y',2,'8',2,$18
	dc.b	1,$fa,1,$dd,1,$c2,1,$a9
	dc.b	1,$91,1,'{',1,'e',1,'Q'
	dc.b	1,'>',1,',',1,$1c,1,$c
	dc.b	0,$fd,0,$ee,0,$e1,0,$d4
	dc.b	0,$c8,0,$bd,0,$b2,0,$a8
	dc.b	0,$9f,0,$96,0,$8e,0,$86
	dc.b	0,'~',0,'w',0,'p',0,'j'
	dc.b	0,'d',0,'^',0,'Y',0,'T'
	dc.b	0,'O',0,'K',0,'G',0,'C'
	dc.b	0,'?',0,';',0,'8',0,'5'
	dc.b	0,'2',0,'/',0,',',0,'*'
	dc.b	0,$27,0,'%',0,'#',0,'!'
	dc.b	0,$1f,0,$1d,0,$1c,0,$1a
	dc.b	0,$19,0,$17,0,$16,0,$15
	dc.b	0,$13,0,$12,0,$11,0,$10
	dc.b	0,$f,0,6,$ea,'$',0,6
	dc.b	$e6,$af,0,6,$ea,'0',0,6
	dc.b	$ea,'6',0,6,$ea,'<',0,6
	dc.b	$ea,'B',0,6,$ea,'H',0,6
	dc.b	$ea,'N',0,6,$ea,'T',0,6
	dc.b	$ea,'Z',0,6,$ea,'^',0,6
	dc.b	$ea,'b',0,6,$e9,$a0,0,6
	dc.b	$e9,'1',0,6,$e8,$c7,0,6
	dc.b	$e8,$cd,0,6,$ea,$a6,0,6
	dc.b	$ea,'z',0,6,$ea,'~',0,6
	dc.b	$ea,$82,0,6,$ea,$86,0,6
	dc.b	$ea,$8a,0,6,$ea,$8e,0,6
	dc.b	$ea,$92,0,6,$ea,$96,0,6
	dc.b	$ea,$9a,0,6,$ea,$aa,0,6
	dc.b	$ea,$9e,0,6,$ea,$a2,0,6
	dc.b	$ea,$ae,0,6,$ea,$b2,0,6
	dc.b	$ea,$b6,0,6,$ea,$a6,0,6
	dc.b	$ea,$ba,0,6,$ea,$be,0,6
	dc.b	$ea,$c2,0,6,$ea,$c6,0,6
	dc.b	$ea,$ca,0,6,$ea,$ce,0,6
	dc.b	$ea,$d2,0,6,$ea,$d6,0,6
	dc.b	$ea,$da,0,6,$ea,$ea,0,6
	dc.b	$ea,$de,0,6,$ea,$e2,0,6
	dc.b	$ea,$ee,0,6,$ea,$f2,0,6
	dc.b	$ea,$f6,0,6,$ea,$fa,0,6
	dc.b	$eb,'N',0,6,$eb,$9a,0,6
	dc.b	$eb,$ee,0,6,$ec,'L',0,6
	dc.b	$ea,8,0,6,$ea,$c,0,6
	dc.b	$ea,$10,0,6,$ea,$14,0,6
	dc.b	$ea,$18,0,6,$ea,$1c,0,6
	dc.b	$ea,' ',0,6,$ec,$b2,0,6
	dc.b	$ed,$11,0,6,$e8,$f5,0,6
	dc.b	$e8,$fb,0,6,$e9,1,0,6
	dc.b	$e9,7,0,6,$e9,$d,0,6
	dc.b	$e9,$13,0,6,$e9,$19,0,6
	dc.b	$e9,$1f,0,6,$e9,'%',0,6
	dc.b	$e9,'+',0,6,$e8,$d7,0,6
	dc.b	$e8,$dd,0,6,$e8,$e3,0,6
	dc.b	$e8,$e9,0,6,$e8,$ef,0,6
	dc.b	$ed,$17,0,6,$ed,$1e,0,6
	dc.b	$ed,$83,0,6,$e8,$c2,0,6
	dc.b	$e8,'~',0,6,$e8,$84,0,6
	dc.b	$e8,$8a,0,6,$e8,$90,0,6
	dc.b	$e8,$96,0,6,$e8,$9c,0,6
	dc.b	$e8,$ae,0,6,$e8,$b3,0,6
	dc.b	$e8,$b8,0,6,$e8,$bd,0,6
	dc.b	$e7,'2',0,6,$e7,'"',0,6
	dc.b	$e8,$a2,0,6,$e8,$a8,0,6
	dc.b	$e7,4,0,6,$e7,9,0,6
	dc.b	$e7,$e,0,6,$e6,$ff,0,6
	dc.b	$e7,$13,0,6,$e6,$e2,0,6
	dc.b	$e6,$e7,0,6,$e6,$ec,0,6
	dc.b	$e6,$f1,0,6,$e6,$f6,0,6
	dc.b	$e6,$fb,0,6,$e6,$c4,0,6
	dc.b	$e6,$c9,0,6,$e6,$ce,0,6
	dc.b	$e6,$d3,0,6,$e6,$d8,0,6
	dc.b	$e6,$dd,0,6,$e6,$a5,0,6
	dc.b	$e6,$aa,0,0,3,7,$8f,0
	dc.b	0,4,9,$8f,0,0,4,8
	dc.b	$c,$10,$14,$18,$1c,' $('
	dc.b	',048<@DH'
	dc.b	$8f,0,0,3,7,$8f,0,0
	dc.b	4,7,$8f,0,0,5,8,$8f
	dc.b	0,0,5,9,$8f,0,0,3
	dc.b	6,$8f,0,0,5,7,$8f,0
	dc.b	0,7,$a,$8f,0,0,5,9
	dc.b	$8f,0,0,4,7,$8f,0,0
	dc.b	7,$c,$8f,0,0,2,5,$8f
	dc.b	0,0,7,$8f,0,0,$c,$18
	dc.b	$8f,0,0,8,5,$8f,0,0
	dc.b	4,7,$8f,0,0,5,9,$8f
	dc.b	0,'-(% ',$1d,$19,$19
	dc.b	$14,$14,$d,$d,$14,$14,$8f,0
	dcb.w	3
	dc.b	$ff,$fe,$fd,$fc,$fb,$fa,$f9,$f8
	dc.b	$8e,0,$d5,$d5,$e1,$e1,$d6,$d6
	dc.b	$e2,$e2,$d7,$d7,$e3,$e3,$d8,$d8
	dc.b	$e4,$e4,$d9,$d9,$e5,$e5,$da,$da
	dc.b	$e6,$e6,$db,$db,$e7,$e7,$dc,$dc
	dc.b	$e8,$e8,$dd,$dd,$e9,$e9,$de,$de
	dc.b	$ea,$ea,$df,$df,$eb,$eb,$e0,$e0
	dc.b	$ec,$ec,$e1,$e1,$ed,$ed,$e2,$e2
	dc.b	$ee,$ee,$e3,$e3,$ef,$ef,$e4,$e4
	dc.b	$f0,$f0,$e5,$e5,$f1,$f1,$e6,$e6
	dc.b	$f2,$f2,$e7,$e7,$f3,$f3,$e8,$e8
	dc.b	$f4,$f4,$e9,$e9,$f5,$f5,$ea,$ea
	dc.b	$f6,$f6,$eb,$eb,$f7,$f7,$ec,$ec
	dc.b	$f8,$f8,$ed,$ed,$f9,$f9,$ee,$ee
	dc.b	$fa,$fa,$ef,$ef,$fb,$fb,$f0,$f0
	dc.b	$fc,$fc,$f1,$f1,$fd,$fd,$f2,$f2
	dc.b	$fe,$fe,$f3,$f3,$ff,$ff,$f4,$f4
	dc.b	0,0,$f5,$f5,1,1,$f6,$f6
	dc.b	2,2,$f7,$f7,3,3,$f8,$f8
	dc.b	4,4,$f9,$f9,5,5,$fa,$fa
	dc.b	6,6,$fb,$fb,7,7,$fc,$fc
	dc.b	8,8,$fd,$fd,9,9,$fe,$fe
	dc.b	$a,$a,$ff,$ff,$b,$b,0,0
	dc.b	$c,$c,1,1,$d,$d,2,2
	dc.b	$e,$e,3,3,$f,$f,4,4
	dc.b	$10,$10,5,5,$11,$11,6,6
	dc.b	$12,$12,7,7,$13,$13,8,8
	dc.b	$14,$14,9,9,$15,$15,$a,$a
	dc.b	$16,$16,$b,$b,$17,$17,$c,$c
	dc.b	$18,$18,$d,$d,$19,$19,$e,$e
	dc.b	$1a,$1a,$f,$f,$1b,$1b,$10,$10
	dc.b	$1c,$1c,$11,$11,$1d,$1d,$12,$12
	dc.b	$1e,$1e,$13,$13,$1f,$1f,$14,$14
	dc.b	'  ',$15,$15,'!!',$16,$16
	dc.b	'""',$17,$17,'##',$18,$18
	dc.b	'$$',$19,$19,'%%',$1a,$1a
	dc.b	'&&',$1b,$1b,$27,$27,$1c,$1c
	dc.b	'((',$1d,$1d,'))',$1e,$1e
	dc.b	'**',$1f,$1f,'++  '
	dc.b	',,!!--""'
	dc.b	'..##//$$'
	dc.b	'00%%11&&'
	dc.b	'22',$27,$27,$8f,0,$fc,0
	dc.b	$f9,0,$8f,0,$fb,0,$f7,0
	dc.b	$8f,0,$fd,0,$f8,0,$8f,0
	dc.b	$fd,0,$f9,0,$8f,0,$fb,0
	dc.b	$f8,0,$8f,0,$fc,0,$f7,0
	dc.b	$8f,0,$c,0,0,0,$8f,0
	dc.b	$fb,0,$f8,0,$8f,0,0,$fc
	dc.b	$f7,$8f,0,0,$fd,$f9,$8f,0
	dc.b	0,$fc,$f7,$8f,0,0,$c,$f4
	dc.b	$8f,0,$fe,$ff,0,$8e,0,0
	dc.b	$ff,$fe,$fd,$8e,0,0,$fc,$f8
	dc.b	$f4,$f0,$ec,$e8,$e4,$8e,0,0
	dc.b	3,7,$c,$8f,0,0,5,9
	dc.b	$c,$8f,0,0,$fc,3,8,$8f
	dc.b	0,0,5,9,$c,$8f,0,0
	dc.b	7,$c,7,$8f,0,$fc,0,$f9
	dc.b	0,$8f,0,$fc,0,$f9,0,$8f
	dc.b	0,$fd,0,$f9,0,$8f,0,$fd
	dc.b	0,$f8,0,$8f,0,$fb,0,$f9
	dc.b	0,$8f,0,$fb,0,$f8,0,$8f
	dc.b	0,$fa,0,$f7,0,$8f,0,$fc
	dc.b	0,$f7,0,$8f,0,$fb,0,$f8
	dc.b	0,$8f,0,$fd,0,$fa,0,$8f
	dc.b	1,0,0,$18,$c,0,$18,$c
	dc.b	0,$18,$c,0,$18,$c,0,$ff
	dc.b	$ff,$fe,$fe,$fd,$fd,$fc,$fc,$fb
	dc.b	$fb,$fa,$fa,$f9,$f9,$f8,$f8,$f7
	dc.b	$f7,$f6,$f6,$f5,$f5,$f4,$f4,$f3
	dc.b	$f3,$f2,$f2,$f1,$f1,$f0,$f0,$ef
	dc.b	$ef,$ee,$ee,$ed,$ed,$ec,$ec,$eb
	dc.b	$eb,$ea,$ea,$e9,$e9,$e8,$e8,$e7
	dc.b	$e7,$e6,$e6,$e5,$e5,$e4,$e4,$e3
	dc.b	$e3,$e2,$e2,$e1,$e1,$e0,$e0,$df
	dc.b	$df,$de,$de,$dd,$dd,$dc,$dc,$db
	dc.b	$db,$da,$da,$d9,$d9,$d8,$d8,$d7
	dc.b	$d7,$d6,$d6,$d5,$d5,$d4,$d4,$d3
	dc.b	$d3,$d2,$d2,$d1,$d1,0,$8e,1
	dcb.w	3
	dc.b	0,$ff,$ff,$fe,$fe,$fd,$fd,$fc
	dc.b	$fc,$fb,$fb,$fa,$fa,$f9,$f9,$f8
	dc.b	$f8,$f7,$f7,$f6,$f6,$f5,$f5,$f4
	dc.b	$f4,$f3,$f3,$f2,$f2,$f1,$f1,$f0
	dc.b	$f0,$ef,$ef,$ee,$ee,$ed,$ed,$ec
	dc.b	$ec,$eb,$eb,$ea,$ea,$e9,$e9,$e8
	dc.b	$e8,$e7,$e7,$e6,$e6,$e5,$e5,$e4
	dc.b	$e4,$e3,$e3,$e2,$e2,$e1,$e1,$e0
	dc.b	$e0,$df,$df,$de,$de,$dd,$dd,$dc
	dc.b	$dc,$db,$db,$da,$da,$d9,$d9,$d8
	dc.b	$d8,$d7,$d7,$d6,$d6,$d5,$d5,$d4
	dc.b	$d4,$d3,$d3,$d2,$d2,$d1,$d1,0
	dc.b	$8e,1,0,$18,$8f,1,0,$18
	dc.b	$8f,1,0,7,$8f,1,$c,4
	dc.b	$8f,1,9,5,$8f,1,8,5
	dc.b	$8f,1,0,0,$8f,0,0,0
	dc.b	0,0,$8e,0,0,$c,0,$c
	dc.b	$8f,0,$c,7,3,0,$8f,0
	dc.b	$c,7,$c,7,$8f,1,0,5
	dc.b	$8f,$c,$ff,0,0,0,$c,$8f
	dc.b	0,0,7,$c,$10,$8f,0,0
	dc.b	3,7,$c,$8f,0,0,$c,0
	dc.b	$c,$8f,0,0,0,$c,$8f,0
	dc.b	0,4,$8f,0,0,3,$8f,0
	dc.b	0,3,$8f,0,$f4,$f2,$ec,$ee
	dc.b	$ec,$e7,$e4,$e0,$8e,1,0,0
	dc.b	0,$c,$8f,0,0,1,$8f,0
	dc.b	0,2,$8f,0,0,3,$8f,0
	dc.b	0,4,$8f,0,0,5,$8f,0
	dc.b	0,6,$8f,0,0,7,$8f,0
	dc.b	0,8,$8f,0,0,9,$8f,0
	dc.b	0,$b,$8f,0,0,$c,$8f,0
	dc.b	0,0,$8f,0,0,$a,$8f,0
	dc.b	0,$d,$8f,0,0,$e,$8f,0
	dc.b	0,$f,$8f,0,0,$ff,$8f,1
	dc.b	0,$fe,$8f,1,0,$fd,$8f,1
	dc.b	0,$fc,$8f,1,0,$fb,$8f,1
	dc.b	0,$fa,$8f,1,0,$f9,$8f,1
	dc.b	0,$f8,$8f,1,0,$f7,$8f,1
	dc.b	0,$f6,$8f,1,0,$f5,$8f,1
	dc.b	0,$f4,$8f,1,0,$f3,$8f,1
	dc.b	0,$f2,$8f,1,0,$f1,$8f,1
	dc.b	0,$f0,$8f,1,0,$c,0,$d
	dc.b	0,$e,0,$f,0,$10,0,$11
	dc.b	0,$12,0,$13,0,$14,0,$15
	dc.b	0,$16,0,$17,0,$18,0,$19
	dc.b	0,$1a,0,$1b,0,$1c,0,$1d
	dc.b	0,$1e,0,$1f,0,' ',0,'!'
	dc.b	0,'"',0,'#',0,'$',0,'%'
	dc.b	0,'&',0,$27,0,'(',0,')'
	dc.b	0,'*',0,'+',0,'(',0,')'
	dc.b	0,'*',0,'+',0,',',0,'-'
	dc.b	0,'.',0,'/',0,'0',$8e,1
	dc.b	0,$f4,0,$f3,0,$f2,0,$f1
	dc.b	0,$f0,0,$ef,0,$ee,0,$ed
	dc.b	0,$ec,0,$eb,0,$ea,0,$e9
	dc.b	0,$e8,0,$e7,0,$e6,0,$e5
	dc.b	0,$e4,0,$e3,0,$e2,0,$e1
	dc.b	0,$e0,0,$df,0,$de,0,$dd
	dc.b	0,$dc,0,$db,0,$da,0,$d9
	dc.b	0,$d8,0,$d7,0,$d6,0,$d5
	dc.b	0,$d4,0,$d3,0,$d2,0,$d1
	dc.b	0,$d0,$8e,1,0,$c,0,$c
	dc.b	0,$c,$ff,$b,$fe,$a,$fd,9
	dc.b	$fc,8,$fb,7,$fa,6,$f9,5
	dc.b	$f8,4,$f7,3,$f6,2,$f5,1
	dc.b	$f4,0,$f3,$ff,$f2,$fe,$f1,$fd
	dc.b	$f0,$fc,$ef,$fb,$ee,$fa,$ed,$f9
	dc.b	$ec,$f8,$eb,$f7,$ea,$f6,$e9,$f5
	dc.b	$e8,$f4,$e7,$f3,$e6,$f2,$e5,$f1
	dc.b	$e4,$f0,$e3,$ef,$e2,$ee,$e1,$ed
	dc.b	$e0,$ec,$df,$eb,$de,$ea,$dd,$e9
	dc.b	$dc,$e8,$db,$e7,$da,$e6,$8e,1
	dcb.w	8
	dc.b	$ff,$b,$fe,$a,$fd,9,$fc,8
	dc.b	$fb,7,$fa,6,$f9,5,$f8,4
	dc.b	$f7,3,$f6,2,$f5,1,$f4,0
	dc.b	$f3,$ff,$f2,$fe,$f1,$fd,$f0,$fc
	dc.b	$ef,$fb,$ee,$fa,$ed,$f9,$ec,$f8
	dc.b	$eb,$f7,$ea,$f6,$e9,$f5,$e8,$f4
	dc.b	$e7,$f3,$e6,$f2,$e5,$f1,$e4,$f0
	dc.b	$e3,$ef,$e2,$ee,$e1,$ed,$e0,$ec
	dc.b	$df,$eb,$de,$ea,$dd,$e9,$dc,$e8
	dc.b	$db,$e7,$da,$e6,$8e,1,0,0
	dcb.w	11
	dc.b	$ff,$b,$fe,$a,$fd,9,$fc,8
	dc.b	$fb,7,$fa,6,$f9,5,$f8,4
	dc.b	$f7,3,$f6,2,$f5,1,$f4,0
	dc.b	$f3,$ff,$f2,$fe,$f1,$fd,$f0,$fc
	dc.b	$ef,$fb,$ee,$fa,$ed,$f9,$ec,$f8
	dc.b	$eb,$f7,$ea,$f6,$e9,$f5,$e8,$f4
	dc.b	$e7,$f3,$e6,$f2,$e5,$f1,$e4,$f0
	dc.b	$e3,$ef,$e2,$ee,$e1,$ed,$e0,$ec
	dc.b	$df,$eb,$de,$ea,$dd,$e9,$dc,$e8
	dc.b	$db,$e7,$da,$e6,$8e,1,0,0
	dcb.w	5
	dc.b	$c,0,$d,0,$e,0,$f,0
	dc.b	$10,0,$11,0,$12,0,$13,0
	dc.b	$14,0,$15,0,$16,0,$17,0
	dc.b	$18,0,$19,0,$1a,0,$1b,0
	dc.b	$1c,0,$1d,0,$1e,0,$1f,0
	dc.b	' ',0,'!',0,'"',0,'#',0
	dc.b	'$',0,'%',0,'&',0,$27,0
	dc.b	'(',0,')',0,'*',0,'+',0
	dc.b	'(',0,')',0,'*',0,'+',0
	dc.b	',',0,'-',0,'.',0,'/',0
	dc.b	'0',$8e,1,0,0,0,$c,$8f
	dc.b	0,0,0,$18,$18,0,$8f,1
	dcb.w	11
	dc.b	0,$ff,$b,$fe,$a,$fd,9,$fc
	dc.b	8,$fb,7,$fa,6,$f9,5,$f8
	dc.b	4,$f7,3,$f6,2,$f5,1,$f4
	dc.b	0,$f3,$ff,$f2,$fe,$f1,$fd,$f0
	dc.b	$fc,$ef,$fb,$ee,$fa,$ed,$f9,$ec
	dc.b	$f8,$eb,$f7,$ea,$f6,$e9,$f5,$e8
	dc.b	$f4,$e7,$f3,$e6,$f2,$e5,$f1,$e4
	dc.b	$f0,$e3,$ef,$e2,$ee,$e1,$ed,$e0
	dc.b	$ec,$df,$eb,$de,$ea,$dd,$e9,$dc
	dc.b	$e8,$db,$e7,$da,$e6,$8e,0,1
	dc.b	2,3,4,5,6,7,8,9
	dc.b	$a,$b,$c,$d,$e,$f,$10,$11
	dc.b	$12,$13,$14,$15,$16,$17,$18,$19
	dc.b	$1a,$1b,$1c,$1d,$1e,$1f,' !'
	dc.b	'"#$%&',$27,'()'
	dc.b	'*+,-./01'
	dc.b	'23456789'
	dc.b	':;<=>',$8f,'!',0
	dc.b	0,6,1,'c',0,6,3,' '
	dc.b	0,0,0,' ',0,$1f,0,6
	dc.b	$ea,'#',0,6,$ea,'5',1,1
	dc.b	$f,$1b,' .',$e,$a,0,2
	dc.b	$a,'Q',0,6,0,'Q',$e,1
	dc.b	1,1,'@',0,0,9,0,0
	dcb.w	31
	dc.b	'3',0,0,6,0,$bb,0,6
	dc.b	3,'`',0,0,0,$d0,0,8
	dc.b	0,6,$ea,'#',0,6,$ea,'5'
	dc.b	1,1,2,3,4,$1b,$e,0
	dc.b	0,2,$a,'"',0,2,$a,'!'
	dc.b	$e,1,1,0,'@',0,0,$12
	dcb.w	32
	dc.b	'!',0,0,6,1,'c',0,6
	dc.b	4,$b0,0,0,0,'$',0,$1f
	dc.b	0,6,$ea,'#',0,6,$ea,'5'
	dc.b	1,1,$f,$1d,' .',$e,2
	dc.b	0,2,$a,'Q',0,2,$a,'Q'
	dc.b	$e,1,1,0,'`',0,0,'$'
	dcb.w	32
	dc.b	4,4,$19,$19,$f8,5,5,0
	dcb.w	4
	dc.b	$10,$10,3,3,3,3,0,0
music_play:	addq.b	#1,$6ef28
	tst.b	$6f7bc
	beq	l00a6
	move.b	$6ef14,$6ef15
	subq.b	#1,$6ef12
	bne	l00a5
	movea.l	#$6edc2,a0
	bsr	l00b3
	movea.l	#$6ee32,a0
	bsr	l00b3
	movea.l	#$6eea2,a0
	bsr	l00b3
	move.b	$6ef13,$6ef12
l00a5	movea.l	#$6edc2,a0
	bsr	l00d6
	move.w	d0,$6f7be
	move.b	d0,$6e40c
	move.b	$6f7be,$6e40d
	move.b	d1,$6e414
	movea.l	#$6ee32,a0
	bsr	l00d6
	move.w	d0,$6f7be
	move.b	d0,$6e40e
	move.b	$6f7be,$6e40f
	move.b	d1,$6e415
	movea.l	#$6eea2,a0
	bsr	l00d6
	move.w	d0,$6f7be
	move.b	d0,$6e410
	move.b	$6f7be,$6e411
	move.b	d1,$6e416
	move.b	$6ef15,$6e412
l00a6	tst.b	$6f7bc
	bne	l00a8
	move.w	#$a,d0
	movea.l	#$6e40c,a0
l00a7	move.b	#0,(a0)+
	dbf	d0,l00a7
	move.b	#$3f,$6e413
l00a8	move.b	#7,$ff8800.l
	move.b	$ff8800.l,d0
	andi.b	#$c0,d0
	andi.b	#$3f,$6e413
	or.b	d0,$6e413
	move.b	l00a3(pc),d1
	andi.l	#$ff,d1
	movea.l	#$6e419,a0
	move.w	#$c,d0
l00a9	move.b	d0,$ff8800.l
	move.b	-(a0),$ff8802.l
	dbf	d0,l00a9
	rts

	dc.b	0,6,$f2,$c8,0,6,$f2,'t'
	dc.b	0,6,$f2,'~',0,6,$f2,$94
	dc.b	0,6,$f2,$12,0,6,$f2,'h'
	dc.b	0,6,$f2,'d',0,6,$f0,$bc
	dc.b	0,6,$f2,'V',0,6,$f2,'L'
	dc.b	0,6,$f1,$cc,0,6,$f1,'t'
	dc.b	0,6,$f0,$a8,0,6,$f2,$ac
	dc.b	0,6,$f0,$b2,0,6,$f1,$9a
	dc.b	0,6,$f2,$b4,0,6,$f6,$84
	dc.b	0,6,$f2,','
	move.b	(a1)+,d0
	bsr	l00c5
	bra	l00b4
	move.b	#1,46(a0)
	bra	l00b4
l00aa	move.l	10(a0),d0
	move.b	#$19,$6ef14
	bclr	#0,96(a0)
	bclr	#2,96(a0)
	bclr	#1,96(a0)
	bclr	#0,64(a0)
	movea.l	6(a0),a2
	adda.l	d0,a2
	addq.l	#1,d0
	cmpi.b	#$80,(a2)
	bne	l00ac
	move.b	1(a2),63(a0)
l00ab	addi.l	#2,10(a0)
	bra	l00aa
l00ac	cmpi.b	#$fe,(a2)
	bne	l00ad
	clr.b	$6f7bc
	bra	l00ab
l00ad	cmpi.b	#$fd,(a2)
	bne	l00ae
	move.b	1(a2),$6ef23
	bra	l00ab
l00ae	cmpi.b	#$ff,(a2)
	bne	l00b0
	movea.l	6(a0),a2
	cmpi.b	#$80,(a2)
	bne	l00af
	move.l	#3,d0
	move.b	1(a2),63(a0)
	adda.l	#2,a2
	bra	l00b0
l00af	move.l	#1,d0
l00b0	move.l	d0,10(a0)
	moveq	#0,d0
	move.b	(a2),d0
	asl.w	#2,d0
	movea.l	$6f7c0,a1
	movea.l	0(a1,d0.l),a1
	move.l	10(a0),d0
	bra	l00b4
l00b1	move.b	47(a0),d0
	move.b	d0,d1
	andi.b	#7,d0
	move.b	$6ef16,d2
	eor.b	d2,d0
	and.b	d1,d0
	eor.b	d2,d0
	move.b	d0,$6ef16
	move.b	#1,45(a0)
	bra	l00b4
	move.b	47(a0),d0
	move.b	d0,d1
	andi.b	#7,d0
	move.b	$6ef16,d2
	eor.b	d2,d0
	and.b	d1,d0
	eor.b	d2,d0
	move.b	d0,$6ef16
	move.b	#1,45(a0)
	bset	#1,54(a0)
	move.b	#$40,55(a0)
	bra	l00b1
	move.b	47(a0),d0
	move.b	d0,d1
	andi.b	#$38,d0
	move.b	$6ef16,d2
	eor.b	d2,d0
	and.b	d1,d0
	eor.b	d2,d0
	move.b	d0,$6ef16
	move.b	#0,45(a0)
	bra	l00b4
	move.b	47(a0),d0
	eori.b	#$ff,d0
	move.b	$6ef16,d2
	and.b	d2,d0
	and.b	d0,$6ef16
	move.b	#1,45(a0)
	bra	l00b4
	move.w	#0,14(a0)
	bset	#2,(a0)
	clr.b	108(a0)
	move.b	(a1)+,24(a0)
	move.b	(a1)+,25(a0)
	bra	l00b4
	move.w	#0,14(a0)
	bset	#2,(a0)
	move.b	#$ff,108(a0)
	move.b	(a1)+,24(a0)
	move.b	(a1)+,25(a0)
	move.b	(a1)+,109(a0)
	bra	l00b4
	move.b	(a1)+,$6f7ba
	bra	l00b4
	move.b	(a1)+,d0
	move.b	(a1),d0
	move.b	(a1)+,d0
	move.b	(a1),d0
	move.b	(a1)+,d0
	bra	l00b4
	bset	#7,(a0)
	bset	#3,(a0)
	move.b	(a1)+,51(a0)
	bra	l00b4
	move.b	#0,44(a0)
	bra	l00b4
	move.b	#$40,44(a0)
	move.b	#$19,$6ef14
	clr.b	110(a0)
	bra	l00b4
	move.b	#$40,44(a0)
	move.b	#$19,$6ef14
	move.b	#1,110(a0)
	bra	l00b4
	bset	#1,(a0)
	bra	l00b4
	bset	#2,54(a0)
	move.b	(a1)+,57(a0)
	move.b	57(a0),56(a0)
	bra	l00b9
	tst.b	46(a0)
	bne	l00b2
	move.b	#0,30(a0)
	bclr	#2,54(a0)
l00b2	bra	l00b9
l00b3	subq.b	#1,27(a0)
	bne	l00c1
	move.b	#$2f,$6ef14
	move.b	#0,46(a0)
	move.b	#0,(a0)
	movea.l	2(a0),a1
l00b4	move.w	#0,d0
	move.b	(a1)+,d0
	bmi	l00c4
	bclr	#2,54(a0)
	move.b	d0,29(a0)
	move.b	$6ef14,65(a0)
	tst.b	45(a0)
	beq	l00b5
	move.b	d0,$6ef14
l00b5	move.b	$6ef14,65(a0)
	move.b	47(a0),d0
	move.b	d0,d1
	andi.b	#$38,d0
	move.b	$6ef16,d2
	eor.b	d2,d0
	and.b	d1,d0
	eor.b	d2,d0
	move.b	d0,$6ef16
	move.b	#0,45(a0)
	move.b	65(a0),$6ef14
	movea.l	32(a0),a2
	tst.b	46(a0)
	bne	l00b8
	movea.l	36(a0),a2
	move.l	92(a0),88(a0)
	move.b	87(a0),86(a0)
	btst	#0,96(a0)
	beq	l00b6
	move.l	70(a0),66(a0)
	bset	#0,64(a0)
l00b6	btst	#2,96(a0)
	beq	l00b7
	bset	#1,96(a0)
	move.l	102(a0),98(a0)
	move.b	107(a0),106(a0)
l00b7	move.l	a2,d2
	move.l	a2,32(a0)
l00b8	move.b	(a2),40(a0)
	move.b	(a2),30(a0)
	move.b	26(a0),31(a0)
	bset	#5,(a0)
l00b9	move.b	28(a0),27(a0)
	move.b	50(a0),48(a0)
	tst.b	46(a0)
	bne	l00ba
	move.b	#0,49(a0)
l00ba	btst	#0,62(a0)
	beq	l00bb
	move.w	#0,14(a0)
	bset	#2,(a0)
	move.b	#$48,24(a0)
	move.b	#1,25(a0)
l00bb	btst	#1,62(a0)
	beq	l00bc
	bset	#1,(a0)
	move.b	#$10,29(a0)
l00bc	btst	#2,62(a0)
	beq	l00bd
	bset	#0,64(a0)
	move.l	#$6e060,70(a0)
	move.l	70(a0),66(a0)
l00bd	btst	#3,62(a0)
	beq	l00be
	bset	#0,64(a0)
	move.l	#$6e067,70(a0)
	move.l	70(a0),66(a0)
l00be	btst	#4,62(a0)
	beq	l00bf
	bset	#0,64(a0)
	move.l	#$6e072,70(a0)
	move.l	70(a0),66(a0)
l00bf	move.b	52(a0),53(a0)
	move.b	57(a0),56(a0)
	move.l	a1,2(a0)
	move.b	#$30,55(a0)
	tst.b	46(a0)
	bne	l00c0
	move.l	16(a0),20(a0)
l00c0	rts

l00c1	btst	#3,(a0)
	bne	l00c2
	rts

l00c2	move.b	51(a0),d5
	btst	#7,(a0)
	beq	l00c3
	add.b	d5,29(a0)
	rts

l00c3	sub.b	d5,29(a0)
	rts

l00c4	cmpi.b	#$b8,d0
	bcs	l00d5
	addi.b	#$20,d0
	bcs	l00cc
	addi.b	#$10,d0
	bcs	l00cd
	addi.b	#$10,d0
	bcc	l00cb
	bra	l00ce
l00c5	andi.l	#$ff,d0
	bclr	#1,96(a0)
	cmpi.b	#$80,d0
	bhi	l00c6
	beq	l00c6
	lsl.w	#2,d0
	movea.l	#$6e4dc,a2
	adda.l	d0,a2
	move.l	(a2),20(a0)
	move.l	(a2),16(a0)
	movea.l	16(a0),a2
	move.b	-1(a2),52(a0)
	move.b	52(a0),53(a0)
	rts

l00c6	cmpi.b	#$90,d0
	bhi	l00c7
	beq	l00c7
	bclr	#1,80(a0)
	andi.l	#$f,d0
	lsl.b	#2,d0
	movea.l	#$6e356,a2
	adda.l	d0,a2
	move.l	(a2),88(a0)
	move.l	(a2),92(a0)
	movea.l	(a2),a2
	move.b	-1(a2),86(a0)
	move.b	86(a0),87(a0)
	moveq	#0,d0
	bra	l00c5
l00c7	cmpi.b	#$a0,d0
	bhi	l00c8
	beq	l00c8
	bset	#1,80(a0)
	andi.l	#$f,d0
	lsl.b	#2,d0
	movea.l	#$6e37a,a2
	adda.l	d0,a2
	move.l	(a2),88(a0)
	move.l	(a2),92(a0)
	movea.l	(a2),a2
	move.b	-1(a2),86(a0)
	move.b	86(a0),87(a0)
	moveq	#0,d0
	bra	l00c5
l00c8	cmpi.b	#$b0,d0
	bhi	l00c9
	beq	l00c9
	andi.l	#$f,d0
	lsl.b	#2,d0
	movea.l	#$6e084,a2
	adda.l	d0,a2
	move.l	(a2),70(a0)
	move.l	(a2),66(a0)
	bclr	#7,62(a0)
	bset	#0,96(a0)
	bset	#0,64(a0)
	moveq	#0,d0
	bra	l00c5
l00c9	cmpi.b	#$c0,d0
	bhi	l00ca
	beq	l00ca
	andi.l	#$f,d0
	asl.b	#2,d0
	movea.l	#$6e15c,a2
	adda.l	d0,a2
	movea.l	(a2),a2
	move.b	-1(a2),106(a0)
	move.b	-1(a2),107(a0)
	move.l	a2,98(a0)
	move.l	a2,102(a0)
	bset	#1,96(a0)
	bset	#2,96(a0)
	moveq	#0,d0
	bra	l00c5
l00ca	andi.l	#7,d0
	addi.l	#8,d0
	move.l	d0,-(a7)
	lsl.b	#2,d0
	movea.l	#$6e084,a2
	adda.l	d0,a2
	move.l	(a2),70(a0)
	move.l	(a2),66(a0)
	bset	#0,96(a0)
	bset	#0,64(a0)
	move.l	(a7)+,d0
	bset	#1,80(a0)
	andi.l	#$f,d0
	lsl.b	#2,d0
	movea.l	#$6e37a,a2
	adda.l	d0,a2
	move.l	(a2),88(a0)
	move.l	(a2),92(a0)
	movea.l	(a2),a2
	move.b	-1(a2),86(a0)
	move.b	86(a0),87(a0)
	moveq	#0,d0
	bra	l00c5
l00cb	addi.b	#9,d0
	move.b	d0,$6ef13
	bra	l00b4
l00cc	addq.b	#1,d0
	move.b	d0,28(a0)
	bra	l00b4
	move.b	(a1)+,d0
	addq.b	#1,d0
	move.b	d0,28(a0)
	bra	l00b4
l00cd	addi.w	#$10,d0
l00ce	lsl.w	#2,d0
	bclr	#0,96(a0)
	bclr	#1,96(a0)
	bclr	#2,96(a0)
	clr.b	97(a0)
	bclr	#0,64(a0)
	movea.l	$6f7b6,a2
	tst.b	110(a0)
	beq	l00cf
	movea.l	$6f7c8,a2
l00cf	move.b	#$19,$6ef14
	movea.l	0(a2,d0.w),a2
	move.l	a2,36(a0)
	move.b	-2(a2),48(a0)
	move.b	-2(a2),50(a0)
	move.b	-3(a2),43(a0)
	move.b	-6(a2),62(a0)
	move.b	-3(a2),41(a0)
	move.b	-4(a2),42(a0)
	move.b	-1(a2),26(a0)
	move.b	-5(a2),d0
	bsr	l00c5
	btst	#0,62(a0)
	beq	l00d0
	move.w	#0,14(a0)
	bset	#2,(a0)
	move.b	#$48,24(a0)
	clr.b	108(a0)
	move.b	#1,25(a0)
l00d0	btst	#1,62(a0)
	beq	l00d1
	bset	#1,(a0)
	addq.l	#1,a1
	move.b	#$10,29(a0)
	bra	l00b5
l00d1	btst	#2,62(a0)
	beq	l00d2
	bset	#0,64(a0)
	move.l	#$6e060,70(a0)
	move.l	70(a0),66(a0)
l00d2	btst	#3,62(a0)
	beq	l00d3
	bset	#0,64(a0)
	move.l	#$6e067,70(a0)
	move.l	70(a0),66(a0)
l00d3	btst	#4,62(a0)
	beq	l00d4
	bset	#0,64(a0)
	move.l	#$6e072,70(a0)
	move.l	70(a0),66(a0)
l00d4	bra	l00b4
l00d5	andi.w	#$7f,d0
	lsl.w	#2,d0
	movea.l	#$6f05c,a2
	movea.l	0(a2,d0.w),a2
	jmp	(a2)
	dc.b	0,6,$fd,'L',0,0,0,0
	dc.b	0,0,0,7,1,',',0,6
	dc.b	$ff,$cc,0,6,$fd,'L'
l00d6	btst	#0,80(a0)
	beq	l00d7
	subq.b	#1,82(a0)
	beq	l00d7
	move.b	83(a0),82(a0)
	subq.b	#1,29(a0)
l00d7	btst	#0,64(a0)
	beq	l00db
	addq.l	#2,66(a0)
	movea.l	66(a0),a2
	cmpi.b	#$ff,(a2)
	bne	l00d8
	bclr	#0,64(a0)
	bra	l00db
l00d8	cmpi.b	#1,(a2)
	bne	l00d9
	move.b	47(a0),d0
	move.b	d0,d1
	andi.b	#7,d0
	move.b	$6ef16,d2
	eor.b	d2,d0
	and.b	d1,d0
	eor.b	d2,d0
	move.b	d0,$6ef16
	move.b	#1,45(a0)
	move.b	1(a2),$6ef14
	bra	l00db
l00d9	cmpi.b	#2,(a2)
	bne	l00da
	move.b	47(a0),d0
	eori.b	#$ff,d0
	move.b	$6ef16,d2
	and.b	d2,d0
	and.b	d0,$6ef16
	move.b	#1,45(a0)
	move.b	1(a2),$6ef14
	bra	l00db
l00da	cmpi.b	#3,(a2)
	bne	l00db
	move.b	47(a0),d0
	move.b	d0,d1
	andi.b	#$38,d0
	move.b	$6ef16,d2
	eor.b	d2,d0
	and.b	d1,d0
	eor.b	d2,d0
	move.b	d0,$6ef16
	move.b	#0,45(a0)
	move.b	65(a0),$6ef14
l00db	move.w	#0,d7
	move.b	(a0),d7
	btst	#5,d7
	beq	l00dd
	subq.b	#1,31(a0)
	bcc	l00dc
	move.b	26(a0),31(a0)
	movea.l	32(a0),a2
	cmpi.b	#$ff,1(a2)
	beq	l00dc
	addq.l	#1,32(a0)
	move.b	1(a2),40(a0)
l00dc	move.b	40(a0),30(a0)
l00dd	move.b	29(a0),d0
	add.b	$6f7ba,d0
	subq.b	#1,53(a0)
	bcc	l00e0
	move.b	52(a0),53(a0)
	movea.l	20(a0),a1
	move.b	(a1),d1
	cmpi.b	#$8f,d1
	bne	l00de
	movea.l	16(a0),a1
	move.b	(a1),d1
l00de	cmpi.b	#$8e,d1
	bne	l00df
	lea	-1(a1),a1
	move.b	(a1),d1
l00df	addq.l	#1,a1
	move.l	a1,20(a0)
	add.b	d1,d0
l00e0	add.b	63(a0),d0
	jsr	$6fc04
	tst.b	d0
	bpl	l00e1
	moveq	#$60,d0
l00e1	movea.l	#$6e41c,a1
	add.b	d0,d0
	move.b	d0,d1
	andi.l	#$ff,d1
	adda.l	d1,a1
	move.w	(a1),d0
	move.b	44(a0),d6
	btst	#6,d6
	beq	l00ea
	cmpi.b	#1,49(a0)
	beq	l00e2
	subq.b	#1,48(a0)
	bcc	l00ea
l00e2	move.b	#1,49(a0)
	move.b	d1,d5
	move.b	41(a0),d4
	lsl.b	#1,d4
	move.b	43(a0),d1
	btst	#7,d6
	beq	l00e3
	btst	#0,d7
	bne	l00e6
l00e3	btst	#5,d6
	bne	l00e4
	sub.b	42(a0),d1
	bcc	l00e5
	bset	#5,44(a0)
	move.w	#0,d1
	bra	l00e5
l00e4	add.b	42(a0),d1
	cmp.b	d4,d1
	bcs	l00e5
	bclr	#5,44(a0)
	move.b	d4,d1
l00e5	move.b	d1,43(a0)
l00e6	lsr.b	#1,d4
	sub.b	d4,d1
	bcc	l00e7
	subi.w	#$100,d1
l00e7	addi.b	#$a0,d5
	bcs	l00e9
l00e8	lsl.w	#1,d1
	addi.b	#$18,d5
	bcc	l00e8
l00e9	add.w	d1,d0
l00ea	eori.b	#1,d7
	move.b	d7,(a0)
	btst	#2,d7
	beq	l00ef
	move.b	25(a0),d4
	subq.b	#1,d4
	bne	l00ee
	move.w	#0,d6
	move.b	24(a0),d6
	move.b	d6,d3
	bpl	l00eb
	addi.w	#$ff00,d6
l00eb	add.w	14(a0),d6
	move.w	d6,14(a0)
	tst.b	108(a0)
	bpl	l00ed
	move.b	109(a0),d5
	move.b	d5,d1
	add.b	63(a0),d5
	add.b	$6f7ba,d5
	add.b	d5,d5
	andi.l	#$ff,d5
	movea.l	#$6e41c,a1
	adda.l	d5,a1
	move.w	(a1),d5
	move.w	d0,d2
	add.w	d6,d2
	tst.b	d3
	bpl	l00ec
	cmp.w	d5,d2
	bcc	l00ed
	clr.w	14(a0)
	move.w	d5,d0
	move.b	d1,29(a0)
	bclr	#2,(a0)
	bra	l00ef
l00ec	cmp.w	d5,d2
	bcs	l00ed
	clr.w	14(a0)
	move.w	d5,d0
	move.b	d1,29(a0)
	bclr	#2,(a0)
	bra	l00ef
l00ed	add.w	d6,d0
	bra	l00ef
l00ee	move.b	d4,25(a0)
l00ef	eori.b	#$ff,d7
	move.b	$6ef16,d3
	andi.b	#3,d7
	bne	l00f0
	move.b	$6ef14,d3
	eori.b	#8,d3
	move.b	d3,$6ef15
	move.b	#7,d3
l00f0	btst	#1,54(a0)
	beq	l00f2
	addq.b	#2,55(a0)
	cmpi.b	#$40,55(a0)
	bmi	l00f1
	bclr	#1,54(a0)
l00f1	move.b	55(a0),$6ef14
l00f2	move.b	$6e413,d2
	eor.b	d2,d3
	and.b	47(a0),d3
	eor.b	d2,d3
	move.b	d3,$6e413
	btst	#2,54(a0)
	beq	l00f4
	subq.b	#1,56(a0)
	bcc	l00f4
	move.b	57(a0),56(a0)
	move.b	30(a0),d3
	cmpi.b	#0,d3
	bhi	l00f3
	bclr	#2,54(a0)
	bra	l00f4
l00f3	subq.b	#1,30(a0)
l00f4	move.b	30(a0),d1
	add.b	97(a0),d1
	bpl	l00f5
	clr.b	d1
l00f5	cmpi.b	#$f,d1
	bcc.s	l00f6
	cmpi.b	#$1f,d1
	bcs.s	l00f6
	move.b	#$f,d1
l00f6	rts

	move.b	#0,$6f7bc
	move.l	d0,d6
	lsl.w	#2,d0
	movea.l	$6fd44,a3
	adda.l	d0,a3
	movea.l	(a3),a3
	movea.l	#$6edc2,a1
	movea.l	a3,a0
	move.w	#2,d7
l00f7	move.b	#1,27(a1)
	move.b	#0,(a1)
	move.b	#0,44(a1)
	clr.b	110(a1)
	clr.b	63(a1)
	movea.l	(a0)+,a2
	move.l	a2,6(a1)
	move.l	#1,10(a1)
	moveq	#0,d0
	move.b	(a2),d0
	cmpi.b	#$80,d0
	bne	l00f8
	move.b	1(a2),63(a1)
	move.l	#3,10(a1)
	move.b	2(a2),d0
l00f8	asl.w	#2,d0
	movea.l	$6fd40,a3
	movea.l	0(a3,d0.l),a3
	move.l	a3,2(a1)
	move.b	#3,83(a1)
	adda.l	#$70,a1
	dbf	d7,l00f7
	move.b	#1,$6ef12
	move.b	#1,$6f7bc
	move.b	#0,$6f7ba
	move.l	$6fd3c,$6f7b6
	move.l	$6fd48,$6f7c8
	move.b	#2,$484.l
	movea.l	#$7011c,a0
	adda.l	d6,a0
	move.b	(a0),$6ef13
	move.b	#$f4,$6f7ba
	clr.b	$6ef28
	rts

	move.b	$6ef28,d3
	btst	#6,62(a0)
	beq	l00f9
	andi.b	#2,d3
	beq	l00f9
	addi.b	#$c,d0
l00f9	btst	#1,80(a0)
	bne	l00fa
	btst	#7,62(a0)
	beq	l00fa
	subq.b	#1,86(a0)
	cmpi.b	#0,86(a0)
	bne	l00fa
	move.b	87(a0),86(a0)
	movea.l	88(a0),a2
	cmpi.b	#$ff,1(a2)
	beq	l00fa
	add.b	(a2)+,d0
	move.l	a2,88(a0)
l00fa	movea.l	88(a0),a2
	btst	#1,80(a0)
	beq	l00fd
	btst	#7,62(a0)
	beq	l00fd
	subq.b	#1,86(a0)
	cmpi.b	#0,86(a0)
	bne	l00fb
	move.b	87(a0),86(a0)
	cmpi.b	#$ff,1(a2)
	beq	l00fb
	move.b	(a2)+,d0
	bra	l00fc
l00fb	move.b	(a2),d0
l00fc	move.l	a2,88(a0)
l00fd	btst	#5,62(a0)
	beq	l00fe
	move.b	29(a0),d4
	cmpi.b	#1,d4
	beq	l00fe
	subi.b	#1,29(a0)
	subi.b	#1,d0
l00fe	btst	#1,96(a0)
	beq	l0104
	subq.b	#1,106(a0)
	bne	l0104
	move.b	107(a0),106(a0)
l00ff	movea.l	98(a0),a2
	cmpi.b	#$fe,(a2)
	bne	l0100
	move.l	102(a0),98(a0)
	bra.s	l00ff
l0100	cmpi.b	#$ff,(a2)
	bne	l0101
	bclr	#1,96(a0)
	bra	l0104
l0101	move.b	(a2)+,d6
	cmpi.b	#$80,d6
	beq	l0102
	move.b	d6,42(a0)
l0102	move.b	(a2)+,d6
	cmpi.b	#$80,d6
	beq	l0103
	move.b	d6,41(a0)
	move.b	d6,43(a0)
l0103	move.b	(a2)+,d6
	move.b	d6,97(a0)
	move.b	(a2)+,d6
	add.b	d6,d0
	move.l	a2,98(a0)
l0104	rts

	dc.b	0,2,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	0,6,0,' ',0,6,4,0
	dc.b	0,6,2,$a0,0,0,0,0
	dc.b	0,6,0,$a6,0,6,0,$b6
	dc.b	0,6,0,$c6,0,6,0,$d6
	dc.b	0,6,0,$e6,0,6,0,$f6
	dc.b	0,6,1,6,0,6,1,$16
	dc.b	0,6,1,'&',0,6,1,'6'
	dc.b	0,6,1,'F',0,6,1,'V'
	dc.b	0,6,1,'f',0,6,1,'v'
	dc.b	0,6,1,$86,0,6,1,$96
	dc.b	0,6,1,$a6,0,6,1,$b6
	dc.b	0,6,1,$c6,0,6,1,$d6
	dc.b	0,6,1,$e6,0,6,1,$f6
	dc.b	0,6,2,6,0,6,2,$16
	dc.b	0,6,2,'&',0,6,2,'6'
	dc.b	0,6,2,'F',0,6,2,'V'
	dc.b	0,6,2,'f',0,6,2,'v'
	dc.b	0,6,2,$86,0,6,2,$96
	dc.b	0,0,3,3,2,1,$f,$e
	dc.b	$e,$e,$e,$e,$d,$c,$b,$ff
	dc.b	1,$a0,1,1,1,1,$f,$f
	dc.b	$f,$e,$d,$a,9,8,7,$ff
	dc.b	0,']',0,0,1,1,$f,$e
	dc.b	$d,$c,$b,$a,9,8,7,$ff
	dc.b	0,0,'c',1,0,1,$f,$e
	dc.b	$ff,$ff,$ff,$ff,$b,$a,$ff,$ff
	dc.b	0,'^',0,0,0,3,$f,$e
	dc.b	$d,$c,$b,$a,9,8,7,$ff
	dc.b	0,0,4,3,1,3,$f,$e
	dc.b	$d,$c,$b,$a,9,8,7,$ff
	dc.b	'$',$f,1,1,1,1,$f,$f
	dc.b	$f,$f,$a,9,7,3,0,$ff
	dc.b	0,'^',0,0,0,1,$f,$e
	dc.b	$d,$c,$b,$ff,$ff,$ff,$ff,$ff
	dc.b	0,0,1,0,4,2,$f,$f
	dc.b	$e,0,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	0,0,3,3,3,1,$e,$e
	dc.b	$f,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	0,'^',1,0,0,4,$f,$e
	dc.b	$e,$d,$ff,$a,9,8,7,$ff
	dc.b	0,'^',2,0,2,1,$f,$e
	dc.b	$c,$a,8,6,4,2,0,$ff
	dc.b	0,0,1,2,1,1,$f,$e
	dc.b	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	0,0,2,5,0,1,$f,$f
	dc.b	$f,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	dc.b	0,0,1,2,$a,1,$e,$f
	dc.b	$e,$e,$ff,0,0,0,0,0
	dc.b	4,0,0,0,0,1,$d,0
	dcb.w	2
	dc.b	$ff,0,0,0,8,0,1,2
	dc.b	1,1,$c,$d,$c,$ff,0,0
	dcb.w	2
	dc.b	$10,0,1,1,1,0,$a,$c
	dc.b	0,$ff,$b,$a,9,8,7,$ff
	dc.b	0,0,1,1,1,1,$e,$d
	dc.b	$c,$a,$b,$a,9,8,7,$ff
	dc.b	0,0,2,2,1,3,3,5
	dc.b	7,$a,$c,$d,$e,$d,$c,$ff
	dc.b	0,0,1,2,1,1,$e,$d
	dc.b	$c,$a,$b,$a,9,8,7,$ff
	dcb.w	2
	dc.b	0,1,$e,$d,$c,$a,$b,$a
	dc.b	9,8,7,$ff,0,0,0,0
	dc.b	0,1,$e,$d,$c,$a,$b,$a
	dc.b	9,8,7,$ff,0,0,1,1
	dc.b	1,1,$f,$e,$ff,$a,$b,$a
	dc.b	9,8,7,$ff,0,0,0,0
	dc.b	0,1,$e,$d,$c,$a,$b,$a
	dc.b	9,8,7,$ff,0,0,0,0
	dc.b	0,1,$e,$d,$c,$a,$b,$a
	dc.b	9,8,7,$ff,0,'Z',0,0
	dc.b	0,1,$e,$d,$c,$a,$b,$a
	dc.b	9,8,7,$ff,0,'Z',0,0
	dc.b	0,1,$e,$d,$c,$a,$b,$a
	dc.b	9,8,7,$ff,0,0,1,1
	dc.b	1,1,$b,$c,$b,$b,$a,$a
	dc.b	$a,9,9,$ff,0,0,0,0
	dc.b	0,1,$e,$d,$c,$a,$b,$a
	dc.b	9,8,7,$ff,0,0,0,0
	dc.b	0,1,$e,$d,$c,$a,$b,$a
	dc.b	9,8,7,$ff,0,9,0,0
	dc.b	0,1,$e,$d,$c,$a,$b,$a
	dc.b	9,8,7,$ff,0,6,3,0
	dc.b	0,6,3,$c,0,6,3,$18
	dc.b	0,6,3,'$',0,6,3,'0'
	dcb.w	38
	dc.b	0,6,$a,0,0,6,$a,$90
	dc.b	0,6,$b,' ',0,6,$11,$f
	dc.b	0,6,$a,$90,0,6,$b,' '
	dc.b	0,6,$11,$f,0,6,$11,$e7
	dc.b	0,6,$10,'o',0,6,$10,'t'
	dc.b	0,6,$11,'*',0,6,$12,$f
	dc.b	0,6,$11,$f,$d1,6,$a,$d7
	dc.b	0,6,$a,$dc,0,0,0,0
	dcb.w	88
	dc.b	3,3,2,2,3,3,3,3
	dc.b	3,3,0,0,0,0,0,0
	dc.b	0,6,4,$a8,0,6,4,$ac
	dc.b	0,6,4,$d8,0,6,5,4
	dc.b	0,6,5,'7',0,6,5,'W'
	dc.b	0,6,5,$87,0,6,5,$b3
	dc.b	0,6,5,$d1,0,6,5,$f8
	dc.b	0,6,6,$1e,0,6,6,'J'
	dc.b	0,6,6,'v',0,6,6,$8b
	dc.b	0,6,6,$9f,0,6,6,$b3
	dc.b	0,6,6,$d8,0,6,6,$fd
	dc.b	0,6,7,$1b,0,6,7,$27
	dc.b	0,6,7,'3',0,6,7,'S'
	dc.b	0,6,7,'~',0,6,7,$88
	dc.b	0,6,7,$9b,0,6,7,$b1
	dc.b	0,6,7,$ca,0,6,7,$e6
	dc.b	0,6,8,0,0,6,8,$1f
	dc.b	0,6,8,'$',0,6,8,'E'
	dc.b	0,6,8,'p',0,6,8,'}'
	dc.b	0,6,8,$9a,0,6,8,$b7
	dc.b	0,6,8,$d2,0,6,8,$ed
	dc.b	0,6,9,'!',0,6,9,'['
	dc.b	0,6,9,'p',0,6,9,$80
	dc.b	$ff,$90,0,$87,$e3,$82,$c6,'1'
	dc.b	$90,0,$c1,'3',$e1,$90,0,$c6
	dc.b	'1',$e3,'1',$e1,'11',$e3,$c1
	dc.b	'3',$90,0,$e1,$c6,'111'
	dc.b	'1',$e3,$c1,'33',$e1,$c6,'1'
	dc.b	'1',$e3,'1',$c1,'3',$c6,'1',$87
	dc.b	$e3,$82,$c0,$1b,$e1,$27,$1b,$e3
	dc.b	'%',$e1,$27,$1b,$e3,'*',$e1,$1b
	dc.b	$e3,$27,$e1,$1b,'%',$27,$e3,$1b
	dc.b	$e1,$27,'%',$90,0,$1b,$e3,'%'
	dc.b	$e1,$90,0,$1b,$e3,'%',$e1,$27
	dc.b	$27,$1b,'%',$87,$e3,$90,0,$82
	dc.b	$c2,'?B?',$e1,'DED'
	dc.b	'B',$e3,'DB',$e7,'D',$e3,'?'
	dc.b	$e1,'=:',$ef,$90,0,$e3,$90
	dc.b	0,'?B?',$e1,'DED'
	dc.b	'B',$e3,'?B',$e7,'D',$e1,'?'
	dc.b	'=B?',$ef,$90,0,$87,$e3
	dc.b	$82,$c0,$1b,$16,$19,$16,$e5,$1b
	dc.b	$e3,$1b,$90,0,$e1,$1b,$90,0
	dc.b	$1b,$e3,$16,$19,$16,$e5,$1b,$e1
	dc.b	$1b,$90,0,$1b,$e3,$19,$87,$e3
	dc.b	$82,$c6,'1',$e1,'11',$e3,$c1
	dc.b	'3',$90,0,$c6,'1',$e1,$90,0
	dc.b	'1',$e3,$c1,'3',$e1,$90,0,$e3
	dc.b	'3',$e1,$c6,'1',$e3,'1',$c1,'3'
	dc.b	$c6,'1',$c1,'3',$e1,$90,0,$e3
	dc.b	'3',$e1,$c6,'1',$e3,'1',$87,$ff
	dc.b	$82,$c4,'8',$e1,$90,0,'6',$e3
	dc.b	'88:',$e5,'63',$e3,'3'
	dc.b	$e7,$90,0,$e3,$c5,'33',$e5
	dc.b	'3',$e7,'3',$e3,'3',$e1,'3',$e3
	dc.b	'333',$e5,'3',$e1,'3',$e7
	dc.b	$90,0,$87,$e3,$1b,$27,$27,$e1
	dc.b	'!"""%',$e7,'"',$e5
	dc.b	$27,$e3,'%',$e1,'""',$e3,'%'
	dc.b	$e1,' ! ',$1e,' ',$e5,$1e
	dc.b	$87,$e3,$82,$c6,'1',$c1,'33'
	dc.b	$c6,'11',$e1,'1',$e3,$c1,'3'
	dc.b	$90,0,'3',$e1,$90,0,$e3,$c6
	dc.b	'111',$e1,$c1,'333'
	dc.b	'33',$e3,'3',$e1,$90,0,$87
	dc.b	$ff,$82,$c7,'=',$8e,$e7,'=',$e3
	dc.b	$90,0,$e1,';=@@',$e3
	dc.b	'?=;',$ff,'8',$e1,$90,0
	dc.b	'D',$e3,'DD',$e1,'BCD'
	dc.b	'D',$e3,'CB@',$87,$e3,$82
	dc.b	$c0,$19,$e1,'%',$19,$e3,'#',$e1
	dc.b	'%',$19,$e3,'(',$e1,$19,$e3,'%'
	dc.b	$e1,$19,'#%',$e3,$19,$e1,'%'
	dc.b	'#',$90,0,$19,$e3,'#',$e1,$90
	dc.b	0,$19,$e3,'#',$e1,'%%',$19
	dc.b	'#',$87,$e3,$82,$c0,$14,$e1,' '
	dc.b	$14,$e3,$1e,$e1,' ',$14,$e3,'#'
	dc.b	$e1,$14,$e3,' ',$e1,$14,$1e,' '
	dc.b	$e3,$14,$e1,' ',$1e,$90,0,$14
	dc.b	$e3,$1e,$e1,$90,0,$14,$e3,$1e
	dc.b	$e1,'  ',$14,$1e,$87,$e7,$82
	dc.b	$c7,'?',$e1,'BBA?',$ff
	dc.b	$90,0,$e7,$90,0,$e1,'??'
	dc.b	'@A',$87,$e3,'F',$fd,$90,0
	dc.b	$e1,'F',$e3,'FF',$e1,'DE'
	dc.b	'FF',$e3,'EDB',$87,$e3
	dc.b	$16,$fd,$90,0,$e1,'"',$e3,'"'
	dc.b	'"',$e1,' !""',$e3,'!'
	dc.b	' ',$1e,$87,$e1,$82,$c6,'11'
	dc.b	'11111111'
	dc.b	'111111',$c6,'1'
	dc.b	'1',$e3,'1',$c1,'3',$c6,'1',$e1
	dc.b	$c1,'33',$e3,'333',$87
	dc.b	$e0,$82,$c5,'-',$e2,'.',$e3,'1'
	dc.b	$ee,$90,0,$e0,'.',$e3,'-,'
	dc.b	$ff,$90,0,$e0,'-',$e2,'.',$e3
	dc.b	'1',$ee,$90,0,$e0,'2',$e3,'3'
	dc.b	'1',$ff,$90,0,$87,$e3,$82,$c6
	dc.b	'1',$c1,'3',$c6,'1',$90,0,'1'
	dc.b	$90,0,'1',$c1,'3',$c6,'1',$90
	dc.b	0,'1',$90,0,'1',$90,0,'1'
	dc.b	$c1,'3',$87,$e7,$82,$c0,$1b,$1b
	dc.b	$1b,$1b,$1b,$1b,$1b,$1b,$87,$e7
	dc.b	$82,$c0,$19,$19,$19,$19,$16,$16
	dc.b	$16,$16,$87,$e0,'-',$e2,'.',$e3
	dc.b	'1',$ee,$90,0,$e0,'.',$e3,'-'
	dc.b	',',$f7,$90,0,$e3,'*',$e7,','
	dc.b	',,,,,,,',$e3
	dc.b	$90,0,$87,$e0,'-',$e2,'.',$e3
	dc.b	'1',$ee,$90,0,$e0,'.',$e3,'-'
	dc.b	',',$f7,$90,0,$e3,'13',$e7
	dc.b	'666',$e3,':',$e7,'88'
	dc.b	'88::::::'
	dc.b	'::',$e3,$90,0,$87,$e7,$12
	dc.b	$12,$12,$12,$14,$14,$14,$14,$87
	dc.b	$e3,$82,$c6,'1',$90,0,'1',$90
	dc.b	0,$e1,'111111'
	dc.b	'11',$87,$e3,$82,$c6,'1',$90
	dc.b	0,$c1,'3',$e1,$c6,'111'
	dc.b	'1',$e3,'1',$e1,'11',$e3,'1'
	dc.b	$87,$e3,$82,$c6,'1',$e1,'11'
	dc.b	$e3,$c1,'3',$c6,'1',$e1,'1',$e3
	dc.b	$c1,'3',$e1,$c6,'1111'
	dc.b	'1',$87,$e7,$90,0,$e3,$82,$c5
	dc.b	$27,$27,$e5,$27,$e7,$27,$e3,$27
	dc.b	$e1,$27,$e3,$27,$27,$27,$e5,$27
	dc.b	$e1,$27,$e7,$90,0,$87,$e3,$82
	dc.b	$c0,$1b,$e1,$27,$1b,$e3,'%',$e1
	dc.b	$27,$1b,$e7,'*',$c8,0,0,0
	dc.b	0,$e1,$c0,$27,$1b,'%',$27,$87
	dc.b	$e3,$82,$c0,$1b,$e1,$27,$1b,'%'
	dc.b	$e3,$27,$e1,$1b,$e7,$c8,0,0
	dc.b	0,0,$e1,$90,0,$e3,$c0,$27
	dc.b	$90,0,$27,$e1,$90,0,$87,$e0
	dc.b	$82,$c9,'-',$87,$e2,'.',$e3,'1'
	dc.b	$ee,$90,0,$e0,'.',$e3,'-,'
	dc.b	$ff,$90,0,$e0,'-',$e2,'.',$e3
	dc.b	'1',$ee,$90,0,$e0,'2',$e3,'3'
	dc.b	'1',$ff,$90,0,$87,$e3,$82,$c6
	dc.b	'11',$c1,'3',$c6,'1',$e1,'1'
	dc.b	$e3,'1',$e1,'1',$e3,$c1,'3',$e1
	dc.b	$90,0,$c6,'1',$e3,$c6,'11'
	dc.b	$c1,'3',$c6,'1',$e1,'1',$e3,'1'
	dc.b	$e1,'1',$e3,$c1,'3',$c6,'1',$87
	dc.b	$e3,$82,$c0,$1b,$16,$19,$16,$e5
	dc.b	$1b,$1b,$e3,$1b,$87,$e1,'6',$e3
	dc.b	'6666',$e1,'6',$e3,'6'
	dc.b	'53533',$e1,'13'
	dc.b	$e3,$90,0,'1',$e1,'112'
	dc.b	'3',$87,$e1,'3',$e3,'333'
	dc.b	'3',$e1,'3',$e3,'3101'
	dc.b	'00',$e1,'10',$e3,$90,0
	dc.b	',',$e1,',,-.',$87,$e1
	dc.b	'9',$e9,'9',$e1,'9',$e9,'9',$e3
	dc.b	'86666',$e1,'86'
	dc.b	$e3,$90,0,'1',$e1,'112'
	dc.b	'3',$87,$e1,'6',$e9,'6',$e1,'6'
	dc.b	$e9,'6',$e3,'53333'
	dc.b	$e1,'53',$e3,$90,0,',',$e1
	dc.b	',,-.',$87,$e7,$82,$c4
	dc.b	'6',$90,0,$e3,'6',$e1,$90,0
	dc.b	$e3,'5',$e1,$90,0,$e3,'6',$ef
	dc.b	$90,0,$e3,'6',$e1,$90,0,$e3
	dc.b	'5',$e1,$90,0,$e3,'6',$ef,$90
	dc.b	0,$e3,'6',$e1,$90,0,$e3,'5'
	dc.b	$e1,$90,0,$ff,'3',$e3,$90,0
	dc.b	$87,$e7,$82,$c0,'3',$c8,0,$e3
	dc.b	$c0,'3',$e1,$90,0,$e3,'1',$e1
	dc.b	$90,0,$e3,'3',$e7,$c8,0,0
	dc.b	$e3,$c0,'3',$e1,$90,0,$e3,'1'
	dc.b	$e1,$90,0,$e3,'3',$e7,$c8,0
	dc.b	0,$e3,$c0,'3',$e1,$90,0,$e3
	dc.b	'1',$e1,$90,0,$eb,'/',$e7,'/'
	dc.b	'//',$87,$e3,$82,$c6,'1',$90
	dc.b	0,'1',$90,0,$c1,'3',$e1,$90
	dc.b	0,'3',$e3,$c6,'1',$c1,'3',$87
	dc.b	$e3,$82,$c6,'1',$90,0,'1',$90
	dc.b	0,'1',$90,0,'1',$90,0,$87
	dc.b	$e1,$82,$cf,'00000'
	dc.b	'00000000'
	dc.b	'00000000'
	dc.b	'00000000'
	dc.b	'000',$87,0,0,0,0
	dcb.w	44
	dc.b	$80,0,0,0,0,0,0,0
	dc.b	0,0,'))))))'
	dc.b	7,3,3,6,6,$80,$18,$80
	dc.b	0,3,3,6,6,$80,$18,7
	dc.b	$80,0,9,9,$80,3,$c,$80
	dc.b	0,$c,$80,3,$c,$80,0,9
	dc.b	9,$80,3,$c,$80,0,$c,$80
	dc.b	3,$c,$80,0,$d,$80,0,$1a
	dc.b	0,0,$10,$14,$10,$15,$80,0
	dc.b	$1a,0,0,0,0,0,0,$80
	dc.b	2,9,0,0,$80,$c,$1a,$1a
	dcb.w	3
	dc.b	$80,3,$c,$80,$f,$1a,$1a,$80
	dc.b	$18,7,$80,$c,$1d,$1e,$14,$1d
	dc.b	$1e,$15,7,$80,0,'!',$1a,'!'
	dc.b	$1a,'#',$1a,'#',$1a,0,0,'%'
	dc.b	'%',$80,$c,$1a,$1a,'!!',$1a
	dc.b	$80,$18,7,$ff,0,0,0,0
	dc.b	0,0,'(((',$17,'(('
	dc.b	'(',$17,'(((',$17,$17,$18
	dc.b	$17,$18,1,1,8,1,1,1
	dc.b	1,5,5,5,5,1,1,1
	dc.b	1,5,5,5,5,8,1,1
	dc.b	1,1,1,1,1,1,1,1
	dc.b	1,1,1,1,$f,$11,$11,$11
	dc.b	$11,$11,$11,$11,$11,$11,$11,$f
	dc.b	$17,$17,$17,$18,$17,$17,$17,$19
	dc.b	$17,$17,$17,$19,$17,$17,$f,$17
	dc.b	$17,$17,$18,$17,$17,$17,$19,$18
	dc.b	$18,$18,$19,$17,$17,8,$1f,$1f
	dc.b	$1f,$1f,$1f,$1f,$1f,$1f,$f,8
	dc.b	$17,$18,1,$17,$18,1,$17,$18
	dc.b	1,$17,$18,1,$11,$27,$27,$27
	dc.b	$17,$27,$27,$27,$17,1,1,$18
	dc.b	$18,$19,$18,1,8,$ff,0,0
	dcb.w	7
	dc.b	'))',$1b,$1b,2,2,2,2
	dc.b	7,2,2,2,2,$80,5,4
	dc.b	4,$80,7,4,4,$80,0,2
	dc.b	2,2,2,$80,5,4,4,$80
	dc.b	7,4,4,$80,0,7,$a,$b
	dc.b	$a,$b,$80,3,2,$80,0,2
	dc.b	$80,3,2,$80,0,$a,$b,$a
	dc.b	$b,$80,3,2,$80,0,2,$80
	dc.b	3,2,$80,0,$e,$80,0,$12
	dc.b	$12,$12,$12,$12,$13,$12,$12,$12
	dc.b	$16,$e,$1b,$1c,$1b,$1c,$1b,$1c
	dc.b	$1b,$e,$1b,$1c,$1b,$1c,$1b,$1c
	dc.b	$1b,7,$80,0,4,4,4,$80
	dc.b	5,4,$80,0,4,4,4,$80
	dc.b	3,' ',$80,5,' ',$80,0,$e
	dc.b	7,'"',2,'"',2,'$',2,'$'
	dc.b	2,$12,'&&',2,2,$80,$c
	dc.b	'""',$80,0,2,7,$ff,0
	
L_Top_Rasters_Table:			; @ = TOP_RASTERS_TBL	$2354A
	dc.b	0,'.',0,'N',0,'n',0,$8e
	dc.b	0,$ae,0,$ce,0,$ee,2,$ec
	dc.b	4,$ea,6,$e8,8,$e6,$a,$e4
	dc.b	$c,$e2,$e,$e0,$e,$c2,$e,$a4
	dc.b	$e,$86,$e,'h',$e,'J',$e,','
	dc.b	$e,$e,$e,$c,$e,$a,$e,8
	dc.b	$e,6,$e,4,$e,2,$e,0
	dc.b	$c,2,$a,4,8,6,6,8
	dc.b	4,$a,2,$c,0,$e,0,$e
	dc.b	0,'.',0,'N',0,'n',0,$8e
	dc.b	0,$ae,0,$ce,0,$ee,2,$ec
	dc.b	4,$ea,6,$e8,8,$e6,$a,$e4
	dc.b	$c,$e2,$e,$e0,$e,$c2,$e,$a4
	dc.b	$e,$86,$e,'h',$e,'J',$e,','
	dc.b	$ee,$e,3,'3',4,'D',4,'D'
	dc.b	4,'D',5,'U',4,'D',5,'U'
	dc.b	5,'U',6,'f',5,'U',6,'f'
	dc.b	6,'f',7,'w',6,'f',7,'w'
	dc.b	7,'w',8,$88,7,'w',8,$88
	dc.b	8,$88,9,$99,8,$88,9,$99
	dc.b	9,$99,$a,$aa,9,$99,$a,$aa
	dc.b	$a,$aa,$b,$bb,$a,$aa,$b,$bb
	dc.b	$b,$bb,$c,$cc,$b,$bb,$c,$cc
	dc.b	$c,$cc,$d,$dd,$c,$cc,$d,$dd
	dc.b	$d,$dd,$e,$ee,$d,$dd,$e,$ee
	dc.b	$e,$ee

	; Union Wizz coders logo
	; 320 * 90 * 1 bitplane = 3600 bytes
L_wizz_logo:	dc.b	0,0,0,0,0,0		; @ = WIZZ_LOGO		$23614	
	dcb.w	169
	dc.b	0,$c,0,0,0,0,0,0
	dcb.w	6
	dc.b	7,0,1,$80,'`',0,1,$f8
	dc.b	$1e,0,0,0,0,0,0,$1f
	dc.b	$f0,$e,0,0,0,'x',0,0
	dc.b	0,0,$1f,$81,$e0,0,0,0
	dcb.w	4
	dc.b	$1f,$c0,1,$80,$f0,0,7,$fc
	dc.b	'?',$80,1,$e0,0,0,0,$7f
	dc.b	$fc,'>',0,0,1,$e0,3,$e0
	dc.b	0,0,$7f,$c3,$f8,0,$1e,0
	dcb.w	4
	dc.b	'#',$e0,7,$e1,$f8,0,$1f,$fe
	dc.b	'x',$c0,7,$f8,0,0,1,$ff
	dc.b	$ff,$fc,0,0,7,$80,6,'x'
	dc.b	0,1,$ff,$e7,$8c,0,$7f,$80
	dcb.w	4
	dc.b	'A',$f0,7,$e1,$fe,0,'?',$ff
	dc.b	'x@',$f,$fc,2,0,3,$ff
	dc.b	$ff,$f8,$c,0,$1f,0,$c,'|'
	dc.b	0,3,$ff,$f7,$84,0,$ff,$c0
	dc.b	' ',0,0,0,0,0,0,0
	dc.b	0,$f8,1,$87,$7f,$e0,'|?'
	dc.b	$fc,0,$1f,$fe,6,0,7,1
	dc.b	$ff,$e0,'8',0,'|',0,'8o'
	dc.b	0,7,$c3,$ff,$c0,1,$ff,$e0
	dc.b	'`',0,0,0,0,0,0,0
	dc.b	0,$fc,1,$fc,$7f,$e0,$f0,$1f
	dc.b	$fe,0,'?',$ff,$cc,0,$e,0
	dc.b	'?',$80,$f0,0,$f8,0,'xg'
	dc.b	$c0,$f,1,$ff,$e0,3,$ff,$fc
	dc.b	$c0,0,0,0,0,0,0,0
	dc.b	0,'|',1,$fc,$7f,$c0,$e0,$e
	dc.b	$7f,0,'0',$7f,$fc,0,8,0
	dc.b	$f,3,$e0,1,$f0,0,$f0,'c'
	dc.b	$e0,$e,0,$e7,$f0,3,7,$ff
	dc.b	$c0,0,0,0,0,0,0,0
	dc.b	0,'~',1,$f0,$7f,$81,$c0,$e
	dc.b	$1f,$80,' ',$7f,$f8,0,8,0
	dc.b	6,7,$80,1,$e0,1,$e0,'a'
	dc.b	$f0,$1c,0,$e1,$f8,2,7,$ff
	dc.b	$80,0,0,0,0,0,0,0
	dc.b	0,'~',1,$80,$7f,1,$c0,6
	dc.b	$f,$c0,'@o',$f0,0,4,0
	dc.b	'x',$f,0,3,$e0,3,$e0,'`'
	dc.b	$f8,$1c,0,'`',$fc,4,6,$ff
	dcb.w	4
	dc.b	0,'~',1,$80,$7f,1,$c0,6
	dc.b	$f,$e0,$80,'g',$e0,0,0,0
	dc.b	'x',$1f,0,3,$c0,7,$c0,'`'
	dc.b	$fc,$1c,0,'`',$fe,8,6,'~'
	dcb.w	4
	dc.b	0,'~',1,$80,'~',1,$e1,6
	dc.b	7,$f0,0,'`',0,0,0,1
	dc.b	$f8,$1e,0,7,$c0,$1f,$c0,'`'
	dc.b	'|',$1e,$10,'`',$7f,0,6,0
	dcb.w	4
	dc.b	0,'~',1,$80,'~',0,$f3,6
	dc.b	7,$f0,0,'`',0,0,0,1
	dc.b	$f8,'>',0,7,$c0,$7f,$80,'`'
	dc.b	'~',$f,'0`',$7f,0,6,0
	dcb.w	4
	dc.b	$1f,$fe,1,$80,'~',0,$fe,6
	dc.b	3,$f8,0,'`',0,0,0,$7f
	dc.b	$f8,'>',0,$f,$81,$ff,$80,'`'
	dc.b	'~',$f,$e0,'`?',$80,6,0
	dcb.w	4
	dc.b	'?',$fe,1,$80,'~',0,'x',6
	dc.b	3,$f8,0,'`',0,0,0,$ff
	dc.b	$f8,'~',0,$f,$87,$ff,$80,'`'
	dc.b	$7f,7,$80,'`?',$80,6,0
	dcb.w	4
	dc.b	'g',$fe,1,$80,'~',0,0,6
	dc.b	1,$fc,0,'`',0,0,0,$87
	dc.b	$f8,'~',0,$1f,$8c,$1f,$80,'`'
	dc.b	$7f,0,0,'`',$1f,$c0,6,0
	dcb.w	4
l0105	bsr.s	l0105
	dc.b	1,$80,'~',0,0,6,1,$fc
	dc.b	0,'`',0,0,0,$c3,$f8,'~'
	dc.b	0,$1f,$88,$1f,$80,'`',$7f,0
	dc.b	0,'`',$1f,$c0,6,0,0,0
	dcb.w	3
	dc.b	'`~',1,$ff,$fe,0,1,$fe
	dc.b	0,$fe,0,'`',0,0,0,'!'
	dc.b	$f8,'~',0,$1f,$88,$1f,$80,'`'
	dc.b	$7f,$80,$1f,$e0,$f,$e0,6,0
	dcb.w	4
	dc.b	'`~',1,$ff,$fe,0,3,$fe
	dc.b	0,$fe,0,'`',0,0,0,1
	dc.b	$f8,'~',0,'?',$84,$1f,$80,'`'
	dc.b	$7f,$80,'?',$e0,$f,$e0,6,0
	dcb.w	4
	dc.b	'0~',1,$80,'~',0,6,6
	dc.b	0,$7f,$10,'`',0,0,0,1
	dc.b	$f8,'~',0,'?',$80,$1f,$80,$7f
	dc.b	$ff,$80,'``',7,$f1,6,0
	dcb.w	4
	dc.b	8,'~',1,$80,'~',0,6,6
	dc.b	0,$7f,'p`',0,0,0,1
	dc.b	$f8,'~',0,'?',$80,$1f,$80,$7f
	dc.b	$ff,$80,'``',7,$f7,6,0
	dcb.w	4
	dc.b	0,'~',1,$80,'~',0,6,6
	dc.b	0,'?',$e0,'`',0,0,0,$f
	dc.b	$f8,'~',0,$7f,$80,$1f,$80,'`'
	dc.b	$7f,$80,'``',3,$fe,6,0
	dcb.w	4
	dc.b	0,'~',1,$80,'~',0,7,6
	dc.b	0,$1f,$e0,'`',0,0,0,'?'
	dc.b	$f8,'~',0,$7f,$80,$1f,$80,'`'
	dc.b	$7f,$80,'p`',1,$fe,6,0
	dcb.w	4
	dc.b	7,$fe,1,$80,'~',0,1,$86
	dc.b	0,$7f,$80,'`',0,0,0,'#'
	dc.b	$f8,'~',0,$7f,$80,$ff,$80,$7f
	dc.b	$ff,$80,$18,'`',7,$f8,6,0
	dcb.w	4
	dc.b	$f,$fe,1,$80,'~',0,0,$86
	dc.b	0,$7f,$80,'`',0,0,0,$11
	dc.b	$f8,'~',0,$7f,$83,$ff,$80,$7f
	dc.b	$ff,$80,8,'`',7,$f8,6,0
	dcb.w	4
	dc.b	$18,'~',1,$ff,$fe,0,0,6
	dc.b	0,$c7,$e0,'`',0,0,0,9
	dc.b	$f8,'~',0,$7f,$82,'?',$80,'`'
	dc.b	$7f,$80,0,'`',$c,'~',6,0
	dcb.w	4
	dc.b	$18,'~',1,$ff,$fe,0,0,6
	dc.b	0,$87,$e0,'`',0,0,0,1
	dc.b	$f8,'~',0,$7f,$81,$1f,$80,'`'
	dc.b	$7f,$80,0,'`',8,'~',6,0
	dcb.w	4
	dc.b	$c,'~',1,$80,'~',0,0,'~'
	dc.b	0,7,$f0,'`',0,0,0,1
	dc.b	$f8,'~',0,$7f,$80,$9f,$80,'`'
	dc.b	$7f,$80,7,$e0,0,$7f,6,0
	dcb.w	4
	dc.b	2,'|',1,$80,'~',0,0,$fe
	dc.b	0,7,$f0,'`',0,0,0,1
	dc.b	$f8,'~',0,$7f,$80,$1f,0,'`'
	dc.b	$7f,$80,$f,$e0,0,$7f,6,0
	dcb.w	4
	dc.b	0,'|',1,$80,'~',0,0,$86
	dc.b	0,3,$f8,'`',0,0,0,1
	dc.b	$f8,'~',0,'?',$80,$1f,0,'`'
	dc.b	$7f,0,8,'`',0,'?',$86,0
	dcb.w	4
	dc.b	0,'x',1,$80,'~',0,0,$c6
	dc.b	0,3,$f8,'`',0,0,0,1
	dc.b	$f8,'~',0,'?',$c0,$1e,0,'`'
	dc.b	$ff,0,$c,'`',0,'?',$86,0
	dcb.w	4
	dc.b	1,$e0,0,0,'~',0,0,'F'
	dc.b	0,1,$fc,'`',0,0,0,1
	dc.b	$e0,$7f,0,$1f,$c0,'>',0,'`'
	dc.b	$fe,0,4,'`',0,$1f,$c6,0
	dcb.w	4
	dc.b	1,$80,0,0,$fe,0,0,'&'
	dc.b	0,1,$fc,'`',0,0,0,1
	dc.b	$e0,$7f,0,$1f,$e0,'<',0,'a'
	dc.b	$fe,0,2,'`',0,$1f,$c6,0
	dcb.w	4
	dc.b	0,$7f,$f8,0,$fe,0,0,7
	dc.b	$e1,$80,$fe,'`',0,0,7,$f8
	dc.b	0,$ff,0,$f,$e0,'p',0,'a'
	dc.b	$fc,0,0,'~',$18,$f,$e6,0
	dcb.w	4
	dc.b	3,$ff,$ff,0,$fe,0,0,$1f
	dc.b	$e3,$80,$7f,'`',0,0,$1f,$fe
	dc.b	0,$ff,$80,$f,$f0,0,0,'c'
	dc.b	$fc,0,1,$fe,'8',7,$f6,0
	dcb.w	4
	dc.b	$1f,$ff,$ff,$e1,$fe,0,0,$7f
	dc.b	$ff,0,$7f,$e0,$10,0,$7f,$ff
	dc.b	$c1,$ff,$80,7,$f8,0,0,'c'
	dc.b	$f8,0,7,$ff,$f0,7,$fe,1
	dcb.w	4
	dc.b	'?',$ff,$ff,$f9,$ff,0,1,$ff
	dc.b	$fe,0,'?',$e0,' ',1,$f8,'?'
	dc.b	$f3,$ff,0,3,$fc,0,0,'g'
	dc.b	$f8,0,$1f,$ff,$e0,3,$fe,2
	dcb.w	4
	dc.b	$7f,3,$ff,$fe,$7f,$e0,7,$ff
	dc.b	$fc,0,$1f,$f8,'`',7,$c0,7
	dc.b	$ff,$f8,0,3,$ff,0,0,$7f
	dc.b	$f0,0,$7f,$ff,$c0,1,$ff,$86
	dcb.w	4
	dc.b	$f8,0,$7f,$fe,$1f,$e0,$f,$ff
	dc.b	$f8,0,$f,$fc,$c0,$f,0,1
	dc.b	$ff,$c0,0,0,$ff,$e0,0,$7f
	dc.b	$e0,0,$ff,$ff,$80,0,$ff,$cc
	dcb.w	4
	dc.b	$e0,0,$1f,$fc,$f,$c0,$1f,$80
	dc.b	'q',0,3,$ff,$c0,$c,0,0
	dc.b	$fe,0,0,0,$7f,$ff,$ff,$ff
	dc.b	$80,1,$f8,7,$10,0,'?',$fc
	dcb.w	3
	dc.b	0,1,$c0,0,7,$e0,7,$c0
	dc.b	'<',0,$e0,$c0,1,$ff,$80,$18
	dc.b	0,0,'x',0,0,0,$1f,$ff
	dc.b	$ff,$fe,0,3,$c0,$e,$c,0
	dc.b	$1f,$f8,0,0,0,0,0,0
	dc.b	0,1,$80,0,3,$c0,3,$80
	dc.b	'8',1,$c0,'`',0,$7f,0,$18
	dc.b	0,0,'`',0,0,0,7,$ff
	dc.b	$ff,$f0,0,3,$80,$1c,6,0
	dc.b	7,$f0,0,0,0,0,0,0
	dc.b	0,1,$80,0,1,$80,1,$80
	dc.b	'8',1,$80,$e0,0,$1e,0,$18
	dc.b	0,0,'@',0,0,0,0,$ff
	dc.b	$ff,$e0,0,3,$80,$18,$e,0
	dc.b	1,$e0,0,0,0,0,0,0
	dc.b	0,1,$80,'@',0,0,0,0
	dc.b	'8',0,1,$c0,0,0,0,$18
	dc.b	$10,0,0,0,0,0,0,0
	dc.b	0,'`',0,3,$80,0,$1c,0
	dcb.w	4
	dc.b	0,1,$c0,' ',0,0,0,0
	dc.b	$1c,0,3,$80,0,0,0,$1c
	dc.b	8,0,0,0,0,0,0,0
	dc.b	0,'`',0,1,$c0,0,'8',0
	dcb.w	5
	dc.b	$f0,$18,0,0,0,0,$e,0
	dc.b	7,0,0,0,0,$f,4,0
	dcb.w	3
	dc.b	1,$f8,0,0,$e0,0,'p',0
	dcb.w	5
	dc.b	'|',$18,0,0,0,0,7,$80
	dc.b	$1e,0,0,0,0,3,$cc,0
	dcb.w	3
	dc.b	1,$f8,0,0,'x',1,$e0,0
	dcb.w	5
	dc.b	'?',$f0,0,0,0,0,3,$ff
	dc.b	$f8,0,0,0,0,0,$f8,0
	dcb.w	3
	dc.b	0,'`',0,0,'?',$ff,$80,0
	dcb.w	5
	dc.b	7,$c0,0,0,0,0,0,$7f
	dc.b	$e0,0,0,0,0,0,0,0
	dcb.w	3
	dc.b	0,'`',0,0,7,$fe,0,0
	dcb.w	67
	dc.b	$ff,'?',$c1,$f7,$f9,$ff,$f8,0
	dc.b	0,'~',$10,1,$f8,3,$ff,$e0
	dc.b	$f,$ff,$f8,$ff,$fc,0,'?',$84
	dcb.w	8
	dc.b	'?',$cf,$f0,'}',$ff,$ff,$fe,0
	dc.b	1,$9f,$b4,7,'~',0,$ff,$f8
	dc.b	3,$ff,$fe,'?',$ff,0,$cf,$ed
	dcb.w	8
	dc.b	$1f,7,$c0,'P',$f9,'`|',0
	dc.b	6,'`|',$1d,$c3,$80,'|',6
	dc.b	1,$e0,$e,$1f,1,$c1,$b0,'?'
	dcb.w	8
	dc.b	$1e,7,$80,'P',$f1,'@|',0
	dc.b	$d,$80,'<?',1,$e0,'x',3
	dc.b	$81,$e0,$a,$1e,1,$e3,'`',$1f
	dcb.w	8
	dc.b	$e,3,$80,$90,$f0,'@',$f8,0
	dc.b	$1b,0,$1c,'~',0,$f0,'x',1
	dc.b	$c1,$e0,2,$1e,0,$e3,$c0,$f
	dcb.w	8
	dc.b	$f,3,$c0,$a0,$f0,1,$f8,0
	dc.b	'6',0,$14,$fc,0,'xx',1
	dc.b	$e1,$e0,0,$1e,0,$f3,$c0,7
	dcb.w	8
	dc.b	$f,3,$c0,$a0,$f0,1,$f0,0
	dc.b	'<',0,4,$f8,0,'|x',0
	dc.b	$e1,$e0,0,$1e,0,$f3,$c0,5
	dcb.w	8
	dc.b	7,5,$c1,' ',$f0,3,$e0,0
	dc.b	'l',0,1,$f8,0,'<x',0
	dc.b	$f1,$e0,' ',$1e,1,$b3,$e0,1
	dcb.w	8
	dc.b	7,$85,$e1,'@',$f0,3,$e0,0
	dc.b	'x',0,1,$f0,0,'>x',0
	dc.b	$f1,$e0,'(',$1e,1,$e1,$fc,0
	dcb.w	8
	dc.b	7,$85,$e1,'@',$f0,7,$c0,0
	dc.b	'x',0,1,$f0,0,'>x',0
	dc.b	$f1,$e0,'h',$1e,7,'`',$7f,$80
	dcb.w	8
	dc.b	3,$89,$e2,'@',$f0,$f,$c0,0
	dc.b	'x',0,1,$f0,0,'>x',0
	dc.b	$f1,$ff,$f8,$1f,$fd,$c0,$1f,$e0
	dcb.w	8
	dc.b	3,$ca,$f2,$80,$f0,$f,$80,0
	dc.b	'x',0,1,$f0,0,'>x',0
	dc.b	$f1,$ff,$f8,$1e,$ff,0,7,$f8
	dcb.w	8
	dc.b	3,$ca,$f2,$80,$f0,$1f,0,0
	dc.b	'x',0,1,$f0,0,'>x',0
	dc.b	$f1,$e0,'8',$1e,$e,0,0,$fe
	dcb.w	8
	dc.b	1,$d2,'t',$80,$f0,$1f,0,0
	dc.b	'x',0,1,$f0,0,'>x',0
	dc.b	$f1,$e0,'(',$1e,7,0,0,$1f
	dcb.w	8
	dc.b	1,$f4,'}',0,$f0,'>',0,0
	dc.b	'8',0,0,$f0,0,'~x',0
	dc.b	$f1,$e0,8,$1e,3,$84,0,$f
	dcb.w	8
	dc.b	1,$f4,'}',0,$f0,'~',0,0
	dc.b	'<',0,0,$f8,0,'|x',1
	dc.b	$b1,$e0,0,$1e,3,$c5,0,7
	dc.b	$80,0,0,0,0,0,0,0
	dcb.w	4
	dc.b	0,$e4,'9',0,$f0,'|',0,0
	dc.b	$1c,0,8,'x',0,$fc,'x',1
	dc.b	$e1,$e0,0,$1e,1,$c7,0,7
	dc.b	$80,0,0,0,0,0,0,0
	dcb.w	4
	dc.b	0,$f8,'>',0,$f0,$f8,4,0
	dc.b	$e,0,$12,'<',1,$f8,'x',3
	dc.b	'a',$e0,4,$1e,0,$e7,$80,7
	dc.b	$80,0,0,0,0,0,0,0
	dcb.w	4
	dc.b	0,$f8,'>',0,$f0,$f8,5,0
	dc.b	7,0,'d',$1e,3,$f0,'x',6
	dc.b	$c1,$e0,5,$1e,0,$f7,$c0,$d
	dc.b	$80,0,0,0,0,0,0,0
	dcb.w	4
	dc.b	0,'x',$1e,1,$f1,$f0,$d,0
	dc.b	1,$81,$98,7,$e,$e0,$f8,$19
	dc.b	$83,$e0,$d,'>',0,'w',$e0,$1b
	dcb.w	8
	dc.b	0,'P',$14,7,$fb,$ff,$ff,0
	dc.b	0,'~`',1,$fb,$83,$ff,$e6
	dc.b	$f,$ff,$ff,$ff,0,'}',$bf,$e6
	dcb.w	8
	dc.b	0,$10,4,1,$fe,$ff,$ff,0
	dc.b	0,$1f,$80,0,'~',0,$ff,$f8
	dc.b	3,$ff,$ff,'?',$c0,$1f,$f,$f8
	dcb.w	164
zuend:	end
