.PHONY: clean all

.PRECIOUS: *.o

all: ballzy.nes run

clean:
	@rm -fv ppu.o init.o main.o
	@rm -fv ballzy.nes.map
	@rm -fv ballzy.nes

run: ballzy.nes
	fceux $< --xscale 4 --yscale 4

%.o: %.s
	ca65 $*.s

%.nes: ppu.o init.o obj_ball.o obj_pad1.o obj_pad2.o collision.o main.o
	ld65 -C nes.cfg -m $@.map -o $@ ppu.o init.o obj_ball.o obj_pad1.o obj_pad2.o collision.o main.o
