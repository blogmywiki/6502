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
  
  ldx #0
print:
  lda message,x
  beq loop
  jsr print_char
  inx
  jmp print

loop:
  jmp loop
  
message: .asciiz "    Micron 1                              @blogmywiki"
mess_btn: .asciiz "You pressed                             a button!"

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
  
nmi:
  rti
  
irq:
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  ldx #0
print_btn:
  lda mess_btn,x
  beq exit_irq
  jsr print_char
  inx
  jmp print_btn
exit_irq:
  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq
  