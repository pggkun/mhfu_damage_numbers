.psp

FRAME_DURATION equ 18
MOD_DEFAULT_ENABLED equ 1
DAMAGE_NUMBER_DEFAULT_SCALE equ 12 ; 10 = 1x, 15 = 1.5x, 100 = 10x
DAMAGE_NUMBER_BASE_WIDTH equ 12
DAMAGE_NUMBER_BASE_HEIGHT equ 13
DAMAGE_NUMBER_COLOR_INDEX equ 0
DAMAGE_NUMBER_OUTLINE_COLOR_INDEX equ 1
DAMAGE_NUMBER_OUTLINE_SIZE equ 1

MOD_CONFIG_ENABLED equ 0x00
MOD_CONFIG_FONT_SCALE equ 0x01
MOD_CONFIG_PENDING_COLOR equ 0x3C

INSTANCE_COUNT equ 4
INSTANCE_SIZE equ 0x10
INSTANCE_BUFFER_SIZE equ INSTANCE_COUNT * INSTANCE_SIZE

INSTANCE_WORLD_X equ 0x00
INSTANCE_WORLD_Y equ 0x04
INSTANCE_WORLD_Z equ 0x08
INSTANCE_DAMAGE equ 0x0C
INSTANCE_TIMER equ 0x0E
INSTANCE_COLOR equ 0x0F

.createfile DAMAGE_NUMBERS_OUTPUT, DAMAGE_NUMBERS_ADDRESS
    move t6, t0

    li      t0, DAMAGE_CONFIG_ADDRESS
    lbu     t1, MOD_CONFIG_ENABLED(t0)
    beqz    t1, @ret
    nop
    lbu     t7, MOD_CONFIG_PENDING_COLOR(t0)
    sb      zero, MOD_CONFIG_PENDING_COLOR(t0)

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
    sb      t7, INSTANCE_COLOR(t0)

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

.org DAMAGE_CONFIG_ADDRESS
damage_numbers_config:
    .byte MOD_DEFAULT_ENABLED
    .byte DAMAGE_NUMBER_DEFAULT_SCALE
    .byte 0
    .byte 0

.if CRITICAL_HIT_CAPTURE_SUPPORTED
critical_hit_capture:
    li      v0, 0x6

    ; 0x40 = negative critical
    ; 0x80 = positive critical
    ; color: 0=white, 4=yellow, 2=red.
    lbu     k0, 0x2B(s2)
    andi    k0, k0, 0xC0
    beqz    k0, @store_critical_color
    li      k1, DAMAGE_NUMBER_COLOR_INDEX
    andi    k0, k0, 0x40
    bnez    k0, @store_critical_color
    li      k1, DAMAGE_NUMBER_NEGATIVE_CRIT_COLOR_INDEX
    li      k1, DAMAGE_NUMBER_POSITIVE_CRIT_COLOR_INDEX

@store_critical_color:
    li      k0, DAMAGE_CONFIG_ADDRESS
    sb      k1, MOD_CONFIG_PENDING_COLOR(k0)
    j       CRITICAL_HIT_HOOK_RETURN
    nop
.endif

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

.if CRITICAL_HIT_CAPTURE_SUPPORTED
    li      t0, CRITICAL_HIT_HOOK_ADDRESS
    li      t1, CRITICAL_HIT_JUMP_OPCODE
    sw      t1, 0(t0)
.endif

    li      t0, DAMAGE_CONFIG_ADDRESS
    lbu     t1, MOD_CONFIG_ENABLED(t0)
    beqz    t1, mod_disabled
    nop

    lbu     t3, MOD_CONFIG_FONT_SCALE(t0)
    addiu   t1, t3, -10
    sltiu   t1, t1, 91
    bnez    t1, @valid_scale
    nop
    li      t3, DAMAGE_NUMBER_DEFAULT_SCALE
@valid_scale:

    la      a0, GAME_DRAW_CONTEXT_ADDRESS

    sll     t0, t3, 3
    sll     a3, t3, 2
    addu    t0, t0, a3
    addiu   t0, t0, 5
    li      v0, 10
    divu    t0, v0
    mflo    t0
    sb      t0, 0x12C(a0)

    sll     a3, t3, 3
    sll     v1, t3, 2
    addu    a3, a3, v1
    addu    a3, a3, t3
    addiu   a3, a3, 5
    li      v0, 10
    divu    a3, v0
    mflo    a3
    sb      a3, 0x12D(a0)

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
    lbu     t1, INSTANCE_COLOR(t0)
    sw      t1, 0x0C(sp)

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
    lw      a2, 0x0C(sp)

    lw      t4, 0x00(sp)
    addiu   sp, sp, 0x10

next_instance:
    addiu   t4, t4, INSTANCE_SIZE
    j       draw_loop
    nop

mod_disabled:
    li      t0, DAMAGE_INSTANCES_ADDRESS
    li      t1, INSTANCE_COUNT
@clear_instances:
    sb      zero, INSTANCE_TIMER(t0)
    addiu   t0, t0, INSTANCE_SIZE
    addiu   t1, t1, -1
    bnez    t1, @clear_instances
    nop

    li      t0, DAMAGE_INDEX_ADDRESS
    sw      zero, 0(t0)
    j       ret
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
