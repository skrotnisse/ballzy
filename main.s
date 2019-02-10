.include "nes.inc"
.include "utils.inc"
.include "game.inc"

.import ppu_clear_nt
.import ppu_hide_unused_oam
.import ppu_load_default_palette
.import ppu_on_all
.import ppu_wait_nmi

.import resolve_collisions

.import obj_ball_init
.import obj_ball_update
.import obj_ball_draw

.import obj_pad1_init
.import obj_pad1_process_input
.import obj_pad1_update
.import obj_pad1_draw

.import obj_pad2_init
.import obj_pad2_process_input
.import obj_pad2_update
.import obj_pad2_draw

.importzp timer1
.importzp nmi_cnt

; Main public API
.export main_init
.export main_frame

; Inputs
.export joypad1
.export joypad2

; Rendering
.export tile_data
.export tile_offset
.export oam_offset

; Gamestate
.export next_gamestate

.segment "CHR"
  .incbin "obj/gamefx.chr"

.segment "ZEROPAGE"
  curr_gamestate: .res 1
  next_gamestate: .res 1

  tile_data:      .res 4
  tile_offset:    .res 1
  oam_offset:     .res 1

  joypad1:        .res 1
  joypad2:        .res 1
  
  p1score:        .res 1
  p2score:        .res 1

  screen_x:       .res 1
  screen_y:       .res 1
  screen_dx:      .res 2
  screen_dy:      .res 2
  screen_ddx:     .res 2
  screen_ddy:     .res 2

.segment "RODATA"
intro_palette:
  .incbin "obj/introscreen.pal"

; Import nametables + attribute tables as 256 byte chunks to make them easier to process.
intro_nt1_1:
  .incbin "obj/introscreen_1.bin", $0, $100
intro_nt1_2:
  .incbin "obj/introscreen_1.bin", $100, $100
intro_nt1_3:
  .incbin "obj/introscreen_1.bin", $200, $100
intro_nt1_4:
  .incbin "obj/introscreen_1.bin", $300, $100
intro_nt2_1:
  .incbin "obj/introscreen_2.bin", $0, $100
intro_nt2_2:
  .incbin "obj/introscreen_2.bin", $100, $100
intro_nt2_3:
  .incbin "obj/introscreen_2.bin", $200, $100
intro_nt2_4:
  .incbin "obj/introscreen_2.bin", $300, $100

sz_player1:
  .byte "PLAYER 1", $00
sz_player2:
  .byte "PLAYER 2", $00
sz_press_start:
  .byte "PRESS START", $00
sz_ready:
  .byte "READY!", $00
sz_player1scores:
  .byte "PLAYER 1 SCORES!", $00
sz_player2scores:
  .byte "PLAYER 2 SCORES!", $00
sz_player1wins:
  .byte "===( PLAYER 1 WINS! )===", $00
sz_player2wins:
  .byte "===( PLAYER 2 WINS! )===", $00


.segment "CODE"

.proc load_intro_nt1
  ldx #$20
  stx PPUADDR
  ldx #$00
  stx PPUADDR

  ldx #0

  ;  Load 256 bytes (1/4)
: lda intro_nt1_1,x
  sta PPUDATA
  inx
  bne :-

  ;  Load 256 bytes (2/4)
: lda intro_nt1_2,x
  sta PPUDATA
  inx
  bne :-

  ;  Load 256 bytes (3/4)
: lda intro_nt1_3,x
  sta PPUDATA
  inx
  bne :-

  ;  Load 256 bytes (4/4)
: lda intro_nt1_4,x
  sta PPUDATA
  inx
  bne :-

  rts
.endproc

.proc load_intro_nt2
  ldx #$28
  stx PPUADDR
  ldx #$00
  stx PPUADDR

  ldx #0

  ;  Load 256 bytes (1/4)
: lda intro_nt2_1,x
  sta PPUDATA
  inx
  bne :-

  ;  Load 256 bytes (2/4)
: lda intro_nt2_2,x
  sta PPUDATA
  inx
  bne :-

  ;  Load 256 bytes (3/4)
: lda intro_nt2_3,x
  sta PPUDATA
  inx
  bne :-

  ;  Load 256 bytes (4/4)
: lda intro_nt2_4,x
  sta PPUDATA
  inx
  bne :-

  rts
.endproc

.proc load_bg_intro_palette
  ; Seek to the start of palette memory ($3F00-$3F1F)
  ldx #$3F
  stx PPUADDR
  ldx #$00
  stx PPUADDR
  ; Copy initial background palette to memory (16 bytes)
: lda intro_palette,x
  sta PPUDATA
  inx
  cpx #16
  bcc :-
  rts
.endproc

; Prereq: Must load bg addr into PPUADDR before calling print subroutines.
.proc bg_print_player1
  ldx #$FF
: inx
  lda sz_player1,x
  sta PPUDATA
  cmp #0
  bne :-
  rts
.endproc

.proc bg_print_player2
  ldx #$FF
: inx
  lda sz_player2,x
  sta PPUDATA
  cmp #0
  bne :-
  rts
.endproc

.proc bg_print_press_start
  ldx #$FF
: inx
  lda sz_press_start,x
  sta PPUDATA
  cmp #0
  bne :-
  rts
.endproc

.proc bg_hide_press_start
  ldx #$FF
  ldy #0
: inx
  lda sz_press_start,x
  sty PPUDATA
  cmp #0
  bne :-
  rts
.endproc

.proc bg_print_ready
  ldx #$FF
: inx
  lda sz_ready,x
  sta PPUDATA
  cmp #0
  bne :-
  rts
.endproc

.proc bg_hide_ready
  ldx #$FF
  ldy #0
: inx
  lda sz_ready,x
  sty PPUDATA
  cmp #0
  bne :-
  rts
.endproc

.proc bg_print_player1scores
  ldx #$FF
: inx
  lda sz_player1scores,x
  sta PPUDATA
  cmp #0
  bne :-
  rts
.endproc

.proc bg_hide_player1scores
  ldx #$FF
  ldy #0
: inx
  lda sz_player1scores,x
  sty PPUDATA
  cmp #0
  bne :-
  rts
.endproc

.proc bg_print_player2scores
  ldx #$FF
: inx
  lda sz_player2scores,x
  sta PPUDATA
  cmp #0
  bne :-
  rts
.endproc

.proc bg_hide_player2scores
  ldx #$FF
  ldy #0
: inx
  lda sz_player2scores,x
  sty PPUDATA
  cmp #0
  bne :-
  rts
.endproc

.proc bg_print_player1wins
  ldx #$FF
: inx
  lda sz_player1wins,x
  sta PPUDATA
  cmp #0
  bne :-
  rts
.endproc

.proc bg_hide_player1wins
  ldx #$FF
  ldy #0
: inx
  lda sz_player1wins,x
  sty PPUDATA
  cmp #0
  bne :-
  rts
.endproc

.proc bg_print_player2wins
  ldx #$FF
: inx
  lda sz_player2wins,x
  sta PPUDATA
  cmp #0
  bne :-
  rts
.endproc

.proc bg_hide_player2wins
  ldx #$FF
  ldy #0
: inx
  lda sz_player2wins,x
  sty PPUDATA
  cmp #0
  bne :-
  rts
.endproc

; Prereq: Must load bg addr into PPUADDR before calling this.
; X - Integer value 0-9 to print on base 10
.proc bg_print_value
  txa
  clc
  adc #48
  sta PPUDATA
  rts
.endproc

; Disables rendering of objects and background. E.g. should 
; be called before modifying background.
.proc disable_bgobj
  lda #PPUCTRL_VBLANK_NMI
  sta PPUCTRL
  rts
.endproc

; Enables rendering of objects and background. E.g. should 
; be called after modifying background.
.proc enable_bgobj
  ldx screen_x
  ldy screen_y
  lda #PPUCTRL_VBLANK_NMI|PPUCTRL_BG_0000|PPUCTRL_OBJ_0000
  sec
  bit PPUSTATUS   ; Clear VBLANK flag to avoid immediate NMI
  jsr ppu_on_all
  rts
.endproc

.proc sample_inputs
readjoy:
  lda #$01
  sta JOYPAD1
  sta joypad2     ; player 2's buttons double as a ring counter
  lsr a           ; now A is 0
  sta JOYPAD1
loop:
  lda JOYPAD1
  and #%00000011  ; ignore bits other than controller
  cmp #$01        ; Set carry if and only if nonzero
  rol joypad1     ; Carry -> bit 0; bit 7 -> Carry
  lda JOYPAD2     ; Repeat
  and #%00000011
  cmp #$01
  rol joypad2     ; Carry -> bit 0; bit 7 -> Carry
  bcc loop
  rts
.endproc

.proc main_init
  ; Load default "base" palette.
  jsr ppu_load_default_palette

  ; Load nametable palette to be used for intro screen.
  jsr load_bg_intro_palette

  ; Init game state
  lda #GAME_STATE_INTRO
  sta curr_gamestate
  sta next_gamestate

  ; Enable NMI, but disable rendering of BG and OBJs.
  lda #PPUCTRL_VBLANK_NMI
  sta PPUCTRL

  ; Clear first nametable.
  ;lda #$00
  ;ldx #$20
  ;ldy #$AA
  ;jsr ppu_clear_nt

  ; Clear third nametable.
  ;lda #$00
  ;ldx #$28
  ;ldy #$AA
  ;jsr ppu_clear_nt

  ; Load introscreens
  jsr load_intro_nt1
  jsr load_intro_nt2

  ; Enable NMI, and enable rendering of BG and OBJs again.
  lda #PPUCTRL_VBLANK_NMI|PPUCTRL_BG_0000|PPUCTRL_OBJ_0000
  sta PPUCTRL

  lda #0
  sta screen_x
  sta screen_y
  sta screen_dx
  sta screen_dx+1
  sta screen_dy
  sta screen_dy+1
  sta screen_ddx
  sta screen_ddx+1
  sta screen_ddy
  lda #15
  sta screen_ddy+1

  rts
.endproc

.proc main_frame_intro
  clc
  lda screen_y
  adc screen_dy            ; Get y-position from High byte
  sta screen_y

  clc
  lda screen_dy+1          ; Low byte
  adc screen_ddy+1
  sta screen_dy+1
  lda screen_dy            ; High byte
  adc screen_ddy 
  sta screen_dy 

  clc
  lda screen_y
  cmp #SCREEN_YSIZE-1
  bcc done
  lda #SCREEN_YSIZE-1     ; Ugly reset of position..
  sta screen_y
  clc                     ; Divide speed by 2 (assumes speed is positive)
  ror screen_dy
  ror screen_dy+1
  neg screen_dy           ; Negate speed, TODO: Not done properly for 16-bit unsigned right now..
  neg screen_dy+1

  lda screen_dy
  cmp #0
  bne done

  lda #0                  ; TODO: Move to somewhere reusable?
  sta screen_x
  sta screen_dx
  sta screen_dx+1
  sta screen_dy
  sta screen_dy+1
  sta screen_ddx
  sta screen_ddx+1
  sta screen_ddy
  sta screen_ddy+1
  lda #SCREEN_YSIZE-1
  sta screen_y

  ; Transition to game menu
  lda #GAME_STATE_MENU
  sta next_gamestate
done:
  rts
.endproc

.proc main_frame_menu
  jsr sample_inputs

  ; Start game if either of joypads pushes START
check_joypad1:
  lda joypad1
  and #JOYPAD_KEY_START
  beq check_joypad2
  jmp start_game

check_joypad2:
  lda joypad2
  and #JOYPAD_KEY_START
  beq done

start_game:
  ; Transition to ready
  lda #GAME_STATE_READY
  sta next_gamestate

done:
  rts
.endproc

.proc main_frame_ready
  jsr obj_pad1_update
  jsr obj_pad2_update

  ; Reset draw state
  lda #0
  sta oam_offset

  jsr obj_pad1_draw
  jsr obj_pad2_draw

  lda timer1
  cmp #0
  bne :+

  ; Transition to in-game
  lda #GAME_STATE_GAME
  sta next_gamestate

: rts
.endproc

.proc main_frame_game
  jsr obj_pad1_process_input
  jsr obj_pad2_process_input

  jsr obj_pad1_update
  jsr obj_pad2_update
  jsr obj_ball_update

  jsr resolve_collisions

  ; Reset draw state
  lda #0
  sta oam_offset

  jsr obj_pad1_draw
  jsr obj_pad2_draw
  jsr obj_ball_draw

  rts
.endproc

.proc main_frame_pause
  ; TODO: Implement support

  rts
.endproc

.proc main_frame_p1score
  jsr obj_pad1_process_input
  jsr obj_pad2_process_input

  jsr obj_pad1_update
  jsr obj_pad2_update

  jsr resolve_collisions

  ; Reset draw state
  lda #0
  sta oam_offset

  jsr obj_pad1_draw
  jsr obj_pad2_draw

  ; Display the score text for a while
  lda timer1
  cmp #0
  bne done

  ; Check if player 1 won the game
  lda p1score
  cmp #MAX_SCORE
  beq endgame

  ; Transition to running state
  lda #GAME_STATE_GAME
  sta next_gamestate
  rts

endgame:
  ; Transition to winner state
  lda #GAME_STATE_P1WINS
  sta next_gamestate

done:
  rts
.endproc

.proc main_frame_p2score
  jsr obj_pad1_process_input
  jsr obj_pad2_process_input

  jsr obj_pad1_update
  jsr obj_pad2_update

  jsr resolve_collisions

  ; Reset draw state
  lda #0
  sta oam_offset

  jsr obj_pad1_draw
  jsr obj_pad2_draw

  ; Display the score text for a while
  lda timer1
  cmp #0
  bne done

  ; Check if player 2 won the game
  lda p2score
  cmp #MAX_SCORE
  beq endgame

  ; Transition to running state
  lda #GAME_STATE_GAME
  sta next_gamestate
  rts

endgame:
  ; Transition to winner state
  lda #GAME_STATE_P2WINS
  sta next_gamestate

done:
  rts
.endproc

.proc main_frame_p1wins
  jsr sample_inputs

  ; Start a new game if either of joypads pushes START
check_joypad1:
  lda joypad1
  and #JOYPAD_KEY_START
  beq check_joypad2
  jmp start_game

check_joypad2:
  lda joypad2
  and #JOYPAD_KEY_START
  beq done

start_game:
  ; Transition to ready
  lda #GAME_STATE_READY
  sta next_gamestate

done:
  rts
.endproc

.proc main_frame_p2wins
  jsr sample_inputs

  ; Start a new game if either of joypads pushes START
check_joypad1:
  lda joypad1
  and #JOYPAD_KEY_START
  beq check_joypad2
  jmp start_game

check_joypad2:
  lda joypad2
  and #JOYPAD_KEY_START
  beq done

start_game:
  ; Transition to ready
  lda #GAME_STATE_READY
  sta next_gamestate

done:
  rts
.endproc

.proc process_gamestate
  lda curr_gamestate
  cmp #GAME_STATE_INTRO
  bne :+
  jsr main_frame_intro
  jmp done
: cmp #GAME_STATE_MENU
  bne :+
  jsr main_frame_menu
  jmp done
: cmp #GAME_STATE_READY
  bne :+
  jsr main_frame_ready
  jmp done
: cmp #GAME_STATE_GAME
  bne :+
  jsr main_frame_game
  jmp done
: cmp #GAME_STATE_PAUSE
  bne :+
  jsr main_frame_pause
  jmp done
: cmp #GAME_STATE_P1SCORE
  bne :+
  jsr main_frame_p1score
  jmp done
: cmp #GAME_STATE_P2SCORE
  bne :+
  jsr main_frame_p2score
  jmp done
: cmp #GAME_STATE_P1WINS
  bne :+
  jsr main_frame_p1wins
  jmp done
: cmp #GAME_STATE_P2WINS
  bne reset_all
  jsr main_frame_p2wins

done:
  rts

reset_all:
  ; Reset all game state if we end up in some illegal state/transition.
  jsr main_init
  rts
.endproc

.proc tr_intro_to_menu
  jsr disable_bgobj

  ; Display 'press start'-text
  lda #$29
  sta PPUADDR
  lda #$8B
  sta PPUADDR
  jsr bg_print_press_start

  jsr enable_bgobj

  rts
.endproc

.proc tr_menu_to_ready
  ; Reset scroll position
  lda #0
  sta screen_y

  ; Init all game objects.
  jsr obj_ball_init
  jsr obj_pad1_init
  jsr obj_pad2_init

  ; Init player scores
  lda #0
  sta p1score
  sta p2score

  ; Reset timer for ready-screen (150 ~= 3 seconds)
  lda #150
  sta timer1

  jsr disable_bgobj

  ; Draw background "programatically".
  ; TODO: Load as nametable from memory instead.

  ; Top wall
  lda #$20
  sta PPUADDR
  lda #$40
  sta PPUADDR
  lda #$02
  ldx #32
: sta PPUDATA
  dex
  bne :-

  ; Bottom wall
  lda #$23
  sta PPUADDR
  lda #$40
  sta PPUADDR
  lda #$02
  ldx #32
: sta PPUDATA
  dex
  bne :-

  ; Display 'player 1'-text
  lda #$20
  sta PPUADDR
  lda #$21
  sta PPUADDR
  jsr bg_print_player1

  ; Display 'player 2'-text
  lda #$20
  sta PPUADDR
  lda #$38
  sta PPUADDR
  jsr bg_print_player2

  ; Display player 1 score
  lda #$23
  sta PPUADDR
  lda #$6C
  sta PPUADDR
  ldx p1score
  jsr bg_print_value

  ; Display player 2 score
  lda #$23
  sta PPUADDR
  lda #$74
  sta PPUADDR
  ldx p2score
  jsr bg_print_value

  ; Display 'ready'-text
  lda #$21
  sta PPUADDR
  lda #$4D
  sta PPUADDR
  jsr bg_print_ready

  jsr enable_bgobj

  ; DEBUG, make some noise to try out the APU
;  lda #$01		; enable pulse 1
;  sta APU_CTRL
;  lda #$08		; period
;  sta $4002
;  lda #$02
;  sta $4003
;  lda #$ba		; volume
;  sta $4000

  rts
.endproc

.proc tr_ready_to_game
  jsr disable_bgobj

  lda #$21
  sta PPUADDR
  lda #$4D
  sta PPUADDR
  jsr bg_hide_ready

  jsr enable_bgobj

  rts
.endproc

.proc tr_game_to_pause
  ; TODO: Implement support
  rts
.endproc

.proc tr_pause_to_game
  ; TODO: Implement support
  rts
.endproc

.proc tr_game_to_p1score
  ; Kickup p1 score
  clc
  ldx p1score
  inx
  stx p1score

  ; Reset ball position
  jsr obj_ball_init

  jsr disable_bgobj
  
  ; Display player1's new score
  lda #$23
  sta PPUADDR
  lda #$6C
  sta PPUADDR
  ldx p1score
  jsr bg_print_value

  ; Display 'player 1 scores'-text
  lda #$21
  sta PPUADDR
  lda #$49
  sta PPUADDR
  jsr bg_print_player1scores

  ; Reset timer for player 1 score-screen (150 ~= 2 seconds)
  lda #100
  sta timer1

  jsr enable_bgobj

  rts
.endproc

.proc tr_game_to_p2score
  ; Kickup p2 score
  ldx p2score
  inx
  stx p2score

  ; Reset ball position
  jsr obj_ball_init

  jsr disable_bgobj
  
  ; Display player2's new score
  lda #$23
  sta PPUADDR
  lda #$74
  sta PPUADDR
  ldx p2score
  jsr bg_print_value

  ; Display 'player 2 scores'-text
  lda #$21
  sta PPUADDR
  lda #$49
  sta PPUADDR
  jsr bg_print_player2scores

  ; Reset timer for player 2 score-screen (150 ~= 2 seconds)
  lda #100
  sta timer1

  jsr enable_bgobj

  rts
.endproc

.proc tr_p1score_to_game
  jsr disable_bgobj

  lda #$21
  sta PPUADDR
  lda #$49
  sta PPUADDR
  jsr bg_hide_player1scores

  jsr enable_bgobj

  rts
.endproc

.proc tr_p2score_to_game
  jsr disable_bgobj

  lda #$21
  sta PPUADDR
  lda #$49
  sta PPUADDR
  jsr bg_hide_player2scores

  jsr enable_bgobj

  rts
.endproc

.proc tr_p1score_to_p1wins
  jsr disable_bgobj

  lda #$21
  sta PPUADDR
  lda #$44
  sta PPUADDR
  jsr bg_print_player1wins

  jsr enable_bgobj

  rts
.endproc

.proc tr_p2score_to_p2wins
  jsr disable_bgobj

  lda #$21
  sta PPUADDR
  lda #$44
  sta PPUADDR
  jsr bg_print_player2wins

  jsr enable_bgobj

  rts
.endproc

.proc tr_p1wins_to_ready
  ; Init all game objects.
  jsr obj_ball_init
  jsr obj_pad1_init
  jsr obj_pad2_init

  ; Init player scores
  lda #0
  sta p1score
  sta p2score

  ; Reset timer for ready-screen (150 ~= 3 seconds)
  lda #150
  sta timer1

  jsr disable_bgobj

  lda #$21
  sta PPUADDR
  lda #$44
  sta PPUADDR
  jsr bg_hide_player1wins

  ; Display player 1 score
  lda #$23
  sta PPUADDR
  lda #$6C
  sta PPUADDR
  ldx p1score
  jsr bg_print_value

  ; Display player 2 score
  lda #$23
  sta PPUADDR
  lda #$74
  sta PPUADDR
  ldx p2score
  jsr bg_print_value

  ; Display 'ready'-text
  lda #$21
  sta PPUADDR
  lda #$4D
  sta PPUADDR
  jsr bg_print_ready

  jsr enable_bgobj

  rts
.endproc

.proc tr_p2wins_to_ready
  ; Init all game objects.
  jsr obj_ball_init
  jsr obj_pad1_init
  jsr obj_pad2_init

  ; Init player scores
  lda #0
  sta p1score
  sta p2score

  ; Reset timer for ready-screen (150 ~= 3 seconds)
  lda #150
  sta timer1

  jsr disable_bgobj

  lda #$21
  sta PPUADDR
  lda #$44
  sta PPUADDR
  jsr bg_hide_player2wins

  ; Display player 1 score
  lda #$23
  sta PPUADDR
  lda #$6C
  sta PPUADDR
  ldx p1score
  jsr bg_print_value

  ; Display player 2 score
  lda #$23
  sta PPUADDR
  lda #$74
  sta PPUADDR
  ldx p2score
  jsr bg_print_value

  ; Display 'ready'-text
  lda #$21
  sta PPUADDR
  lda #$4D
  sta PPUADDR
  jsr bg_print_ready

  jsr enable_bgobj

  rts
.endproc

.proc update_gamestate
  lda curr_gamestate
  cmp next_gamestate
  bne process_transition
  rts

process_transition:
.repeat 4
  asl a 
.endrepeat
  ora next_gamestate
  cmp #GAME_STATE_TR_INTRO_TO_MENU
  bne :+
  jsr tr_intro_to_menu
  jmp done
: cmp #GAME_STATE_TR_MENU_TO_READY
  bne :+
  jsr tr_menu_to_ready
  jmp done
: cmp #GAME_STATE_TR_READY_TO_GAME
  bne :+
  jsr tr_ready_to_game
  jmp done
: cmp #GAME_STATE_TR_GAME_TO_PAUSE
  bne :+
  jsr tr_game_to_pause
  jmp done
: cmp #GAME_STATE_TR_PAUSE_TO_GAME
  bne :+
  jsr tr_pause_to_game
  jmp done
: cmp #GAME_STATE_TR_GAME_TO_P1SCORE
  bne :+
  jsr tr_game_to_p1score
  jmp done
: cmp #GAME_STATE_TR_GAME_TO_P2SCORE
  bne :+
  jsr tr_game_to_p2score
  jmp done
: cmp #GAME_STATE_TR_P1SCORE_TO_GAME
  bne :+
  jsr tr_p1score_to_game
  jmp done
: cmp #GAME_STATE_TR_P2SCORE_TO_GAME
  bne :+
  jsr tr_p2score_to_game
  jmp done
: cmp #GAME_STATE_TR_P1SCORE_TO_P1WINS
  bne :+
  jsr tr_p1score_to_p1wins
  jmp done
: cmp #GAME_STATE_TR_P2SCORE_TO_P2WINS
  bne :+
  jsr tr_p2score_to_p2wins
  jmp done
: cmp #GAME_STATE_TR_P1WINS_TO_READY
  bne :+
  jsr tr_p1wins_to_ready
  jmp done
: cmp #GAME_STATE_TR_P2WINS_TO_READY
  bne reset_all
  jsr tr_p2wins_to_ready

done: 
  lda next_gamestate
  sta curr_gamestate
  rts

reset_all:
  ; Reset all game state if we end up in some illegal state/transition.
  jsr main_init
  rts
.endproc

.proc main_frame
  jsr sample_inputs
  jsr process_gamestate
  jsr update_gamestate

  ; Hide all OAM objects that are not to be drawn
  ldx oam_offset
  jsr ppu_hide_unused_oam

  ; Wait for NMI
  jsr ppu_wait_nmi

  ; Load 256 bytes of data from RAM ($0200) to the internal PPU OAM
  lda #0
  sta OAMADDR
  lda #>OAM          ; Load OAM RAM address, high byte ($02)
  sta OAMDMA

  ; Turn the screen on
  ldx screen_x
  ldy screen_y
  lda #PPUCTRL_VBLANK_NMI|PPUCTRL_BG_0000|PPUCTRL_OBJ_0000
  sec
  jsr ppu_on_all

  rts
.endproc

