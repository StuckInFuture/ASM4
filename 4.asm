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
rand2 db 22 ;ост от дел на 22 +2

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
    ;выводим информационные сообщения и границы площадки 
    
    ;ставим курсор для отрисовки хвоста
    mov dh,02       ;номер строки
    mov dl,01       ;номер столбца
    mov ax,0200h 
    int 10h  
    
    mov cx, lenght   ;кол-во символов
    dec cx 
    mov ah,09h
    mov al,snakeSymb 
    mov bl,snakeColor
    int 10h
    ;рисуем змейку до головы 
     
    mov dl,05    ;столбец   
    mov ax,0200h 
    int 10h  
    
    ;рисуем голову змейки другим цветом для удобства
    mov cx,1
    mov ah,09h
    mov al,snakeSymb
    mov bl,headColor
    int 10h
          
    mov si,8        ;индекс головы         
    xor di,di       ;индекс хвоста                    
    mov cx,0001h    ;для изменения координаты
    mov dh,02            ;номер строки для курсора
    mov dl,00            ;номер столбца для курсора  
     
    ;рисуем первый элемент в константном месте 
    pusha 
    mov dh,07            ;номер строки для курсора
    mov dl,05
    mov bh,00                
    mov ax,0200h             ;ставим курсор на 2 строку 0 столб
    int 10h  
    mov cx,1                 ;колво символов которые выводятся за выполнение функции
    mov ah,09h               ;рисуем символ слева
    mov al,food
    mov bl,12 
    int 10h
    popa
 
    call delay ; задежка  
    push cx 
    
main: 

    pop cx      
    call is_pressed ;проверяем нажатую клавишу пользователем
    push cx          
    mov ax,[snake+si]   ;в ах помещаем позицию головы   стр+стлб
    add ax,cx           ;добавляем к текущей позиции "нажатие" пользователя
    call is_snake_behind_border 
    add si,2 ;переставляем в массиве голову
    mov [snake+si],ax   ;новое положение головы
                           ;по сути только изменяем так голова на +клетку и удаляем хвост, если не съели яблоко
    
    
    mov dx,ax     ;сохран положен
    mov ax,0200h  ;курсор в новое положение
    int 10h
    
    mov ax,0800h   ;считываем символ с этой позиции
    int 10h                  
    call end_of_game;проверяем на съедение себя   
    
is_snake_has_eaten_food: 
    
    mov ah,02  ;курсор
    int 10h 
    
    mov ax,0800h   ;считываем символ с новой позиции головы
    int 10h
    mov dh,al         ;в dh прочитанный символ из al
     
    push cx     ;сохраняем направление движения
    call delay       
    mov ah,09h
    mov al,snakeSymb
    mov bl,headColor
    mov cx,1
    int 10h
    
    push dx                  ;здесь перекрашиваем "предыдущую голову змеи" в цвет самой змейки
    sub si, 2
    mov ax, [snake+si] 
    mov dx, ax
    mov ah, 02  ;курсор
    int 10h
    mov ah,09h
    mov al,snakeSymb
    mov bl,snakeColor
    mov cx,1
    int 10h   
    add si, 2                                          
    pop dx
    
    cmp dh,food               ;сравниваем считанный символ с символом еды
    jne next
    call addScore            ; если еда, добавляем балл 
    xor bh,bh
    jmp main  
        
next:    
   
    mov ah,02h
    mov al,00h
    mov dx,[snake+di]                ;индекс хвоста
    mov cx,1
    int 10h 
  
    
    mov ah,09h
    mov al,00h
    mov bl,00h     ;атрибут
    int 10h 
    add di,2  
 
jmp main

 
timer proc
    ;push cx
    xor bx,bx
    xor dx,dx
    xor ax,ax    
    mov ah,2Ch
    int 21h   ;получаем текущее время(будем считать это рандомом)
    mov bx,dx ;забираем число в формате секунды+сотые доли секунды(но считаем это просто рандомным числом)               
    ;pop cx     ;dh - сек, dl - сотые доли сек
    ret   
timer endp

is_pressed proc    
    mov ax,0100h   ;проверка наличия символа в буфере клавы
    int 16h
    jz endProc ;проверяем на готовность клавиатуры давать код нажатой клавиши(в буфере клавиатуры) и нажата ли клавиша вообще
               ;если не нажата клавишу то выходим из процедуры
    
    
    xor ah,ah
    int 16h    ;если всё таки нажимали клавишу, то считываем её код в ah
    
    cmp ah,50h  ;полученный скан-код сравниваем со стрелками 50 вниз 48 вверх 4В влево 4D вправо
    jne up_pressed
    cmp cx, 0FF00h ;проверяем, что мы не пойдём сквозь себя(змейка идёт вправо, а нажаты влево и вверх/низ)
    je game_over
    mov cx, 0100h   ;помещаем код что идём вниз
    jmp endProc
up_pressed:
    cmp ah, 48h
    jne left_pressed
    cmp cx, 0100h    ;проверяем, что мы не пойдём сквозь себя
    je game_over
    mov cx, 0FF00h      ;помещаем код что идём вверх
    jmp endProc
left_pressed:
    cmp ah,4Bh
    jne right_pressed
    cmp cx, 0001h     ;проверяем что, мы не пойдём сквозь себя
    je game_over
    mov cx, 0FFFFh       ;помещаем код что идём влево
    jmp endProc
right_pressed:
    cmp ah, 4Dh
    jne endProc
    cmp cx, 0FFFFh   ;проверяем что, мы не пойдём сквозь себя
    je game_over
    mov cx, 0001h        ;помещаем код что идём вправо
endProc:
    ret
is_pressed endp 

set_random_food proc 
      
    pusha
    setnewpos:                   
    call timer                  ;в bx и dx число сек+сотые сек
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
    mov ax,0200h             ;ставим курсор 
    int 10h 
    mov ah,08h
    int 10h
    
    cmp al,snakeSymb 
    je  setnewpos
    cmp al,border_up_down
    je setnewpos
    cmp al,border_left_right
    je setnewpos 
       
    mov cx,1                 ;колво символов которые выводятся за выполнение функции
    mov ah,09h               
    mov al,food
    mov bl,12 
    int 10h 
    
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
    left: 
    mov bh,00                
    mov ax,0200h             ;ставим курсор на 2 строку 0 столб
    int 10h  
    mov cx,1                 ;колво символов которые выводятся за выполнение функции
    mov ah,09h               ;рисуем символ слева
    mov al,border_left_right
    mov bl,colorOfBorder 
    int 10h
    inc dh                   ;к след строке 
    cmp dh, 17h  
    jle  left  
    
    mov dh,02
    mov dl,79                ;номер стобца
    mov ax,0200h 
    int 10h  
        
    right:                
    mov ax,0200h             ;ставим курсор на 2 строку 0 столб
    int 10h
    mov cx,1                 ;рисуем символ справа
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
    mov dh,00         ;координаты очков
    mov dl,06
    mov ah,02h 
    mov al,00h
    int 10h
     
    inc score 
get_output_score: 
    xor cx,cx
    xor ax,ax 
    lea di,outputScore    ;надпись
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
    add al,'0'      ;к целой части код нуля, чтобы код цифры
    mov [di],al      ;цифру по смещению
    inc di 
    xor al,al
    cmp ch,1
    je printing
    add ah,'0'      ;берем цифру из остатка от деления
    mov [di],ah      ;цифру по смещению
printing:               
    print_str outputScore 
    popa
    ret
addScore endp
                                          
                                          
end_of_game proc
    cmp al,snakeSymb ;проверяем что змейка не ударилась сама в себя
    je game_over   ;если ударилась, то конец игры
    jmp continue   ;если нет, то продолжнаем играть  
game_over:
    mov dh,00       ;если ударилась,
    mov dl,35       ;то переносим курсор в нужное положение для вывода сообщения
    mov ax,0200h 
    int 10h
    
    print_str msgGameOver  ;выводим сообщение об ошибке
    print_str msgReturn    ;выводим сообщение об выходе из игры
    
    mov ah,00
    mov al,00
    int 16h                 ;ждём нажатия клавиши
    
    cmp al,'q'              ;если нажата q то выходим из игры
    je endOf 
        
endOf:    
    mov ah,4Ch              ;конец программы (принудительный выход)
    mov al,00h
    int 21h
   
continue:                    ;если змейка не ударилась - прододлдаем играть
    ret        
end_of_game endp 


is_snake_behind_border proc
    cmp ah,01h          ;верхняя граница
    jne ch_down
    mov ah,17h          ;на 23ю, чтобы появилась над нижней границей
    jmp not_behind
ch_down:    
    cmp ah,18h          ;нижняя граница
    jne ch_right
    mov ah,02h          ;на 2ю, чтобы под верхней
    jmp not_behind 
ch_right:    
    cmp al,4Fh          ;правая 
    jne ch_left
    mov al,01h           ;на 1ый столбец, чтобы за левой границей
    jmp not_behind 
ch_left:
    cmp al,00h          ;левая
    jne not_behind
    mov al,4Eh          ;на 78й столбец, чтобы перед правой границей
    jmp not_behind
not_behind:
    ret    
is_snake_behind_border endp

delay proc 
    push ax
    push cx
    push dx
    
    xor ax, ax
    mov cx, 3     ;старший
    mov dx, 7FFh ;младший 
    mov ah, 86h
    int 15h ;вызываем задержку программы с помощью системного таймера
    
    pop dx
    pop cx
    pop ax
    ret
delay endp    

end start 

