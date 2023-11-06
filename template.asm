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
    ; main up to draw_array
    ;stw		zero,		HEAD_X(zero)
    ;stw		zero,		HEAD_Y(zero)
    ;stw		zero,		TAIL_X(zero)
    ;stw		zero,		TAIL_Y(zero)
    ;addi	t1,		    zero,		1
    ;stw		t1,		    GSA(zero)
    ;
    ;loop1 :
    ;    call    clear_leds
    ;    call	get_input
    ;    call	move_snake
    ;    call	draw_array
    ;    jmpi		loop1
    ;game:
    ;    call		clear_leds
    ;    call		get_input
    ;    call        hit_test
    ;    beq         v0,     zero,   call_move_draw
    ;    addi        s1,     zero,   1
    ;    beq         v0,     s1,     call_create_food
    ;    addi        s1,     zero,   2
    ;    beq         v0,     s1,     end_game
;
    ;    jmpi        game
    ;    
    ;    call_create_food:
    ;        call    create_food
    ;        jmpi    game
    ;
    ;    call_move_draw:
    ;        call       move_snake
    ;        call       draw_array
    ;        jmpi       game  
;
    ;    end_game:
    ;        ret

    stw		zero,		CP_VALID(zero)
    addi	s5,		zero,		5       ; s1 <- checkpoint button return value
    addi    s1,     zero,       1       
    addi    s2,     zero,       2       
    
    init_game_label:
        call		init_game
    
    get_input_label:
        call        wait_procedure
        call        get_input
    
    beq         v0,     s1,     restore_checkpoint_label
    
    call        hit_test
    
    beq         v0,     s1,   eat_update_label
    beq         v0,     s2,   init_game_label
    
    call        move_snake
    
    clear_and_draw_label:
        call        clear_leds
        call        draw_array
        br          get_input_label 
        
    restore_checkpoint_label:
        call        restore_checkpoint
        beq		    v0,		zero,		get_input
        br		    blink_score_label

    eat_update_label:
        ldw		    s6,		SCORE(zero)
        addi		s6,		s6,		1
        stw		    s6,		SCORE(zero)
        
        call        display_score
        call        move_snake
        call        create_food
        call        save_checkpoint
        beq		    v0,		zero,		clear_and_draw_label
        br          blink_score_label
    
    blink_score_label:
        call        blink_score
        br          clear_and_draw_label

    ; TODO: Finish this procedure.

    ret

wait_procedure:
    addi		t1,		zero,		30 000 000
    wait_loop:
        addi	t1,		t1,		-1
        bne		t1,		zero,		wait_loop
        jmp		ra
    

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

    ldw		t1,		SCORE(zero)
    cmpgei  t2,		t1,		100
    bne		t2,		zero,		up_to_hundred
    add		t2,		zero,		zero
    ldw     t6,		digit_map(zero)

    div_10_loop:
        cmrlti      t3,		t1,		10
        bne		    t3,		zero,		div_10_loop_end
        addi		t1,		t1,		-10
        addi        t2,		t2,		1
        br          div_10_loop

    div_10_loop_end:
        slli        t2,		t2,		2
        slli        t1,		t1,		2
        ldw        t4,		digit_map(t1)
        ldw        t5,		digit_map(t2)
        
        stw        t4,		SEVEN_SEGS(zero)
        stw        t5,		SEVEN_SEGS+4(zero)
        stw        t6,	SEVEN_SEGS+8(zero)
        stw        t6,	SEVEN_SEGS+12(zero)

    up_to_hundred:
        stw        t6,		SEVEN_SEGS(zero)
        stw        t6,		SEVEN_SEGS+4 (zero)
        stw        t6,	    SEVEN_SEGS+8(zero)
        stw        t6,		SEVEN_SEGS+12(zero)
        

; END: display_score


; BEGIN: init_game
init_game:

    stw		zero,		HEAD_X(zero)
    stw		zero,		HEAD_Y(zero)
    stw		zero,		TAIL_X(zero)
    stw		zero,		TAIL_Y(zero)
    addi	t1,		    zero,		4
    stw		t1,		    GSA(zero)
    stw		zero,		SCORE(zero)
    
    call    create_food
    call	draw_array

; END: init_game


; BEGIN: create_food
create_food:

    generate_random:
        ldw		    t1,		RANDOM_NUM(zero)
        andi		t1,		t1,		255 ;  take lowest byte
        cmplti		t2,		t1,		96  ;  check if is in GSA bound
        beq		    t2,		zero,		generate_random
        slli		t1,		t1,		2
        ldw		    t2,		GSA(t1)     ;  check if GSA position is occupied
        bne		    t2,		zero,		generate_random
    
    addi		t2,		zero,		FOOD
    stw		    t2,		GSA(t1)

    jmp		ra
    
; END: create_food


; BEGIN: hit_test
hit_test:

    ldw		t1,		HEAD_X(zero) ; previous x_position of our snake
    slli	t2,		t1,		3
    ldw		t3,		HEAD_Y(zero) ; previous y_position of our snake
    add		t2,		t2,		t3
    slli	t2,		t2,		2
    ldw		t2,		GSA(t2)  ; previous direction of our snake

    addi	t5,		zero,		1
    
    cmpeqi	t4,		t2,		DIR_LEFT
    beq		t4,		t5,		left
    cmpeqi	t4,		t2,		DIR_RIGHT
    beq		t4,		t5,		right
    cmpeqi	t4,		t2,		DIR_UP
    beq		t4,		t5,		up
    cmpeqi	t4,		t2,		DIR_DOWN
    beq		t4,		t5,		move_head_down 
        
    left:
        addi		t1,		t1,		-1
        jmpi		test_collision  
        
    right:
        addi        t1,		t1,		1
        jmpi	    test_collision

    up:
        addi        t3,     t3,     -1
        jmpi	    test_collision

    down:
        addi        t3,		t3,		-1
        jmpi	    test_collision

    test_collision:
        cmpeqi         t2,   t1,    12
        cmpeqi         t4,   t1,    -1
        or             t2,   t2,    t4

        cmpeqi         t4,   t3,    -1
        cmpeqi         t5,   t3,    8
        or             t4,   t4,    t5

        or             t2,   t2,    t4
        bne            t2,   zero,  collision_end_game

        slli	t2,		t1,		3
        add		t2,		t2,		t3
        slli	t2,		t2,		2
        ldw		t2,		GSA(t2)
        beq		t2,		zero,	no_collision
        addi    t4,     zero,   FOOD
        beq     t2,		t4,		eat_food
        br		collision_end_game
        
    collision_end_game:
        addi		   v0,		zero,		2
        jmp		       ra

    eat_food:
        addi		   v0,		zero,		1
        jmp		       ra

    no_collision:
        addi		   v0,		zero,		0
        jmp		       ra
    
; END: hit_test


; BEGIN: get_input
get_input:

    ldw		t1,		BUTTONS(zero) ; t1 <- buttons state
    xori    t1,     t1,     31 ; inverse active low buttons
    ldw		t2,		(BUTTONS + 4)(zero) ; t2 <- edgedet
    ldw		t5,		HEAD_X(zero)
    slli	t5,	    t5,		3 
    ldw		t6,		HEAD_Y(zero)
    add		t6,		t5,		t6
    slli    t6,     t6,     2
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

    addi		t3,		zero,		384

    loop:
        addi	t3,		t3,		-4
        ldw		t2,		GSA(t3)
        bne		t2,		zero,		pixel
        bne		t3,		zero,		loop
        jmp		ra
        
        
    pixel:
        srli	t4,		t3,		5
        andi	t5,		t3,		28
        add     a0,     zero,   t4
        add     a1,     zero,   t5
        call		set_pixel
        jmpi		loop

; END: draw_array


; BEGIN: move_snake
move_snake:

    ldw		t1,		HEAD_X(zero) ; previous x_position of our snake
    slli	t2,		t1,		3
    ldw		t3,		HEAD_Y(zero) ; previous y_position of our snake
    add		t2,		t2,		t3
    slli	t2,		t2,		2
    ldw		t2,		GSA(t2)  ; previous direction of our snake

    cmpne	t4,	    v0,		zero
    cmpnei	t5,		v0,		BUTTON_CHECKPOINT
    and		t5,		t4,		t5
    beq     t5,     zero,   update_direction
    add     t2,    zero,   v0
    jmpi	update_direction
    

    update_direction:
        addi	t5,		zero,		1
        
        cmpeqi	t4,		t2,		DIR_LEFT
        beq		t4,		t5,		move_head_left

        cmpeqi	t4,		t2,		DIR_RIGHT
        beq		t4,		t5,		move_head_right
        
        cmpeqi	t4,		t2,		DIR_UP
        beq		t4,		t5,		move_head_up

        cmpeqi	t4,		t2,		DIR_DOWN
        beq		t4,		t5,		move_head_down
        
        
    move_head_left:
        addi		t1,		t1,		-1
        stw		    t1,		HEAD_X(zero)
        jmpi		update_head_GSA
        
        
    move_head_right:
        addi      t1,		t1,		1
        stw       t1,		HEAD_X(zero)
        jmpi	  update_head_GSA

    move_head_up:
        addi       t3,     t3,     -1
        stw		   t3,		HEAD_Y(zero)
        jmpi	   update_head_GSA

    move_head_down:
        addi      t3,		t3,		-1
        stw       t3,		HEAD_Y(zero)
        jmpi	  update_head_GSA

    update_head_GSA:
        slli	t4,		t1,		3
        add		t4,		t4,		t3
        slli	t4,		t4,		2
        stw		t2,		GSA(t4)
        beq		a0,		zero,	update_tail
        jmpi		return
        
    update_tail:
        ldw		t1,		TAIL_X(zero) ; previous x_position of our tail
        slli	t2,		t1,		3
        ldw		t3,		TAIL_Y(zero) ; previous y_position of our tail
        add		t4,		t2,		t3
        slli	t4,		t4,		2
        ldw		t2,		GSA(t4)  ; previous direction of our tail
        stw		zero,	GSA(t4)
        
        
        addi	t5,		zero,		1
        
        cmpeqi	t4,		t2,		DIR_LEFT
        beq		t4,		t5,		move_tail_left

        cmpeqi	t4,		t2,		DIR_RIGHT
        beq		t4,		t5,		move_tail_right
        
        cmpeqi	t4,		t2,		DIR_UP
        beq		t4,		t5,		move_tail_up

        cmpeqi	t4,		t2,		DIR_DOWN
        beq		t4,		t5,		move_tail_down

    move_tail_left:
        addi		t1,		t1,		-1
        stw		    t1,		TAIL_X(zero)
        jmpi		update_tail_GSA
        
        
    move_tail_right:
        addi       t1,		t1,		1
        stw        t1,		TAIL_X(zero)
        jmpi	   update_tail_GSA

    move_tail_up:
        addi       t3,     t3,     -1
        stw		   t3,		TAIL_Y(zero)
        jmpi		update_tail_GSA

    move_tail_down:
        addi      t3,		t3,		-1
        stw       t3,		TAIL_Y(zero)
        jmpi	    update_tail_GSA

    update_tail_GSA:
        slli	t4,		t1,		3
        add		t4,		t4,		t3
        slli		t4,		t4,		2
        stw		t2,		GSA(t4)
        jmpi		return
        
    return:
        jmp		ra

; END: move_snake


; BEGIN: save_checkpoint
save_checkpoint:

    ldw        t1,		SCORE(zero)

    loop_multipl_ten:
        cmplti      t2,		t1,		10
        bne		    t2,		zero,		exit_loop
        addi		t1,		t1,		-10
        br          loop_multipl_ten

    exit_loop:
        bne		t1,		zero,		checkpoint_ret
        addi	v0,		zero,		1
        stw		v0,		CP_VALID(zero)
        
    addi		t1,		zero,		198

    copy_loop:
        addi    t1,     t1,     -4
        ldw     t2,		   HEAD_X(t1)
        stw     t2,		   CP_HEAD_X(t1)
        bne		t1,		zero,		copy_loop

    jmp ra
        
    checkpoint_ret:
        add		v0,		zero,		zero
        jmp		ra
        
; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:

    ldw		t1,		CP_VALID(zero)
    beq		t1,		zero,		checkpoint_restore_ret
    

    addi		t1,		zero,		198
    restore_loop:
        addi    t1,     t1,     -4
        ldw     t2,		   CP_HEAD_X(t1)
        stw     t2,		   HEAD_X(t1)
        bne		t1,		zero,		restore_loop
    
    addi		v0,		zero,		1
    jmp		ra

    checkpoint_restore_ret:
        add		v0,		zero,		zero
        jmp		ra

; END: restore_checkpoint


; BEGIN: blink_score
blink_score:
    addi		t7,		zero,		3

    loop_blink:

        stw        zero,		SEVEN_SEGS(zero)
        stw        zero,		SEVEN_SEGS+4 (zero)
        stw        zero,	    SEVEN_SEGS+8(zero)
        stw        zero,		SEVEN_SEGS+12(zero)
        call        wait_procedure
        call		display_score
        addi        t7,		t7,		-1
        bne		    t7,		zero,		loop_blink
        jmp		    ra
    
        

; END: blink_score

; digit map
digit_map:
    .word 0xFC ; 0
    .word 0x60 ; 1
    .word 0xDA ; 2
    .word 0xF2 ; 3
    .word 0x66 ; 4
    .word 0xB6 ; 5
    .word 0xBE ; 6
    .word 0xE0 ; 7
    .word 0xFE ; 8
    .word 0xF6 ; 9
