clearScreen macro
	;25*80分辨率
	mov ah,00h
	mov al,03h
	int 10h
	endm

pushR macro
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	endm

popR macro
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
	snake_direction db 4dh,00h
	snake_body dw 400 dup(0)
	food_position dw 0
	snake_body_length dw 3
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
data ends
code segment
assume ds:data,cs:code,ss:stack
start:
main proc far

game:
	mov ax,data
	mov ds,ax
	mov ax,stack
	mov ss,ax
	lea sp,top
	
	mov ax,0b800h
	mov es,ax	;直接写屏
	
	mov si,2	;定位到body 初始化蛇
	mov cx,4

	
	clearScreen
	;设置地图上下边界
	call setRowBackground 
	;设置地图左右边界
	call setColBackground 
	
	
	call showScore
	
	call initSnake
	
	call generateFood
	;mov ax,snake_body_length
	;call outputOct body_length,382
	call showSpeed
game1:		
		cmp gameover,1
		je	endgame
        call moveSnake
        
		call delayInput
		call showScore
		;call showSpeed
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
	call showScore	
	mov ah,4ch
	int 21h
main endp
showScore proc near
	 pushR
	 mov dh,07h
	 mov cx,7
	 ;mov si,125	;(80*0+52)*2+1
	 mov si,3521	;22*80*2+1
setColorForScore:
	 mov es:[si],dh
	 add si,2
	 loop setColorForScore
setScoreFont:
	 mov byte ptr es:[3522],'s'
	 mov byte ptr es:[3524],'c'
	 mov byte ptr es:[3526],'o'
	 mov byte ptr es:[3528],'r'
	 mov byte ptr es:[3530],'e'
	 mov byte ptr es:[3532],':'
setScore: 
	 mov ax,score
	 push di
	 mov di,3536
	 call outputDec
	 pop di
	 popR
	 ret 
showScore endp
initSnake proc near
	 pushR
	 mov byte ptr ds:[0],right
	 mov ax,0808H
	 mov di,2
init:
	 mov ds:[di],ax
	 add di,2
	 inc al
	 loop init		 
	 mov di,2
initBody:
	;四段身子
	 
printSnake:
	 
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
	 mov snake_head,di
	;四段身子初始化结束
	 popR
	 ret
initSnake endp

getInput proc near
	pushR
	mov al,0
	mov ah,1
	int 16h
	
	cmp ah,1
	je endGetInput
	
	mov al,0
	mov ah,0
	int 16h
	
left_key:
	cmp ah,left
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
	pushR
	
	
	mov di,snake_head
	sub di,2
	cmp byte ptr ds:[0],up
	je move_up
	
	;mov ax,snake_direction
    cmp byte ptr ds:[0], down
    je move_down

    ;mov ax,snake_direction
    cmp byte ptr ds:[0], left
    je move_left

    ;mov ax,snake_direction
    cmp byte ptr ds:[0], right
    je move_right
    
 	move_up:
        mov ax, ds:[di]
        sub ax,0100h
        jmp checkout

    move_down:
        mov ax, ds:[di]
        add ax,0100h
        jmp checkout
    move_left:
        mov ax, ds:[di]
        sub ax,0001h
        jmp checkout

    move_right:
        mov ax, ds:[di]
        add ax,0001h
        ;mov ds:[di], ax
        jmp checkout	
        
checkout: 

	cmp ah, 0
    je setGameover
    cmp ah, 21
    je setGameover
    cmp al, 0
    je setGameover
    cmp al, 39
    je setGameover
    
    mov cx, snake_head
    sub cx, 4
    mov di, 2
	shr cx,1
	
    s0: 
        
        cmp ds:[di], ax
        je setGameover

        add di, 2

        loop s0


	mov bx,food_position
	
	
	push ax
	push bx
	xor bx,bx 
	mov bx,food_position
	xor ax,ax
	mov al,bh
	mov di,500
	call outputDec
	 
	xor ax,ax
	mov al,bl
	mov di,506
	call outputDec
	pop bx
	pop ax
	
	cmp ax,bx	
		
	je getFood
	
	;jmp backWardBody
	
backWardBody:
	mov cx,snake_head
	
	sub cx,4
	mov di,2
	
	shr cx,1
	push ax
	mov dl,' '
	mov dh,black
	mov bx,ds:[di]
	call print	
s5: 
        mov dx, ds:[di+2]
        mov ds:[di], dx

        add di, 2

        loop s5

    mov dl, ' ';字符
    mov dh, white;颜色
    mov bx, ds:[di]	
	call print
	
	pop ax
	mov ds:[di],ax
	mov dl,' '
	mov dh,red
	mov bx,ds:[di]
	call print
	jmp endMove

getFood:
	mov dl,' '
	mov dh,white
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
	
	add di,2
	mov snake_head,di
	add score,10
	inc integral
	cmp integral,5
	ja	zeroing
	jmp continue
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
	pushR
setFoodPosition:
	
	call getRandPosition
	mov cx,snake_head
	
	sub cx,4
	mov di,2
	shr cx,1


	scan:
		mov ax,ds:[di]
		cmp ax,food_position
		jz setFoodPosition
		inc di
		inc di
	loop scan
	
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
	pushR
	mov al,80
	mul bh
	xor bh,bh
	shl bl,1
	add ax,bx
	
	push si
	mov si,ax
	shl si,1
	mov es:[si],dl
	mov es:[si+1],dh
	mov es:[si+2],dl
	mov es:[si+3],dh
	pop si
	popR
	ret
print endp

setRowBackground proc 
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
	pushR
	mov cx,speed
	input:
		call getInput
		loop input
	popR
	ret
delayInput endp

getRandPosition proc near
pushR
getRow:

	mov ah,0
	int 1ah
	mov ax,dx
	and ah,3
	mov dl,19
	div dl
	;ah存余数
    
    cmp ah,1
    jb getRow
    cmp ah,18
    ja getRow
    mov byte ptr food_position+1,ah
getCol:	

	mov ah,0
	int 1ah
	mov ax,dx
	and ah,3
	mov dl,38
	div dl
	;ah存余数
	
	cmp ah,1
	jb getCol
	cmp ah,37
	ja getCol
	mov byte ptr food_position,ah
popR
	ret
	
getRandPosition endp

outputDec proc near
	 pushR
	 ;di作为输出的参数
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
	 ;mov si,382
	 mov dh,00000111b
	 
	 mov es:[di],dl
	 mov es:[di+1],dh
	 
	 add di,2 
	 loop l2
	 popR
	 ret
outputDec endp

showSpeed proc near
	pushR
	mov si,3681	;23*80*2+1
setSpeedFont:
	 mov byte ptr es:[3682],'s'
	 mov byte ptr es:[3683],07h
	 mov byte ptr es:[3684],'p'
	 mov byte ptr es:[3685],07h
	 mov byte ptr es:[3686],'e'
	 mov byte ptr es:[3687],07h
	 mov byte ptr es:[3688],'e'
	 mov byte ptr es:[3689],07h
	 mov byte ptr es:[3690],'d'
	 mov byte ptr es:[3691],07h
	 mov byte ptr es:[3692],':'
	 mov byte ptr es:[3693],07h
setSpeed: 
	 mov ax,speed_level
	 push di
	 mov di,3696
	 call outputDec
	 pop di
	 popR
	 ret 
	popR
	ret
showSpeed endp




code ends
end start

