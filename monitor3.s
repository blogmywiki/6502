; stab at a working monitor program
; programs must be 256 bytes or less and reside at $0300
; step forwards with shift-D, back with shift-C
; enter opcodes data directly with keypad
; run p rogram with shift-A, always starts at $0300

PORTB = $6000	; addresses of VIA ports
PORTA = $6001	
DDRB = $6002	; addresses of VIA data direction registers
DDRA = $6003
PCR = $600c		; peripheral control register
IFR = $600d		; interrupt flag register
IER = $600e		; interrupt enable register

inport = $0200  	; contents of PORTA, 1 byte
inkey = $0201		; value of last key pressed, 1 byte
shift = $0202		; flag - have I pressed shift? 1 byte, though frankly 1 *bit* would do
lo_ascii = $0203	; low nibble of memory contents expressed as ascii hex digit
hi_ascii = $0204	; high nibble of memory contents expressed as ascii hex digit
temp_data = $0205	; temporary store for data being written back to RAM
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
  lda #$00		; clear the shift flag
  sta shift
  txs
  
  jsr refresh_ascii_nibbles
  
  lda #$0
  sta temp_data
  
  lda #$82			; configure interrupt enable register for CA1 pin
  sta IER
  lda #%00000001	; configure PCR for positive active edge - was previously 0 for negative
  sta PCR

  lda #%11111111 	; Set all pins on port B to output
  sta DDRB
  lda #%11100000 	; Set top 3 pins on port A to output
  sta DDRA

  lda #%00111000 	; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001100 	; Display on; cursor off; blink off
  jsr lcd_instruction
  lda #%00000110 	; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 	; Clear display
  jsr lcd_instruction
  
; print the splash screen
  ldx #$00
print_splash:
  lda splash,x
  beq end_splash
  jsr print_char
  inx
  jmp print_splash
    
end_splash:  
  ldx #$00			; clear the x register
  jsr lcd_update	; initialise the monitor display

  cli				; interrupts on
  
loop:
  jmp loop
  
splash: .asciiz "                                        Micron 1 monitor"
keys:   .byte "174F396E2850ACBD"

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
  
ascii_hex:			; convert 2 ascii digits to 1 hex value and store at current location
  clc				; clear carry flag in case that makes a difference *waves dead chicken* - narrator: it didn't make any difference
  lda lo_ascii
  cmp #$41			; if it's below $41 it's a number
  bcc asc_num_lo
  sbc #$37			; subtract letter offset - should be $36
  jmp asc_lo
asc_num_lo:
  sbc #$2F			; should be $30
asc_lo:
  clc				; clear carry flag again why don't you
  sta temp_data		; store the numerical equivalent of low ascii nibble in temp_data
  lda hi_ascii
  cmp #$41			; if it's below $41 it's a number
  bcc asc_num_hi
  sbc #$37			; subtract letter offset - should be $36
  jmp asc_store
asc_num_hi:
  sbc #$2F			; subtract letter offset - should be $30
asc_store:
  clc
  rol
  rol
  rol
  rol
  adc temp_data
  sta $0300,y
  rts
  
refresh_ascii_nibbles:
  lda $0300,y
  jsr hex_ascii_lo
  sta lo_ascii
  lda $0300,y
  jsr hex_ascii_hi
  sta hi_ascii
  rts
  
lcd_update:
  lda #%00000010 ; put LCD cursor at home position
  jsr lcd_instruction
  lda #"0"
  jsr print_char
  lda #"3"
  jsr print_char
  
; convert index from hex to ascii to display address
  tya
  jsr hex_ascii_hi
  jsr print_char  
  tya
  jsr hex_ascii_lo
  jsr print_char  
 
; display memory high nibble as hex
  lda #" "
  jsr print_char
  lda hi_ascii
  jsr print_char 
; display memory low nibble hex
  lda lo_ascii
  jsr print_char 

; display ascii equivalent
  lda #" "
  jsr print_char
  lda $0300,y		; was $8000
  jsr print_char
  
; test print last-pressed character - remove eventually
;  lda #" "
;  jsr print_char
;  lda inkey		    ; fetch the value of the last pressed key
;  tax				; put it in x for an offset
;  lda keys,x		; fetch the ascii value of the relevant key 
;  jsr print_char 	; print it
  
  rts

nmi:
; maybe this should be wired to a discrete stop key?
  rti
  
irq:
; so, you've pressed a button...
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
  lda lo_ascii		; transfer low ascii nibble to high
  sta hi_ascii
  lda inkey			; store key press in new low nibble
  tax
  lda keys,x
  sta lo_ascii
  jsr ascii_hex				; load the new data into memory
  jmp update				; if no shift key is pressed just update the display
shift_cont:			
  lda #%00001111			; is the key 'd'?
  cmp inkey			
  bne key_c					; if not, jump to next test
  iny						; if it is 'd', increment the location being displayed
  jmp no_shift_update
key_c:
  lda #%00001101			; is it 'C'?
  cmp inkey
  bne key_a					; if not, skip to next test
  dey						; if it is, decrement location index
key_a:
  lda #%00001100			; is it 'A'?
  cmp inkey
  bne no_shift_update		; if not, skip GO
  jmp $0300					; if it is A, GO! to $0300 to run user-entered program; change to run from current memory location!
no_shift_update:
  jsr refresh_ascii_nibbles	; update the ascii nibbles for new address
update:
  jsr lcd_update			; update the display
  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq