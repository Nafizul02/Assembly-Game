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
EnemyX: .word 4,4
EnemyY: .word 22, 38
EnemyNum: .word 2
Bullets: .word 0:2
platformX: .word 1,1,11, 19, 24, 28, 16, 48,42
platformY: .word 24,40,48, 40, 24, 32, 16, 32,16
platformSize: .word 6,6,10, 11, 8, 13, 13, 5,13
platformLen: .word 9
newline: .asciiz "\n"
.eqv LIVES 2
.eqv SPEED 4
.eqv JUMP 10
.eqv CHARX 12
.eqv CHARY 45
.eqv BASE_ADDRESS 0x10008000
.eqv RESOLUTION 64
.eqv HEALTHX 50
.eqv HEALTHY 28
.eqv DBLJUMPX 22
.eqv DBLJUMPY 12
.eqv DBLJUMPINDX 5
.eqv DBLJUMPINDY 59
.eqv SLEEP 70
.eqv CENTERCOLOR CYAN
.eqv CHARCOLOR BLUE
.eqv HEALTHCOLOR RED
.eqv DBLJUMPCOLOR GREEN
.eqv ENDX 50
.eqv ENDY 12
.eqv BORDERCOLOR 0xe6cc00
.eqv PLATFORMCOLOR 0xD16002
.eqv ENEMYTOPCOLOR 0x707070
.eqv ENEMYBOTTOMCOLOR 0x9c5a3c
.eqv BULLETCOLOR 0xb4b4b4
.eqv RED 0xff0000
.eqv GREEN 0x00ff00
.eqv BLUE 0x0000ff
.eqv CYAN 0x00ffff
.eqv PURPLE 0x6f3198
.eqv WHITE 0xffffff
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
	li $s0, LIVES # $s0 = number of lives in current game, lose if = -1
	jal addLives
	# Create Health Pickup
	li $a0, HEALTHX
	li $a1, HEALTHY
	li $a2, HEALTHCOLOR
	jal drawPickup
	# Create Double Jump Pickup
	li $a0, DBLJUMPX
	li $a1, DBLJUMPY
	li $a2, DBLJUMPCOLOR
	jal drawPickup
	# Create Win Item
	jal drawWinItem
	
	li $a0, CHARX
	li $a1, 42
	li $a2, BULLETCOLOR
	jal drawPixel
	
	li $s2, 0 # $s2 = 0, Double jump has not been picked up
	li $s3, 0 # $s3 = 0, Double Jump not available
	#jal winItem 
	li $s4, 0 # $s4 = 0, Win Item has not been picked up
	li $s5, 0 # $s5 = 0, Game is not over
	
mainLoop: # main loop of the game
	li $s1, 1 # $s1 = 1;character has not collided with bullet nor fallen off
	li $t9, 0xffff0000
	lw $t8, 0($t9)
	bne $t8, 1, skipKey
	jal keyPress
skipKey:
	beq $s5, 1, mainLoop # If game is over, only check for inputs

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
	beq $s4, 0, skipGameWin
	jal gameOver
skipGameWin:
	bge $s0, 0, skipGameLose
	jal gameOver
skipGameLose:
	li $v0, 32
	li $a0, SLEEP # Wait 70 milliseconds
	syscall
	j mainLoop
keyPress: # Check for input
	lw $t2, 4($t9) 
	beq $s5, 1, noInput
	
	beq $t2, 0x61, moveLeft # a = left
	beq $t2, 0x64, moveRight # d = right
	beq $t2, 0x77, jumpCheck # w = jump
noInput: # If game is over, other inputs are not registered
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
	addi $s0, $s0, -1
	bge $s0, 0, playOn
	li $s0, -1
	jr $ra
playOn:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
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
respawnChar:	# Create new character at starting x and y
	jal createChar
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	
moveLeft:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $t1, hitbox
	lw $t2, 0($t1)
	
	addi $t2, $t2, -SPEED # Check left of top left
	lw $t2, 0($t2)
	bne $t2, HEALTHCOLOR, skipL1heal
	jal heal
skipL1heal:
	bne $t2, DBLJUMPCOLOR, skipL1Jump
	jal doubleJump
skipL1Jump:
	bne $t2, PURPLE, skipL1Win
	jal win
skipL1Win:
	beq $t2, PLATFORMCOLOR, return
	beq $t2, BORDERCOLOR, return
	beq $t2, ENEMYTOPCOLOR, return
	beq $t2, BULLETCOLOR, takeDamage
	la $t1, hitbox
	lw $t3, 12($t1)
	addi $t3, $t3, -SPEED # Check left of middle left
	lw $t3, 0($t3)
	bne $t3, HEALTHCOLOR, skipL2heal
	jal heal
skipL2heal:
	bne $t3, DBLJUMPCOLOR, skipL2jump
	jal doubleJump
skipL2jump:
	bne $t3, PURPLE, skipL2Win
	jal win
skipL2Win:
	beq $t3, PLATFORMCOLOR, return
	beq $t3, ENEMYTOPCOLOR, return
	beq $t3, BULLETCOLOR, takeDamage
	la $t1, hitbox
	lw $t4, 24($t1)
	addi $t4, $t4, -SPEED # Check left of bottom left
	lw $t4, 0($t4)
	bne $t4, HEALTHCOLOR, skipL3heal
	jal heal
skipL3heal:
	bne $t4, DBLJUMPCOLOR, skipL3jump
	jal doubleJump
skipL3jump:
	bne $t4, PURPLE, skipL3Win
	jal win
skipL3Win:
	beq $t4, PLATFORMCOLOR, return
	beq $t4, ENEMYTOPCOLOR, return
	beq $t4, BULLETCOLOR, takeDamage
	li $a0, -SPEED
	la $t1, hitbox
	
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
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $t1, hitbox
	lw $t2, 8($t1)

	addi $t2, $t2, SPEED # Check right of top right
	lw $t2, 0($t2)
	bne $t2, HEALTHCOLOR, skipR1heal
	jal heal
skipR1heal:
	bne $t2, DBLJUMPCOLOR, skipR1Jump
	jal doubleJump
skipR1Jump:
	bne $t2, PURPLE, skipR1Win
	jal win
skipR1Win:
	beq $t2, PLATFORMCOLOR, return
	beq $t2, BORDERCOLOR, return
	beq $t2, ENEMYTOPCOLOR, return
	beq $t2, BULLETCOLOR, takeDamage
	la $t1, hitbox
	lw $t3, 20($t1)
	addi $t3, $t3, SPEED # Check right of middle right
	lw $t3, 0($t3)
	bne $t3, HEALTHCOLOR, skipR2heal
	jal heal
skipR2heal:
	bne $t3, DBLJUMPCOLOR, skipR2jump
	jal doubleJump
skipR2jump:
	bne $t3, PURPLE, skipR2Win
	jal win
skipR2Win:
	beq $t3, PLATFORMCOLOR, return
	beq $t3, ENEMYTOPCOLOR, return
	beq $t3, BULLETCOLOR, takeDamage
	la $t1, hitbox
	lw $t4, 32($t1)
	addi $t4, $t4, SPEED # Check right of bottom right
	lw $t4, 0($t4)
	bne $t4, HEALTHCOLOR, skipR3heal
	jal heal
skipR3heal:
	bne $t4, DBLJUMPCOLOR, skipR3jump
	jal doubleJump
skipR3jump:
	bne $t4, PURPLE, skipR3Win
	jal win
skipR3Win:
	beq $t4, PLATFORMCOLOR, return
	beq $t4, ENEMYTOPCOLOR, return
	beq $t4, BULLETCOLOR, takeDamage
	li $a0, 4

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
jumpCheck: # Checks if character can jump
	
	beq $s2, 0, skipExtraJump # Double Jump not obtained
	beq $s3, 0, skipExtraJump # no jumps remaining
	beq $s3, 1, startJump # One jump left
skipExtraJump:
	beq $s3, 0, return
	la $t1, hitbox
	lw $t2, 24($t1)
	lw $t3, 28($t1)
	lw $t4, 32($t1)	

	addi $t2, $t2, 256 # Check bottom of bottom left
	lw $t2, 0($t2)
	beq $t2, PLATFORMCOLOR, startJump
	beq $t2, ENEMYTOPCOLOR, startJump
	
	addi $t3, $t3, 256 # Check bottom of bottom middle
	lw $t3, 0($t3)
	beq $t3, PLATFORMCOLOR, startJump
	beq $t3, ENEMYTOPCOLOR, startJump
	
	addi $t4, $t4, 256 # Check bottom of bottom right
	lw $t4, 0($t4)
	beq $t4, PLATFORMCOLOR, startJump
	beq $t4, ENEMYTOPCOLOR, startJump
	jr $ra
startJump: # Deducts a jump from $s3 and initiates jump
	addi $s3, $s3, -1
	li $s7, JUMP
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal changeColor
	lw $ra, 0($sp)
	addi $sp, $sp, 4
jump: # Jump for JUMP iterations
	addi $sp, $sp, -4
	sw $s7, 0($sp)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal moveUp
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	lw $s7, 0($sp)
	addi $sp, $sp, 4
	addi $s7, $s7, -1
	bge $s7, $zero, jump
	jr $ra

moveUp: # Move up one pixel to jump
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $t1, hitbox
	lw $t2, 0($t1)		

	addi $t2, $t2, -256 # Check up of top left
	lw $t2, 0($t2)
	beq $t2, BULLETCOLOR, takeDamage
	beq $t2, PLATFORMCOLOR, restoreStackAndReturn
	beq $t2, BORDERCOLOR, restoreStackAndReturn
	beq $t2, ENEMYTOPCOLOR, restoreStackAndReturn
	bne $t2, HEALTHCOLOR, skipU1Heal
	jal heal
skipU1Heal:
	bne $t2, DBLJUMPCOLOR, skipU1Jump
	jal doubleJump
skipU1Jump:
	bne $t2, PURPLE, skipU1Win
	jal win
skipU1Win:
	la $t1, hitbox
	lw $t3, 4($t1)
	addi $t3, $t3, -256 # Check up of top middle
	lw $t3, 0($t3)
	beq $t3, BULLETCOLOR, takeDamage
	beq $t3, PLATFORMCOLOR, restoreStackAndReturn
	beq $t3, BORDERCOLOR, restoreStackAndReturn
	beq $t3, ENEMYTOPCOLOR, restoreStackAndReturn
	bne $t3, HEALTHCOLOR, skipU2Heal
	jal heal
skipU2Heal:
	bne $t3, DBLJUMPCOLOR, skipU2Jump
	jal doubleJump
skipU2Jump:
	bne $t3, PURPLE, skipU2Win
	jal win
skipU2Win:
	la $t1, hitbox
	lw $t4, 8($t1)
	addi $t4, $t4, -256 # Check up of top right
	lw $t4, 0($t4)
	beq $t4, BULLETCOLOR, takeDamage
	beq $t4, PLATFORMCOLOR, restoreStackAndReturn
	beq $t4, BORDERCOLOR, restoreStackAndReturn
	beq $t4, ENEMYTOPCOLOR, restoreStackAndReturn
	bne $t4, HEALTHCOLOR, skipU3Heal
	jal heal
skipU3Heal:
	bne $t4, DBLJUMPCOLOR, skipU3Jump
	jal doubleJump
skipU3Jump:
	bne $t4, PURPLE, skipU3Win
	jal win
skipU3Win:
	li $a0, -256
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
	beq $s1, 1, playerNotDamaged
	jr $ra
playerNotDamaged:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $s1, 0 # Unless changed, player has fallen off and died
	la $t1, hitbox
	lw $t2, 24($t1)
	
	sub $t6, $t2, $t0
	li $t5, 13568
	bge $t6, $t5, return # Checks if player has fallen off
	
	li $s1, 1 # Player has not fallen off
	addi $t2, $t2, 256 # Check bottom of bottom left
	lw $t2, 0($t2)
	beq $t2, BULLETCOLOR, takeDamage
	beq $t2, PLATFORMCOLOR, land
	beq $t2, ENEMYTOPCOLOR, land
	bne $t2, HEALTHCOLOR, skipD1Heal
	jal heal
skipD1Heal:
	bne $t2, DBLJUMPCOLOR, skipD1Jump
	jal doubleJump
skipD1Jump:
	bne $t2, PURPLE, skipD1Win
	jal win
skipD1Win:
	la $t1, hitbox
	lw $t3, 28($t1)
	addi $t3, $t3, 256 # Check bottom of bottom middle
	lw $t3, 0($t3)
	beq $t3, BULLETCOLOR, takeDamage
	beq $t3, PLATFORMCOLOR, land
	beq $t3, ENEMYTOPCOLOR, land
	bne $t3, HEALTHCOLOR, skipD2Heal
	jal heal
skipD2Heal:
	bne $t3, DBLJUMPCOLOR, skipD2Jump
	jal doubleJump
skipD2Jump:
	bne $t3, PURPLE, skipD2Win
	jal win
skipD2Win:
	la $t1, hitbox
	lw $t4, 32($t1)	
	addi $t4, $t4, 256 # Check bottom of bottom right
	lw $t4, 0($t4)
	beq $t4, BULLETCOLOR, takeDamage
	beq $t4, PLATFORMCOLOR, land
	beq $t4, ENEMYTOPCOLOR, land
	bne $t4, HEALTHCOLOR, skipD3Heal
	jal heal
skipD3Heal:
	bne $t4, DBLJUMPCOLOR, skipD3Jump
	jal doubleJump
skipD3Jump:
	bne $t4, PURPLE, skipD3Win
	jal win
skipD3Win:
	
	# Player has nothing under it. So it keeps falling
	li $a0, 256
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
land: # Player lands on a legal surface (Platforms)
	li $s3, 1
	beq $s2, 1, chargeExtraJump # Double Jump has been picked
	j changeColor
chargeExtraJump: # Player can jump twice once it lands on a platform
	li $s3, 2
	j changeColor
updateChar: # Updates position of character. $a0=change in position
	la $t1, hitbox
	li $t2, 0
	move $t3, $a0
	li $t6, 32 #Limit (Included)
storeColor: # Store color of each hitbox in Stack to set later
	add $t4, $t1, $t2 # $t4 = addr(hitbox) + i
	lw $t5, 0($t4) # $t5 = current address
	lw $t8, 0($t5) # color at current address
	addi $sp, $sp, -4
	sw $t8, 0($sp) # Save color to stack
	
	addi $t2, $t2, 4 # $t2 iterates hitbox array
	
	ble $t2, $t6, storeColor
	li $t2, 32
moveLoop: # Moves each hitbox address by value in $t3
	add $t4, $t1, $t2 # $t4 = addr(hitbox) + i
	lw $t5, 0($t4) # $t5 = current address
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
	beq $t5, DBLJUMPCOLOR, bulletHit
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
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $s6, hitbox
	
	# Set top hitbox
	li $t1, CHARX
	addi $a0, $t1, -1
	li $t1, CHARY
	addi $a1, $t1, -1
	li $t1, 0
	jal setHitbox 
	
	# Set middle hitbox
	addi $s6, $s6, 12
	li $t1, CHARX
	addi $a0, $t1, -1
	li $t1, CHARY
	addi $a1, $t1, 0
	li $t1, 0
	jal setHitbox 
	
	# Set bottom hitbox
	addi $s6, $s6, 12
	li $t1, CHARX
	addi $a0, $t1, -1
	li $t1, CHARY
	addi $a1, $t1, 1
	li $t1, 0
	jal setHitbox 
	

	# Create center
	li $a0, CHARX
	li $a1, CHARY
	li $a2, CENTERCOLOR
	
	jal drawPixel
	
	li $a0, CHARX
	li $t1, CHARY
	addi $a1, $t1, 1
	li $a2, 0
	
	jal drawPixel
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

setHitbox: # Saves next three horizontal addresses in hitbox. $a0=x, $a1=y, $s6=hitbox, $t1=0
	li $t2,8  # Include when t1=0,4 or 8; cannot increment further
	li $t0, BASE_ADDRESS
	
	mul $t5, $a1, RESOLUTION
	add $t5, $t5, $a0
	mul $t5, $t5, 4 
	add $t5, $t5, $t0 # $t5 stores address of pixel in display
	
	add $t3, $s6, $t1 # $t3 = addr(hitbox) + i
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
addLives:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $t1, 2
	beq $s0, $t1, addSecondLife
	li $t1, 1
	beq $s0, $t1, addFirstLife
addThirdLife:	
	li $a0, 42
	li $a1, 59
	li $a2, RED
	jal drawPickup
addSecondLife:	
	li $a0, 50
	li $a1, 59
	li $a2, RED
	jal drawPickup

addFirstLife:
	li $a0, 58
	li $a1, 59
	li $a2, RED
	jal drawPickup
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
drawPickup: # Draws a health token given center coordinates. $a0 = x, $a1 = y, $a2 = color
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	move $t7, $a0
	move $t8, $a1
	move $t9, $a2
	addi $a0, $t7, -2
	li $a3, 5
	jal drawLineX
	
	move $a0, $t7
	addi $a1, $t8, -2
	move $a2, $t9
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
doubleJump: # Obtain double jump ability. Creates a jump visual. Removes pickup from display 
	addi $sp, $sp, -4 # Store $ra in stack
	sw $ra, 0($sp)
	
	li $s2, 1 # Indicates double jump ability obtained

	li $a0, DBLJUMPX
	li $a1, DBLJUMPY
	li $a2, 0
	jal drawPickup
	li $a0, DBLJUMPINDX
	li $a1, DBLJUMPINDY
	li $a2, DBLJUMPCOLOR
	jal drawPickup
	lw $ra, 0($sp) # load $ra 
	addi $sp, $sp, 4
	jr $ra
heal: # Obtain an extra life. Creates a life visual and increases life counter. Removes pickup from display
	addi $sp, $sp, -4 # Store $ra in stack
	sw $ra, 0($sp)
	
	addi $s0, $s0, 1
	jal addLives

	li $a0, HEALTHX
	li $a1, HEALTHY
	li $a2, 0
	jal drawPickup
	lw $ra, 0($sp) # load $ra 
	addi $sp, $sp, 4
	jr $ra
changeColor: # Changes color according to value in $s3
	la $a0, hitbox
	li $a1, 0
	li $a3, 36
	beq $s3, 2, jumpColor
	li $a2, CHARCOLOR # Set to default Color
	j setColor
jumpColor: # Set to Double Jump Color
	li $a2, DBLJUMPCOLOR
setColor: # Sets color of player. $a0=hitbox, $a1=0,$a2=new color,$a3=4*hitboxLen
	add $t4, $a0, $a1 # $t4 = addr(hitbox) + i
	lw $t5, 0($t4) # $t5 = current address
	beq $a1, 16, skipColor
	sw $a2, 0($t5) # set color at current address
skipColor:
	addi $a1, $a1, 4 # $a1 iterates hitbox array
	
	blt $a1, $a3, setColor
	jr $ra
	
takeDamage: # Player takes damage and loses a life
	li $s1, 0
restoreStackAndReturn: # Restores stack and returns
	lw $ra, 0($sp)
	addi $sp, $sp, 4
return:	#returns to prior PC
	jr $ra
drawWinItem:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $s1, ENDX
	li $s2, ENDY
	
	addi $a0, $s1, -2
	addi $a1, $s2, -2
	li $a2, PURPLE
	li $a3, 5
	jal drawLineX
	
	addi $a0, $s1, -2
	addi $a1, $s2, -2
	li $a2, PURPLE
	li $a3, 5
	jal drawLineY
	
	addi $a0, $s1, 2
	addi $a1, $s2, -2
	li $a2, PURPLE
	li $a3, 5
	jal drawLineY
	
	addi $a0, $s1, -2
	addi $a1, $s2, 2
	li $a2, PURPLE
	li $a3, 5
	jal drawLineX
	
	move $a0, $s1
	move $a1, $s2
	li $a2, PURPLE
	jal drawPixel
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
win:
	li $s4, 1
	jr $ra
winScreen:
	la $a0, BASE_ADDRESS
	li $a1, 4096
	li $a2, GREEN
	jal fill
	j end
restart:
	la $a0, BASE_ADDRESS
	li $a1, 4096
	li $a2, 0
	la $t1, Bullets
	sw $zero, 0($t1)
	sw $zero, 4($t1)
	jal fill
	j main
gameOver:
	li $s5, 1
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, BASE_ADDRESS
	li $a1, 4096
	beq $s4,1, gameWin
	li $a2, RED
	jal fill
	jal printYOU
	jal printLOSE
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	jr $ra
gameWin:
	li $a2, GREEN
	jal fill	
	jal printYOU
	jal printWIN
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
printYOU:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $a0, 10
	li $a1, 10
	li $a2, WHITE
	li $a3, 6
	jal drawLineY
	li $a0, 10
	li $a1, 16
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	li $a0, 20
	li $a1, 10
	li $a2, WHITE
	li $a3, 6
	jal drawLineY
	li $a0, 15
	li $a1, 16
	li $a2, WHITE
	li $a3, 10
	jal drawLineY
	
	li $a0, 25
	li $a1, 10
	li $a2, WHITE
	li $a3, 15
	jal drawLineY
	li $a0, 25
	li $a1, 10
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	li $a0, 25
	li $a1, 25
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	li $a0, 35
	li $a1, 10
	li $a2, WHITE
	li $a3, 15
	jal drawLineY
	
	li $a0, 40
	li $a1, 10
	li $a2, WHITE
	li $a3, 15
	jal drawLineY
	li $a0, 40
	li $a1, 25
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	li $a0, 50
	li $a1, 10
	li $a2, WHITE
	li $a3, 15
	jal drawLineY
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
printLOSE:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $a0, 5
	li $a1, 35
	li $a2, WHITE
	li $a3, 15
	jal drawLineY
	li $a0, 5
	li $a1, 50
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	
	li $a0, 20
	li $a1, 35
	li $a2, WHITE
	li $a3, 15
	jal drawLineY
	li $a0, 20
	li $a1, 35
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	li $a0, 20
	li $a1, 50
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	li $a0, 30
	li $a1, 35
	li $a2, WHITE
	li $a3, 15
	jal drawLineY
	
	li $a0, 35
	li $a1, 35
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	li $a0, 35
	li $a1, 35
	li $a2, WHITE
	li $a3, 8
	jal drawLineY
	li $a0, 35
	li $a1, 42
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	li $a0, 45
	li $a1, 42
	li $a2, WHITE
	li $a3, 8
	jal drawLineY
	li $a0, 35
	li $a1, 50
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	
	
	li $a0, 50
	li $a1, 35
	li $a2, WHITE
	li $a3, 15
	jal drawLineY
	li $a0, 50
	li $a1, 35
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	li $a0, 50
	li $a1, 42
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	li $a0, 50
	li $a1, 50
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
printWIN:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $a0, 10
	li $a1, 35
	li $a2, WHITE
	li $a3, 15
	jal drawLineY
	li $a0, 10
	li $a1, 50
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	li $a0, 15
	li $a1, 35
	li $a2, WHITE
	li $a3, 15
	jal drawLineY
	li $a0, 20
	li $a1, 35
	li $a2, WHITE
	li $a3, 15
	jal drawLineY
	
	li $a0, 25
	li $a1, 35
	li $a2, WHITE
	li $a3, 11
	jal drawLineX
	li $a0, 30
	li $a1, 35
	li $a2, WHITE
	li $a3, 15
	jal drawLineY
	li $a0, 25
	li $a1, 50
	li $a2, WHITE
	li $a3, 11
	jal drawLineX

	li $a0, 40
	li $a1, 35
	li $a2, WHITE
	li $a3, 16
	jal drawLineY
	li $a0, 49
	li $a1, 35
	li $a2, WHITE
	li $a3, 16
	jal drawLineY
	li $a0, 41
	li $a1, 35
	li $a2, WHITE
	li $a3, 2
	jal drawLineY
	li $a0, 42
	li $a1, 37
	li $a2, WHITE
	li $a3, 2
	jal drawLineY
	li $a0, 43
	li $a1, 39
	li $a2, WHITE
	li $a3, 2
	jal drawLineY
	li $a0, 44
	li $a1, 41
	li $a2, WHITE
	li $a3, 2
	jal drawLineY

	li $a0, 45
	li $a1, 43
	li $a2, WHITE
	li $a3, 2
	jal drawLineY
	li $a0, 46
	li $a1, 45
	li $a2, WHITE
	li $a3, 2
	jal drawLineY
	li $a0, 47
	li $a1, 47
	li $a2, WHITE
	li $a3, 2
	jal drawLineY
	li $a0, 48
	li $a1, 49
	li $a2, WHITE
	li $a3, 2
	jal drawLineY
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
fill: # Fills the display with pixels. $a0=BASE_ADDRESS, $a1=Number of pixels, $a2=color to be filled in
	sw $a2, 0($a0)
	addi $a0, $a0, 4 	# advance to next pixel position in display
	addi $a1, $a1, -1	# decrement number of pixels
	bnez $a1, fill	# repeat while number of pixels is not zero
	jr $ra
end: 	li $v0, 10                  # terminate the program gracefully
	syscall