.data

filename: .asciiz "test.bf"
s_fopenerror: .asciiz "Error: Could not open file\n"
s_freaderror: .asciiz "Error: Could not read from file\n"

.text

main:
	# open file for reading
	li $v0, 13
	la $a0, filename
	li $a1, 0
	syscall
	
	bltz $v0, fopenerror
	
	move $s0, $v0		# s0: file handle
	move $s1, $sp		# s1: start of file text as reversed string (on stack)
	move $s2, $sp		# s2: end of file text as reversed string
									# s3: start of memory
									# s4: end of memory
	freadloop:
		bgt $s2, $sp, freadchar
		sub $sp, $sp, 8
		freadchar:
			# read a character from the file
			li $v0, 14
			move $a0, $s0	# file handle
			move $a1, $s2	# store at end of string
			li $a2, 1			# read 1 character
			syscall
			
			beqz $v0, freaddone
			bltz $v0, freaderror
			
			lb $t0, ($s2)
			beq $t0, '<', keepchar
			beq $t0, '>', keepchar
			beq $t0, '+', keepchar
			beq $t0, '-', keepchar
			beq $t0, '[', keepchar
			beq $t0, ']', keepchar
			beq $t0, '.', keepchar
			beq $t0, ',', keepchar
			b freadloop
			keepchar:
				sub $s2, $s2, 1
		b freadloop
	freaddone:
		bgt $s2, $sp, freadappendnull
		sub $sp, $sp, 8
		freadappendnull:
			sb $zero, -1($s2)
		
		# close the file
		li $v0, 16
		move $a0, $s0
		syscall
	
	jal allocmem	
	jal runprogram
	
	b exit

allocmem:
	move $s4, $sp
	sub $sp, $sp, 64 # change this line to change memory size
	move $s3, $sp
	jr $ra

runprogram:
	move $t0, $s1		# t0: program counter
	move $t2, $s3 	# t2: memory pointer
	programloop:
		lb $t1, ($t0)	# t1: current instruction
		beqz $t1, programfinish
		beq $t1, '+', i_inc
		beq $t1, '-', i_dec
		beq $t1, '<', i_left
		beq $t1, '>', i_right
		beq $t1, ',', i_read
		beq $t1, '.', i_write
		beq $t1, '[', i_start
		beq $t1, ']', i_end
		i_inc:
			lw $t3, ($t2)
			add $t3, $t3, 1
			sw $t3, ($t2)
			b programloopnext
		i_dec:
			lw $t3, ($t2)
			sub $t3, $t3, 1
			sw $t3, ($t2)
			b programloopnext
		i_left:
			sub $t2, $t2, 1
			bge $t2, $s3, programloopnext
			move $t2, $s4
			sub $t2, $t2, 1
			b programloopnext
		i_right:
			add $t2, $t2, 1
			blt $t2, $s4, programloopnext
			move $t2, $s3
			b programloopnext
		i_read:
			li $v0, 12
			syscall
			sb $v0, ($t2)
			b programloopnext
		i_write:
			li $v0, 11
			lb $a0, ($t2)
			syscall
			b programloopnext
		i_start:
			b programloopnext
		i_end:
			b programloopnext
		programloopnext:
			sub $t0, $t0, 1
			b programloop
	programfinish:
		jr $ra

printprogram:
	move $t0, $s1
	li $v0, 11
	printloop:
		lb $a0, ($t0)
		beqz $a0, printfinish
		syscall
		printnext:
			sub $t0, $t0, 1
			b printloop
			
	printfinish:
		li $a0, '\n'
		syscall
		jr $ra
	
exit:
	li $v0, 10 # exit
	syscall

error:
	li $v0, 4	# prints
	syscall
	li $v0, 17	# exit
	li $a0, 1
	syscall
	
fopenerror:
	la $a0, s_fopenerror
	b error

freaderror:
	la $a0, s_freaderror
	b error
