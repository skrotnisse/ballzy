.include "nes.inc"

.export ppu_clear_nt
.export ppu_on_all
.export ppu_on_bgobj
.export ppu_off_all
.export ppu_disable_nmi
.export ppu_hide_unused_oam
.export ppu_load_default_palette
.export ppu_wait_nmi

.importzp nmi_cnt

.segment "RODATA"
initial_palette:
  .byte $1D            ; Universal background color (mirrored, must be same as byte at offset $10)
  .byte $18,$28,$38    ; Background palette 0
  .byte $0F
  .byte $06,$16,$26    ; Background palette 1
  .byte $0F
  .byte $08,$19,$2A    ; Background palette 2
  .byte $0F
  .byte $02,$12,$22    ; Background palette 3
  .byte $1D            ; Universal background color (mirrored, must be same as byte at offset $0)
  .byte $10,$20,$02    ; Sprite palette 0 (pad 1)
  .byte $0F
  .byte $10,$20,$05    ; Sprite palette 1 (pad 2)
  .byte $0F
  .byte $10,$20,$20    ; Sprite palette 2 (ball)
  .byte $0F
  .byte $02,$12,$22    ; Sprite palette 3

.segment "CODE"

;  Clears a nametable to a given tile number and attribute value.
;  (Turn off rendering in PPUMASK and set the VRAM address increment
;  to 1 in PPUCTRL first.)
;  @param A tile number
;  @param X base address of nametable ($20, $24, $28, or $2C)
;  @param Y attribute value ($00, $55, $AA, or $FF)
.proc ppu_clear_nt
  ;  Set base PPU address to XX00
  stx PPUADDR
  ldx #$00
  stx PPUADDR

  ;  Clear the 960 spaces of the main part of the nametable,
  ;  using a 4 times unrolled loop
  ldx #960/4
: .repeat 4
  sta PPUDATA
  .endrepeat
  dex
  bne :-

  ;  Clear the 64 entries of the attribute table
  ldx #64
: sty PPUDATA
  dex
  bne :-
  rts
.endproc

  ;  Sets the scroll position and turns PPU rendering on.
  ;  @param A value for PPUCTRL ($2000) including scroll position MSBs
  ;  @param X horizontal scroll position (0-255)
  ;  @param Y vertical scroll position (0-239)
  ;  @param C if true, sprites will be visible
.proc ppu_on_all
  stx PPUSCROLL
  sty PPUSCROLL
  sta PPUCTRL
  lda #PPUMASK_BG_ON
  bcc :+
  lda #PPUMASK_BG_ON|PPUMASK_OBJ_ON
: sta PPUMASK
  rts
.endproc

.proc ppu_on_bgobj
  lda #PPUMASK_BG_ON|PPUMASK_OBJ_ON
  sta PPUMASK
  rts
.endproc

.proc ppu_off_all
  lda #0
  sta PPUMASK
  rts
.endproc

.proc ppu_disable_nmi
  lda #0
  sta PPUCTRL
  rts
.endproc

  ;  Moves all unused sprites, starting from OAM address offset 'x'
  ;  ($04, $08, etc..), out of the visible area.
  ;  @param X address offset (multiple of $04)
.proc ppu_hide_unused_oam
  ; First round the address down to a multiple of 4 so that it won't
  ; freeze should the address get corrupted.
  txa
  and #%11111100
  tax
  lda #$FF  ; Any Y value from $EF through $FF will work
: sta OAM,x
  inx
  inx
  inx
  inx
  bne :-
  rts
.endproc

  ;  Loads a default background and sprite palette
.proc ppu_load_default_palette
  ; Seek to the start of palette memory ($3F00-$3F1F)
  ldx #$3F
  stx PPUADDR
  ldx #$00
  stx PPUADDR
  ; Copy initial palette to memory (32 bytes)
: lda initial_palette,x
  sta PPUDATA
  inx
  cpx #32
  bcc :-
  rts
.endproc

.proc ppu_wait_nmi
  lda nmi_cnt
: cmp nmi_cnt
  beq :-
  rts
.endproc
