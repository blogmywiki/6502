; first steps towards a monitor program
; v2 folding hex>ascii conversion into subroutines

PORTB = $6000	; addresses of VIA ports
PORTA = $6001	
DDRB = $6002	; addresses of VIA data direction registers
DDRA = $6003
PCR = $600c		; peripheral control register
IFR = $600d		; interrupt flag register
IER = $600e		; interrupt enable register

E  = %10000000
RW = %01000000
RS = %00100000

  .org $8000

reset:
  ldx #$ff		; set stack pointer to FF
  txs
  cli			; clear interrupt disable bit
  
  lda #$82		; configure interrupt enable register for CA1 pin
  sta IER
  lda #$00		; configure peripheral control register for negative active edge
  sta PCR

  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  lda #%11100000 ; Set top 3 pins on port A to output
  sta DDRA

  lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001100 ; Display on; cursor off; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  
  ldx #$0
print:
  lda splash,x
  beq end_print
  jsr print_char
  inx
  jmp print

end_print:
  ldy #$0	; reset y to zero as used for address counter
  
loop:
  jmp loop
  
splash: .asciiz "                                        Micron 1 monitor"

lcd_wait:
  pha
  lda #%00000000  ; Port B is input
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB
  and #%10000000
  bne lcdbusy

  lda #RW
  sta PORTA
  lda #%11111111  ; Port B is output
  sta DDRB
  pla
  rts
  
lcd_instruction:
  jsr lcd_wait
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set E bit to send instruction
  sta PORTA
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  rts
  
print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set E bit to send instruction
  sta PORTA
  lda #RS         ; Clear E bits
  sta PORTA
  rts

hex_ascii_hi:		; return ascii character of most significant nibble
  and #%11110000
  ror
  ror
  ror
  ror
  cmp #10
  bcc num_hi
  adc #$36 			; add offset for letters, no idea why it's 36
  rts
num_hi:
  adc #$30 			; add offset for numbers 
  rts

hex_ascii_lo:		; return ascii character of least significant nibble
  and #%00001111
  cmp #10
  bcc num_lo
  adc #$36 			; add offset for letters, no idea why it's 36
  rts
num_lo:
  adc #$30 			; add offset for numbers 
  rts

nmi:
  rti
  
irq:
  lda #%00000010 ; put LCD cursor at home position
  jsr lcd_instruction
  lda #"8"
  jsr print_char
  lda #"0"
  jsr print_char
  
; convert index from hex to ascii to display address  
  tya
  jsr hex_ascii_hi
  jsr print_char  
  tya
  jsr hex_ascii_lo
  jsr print_char  
  
; display hex value at address
  lda #" "
  jsr print_char 
  lda $8000,y
  jsr hex_ascii_hi
  jsr print_char  
  lda $8000,y
  jsr hex_ascii_lo
  jsr print_char  

; display ascii equivalent
  lda #" "
  jsr print_char
  lda $8000,y
  jsr print_char

  iny
  bit PORTA				; clear interrupt by reading PORTA
  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq