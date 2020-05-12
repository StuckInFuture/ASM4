.model small

.286
.stack 200h
.data
snake   dw 0201h
        dw 0202h
        dw 0203h
        dw 0204h
        dw 0205h
        dw 6B3h dup ('?')   
msgScore db 'SCORE:$' 
score db 0
startPos dw 0470h   
outputScore db '0 $'
snakeSymb EQU 'O' 
snakeColor EQU 010  
headColor db 14
lenght dw 5
border_up_down EQU 196
border_left_right EQU '|'
colorOfBorder db 13
food db 03
msgGameOver db 'GAME OVER!$'
msgReturn db ' Press q to exit$'  
rand1 db 78
rand2 db 22 ;��� �� ��� �� 22 +2

.code
.386
print_str macro out_str
    mov ah,09h
    mov dx,offset out_str
    int 21h
endm 

start: 
    call set_screen
    mov ax,@data
    mov ds,ax
    mov es,ax
    print_str msgScore
    print_str outputScore
    call printBorders 
    ;������� �������������� ��������� � ������� �������� 
    
    ;������ ������ ��� ��������� ������
    mov dh,02       ;����� ������
    mov dl,01       ;����� �������
    mov ax,0200h 
    int 10h  
    
    mov cx, lenght   ;���-�� ��������
    dec cx 
    mov ah,09h
    mov al,snakeSymb 
    mov bl,snakeColor
    int 10h
    ;������ ������ �� ������ 
     
    mov dl,05    ;�������   
    mov ax,0200h 
    int 10h  
    
    ;������ ������ ������ ������ ������ ��� ��������
    mov cx,1
    mov ah,09h
    mov al,snakeSymb
    mov bl,headColor
    int 10h
          
    mov si,8        ;������ ������         
    xor di,di       ;������ ������                    
    mov cx,0001h    ;��� ��������� ����������
    mov dh,02            ;����� ������ ��� �������
    mov dl,00            ;����� ������� ��� �������  
     
    ;������ ������ ������� � ����������� ����� 
    pusha 
    mov dh,07            ;����� ������ ��� �������
    mov dl,05
    mov bh,00                
    mov ax,0200h             ;������ ������ �� 2 ������ 0 �����
    int 10h  
    mov cx,1                 ;����� �������� ������� ��������� �� ���������� �������
    mov ah,09h               ;������ ������ �����
    mov al,food
    mov bl,12 
    int 10h
    popa
 
    call delay ; �������  
    push cx 
    
main: 

    pop cx      
    call is_pressed ;��������� ������� ������� �������������
    push cx          
    mov ax,[snake+si]   ;� �� �������� ������� ������   ���+����
    add ax,cx           ;��������� � ������� ������� "�������" ������������
    call is_snake_behind_border 
    add si,2 ;������������ � ������� ������
    mov [snake+si],ax   ;����� ��������� ������
                           ;�� ���� ������ �������� ��� ������ �� +������ � ������� �����, ���� �� ����� ������
    
    
    mov dx,ax     ;������ �������
    mov ax,0200h  ;������ � ����� ���������
    int 10h
    
    mov ax,0800h   ;��������� ������ � ���� �������
    int 10h                  
    call end_of_game;��������� �� �������� ����   
    
is_snake_has_eaten_food: 
    
    mov ah,02  ;������
    int 10h 
    
    mov ax,0800h   ;��������� ������ � ����� ������� ������
    int 10h
    mov dh,al         ;� dh ����������� ������ �� al
     
    push cx     ;��������� ����������� ��������
    call delay       
    mov ah,09h
    mov al,snakeSymb
    mov bl,headColor
    mov cx,1
    int 10h
    
    push dx                  ;����� ������������� "���������� ������ ����" � ���� ����� ������
    sub si, 2
    mov ax, [snake+si] 
    mov dx, ax
    mov ah, 02  ;������
    int 10h
    mov ah,09h
    mov al,snakeSymb
    mov bl,snakeColor
    mov cx,1
    int 10h   
    add si, 2                                          
    pop dx
    
    cmp dh,food               ;���������� ��������� ������ � �������� ���
    jne next
    call addScore            ; ���� ���, ��������� ���� 
    xor bh,bh
    jmp main  
        
next:    
   
    mov ah,02h
    mov al,00h
    mov dx,[snake+di]                ;������ ������
    mov cx,1
    int 10h 
  
    
    mov ah,09h
    mov al,00h
    mov bl,00h     ;�������
    int 10h 
    add di,2  
 
jmp main

 
timer proc
    ;push cx
    xor bx,bx
    xor dx,dx
    xor ax,ax    
    mov ah,2Ch
    int 21h   ;�������� ������� �����(����� ������� ��� ��������)
    mov bx,dx ;�������� ����� � ������� �������+����� ���� �������(�� ������� ��� ������ ��������� ������)               
    ;pop cx     ;dh - ���, dl - ����� ���� ���
    ret   
timer endp

is_pressed proc    
    mov ax,0100h   ;�������� ������� ������� � ������ �����
    int 16h
    jz endProc ;��������� �� ���������� ���������� ������ ��� ������� �������(� ������ ����������) � ������ �� ������� ������
               ;���� �� ������ ������� �� ������� �� ���������
    
    
    xor ah,ah
    int 16h    ;���� �� ���� �������� �������, �� ��������� � ��� � ah
    
    cmp ah,50h  ;���������� ����-��� ���������� �� ��������� 50 ���� 48 ����� 4� ����� 4D ������
    jne up_pressed
    cmp cx, 0FF00h ;���������, ��� �� �� ����� ������ ����(������ ��� ������, � ������ ����� � �����/���)
    je game_over
    mov cx, 0100h   ;�������� ��� ��� ��� ����
    jmp endProc
up_pressed:
    cmp ah, 48h
    jne left_pressed
    cmp cx, 0100h    ;���������, ��� �� �� ����� ������ ����
    je game_over
    mov cx, 0FF00h      ;�������� ��� ��� ��� �����
    jmp endProc
left_pressed:
    cmp ah,4Bh
    jne right_pressed
    cmp cx, 0001h     ;��������� ���, �� �� ����� ������ ����
    je game_over
    mov cx, 0FFFFh       ;�������� ��� ��� ��� �����
    jmp endProc
right_pressed:
    cmp ah, 4Dh
    jne endProc
    cmp cx, 0FFFFh   ;��������� ���, �� �� ����� ������ ����
    je game_over
    mov cx, 0001h        ;�������� ��� ��� ��� ������
endProc:
    ret
is_pressed endp 

set_random_food proc 
      
    pusha
    setnewpos:                   
    call timer                  ;� bx � dx ����� ���+����� ���
    xor bh,bh 
    xor dx, dx
    xor ax, ax
      
    mov ax, bx
    div rand2
    add ah, 2                                      ;---------------------------------------------------------------
    mov dh, ah 
    xor ax,ax 
    mov ax, bx
    div rand1
    add ah, 1                                      ;---------------------------------------------------------------
    mov dl, ah 
    jmp add_food 
    

       
add_food: 
    xor ax,ax      
    mov ax,0200h             ;������ ������ 
    int 10h 
    mov ah,08h
    int 10h
    
    cmp al,snakeSymb 
    je  setnewpos
    cmp al,border_up_down
    je setnewpos
    cmp al,border_left_right
    je setnewpos 
       
    mov cx,1                 ;����� �������� ������� ��������� �� ���������� �������
    mov ah,09h               
    mov al,food
    mov bl,12 
    int 10h 
    
    popa               
    ret
set_random_food endp 

set_screen proc 
    mov ah,00h
    mov al,03h   ;����������� 16 ������� �����
    int 10h 
    ret
set_screen endp    

printBorders proc
    pusha                ;��� �������� � ����
    mov cx,2 
    mov dh,01            ;����� ������ ��� �������
    mov dl,00            ;����� ������� ��� �������
up_and_down:
    push cx 
      
    mov bh,00            ;����� �������� ��� �������
    mov ax,0200h          ;����������� ��������� �������
    int 10h                                          
    
    mov cx,80            ;���������� ���������� �������
    mov ah,09h           ;����� ������� � �������� �����������
    mov al,border_up_down        ;������
    mov bl,colorOfBorder 
    int 10h                         
    
    pop cx
    mov dh,24            ;������ ��� ������ �������
    loop up_and_down                                
    
    mov dh,02            ;����� ������ ��� �������
    mov dl,00            ;����� ������� ��� �������  
left_and_right:                     
    left: 
    mov bh,00                
    mov ax,0200h             ;������ ������ �� 2 ������ 0 �����
    int 10h  
    mov cx,1                 ;����� �������� ������� ��������� �� ���������� �������
    mov ah,09h               ;������ ������ �����
    mov al,border_left_right
    mov bl,colorOfBorder 
    int 10h
    inc dh                   ;� ���� ������ 
    cmp dh, 17h  
    jle  left  
    
    mov dh,02
    mov dl,79                ;����� ������
    mov ax,0200h 
    int 10h  
        
    right:                
    mov ax,0200h             ;������ ������ �� 2 ������ 0 �����
    int 10h
    mov cx,1                 ;������ ������ ������
    mov ah,09h
    mov al,border_left_right
    mov bl,colorOfBorder 
    int 10h 
    inc dh                   
    cmp dh, 17h  
    jle  right
    jmp  end_of_print_Borders  
        
end_of_print_Borders:       
    popa
    ret
printBorders endp   
 
addScore proc
    call delay
    call set_random_food      
    pusha 
    mov bh,00
    mov dh,00         ;���������� �����
    mov dl,06
    mov ah,02h 
    mov al,00h
    int 10h
     
    inc score 
get_output_score: 
    xor cx,cx
    xor ax,ax 
    lea di,outputScore    ;�������
    mov cl,0Ah             ;10
    mov al,score 
    cmp al,0Ah
    jl one_num 
    cmp al,64h             ;100
    jl two_num
one_num:
    mov ch,1
    jmp only_one  
two_num:
    mov ch,2
    jmp get_string  

get_string:
    div cl 
only_one:    
    add al,'0'      ;� ����� ����� ��� ����, ����� ��� �����
    mov [di],al      ;����� �� ��������
    inc di 
    xor al,al
    cmp ch,1
    je printing
    add ah,'0'      ;����� ����� �� ������� �� �������
    mov [di],ah      ;����� �� ��������
printing:               
    print_str outputScore 
    popa
    ret
addScore endp
                                          
                                          
end_of_game proc
    cmp al,snakeSymb ;��������� ��� ������ �� ��������� ���� � ����
    je game_over   ;���� ���������, �� ����� ����
    jmp continue   ;���� ���, �� ����������� ������  
game_over:
    mov dh,00       ;���� ���������,
    mov dl,35       ;�� ��������� ������ � ������ ��������� ��� ������ ���������
    mov ax,0200h 
    int 10h
    
    print_str msgGameOver  ;������� ��������� �� ������
    print_str msgReturn    ;������� ��������� �� ������ �� ����
    
    mov ah,00
    mov al,00
    int 16h                 ;��� ������� �������
    
    cmp al,'q'              ;���� ������ q �� ������� �� ����
    je endOf 
        
endOf:    
    mov ah,4Ch              ;����� ��������� (�������������� �����)
    mov al,00h
    int 21h
   
continue:                    ;���� ������ �� ��������� - ����������� ������
    ret        
end_of_game endp 


is_snake_behind_border proc
    cmp ah,01h          ;������� �������
    jne ch_down
    mov ah,17h          ;�� 23�, ����� ��������� ��� ������ ��������
    jmp not_behind
ch_down:    
    cmp ah,18h          ;������ �������
    jne ch_right
    mov ah,02h          ;�� 2�, ����� ��� �������
    jmp not_behind 
ch_right:    
    cmp al,4Fh          ;������ 
    jne ch_left
    mov al,01h           ;�� 1�� �������, ����� �� ����� ��������
    jmp not_behind 
ch_left:
    cmp al,00h          ;�����
    jne not_behind
    mov al,4Eh          ;�� 78� �������, ����� ����� ������ ��������
    jmp not_behind
not_behind:
    ret    
is_snake_behind_border endp

delay proc 
    push ax
    push cx
    push dx
    
    xor ax, ax
    mov cx, 3     ;�������
    mov dx, 7FFh ;������� 
    mov ah, 86h
    int 15h ;�������� �������� ��������� � ������� ���������� �������
    
    pop dx
    pop cx
    pop ax
    ret
delay endp    

end start 

