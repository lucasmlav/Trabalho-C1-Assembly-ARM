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

