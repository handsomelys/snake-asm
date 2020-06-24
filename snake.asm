clearScreen macro
	;25*80分辨率
	mov ah,00h
	mov al,03h
	int 10h
	endm
print macro p1,p2
	mov al,80
	mul bh
	xor bh,bh
	shl bl,1
	add ax,bx
	
	push si
	mov si,ax
	shl si,1
	mov es:[si],p1
	mov es:[si+1],p2
	mov es:[si+2],p1
	mov es:[si+3],p2
	pop si
	endm

printBody macro p1,color
	 mov ax,ds:[p1]
	 mov dl,' '
	 mov dh,color
	 mov bl,al
	 mov bh,ah
	 print dl,dh
	endm
setRowBackground macro p1,p2,p3,p4,p5,p6
	mov dl,p1
	mov dh,p2
	mov bl,p3
	mov bh,p4
	mov cx,p5
drawRow:
	push cx
	push bx
	print dl,dh
	pop bx
	push bx
	add bh,p6
	print dl,dh
	pop bx
	inc bl
	pop cx
	loop drawRow
	endm
setColBackground macro p1,p2,p3,p4,p5,p6
	mov dl,p1
	mov dh,p2
	mov bl,p3
	mov bh,p4
	mov cx,p5
drawCol:
	push cx
	push bx
	print dl,dh
	pop bx
	push bx
	add bl,p6
	print dl,dh
	pop bx
	inc bh
	pop cx
	loop drawCol
	endm
	
.model small
.data
	snake_direction dw 4d00h
	snake_body dw 400 dup(0)
	food_position dw 0
	snake_length dw 4
	score dw 0
	white equ 01110111b
	pink equ 01010101b
	red	equ 01000100b
	yellow equ 01100110b
	grren equ 00110011b
	blue equ 00010001b
	black equ 00000000b
	greenplus equ 00110011b
	up	equ	4800h
	down equ 5000h
	left equ 4b00h
	right equ 4d00h
	nscore equ 25
	score_position equ 26
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
	setRowBackground ' ',white,0,0,30,20
	;设置地图左右边界
	setColBackground ' ',white,0,0,21,30
	
	
	call showScore
	call delay	
	call initSnake
	mov cx,5
l0:
	call moveSnake
	call delay
	loop l0
main endp
showScore proc near
	 push ax
	 push bx
	 push cx
	 push dx
	 push si
	 push di
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
	 xor cx,cx
	 mov cx,5
	 mov si,148
	 mov di,10
	 lset:
	 	xor dx,dx
	 	div di
	 	add dl,30h
	 	mov byte ptr es:[si],dl
	 	sub si,2
	 	loop lset
	 pop di
	 pop si
	 pop dx
	 pop cx
	 pop bx
	 pop ax
	 ret 
showScore endp
initSnake proc near
	 push ax
	 push bx
	 push cx
	 push dx
	 push si
	 push di
	 mov ax,0E0cH
init:
	 mov ds:[di],ax
	 add di,2
	 inc al
	 loop init		 
	 mov di,2
initBody:
	;四段身子
	 mov cx,4
printSnake:
	 
	 mov ax,ds:[di]
	 mov dl,07h
	 mov dh,greenplus
	 mov bl,al
	 mov bh,ah
	 print dl,dh
	 inc di
	 inc di
	 loop printSnake
	;四段身子初始化结束
	 pop di
	 pop si
	 pop dx
	 pop cx
	 pop bx
	 pop ax
	 ret
initSnake endp

movesnake proc near
	push ax
	push bx
	push cx
	push dx
	push si
	push di

	mov ax,snake_direction

	mov di,snake_length
	sub di,2
	
	cmp ax,right
	je move_r
move_r:
	mov ax,ds:[di]
	add al,1
	jmp judgePlug
	
judgePlug:
	push ax
	cmp ah,0
	je gameend
	cmp ah,21
	je gameend
	cmp al,0
	je gameend
	cmp al,30
	je gameend
	
	mov cx,snake_length
	sub cx,6
	mov di,2
	shr cx,1
	
s0:
	mov bx,ds:[di]
	cmp bx,ax
	je gameend
	
	add di,2
	loop s0
	
	pop ax
update:
	mov cx,snake_length
	sub cx,6
	mov di,2
	shr cx,1
	push ax
	
	mov dl,' '
	mov dh,black
	mov bx,ds:[di]
	print dl,dh
	
s5:
	mov dx,ds:[di+2]
	mov ds:[di],dx
	add di,2
	loop s5
	
	mov dl,' '
	mov dh,71h
	mov bx,ds:[di]
	print dl,dh
	
	pop ax
	mov ds:[di],ax
	mov dl,' '
	mov dh,44h
	mov bx,ds:[di]
	print dl,dh

gameend:
 	 pop di
	 pop si
	 pop dx
	 pop cx
	 pop bx
	 pop ax
	ret
movesnake endp

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
	add ax,1
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

end start





