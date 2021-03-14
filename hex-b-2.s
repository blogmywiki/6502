; first steps getting a hex keypad working
; just a demo typing numbers, letters and symbols on the LCD

PORTB = $6000	; addresses of VIA ports
PORTA = $6001	
DDRB = $6002	; addresses of VIA data direction registers
DDRA = $6003
PCR = $600c		; peripheral control register
IFR = $600d		; interrupt flag register
IER = $600e		; interrupt enable register

inkey = $0200	; value of last key pressed may go in here
E  = %10000000
RW = %01000000
RS = %00100000

  .org $8000

reset:
  sei			; interrupts off
  cld			; clear decimal mode
  clc			; clear carry bit
  ldy #$00		; reset y to zero - used for address counter
  ldx #$ff		; set stack pointer to FF
  txs
  
  lda #$82		; configure interrupt enable register for CA1 pin
  sta IER
  lda #%00000001	; configure PCR for positive active edge - was previously 0 for negative
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
  
  cli			; interrupts on
  
; print the splash screen
  ldx #$0
print_splash:
  lda splash,x
  beq end_splash
  jsr print_char
  inx
  jmp print_splash
  
end_splash:  
  ldx #$0
  lda #%00000010 ; put LCD cursor at home position
  jsr lcd_instruction

    
loop:
;  the main monitor program is commented out so we can just see typing on the LCD
;  lda #%00000010 ; put LCD cursor at home position
;  jsr lcd_instruction
;  lda #"8"
;  jsr print_char
;  lda #"0"
;  jsr print_char
  
; convert index from hex to ascii to display address  
;  tya
;  jsr hex_ascii_hi
;  jsr print_char  
;  tya
;  jsr hex_ascii_lo
;  jsr print_char  
  
; display hex value at address
;  lda #" "
;  jsr print_char 
;  lda $8000,y
;  jsr hex_ascii_hi
;  jsr print_char  
;  lda $8000,y
;  jsr hex_ascii_lo
;  jsr print_char  

; display ascii equivalent
;  lda #" "
;  jsr print_char
;  lda $8000,y
;  jsr print_char

  jmp loop
  
splash: .asciiz "                                        Micron 1"
keys:   .byte "174*396#2850ACBD"

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
; moved screen updating from here to main loop
  iny				; increment y for monitor memory offset - not used here
  
  lda PORTA
  and #%00001111
;  sta inkey		; maybe I'll need this later
  tax
  lda keys,x
  jsr print_char  

;  bit PORTA				; clear interrupt by reading PORTA - doesn't seem to be needed now I am actually reading port A
  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq