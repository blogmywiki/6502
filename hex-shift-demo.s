; first steps getting a hex keypad working
; just a demo typing numbers, letters and symbols on the LCD
; print key character on monitor display
; use shift key on PA4 to make step forward & back keys D and C work

PORTB = $6000	; addresses of VIA ports
PORTA = $6001	
DDRB = $6002	; addresses of VIA data direction registers
DDRA = $6003
PCR = $600c		; peripheral control register
IFR = $600d		; interrupt flag register
IER = $600e		; interrupt enable register

inport = $0200  ; contents of PORTA, 1 byte
inkey = $0201	; value of last key pressed, 1 byte
shift = $0202	; flag - have I pressed shift? 1 byte, though frankly 1 *bit* would do
;memloc = $0203	; holds the current memory location offset
shift_debug = $0203
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
;  lda #0		; set initial memory offset to 0
;  sta memloc
  lda #$00		; clear the shift flag
  sta shift
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
  ldx #$00
print_splash:
  lda splash,x
  beq end_splash
  jsr print_char
  inx
  jmp print_splash
  
end_splash:  
  ldx #$00		; clear the x register
  jsr lcd_mon	; initialise the monitor display
  
loop:
  jmp loop
  
splash: .asciiz "                                        Micron 1 monitor"
keys:   .byte "174F396E2850ACBD"
;sh:		.byte "01"

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
  clc				; clear carry flag or you may rotate rubbish into the number
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

lcd_mon:
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

; test print last-pressed character
  lda #" "
  jsr print_char
  lda inkey		    ; fetch the value of the last pressed key
  tax				; put it in x for an offset
  lda keys,x		; fetch the ascii value of the relevant key 
  jsr print_char 	; print it
  
  rts

nmi:
; maybe this should be wired to a discrete stop key?
  rti
  
irq:
  lda PORTA			; read contents of PORTA into memory
  sta inport
  lda inport		; read the state of PORTA back into A again - needed?
  and #%00001111	; strip out all but the key encoding
  sta inkey		    ; store the key value in memory
  lda inport		; read the state of PORTA back into A again
  and #%00010000	; read the shift key input
  beq no_shift		; if zero flag set, no shift key is pressed
  lda #$01			; if shift pressed, set shift flag
  sta shift
  jmp shift_cont	; skip clearing the shift flag, obvs
no_shift:
  lda #$00			; if shift not pressed, clear shift flag
  sta shift
  jmp update		; if no shift key is pressed just update the display
shift_cont:			; there was a colon missing here but it worked!
  lda #%00001111	; is the key 'd'?
  cmp inkey			
  bne key_c			; if not, jump to next test
  iny				; if it is 'd', increment the location being displayed
key_c:
  lda #%00001101	; is it 'C'?
  cmp inkey
  bne update		; if not, skip decrementing
  dey				; if it is, decrement location index
update:
  jsr lcd_mon
  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq