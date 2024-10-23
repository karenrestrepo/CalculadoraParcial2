section .data
    msg_bienvenida db 'Calculadora en Ensamblador', 0xA
    db 'Modo normal: num1 operador num2', 0xA
    db 'Modo RPN: num1 num2 operador', 0xA
    db 'Escriba "exit" para salir', 0xA
    len_bienvenida equ $ - msg_bienvenida
    
    msg_modo db 'Seleccione modo (1:Normal, 2:RPN): '
    len_modo equ $ - msg_modo
    
    msg_num1 db 'Ingrese primer numero: '
    len_msg_num1 equ $ - msg_num1
    
    msg_num2 db 'Ingrese segundo numero: '
    len_msg_num2 equ $ - msg_num2
    
    msg_op db 'Ingrese operacion (+,-,*,/,%): '
    len_msg_op equ $ - msg_op
    
    msg_resultado db 'Resultado: '
    len_msg_resultado equ $ - msg_resultado
    
    msg_error_div db 'Error: Division por cero!', 0xA
    len_error_div equ $ - msg_error_div
    
    msg_error_num db 'Error: Numero invalido!', 0xA
    len_error_num equ $ - msg_error_num
    
    exit_cmd db 'exit'
    newline db 0xA

section .bss
    num1 resb 1
    num2 resb 1
    resultado resb 1
    buffer resb 32
    modo resb 1
    num_str resb 12

section .text
    global_start

_start:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_bienvenida
    mov edx, len_bienvenida
    int 0x80

seleccionar_modo:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_modo
    mov edx, len_modo
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_modo
    mov edx, len_modo
    int 0x80

    mov al, [modo]
    sub al, '0'
    cmp al, 1
    je bucle_principal
    cmp al, 2
    je bucle_rpn
    jmp seleccionar_modo

bucle_principal:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_num1
    mov edx, len_msg_num1
    int 0x80

    call leer_numero
    cmp byte [buffer], 'e'  
    je salir
    mov [num1], eax

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_num2
    mov edx, len_msg_num2
    int 0x80

    call leer_numero
    mov [num2], eax

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_op
    mov edx, len_msg_op
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, buffer
    mov edx, 2
    int 0x80

    mov al, [buffer]
    call realizar_operacion
    jmp bucle_principal

bucle_rpn:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_num1
    mov edx, len_msg_num1
    int 0x80

    call leer_numero
    cmp byte [buffer], 'e'
    je salir
    mov [num1], eax

    mov eax, 4
    mov ebx, 1
    mov ecx, msg_num2
    mov edx, len_msg_num2
    int 0x80

    call leer_numero
    mov [num2], eax
    
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_op
    mov edx, len_msg_op
    int 0x80
    
    mov eax, 3
    mov ebx, 0
    mov ecx, buffer
    mov edx, 2
    int 0x80

    mov al, [buffer]
    call realizar_operacion
    jmp bucle_rpn

realizar_operacion:
    cmp al, '+'
    je suma
    cmp al, '-'
    je resta
    cmp al, '*'
    je multiplicacion
    cmp al, '/'
    je division
    cmp al, '%'
    je modulo
    ret

suma:
    mov eax, [num1]
    add eax, [num2]
    mov [resultado], eax
    jmp mostrar_resultado
    
resta:
    mov eax, [num1]
    sub eax, [num2]
    mov [resultado], eax
    jmp mostrar_resultado
    
multiplicacion:
    mov eax, [num1]
    imul dword [num2]
    mov [resultado], eax
    jmp mostrar_resultado
    
division:
    mov ebx, [num2]
    cmp ebx, 0
    je error_division
    
    mov eax, [num1]
    cdq
    idiv dword [num2]
    mov [resultado], eax
    jmp mostrar_resultado
    
modulo:
    mov ebx, [num2]
    cmp ebx, 0
    je error_division
    
    mov eax, [num1]
    cdq
    idiv dword [num2]
    mov [resultado], edx
    jmp mostrar_resultado

error_division:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_error_div
    mov edx, len_error_div
    int 0x80
    ret

mostrar_resultado:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_resultado
    mov edx, len_msg_resultado
    int 0x80
    
    mov eax, [resultado]
    call imprimir_numero
    
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    ret

leer_numero:
    push ebx
    push ecx
    push edx

    mov eax, 3
    mov ebx, 0
    mov ecx, buffer
    mov edx, 32
    int 0x80

    mov esi, buffer
    mov edi, exit_cmd
    mov ecx, 4
    cld
    repe cmpsb
    je salir

    mov esi, buffer
    xor eax, eax
    xor ebx, ebx

    mov cl, [esi]
    cmp cl, '-'
    jne conversion_numero
    inc esi
    mov bl, 1

conversion_numero:
    xor ecx, ecx
    mov cl, [esi]
    cmp cl, 0xA
    je fin_conversion
    cmp cl, '0'
    jl numero_invalido
    cmp cl, '9'
    jg numero_invalido
    
    sub cl, '0'
    imul eax, 10
    add eax, ecx
    inc esi
    jmp conversion_numero
    
fin_conversion:
    cmp bl, 1
    jne numero_valido
    neg eax 

numero_valido:
    pop edx
    pop ecx
    pop ebx
    ret
    
numero_invalido:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_error_num
    mov edx, len_error_num
    int 0x80
    xor eax, eax
    jmp numero_valido

imprimir_numero:
    push ebx
    push ecx
    push edx
    
    mov esi, num_str
    add esi, 11
    mov byte [esi], 0
    dec esi
    
    mov ebx, eax

    test eax, eax
    jns conversion_positiva
    neg eax

conversion_positiva:
    mov ecx, 10
    
ciclo_conversion:
    xor edx, edx
    div ecx
    add dl, '0'
    mov [esi], dl
    dec esi
    test eax, eax
    jnz ciclo_conversion

    test ebx, ebx
    jns imprimir_string
    mov byte [esi], '-'
    dec esi

imprimir_string:
    inc esi
    mov eax, 4
    mov ebx, 1
    mov ecx, esi
    mov edx, num_str
    add edx, 11
    sub edx, esi
    int 0x80
    
    pop edx
    pop ecx
    pop ebx
    ret

salir:
    mov eax, 1
    xor ebx, ebx
    int 0x80