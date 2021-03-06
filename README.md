# 6502
A place to keep my 6502 breadboard computer assembler programs.

My current computer is a bit like a Kim-1 or Acorn System 1 single board computer with a hex keypad for entering machine code programs. Its design is based on the work of Ben Eater https://eater.net/6502 up to but not including the part where he adds a physical button. Instead I added a shift key and a hex keypad with an encoder chip. Read my blog for more information: http://www.suppertime.co.uk/blogmywiki/2021/03/6502-breadboard-computer-part-5-hex-keypad/

I've written a user manual for this computer as if it had been produced in 1979 rather than 2021 - see 'micron 1 manual.pdf'.

Assembly language .s files are assembled using vasm in 6502 'oldstyle' mode, eg 
`./vasm6502_oldstyle -Fbin -dotdir monitor2.s `
Flashed to EEPROM using minipro:
`minipro -p AT28C256 -w a.out`



## hello world
Prints text to LCD display using RAM for stack pointer and VIA to interface with LCD

## irq
Prints some different text with a button connected to VIA CA1 pin

## monitor1
Really dreadful code, first steps towards a monitor program. Shows contents of ROM on LCD display: address, hex contents, ASCII representation.
Press button on CA1 to advance.
Only steps through 256 bytes.
Byte to ASCII hex code needs putting in a subroutine.
Weird sh&t going on with the X register - had to paste display code in before infinite loop otherwise x was not reset to 0, why this makes any difference beats me.
The ASCII offset for converting hex numbers A-F is mad - should be #41 not #30. Why? WHY DOES #41 WORK? IT MAKES NO SENSE.

## monitor2
Slightly less dreadful.
Folds hex>ascii conversion into subroutines.
.out file is raw binary for flashing to EEPROM.

## hex-b-2.s
Test program to type characters on the LCD display from a 4x4 matrix keypad attached via a 74C922 encoder chip.
More info here: http://www.suppertime.co.uk/blogmywiki/2021/03/6502-breadboard-computer-part-5-hex-keypad/

## hex-shift-demo.s
Demo of shift key wired via pull-down resistor to 6522 pin PA4. Shift-D steps forwards in memory, shift-C steps back.
More info here: http://www.suppertime.co.uk/blogmywiki/2021/03/6502-breadboard-computer-part-6-shift-key/

## monitor3.s
First working monitor program.
- Programs must be 256 bytes or less and reside at $0300
- step forwards with shift-D, back with shift-C
- enter opcodes data directly with keypad
- run program with shift-A, always starts at $0300
- press reset button on CPU to drop back into the monitor
