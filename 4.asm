.model small


.stack 200h
.data
snake   dw 0201h
        dw 0202h
        dw 0203h
        dw 0204h
        dw 0205h
        dw 7CCh dup ('?')   
msgScore db 'SCORE:$' 
score db 0
startPos dw 0580h   
outputScore db '0 $'
snakeSymb EQU 'O' 
colorOfSnake EQU 010
lenght dw 5
border_up_down EQU 196
border_left_right EQU '|'
colorOfBorder EQU 011
food db 003
count db 0
delay dw 10
msgGameOver db 'GAME OVER!$'
msgReturn db ' Prees e to exit...$' 

.code
print_str macro out_str
    mov ah,09h
    mov dx,offset out_str
    int 21h
endm 

start: 
    call set_screen
    ;///get pos and sizeof cursos
    mov ax,@data
    mov ds,ax
    mov es,ax
    ;mov ax,0003h
    ;int 10h
    print_str msgScore
    print_str outputScore
    call printBorders 
    ;выводим информационные сообщения и границы площадки 
    
    ;///set cursor
    mov dh,02       ;num of str
    mov dl,01       ;num of row
    mov ax,0200h 
    int 10h  
    ;устанавливаем курсор для хвоста змейки
    
    
    mov cx, lenght
    dec cx 
    mov ah,09h
    mov al,snakeSymb 
    mov bl,colorOfSnake
    int 10h
    ;рисуем змейку до головы 
     
    mov dl,01
    mov dl,05       ;num of row
    mov ax,0200h 
    int 10h  
    
    mov cx,1
    mov ah,09h
    mov al,snakeSymb
    mov bl,100 
    int 10h
    
    ;рисуем голову змейки другим цветом для удобства
      
    mov si,8        ;pos of head 4*2
    xor di,di       ;pos of tail                    
    mov cx,0001h    ;use for cotnrol snake head
    
    pusha
    push 0B800h
    pop es 
    mov di,word ptr startPos
    mov si,offset food
    cld
    movsb
    popa
    ;выводим первое СЕРДЕЧКО на экран в константное место
    
    call speed_up ; задежка  
    push cx 
    
main: 
    pop cx      
    call is_pressed ;проверяем нажатую клавишу пользователем
    push cx          
    mov ax,[snake+si]   ;в ах помещаем полицию головы 
    add ax,cx           ;добавляем к текущей позиции "нажатие" пользователя
    call is_snake_behind_border 
    add si,2 ;переставляем в массиве голову
    mov [snake+si],ax   ;перезаписываем новое положение головы(старое значение это значение клетки куда станет тело змейки)
                           ;по сути только изменяем так голова на +клетку и удаляем хвост если не съели яблоко
    
    
    mov dx,ax
    mov ax,0200h 
    int 10h
    
    mov ax,0800h
    int 10h 
    ;устанавливаем курсов на положение головы и получаем какой там стоит символ(собственно на что напоролись)                     
    call end_of_game;проверяем не напоролись на змейку(сами на себя)    
    
is_snake_has_eaten_food: 
    
    mov ah,02
    int 10h 
    
    ;///get symbol for cmp head and snake
    mov ax,0800h
    int 10h
    mov dh,al
     
    push cx 
    ;///print symb
    call speed_up       ;it's current speed of shake
    mov ah,09h
    mov al,snakeSymb
    mov bl,colorOfSnake
    mov cx,1
    int 10h                                 
    
    cmp dh,food
    jne next
    call addScore 
    inc count
    call timer
    xor bh,bh
    call set_random_food
    jmp main  ;if snake has eaten food we just don't print space
        
next:    
    ;///set pos of cursor to tail pos
    mov ah,02h
    mov al,00h
    mov dx,[snake+di]
    mov cx,1
    int 10h 
  
    ;///print black prob
    mov ah,09h
    mov al,00h
    mov bl,00h
    mov dl,20h
    int 10h 
    add di,2  
 
jmp main

 
timer proc
    push cx
    
    mov ah,2Ch
    int 21h   ;получаем текущее время(будем считать это рандомом)
    mov bx,dx ;забираем число в формате секунды+сотые доли секунды(но считаем это просто рандомным числом)

    pop cx  
    ret   
timer endp

is_pressed proc    
    mov ax,0100h
    int 16h
    jz endProc ;проверяем на готовность клавиатуры давать код нажатой клавиши(в буфере клавиатуры) и нажала ли клавиша вообще
               ;если не нажималь клавишу то выходим из процедуры
    
    
    xor ah,ah
    int 16h    ;если всё таки нажимали клавишу то считываем её код
    
    cmp ah,50h  ;СКАН КОД ПОЛУЧИЛИ СРАВНИВАЕМ со стрелками 50 вниз 48 вверх 4В влево 4D вправо
    jne up_pressed
    cmp cx, 0FF00h ;проверяем что мы не пойдём сквозь себя(змейка идёт вправо а я нажал влево и вверх низ тоже так)
    je endProc
    mov cx, 0100h   ;помещаем код что идём вниз
    jmp endProc
up_pressed:
    cmp ah, 48h
    jne left_pressed
    cmp cx, 0100h    ;проверяем что мы не пойдём сквозь себя(змейка идёт вправо а я нажал влево и вверх низ тоже так)
    je endProc
    mov cx, 0FF00h      ;помещаем код что идём вверх
    jmp endProc
left_pressed:
    cmp ah,4Bh
    jne right_pressed
    cmp cx, 0001h     ;проверяем что мы не пойдём сквозь себя(змейка идёт вправо а я нажал влево и вверх низ тоже так)
    je endProc
    mov cx, 0FFFFh       ;помещаем код что идём влево
    jmp endProc
right_pressed:
    cmp cx, 0FFFFh   ;проверяем что мы не пойдём сквозь себя(змейка идёт вправо а я нажал влево и вверх низ тоже так)
    je endProc
    mov cx, 0001h        ;помещаем код что идём вправо
endProc:
    ret
is_pressed endp 

set_random_food proc 
    pusha
    call timer 
    xor bh,bh 
get_pos:
    inc bl              ;just some num in bl, that rundomized timer    
    cmp bx,4Eh
    jng set_pos
    shr bl,1
    jmp get_pos
set_pos:
    mov dl,bl
check_pos:
    cmp bx,17h          ;it's a check for setting behind borders
    jng add_food
    shr bl,2
    jmp check_pos
add_food:
    mov dh,bl
    mov ah,02
    mov al,00
    int 10h
    
    mov ah,08
    mov al,00
    int 10h
    
    cmp al,snakeSymb    ;check for not to set food in border or snake
    je get_pos
    cmp al,border_up_down
    je get_pos
    cmp al,border_left_right
    je get_pos 
    mov cx,1
    mov ah,02
    mov al,00
    mov dl,food
    int 21h
    popa               
    ret
set_random_food endp 

set_screen proc 
    mov ah,00h
    mov al,03h   ;стандартный 16 цветный режим
    int 10h 
    ret
set_screen endp    

printBorders proc
    pusha                ;все регистры в стек
    mov cx,2 
    mov dh,01            ;номер строки для курсора
    mov dl,00            ;номер столбца для курсора
up_and_down:
    push cx 
      
    mov bh,00            ;номер страницы для курсора
    mov ax,0200h          ;устнановить положение курсора
    int 10h                                          
    
    mov cx,80            ;количество повторений символа
    mov ah,09h           ;вывод символа с заданным повторением
    mov al,border_up_down        ;символ
    mov bl,colorOfBorder 
    int 10h                         
    
    pop cx
    mov dh,24            ;строка для нижней границы
    loop up_and_down                                
    
    mov dh,02            ;номер строки для курсора
    mov dl,00            ;номер столбца для курсора  
left_and_right:               
    mov bh,00                
    mov ax,0200h             ;ставим курсор на 2 строку 0 столб
    int 10h    
    
    mov cx,1                 ;колво символов которые выводятся за выполнение функции
    mov ah,09h               ;рисуем символ слева
    mov al,border_left_right
    mov bl,colorOfBorder 
    int 10h 
    
    add dl,79                ;номер стобца
    mov bh,00                ;страница
    mov ax,0200h 
    int 10h 
    
    mov cx,1                 ;рисуем символ справа
    mov ah,09h
    mov al,border_left_right
    mov bl,colorOfBorder 
    int 10h         
  
    sub dl,79                ;к левому столбцу
    inc dh                   ;к след строке 
    cmp dh, 17h  
    jg  end_of_print_Borders
    jmp left_and_right
      
    
end_of_print_Borders:       
    popa
    ret
printBorders endp   
 
;---when snake has eaten food, we call this proc---- 
addScore proc
    cmp delay,0
    je add_to_score
    sub delay,100 ;inc speed for run faster 
add_to_score:
    call speed_up
    add bl,32h
    call set_random_food 
    pusha 
    mov bh,00
    mov dh,00
    mov dl,06
    mov ah,02h 
    mov al,00h
    int 10h
     
    inc score 
get_output_score: 
    xor cx,cx
    xor ax,ax 
    lea di,outputScore
    mov cl,0Ah
    mov al,score 
    cmp al,0Ah
    jl one_num 
    cmp al,64h
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
    add al,'0'
    mov [di],al 
    inc di 
    xor al,al
    cmp ch,1
    je printing
    add ah,'0'
    mov [di],ah
printing:               
    print_str outputScore 
    popa
    ret
addScore endp
                                          
                                          
end_of_game proc
    cmp al,snakeSymb ;проверяем что змейка не ударилась сама в себя
    je game_over   ;если ударилась то значит конец игры
    jmp continue   ;если нет то продолжнаем играть  
game_over:
    mov dh,00       ;если всё таки ударилась
    mov dl,40       ;то переносим курсор у нужное положение для вывода сообщения
    mov ax,0200h 
    int 10h
    
    print_str msgGameOver  ;выводим сообщение об ошибке
    print_str msgReturn    ;выводим сообщение об выходе из игры
    
    mov ah,00
    mov al,00
    int 16h                 ;ждём нажатия клавиши
    
    cmp al,'e'              ;если нажата е то выходим из игры
    je endOf
    
endOf:    
    mov ah,4Ch              ;конец программы (принудительный выход)
    mov al,00h
    int 21h
   
continue:                    ;если змейка не ударилась - прододлдаем играть
    ret        
end_of_game endp 


is_snake_behind_border proc
    cmp ah,01h          ;up border
    jne ch_down
    mov ah,17h 
    jmp not_behind
ch_down:    
    cmp ah,18h          ;down border
    jne ch_right
    mov ah,02h
    jmp not_behind 
ch_right:    
    cmp al,4Fh          ;right border 
    jne ch_left
    mov al,01h
    jmp not_behind 
ch_left:
    cmp al,00h          ;left border
    jne not_behind
    mov al,4Eh
    jmp not_behind
not_behind:
    ret    
is_snake_behind_border endp

speed_up proc 
    push ax
    push cx
    push dx
    
    xor ax, ax
    mov cx, 0     ;старший
    mov dx, delay ;младший 
    mov ah, 86h
    int 15h ;вызываем задержку программы с помощью системного таймера
    
    pop dx
    pop cx
    pop ax
    ret
speed_up endp    

end start 

