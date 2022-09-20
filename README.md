# Reverse engineering of "Cuddly Demos – The Star-Wars Scroller by The Carebears"
This repository contains the reverse engineered source code and explanations of one of the most famous Atari ST demos

## Introduction
No doubt that if you owned an Atari ST at the end of the eighties you have been really impressed by one of the most famous megademos: The Cuddly Demos by The Carebears (TCB):
[Demozoo](https://demozoo.org/productions/76257/),
[Pouët](https://www.pouet.net/prod.php?which=3242)

Technically incredible (Syncscroll, Fullscreen) and never seen effects pushed it into all ST users memory.

One screen that I have always loved is the The Star-Wars Scroller: it is not especially technically advanced, but it was the first demo (to my knowledge) to show a scroller like in the eponym movie. 
     
![TCB_STWR_Picture](https://media.demozoo.org/screens/s/be/c7/5d46.70269.png)

And surprinsingly, this kind of scroller has not been very frequent (non exhaustive list [here](https://demozoo.org/productions/tagged/star-wars-scroller/)).

I have always loved this effect, and with my friend ZPK (from T.AL) we made a version of this effect on Falcon for the Place To Be Again in 1994 (unfortunately lost...), and I striked back during the 2020 lockdown, with a STE demo:
[Demozoo](https://demozoo.org/productions/289094/), 
[Pouët](https://www.pouet.net/prod.php?which=87771), 
[GitHub](https://github.com/Uko-TAL/TheStarWarsDemo)

I also made a tutorial about the way I have implemented it(
[GitHub](https://github.com/Uko-TAL/TheStarWarsDemo/blob/main/Tuto/StarWarsSWSC.pptx), 
[YouTube](https://youtu.be/quv_D2c6LGw)), and during a discussion on atari-forum about this tutorial, it was asked if anyone has looked into how TCB did theirs all those years back.

I haven't and didn't want to, in order not to be influenced before coding :wink: . And also I suppose that it is the habit I have taken from back in the days, i.e. to try to reproduce their demos without having access to their source code ! :smile:

But after reading a [blog article of Dbug](https://blog.defence-force.org/index.php?page=articles&ref=ART49) who reverse engineered the 3D Doc Demo (Cuddly demos too !), I have thought the time has come to dig into TCB's code !


## The disassembly process
First have a look at the Dbug's article mentioned above, as I have followed his way of proceeding, you will find more details than here. Moreover there are a lot of common tricks used by both demos (which seems logical since both are from TCB) that are explained in his article.

So I managed to find an extracted standalone version of the demo from a compilation: TCB_STWR.PRG, size = 41 560 bytes.

The file is compressed of course, and once uncompressed its size is 104 634 bytes.

Then I have used Easy Rider to get a first version of the source code, and vasm to assemble it again.


## The reverse engineering process
The source code contains several sections: the music which is relocated to $6E000 at the begin of the demo, and the demo itself that is relocated to $AC00 at the very beginning of the execution.

The code is composed of a mix of PC relative (using labels) and absolute adressing (sometimes both are used for a same address on two consecutive lines of code...) which makes the readibility difficult and the association between labels and adresses mandatory for a correct understanding.

For this, the wonderful [hrdb (Hatari Remote Debugger GUI)](http://clarets.org/steve/projects/hrdb.html) has been of a great help ! Thanks Tat for this amazing tool !

Finally I haved defined both constants (`equ`) and labels to make the source understandable.

I think it could have been simpler by using the `ORG` directive, but I did not manage to use it more than once with vasm...

I initially wanted to focus only on the Star Wars scroller part (SWSC) but it was not as straightforward as I thought, and I finally reversed, commented and explained most of the demo. Only the distorted scroller part is not fully reversed, because it doesn't seem to reveal big surprises and I had already spent too much time on this demo.

***The commented source code is [here](https://github.com/Uko-TAL/TCB-Star-Wars-Scroller-Reverse-Engineering/blob/main/TCB_STW2.S).***

  
## Overview
First things we can learn:
- there is almost 25% of CPU left
- the SW scroller part takes 280 KBytes of memory 
- the demo is refreshed at 50 Hz, but is not in the VBL code. The main code is in an infinte loop that syncs with VBL using a flag
- the VBL sets this flag, initializes rasters, and plays music
- there is an attract mode (see Dbug's article)
- it was impossible to quit the demo, either by attract mode or by space key press... I had to modify the code to restore the good behaviour; it seems this has been initially modified by the people who extracted the demo...
- the Union Wizz Coders logo is drawn only once during initialization, and appears/disappears by simple color change
- the drawing of the whole demo is made using double-buffering


## CPU Usage
Main figures of CPU usage:
```
    jsr MUSIC_ADR+4         ; Plays Music               : 11 scanlines =  5 600 cycles
    bsr clear_SWSC          ; Clear SWSC                : 26 scanlines = 13 312 cycles
    bsr clear_stars         ; Clear stars               :  6 scanlines =  3 072 cycles
    bsr clear_moving_logo   ; Clear Moving logo         :  9 scanlines =  4 608 cycles
    
    bsr draw_dist_scroller  ; Draw distorted scroller   : 70 scanlines = 35 840 cycles
    bsr draw_stars          ; Draw stars                : 19 scanlines =  9 728 cycles

    bsr draw_SWSC           ; Draw SWSC                 : 71 scanlines = 36 352 cycles
    bsr draw_moving_logo    ; Draw Moving logo          : 36 scanlines = 18 432 cycles
```


## Rasters
Rasters are implemented through daisy-chain Timer B launched at the end of the VBL. There is a first code dealing with the upper half of the screen, and another one with the gradient of the SW scroller.
For the first half there are two color tables, which are alternated at each VBL so as to produce smoother gradient of colors. 

```
        ; Rasters management
        not.w   RASTER_FLAG
        bmi.s   .vbl3
        lea BUF_RASTER_1,a6
        bra.s   .vbl4
.vbl3:  lea BUF_RASTER_2,a6

.vbl4:  ; Set Timer B
        move.l  #TIMB_CODE_ADR,$120.l   ; timb_code
        move.b  #0,$fffffa1b.w
        move.b  #2,$fffffa21.w  ; 2 lines
        move.b  #8,$fffffa1b.w  ; Event count mode
        rte


timb_code:  ; @ TIMB_CODE_ADR = $ACC4
        ; Rasters for first half screen
        move.w  (a6),$ffff8244.w
        move.w  (a6)+,$ffff8246.w
        bmi.s   timb_code_2
        rte


timb_code_2:    ; Change rasters table for SW Scroller
        move.l  #TIMB_CODE3_ADR,$120.l
        move.b  #0,$fffffa1b.w
        move.b  #2,$fffffa21.w
        move.b  #8,$fffffa1b.w
        move.l  a6,-(a7)
        move.l  a0,-(a7)
        lea SW_Scroll_Rasters_Table(pc),a0
        lea $ffff8240.w,a6
        move.l  (a0)+,(a6)+
        move.l  (a0)+,(a6)+
        move.l  (a0)+,(a6)+
        move.l  (a0)+,(a6)+
        move.l  (a0)+,(a6)+
        move.l  (a0)+,(a6)+
        move.l  (a0)+,(a6)+
        move.l  (a0)+,(a6)+
        movea.l (a7)+,a0
        movea.l (a7)+,a6
        rte

timb_code_3:    ; @ TIMB_CODE3_ADR = $AD0E
        ; Rasters for SW Scroller part
        move.w  (a6)+,$ffff8248.w
        rte
```

 
## Stars
There are 100 stars displayed on two bitplanes. The drawing is performed using a 20 iterations loop which displays 5 stars. This is quite strange not to have completely unrolled the loop, or instead directly used a 100 iterations loop...
The display is based on a precomputed included table which contains for each star:
- the delta screen address. This value is reminded in another buffer for the clearing at the next VBL
- the 2 bitplane pixel data.
So the display code is very simple. 

```
        movea.l (a3),a5         ; Data address in sequence for current star
        move.w  (a5)+,d1        ; Get delta screen address
        bmi.s   .star1_rewind   ; End of sequence for current star ?
.star1: move.l  (a5)+,d2        ; 2 bitplane data (several possible colors for stars) for current star
        or.l    d2,0(a1,d1.w)   ; Display star
        move.w  d1,(a4)+        ; Save the delta screen address in buffer for clearing at next iteration
        move.l  a5,(a3)         ; Save new data address in sequence for current star
```


## Union logo
During the demo initialisation, the letters of the `THE UNION` moving logo are X shifted and a mask is computed.
Then, as for the stars, all the display is based on a table, and each letter is displayed indepently. The addresses of the modified screen words are strored in a table so as to ease the cleaning.

```
draw_moving_logo_letter:
        ; d0 = X pos
        ; d1 = Y pos
        ; a1 = letter sprite address
        ; a3 = clear buffer
        lea BUF_LINE_OFFSET,a2
        add.w   d1,d1
        add.w   d1,d1
        movea.l 0(a2,d1.w),a0       ; offset of screen line
        adda.l  L_Log_Base(pc),a0   ; destination address
        
        move.w  d0,d1
        lsr.w   #1,d0
        andi.w  #$fff8,d0           ; X offset
        adda.w  d0,a0
        
        move.l  a0,(a3)+            ; Save address for further cleaning
        
        subq.l  #2,a0
        
        andi.w  #$f,d1              ; Get the shifted sprite address
        add.w   d1,d1
        add.w   d1,d1
        lea MOVING_LOGO_SHIFT_OFST,a2
        move.l  0(a2,d1.w),d1
        adda.l  d1,a1
        
        REPT 10 ; 10 lines
        movem.l (a0)+,d0-d3         ; Get screen data
        and.w   (a1),d0             ; Apply mask
        and.l   (a1)+,d1
        and.w   (a1),d2
        and.l   (a1)+,d3
        
        or.w    (a1)+,d0            ; Or sprite
        or.l    (a1)+,d1
        or.w    (a1)+,d2
        or.l    (a1)+,d3
        movem.l d0-d3,-(a0)         ; Write screen
        lea 160(a0),a0              ; Next screen line 
        ENDR
        
        rts
```


## Distorted scroller
Sorry, I did not reverse the whole part of this scroller :wink:
But I have commented a part of it, you can look at the source.


## Star Wars Scroller
Here we are ! Now let's see how this scroller has been implemented !

First of all, it is based on using different sizes fo each char, and displaying them at precomputed X positions. No texture mapping, nor polygon filling approaches, which seems logical in order to be efficient on a ST.

The scroller height is 82 lines. And its width varies between 288 pixels and 80 pixels. So roughly 15 000 pixels.

The font is 16 x 10 x 1 bitplane. It contains 25 characters: alphabet minus "J", "Q" anf "Z" plus dot and space.
The remove of unused letters from the font, and the limited number of symbols highlights the difficulties to limit the memory usage (280 KBytes used as mentioned before).
The font is rather small and does not allow a good definition for the "3D projection" effect. But this is hidden by the high speed of the scrolling.
Here is for example what it looks like when stopped and without rasters.

![Screenshot](https://github.com/Uko-TAL/TCB-Star-Wars-Scroller-Reverse-Engineering/blob/main/Screenshot.png)

Even the closest lines are not really readable and the more distant ones are.. euh...
But speed and rasters change everything ! Well done !

They have taken the approximation that the projection for all columns is the same (not true, but visually acceptable), so this the problem to having different char sizes and to X-preshift them.
This rescaling and X-shifting is performed during the demo initialisation and requires a final font buffer of 232 KBytes. 
This pre-processing is done with a per pixel subroutine, and is not really optimised: this explains the delay before the demo really starts.

```
swsc_rescale_pixel:
        movem.l d0-d3,-(a7)
        ; d0 = pixel index
        ; d1 = line number
        ; d4 = currently processed pixel
        ; a0 = source font address
        ; a1 = rescale font address
        ; The current routine is called for consecutive d4 pixel values, and selected d0 values
        ; this is what allows the rescaling
        lsl.b   #1,d1           ; 2 bytes per line in source data, so multiply per 2
        move.w  0(a0,d1.l),d2   ; Get the 16 pixels of the char line. Memory done for each pixel... Not very efficient
        lsl.b   #1,d1           ; 32 pixels (4 bytes) per line in destination data to handle X-shift , so multiply again per 2
        moveq   #$f,d3          ; 16 pixels
        sub.b   d0,d3           ; Reverse order for pixel index
        btst    d3,d2           ; Is the pixel set in source ?
        bne .srcPixelSet
        move.w  #$ffff,d0
        moveq   #$f,d3
        sub.b   d4,d3
        bclr    d3,d0
        and.w   d0,0(a1,d1.l)   ; Clear pixel
        bra .exit
.srcPixelSet:
        moveq   #0,d0
        moveq   #$f,d3
        sub.b   d4,d3
        bset    d3,d0
        or.w    d0,0(a1,d1.l)   ; Set Pixel
.exit:  movem.l (a7)+,d0-d3
        rts 
```


And the global pre-processing code:
```
swsc_rescale_shift_font:
            lea swsc_font(pc),a0
            lea SWSC_FONT_BUFF,a1
            moveq   #$1b,d6     ; 28 chars (alphabet + dot and space). But it seems that J, Q and Z are missing in the font data.
            ; This is managed later by a translation table
.nextChar:  moveq   #0,d4       ; Currently processed pixel index
            moveq   #$c,d3      ; 13 X-rescaling to be done
            lea swsc_rescale_table(pc),a2 ; this table contains the list of "kept" pixels wen rescaling
.nextPixel: move.b  (a2)+,d0    ; d0 contains the index of a pixel to be kept
            tst.b   d0
            bmi .nextSize       ; no more pixels to be kept for this size
            moveq   #0,d1       ; Current char line number
            moveq   #9,d5       ; Char height = 10
.nextCharLine:  bsr swsc_rescale_pixel
            addq.b  #1,d1       ; Next line
            dbf d5,.nextCharLine
            addq.l  #1,d4       ; The current pixel index has been processed for all lines, we can process the next pixel
            bra .nextPixel
.nextSize:  ; Now process the X-shifting
            lea 40(a1),a3       ; a3 = end of char in buffer
            moveq   #$e,d0      ; 16 shifts to be done
            moveq   #1,d1       ; Current shift number
.nextXShift:    moveq   #9,d7   ; Char height = 10
.nextShiftedLine:   
            moveq   #0,d2
            move.w  (a1),d2     ; Rescaled 16 pixels line
            swap    d2
            lsr.l   d1,d2       ; Shift
            move.w  d2,2(a3)
            swap    d2
            move.w  d2,(a3)
            addq.l  #4,a3       ; Next line
            addq.l  #4,a1
            dbf d7,.nextShiftedLine
            addq.l  #1,d1       ; Next shift number
            lea -40(a1),a1
            dbf d0,.nextXShift
            lea 640(a1),a1      ; Go after all shifts
            moveq   #0,d4   
            dbf d3,.nextPixel
            lea 20(a0),a0
            dbf d6,.nextChar
            rts
```


Now if we look at the main code. First the cleaning is very simple: it is done by sections of lines which have roughly the same width:
```
clear_SWSC: ; Cleans the previous displayed SWSC per sections
            moveq   #0,d1
            movea.l L_Log_Base(pc),a0
            lea 18724(a0),a0    ; Line 118 of screen + 2nd bitplan
            
            lea 56(a0),a0
            moveq   #$a,d0
.loop1:     move.w  d1,(a0)
            move.w  d1,8(a0)
            move.w  d1,16(a0)
            move.w  d1,24(a0)
            move.w  d1,32(a0)
            move.w  d1,40(a0)   ; 96 pixel for first section
            lea 160(a0),a0
            dbf d0,.loop1

...
    
            lea -8(a0),a0
            moveq   #$b,d0
.loop8:     move.w  d1,(a0)
            move.w  d1,8(a0)
            move.w  d1,16(a0)
            move.w  d1,24(a0)
            move.w  d1,32(a0)
            move.w  d1,40(a0)
            move.w  d1,48(a0)
            move.w  d1,56(a0)
            move.w  d1,64(a0)
            move.w  d1,72(a0)
            move.w  d1,80(a0)
            move.w  d1,88(a0)
            move.w  d1,96(a0)
            move.w  d1,104(a0)
            move.w  d1,112(a0)
            move.w  d1,120(a0)
            move.w  d1,128(a0)
            move.w  d1,136(a0)  ; 288 pixels at max
            lea 160(a0),a0
            dbf d0,.loop8
            rts
```

Then the display is split in two steps:
- Scroll of one line and fill one line of a buffer. This buffer contains a "non projected view" of the scrolltext containing the addresses of the font char lines (and not the bitmap itself)
- Display the "3D projection" of this buffer on the screen


Here is the code for the first part:
```
fill_SWSC_buffer_line:
            ; Fill an intermediate buffer line before displaying to screen
            ; this buffer contains a "non projected view" of the scrolltext containing the addresses of the font char lines (and not the bitmap itself)
            move.l  L_SWSC_Buf_Pos(pc),d3   ; Current position (offset) in buffer
            move.l  SWSC_BUF_POS,d2         ; Move.l d3,d2 would have been the same...
            addi.l  #$30,d2                 ; Next line (12 chars  * 4 bytes = $30) 
            cmp.l   L_SWSC_Buf_Mid(pc),d2   ; Get middle of buffer
            blt .setPos                     ; Current pos is higher the middle ?
            sub.l   L_SWSC_Buf_Mid(pc),d2   ; Go back !
.setPos:    move.l  d2,SWSC_BUF_POS

            lea SWSC_BUFFER,a5              ; a5 = begin of buffer
            lea 21120(a5),a4                ; a4 = middle of buffer
            lea SWSC_FONT_BUFF,a0           ; a0 = begin of the rescaled/X-shifted font
            lea L_swsc_text(pc),a2          ; a2 = begin of the text
            lea swsc_Translation_Table(pc),a1   ; a1 = text translation table (for chars without font items)
            move.w  L_Swsc_Text_Pos(pc),d4
            cmpi.b  #$ff,0(a2,d4.w)         ; End of text
            bne .noTextEnd
            clr.w   SWSC_TEXT_POS           ; Go to begin of text

.noTextEnd: cmpi.l  #$28,SWSC_CHAR_LINE4    ; $28 = 40 = 4*10, so are we after the last line of the chars font ?
            blt .readTextLine               ; if no, read the text line
            
            moveq   #-1,d1                  ; if yes, then we insert empty lines for spacing
            move.l  d1,0(a5,d3.w)
            move.l  d1,0(a4,d3.w)
            move.l  d1,4(a5,d3.w)
            move.l  d1,4(a4,d3.w)
            move.l  d1,8(a5,d3.w)
            move.l  d1,8(a4,d3.w)
            move.l  d1,12(a5,d3.w)
            move.l  d1,12(a4,d3.w)
            move.l  d1,16(a5,d3.w)
            move.l  d1,16(a4,d3.w)
            move.l  d1,20(a5,d3.w)
            move.l  d1,20(a4,d3.w)
            move.l  d1,24(a5,d3.w)
            move.l  d1,24(a4,d3.w)
            move.l  d1,28(a5,d3.w)
            move.l  d1,28(a4,d3.w)
            move.l  d1,32(a5,d3.w)
            move.l  d1,32(a4,d3.w)
            move.l  d1,36(a5,d3.w)
            move.l  d1,36(a4,d3.w)
            move.l  d1,40(a5,d3.w)
            move.l  d1,40(a4,d3.w)
            move.l  d1,44(a5,d3.w)
            move.l  d1,44(a4,d3.w)
            addi.l  #$30,d3
            bra .endLine
    
.readTextLine:  moveq   #$b,d7              ; 12 chars per line
.nextChar:  moveq   #0,d1
            move.b  0(a2,d4.w),d1           ; Get text char
            move.b  0(a1,d1.w),d1           ; Translate it into Font char number (for chars without font)
            lea swsc_char_to_fontaddr(pc),a3    ; Then into address for char in font buffer
            lsl.w   #2,d1
            move.l  0(a3,d1.w),d1
            addi.l  #SWSC_FONT_BUFF,d1
            add.l   L_Swsc_Char_Line4(pc),d1
            move.l  d1,0(a5,d3.w)
            move.l  d1,0(a4,d3.w)
            addq.l  #4,d3
            addq.l  #1,d4
            dbf d7,.nextChar
    
.endLine:   cmp.l   L_SWSC_Buf_Mid(pc),d3   ; Manage buffer length (as at the begin of this sub-routine)
            blt .setLineNumber
            sub.l   L_SWSC_Buf_Mid(pc),d3
    
.setLineNumber: addq.l  #4,SWSC_CHAR_LINE4  ; Next line (4 bytes per line)
            cmpi.l  #$48,SWSC_CHAR_LINE4    ; Have we inserted also 10 lines of spaces ?
            blt .exit
            subi.l  #$48,SWSC_CHAR_LINE4    ; Yes, so we go back to line 0
            addi.w  #$c,SWSC_TEXT_POS       ; And we go to next scroller line

.exit:      rts
```

And now the drawing itself. It is based on two precomputed tables (already included in the executable):

`swsc_X_size_table` : this table contains pairs of words. There are 12 pairs per line (12 chars), and for the displayed 82 lines. Each pair is composed of:
- horizontal jump (delta screen address)
- offset in rescaled/X-shifted font to get the correct char size & X position

`swsc_Y_table` :  because of the 3D projection, only some lines of the buffer are displayed on screen. This tables lists the jumps to be performed in the buffer to go to the next displayed line


```
draw_SWSC:  bsr fill_SWSC_buffer_line

            movea.l L_Log_Base(pc),a0
            lea 18724(a0),a0                ; Line #117, 3rd bitplan
            
            lea SWSC_BUFFER,a5
            lea swsc_X_size_table(pc),a3
            lea swsc_Y_table(pc),a4
            adda.l  L_SWSC_Buf_Pos(pc),a5   ; Set to current position in buffer
            
            moveq   #$51,d1                 ; 82 lines
.loopLine:  move.l  (a5)+,d3                ; d3 = char address in font
            bmi .emptyLine                  ; if -1, empty line
            
            movea.l d3,a1                   ; a1 = char address in font
            adda.w  (a3)+,a0                ; horizontal screen jump to word where the char will be displayed       
            adda.w  (a3)+,a1                ; Select char size and X preshift to be used for display
            move.w  (a1)+,d0                ; Read the first 16 pixels
            or.w    d0,(a0)                 ; OR with previous char (because chars are shifted across columns)
            move.w  (a1),d0                 ; Then read the next 16 pixels  
            or.w    d0,8(a0)                ; And OR again to screen
            
            ; Do the same thing for the next 11 chars 
            REPT 11
            adda.w  (a3)+,a0
            movea.l (a5)+,a1
            adda.w  (a3)+,a1
            move.w  (a1)+,d0
            or.w    d0,(a0)
            move.w  (a1),d0
            or.w    d0,8(a0)
            ENDR 
    
.nextLine:  adda.w  (a4)+,a5                ; Select the next line in buffer to be displayed
            dbf d1,.loopLine
            rts

.emptyLine: ; Empty line, display nothing
            ; Only update pointers
            lea 44(a5),a5                   ; Next line in buffer (4*12)
            adda.w  (a3),a0                 ; Perform X jumps on screen address
            adda.w  4(a3),a0
            adda.w  8(a3),a0
            adda.w  12(a3),a0
            adda.w  16(a3),a0
            adda.w  20(a3),a0
            adda.w  24(a3),a0
            adda.w  28(a3),a0
            adda.w  32(a3),a0
            adda.w  36(a3),a0
            adda.w  40(a3),a0
            adda.w  44(a3),a0
            lea 48(a3),a3
            bra .nextLine

```

And that's all ! There is no complexity in the code itself (no specific, or advanced optimisation). That could appear quite simple but the hidden difficulty of course comes from the choice of the method and of the sizing in order to fit in memory and to use a reasonable amount of CPU time. And by experience I know how brain-intensive and time-consuming this phase can be !!

Of course we have no access to the tools that allowed to generate all the precomputed tables. The maths are quite simple, but here again, there is a lot of hidden work.

Nice job ! 


# T.AL vs TCB
I hope that most of you have reached their objectives at this point, and have a good vision of how TCB implemented this effect.

But I think that you have also understood that my goal was not only to see how TCB did their demo, but also to compare with my implementation of the same effect: no war here, of course :wink:, but are the approaches identical ? Are there different tricks ? Or are the solutions quite similar ?

If you are interested in this further step, it may be interesting to first read the tutorial I wrote(
[GitHub](https://github.com/Uko-TAL/TheStarWarsDemo/blob/main/Tuto/StarWarsSWSC.pptx), 
[YouTube](https://youtu.be/quv_D2c6LGw)).

## Design constraints
First of course the design constraints have not been the same: fullscreen, 3D projection close to the movie, and slow scrolling.
So a size of 400 x 152 x 187 (51 600 pixels) vs. 288 x 80 x 82 (15 000 pixels). This size combined with the slow scrolling have led to a 16x24 font size (vs. 16 x 10).
Moreover, it was mandatory to have both uppercase and lowercase chars: 56 letters instead of 25. 
 
# General approach
It is also based on using different sizes fo each char, and displaying them at precomputed X positions. No surprise for me here, I do not see other solutions to be efficient.

The font is also reduced and X-shifted. Moreover the display is also split in the two same steps:
- Scroll of one line and fill one line of a buffer. This buffer contains a "non projected view" of the scrolltext containing the addresses of the font char lines (and not the bitmap itself)
- Display the "3D projection" of this buffer on the screen


## Projection method
I have also taken the approximation that the projection for all columns is the same (not true, but visually acceptable) in order to reduce the precomputed font.

But because of higer number of chars and of the size fonts, the required memory size was too huge: 990 KBytes vs. 232 KBytes.
I therefore had go a step further: letters have a lot of common lines (within a same letter, and between letters): for the 56 letters, there are only 188 different lines.

I have therefore worked on reduced elementary lines. This has the inconvienent of requiring an additional indirection, but it saves a lot of memory: at the end 135 KBytes (vs. 232 KBytes). 

I win ! :wink:

## Cleaning
Because of the display method I have used (see further), there is no need to clean the screen before displaying.

Moreover the height of the spacing between is reduced, so there are less empty lines. In order to have a fixed CPU time, I have chosen to display spaces for empty lines instead of not displaying them.

So no need for cleaning, but additional display time.

No winner...

## Display method
The display method is very close. But except for the top lines where more than 2 columns fit in 16 pixels, it is possible to avoid making an OR between columns using a bitplanes trick: in most cases, a letter of a column will have to be “split” onto two consecutive 16 pixels groups. We use a single Move.L to copy 1st part of the letter on bitplane 3 of the first 16 pixels group, then the 2nd part on bitplane 0 of next 16 pixels group. And we do the same for the next column.

This allows to save some precious cycles !

I win again ! :wink:


## CPU
There is a 3.44 ratio between the number of pixels of the two scrollers.

Since TCB's scroller requires 49 664 cycles, we can interpolate to 170 844 cycles for displaying a scroller with the same dimensions than mine.

Using the same precomputation than TCB, I would have only taken 130 900 cycles ! Yeah !

But as explained before, because of the scroller and font size, and to run on a 512 KBytes computer, I had to take the "line" approach, which finally leads to 187 000 cycles (including useless `NOP` to fit into fulscreen switches).


## Conclusion
We have finally used the same approaches, but I managed to brought additional optimisations to cope with the larger size. 
But at the end no doubt that TCB clearly won on the myth & iconic battlefields !! Thank you guys for this inspiring demo ! 


# Contact
David aka Uko from T.AL (The Arctic Land)

uko.tal@gmail.com or uko at http://www.atari-forum.com
