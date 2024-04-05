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
hitbox: .word 0:9
hitboxLen: .word 9
CharX: .word 10
CharY: .word 20
platformX: .word 6, 18, 24, 28, 16, 48
platformY: .word 48, 40, 24, 32, 16, 32
platformSize: .word 10, 11, 8, 13, 13, 5
platformLen: .word 6
newline: .asciiz "\n"
.eqv SPEED 4
.eqv JUMP 15
.eqv BASE_ADDRESS 0x10008000
.eqv RESOLUTION 64

.eqv CENTERCOLOR CYAN
.eqv CHARCOLOR RED
.eqv BORDERCOLOR 0xD16002
.eqv PLATFORMCOLOR 0xe6cc00
.eqv RED 0xff0000
.eqv GREEN 0x00ff00
.eqv BLUE 0x0000ff
.eqv CYAN 0x00ffff
.globl main
.text
main:	
	# Sets up the game
	li $t0, BASE_ADDRESS
	# Draw border ///////////////////////
	li $a0, 0
	li $a1, 0
	li $a2, BORDERCOLOR
	li $a3, 63
	jal drawLineX
	li $a0, 0
	li $a1, 0
	li $a2, BORDERCOLOR
	li $a3, 54
	jal drawLineY
	li $a0, 63
	li $a1, 0
	li $a2, BORDERCOLOR
	li $a3, 54
	jal drawLineY
	li $a0, 0
	li $a1, 54
	li $a2, BORDERCOLOR
	li $a3, 64
	jal drawLineX
	#jal drawBorder
	
	# Create playable object
	
	jal createChar
	
	
	# Create Platforms
	li $s3, RED
	
	la $a0, platformX # store address of X
	la $a1, platformY # store address of Y
	la $a2, platformSize # store address of Size
	lw $a3, platformLen
	jal createPlatforms
	
	#la $t1, hitbox
	#lw $t2, 0($t1)
	#addi $t2, $t2, -4
	#lw $t2, 0($t2)
	#lw $t3, 12($t1)
	#lw $t3, 0($t3)
	#lw $t4, 24($t1)
	#lw $t4, 0($t4)
	
	#li $v0, 1
	#move $a0, $t2
	#syscall
	
	#li $v0, 4
	#la $a0, newline
	#syscall 
	
	#li $v0, 1
	#move $a0, $t3
	#syscall
	
	#li $v0, 4
	#la $a0, newline
	#syscall
	
	#li $v0, 1
	#move $a0, $t4
	#syscall
	
	#li $v0, 4
	#la $a0, newline
	#syscall 
	

mainLoop: # main loop of the game
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	bne $t8, 1, skipKey
	jal keyPress
skipKey:
	li $v0, 0
	jal fall
	beq $v0, 1, skipDeath
	jal death
skipDeath:
	li $v0, 32
	li $a0, 66 # Wait 66 milliseconds
	syscall
	j mainLoop
keyPress: # Check for input
	lw $t2, 4($t9) 
	li $a0, JUMP
	beq $t2, 0x61, moveLeft # a = left
	beq $t2, 0x64, moveRight # d = right
	beq $t2, 0x77, jumpCheck # w = jump
	beq $t2, 0x72, main # r = reset
	beq $t2, 0x71, end # q = quit
	jr $ra
death: # Character took damage or fell from world
	la $t1, hitbox
	li $t2, 0
	li $t6, 32 #Limit (Included)
	
death_loop: # Remove color of each hitbox
	add $t4, $t1, $t2 # $t4 = addr(hitbox) + i
	lw $t5, 0($t4) # $t5 = current address
	li $t9, 0
	sw $t9, 0($t5) # color at current address
	
	addi $t2, $t2, 4 # $t2 iterates hitbox array
	
	ble $t2, $t6, death_loop
	# When current charcater disappears, create new character at starting x and y
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal createChar
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	
moveLeft:
	la $t1, hitbox
	lw $t2, 0($t1)
	lw $t3, 12($t1)
	lw $t4, 24($t1)
	li $t5, 256
	sub $t6, $t2, $t0
	div $t6, $t5
	
	mfhi $t5
	beq $t5, $zero, return
	
	addi $t2, $t2, -SPEED # Check left of top left
	lw $t2, 0($t2)
	bne $t2, 0, return
	
	addi $t3, $t3, -SPEED # Check left of middle left
	lw $t3, 0($t3)
	bne $t3, 0, return
	
	addi $t4, $t4, -SPEED # Check left of bottom left
	lw $t4, 0($t4)
	bne $t4, 0, return
	li $a0, -SPEED
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal updateChar
	
	lw $t2, 8($t1)
	addi $t2, $t2, SPEED
	sw $zero, 0($t2)
	lw $t3, 20($t1)
	addi $t3, $t3, SPEED
	sw $zero, 0($t3)
	lw $t4, 32($t1)
	addi $t4, $t4, SPEED
	sw $zero, 0($t4)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
moveRight:
	la $t1, hitbox
	lw $t2, 8($t1)
	lw $t3, 20($t1)
	lw $t4, 32($t1)
	
	sub $t5, $t2, $t0
	li $t6, 4
	div $t5, $t6
	mflo $t5
	
	#mfhi $t5
	#beq $t5, $zero, return

	addi $t2, $t2, SPEED # Check right of top right
	lw $t2, 0($t2)
	bne $t2, 0, return
	
	addi $t3, $t3, SPEED # Check left of middle right
	lw $t3, 0($t3)
	bne $t3, 0, return
	
	addi $t4, $t4, SPEED # Check left of bottom right
	lw $t4, 0($t4)
	bne $t4, 0, return
	li $a0, 4
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal updateChar
	
	lw $t2, 0($t1)
	addi $t2, $t2, -SPEED
	sw $zero, 0($t2)
	lw $t3, 12($t1)
	addi $t3, $t3, -SPEED
	sw $zero, 0($t3)
	lw $t4, 24($t1)
	addi $t4, $t4, -SPEED
	sw $zero, 0($t4)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
jumpCheck: # Checks if character is airborne
	la $t1, hitbox
	lw $t2, 24($t1)
	lw $t3, 28($t1)
	lw $t4, 32($t1)	
	
	sub $t6, $t2, $t0
	li $t5, 256
	blt $t6, $t5, return

	addi $t2, $t2, 256 # Check bottom of bottom left
	lw $t2, 0($t2)
	bne $t2, 0, jump
	
	addi $t3, $t3, 256 # Check bottom of bottom middle
	lw $t3, 0($t3)
	bne $t3, 0, jump
	
	addi $t4, $t4, 256 # Check bottom of bottom right
	lw $t4, 0($t4)
	bne $t4, 0, jump
	jr $ra
	
jump: # Jump for JUMP iterations
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal moveUp
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	lw $a0, 0($sp)
	addi $sp, $sp, 4
	subi $a0, $a0, 1
	bne $a0, $zero, jump
	jr $ra

moveUp: # Move up one pixel to jump
	la $t1, hitbox
	lw $t2, 0($t1)
	lw $t3, 4($t1)
	lw $t4, 8($t1)	
	
	sub $t6, $t2, $t0
	li $t5, 256
	blt $t6, $t5, return

	addi $t2, $t2, -256 # Check up of top left
	lw $t2, 0($t2)
	bne $t2, 0, return
	
	addi $t3, $t3, -256 # Check up of top middle
	lw $t3, 0($t3)
	bne $t3, 0, return
	
	addi $t4, $t4, -256 # Check left of top right
	lw $t4, 0($t4)
	bne $t4, 0, return
	li $a0, -256
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal updateChar
	
	lw $t2, 24($t1)
	addi $t2, $t2, 256
	sw $zero, 0($t2)
	lw $t3, 28($t1)
	addi $t3, $t3, 256
	sw $zero, 0($t3)
	lw $t4, 32($t1)
	addi $t4, $t4, 256
	sw $zero, 0($t4)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
fall:
	j moveDown

moveDown: 
	la $t1, hitbox
	lw $t2, 24($t1)
	lw $t3, 28($t1)
	lw $t4, 32($t1)	
	
	sub $t6, $t2, $t0
	li $t5, 13568
	bge $t6, $t5, return
	
	li $v0, 1
	addi $t2, $t2, 256 # Check bottom of bottom left
	lw $t2, 0($t2)
	bne $t2, 0, return
	
	addi $t3, $t3, 256 # Check bottom of bottom middle
	lw $t3, 0($t3)
	bne $t3, 0, return
	
	addi $t4, $t4, 256 # Check bottom of bottom right
	lw $t4, 0($t4)
	bne $t4, 0, return
	li $a0, 256
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal updateChar
	
	lw $t2, 0($t1)
	addi $t2, $t2, -256
	sw $zero, 0($t2)
	lw $t3, 4($t1)
	addi $t3, $t3, -256
	sw $zero, 0($t3)
	lw $t4, 8($t1)
	addi $t4, $t4, -256
	sw $zero, 0($t4)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
updateChar: # Updates position of character. $a0=change in position
	la $t1, hitbox
	li $t2, 0
	move $t3, $a0
	li $t6, 32 #Limit (Included)
	
StoreColor: # Store color of each hitbox in Stack to set later
	add $t4, $t1, $t2 # $t4 = addr(hitbox) + i
	lw $t5, 0($t4) # $t5 = current address
	lw $t8, 0($t5) # color at current addrss
	addi $sp, $sp, -4
	sw $t8, 0($sp) 
	
	addi $t2, $t2, 4 # $t2 iterates hitbox array
	
	ble $t2, $t6, StoreColor
	li $t2, 32
moveLoop: # Moves each hitbox address by value in $t3
	add $t4, $t1, $t2 # $t4 = addr(hitbox) + i
	lw $t5, 0($t4) # $t5 = current address
	#ld $t8, 0($t5)
	#li $t9, 0
	#sw $t9, 0($t5)
	add $t5, $t5, $t3 # $t5 = new address
	
	lw $t8, 0($sp)
	addi $sp, $sp, 4
	sw $t8, 0($t5) # save color in new address
	sw $t5, 0($t4) # new address saved in current hitbox i
	addi $t2, $t2, -4 # $t2 iterates hitbox array in reverse
	
	bge $t2, $zero, moveLoop
	jr $ra

	
	
createChar: # Creates playable character.
	lw $s1, CharX
	lw $s2, CharY
	la $s3, hitbox
	lw $s4, hitboxLen
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Set top hitbox
	addi $a0, $s1, -1
	addi $a1, $s2, -1
	li $t1, 0
	jal setHitbox 
	
	# Set middle hitbox
	addi $s3, $s3, 12
	addi $a0, $s1, -1
	addi $a1, $s2, 0
	li $t1, 0
	jal setHitbox 
	
	# Set bottom hitbox
	addi $s3, $s3, 12
	addi $a0, $s1, -1
	addi $a1, $s2, 1
	li $t1, 0
	jal setHitbox 
	

	# Create center
	move $a0, $s1
	move $a1, $s2
	li $a2, CENTERCOLOR
	
	jal drawPixel
	
	addi $a0, $s1, 0
	addi $a1, $s2, 1
	li $a2, 0
	
	jal drawPixel
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

setHitbox: # Saves next three horizontal addresses in hitbox. $a0=x, $a1=y, $s3=hitbox, $t1=0
	li $t2,8  # Include when t1=0,4 or 8; cannot increment further
	li $t0, BASE_ADDRESS
	
	mul $t5, $a1, RESOLUTION
	add $t5, $t5, $a0
	mul $t5, $t5, 4 
	add $t5, $t5, $t0 # $t5 stores address of pixel in display
	
	add $t3, $s3, $t1 # $t3 = addr(hitbox) + i
	li $t6, CHARCOLOR
	sw $t6, 0($t5)
	sw $t5, 0($t3) # Save address in $t5 to hitbox array
	addi $t1, $t1, 4 # Increment array iteraing $t1
	
	bgt $t1, $t2, return # Loop Check
	add $a0, $a0, 1
	j setHitbox
	


createPlatforms: # Creates platforms from platforms arrays. $a0=PlatformX,$a1=platformY,$a2=platformSize,$a3=PlatformLEN
	bge $zero, $a3, return
	
	move $s0, $a0 # $s0 = PlatformX
	move $s1, $a1 # $s1 = PlatformY
	move $s2, $a2 # $s2 = PlatformSize
	move $s3, $a3 # $s3 = PlatformLEN
	
	lw $a0, 0($s0)
	lw $a1, 0($s1)
	li $a2, PLATFORMCOLOR
	lw $a3, 0($s2)
	
	addi $sp, $sp, -4 # Save $ra
	sw $ra, 0($sp)
	
	jal drawLineX
	
	lw $ra, 0($sp) # load $ra 
	addi $sp, $sp, 4
	
	addi $a0, $s0, 4
	addi $a1, $s1, 4
	addi $a2, $s2, 4
	addi $a3, $s3, -1
	j createPlatforms

drawLineX:	#draws horizontal line on display from left. $a0=x,$a1=y,$a2=color,$a3=size
	
	move $t1, $a0
	move $t2, $a1
	move $t3, $a2
	move $t4, $a3
	

drawLineX_loop:
	# Set $ra in stack in order
	addi $sp, $sp, -4 # Store $ra in stack
	sw $ra, 0($sp)
	
	# Draw pixel
	move $a0, $t1
	move $a1, $t2
	move $a2, $t3
	move $a3, $t4
	jal drawPixel
	
	# Extract from stack
	lw $ra, 0($sp) # load $ra 
	addi $sp, $sp, 4
	
	# Increment x and decrease size
	addi $t1, $t1, 1
	addi $t4, $t4, -1
	
	#Loop Case
	bne $t4, $zero, drawLineX_loop
	jr $ra
	
drawLineY:	#draws vertical line on display from up. $a0=x,$a1=y,$a2=color,$a3=size
	
	move $t1, $a0
	move $t2, $a1
	move $t3, $a2
	move $t4, $a3

drawLineY_loop:
	# Set $ra in stack in order
	addi $sp, $sp, -4 # Store $ra in stack
	sw $ra, 0($sp)
	
	# Draw pixel
	move $a0, $t1
	move $a1, $t2
	move $a2, $t3
	move $a3, $t4
	jal drawPixel
	
	# Extract from stack
	lw $ra, 0($sp) # load $ra 
	addi $sp, $sp, 4
	
	# Increment x and decrease size
	addi $t2, $t2, 1
	addi $t4, $t4, -1
	
	#Loop Case
	bne $t4, $zero, drawLineY_loop
	jr $ra

drawPixel:	#draws pixel on display. $a0=x,$a1=y,$a2=color
	li $t0 BASE_ADDRESS
	mul $t5, $a1, RESOLUTION
	add $t5, $a0, $t5 # $t5 holds address of the pixel
	mul $t5, $t5, 4
	add $t5,$t5,$t0
	
	sw $a2, 0($t5)
	jr $ra

	jr $ra
return:	#returns to prior PC
	jr $ra

end: 	li $v0, 10                  # terminate the program gracefully
	syscall
