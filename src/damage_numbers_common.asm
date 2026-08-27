.psp

FRAME_DURATION equ 18
DAMAGE_NUMBER_SCALE equ 12 ; Scale in tenths: 10 = 1x, 15 = 1.5x, 100 = 10x
DAMAGE_NUMBER_BASE_WIDTH equ 12
DAMAGE_NUMBER_BASE_HEIGHT equ 13
DAMAGE_NUMBER_WIDTH equ (DAMAGE_NUMBER_BASE_WIDTH * DAMAGE_NUMBER_SCALE + 5) / 10
DAMAGE_NUMBER_HEIGHT equ (DAMAGE_NUMBER_BASE_HEIGHT * DAMAGE_NUMBER_SCALE + 5) / 10
DAMAGE_NUMBER_SIZE equ (DAMAGE_NUMBER_HEIGHT << 8) | DAMAGE_NUMBER_WIDTH
DAMAGE_NUMBER_COLOR_INDEX equ 0
DAMAGE_NUMBER_OUTLINE_COLOR_INDEX equ 1
DAMAGE_NUMBER_OUTLINE_SIZE equ 1

INSTANCE_COUNT equ 4
INSTANCE_SIZE equ 0x10
INSTANCE_BUFFER_SIZE equ INSTANCE_COUNT * INSTANCE_SIZE

INSTANCE_WORLD_X equ 0x00
INSTANCE_WORLD_Y equ 0x04
INSTANCE_WORLD_Z equ 0x08
INSTANCE_DAMAGE equ 0x0C
INSTANCE_TIMER equ 0x0E

.createfile DAMAGE_NUMBERS_OUTPUT, DAMAGE_NUMBERS_ADDRESS
    move t6, t0

    li      t0, DAMAGE_INSTANCES_ADDRESS
    li      t3, DAMAGE_INDEX_ADDRESS
    lw      t1, 0(t3)
    addu   t0, t0, t1

    lw      t1, 0x30(t6)
    sw      t1, INSTANCE_WORLD_X(t0)

    lv.s    s500, 0x34(t6)
    li      t1, 0x42C80000
    mtv     t1, s501
    vadd.s  s500, s500, s501
    sv.s    s500, INSTANCE_WORLD_Y(t0)

    lw      t1, 0x38(t6)
    sw      t1, INSTANCE_WORLD_Z(t0)

    sh      t2, INSTANCE_DAMAGE(t0)

    li      t1, FRAME_DURATION
    sb      t1, INSTANCE_TIMER(t0)

    li      t0, DAMAGE_INDEX_ADDRESS
    lw      t1, 0(t0)
    addiu   t1, t1, INSTANCE_SIZE
    sw      t1, 0(t0)

    bge     t1, INSTANCE_BUFFER_SIZE, @reset_index
    nop

    j @ret

@reset_index:
    li      t0, DAMAGE_INDEX_ADDRESS
    li      t1, 0x0
    sw      t1, 0(t0)

@ret:
    sh      v0,0x2E4(s5)
    j       DAMAGE_CAPTURE_RETURN

.close

.createfile COPY_MATRIX_OUTPUT, COPY_MATRIX_ADDRESS
    vmmov.q m700, m100
    jr     ra
.close

.createfile DAMAGE_DRAWING_OUTPUT, DAMAGE_DRAWING_ADDRESS

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

    jal	GAME_DRAW_BEGIN_CALL
    nop

    li      t0, GAME_DRAW_STATE_ADDRESS
    li      t1, 0x24030008
    sw      t1, 0(t0)

    li      t0, DAMAGE_CAPTURE_HOOK_ADDRESS
    li      t1, DAMAGE_CAPTURE_JUMP_OPCODE
    sw      t1, 0(t0)

    li      t4, 0

draw_loop:
    bge     t4, INSTANCE_BUFFER_SIZE, ret
    nop

    li      t0, DAMAGE_INSTANCES_ADDRESS
    addu    t0, t0, t4

    lbu     t5, INSTANCE_TIMER(t0)
    beqz    t5, next_instance
    nop
    addiu   t5, t5, -1
    sb      t5, INSTANCE_TIMER(t0)

    vzero.q c500
    vzero.q c510
    vzero.q c520
    vzero.q c530
    vone.s  s503
    lv.s    s500, INSTANCE_WORLD_X(t0)
    lv.s    s501, INSTANCE_WORLD_Y(t0)
    lv.s    s502, INSTANCE_WORLD_Z(t0)

    vdot.q  s600, r700, c500
    vdot.q  s610, r701, c500
    vdot.q  s620, r702, c500
    vdot.q  s630, r703, c500

    vzero.q c500
    vzero.q c510
    vzero.q c520
    vzero.q c530

    li      t1, 0x3F9B8C00
    mtv     t1, s500
    li      t1, 0x40093EFF
    mtv     t1, s511
    li      t1, 0xBF800000
    mtv     t1, s522
    mtv     t1, s532
    li      t1, 0xC2700000
    mtv     t1, s523

    vtfm4.q r601, M500, r600
    vdiv.s  s602, s601, s631
    vdiv.s  s612, s611, s631

    vone.s  s630
    li      t1, 0x3F000000
    mtv     t1, s620
    li      t1, 0x43F00000
    mtv     t1, s600
    li      t1, 0x43880000
    mtv     t1, s610

    vadd.s  s602, s602, s630
    vmul.s  s602, s602, s620
    vmul.s  s602, s602, s600
    vsub.s  s612, s630, s612
    vmul.s  s612, s612, s620
    vmul.s  s612, s612, s610
    vf2in.s s602, s602, 0
    vf2in.s s612, s612, 0

    mfv     t1, s602
    mfv     t2, s612

    addiu   sp, sp, -0x10
    sw      t4, 0x00(sp)
    sw      t1, 0x04(sp)
    sw      t2, 0x08(sp)

    lw      a0, 0x04(sp)
    addiu   a0, a0, -DAMAGE_NUMBER_OUTLINE_SIZE
    lw      a1, 0x08(sp)
    jal     draw_damage_number_at
    li      a2, DAMAGE_NUMBER_OUTLINE_COLOR_INDEX

    lw      a0, 0x04(sp)
    addiu   a0, a0, DAMAGE_NUMBER_OUTLINE_SIZE
    lw      a1, 0x08(sp)
    jal     draw_damage_number_at
    li      a2, DAMAGE_NUMBER_OUTLINE_COLOR_INDEX

    lw      a0, 0x04(sp)
    lw      a1, 0x08(sp)
    addiu   a1, a1, -DAMAGE_NUMBER_OUTLINE_SIZE
    jal     draw_damage_number_at
    li      a2, DAMAGE_NUMBER_OUTLINE_COLOR_INDEX

    lw      a0, 0x04(sp)
    lw      a1, 0x08(sp)
    addiu   a1, a1, DAMAGE_NUMBER_OUTLINE_SIZE
    jal     draw_damage_number_at
    li      a2, DAMAGE_NUMBER_OUTLINE_COLOR_INDEX

    lw      a0, 0x04(sp)
    lw      a1, 0x08(sp)
    jal     draw_damage_number_at
    li      a2, DAMAGE_NUMBER_COLOR_INDEX

    lw      t4, 0x00(sp)
    addiu   sp, sp, 0x10

next_instance:
    addiu   t4, t4, INSTANCE_SIZE
    j       draw_loop
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

    j       DAMAGE_DRAWING_RETURN
    nop

draw_damage_number_at:
    move    t1, a0
    move    t2, a1
    move    t5, a2

    la      a0, GAME_DRAW_CONTEXT_ADDRESS
    sh      t1, 0x120(a0)
    sh      t2, 0x122(a0)
    li      t0, DAMAGE_NUMBER_SIZE
    sh      t0, 0x12C(a0)
    sb      t5, 0x12E(a0)
    sb      zero, 0x12F(a0)

    li      t0, DAMAGE_INSTANCES_ADDRESS
    lw      t1, 0x00(sp)
    addu    t0, t0, t1
    lh      a2, INSTANCE_DAMAGE(t0)
    la      a1, string_buffer
    li      a3, 0

    j       GAME_DRAW_NUMBER_CALL
    nop

string_buffer:
    .asciiz "%d"
.close
