# Plano de testes — CPUlator ARMv7 / DE1-SoC

## Preparação

1. Compile o `main.s`, inicie a simulação com e mantenha os dispositivos visíveis.
2. Verifique o vetor na janela **Memory**, próximo ao símbolo `vetor`, após retornar da primeira chamada `BL ordenar_bubble`.
3. Verifique **Registers** para conferir `R9 = 42 (0x2A)`, `R10 = 3 (0x3)` e `R11 = 186 (0xBA)` após as três funções de cálculo.
4. Execute os testes abaixo e anote *aprovado/reprovado* com captura de tela, se desejar.

## Casos funcionais

| ID | Ação no simulador | Resultado esperado |
|---|---|---|
| T01 | SW1=0, SW0=0 | HEX `002A`; LEDR `0000101010` (42) |
| T02 | SW1=0, SW0=1 | HEX `0003`; LEDR `0000000011` (3) |
| T03 | SW1=1, SW0=0 | HEX `00BA`; LEDR `0010111010` (186) |
| T04 | SW1=1, SW0=1; KEY0 solto | HEX `0003` (primeiro valor ordenado) |
| T05 | No modo 11, pressionar e soltar KEY0 uma vez | HEX `0005` (segundo valor) |
| T06 | No modo 11, segurar KEY0 sem soltar | Valor deve permanecer `0005` |
| T07 | Soltar e pressionar KEY0 novamente | HEX `0007` (terceiro valor) |
| T08 | Pressionar e soltar KEY0 até passar do último elemento | Após `002A`, a próxima pressão retorna a `0003` |
| T09 | Mudar do modo 11 para 00, depois retornar a 11 | Reinicia no primeiro elemento `0003` |
| T10 | Alterar SW2..SW9 mantendo SW1..SW0 | Não altera o modo selecionado |

### Sequência completa do modo 11

| Índice R8 | Decimal | HEX3–HEX0 |
|---:|---:|:---:|
| 0 | 3 | `0003` |
| 1 | 5 | `0005` |
| 2 | 7 | `0007` |
| 3 | 9 | `0009` |
| 4 | 11 | `000B` |
| 5 | 18 | `0012` |
| 6 | 20 | `0014` |
| 7 | 31 | `001F` |
| 8 | 40 | `0028` |
| 9 | 42 | `002A` |

## Inspeção de sub-rotinas, registradores e pilha

1. Pare/reinicie o programa para inspecionar novamente a ordenação. Posicione um breakpoint no rótulo `ordenar_bubble` e execute até ele.
2. Antes do `PUSH {R4-R8,LR}`, examine **SP** e os registradores R4–R8/LR.
3. Execute o `PUSH` passo a passo: **SP diminui 24 bytes**, armazenando seis registradores na pilha.
4. Avance dentro da ordenação para observar trocas de `.word` do vetor. O laço usa `LDR`, `CMP` e `STRGT`.
5. Execute até `POP {R4-R8,PC}`: **SP volta ao valor anterior** e os registradores preservados são recuperados.
6. Observe as chamadas `BL calcular_maior`, `BL calcular_menor` e `BL calcular_soma` e os retornos em R0.
7. Durante `mostrar_valor`, observe a chamada `BL converter_7segmentos`, o acesso `LDRB` à tabela e o `STR` no endereço `0xFF200020`.

## Critérios de aprovação

- Compilação no CPUlator sem erros de assembler.
- Os quatro modos apresentam os resultados previstos.
- KEY0 avança apenas com um novo pressionamento e reinicia ao ultrapassar o último elemento.
- O vetor fica ordenado em memória.
- A pilha e os registradores preservados são restaurados na saída das sub-rotinas.
- Não há avisos inesperados de acesso inválido à memória ou quebra das convenções de chamada.
