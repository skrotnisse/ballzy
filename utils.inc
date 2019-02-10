
; Macro to perform 2-complement negation on 'arg'.
.macro neg arg
  pha
  lda arg
  eor #$FF
  sta arg
  inc arg
  pla
.endmacro

