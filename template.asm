;	set game state memory location
.equ    HEAD_X,         0x1000  ; Snake head's position on x
.equ    HEAD_Y,         0x1004  ; Snake head's position on y
.equ    TAIL_X,         0x1008  ; Snake tail's position on x
.equ    TAIL_Y,         0x100C  ; Snake tail's position on Y
.equ    SCORE,          0x1010  ; Score address
.equ    GSA,            0x1014  ; Game state array address

.equ    CP_VALID,       0x1200  ; Whether the checkpoint is valid.
.equ    CP_HEAD_X,      0x1204  ; Snake head's X coordinate. (Checkpoint)
.equ    CP_HEAD_Y,      0x1208  ; Snake head's Y coordinate. (Checkpoint)
.equ    CP_TAIL_X,      0x120C  ; Snake tail's X coordinate. (Checkpoint)
.equ    CP_TAIL_Y,      0x1210  ; Snake tail's Y coordinate. (Checkpoint)
.equ    CP_SCORE,       0x1214  ; Score. (Checkpoint)
.equ    CP_GSA,         0x1218  ; GSA. (Checkpoint)

.equ    LEDS,           0x2000  ; LED address
.equ    SEVEN_SEGS,     0x1198  ; 7-segment display addresses
.equ    RANDOM_NUM,     0x2010  ; Random number generator address
.equ    BUTTONS,        0x2030  ; Buttons addresses

; button state
.equ    BUTTON_NONE,    0
.equ    BUTTON_LEFT,    1
.equ    BUTTON_UP,      2
.equ    BUTTON_DOWN,    3
.equ    BUTTON_RIGHT,   4
.equ    BUTTON_CHECKPOINT,    5

; array state
.equ    DIR_LEFT,       1       ; leftward direction
.equ    DIR_UP,         2       ; upward direction
.equ    DIR_DOWN,       3       ; downward direction
.equ    DIR_RIGHT,      4       ; rightward direction
.equ    FOOD,           5       ; food

; constants
.equ    NB_ROWS,        8       ; number of rows
.equ    NB_COLS,        12      ; number of columns
.equ    NB_CELLS,       96      ; number of cells in GSA
.equ    RET_ATE_FOOD,   1       ; return value for hit_test when food was eaten
.equ    RET_COLLISION,  2       ; return value for hit_test when a collision was detected
.equ    ARG_HUNGRY,     0       ; a0 argument for move_snake when food wasn't eaten
.equ    ARG_FED,        1       ; a0 argument for move_snake when food was eaten

; initialize stack pointer
addi    sp, zero, LEDS

; main
; arguments
;     none
;
; return values
;     This procedure should never return.
main:
    call   clear_leds
    addi  a0, zero, 5
    addi  a1, zero, 3
    call  set_pixel
    call   clear_leds
    ; TODO: Finish this procedure.

    ret


; BEGIN: clear_leds
clear_leds:
    addi		t1,		zero,		4
    addi        t2,		zero,		8
    
    stw		zero,		LEDS(zero) 
    stw		zero,		LEDS(t1)
    stw		zero,		LEDS(t2)

    jmp    ra
; END: clear_leds


; BEGIN: set_pixel
set_pixel:
    andi		t1,		a0,		3 ; x mod 4
    srli        t2,		a0,		2 ; x / 4
    slli		t2,		t2,		2
    
    ldw     t5,		LEDS(t2)
    addi    t6,		zero,	1 ; t6 -> 1
    slli		t7,		t1,		3 ; t7 -> x mod 4
    add     t7,		t7,		a1 ; t7 += y
    sll		t6,		t6,		t7 ; t6 -> 1 << (x mod 4) + y
    or      t5,		t5,		t6 ; putting the new pixel in t5
    stw		t5,		LEDS(t2) ; storing the new pixel in the right place

    jmp    ra

; END: set_pixel


; BEGIN: display_score
display_score:

; END: display_score


; BEGIN: init_game
init_game:

; END: init_game


; BEGIN: create_food
create_food:

; END: create_food


; BEGIN: hit_test
hit_test:

; END: hit_test


; BEGIN: get_input
get_input:

    ldw		t1,		BUTTONS(zero) ; state
    ldw		t2,		(BUTTONS + 4)(zero) ; edgedet
    ldw		t5,		HEAD_X(zero)
    muli	t5,		t5,		8
    ldw		t6,		HEAD_Y(zero)
    add		t6,		t5,		t6
    ldw		t7,		GSA(t6) ; direction snake head

    and		t3,		t1,		t2 ; pressed buttons
    
    slli	t4,		t3,		4
    bne		t4,		zero,	checkpoint_pres
    

    slli	t4,		t3,		3
    bne		t4,		zero,	right_pres 

    
    slli	t4,		t3,		2
    bne		t4,		zero,	down_pres
    

    slli	t4,		t3,		1
    bne		t4,		zero,	up_pres
    

    bne		t3,		zero,	left_pres

    addi	v0,		zero,	BUTTON_NONE
    jmp		ra


    checkpoint_pres: 
        addi	v0,		zero,	BUTTON_CHECKPOINT
        jmp		ra

    right_pres: 
        addi	t1,		zero,	BUTTON_LEFT
        beq		t7,		t1,		none_pres
        addi	v0,		zero,	BUTTON_RIGHT
        jmp		ra

    down_pres: 
        addi	t1,		zero,	BUTTON_UP
        beq		t7,		t1,		none_pres
        addi	v0,		zero,	BUTTON_DOWN
        jmp		ra
        
    up_pres: 
        addi	t1,		zero,	BUTTON_DOWN
        beq		t7,		t1,		none_pres
        addi	v0,	    zero,	BUTTON_UP
        jmp		ra
        
    left_pres: 
        addi	t1,		zero,	BUTTON_RIGHT
        beq		t7,		t1,		none_pres
        addi	v0,		zero,	BUTTON_LEFT
        jmp		ra
    
    none_pres:
        addi	v0,		zero,	BUTTON_NONE
        jmp		ra
    
; END: get_input


; BEGIN: draw_array
draw_array:

; END: draw_array


; BEGIN: move_snake
move_snake:

    ldw		t1,		HEAD_X(zero) ; previous x_position of our snake
    muli	t2,		t1,		8
    ldw		t3,		HEAD_Y(zero) ; previous x_position of our snake
    add		t2,		t2,		t3
    ldw		t2,		GSA(t2)  ; previous direction of our snake

    cmpne	t4,     t2,		v0
    cmpne	t5	    v0,		zero
    and		t5,		t4,		t5
    bne     t5,     zero,   update_direction
    


    update_direction:
    add     t2,    zero,   v0
    
    stw     HEAD_X(zero),   t1
    stw     HEAD_Y(zero),   t3
    
    



; END: move_snake


; BEGIN: save_checkpoint
save_checkpoint:

; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:

; END: restore_checkpoint


; BEGIN: blink_score
blink_score:

; END: blink_score
