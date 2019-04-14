.include "nes.inc"

.import main_init
.import main_frame

.export nmi_cnt
.export timer1

.export FamiToneMusicPlay

; http://nesdev.com/neshdr20.txt  
.segment "INESHDR"
  .byte "NES", $1A             
  .byte 2                ; 2 x 16K PRG
  .byte 1                ; 1 x 8K  CHR
  .byte $00              ; Memory-Mapper low nibble (and more)
  .byte $00              ; Memory-Mapper high nibble (and more); NES 2.0
  .byte $00              ; No submapper
  .byte $00              ; PRG ROM not 4MiB or larger
  .byte $00              ; No PRG RAM
  .byte $00              ; No CHR RAM
  .byte $01              ; NTSC ($00) or PAL ($01)
  .byte $00              ; No special PPU

.segment "ZEROPAGE"
  nmi_cnt:    .res 1
  timer1:     .res 1     ; Decremented to zero during NMI (roughly 50 ticks per second on PAL)

.segment "VECTORS"
  .addr nmi_handler, reset_handler, irqbrk_handler

.segment "CODE"
  .include "famitone2.s"

.proc nmi_handler
  jsr FamiToneUpdate

  inc nmi_cnt
  ; Decrement timer1
  lda timer1
  cmp #0
  beq :+
  dec timer1
: rti

.endproc
  
.proc irqbrk_handler
  rti
.endproc

.proc reset_handler
  ; ============================================
  ; Put PPU/APU registers in a known state (disable interrupts, etc)
  ; ============================================
  sei                    ; Disable interrupts
  cld                    ; Clear decimal mode
  ldx #$00               
  stx PPUCTRL            ; Disable NMI and set VRAM increment to 1
  stx APU_DMCC_CTRL      ; Disable DMC IRQ
  stx PPUMASK            ; Disable rendering
  dex                    ; Initialize SP = $FF
  txs
  ldx #$40               ; Disable APU frame IRQ
  stx APU_FRAMECNT
  ldx #$0F
  stx APU_CTRL           ; Disable DMC playback, enable other channels
  
  ; TODO: Setup memory mapper and jmp to other init code from here?

  ; ============================================
  ; Wait for PPU to initialize.
  ; ============================================
  ; If the user presses Reset during vblank, the PPU may reset
  ; with the vblank flag still true.  This has about a 1 in 13
  ; chance of happening on NTSC or 2 in 9 on PAL.  Clear the
  ; flag now so the first loop below sees an actual vblank.
  bit PPUSTATUS

  ; PPU warmup, wait for two frames.
: bit PPUSTATUS
  bpl :-
: bit PPUSTATUS
  bpl :-

  ; Clear RAM while waiting for PPU to warmup.
  txa
: sta $000, x
  sta $100, x
  sta $200, x
  sta $300, x
  sta $400, x
  sta $500, x
  sta $600, x
  sta $700, x
  inx
  bne :-

  ; PPU warmup, wait for a third frame.
: bit PPUSTATUS
  bpl :-

  ; Initialize FamiTone2.
  lda #0
  ldx #<music_data
  ldy #>music_data
  jsr FamiToneInit

  ; ============================================
  ; Initialize main game logic
  ; ============================================
  jsr main_init

forever:
  jsr main_frame

  jmp forever

.endproc

.segment "RODATA"
music_data:
  .include "ballzytunes.s"

.segment "DMC"
  .incbin "obj/ballzytunes.dmc"

