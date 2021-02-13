PORTB = $6000	; addresses of VIA ports
PORTA = $6001	
DDRB = $6002	; addresses of VIA data direction registers
DDRA = $6003
PCR = $600c		; peripheral control register
IFR = $600d		; interrupt flag register
IER = $600e		; interrupt enable register
; address_counter = $0200 ; 2 byte counter to keep track of address being shown

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
  lda splash,x
  beq end_print
  jsr print_char
  inx
  jmp print
  
;  lda #$00		; store starting address in address_counter
;  sta address_counter
;  lda #$80
;  sta address_counter + 1

end_print:
  ldx #0	; reset x to zero as used for address counter
  
  
; debug-----------
  lda #%00000001 ; Clear display - should replace with 010 home
  jsr lcd_instruction
  lda #"8"
  jsr print_char
  lda #"0"
  jsr print_char
  
  txa
  and #%11110000
  ror
  ror
  ror
  ror
  cmp #10
  bcc ascc
  adc #$36 			; add offset for letters, no idea why it's 36
  jmp print_ascc
ascc:
  adc #$30 			; add offset for numbers 
print_ascc:
  jsr print_char  

  txa
  and #%00001111
  cmp #10
  bcc ascd
  adc #$36 			; add offset for letters, no idea why it's 36
  jmp print_ascd
ascd:
  adc #$30 			; add offset for numbers 
print_ascd:
  jsr print_char  
  
  lda #" "
  jsr print_char
  
  lda $8000,x
  jsr print_char
  inx
; debug-------
  
  

loop:
  jmp loop
  
splash: .asciiz "    Micron 1                              @blogmywiki"

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
;  inc address_counter
;  bne update
;  inc address_counter + 1
;update
  lda #%00000001 ; Clear display - should replace with 010 home
  jsr lcd_instruction
  lda #"8"
  jsr print_char
  lda #"0"
  jsr print_char
  
  
; convert index from hex to ascii to display address  

  txa
  and #%11110000
  ror
  ror
  ror
  ror
  cmp #10
  bcc asca
  adc #$36 			; add offset for letters, no idea why it's 36
  jmp print_asca
asca:
  adc #$30 			; add offset for numbers 
print_asca:
  jsr print_char  

  txa
  and #%00001111
  cmp #10
  bcc ascb
  adc #$36 			; add offset for letters, no idea why it's 36
  jmp print_ascb
ascb:
  adc #$30 			; add offset for numbers 
print_ascb:
  jsr print_char  
  
; display hex value at address
  
  lda #" "
  jsr print_char
  
  lda $8000,x
  and #%11110000
  ror
  ror
  ror
  ror
  cmp #10
  bcc asce
  adc #$36 			; add offset for letters, no idea why it's 36
  jmp print_asce
asce:
  adc #$30 			; add offset for numbers 
print_asce:
  jsr print_char  

  lda $8000,x
  and #%00001111
  cmp #10
  bcc ascf
  adc #$36 			; add offset for letters, no idea why it's 36
  jmp print_ascf
ascf:
  adc #$30 			; add offset for numbers 
print_ascf:
  jsr print_char  

  
  lda #" "
  jsr print_char
  
    
  lda $8000,x
  jsr print_char
  inx
  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq
  