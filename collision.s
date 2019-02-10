.include "utils.inc"
.include "game.inc"

.export resolve_collisions

.importzp ball_y
.importzp ball_dy
.importzp ball_ddy
.importzp ball_x
.importzp ball_dx
.importzp ball_ddx

.importzp pad1_y
.importzp pad1_dy
.importzp pad1_ddy
.importzp pad1_x
.importzp pad1_dx
.importzp pad1_ddx

.importzp pad2_y
.importzp pad2_dy
.importzp pad2_ddy
.importzp pad2_x
.importzp pad2_dx
.importzp pad2_ddx

.importzp next_gamestate

.segment "CODE"

.proc resolve_pad1_wall_collision
  clc
  lda pad1_y

yneg_collision_check:
  cmp #GAME_AREA_YTOP
  bcs ypos_collision_check
  lda #GAME_AREA_YTOP
  sta pad1_y
  lda #0
  sta pad1_dy
  sta pad1_dy+1
  sta pad1_ddy
  sta pad1_ddy+1

  jmp done

ypos_collision_check:
  cmp #GAME_AREA_YBOTTOM-8*2
  bcc done
  lda #GAME_AREA_YBOTTOM-8*2-1
  sta pad1_y
  lda #0
  sta pad1_dy
  sta pad1_dy+1
  sta pad1_ddy
  sta pad1_ddy+1

done:
  rts
.endproc

.proc resolve_pad2_wall_collision
  clc
  lda pad2_y

yneg_collision_check:
  cmp #GAME_AREA_YTOP
  bcs ypos_collision_check
  lda #GAME_AREA_YTOP
  sta pad2_y
  lda #0
  sta pad2_dy
  sta pad2_dy+1
  sta pad2_ddy
  sta pad2_ddy+1

  jmp done

ypos_collision_check:
  cmp #GAME_AREA_YBOTTOM-8*2
  bcc done
  lda #GAME_AREA_YBOTTOM-8*2-1
  sta pad2_y
  lda #0
  sta pad2_dy
  sta pad2_dy+1
  sta pad2_ddy
  sta pad2_ddy+1

done:
  rts
.endproc

.proc resolve_ball_wall_collision
xneg_collision_check:
  clc
  lda ball_x
  cmp #GAME_AREA_XLEFT
  bcs xpos_collision_check

  ; Transition to p2 score state
  lda #GAME_STATE_P2SCORE
  sta next_gamestate

  neg ball_dx               ; 2-complement negation
  lda #GAME_AREA_XLEFT
  sta ball_x
  jmp yneg_collision_check

xpos_collision_check:
  cmp #GAME_AREA_XRIGHT
  bcc yneg_collision_check

  ; Transition to p1 score state
  lda #GAME_STATE_P1SCORE
  sta next_gamestate

  neg ball_dx               ; 2-complement negation
  lda #GAME_AREA_XRIGHT
  sta ball_x

yneg_collision_check:
  clc
  lda ball_y
  cmp #GAME_AREA_YTOP
  bcs ypos_collision_check
  neg ball_dy               ; 2-complement negation
  lda #GAME_AREA_YTOP
  sta ball_y
  jmp done

ypos_collision_check:
  cmp #GAME_AREA_YBOTTOM
  bcc done
  neg ball_dy               ; 2-complement negation
  lda #GAME_AREA_YBOTTOM
  sta ball_y

done:
  rts
.endproc

.proc resolve_pad1_ball_collision
  ; Check collision between pad1 and ball
  lda pad1_x
  clc
  adc #8
  cmp ball_x
  bcc done

  lda pad1_y
  clc
  adc #23
  cmp ball_y
  bcc done
  clc
  sbc #30
  cmp ball_y
  bcs done
  
  ; Bounce ball on pad1. Apply some "friction" depending on pad vs ball movement. Ball y-direction
  ; is flipped if the pad is moving in opposite direction.
  lda pad1_dy
  cmp #0
  beq :+
  eor ball_dy
  and #$80
  cmp #0
  beq :+
  neg ball_dy               ; 2-complement negation
: neg ball_dx               ; 2-complement negation
  lda #GAME_AREA_XLEFT+7
  sta ball_x
done:
  rts
.endproc

.proc resolve_pad2_ball_collision
  ; Check collision between pad1 and ball
  lda pad2_x
  clc
  sbc #8
  cmp ball_x
  bcs done

  lda pad2_y
  clc
  adc #23
  cmp ball_y
  bcc done
  clc
  sbc #30
  cmp ball_y
  bcs done
  
  ; Bounce ball on pad1. Apply some "friction" depending on pad vs ball movement. Ball y-direction
  ; is flipped if the pad is moving in opposite direction.
  lda pad2_dy
  cmp #0
  beq :+
  eor ball_dy
  and #$80
  cmp #0
  beq :+
  neg ball_dy               ; 2-complement negation
: neg ball_dx               ; 2-complement negation
  lda #GAME_AREA_XRIGHT-16
  sta ball_x
done:
  rts
.endproc

.proc resolve_collisions
  jsr resolve_pad1_wall_collision
  jsr resolve_pad2_wall_collision
  jsr resolve_ball_wall_collision
  jsr resolve_pad1_ball_collision
  jsr resolve_pad2_ball_collision
  rts
.endproc

