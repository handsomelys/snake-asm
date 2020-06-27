clearScreen macro
	;25*80 resolution
	mov ah,00h
	mov al,03h
	int 10h
	endm

pushR macro
	;Macro of push all R into stack
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	endm

popR macro
	;Macro of pop all R from stack
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	endm


stack segment
dw	80 dup (0)
top label word

stack ends

data segment
	;Set data structure
	
	snake_direction db 4dh,00h
	snake_body dw 400 dup(0)
	food_position dw 0
	snake_body_length dw 0
	snake_head	dw 8
	score dw 0
	white equ 01110111b
	pink equ 01010101b
	red	equ 01000100b
	yellow equ 01100110b
	grren equ 00110011b
	blue equ 00010001b
	black equ 00000000b
	greenplus equ 00110011b
	current_color db 0
	up	equ	48h
	down equ 50h
	left equ 4bh
	right equ 4dh
	jblink dw 1
	gameover dw 0
	speed dw 04abch
	food_get dw 0
	acceleration dw 0
	speed_level dw 0
	integral dw 0
	color dw 0
	chgdirection dw 0
	string0 db 'Your score is:'
	nstring0 equ $-string0
	szgameover db 'Game Over!'
	nszgameover equ $-szgameover
	string1 db 'You have got point :'
	nstring1 equ $-string1
	string2 db 'Current speed is:'
	nstring2 equ $-string2
	
data ends
code segment
assume ds:data,cs:code,ss:stack
start:
main proc far

init:
	;Init
	mov ax,data
	mov ds,ax
	mov ax,stack
	mov ss,ax
	lea sp,top
	;Write the screen directly
	mov ax,0b800h
	mov es,ax	
	;Navigate to snake_body to initialize snake
	mov si,2	
	mov cx,4

	
	clearScreen
	;Set map
	call setRowBackground 
	call setColBackground 
	
	;Set score board
	call showScore
	;Init snake body in map
	call initSnake
	;Generate food
	call generateFood
	;Show speed board
	call showSpeed
game1:		
		;If gameover then game over
		cmp gameover,1
		je	endgame
		;Auto move snake if not input
        call moveSnake
        ;Delay input
		call delayInput
		;Update score
		call showScore
		;If integral % 5 = 0, then accelerate
		cmp integral,5
		je accelerate

		jne game1
accelerate:
		sub speed,100h	
		inc speed_level
		mov integral,0
		call showSpeed
        jmp game1
endgame:	
	clearScreen		
	call gameOverP
	mov ah,4ch
	int 21h
main endp

initSnake proc near
	 pushR
	 ;Init snake direction to right
	 mov byte ptr ds:[0],right
	 ;Init snake initial position
	 mov ax,0808H
	 ;Nevigate to snake_body
	 mov di,2
init:
	;Init for pack of snake body's position in the map
	 mov ds:[di],ax
	 add di,2
	 inc al
	 loop init		 
	 mov di,2
initBody:
	 
printSnake:
	 ;Print the snake body by the position in snake_body
	 mov ax,ds:[di]
	 mov dl,' '
	 mov dh,white
	 mov bl,al
	 mov bh,ah
	 call print
	 inc di
	 inc di
	 
	 mov ax,ds:[di]
	 mov dl,' '
	 mov dh,white
	 mov bl,al
	 mov bh,ah
	 call print
	 inc di
	 inc di
	 
	 mov ax,ds:[di]
	 mov dl,' '
	 mov dh,white
	 mov bl,al
	 mov bh,ah
	 call print
	 inc di
	 inc di
	 
	 mov ax,ds:[di]
	 mov dl,' '
	 mov dh,red
	 mov bl,al
	 mov bh,ah
	 call print
	 inc di
	 inc di
	 ;Snake_head store the EA of next snake_head
	 mov snake_head,di
	
	 popR
	 ret
initSnake endp

getInput proc near
	;Proc for get keyboard input to change the direction
	pushR
	;Check out the buffer
	mov al,0
	mov ah,1
	int 16h
	
	cmp ah,1
	je endGetInput
	;Wait for the keyboard input
	mov al,0
	mov ah,0
	int 16h
	
	;Judge the for direction's scan code
	;And change the snake direction if ok
left_key:
	cmp ah,left
	;If current direction isnt right
	;Then change the snake_direction to input direction
	;The following is the same
	jne right_key
	mov bh,ds:[0]
	cmp bh,right
	je	endGetInput
	mov byte ptr ds:[0],left
	
	
right_key:
	cmp ah,right
	jne up_key
	mov bh,ds:[0]
	cmp bh,left
	je endGetInput
	mov byte ptr ds:[0],right
	
	
up_key:
	cmp ah,up
	jne down_key
	mov bh,ds:[0]
	cmp bh,down
	je endGetInput
	mov byte ptr ds:[0],up
	
down_key:
	cmp ah,down
	jne endGetInput
	mov bh,ds:[0]
	cmp bh,up
	je endGetInput
	mov byte ptr ds:[0],down

endGetInput:
	popR
	ret
getInput endp

moveSnake proc near
	;Proc for moving the snake by snake_direction
	pushR
	;Check the snake_direction, and move the snake
	mov di,snake_head
	sub di,2
	cmp byte ptr ds:[0],up
	je move_up
	
	;Mov ax,snake_direction
    cmp byte ptr ds:[0], down
    je move_down

    ;Mov ax,snake_direction
    cmp byte ptr ds:[0], left
    je move_left

    ;Mov ax,snake_direction
    cmp byte ptr ds:[0], right
    je move_right
    
 	move_up:
        mov ax, ds:[di]
        sub ax,0100h
        jmp checking

    move_down:
        mov ax, ds:[di]
        add ax,0100h
        jmp checking
    move_left:
        mov ax, ds:[di]
        sub ax,0001h
        jmp checking

    move_right:
        mov ax, ds:[di]
        add ax,0001h
        jmp checking	
        
checking: 
	;Check if the snake hit the border
	cmp ah, 0
    je setGameover
    cmp ah, 21
    je setGameover
    cmp al, 0
    je setGameover
    cmp al, 39
    je setGameover
    
    ;Check if the snake bite itself
    mov cx, snake_head
    sub cx, 4
    mov di, 2
	shr cx,1
	
    s0: 
        
        cmp ds:[di], ax
        je setGameover

        add di, 2

        loop s0

	;To get the food position in the map
	;But i set it transparent in order to beautify the ui
	mov bx,food_position
	push ax
	push bx
	xor bx,bx 
	mov bx,food_position
	xor ax,ax
	mov al,bh
	mov di,3640
	call outputDecTransparent
	 
	xor ax,ax
	mov al,bl
	mov di,3646
	call outputDecTransparent
	pop bx
	pop ax
	
	;If the head of snake has the same location to the food position
	;Then snake get the food, we should enlarge it
	cmp ax,bx	
		
	je getFood

backWardBody:
	;Update the snake body position
	;By backward the packs of snake
	mov cx,snake_head
	
	sub cx,4
	mov di,2
	
	shr cx,1
	push ax
	;Set the backward one black
	mov dl,' '
	mov dh,black
	mov bx,ds:[di]
	call print	
s5: 
        mov dx, ds:[di+2]
        mov ds:[di], dx

        add di, 2

        loop s5
	;Other one has the normal color
	;When color % 5 = 0, the snake is white
	;When color % 5 = 1, the snake is blue
	;When color % 5 = 2, the snake is greenplus
	;When color % 5 = 3, the snake is pink
	;When color % 5 = 4, the snake is zeroing the color
	cmp color,0
	je	white_color
	cmp color,1
	je	blue_color
	cmp color,2
	je	greenplus_color
	cmp color,3
	je  pink_color
	cmp color,4
	je	zeroing_color

zeroing_color:
	mov color,0
white_color:	
    mov dl, ' '
    mov dh, white
    mov bx, ds:[di]	
	call print
	
	pop ax
	mov ds:[di],ax
	mov dl,' '
	mov dh,red
	mov bx,ds:[di]
	call print
	mov current_color,white
	jmp endMove
blue_color:	
    mov dl, ' '
    mov dh, blue
    mov bx, ds:[di]	
	call print
	
	pop ax
	mov ds:[di],ax
	mov dl,' '
	mov dh,red
	mov bx,ds:[di]
	call print
	mov current_color,blue
	jmp endMove
greenplus_color:	
    mov dl, ' '
    mov dh, greenplus
    mov bx, ds:[di]	
	call print
	
	pop ax
	mov ds:[di],ax
	mov dl,' '
	mov dh,red
	mov bx,ds:[di]
	call print
	mov current_color,greenplus
	jmp endMove

pink_color:	
    mov dl, ' '
    mov dh, pink
    mov bx, ds:[di]	
	call print
	
	pop ax
	mov ds:[di],ax
	mov dl,' '
	mov dh,red
	mov bx,ds:[di]
	call print
	;mov color,0
	mov current_color,pink

	jmp endMove	
getFood:
	;If get the food, set the current position of snake head
	;To the food position
	;Set color to select the snake's color
	mov dl,' '
	mov dh,current_color
	mov di,snake_head
	sub di,2
	mov bx,ds:[di]
	call print
	
	mov di,snake_head
	mov ax,food_position
	mov ds:[di],ax
	
	mov dl,' '
	mov dh,red
	mov bx,ds:[di]
	call print
	;Update the snake_head (pointer of next head)
	add di,2
	mov snake_head,di
	;Add your score
	add score,10
	;Inc color
	inc color
	;Add the integral
	inc integral
	cmp integral,5
	ja	zeroing
	jmp continue
	;If the integral > 5, then zeroing it
zeroing:
	mov integral,0
continue:
	call generateFood
	jmp endMove
	
setGameover:
	mov gameover,1
	
endMove:
	;call generateFood
 	popR
	ret
moveSnake endp


generateFood proc near
	;The proc for generate the food
	;Include the position and print the food in the map
	pushR
setFoodPosition:
	
	;Check if the food position coincident with snake
	call getRandPosition
	mov cx,snake_head
	
	sub cx,2
	mov di,2
	shr cx,1


	scan:
		mov ax,ds:[di]
		;If coincident, then restart the segment
		cmp ax,food_position
		jz setFoodPosition
		inc di
		inc di
	loop scan
	
	;Print the food in the map
	mov ax,food_position

	mov bl,byte ptr food_position
	mov bh,byte ptr food_position+1
	mov dl,' '
	mov dh,blue

	call print
	
	
	popR
	ret
generateFood endp


print proc near
	;Proc for print the snake && food in the map
	pushR
	;The position formula is
	;(bh*80+bl)*2
	;Cause i replac a grid with a WORD
	mov al,80
	mul bh
	xor bh,bh
	shl bl,1
	add ax,bx
	
	push si
	mov si,ax
	shl si,1
	;Actually there has two blocks
	mov es:[si],dl
	mov es:[si+1],dh
	mov es:[si+2],dl
	mov es:[si+3],dh
	pop si
	popR
	ret
print endp

setRowBackground proc 
	;The proc for set the row of background
	;The length of the line is 21
	;The length of the column is 39
	;Loop to draw the background symmetrically
	;The setColBackground's algorithm is the same
	pushR
	mov dl,' '
	mov dh,greenplus
	mov bl,0
	mov bh,0
	mov cx,39
drawRow:
	push cx
	push bx
	call print
	pop bx
	push bx
	add bh,21
	call print
	pop bx
	inc bl
	pop cx
	loop drawRow
	popR
	ret
setRowBackground endp
setColBackground proc near
	;The proc for set the col of background
	pushR
	mov dl,' ' 
	mov dh,greenplus
	mov bl,0
	mov bh,0
	mov cx,22
drawCol:
	push cx
	push bx
	call print
	pop bx
	push bx
	add bl,39
	call print
	pop bx
	inc bh
	pop cx
	loop drawCol
	popR
	ret
setColBackground endp

delayInput proc near
	;The proc for delay input
	;And control the snake moving speed
	pushR
	
	mov cx,speed
	input:
		call getInput
		loop input
	popR
	ret
delayInput endp

getRandPosition proc near
	;The proc for getting the food position
	;randomly
	pushR
getRow:
	;Get a random number through port 43h
	;Get the required coordinates based on the boundary
	mov ax,0
	out 43h,al
	in al,40h
	in al,40h
	in al,40h
	
	mov bl,18
	
	div bl
	;ah store the remainder
    
    cmp ah,1
    jb getRow
    cmp ah,18
    ja getRow
    mov byte ptr food_position+1,ah
getCol:	

	mov ax,0
	out 43h,al
	in al,40h
	in al,40h
	in al,40h
	
	mov bl,37
	
	div bl
	
	cmp ah,1
	jb getCol
	cmp ah,37
	ja getCol
	mov byte ptr food_position,ah
popR
	ret
	
getRandPosition endp

outputDec proc near
	;The proc for print the decimal in the screen
	;Use in speed board && score board
	 pushR
	 ;di as the param
	 xor cx,cx
l1:
	 xor dx,dx
	 mov si,10
	 div si
	 push dx
	 inc cx
	 cmp ax,0
	 jne l1
l2:
	 pop dx
	 add dl,30h
	 
	 mov dh,00000111b	 
	 mov es:[di],dl
	 mov es:[di+1],dh	 
	 add di,2 
	 loop l2
	 popR
	 ret
outputDec endp

outputDecTransparent proc near
	 pushR
	 ;di as the param
	 ;Output decimal data transparently
	 xor cx,cx
l1:
	 xor dx,dx
	 mov si,10
	 div si
	 push dx
	 inc cx
	 cmp ax,0
	 jne l1
l2:
	 pop dx
	 add dl,30h
	 mov dh,0	 
	 mov es:[di],dl
	 mov es:[di+1],dh	 
	 add di,2 
	 loop l2
	 popR
	 ret
outputDecTransparent endp

showScore proc near
	 ;The proc for showing the socre board
	 pushR
	 ;Set the score board's location
	 mov si,3520	;(22*80+0)*2
	 mov cx,nstring0
	 mov di,0
setText:
	;show "Your score is:"
	 mov al,string0[di]
	 mov byte ptr es:[si],al
	 mov byte ptr es:[si+1],07h
	 add si,2
	 inc di
	 loop setText
setScore:
	;Set the current score in the screen
	 mov di,si
	 add di,4
	 mov ax,score
	 call outputDec
	 popR
	 ret
showScore endp

showSpeed proc near
	;The proc for showing the speed board
	pushR
	;Set the speed board's location
	mov si,3680	;23*80*2
	mov cx,nstring2
	mov di,0
setText:
	;Print "Current speed is"
	mov al,string2[di]
	mov byte ptr es:[si],al
	mov byte ptr es:[si+1],07h
	add si,2
	inc di
	loop setText
setSpeed: 
	;Print the current speed
	 mov di,si
	 add di,4
	 mov ax,speed_level
	 call outputDec
	 popR
	 ret 
	popR
	ret
showSpeed endp

gameOverP proc near
	;The proc for showing the game over screen
	pushR
	;Set position
	mov si,1330	;(8*80+25)*2
	mov cx,nszgameover
	mov di,0
setText:
	;Print "game over!"
	mov al,szgameover[di]
	mov byte ptr es:[si],al
	mov byte ptr es:[si+1],07h
	add si,2
	inc di
	loop setText
	mov si,1650	;(10*80+25)*2
	mov cx,nstring1
	mov di,0
setString:
	;Print "You have got point:"
	mov al,string1[di]
	mov byte ptr es:[si],al
	mov byte ptr es:[si+1],07h
	add si,2
	inc di
	loop setString
setScore:
	;Print the current score
	mov di,si
	add di,4
	mov ax,score
	call outputDec
	popR
	ret
gameOverP endp
code ends
end start



