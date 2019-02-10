.include "nes.inc"
.include "game.inc"

; Rendering
.importzp tile_data
.importzp tile_offset
.importzp oam_offset

; Inputs
.importzp joypad2

.export pad2_y
.export pad2_dy
.export pad2_ddy
.export pad2_x
.export pad2_dx
.export pad2_ddx

.export obj_pad2_init
.export obj_pad2_process_input
.export obj_pad2_update
.export obj_pad2_draw

.segment "ZEROPAGE"
  pad2_x:         .res 1
  pad2_y:         .res 1
  pad2_dx:        .res 2
  pad2_dy:        .res 2
  pad2_ddx:       .res 2
  pad2_ddy:       .res 2

.segment "RODATA"
md_pad2_idle:
  .byte $00, $0E, $41, $00  ; Tile data: Y-offset, Tile index, Attribute, X-offset
  .byte $08, $0F, $41, $00  ; Tile data: Y-offset, Tile index, Attribute, X-offset
  .byte $10, $0E, $C1, $00  ; Tile data: Y-offset, Tile index, Attribute, X-offset

.segment "CODE"

.proc obj_pad2_init
  lda #GAME_AREA_XRIGHT-8
  sta pad2_x
  lda #104
  sta pad2_y
  lda #0
  sta pad2_dx
  sta pad2_dx+1
  sta pad2_dy
  sta pad2_dy+1
  sta pad2_ddx
  sta pad2_ddx+1
  sta pad2_ddy
  sta pad2_ddy+1
  rts
.endproc

.proc obj_pad2_process_input
check_joypad2_up:
  lda joypad2
  and #JOYPAD_KEY_UP
  beq check_joypad2_down
;  lda #$FE
;  sta pad2_dy

  lda #$FF
  sta pad2_ddy
  lda #$F0
  sta pad2_ddy+1

  jmp end_input

check_joypad2_down:
  lda joypad2
  and #JOYPAD_KEY_DOWN
  beq none_pressed
;  lda #$02
;  sta pad2_dy

  lda #0
  sta pad2_ddy
  lda #10
  sta pad2_ddy+1

  jmp end_input

none_pressed:
  lda #0
;  sta pad2_dy

  sta pad2_ddy
  sta pad2_ddy+1

end_input:
  rts
.endproc

.proc obj_pad2_update
  clc
  lda pad2_y
  adc pad2_dy
  sta pad2_y

  clc
  lda pad2_dy+1          ; Low byte
  adc pad2_ddy+1
  sta pad2_dy+1
  lda pad2_dy            ; High byte
  adc pad2_ddy 
  sta pad2_dy 

  rts
.endproc

; Draws pad2 at (pad2_x, pad2_y).
.proc obj_pad2_draw
  ; Reset draw state
  lda #0
  sta tile_data
  sta tile_offset

  ; For each tile..
: ldx tile_offset
  lda md_pad2_idle,x
  clc
  adc pad2_y
  sta tile_data
  lda md_pad2_idle+1,x
  sta tile_data+1
  lda md_pad2_idle+2,x
  sta tile_data+2
  lda md_pad2_idle+3,x
  clc
  adc pad2_x
  sta tile_data+3

  ; .. store it to OAM.
  ldx oam_offset
  lda tile_data
  sta OAM,x
  lda tile_data+1
  sta OAM+1,x
  lda tile_data+2
  sta OAM+2,x
  lda tile_data+3
  sta OAM+3,x

  lda oam_offset     ; OAM index offset += 4
  clc
  adc #4
  sta oam_offset

  lda tile_offset    ; Tile index offset += 4
  clc
  adc #4
  sta tile_offset

  cmp #12
  bne :-

  rts
.endproc

