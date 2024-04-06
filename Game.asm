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
CharX: .word 12
CharY: .word 40
Lives: .word 3
EnemyX: .word 4,4
EnemyY: .word 22, 38
EnemyNum: .word 2
Bullets: .word 0:2
platformX: .word 1,1,11, 19, 24, 28, 16, 48,45
platformY: .word 24,40,48, 40, 24, 32, 16, 32,16
platformSize: .word 6,6,10, 11, 8, 13, 13, 5,7
platformLen: .word 9
newline: .asciiz "\n"
.eqv SPEED 4
.eqv JUMP 15
.eqv BASE_ADDRESS 0x10008000
.eqv RESOLUTION 64

.eqv CENTERCOLOR CYAN
.eqv CHARCOLOR RED
.eqv BORDERCOLOR 0xe6cc00
.eqv PLATFORMCOLOR 0xD16002
.eqv ENEMYTOPCOLOR 0x707070
.eqv ENEMYBOTTOMCOLOR 0x9c5a3c
.eqv BULLETCOLOR 0xb4b4b4
.eqv RED 0xff0000
.eqv GREEN 0x00ff00
.eqv BLUE 0x0000ff
.eqv CYAN 0x00ffff
.globl main
.text
main:	# Sets up the game
	li $t0, BASE_ADDRESS
	# Draw border 
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
	# Create playable character
	jal createChar
	# Create Platforms
	la $a0, platformX # store address of X
	la $a1, platformY # store address of Y
	la $a2, platformSize # store address of Size
	lw $a3, platformLen
	jal createPlatforms
	# Create Enemies
	jal createEnemies
	# Create Lives
	jal createLives
	lw $s0, Lives
mainLoop: # main loop of the game
	li $s1, 1 # $s1 = character has not collided with bullet nor fallen off
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	bne $t8, 1, skipKey
	jal keyPress
skipKey:
	li $v0, 0
	jal fall
	
	# Update bullets and items
	la $t1, Bullets
	lw $t2, 0($t1) # Address in current Bullets array
	li $a0, 8 # Bullets x
	li $a1,21 # Bullet y
	move $a2, $t1 # Current Bullets array
	bne $t2, 0, skipEnemy1 # If bullet does not exist, enemy fires a bullet
	jal enemyFire
skipEnemy1:
	la $t1, Bullets
	li $a0, 8 # Bullets x
	li $a1,37 # Bullet y
	addi $a2, $t1, 4 # Current Bullets array 
	lw $t2, 0($a2) # Address  in current Bullets array
	bne $t2, 0, skipEnemy2 # If bullet does not exist, enemy fires a bullet
	jal enemyFire
skipEnemy2:
	la $t1, Bullets
	li $t2, 2
	jal bulletsMove
	# Check collision
	
	beq $s1, 1, skipDeath
	jal death
skipDeath:
	li $v0, 32
	li $a0, 120 # Wait 120 milliseconds
	syscall
	j mainLoop
keyPress: # Check for input
	lw $t2, 4($t9) 
	li $a0, JUMP
	beq $t2, 0x61, moveLeft # a = left
	beq $t2, 0x64, moveRight # d = right
	beq $t2, 0x77, jumpCheck # w = jump
	beq $t2, 0x72, restart # r = reset
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
	
removeLife: # Removes a life from the screen
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $s0, $s0, -1
	blt $s0, 0, gameOver
	beq $s0, 0, lastLife
	beq $s0, 1, midLife
	# Remove First life
	li $a0, 40
	li $a1, 59
	li $a2, 0
	li $a3, 5
	jal drawLineX
	
	li $a0, 42
	li $a1, 57
	li $a2, 0
	li $a3, 5
	jal drawLineY
	j respawnChar
lastLife: # Removes last life
	li $a0, 56
	li $a1, 59
	li $a2, 0
	li $a3, 5
	jal drawLineX
	
	li $a0, 58
	li $a1, 57
	li $a2, 0
	li $a3, 5
	jal drawLineY
	j respawnChar
midLife: # Removes middle life
	li $a0, 48
	li $a1, 59
	li $a2, 0
	li $a3, 5
	jal drawLineX
	
	li $a0, 50
	li $a1, 57
	li $a2, 0
	li $a3, 5
	jal drawLineY
	j respawnChar
respawnChar:	# Create new character at starting x and y
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
	li $s1, 0 # Unless changed, player has fallen off and died
	la $t1, hitbox
	lw $t2, 24($t1)
	lw $t3, 28($t1)
	lw $t4, 32($t1)	
	
	sub $t6, $t2, $t0
	li $t5, 13568
	bge $t6, $t5, return # Checks if player has fallen off
	
	li $s1, 1 # Player has not fallen off
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

bulletsMove: # Bullets move right until collision. $t1=address of Bullets array, $t2=size of Bullets array
	lw $t3, 0($t1) # $t3 = address of current bullet
	addi $t4, $t3, 4 # $t4 = address of front of current bullet
	lw $t5, 0($t4) # $t5 = Color of front of current bullet
	bne $t5, 0, bulletCollision # Check for collision
	sw $t4, 0($t1) # new address of bullet
	li $t5, BULLETCOLOR
	sw $t5, 0($t4) # Color head of bullet
	addi $t4, $t3, -4 # pixel bullet has passed
	sw $zero, 0($t4) # remove trail
bulletsMoveEnd:
	addi $t1, $t1, 4
	addi $t2, $t2, -1
	bne $t2, 0, bulletsMove
	jr $ra
	
bulletCollision: # Bullet collides into an object and disappears. $t1=address of Bullets array, $t3=address of current bullet,$t5 = Color of object bullet has collided with
	sw $zero, 0($t1) # Reset address in Bullets array
	sw $zero, 0($t3)
	sw $zero, -4($t3)
	beq $t5, CHARCOLOR, bulletHit
	j bulletsMoveEnd
bulletHit: # Bullet collided with player
	li $s1, 0 # Player is killed
	j bulletsMoveEnd
enemyFire: # Creates a bullet. $a0 = x, $a1 = y, $a2 = Current Bullets array
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Save head of bullet in Bullets array
	mul $t2, $a1, RESOLUTION # $t2 = y*Res
	add $t3, $a0, 1 # $t3 = x + 1 for head of bullet
	add $t2, $t2, $t3 # $t2 = x+1+y*Res 
	mul $t2, $t2, 4 # $t2 = 4*(x+1+y*Res)
	add $t2, $t2, $t0
	sw $t2, 0($a2) 
	li $a2, BULLETCOLOR
	li $a3, 2
	
	jal drawLineX
	
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
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
	
createEnemies: # Creates enemies
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $s1, EnemyX
	la $s2, EnemyY
	lw $s3, EnemyNum
	
	jal drawEnemy
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
drawEnemy: # Draws Enemy
	addi $sp, $sp, -4
	sw $ra, 0($sp)	
	
	lw $s5, 0($s1) # $t5 = Enemy x
	lw $s6, 0($s2) # $t6 = enemy y
	
	addi $a0, $s5, -2
	addi $a1, $s6, -1
	li $a2, ENEMYTOPCOLOR
	li $a3, 6
	jal drawLineX
	
	addi $a0, $s5, -1
	addi $a1, $s6, 0
	li $a2, ENEMYBOTTOMCOLOR
	li $a3, 3
	jal drawLineX
	
	addi $a0, $s5, -1
	addi $a1, $s6, 1
	li $a2, ENEMYBOTTOMCOLOR
	jal drawPixel
	
	addi $a0, $s5, 1
	addi $a1, $s6, 1
	li $a2, ENEMYBOTTOMCOLOR
	jal drawPixel
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	addi $s3, $s3, -1	
	addi $s1, $s1, 4
	addi $s2, $s2, 4
	bgt $s3, 0, drawEnemy
	jr $ra
createLives:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	li $a0, 56
	li $a1, 59
	li $a2, RED
	li $a3, 5
	jal drawLineX
	
	li $a0, 58
	li $a1, 57
	li $a2, RED
	li $a3, 5
	jal drawLineY
	
	li $a0, 48
	li $a1, 59
	li $a2, RED
	li $a3, 5
	jal drawLineX
	
	li $a0, 50
	li $a1, 57
	li $a2, RED
	li $a3, 5
	jal drawLineY
	
	li $a0, 40
	li $a1, 59
	li $a2, RED
	li $a3, 5
	jal drawLineX
	
	li $a0, 42
	li $a1, 57
	li $a2, RED
	li $a3, 5
	jal drawLineY
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
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
restart:
	la $a0, BASE_ADDRESS
	li $a1, 4096
	li $a2, 0
	jal fill
	j main
gameOver:
	la $a0, BASE_ADDRESS
	li $a1, 4096
	li $a2, BLUE
	jal fill
	j end
fill: # Fills the display with pixels. $a0=BASE_ADDRESS, $a1=Number of pixels, $a2=color to be filled in
	sw $a2, 0($a0)
	addi $a0, $a0, 4 	# advance to next pixel position in display
	addi $a1, $a1, -1	# decrement number of pixels
	bnez $a1, fill	# repeat while number of pixels is not zero
	jr $ra
end: 	li $v0, 10                  # terminate the program gracefully
	syscall
