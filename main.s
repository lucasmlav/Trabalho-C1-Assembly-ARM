/*
 * Trabalho C1 - Microprocessadores e Microcontroladores (2026/2)
 * Assembly ARMv7 - DE1-SoC / CPUlator
 *
 * Modos (SW1:SW0):
 *   00: maior elemento
 *   01: menor elemento
 *   10: soma dos elementos
 *   11: vetor ordenado, KEY0 avanca um elemento por pressionamento
 *
 * Saidas: HEX3..HEX0 = valor hexadecimal de 16 bits;
 *         LEDR9..LEDR0 = 10 bits menos significativos do valor.
 *
 * Nota: os valores do vetor de exemplo sao nao negativos e cabem
 * em 16 bits. A soma tambem cabe em 16 bits.
 */

    .syntax unified
    .arm

    .equ LEDR,       0xFF200000
    .equ HEX3_HEX0,  0xFF200020
    .equ SW,         0xFF200040
    .equ KEY,        0xFF200050
    .equ TAM_VETOR,  10

    .section .text
    .align 2
    .global _start

    _start:
    /* Pilha reservada neste programa; alinhamento de 8 bytes. */
    LDR     SP, =pilha_topo

    /* Ordena o vetor in-place antes de operar os quatro modos. */
    LDR     R0, =vetor
    MOV     R1, #TAM_VETOR
    BL      ordenar_bubble

    /* Calcula e guarda as tres estatisticas nos registradores. */
    LDR     R0, =vetor
    MOV     R1, #TAM_VETOR
    BL      calcular_maior
    MOV     R9, R0

    LDR     R0, =vetor
    MOV     R1, #TAM_VETOR
    BL      calcular_menor
    MOV     R10, R0

    LDR     R0, =vetor
    MOV     R1, #TAM_VETOR
    BL      calcular_soma
    MOV     R11, R0

    /* Registradores usados continuamente no loop principal. */
    MVN     R4, #0              @ modo anterior: -1 (invalido)
    LDR     R5, =SW
    LDR     R6, =KEY
    LDR     R7, =vetor
    MOV     R8, #0              @ indice do vetor ordenado

laco_principal:
    /* Ler apenas SW1 e SW0: quatro modos de exibicao. */
    LDR     R0, [R5]
    AND     R0, R0, #3

    /* Na entrada no modo 11, volta ao primeiro elemento. */
    CMP     R0, R4
    BEQ     verificar_key0
    MOV     R4, R0
    CMP     R0, #3
    MOVEQ   R8, #0

verificar_key0:
    /*
     * A tecla KEY0 vale 1 quando pressionada.
     * Um toque = transicao 0 -> 1; nao repete com tecla segurada.
     * Amostramos mesmo nos outros modos para manter o estado coerente.
     */
    LDR     R2, [R6]
    AND     R2, R2, #1
    LDR     R1, =estado_key0
    LDR     R3, [R1]            @ estado anterior
    STR     R2, [R1]            @ registra estado atual

    CMP     R0, #3
    BNE     escolher_modo
    CMP     R2, #1
    BNE     escolher_modo
    CMP     R3, #0
    BNE     escolher_modo

    ADD     R8, R8, #1          @ proximo elemento
    CMP     R8, #TAM_VETOR
    MOVEQ   R8, #0              @ apos o ultimo, reinicia

escolher_modo:
    CMP     R0, #0
    BEQ     mostrar_maior
    CMP     R0, #1
    BEQ     mostrar_menor
    CMP     R0, #2
    BEQ     mostrar_soma
    B       mostrar_ordenado

mostrar_maior:
    MOV     R0, R9
    BL      mostrar_valor
    B       laco_principal

mostrar_menor:
    MOV     R0, R10
    BL      mostrar_valor
    B       laco_principal

mostrar_soma:
    MOV     R0, R11
    BL      mostrar_valor
    B       laco_principal

mostrar_ordenado:
    LDR     R0, [R7, R8, LSL #2]
    BL      mostrar_valor
    B       laco_principal

    /* ----------------------------------------------------------------------
 * ordenar_bubble
 * Entrada: R0 = endereco do vetor (palavras de 32 bits), R1 = tamanho.
 * Saida: vetor ordenado em ordem crescente (in-place).
 * Altera: R2, R3, R12 e flags; R4-R8 alterados temporariamente.
 * Pilha: PUSH/POP de R4-R8 e LR (24 bytes, alinhados em 8).
 * Observacao: comparacao com sinal (BGT/STRGT); tamanho sem sinal.
 * ---------------------------------------------------------------------- */
ordenar_bubble:
    PUSH    {R4-R8, LR}
    MOV     R4, R0              @ base do vetor
    CMP     R1, #1
    BLS     fim_ordenacao       @ nao ha trabalho se tamanho <= 1
    SUB     R5, R1, #1          @ n-1
    MOV     R6, #0              @ indice externo i

inicio_passada:
    MOV     R7, #0              @ indice interno j
    SUB     R8, R5, R6          @ limite de comparacoes desta passada

comparar_par:
    LDR     R2, [R4, R7, LSL #2]
    ADD     R3, R7, #1
    LDR     R12, [R4, R3, LSL #2]
    CMP     R2, R12
    STRGT   R12, [R4, R7, LSL #2]
    STRGT   R2, [R4, R3, LSL #2]
    ADD     R7, R7, #1
    CMP     R7, R8
    BLO     comparar_par

    ADD     R6, R6, #1
    CMP     R6, R5
    BLO     inicio_passada

fim_ordenacao:
    POP     {R4-R8, PC}

/* ----------------------------------------------------------------------
 * calcular_maior
 * Entrada: R0 = endereco do vetor, R1 = quantidade de elementos.
 * Saida: R0 = maior inteiro com sinal (ou 0 se tamanho == 0).
 * Altera: R0-R3 e flags; nao altera registradores preservados.
 * Pilha: nao utiliza (sub-rotina folha; somente caller-saved).
 * ---------------------------------------------------------------------- */
calcular_maior:
    CMP     R1, #0
    MOVEQ   R0, #0
    BXEQ    LR
    LDR     R2, [R0], #4
    SUBS    R1, R1, #1
    BEQ     fim_maior

laco_maior:
    LDR     R3, [R0], #4
    CMP     R3, R2
    MOVGT   R2, R3
    SUBS    R1, R1, #1
    BNE     laco_maior

fim_maior:
    MOV     R0, R2
    BX      LR

/* ----------------------------------------------------------------------
 * calcular_menor
 * Entrada: R0 = endereco do vetor, R1 = quantidade de elementos.
 * Saida: R0 = menor inteiro com sinal (ou 0 se tamanho == 0).
 * Altera: R0-R3 e flags; nao altera registradores preservados.
 * Pilha: nao utiliza (sub-rotina folha; somente caller-saved).
 * ---------------------------------------------------------------------- */
calcular_menor:
    CMP     R1, #0
    MOVEQ   R0, #0
    BXEQ    LR
    LDR     R2, [R0], #4
    SUBS    R1, R1, #1
    BEQ     fim_menor

laco_menor:
    LDR     R3, [R0], #4
    CMP     R3, R2
    MOVLT   R2, R3
    SUBS    R1, R1, #1
    BNE     laco_menor

fim_menor:
    MOV     R0, R2
    BX      LR

/* ----------------------------------------------------------------------
 * calcular_soma
 * Entrada: R0 = endereco do vetor, R1 = quantidade de elementos.
 * Saida: R0 = soma dos valores modulo 2^32.
 * Altera: R0-R3 e flags; nao altera registradores preservados.
 * Pilha: nao utiliza (sub-rotina folha; somente caller-saved).
 * ---------------------------------------------------------------------- */
calcular_soma:
    MOV     R2, #0
    CMP     R1, #0
    BEQ     fim_soma

laco_soma:
    LDR     R3, [R0], #4
    ADD     R2, R2, R3
    SUBS    R1, R1, #1
    BNE     laco_soma

fim_soma:
    MOV     R0, R2
    BX      LR

    /* ----------------------------------------------------------------------
 * converter_7segmentos
 * Entrada: R0 = digito hexadecimal 0..15.
 * Saida: R0 = padrao dos segmentos gfedcba (bit 0 = segmento a).
 * Altera: R0, R1; nao altera registradores preservados.
 * Pilha: nao utiliza (sub-rotina folha; somente caller-saved).
 * A conversao depende da tabela de bytes na secao .data.
 * ---------------------------------------------------------------------- */
converter_7segmentos:
    LDR     R1, =tabela_7segmentos
    LDRB    R0, [R1, R0]
    BX      LR

    /* ----------------------------------------------------------------------
 * mostrar_valor
 * Entrada: R0 = valor de 32 bits a exibir.
 * Saida: escrita nos perifericos LEDR e HEX3..HEX0.
 *         HEX recebe os 16 bits menos significativos (4 digitos).
 *         LEDR recebe os 10 bits menos significativos.
 * Altera: R0-R3 e flags; R4-R8 e LR alterados temporariamente.
 * Pilha: PUSH/POP de R4-R8 e LR; preservacao de 8 bytes para BL.
 * Chama converter_7segmentos quatro vezes, uma para cada nibble.
 * ---------------------------------------------------------------------- */
mostrar_valor:
    PUSH    {R4-R8, LR}
    MOV     R8, R0              @ valor original, para os LEDs
    MOV     R4, R0              @ copia deslocada para obter os nibbles
    MOV     R5, #0              @ palavra codificada para os displays
    MOV     R6, #0              @ deslocamento em bits (0,8,16,24)
    MOV     R7, #4              @ quatro digitos

proximo_digito:
    AND     R0, R4, #15
    BL      converter_7segmentos
    ORR     R5, R5, R0, LSL R6
    LSR     R4, R4, #4
    ADD     R6, R6, #8
    SUBS    R7, R7, #1
    BNE     proximo_digito

    LDR     R0, =HEX3_HEX0
    STR     R5, [R0]
    LDR     R0, =LEDR
    STR     R8, [R0]            @ so LEDR9..LEDR0 sao usados pelo hardware
    POP     {R4-R8, PC}

    .ltorg

    .section .data
    .align 2
vetor:
    .word   18, 7, 42, 5, 31, 9, 20, 3, 40, 11
    /* Ordenado: 3, 5, 7, 9, 11, 18, 20, 31, 40, 42 */
    /* Maior = 42 (0x002A); menor = 3 (0x0003); soma = 186 (0x00BA). */

estado_key0:
    .word   0

/* Padroes 7 segmentos para 0,1,2,3,4,5,6,7,8,9,A,b,C,d,E,F. */
tabela_7segmentos:
    .byte   0x3F, 0x06, 0x5B, 0x4F
    .byte   0x66, 0x6D, 0x7D, 0x07
    .byte   0x7F, 0x6F, 0x77, 0x7C
    .byte   0x39, 0x5E, 0x79, 0x71

    .section .bss
    .balign 8
pilha_base:
    .space 1024
pilha_topo:
