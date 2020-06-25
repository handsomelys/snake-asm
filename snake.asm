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

.model small
.data
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
.code
start:
main proc far
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
	
	mov ax,snake_body_length
	;call outputOct

game:
        push cx

        call moveSnake

        mov cx, 0Fh
        aaaa1:
            push cx
            mov cx, 0FFFh
            bbbb:
                push cx
                call getInput
                pop cx
                loop bbbb
            pop cx
            loop aaaa1
        jmp game
			
	mov ah,4ch
	int 21h
main endp
showScore proc near
	 pushR
	 mov dh,07h
	 mov cx,7
	 mov si,125	;(80*0+52)*2+1
setColorForScore:
	 mov es:[si],dh
	 add si,2
	 loop setColorForScore
setScoreFont:
	 mov byte ptr es:[126],'s'
	 mov byte ptr es:[128],'c'
	 mov byte ptr es:[130],'o'
	 mov byte ptr es:[132],'r'
	 mov byte ptr es:[134],'e'
	 mov byte ptr es:[136],':'
setScore: 
	 mov ax,score
	 mov cx,5
	 mov si,146
	 mov bx,10
	 lset:
	 	mov dx,0
	 	div bx
	 	add dl,30h
	 	mov byte ptr es:[si],dl
	 	mov byte ptr es:[si+1],00000111b
	 	sub si,2
	 	loop lset
	 popR
	 ret 
showScore endp
initSnake proc near
	 pushR
	 mov byte ptr ds:[0],right
	 mov ax,0d0eH
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
	 mov dl,07h
	 mov dh,white
	 mov bl,al
	 mov bh,ah
	 call print
	 inc di
	 inc di
	 
	 mov ax,ds:[di]
	 mov dl,07h
	 mov dh,white
	 mov bl,al
	 mov bh,ah
	 call print
	 inc di
	 inc di
	 
	 mov ax,ds:[di]
	 mov dl,07h
	 mov dh,white
	 mov bl,al
	 mov bh,ah
	 call print
	 inc di
	 inc di
	 
	 mov ax,ds:[di]
	 mov dl,07h
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
        sub ah, 1
        jmp checkBody

    move_down:
        mov ax, ds:[di]
        add ah, 1
        jmp checkBody
    move_left:
        mov ax, ds:[di]
        sub al, 1
        jmp checkBody

    move_right:
        mov ax, ds:[di]
        add al, 1
        ;mov ds:[di], ax
        jmp checkBody	
        
checkBody: 

	cmp ah, 0
    je setGameover
    cmp ah, 20
    je setGameover
    cmp al, 0
    je setGameover
    cmp al, 30
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

backWardBody:
	mov cx,snake_head
	
	sub cx,4
	mov di,2
	
	shr cx,1
	push ax
	mov dl,' '
	mov dh,black
	mov bx,ds:[di]
	call print	;走不到这步

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

setGameover:
	mov gameover,1
	
endMove:
 	popR
	ret
moveSnake endp



delay proc near
delayed_one_second:
	push ax
	push ds
	push si
	push cx
	 
	mov ax,0
	mov ds,ax
	mov si,46ch
	lodsw
	;设置时延
	add ax,3
	mov cx,ax
	_delayed_one_second:
	mov si,46ch
	lodsw
	cmp ax,cx
	jnb _delayed_over
	jmp _delayed_one_second
	 
	_delayed_over:
	pop cx
	pop si
	pop ds
	pop ax
	ret
delay endp

outputOct proc near
	pushR
	
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
	mov si,381
	mov dh,white
	mov es:[si],dl
	mov es:[si+1],dh
	
	add si,2	
	loop l2
	popR
	ret
outputOct endp

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
	mov dh,white
	mov bl,0
	mov bh,0
	mov cx,30
drawRow:
	push cx
	push bx
	call print
	pop bx
	push bx
	add bh,20
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
	mov dh,white
	mov bl,0
	mov bh,0
	mov cx,21
drawCol:
	push cx
	push bx
	call print
	pop bx
	push bx
	add bl,30
	call print
	pop bx
	inc bh
	pop cx
	loop drawCol
	popR
	ret
setColBackground endp
end start

