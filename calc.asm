section .data                                                 ; Inicializamos los datos
    msg_bienvenida db 'Calculadora en Ensamblador', 0xA       ; Mensajes para el uso de la calculadora seguido de salto de línea
    db 'Modo normal: num1 operador num2', 0xA
    db 'Modo RPN: num1 num2 operador', 0xA
    db 'Escriba "exit" para salir', 0xA
    len_bienvenida equ $ - msg_bienvenida                     ; Calcula la longitud del mensaje
    
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

section .bss                     ; Para datos no inicializados
    num1 resd 1                  ; Reserva 4 bytes para num1
    num2 resd 1                  ; Reserva 4 bytes para num2
    resultado resd 1             ; Reserva 4 bytes para el resultado
    buffer resb 32               ; Reserva un buffer de 32 bytes, es deci, para la entrada del usuario
    modo resb 1                  ; Reserva 1 byte para el modo de operacion
    num_str resb 12              ; Reserva 12 bytes para convertir números a string

section .text                    ; Se usa para el código ejecutable
    global _start

_start:                          ; Punto de entrada al programa
    mov eax, 4                   ; Llamada al sistema sys_write
    mov ebx, 1                   ; Descriptor de archivo (stdout)
    mov ecx, msg_bienvenida      ; Mensaje a mostrar
    mov edx, len_bienvenida      ; Longitud del mensaje
    int 0x80                     ; Interrupción para hacer la llamada al sistema

seleccionar_modo:
    ; Solicita el modo de operación
    mov eax, 4                   
    mov ebx, 1                   
    mov ecx, msg_modo
    mov edx, len_modo
    int 0x80

    ; Lee el modo
    mov eax, 3                   ; Llamada al sistema sys_read
    mov ebx, 0                   ; Descriptor de archivo stdin
    mov ecx, modo                ; Dirección del modo
    mov edx, 2                   ; Tamaño máximo a leer
    int 0x80                     ; Interrupción para hacer la llamada al sistema

    ; Verifica que sea un modo válido
    mov al, [modo]               ; lee el modo seleccionado
    sub al, '0'                  ; Convierte ASCII a número
    cmp al, 1                    ; ¿Seleccionó el modo normal?
    je bucle_principal           ; Si es modo normal, salta a bucle_principal
    cmp al, 2                    ; ¿Seleccionó el modo RPN?
    je bucle_rpn                 ; Si es modo RPN, salta a bucle_rpn
    jmp seleccionar_modo         ; Si no es ninguno, se debe volver a seleccionar el modo

bucle_principal:
    ; Solicita el primer número a operar
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_num1            ; Mensaje para el primer número
    mov edx, len_msg_num1
    int 0x80

    ; Lee ese primer número
    call leer_numero             ; Lee y convierte el número
    cmp byte [buffer], 'e'       ; ¿Escribieron "Exit"?
    je salir                     ; Si escribieron exit, termina el programa
    mov [num1], eax              ; Almacena el número leido en num1

    ; Solicita el segundo número a operar
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_num2
    mov edx, len_msg_num2
    int 0x80

    ; Lee ese segundo número
    call leer_numero
    mov [num2], eax

    ; Solicitud para la operación
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_op
    mov edx, len_msg_op
    int 0x80

    ; Lee la operación
    mov eax, 3
    mov ebx, 0
    mov ecx, buffer
    mov edx, 2
    int 0x80

    ; Realiza la operación
    mov al, [buffer]
    call realizar_operacion
    jmp bucle_principal

bucle_rpn:
    ; En modo RPN, en este modo primero leemos los dos números y luego el operador
    ; En RPN: "5 3 +" es equivalente a "5 + 3" en notación normal
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
    ;  Compara el operador ingresado con cada posibilidad y salta a la operación
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
    mov eax, [num1]                ; Carga num1 en eax
    add eax, [num2]                ; Suma num2 a eax
    mov [resultado], eax           ; Almacena el resultado en resultado, valga la redundancia 
    jmp mostrar_resultado          ; Salta a mostrar_resultado
    
resta:
    mov eax, [num1]
    sub eax, [num2]                ; Resta num2 a eax
    mov [resultado], eax
    jmp mostrar_resultado

multiplicacion:
    mov eax, [num1]
    imul dword [num2]              ; Multiplicación con signo
    mov [resultado], eax
    jmp mostrar_resultado
    
division:
    mov ebx, [num2]                ; Carga el divisor
    cmp ebx, 0                     ; ¿Es división por cero?
    je error_division              ; Salta a error_division
    
    mov eax, [num1]                ; Carga el dividendo
    cdq                            ; Extiende el signo de eax a edx
    idiv dword [num2]              ; Hace la división con el signo
    mov [resultado], eax
    jmp mostrar_resultado
    
modulo:
    mov ebx, [num2]
    cmp ebx, 0
    je error_division-
    
    mov eax, [num1]
    cdq
    idiv dword [num2]
    mov [resultado], edx           ; Guarda el residuo (no el cociente) en resultado
    jmp mostrar_resultado

error_division:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_error_div         ; Mensaje de error de división por cero
    mov edx, len_error_div
    int 0x80
    ret                            ; Retorno

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

leer_numero:                       ; Función para leer número y convertirlo de String a número  
    push ebx
    push ecx
    push edx

    ; Lee la entrada
    mov eax, 3
    mov ebx, 0
    mov ecx, buffer
    mov edx, 32
    int 0x80

    mov esi, buffer                ; Carga la dirección del buffer de entrada en esi
    mov edi, exit_cmd              ; Carga la dirección de "exit" en edi
    mov ecx, 4                     ; Longitud del exit
    cld                            ; Clear Direction Flag - compara de izquierda a derecha
    repe cmpsb                     ; Compara strings, byte por byte mientras sean iguales
    je salir                       ; Si son iguales, salta a salir

    ; Realiza la conversión de String a número
    mov esi, buffer                ; Apunta al inicio del buffer de entrada
    xor eax, eax                   ; Limpia eax (será el resultado final)
    xor ebx, ebx                   ; Limpia ebx (se usará para el signo: 0=positivo, 1=negativo)

    ; Verifica el signo
    mov cl, [esi]                  ; Obtiene el primer carácter
    cmp cl, '-'                    ; ¿Es un signo menos?
    jne conversion_numero          ; Si no es menos, empieza la conversión
    inc esi                        ; Si es menos, avanza al siguiente carácter
    mov bl, 1                      ; Marca que el número es negativo

conversion_numero:
    xor ecx, ecx                   ; Limpia a ecx
    mov cl, [esi]                  ; Obtiene un carácter
    cmp cl, 0xA                    ; ¿Es una nueva línea?
    je fin_conversion              ; Si es una nueva línea, salta a fin_conversion
    cmp cl, '0'                    ; ¿Es menor que cero?
    jl numero_invalido             ; Si es menor que cero, salta a numero_invalido
    cmp cl, '9'                    ; ¿Es mayor que 9?
    jg numero_invalido             ; Si es mayor que nueve, salta a numero_invalido
    
    sub cl, '0'                    ; Convierte ASCII a valor numérico
    imul eax, 10                   ; Multiplica el resultado actual por 10
    add eax, ecx                   ; Le suma el nuevo dígito
    inc esi                        ; Avanza al siguiente carácter
    jmp conversion_numero          ; Salta a conversion_numero
    
fin_conversion:
    cmp bl, 1                      ; ¿El número es negativo?
    jne numero_valido              ; Si no es negativo, termina
    neg eax                        ; Si es negativo, cambia el signo

numero_valido:
    ; Recupera los valores originales desde la pila
    pop edx
    pop ecx
    pop ebx
    ret                            ; Retorna al punto de llamada de la función
    
numero_invalido:
    mov eax, 4
    mov ebx, 1
    mov ecx, msg_error_num         ; Mensaje de error por número inválido
    mov edx, len_error_num
    int 0x80
    xor eax, eax                   ; Retorna 0 como valor
    jmp numero_valido

imprimir_numero:                   ; Función para convertir número a String e imprimir
    ;Guarda los registros en la pila
    push ebx
    push ecx
    push edx
    
    mov esi, num_str               ; Apunta al buffer de string
    add esi, 11                    ; Va al final del buffer
    mov byte [esi], 0              ; Agrega terminador nulo
    dec esi
    
    mov ebx, eax                   ; Guarda el número original

    ; Verifica si es negativo
    test eax, eax
    jns conversion_positiva
    neg eax                        ; Convierte el número a positivo para procesar

conversion_positiva:
    mov ecx, 10                    ; Divisor
    
ciclo_conversion:
    xor edx, edx                   ; Limpia a edx para la división
    div ecx                        ; Divide entre 10
    add dl, '0'                    ; Convierte el residuo a ASCII
    mov [esi], dl                  ; Guarda el dígito
    dec esi                        ; Retrocede en buffer
    test eax, eax                  ; Verifica si quedan más dígitos
    jnz ciclo_conversion

    ; Si era negativo, agregar signo
    test ebx, ebx                  ; ¿El número es negativo?
    jns imprimir_string            ; Si no es negativo, salta a imprimir_string
    mov byte [esi], '-'            ; Si es negativo, coloca el signo menos
    dec esi                        ; Retrocede para incluir el signo

imprimir_string:
    inc esi                        ; Mueve el puntero de inicio hacia adelante
    mov eax, 4
    mov ebx, 1
    mov ecx, esi                   ; Dirección del String a imprimir
    mov edx, num_str               ; Dirección del buffer completo
    add edx, 11                    ; Va al final del buffer
    sub edx, esi                   ; Calcula la longitud (fin - inicio)
    int 0x80
    
    pop edx
    pop ecx
    pop ebx
    ret

salir:
    mov eax, 1          ; Número de llamada del sistema para sys_exit (1)
    xor ebx, ebx        ; Código de salida (0)
    int 0x80            ; Interrupción para salir