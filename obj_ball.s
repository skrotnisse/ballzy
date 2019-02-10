.include "nes.inc"

.importzp tile_data
.importzp tile_offset
.importzp oam_offset

.export ball_y
.export ball_dy
.export ball_ddy
.export ball_x
.export ball_dx
.export ball_ddx

.export obj_ball_init
.export obj_ball_update
.export obj_ball_draw

.segment "ZEROPAGE"
  ball_x:         .res 1
  ball_y:         .res 1
  ball_dx:        .res 2
  ball_dy:        .res 2
  ball_ddx:       .res 2    ;; TODO: Unused for now
  ball_ddy:       .res 2    ;; TODO: Unused for now

.segment "CODE"

.proc obj_ball_init
  lda #128
  sta ball_x
  lda #120
  sta ball_y
  lda #$FE
  sta ball_dx
  sta ball_dy
  lda #0
  sta ball_ddx
  sta ball_ddy
  rts
.endproc

.proc obj_ball_update
  ; Move ball along X axis
  clc
  lda ball_x
  adc ball_dx
  sta ball_x

  ; Move ball along Y axis
  clc
  lda ball_y
  adc ball_dy
  sta ball_y

  rts
.endproc

; Draws ball at (ball_x, ball_y).
.proc obj_ball_draw
  ldx oam_offset

  lda ball_y
  sta OAM,x
  lda #$0D
  sta OAM+1,x
  lda #$02
  sta OAM+2,x
  lda ball_x
  sta OAM+3,x

  lda oam_offset     ; Move to next OAM index offset (+= $04)
  clc
  adc #4
  sta oam_offset

  rts
.endproc


