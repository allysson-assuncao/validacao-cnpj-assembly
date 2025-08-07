.data
	vetorCNPJ: .space 15
	mensInicial: .asciiz "====================Bem vindo ao novo programa de validação de CNPJ====================\n\n\n"
	mensEntradaCNPJ: .asciiz "Digite o CNPJ completo (14 dígitos, sem espaços ou caracteres especiais) para validação:\n"
	mensCNPJInvalido: .asciiz "O CNPJ Informado é inválido!\n"
	mensProximaTentativa: .asciiz "Tente Novamente...\n\n"
	mensCNPJValido: .asciiz "O CNPJ Informado é válido!\n"
	mensFim: .asciiz "\nEncerrando o programa, obrigado pela preferência.\n"

.text
main:
	# Exibir mensagem de boas-vindas
	li $v0, 4
	la $a0, mensInicial
	syscall

	# Inicia o contador de tentativas
	li $s0, 0  # $s0 será nosso contador de tentativas (0, 1, 2)
	li $s1, 3  # $s1 é o número máximo de tentativas

loopTentativas:
	# Verifica se o número de tentativas excedeu o limite
	bge $s0, $s1, fim

	# Incrementa o contador de tentativas para a rodada atual
	addi $s0, $s0, 1

	# Exibir mensagem para entrada do CNPJ
	li $v0, 4
	la $a0, mensEntradaCNPJ
	syscall

	# Recebe a entrada do usuário (string do CNPJ)
	li $v0, 8
	la $a0, vetorCNPJ
	li $a1, 15        # Limite de 14 caracteres + terminador nulo
	syscall

	# Chama a sub-rotina para validar o primeiro dígito.
	# A sub-rotina retornará 1 em $v0 se for válido, e 0 se for inválido.
	jal calculaPrimeiroDigito

	# Se o retorno ($v0) for 0, o primeiro dígito é inválido. Pula para a mensagem de erro.
	beq $v0, $zero, cnpjInvalido

	# Se o primeiro dígito foi válido, chama a sub-rotina para validar o segundo.
	# A lógica é a mesma: retorna 1 para sucesso, 0 para falha.
	jal calculaSegundoDigito

	# Se o retorno ($v0) for 0, o segundo dígito é inválido. Pula para a mensagem de erro.
	beq $v0, $zero, cnpjInvalido

	# Se ambas as validações passaram, o CNPJ é válido. Pula para a mensagem de sucesso.
	j sucesso

cnpjInvalido:
	# Exibe a mensagem de CNPJ inválido
	li $v0, 4
	la $a0, mensCNPJInvalido
	syscall

	# Exibe a mensagem para tentar novamente
	li $v0, 4
	la $a0, mensProximaTentativa
	syscall

	# Volta para o início do loop para uma nova tentativa
	j loopTentativas

# Sub-rotina que calcula o primeiro dígito verificador e o compara com o informado.
# "Retorna" 1 se for válido e 0 se for inválido.
calculaPrimeiroDigito:
	# Inicia registradores para o cálculo
	la $t0, vetorCNPJ       # $t0: endereço base do CNPJ
	li $t6, 5               # $t6: inicia o peso em 5
	li $t2, 0               # $t2: soma dos produtos (inicia com 0)
	li $t3, 0               # $t3: contador do loop (de 0 a 11)
	li $t4, 12              # $t4: limite do loop

loopSoma1:
	# Carrega o dígito e o peso da vez
	lb $t5, 0($t0)          # $t5 = dígito atual (como caractere ASCII)

	# Converte o dígito de ASCII para inteiro subtraindo 48
	subi $t5, $t5, 48

	# Multiplica dígito pelo peso
	mul $t7, $t5, $t6

	# Acumula o resultado na soma total
	add $t2, $t2, $t7
	
	# Lógica para atualizar o peso para a próxima iteração
	subi $t6, $t6, 1        # Decrementa o peso
	bne $t6, 1, peso1_ok    # Se o peso não chegou em 1, a lógica de atualização termina.
	li $t6, 9               # Se o peso chegou em 1 (agora é 1), reseta para 9.
	
peso1_ok:

	# Avança o ponteiro do CNPJ e o contador do loop
	addi $t0, $t0, 1
	addi $t3, $t3, 1

	# Continua o loop se o contador for menor que 12
	blt $t3, $t4, loopSoma1

	# Fim do loop, agora calcula o dígito verificador
	li $t5, 11
	div $t2, $t5            # Divide a soma por 11
	mfhi $t6                # $t6 = resto da divisão (soma % 11)

	# Se o resto for menor que 2, o dígito é 0.
	blt $t6, 2, dv1_eh_zero

	# Senão, o dígito é 11 - resto
	sub $t6, $t5, $t6       # $t6 = 11 - resto (dígito calculado)
	j comparaDV1

dv1_eh_zero:
	li $t6, 0               # $t6 = 0 (dígito calculado)

comparaDV1:
	# Carrega o 13º dígito do CNPJ (índice 12), que foi o informado pelo usuário
	la $t0, vetorCNPJ
	addi $t0, $t0, 12       # Aponta para o 13º caractere
	lb $t7, 0($t0)          # $t7 = 13º dígito (como caractere ASCII)
	subi $t7, $t7, 48       # Converte para inteiro

	# Compara o dígito calculado ($t6) com o dígito informado ($t7)
	bne $t6, $t7, falhaDV1  # Se forem diferentes, falhou

	# Sucesso: Retorna 1
	li $v0, 1
	jr $ra                  # Retorna para o ponto de onde foi chamado (jal)

falhaDV1:
	# Falha: Retorna 0
	li $v0, 0
	jr $ra                  # Retorna para o ponto de onde foi chamado (jal)

# Sub-rotina que calcula o segundo dígito verificador e o compara com o informado.
# A lógica é idêntica à da primeira, mas usa 13 dígitos e considera o peso adicional.
calculaSegundoDigito:
	# Inicia registradores para o cálculo
	la $t0, vetorCNPJ       # $t0: endereço base do CNPJ
	li $t6, 6               # $t6: INICIA o peso em 6
	li $t2, 0               # $t2: soma (inicia com 0)
	li $t3, 0               # $t3: contador do loop (de 0 a 12)
	li $t4, 13              # $t4: limite do loop

loopSoma2:
	# Carrega o dígito e o peso da vez
	lb $t5, 0($t0)

	# Converte o dígito de ASCII para inteiro
	subi $t5, $t5, 48

	# Multiplica e acumula na soma
	mul $t7, $t5, $t6
	add $t2, $t2, $t7

	# Lógica para atualizar o peso para a próxima iteração
	subi $t6, $t6, 1        # Decrementa o peso
	bne $t6, 1, peso2_ok    # Se o peso não chegou em 1, está ok.
	li $t6, 9               # Se chegou em 1, reseta para 9.
	
peso2_ok:

	# Avança ponteiros e contador
	addi $t0, $t0, 1
	addi $t3, $t3, 1

	# Continua o loop se o contador for menor que 13
	blt $t3, $t4, loopSoma2

	# Fim do loop, calcula o dígito verificador
	li $t5, 11
	div $t2, $t5            # Divide a soma por 11
	mfhi $t6                # $t6 = resto da divisão (soma % 11)

	# Se resto < 2, dígito é 0
	blt $t6, 2, dv2_eh_zero

	# Senão, dígito é 11 - resto
	sub $t6, $t5, $t6
	j comparaDV2

dv2_eh_zero:
	li $t6, 0

comparaDV2:
	# Carrega o 14º dígito do CNPJ (índice 13)
	la $t0, vetorCNPJ
	addi $t0, $t0, 13       # Aponta para o 14º caractere
	lb $t7, 0($t0)
	subi $t7, $t7, 48       # Converte para inteiro

	# Compara o dígito calculado ($t6) com o informado ($t7)
	bne $t6, $t7, falhaDV2

	# Sucesso: Retorna 1
	li $v0, 1
	jr $ra

falhaDV2:
	# Falha: Retorna 0
	li $v0, 0
	jr $ra

# Desfecho do Programa
sucesso:
	# Mensagem de sucesso em caso de CNPJ válido
	li $v0, 4
	la $a0, mensCNPJValido
	syscall
	j fim

fim:
	# Mensagem de fim da execução do programa
	li $v0, 4
	la $a0, mensFim
	syscall

	# Encerra o programa
	li $v0, 10
	syscall
