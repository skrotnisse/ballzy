; General registers
JOYPAD1           = $4016
JOYPAD2           = $4017

; Joypad bitmasks
JOYPAD_KEY_A      = %10000000
JOYPAD_KEY_B      = %01000000
JOYPAD_KEY_SELECT = %00100000
JOYPAD_KEY_START  = %00010000
JOYPAD_KEY_UP     = %00001000
JOYPAD_KEY_DOWN   = %00000100
JOYPAD_KEY_LEFT   = %00000010
JOYPAD_KEY_RIGHT  = %00000001

; PPU registers
PPUCTRL       = $2000
PPUMASK	      = $2001
PPUSTATUS     = $2002
OAMADDR	      = $2003
OAMDATA	      = $2004
PPUSCROLL     = $2005
PPUADDR	      = $2006
PPUDATA	      = $2007
OAMDMA        = $4014
OAM           = $0200

; PPUCONTROL commands
PPUCTRL_VRAM_DOWN  = $04
PPUCTRL_OBJ_0000   = $00
PPUCTRL_OBJ_1000   = $08
PPUCTRL_BG_0000    = $00
PPUCTRL_BG_1000    = $10
PPUCTRL_VBLANK_NMI = $80

; PPUMASK commands
PPUMASK_BG_OFF     = $00
PPUMASK_BG_ON      = $08
PPUMASK_BG_CLIP    = $0A
PPUMASK_OBJ_OFF    = $00
PPUMASK_OBJ_ON     = $10
PPUMASK_OBJ_CLIP   = $14
PPUMASK_TINT_RED   = $20
PPUMASK_TINT_GREEN = $40
PPUMASK_TINT_BLUE  = $80

; APU registers
APU_DMCC_CTRL = $4010
APU_CTRL      = $4015
APU_FRAMECNT  = $4017

; NES screen size (nametable) in pixels
SCREEN_XSIZE      = 256
SCREEN_YSIZE      = 240

; FamiTone2 settings
FT_BASE_ADR     = $0100 ; Page in the RAM used for FT2 variables, should be $xx00
FT_TEMP         = $E0   ; 3 bytes in zeropage used by the library as a scratchpad
FT_DPCM_OFF     = $C000 ; DPCM offset, $C000..$FFC0, 64-byte steps (DMC must be stored at >= $C000)
FT_SFX_STREAMS  = 4     ; Number of sound effects played at once, 1..4

FT_DPCM_ENABLE  = 1     ; Enable/disable DMC mode
FT_SFX_ENABLE   = 0     ; Exclude/include sound effects code
FT_THREAD       = 1     ; Define if calling sound effects from the same thread as the sound update call

FT_PAL_SUPPORT  = 1     ; Enable/disable PAL support
FT_NTSC_SUPPORT = 1     ; Enable/disable NTSC support

