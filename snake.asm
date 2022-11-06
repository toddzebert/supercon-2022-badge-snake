; borrowed from
; symbols for special registers
Page        EQU 0xf0
Clock       EQU 0xf1
Sync        EQU 0xf2
WrFlags     EQU 0xf3
  LedsOff   EQU 3
  MatrixOff EQU 2
  InOutPos  EQU 1
  RxTxPos   EQU 0
RdFlags     EQU 0xf4
  Vflag     EQU 1
  UserSync  EQU 0       ; cleared after read
SerCtl      EQU 0xf5
  RxError   EQU 3       ; cleared after read
SerLow      EQU 0xf6
SerHigh     EQU 0xf7
Received    EQU 0xf8
AutoOff     EQU 0xf9
OutB        EQU 0xfa
InB         EQU 0xfb
KeyStatus   EQU 0xfc
  AltPress  EQU 3
  AnyPress  EQU 2
  LastPress EQU 1
  JustPress EQU 0       ; cleared after read
KeyReg      EQU 0xfd
Dimmer      EQU 0xfe
Random      EQU 0xff



; registers...
; r0 - special!
; r1 - misc
; r2
; r3
; r4
; r5
; r6
; r7
; r8
; r9 - overall state

; pages...
; 00 - regs
; 01 - stack
; 02 & 03 - display
; 04-06 (X), 07-09 (Y) snake position list
; Ax:
;  0-4 bit positions map
; Bx:
;  0 snake head HON - high offset, only 0-2
;  1 snake head LON - low offset
;  2 snake tail HON - high offset, only 0-2
;  3 snake tail LON - low offset
; Cx, Dx avail....
; E0 - Alt reg.
; F0 - Spec func

snakeHeadHON EQU 0xb
snakeHeadLON EQU 0
snakeTailHON EQU 0xb
snakeTailLON EQU 0
snakeListXHN EQU 0x4
snakeListYHN EQU 0x7
snakeInitX EQU 7
snakeInitY EQU 0xa

displayPage EQU 2
displayPagePlus1 EQU 3

state_alive EQU 1
state_dead EQU 2
state_snacked EQU 3

bitPosMapHN EQU 0xA
bitPosMapLN EQU 0x0

pixelClear EQU 0
pixelSet EQU 1
pixelToggle EQU 2
pixelRead EQU 3

init:
; go to display page
mov r0, displayPage
mov [0xF0], r0

; slow down a bit, I guess?
mov r0,7
mov [0xF1], r0

; prep.
gosub init_bit_pos

; set initial state
mov r9, state_alive

; @TODO draw initial snake.
; @TODO draw initial food

main:
; @TODO check for user input
; @TODO check display boundary
; @TODO check self-crash
; if dead, skip ahead...?
; @TODO check if gets a snack, set state
; @TODO if snaked, get new snack coords; reset fash...
; @TODO move head, and erase tail
;   @TODO unless in snacked state; reset state

; @TODO loop back to main

; @DEBUG is just test
; set "params"
mov r5, 1 ; x
mov r6, 1 ; y
mov r7, pixelSet
; draw it
gosub pixel

ret r0, 1 ; end main

; @TODO
draw_initial_snake:

gosub draw_initial_snake_head

gosub move_snake_head_unsafe
gosub move_snake_head_unsafe
gosub move_snake_head_unsafe

ret r0, 1; end draw_initial_snake


; @TODO doc....
;
move_snake_head_unsafe:


; @TODO ....

ret r0, 1; end move_snake_head_unsafe


; @TODO doc....
draw_initial_snake_head:
; set the first X
mov r1, snakeListXHN
mov r2, 0; this is the first, 0-indexed
mov r0, snakeInitX
mov [r1: r2], r0; record X
mov r5, r0; save X for drawing (later)
; set the first Y
mov r1, snakeListYHN
mov r2, 0; this is the first, 0-indexed
mov r0, snakeInitY
mov [r1: r2], r0; record Y
mov r6, r0; save X for drawing (later)
; prepare to draw
mov r0, pixelSet
mov r7, r0
; draw
gosub pixel
; done here
ret r0, 1; end draw_initial_snake_head


init_bit_pos:
; basics.
; @TODO should make this a loop.
mov r1, bitPosMapHN
mov r2, bitPosMapLN
; 0
mov r0,0 ; 0b0000
mov [r1:r2], r0 ; [r1 + r2]
; 1
mov r0, 1 ; 0b0001
inc r2 ; = 01
mov [r1:r2], r0
; 2
mov r0, 2 ; 0b0010
inc r2 ; = 02
mov [r1:r2], r0
; 3
mov r0, 4 ; 0b0100
inc r2 ; = 03
mov [r1:r2], r0
; 4
mov r0, 8 ; 0b1000
inc r2 ; = 04
mov [r1:r2], r0

ret r0, 1


;**
 ;* Change pixel status
 ;* Inputs:
 ;* r5, x AKA modified bit position (set below)
 ;* r6, y AKA pixel bank ln (set below)
 ;* r7, type:
 ;*    00 clear
 ;*    01 set
 ;*    02 toggle
 ;*    03 read
 ;*
 ;* Internal:
 ;* ~~~~r3, bit position
 ;* r3, pixel bank hn (derived from MSB of x)
 ;* r4, display nibble
 ;*
 ;* Output:
 ;* r8, display mask, and later RETURN???
pixel:

; figure out which display bank, based on x >= 8
; default to "left" page.
; NOTE "page" + 1 is LEFT of "page"!!!
mov r3, displayPagePlus1 ; pixel hn
; copy x to work on it.
mov r0, r5
and r0, 8 ; 0b1000
cp r0, 8
; If  (R0) = N, set Z. Otherwise, reset Z. ZN is reverse.
skip NZ, 0x01 ; skip one line...
; must be pg 2.
mov r3, displayPagePlus1
; moving on from skip...
; copy x, again
mov r0, r5
; now clear the high bit.
and r0, 0b0111; reverse of 0b1000
; so now r0 is the bit position, and save it (overwritting original x).
mov r5, r0
; end of x processing.
; get the display nibble...
mov r0, [r3:r6]
; , and save it.
mov r4, r0
; get map mask
mov r1, bitPosMapHN
mov r2, bitPosMapLN
; add to ln the modified bit position
add r2, r5
; get mapped mask.
mov r0, [r1:r2]
; save r0's mask.
mov r8, r0
; end of display nibble/mask code.
; now let's determine which "type" of action, by copying to r0 for cp's.
mov r0, r7

pixel_op3: ; "read"
cp r0, 3 ; @TODO make this is symbol?
; If  (R0) = N, set Z. Otherwise, reset Z. NZ is reverse.
skip nz, 1
jr 8
; it's 3, so "read".
; load r0 with display nibble with mask.
mov r0, r4
; and with mask
and r0, r8
; default return (assume pixel not set), now that r8 "free".
mov r8, 0;
; If  (R0) > N  or  (R0) = N, set C. Otherwise, reset C.
cp r0, 1
; this is true if r0 is 0
skip nc, 1
; pixel is set.
mov r8, 1;
; done. @TODO or should I just use return value?
ret r0, 1;

pixel_op2: ; "toggle"s
cp r0, 2
; If  (R0) = N, set Z. Otherwise, reset Z. NZ is reverse.
skip nz, 1
jr 2 ; @TODO
; it's 2, so "toggle".
; @TODO skipping for now
ret r0, 0

pixel_op1: ; "set"
cp r0, 1
; If  (R0) = N, set Z. Otherwise, reset Z. NZ is reverse.
skip nz, 1
jr 5
; it's 1, so "set".
; OR curr display nibble with mask
or r4, r8
; move to r0
mov r0, r4
; write back value
mov [r3:r6], r0
; done
ret r0, 1

pixel_op0: ; "clear"
cp r0, 1
; If  (R0) = N, set Z. Otherwise, reset Z. nz is reverse.
skip nz, 1
jr 6
; it's 1, so "clear".
; move display mask to r0
mov r0, r8
; invert mask
xor r0, 0xf
; and to unset the mask
and r0, r4
; write back value
mov [r3:r6], r0
; done
ret r0, 1

pixel_done:
ret r0, 0
