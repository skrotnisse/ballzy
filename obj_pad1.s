.include "nes.inc"

; Rendering
.importzp tile_data
.importzp tile_offset
.importzp oam_offset

; Inputs
.importzp joypad1

.export pad1_y
.export pad1_dy
.export pad1_ddy
.export pad1_x
.export pad1_dx
.export pad1_ddx

.export obj_pad1_init
.export obj_pad1_process_input
.export obj_pad1_update
.export obj_pad1_draw

.segment "ZEROPAGE"
  pad1_x:         .res 1
  pad1_y:         .res 1
  pad1_dx:        .res 2
  pad1_dy:        .res 2
  pad1_ddx:       .res 2
  pad1_ddy:       .res 2

.segment "RODATA"
md_pad1_idle:
  .byte $00, $0E, $00, $00  ; Tile data: Y-offset, Tile index, Attribute, X-offset
  .byte $08, $0F, $00, $00  ; Tile data: Y-offset, Tile index, Attribute, X-offset
  .byte $10, $0E, $80, $00  ; Tile data: Y-offset, Tile index, Attribute, X-offset

.segment "CODE"

.proc obj_pad1_init
  lda #8
  sta pad1_x
  lda #104
  sta pad1_y
  lda #0
  sta pad1_dx
  sta pad1_dx+1
  sta pad1_dy
  sta pad1_dy+1
  sta pad1_ddx
  sta pad1_ddx+1
  sta pad1_ddy
  sta pad1_ddy+1
  rts
.endproc

.proc obj_pad1_process_input
check_joypad1_up:
  lda joypad1
  and #JOYPAD_KEY_UP
  beq check_joypad1_down
;  lda #$FE
;  sta pad1_dy

  lda #$FF
  sta pad1_ddy
  lda #$F0
  sta pad1_ddy+1

  jmp end_input

check_joypad1_down:
  lda joypad1
  and #JOYPAD_KEY_DOWN
  beq none_pressed
;  lda #$02
;  sta pad1_dy

  lda #0
  sta pad1_ddy
  lda #10
  sta pad1_ddy+1

  jmp end_input

none_pressed:
  lda #0
;  sta pad1_dy

  sta pad1_ddy
  sta pad1_ddy+1

end_input:
  rts
.endproc

.proc obj_pad1_update
  clc
  lda pad1_y
  adc pad1_dy
  sta pad1_y

  clc
  lda pad1_dy+1          ; Low byte
  adc pad1_ddy+1
  sta pad1_dy+1
  lda pad1_dy            ; High byte
  adc pad1_ddy 
  sta pad1_dy 

  rts
.endproc

; Draws pad1 at (pad1_x, pad1_y).
.proc obj_pad1_draw
  ; Reset draw state
  lda #0
  sta tile_data
  sta tile_offset

  ; For each tile..
: ldx tile_offset
  lda md_pad1_idle,x
  clc
  adc pad1_y
  sta tile_data
  lda md_pad1_idle+1,x
  sta tile_data+1
  lda md_pad1_idle+2,x
  sta tile_data+2
  lda md_pad1_idle+3,x
  clc
  adc pad1_x
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

