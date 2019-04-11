.data
mensaje: .asciiz "Introduzca una operacion:\n> "
prompt: .asciiz "= "
new_line: .asciiz "\n"
error: .asciiz "Error. "
buffer: .byte 64
.text
.globl main
main:
loop:
     la $a0, mensaje
     li $v0, 4
     syscall
     la $a0, buffer
     li $v0, 8
     syscall
     move $a3, $zero # contador de parentesis
     jal parse
     bne $v1, $zero, p_error
     move $t0, $v0
     la $a0, prompt
     li $v0, 4
     syscall
     move $a0, $t0
     li $v0, 1
     syscall
     la $a0, new_line
     li $v0, 4
     syscall
     j loop
p_error:
     la $a0, error
     li $v0, 4
     syscall
     j loop

parse:
    sub $sp, $sp, 4
    sw $ra, ($sp)
    jal parse_add_sub
    lw $ra, ($sp)
    add $sp, $sp, 4
    beqz $a3, continue
continue:
    lb $t0, ($a0)
    bne $t0, 41, char_not_paren
    move $v0, $zero
    li $v1, 1 # error parentesis
    j return_parse
char_not_paren:
    beq $t0, $zero, return_parse
    beq $t0, 10, return_parse
    move $v0, $zero
    li $v1, 2 # char incorrecto
return_parse:
    jr $ra

# $a0 puntero
# $v0 valor int
parse_char:
char_space:
    lb $t0, ($a0)
    bne $t0, 32, end_char_space
    addi $a0, $a0, 1
    j char_space
end_char_space:
    move $t1, $zero # flag signo menos false
    bne $t0, 45, char_not_sub
    li $t1, 1 # flag signo menos true
    addi $a0, $a0, 1 # siguiente char
    lb $t0, ($a0) # cargamos siguiente char
char_not_sub:
    bne $t0, 43, char_not_add # signo mas ?
    addi $a0, $a0, 1 # siguiente char
    lb $t0, ($a0) # cargamos siguiente char
char_not_add:
    bne $t0, 40, char_not_o_paren
    addi $a0, $a0, 1 # siguiente char
    # contador parentesis++ global
    addi $a3, $a3, 1
    sub $sp, $sp, 8
    sw $t1, 4($sp)
    sw $ra, ($sp)
    jal parse_add_sub # funcion
    lw $ra, ($sp)
    lw $t1, 4($sp)
    addi $sp, $sp, 8
    lb $t0, ($a0) # siguiente char
    beq $t0, 41, char_c_paren
    move $v0, $zero # valor a devolver
    li $v1, 1 # error parentesis
    j  return_char
char_c_paren:
    addi $a0, $a0, 1 # siguiente char
    # contador parentesis-- global
    sub $a3, $a3, 1
check_sign:
    beq $t1, $zero, char_sign_false
    sub $v0, $zero, $v0
    move $v1, $zero # no error
char_sign_false:
    j return_char
char_not_o_paren:
    sub $sp, $sp, 8
    sw $t1, 4($sp)
    sw $ra, ($sp)
    jal convert_to_int # funcion
    lw $ra, ($sp)
    lw $t1, 4($sp)
    addi $sp, $sp, 8
    bne $a0, $a1, not_wrong_char
    move $v0, $zero
    li $v1, 2 # char no valido
    j  return_char
not_wrong_char:
    move $a0, $a1 #cambiamos de posicion
    j check_sign
return_char:
    jr $ra

# $a0 puntero a cadena
# $a1 puntero a ultimo caracter procesado
convert_to_int:
    move $a1, $a0
    li $t0, 10 # constante multiplicativa
    move $t3, $zero
    move $t2, $zero # inizializar res
    lb $t1, ($a1)
    bne $t1, 45, not_negative
    li $t3, 1
    addi $a1, $a1, 1
not_negative:
    bne $t1, 43, loop_to_int
    addi $a1, $a1, 1
loop_to_int:
    lb $t1, ($a1)
    blt $t1, 48, return_to_int
    bgt $t1, 57, return_to_int
    addi $t1, $t1, -48 # ascii to int
    mul $t2, $t2, $t0  # base 10
    add $t2, $t2, $t1
    addi $a1, $a1, 1
    j loop_to_int
return_to_int:
    beq $t3, $zero, not_signed
    sub $t2, $zero, $t2
not_signed:
    move $v0, $t2
    jr $ra

### parse_add_sub
parse_add_sub:
    sub $sp, $sp, 4
    sw $ra, ($sp)
    jal parse_mul_div # funcion
    move $t0, $v0
    lw $ra, ($sp)
    addi $sp, $sp, 4
loop_add_sub:
char_space_add_sub:
    lb $t1, ($a0)
    bne $t1, 32, end_char_space_add_sub
    addi $a0, $a0, 1
    j char_space_add_sub
end_char_space_add_sub:
    beq $t1, 45, char_eq_add_or_sub
    beq $t1, 43, char_eq_add_or_sub
    move $v0, $t0
    li $v1, 0 # sin errores
    j return_add_sub
char_eq_add_or_sub:
    addi $a0, $a0, 1
    sub $sp, $sp, 12
    sw $t1, 8($sp)
    sw $t0, 4($sp)
    sw $ra, ($sp)
    jal parse_mul_div # funcion
    move $t2, $v0
    lw $ra, ($sp)
    lw $t0, 4($sp)
    lw $t1, 8($sp)
    addi $sp, $sp, 12
    bne $t1, 45, char_not_eq_minus
    sub $t0, $t0, $t2
    j loop_add_sub
char_not_eq_minus:
    add $t0, $t0, $t2
    j loop_add_sub
return_add_sub:
    jr $ra

parse_mul_div:
    sub $sp, $sp, 4
    sw $ra, ($sp)
    jal parse_char # funcion
    move $t0, $v0
    lw $ra, ($sp)
    addi $sp, $sp, 4
loop_mul_div:
char_space_mul_div:
    lb $t1, ($a0)
    bne $t1, 32, end_char_space_mul_div
    addi $a0, $a0, 1
    j char_space_mul_div
end_char_space_mul_div:
    beq $t1, 47, char_eq_mul_or_div
    beq $t1, 42, char_eq_mul_or_div
    move $v0, $t0
    li $v1, 0 # sin errores
    j return_mul_div
char_eq_mul_or_div:
    addi $a0, $a0, 1
    sub $sp, $sp, 12
    sw $t1, 8($sp)
    sw $t0, 4($sp)
    sw $ra, ($sp)
    jal parse_char # funcion
    move $t2, $v0
    lw $ra, ($sp)
    lw $t0, 4($sp)
    lw $t1, 8($sp)
    addi $sp, $sp, 12
    bne $t1, 47, char_not_eq_div
    beq $t2, $zero zero_div
    div $t0, $t0, $t2 # num1 /= num2
    j loop_mul_div
char_not_eq_div:
    mul $t0, $t0, $t2 # num1 *= num2
    j loop_mul_div
zero_div:
    li $v0, 0
    li $v1, 3 # error division zero
return_mul_div:
    jr $ra
