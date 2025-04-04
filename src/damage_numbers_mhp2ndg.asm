.psp

FRAME_DURATION equ 18
MAX_INSTANCES equ 0x20
index equ 0x0891DBB0
pointer equ 0x0891DBC0

.createfile "./bin/DAMAGE_NUMBERS_JP.bin", 0x0891D900
    move t6, t0

    ;cleaning matrix M500 and M600
	vzero.q c500
	vzero.q c510
	vzero.q c520
	vzero.q c530

	vzero.q	c600
	vzero.q	c610
	vzero.q	c620
	vzero.q	c630

	vone.q  c500
	lv.s	S500, 0x30(t6) ;input x

	lv.s	S501, 0x34(t6) ;input y
	li		t0, 0x42c80000 ; offset +100
	mtv		t0, s602
	vadd.s	S501, S501, s602
	
	lv.s	S502, 0x38(t6) ;input z

	;view @ position (using vdot because view matrix is transposed)
	vdot.q	c600, r700, c500
	vdot.q	c610, r701, c500
	vdot.q	c620, r702, c500
	vdot.q	c630, r703, c500

	;loading projection matrix values
	vzero.q	c500

	li		t0,	0x3f9b8c00
	mtv		t0, s500

	li		t0, 0x40093eff
	mtv		t0, s511

	li		t0, 0xbf800000
	mtv		t0, s522

	li		t0, 0xbf800000
	mtv		t0, s532

	li		t0, 0xc2700000
	mtv		t0, s523

	; projection @ (view @ position)
	vtfm4.q	r601, M500, r600

	;ndc
	vdiv.s	s602, s601, s631
	vdiv.s	s612, s611, s631
	vdiv.s	s622, s621, s631

	li		t0, 0x43f00000
	mtv		t0, s600

	li		t0, 0x43880000
	mtv		t0, s610

	li		t0, 0x3f000000
	mtv		t0, s620

	;ndc to screen coordinates
	vadd.s	s602, s602, s630
	vmul.s	s602, s602, s620
	vmul.s	s602, s602, s600 

	vsub.s	s612, s630, s612
	vmul.s	s612, s612, s620
	vmul.s	s612, s612, s610 

	vf2in.s  s602, s602, 0 ;result x
	vf2in.s  s612, s612, 0 ;result y

	mfv t6, s602
	mfv t7, s612

    li      t0, pointer

    li      t3, index
    lw      t1, 0(t3)
    addu   t0, t0, t1

    move    t1, t6
    sh      t1, 0x0(t0)

    move    t1, t7
    sh      t1, 0x2(t0)

    sh      t2, 0x4(t0)

    li      t1, 0x0
    sb      t1, 0x6(t0)

    li      t1, FRAME_DURATION
    sb      t1, 0x7(t0)

    li      t0, index
    lw      t1, 0(t0)
    addiu   t1, t1, 8
    sw      t1, 0(t0)

    bgt     t1, MAX_INSTANCES - 1, @reset_index
    nop

    j @ret

@reset_index:
    li      t0, index
    li      t1, 0x0
    sw      t1, 0(t0)

@ret:
    sh      v0,0x2E4(s5)
    j       0x09AC2CA8

.close

.createfile "./bin/COPY_MATRIX.bin", 0x0891DDB0
    vmmov.q m700, m100
    jr     ra
.close

.createfile "./bin/DAMAGE_DRAWING_JP.bin", 0x0891DC00 ; crashing?

    addiu	sp, sp, -0x18
	sv.q	c000, 0x8(sp);
	sw		ra, 0x4(sp)

    addiu	sp, sp, -0xC
    sw	    t5, 0xC(sp)
	sw	    a2, 0x8(sp)
	sw		a0, 0x4(sp)

    addiu  sp, sp, -0x1C
    sw     ra, 0x1C(sp)
    sw     s5, 0x18(sp)
    sw     t2, 0x14(sp)
    sw     t4, 0x10(sp)
    sw     t1, 0x0C(sp)
    sw     a3, 0x08(sp)
    sw     t0, 0x04(sp)

    jal	0x08826f24
    nop

    li      t0, 0x09C3F7CC 
    li      t1, 0x24030008
    sw      t1, 0(t0)

    li      t0, 0x09AC2CA4
    li      t1, 0x0A247640
    sw      t1, 0(t0)

    li      t4, 0

draw_loop:
    bgt     t4, MAX_INSTANCES, ret
    nop

    la      a0, 0x996d000
    la      a1, string_buffer

    li      t0, pointer 
    addu    t0, t0, t4  

    ;loading damage
    lh      t2, 0x4(t0)
    move    a2, t2
    li      a3, 0

    ;loading x, y
    lh      t1, 0x0(t0)
    move    t5, t4
    srl     t5, t5, 1
    addu    t1, t1, t5

    lh      t2, 0x2(t0)
    move    t5, t4
    srl     t5, t5, 1
    addu    t2, t2, t5
    
    sh      t1,0x120(a0)
    sh      t2,0x122(a0)

    li      t1, 0x0d0c
    sw      t1,0x12c(a0)
    
    ;checking timer
    lb      t5, 0x7(t0)     
    bnez    t5, draw_number
    nop

    addiu   t4, t4, 8       
    j draw_loop
    nop

draw_number:
    ;la   $t0, my_byte
    lbu  t1, 0x7(t0)
    beqz t1, end 
    addi t1, t1, -1      
    sb   t1, 0x7(t0) 
end:
    ;addiu    t5, t5, -1
    ;sb      t5, 0x7(t0)
    ;beqz    t5, ret
    ;nop

    bgt     t4, MAX_INSTANCES, ret
    nop

    addiu  sp, sp, -0x4
    sw     t4, 0x04(sp)

    jal      0x08890e0c
    nop

    lw      t4, 0x4(sp)

    addiu   t4, t4, 8
    addiu   sp, sp, 0x4

    blt     t4, 31, draw_loop
    nop

ret:
    lw     ra, 0x1C(sp)
    lw     s5, 0x18(sp)
    lw     t2, 0x14(sp)
    lw     t4, 0x10(sp)
    lw     t1, 0x0C(sp)
    lw     a3, 0x08(sp)
    lw     t0, 0x04(sp)
    addiu  sp, sp, 0x1C
    
	lw		a0, 0x4(sp)
    lw	    a2, 0x8(sp)
    lw	    t5, 0xC(sp)
    addiu	sp, sp, 0xC

    lw		ra, 0x4(sp)
	addiu	ra, ra, 0xC
	lv.q	c000, 0x8(sp)
	addiu	sp, sp, 0x18

    move a1, s4

    j       0x08841DD8
    nop

string_buffer:
    .asciiz "%d"
.close