.include "m8def.inc"

.def temp = r22
.def mode = r23
.def Pointer = r25
.def counter = r19
.def counter2 = r20
.def counter3 = r21


.def Ist_1 = r12
.def Ist_2 = r10
.def temp2 = r24
.def Ziel_2 = r9

.def Stop_1 = r15
.def null = r13
.def Glas = r11
.def gesamt = r8

.equ XTAL = 8000000                            ; Baudrate

.def temp1 = r16
.def temp4 = r17
.def temp3 = r18

.def BEENDET = r7
 
.equ LCD_PORT = PORTD
.equ LCD_DDR  = DDRD
.equ PIN_RS   = 4
.equ PIN_E    = 5

.org 0x0000
rjmp reset
.org OC1Aaddr  
rjmp loop

reset:
  
; Pins einstellen
ldi temp, LOW(RAMEND)
out SPL, temp
ldi temp, HIGH(RAMEND)
out SPH, temp

ldi temp, 0xFF
out DDRB, temp
out PORTB, temp

ldi temp, 0x00
out DDRD, temp
ldi temp, 0xFF
out PORTD, temp

; Init
ldi temp, 0
sts LCD_INI, temp
ldi Pointer, 0
ldi counter3, 0
ldi counter2, 0
ldi counter, 0
ldi mode,0
ldi temp, 0
mov Ist_2, temp
mov Ziel_2, temp
ldi temp, 5
mov Ist_1, temp

ldi temp, 0
mov BEENDET, temp

cbi PORTB, 0x06
cbi PORTB, 0x07
ldi temp2, 0b00000000
sts SERVO_STAT,temp2

ldi temp ,0
mov Glas, temp
mov gesamt, temp

sub Stop_1, Stop_1

sub null, null

rcall lcd_init     ; Display initialisieren
rcall lcd_load_user_chars
rcall lcd_clear    ; Display löschen
ldi ZL, LOW(Start*2)        
ldi ZH, HIGH(Start*2)        
rcall lcd_flash_string
ldi temp1, $c0
rcall lcd_command
ldi ZL, LOW(Start2*2)        
ldi ZH, HIGH(Start2*2)        
rcall lcd_flash_string

;Timer 1
 ldi     temp, high( 16000 - 1 )
        out     OCR1AH, temp
        ldi     temp, low( 16000 - 1 )
        out     OCR1AL, temp
		 ldi     temp, ( 1 << WGM12 ) | ( 1 << CS10 )
        out     TCCR1B, temp
 
        ldi     temp, 1 << OCIE1A  ; OCIE1A: Interrupt bei Timer Compare
        out     TIMSK, temp
sei

do: rjmp do

loop:

cpi Counter3, 0
brne test_servo
sbi PORTB,0x06
sbi PORTB,0x07
ldi temp2, 0b11000000
sts SERVO_STAT,temp2
inc Counter3
rjmp no_Counter_res

test_servo:
cpi Counter3, 1
brne no_servo
ldi Pointer, 0
loop2: 
; Servo 1
cp Pointer, Ist_1
brlo n3
cbi PORTB,0x06
rjmp end_n3
n3:
sbi PORTB,0x06
NOP
end_n3:

; Servo 2
cp Pointer, Ist_2
brlo n4
cbi PORTB,0x07
rjmp end_n4
n4:
sbi PORTB,0x07
NOP
end_n4:

inc Pointer
cpi Pointer, 205
brne loop2
cbi PORTB, 0x06
cbi PORTB, 0x07
ldi temp2, 0b00000000
sts SERVO_STAT,temp2
no_servo:

inc Counter3
cpi Counter3, 4
brne no_Counter_res
ldi Counter3, 0
no_Counter_res:

// Servos ansteuern ende

; Dreh Position
ldi     zl,low(DREH*2);            
ldi     zh,high(DREH*2);
add zl, Glas
adc zh, null
lpm Ziel_2, Z


cp null, Stop_1
breq change
dec Stop_1
rjmp no_change
change:

; Dreh einstellen
cp Ist_2, Ziel_2
breq Ende2  
brcs Hoch2
; Runterschalten
dec Ist_2
rjmp Ende2
Hoch2:
;Hochschalten
inc Ist_2
rjmp Ende2
Ende2:
ldi temp, 200
mov Stop_1, temp
no_change:

; Counter für Schritte

cpi Counter,0
brne weiter
rjmp no_Counter
weiter:
cpi Counter2, 0
breq weiter2
dec Counter2
rjmp no_schritt
weiter2:

mov temp, GLAS
cpi temp, 9
breq no_zeich
ldi   temp1,141
rcall lcd_command

mov temp1, gesamt
lsr temp1
lsr temp1
lsr temp1
rcall lcd_number

ldi temp1, 's'
rcall lcd_data

no_zeich:

dec Counter
dec gesamt
ldi Counter2, 125

rjmp no_schritt
no_Counter:


; Schritte durchgehen

cpi counter, 0
brne no_schritt2

sbic PIND, 0x00
rjmp no_start
cpi mode, 0
brne no_start
; Start
mov temp, Glas
cpi temp, 9
breq no_schritt2
inc Glas

ldi   temp1,$c0
 rcall lcd_command
ldi     zl,low(Position*2);            
ldi     zh,high(Position*2);
rcall lcd_flash_string
mov temp1, GLAS
rcall lcd_number
ldi temp1, ' '
rcall lcd_data
ldi temp1, ' '
rcall lcd_data
ldi temp1, ' '
rcall lcd_data
ldi temp1, ' '
rcall lcd_data

ldi   temp1,$80
 rcall lcd_command
ldi     zl,low(Texte*2);            
ldi     zh,high(Texte*2);
rcall lcd_flash_string

ldi temp1, 14
rcall lcd_number

ldi temp1, 's'
rcall lcd_data

ldi mode, 1
ldi temp, 114
mov gesamt, temp

ldi temp, 5
mov Ist_1, temp
ldi Counter,4 // 500ms
rjmp no_schritt
no_start:

cpi mode, 8
brne no_new

ldi   temp1,$80
 rcall lcd_command

ldi     zl,low(Texte*2);            
ldi     zh,high(Texte*2);
mov temp, mode
ldi temp2, 14
mul temp, temp2
add zl, r0
adc zh, r1
rcall lcd_flash_string

ldi mode, 0
no_new:
rjmp no_new2
no_schritt2:
rjmp no_schritt

no_new2:

mov temp, GLAS
cpi mode, 0
breq no_mode
cpi temp, 9
breq no_mode

// Data
ldi     zl,low(Data*2);            
ldi     zh,high(Data*2);
mov temp, mode
ldi temp2, 3
mul temp, temp2

add zl, r0
adc zh, r1

lpm Ist_1, Z+ ; Hebel
lpm temp, Z+ ;Schritt
lds temp2,SERVO_STAT
or temp2, temp
out PORTB, temp2


lpm Counter, Z ; Zeit
ldi   temp1,$80
 rcall lcd_command

ldi     zl,low(Texte*2);            
ldi     zh,high(Texte*2);
mov temp, mode
ldi temp2, 14
mul temp, temp2
add zl, r0
adc zh, r1
rcall lcd_flash_string

mov temp1, gesamt
lsr temp1
lsr temp1
lsr temp1
rcall lcd_number
ldi temp1, 's'
rcall lcd_data

inc mode // nächsten Schritt
no_mode:

no_schritt:

mov temp, GLAS
cpi temp, 9
brne no_ended
mov temp, BEENDET
cpi temp, 0
brne no_ended
ldi temp, 1
mov BEENDET, temp
rjmp no_ende
no_ended:

mov temp, BEENDET
cpi temp, 1
brne no_ende2
ldi   temp1,$80
rcall lcd_command
ldi     zl,low(Ende4*2);            
ldi     zh,high(Ende4*2);
rcall lcd_flash_string
ldi temp, 2
mov BEENDET, temp
rjmp no_ende
no_ende2:

cpi temp, 2
brne no_ende
ldi   temp1,$c0
rcall lcd_command
ldi     zl,low(Ende3*2);            
ldi     zh,high(Ende3*2);
rcall lcd_flash_string
ldi temp, 3
mov BEENDET, temp
no_ende:
reti 

.include "LCD.asm"

DREH:    .db 0, 20, 40, 60, 83, 110, 133, 155, 178, 198, 198, 198, 198, 198

;                  Start     Befüllung   Tankventil zu   Bef. abschließen   Ausgang öffnen   Druck zuschalten   Entl. abschließen   Abschluss
;HEBEL:         .db 108       , 108       , 108           , 125              , 125            , 125              , 108               , 108
;SCHRITTE:      .db 0b00111111, 0b00111001, 0b00111011    , 0b00111111       , 0b00110111     , 0b00100111       , 0b00110111        , 0b00111111
;ZEIT:          .db 4         , 52        , 4             , 8                , 4              , 32               , 4                 , 8

Data: .db 5,0b00111111,4,5,0b00111001,48,5,0b00111011,4,120,0b00111111,8,120,0b00110111,4,120,0b00100111,32,5,0b00110111,4,5,0b00011111,8, 5,0b00111111,0 

Start:      .db "--Abf",2,"llanlage--",0  
Start2:     .db "****************",0  
Texte:      .db "Start:       ",0,"Bef",2,"llung:   ",0,"T-Ventil zu: ",0,"Bef. absch.: ",0,"Ausgang auf: ",0,"Druck an:    ",0,"Entl. absch.:",0,"Abschluss:   ",0,"     Fertig...       ",0
Position:   .db "Position: ",0
Ende4:      .db "**Alles Bef",2,"llt*",0
Ende3:      .db "******-==-******",0

ldc_user_char:
                              ;    Zeichen 
                              ;   0       1
       .db 0b00000, 0b00000   ;       ,    
       .db 0b00000, 0b00000   ;       ,     
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       , 
 
                              ;    Zeichen
                              ;   2       3
       .db 0b01010, 0b00000   ;  @ @  , 
       .db 0b00000, 0b00000   ;       , 
       .db 0b10001, 0b00000   ; @   @ , 
       .db 0b10001, 0b00000   ; @   @ ,       
       .db 0b10001, 0b00000   ; @   @ , 
       .db 0b10011, 0b00000   ; @  @@ , 
       .db 0b01101, 0b00000   ;  @@ @ , 
       .db 0b00000, 0b00000   ;       ,  
 
                              ;    Zeichen
                              ;   4       5
       .db 0b00000, 0b00000   ;       ,        
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       ,       
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       ,  
 
                              ;    Zeichen
                              ;   6       7
       .db 0b00000, 0b00000   ;       ,        
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       ,      
       .db 0b00000, 0b00000   ;       ,       
       .db 0b00000, 0b00000   ;       ,  
 
       ; End of Tab
       .db 0xFF, 0xFF

.DSEG ; Arbeitsspeicher
SERVO_STAT: .BYTE 1 // Zustände der Servos speichern
LCD_INI: .BYTE 1



