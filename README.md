# 6502
A place to keep my 6502 breadboard computer assembler programs

Based on the work of Ben Eater https://eater.net/6502

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
Displays x register - for some reason this fixes bug displaying MSN as 'G0' instead of '00' - no idea why, this makes no sense.
