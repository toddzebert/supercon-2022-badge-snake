TARGET:=snake
PORT:=/dev/ttyUSB1
ASSEMBLER:=../../2022-Supercon6-Badge-Tools/assembler/assemble.py

all: $(TARGET).hex flash

%.hex: %.asm
	$(ASSEMBLER) $^

flash: $(TARGET).hex
	stty -F $(PORT) raw
	cat $^ > $(PORT)


