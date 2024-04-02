# Bitmap display starter code
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
.data
#hitbox: .word 9
platformX: .word 6, 18
platformY: .word 48, 40
platformSize: .word 10, 11
platformLen: .word 2
.eqv BASE_ADDRESS 0x10008000
.eqv RESOLUTION 64
.eqv STARTINGX 10
.eqv STARTINGY 45
.eqv RED 0xff0000
.eqv GREEN 0x00ff00
.eqv BLUE 0x0000ff
.eqv CYAN 0x00ffff
.globl main
.text
main:	
	li $t0, BASE_ADDRESS
	# Create center for playable object
	li $s1, STARTINGX
	li $s2, STARTINGY
	li $s3, CYAN
	
	addi $sp, $sp, -12
	sw $s1, 0($sp)
	sw $s2, 4($sp)
	sw $s3, 8($sp)
	jal drawPixel
	
	# Create playable object
	li $s4, 3
	li $s3, GREEN
	
	addi $s1, $s1, -1 
	addi $s2, $s2, -1
	
	addi $sp, $sp, -16
	sw $s1, 0($sp)
	sw $s2, 4($sp)
	sw $s3, 8($sp)
	sw $s4, 12($sp)
	jal drawLineX
	
	addi $sp, $sp, -16
	sw $s1, 0($sp)
	sw $s2, 4($sp)
	sw $s3, 8($sp)
	sw $s4, 12($sp)
	jal drawLineY
	
	addi $s1, $s1, 2
	
	addi $sp, $sp, -16
	sw $s1, 0($sp)
	sw $s2, 4($sp)
	sw $s3, 8($sp)
	sw $s4, 12($sp)
	jal drawLineY
	
	# Create Platforms
	li $s3, RED
	
	la $t6, platformX # store address of X
	la $t7, platformY # store address of Y
	la $t8, platformSize # store address of Size
	lw $t9, platformLen
	jal createPlatforms
	
	j end
	
createPlatforms:
	bge $zero, $t9, return
	lw $s1, 0($t6)
	lw $s2, 0($t7)
	lw $s4, 0($t8)
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $s4, 0($sp)
	addi $sp, $sp, -4
	sw $s3, 0($sp)
	addi $sp, $sp, -4
	sw $s2, 0($sp)
	addi $sp, $sp, -4
	sw $s1, 0($sp)
	jal drawLineX
	
	# Extract from stack
	lw $ra, 0($sp) # load $ra 
	addi $sp, $sp, 4
	
	addi $t6, $t6, 4
	addi $t7, $t7, 4
	addi $t8, $t8, 4
	addi $t9, $t9, -1
	j createPlatforms

drawLineX:	#draws horizontal line on display from left. From stack: x,y,color,size
	# Extract from stack
	lw $t1, 0($sp) # $t1 stores x
	lw $t2, 4($sp) # $t2 stores y
	lw $t3, 8($sp) # $t3 stores color
	lw $t4, 12($sp) # $t4 stores size
	addi $sp, $sp, 16
	add $t5, $t1, $t4 # check if line fits in display
	bge $t5, RESOLUTION, return 
	bge $t2, RESOLUTION, return

drawLineX_loop:
	# Set x,y,color,size,$ra,x,y,color in stack in order
	addi $sp, $sp, -4 # Store x in stack
	sw $t1, 0($sp)
	addi $sp, $sp, -4 # Store y in stack
	sw $t2, 0($sp)
	addi $sp, $sp, -4 # Store color in stack
	sw $t3, 0($sp)
	addi $sp, $sp, -4 # Store size in stack
	sw $t4, 0($sp)
	addi $sp, $sp, -4 # Store $ra in stack
	sw $ra, 0($sp)
	addi $sp, $sp, -4 # Store color in stack
	sw $t3, 0($sp)
	addi $sp, $sp, -4 # Store y in stack
	sw $t2, 0($sp)
	addi $sp, $sp, -4 # Store x in stack
	sw $t1, 0($sp)
	
	# Draw pixel
	jal drawPixel
	
	# Extract from stack
	lw $ra, 0($sp) # load $ra 
	addi $sp, $sp, 4
	lw $t4, 0($sp) # load size 
	addi $sp, $sp, 4
	lw $t3, 0($sp) # load color
	addi $sp, $sp, 4
	lw $t2, 0($sp) # load y
	addi $sp, $sp, 4
	lw $t1, 0($sp) # load x
	addi $sp, $sp, 4
	
	# Increment x and decrease size
	addi $t1, $t1, 1
	addi $t4, $t4, -1
	
	#Loop Case
	bne $t4, $zero, drawLineX_loop
	jr $ra
	
drawLineY:	#draws vertical line on display from up. From stack: x,y,color,size
	# Extract from stack
	lw $t1, 0($sp) # $t1 stores x
	lw $t2, 4($sp) # $t2 stores y
	lw $t3, 8($sp) # $t3 stores color
	lw $t4, 12($sp) # $t4 stores size
	addi $sp, $sp, 16
	add $t5, $t1, $t4 # check if line fits in display
	bge $t5, RESOLUTION, return 
	bge $t2, RESOLUTION, return

drawLineY_loop:
	# Set x,y,color,size,$ra,x,y,color in stack in order
	addi $sp, $sp, -4 # Store x in stack
	sw $t1, 0($sp)
	addi $sp, $sp, -4 # Store y in stack
	sw $t2, 0($sp)
	addi $sp, $sp, -4 # Store color in stack
	sw $t3, 0($sp)
	addi $sp, $sp, -4 # Store size in stack
	sw $t4, 0($sp)
	addi $sp, $sp, -4 # Store $ra in stack
	sw $ra, 0($sp)
	addi $sp, $sp, -4 # Store color in stack
	sw $t3, 0($sp)
	addi $sp, $sp, -4 # Store y in stack
	sw $t2, 0($sp)
	addi $sp, $sp, -4 # Store x in stack
	sw $t1, 0($sp)
	
	# Draw pixel
	jal drawPixel
	
	# Extract from stack
	lw $ra, 0($sp) # load $ra 
	addi $sp, $sp, 4
	lw $t4, 0($sp) # load size 
	addi $sp, $sp, 4
	lw $t3, 0($sp) # load color
	addi $sp, $sp, 4
	lw $t2, 0($sp) # load y
	addi $sp, $sp, 4
	lw $t1, 0($sp) # load x
	addi $sp, $sp, 4
	
	# Increment y and decrease size
	addi $t2, $t2, 1
	addi $t4, $t4, -1
	
	#Loop Case
	bne $t4, $zero, drawLineY_loop
	jr $ra

drawPixel:	#draws pixel on display. From stack: x,y,color
	li $t0 BASE_ADDRESS
	lw $t1, 0($sp)
	lw $t2, 4($sp)
	lw $t3, 8($sp)
	addi $sp, $sp, 12
	mul $t2, $t2, RESOLUTION
	add $t1, $t1, $t2
	mul $t1, $t1, 4
	add $t1,$t1,$t0
	
	sw $t3, 0($t1)
	jr $ra

return:	#returns to prior PC
	jr $ra

end: 	li $v0, 10                  # terminate the program gracefully
	syscall