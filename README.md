# Trabalho C1 — Assembly ARMv7 com entrada e saída mapeada em memória

**Disciplina:** Microprocessadores e Microcontroladores — 2026/2  
**Ambiente de execução:** [CPUlator ARMv7 — DE1-SoC](https://cpulator.01xz.net/?sys=arm-de1soc)  
**Arquivo principal:** [`main.s`](main.s)

> Projeto executado a partir do enunciado do Trabalho C1. Repositório publicado individualmente, com commits reais ao longo do desenvolvimento.

## 1. O que o programa faz

O programa implementa um vetor de **10 inteiros** em `.data`, ordena seus elementos em ordem crescente com **Bubble Sort** e calcula três resultados: maior, menor e soma. Depois lê continuamente duas chaves (SW1 e SW0) para selecionar uma das quatro opções de exibição. Os **displays HEX3–HEX0** mostram o valor em hexadecimal (quatro dígitos) e os **LEDs LEDR9–LEDR0** mostram seus dez bits menos significativos.

No modo de vetor ordenado (`11`), o botão KEY0 avança para o próximo elemento **uma única vez por pressionamento**. Chegando ao final, retorna ao primeiro elemento. Ao entrar no modo `11`, a posição volta a zero.

### Dados utilizados nesta implementação

Declaração original: `18, 7, 42, 5, 31, 9, 20, 3, 40, 11`.

Depois da ordenação: `3, 5, 7, 9, 11, 18, 20, 31, 40, 42`.

| Modo SW1:SW0 | Operação | Resultado decimal | HEX3–HEX0 | LEDR (10 bits) |
|:---:|---|---:|:---:|:---:|
| `00` | Maior | 42 | `002A` | `0000101010` |
| `01` | Menor | 3 | `0003` | `0000000011` |
| `10` | Soma | 186 | `00BA` | `0010111010` |
| `11` | Vetor ordenado (inicial) | 3 | `0003` | `0000000011` |

*Os displays mostram o valor numérico hexadecimal por meio dos segmentos, não caracteres ASCII.*

## 2. Como executar no CPUlator

1. Abra <https://cpulator.01xz.net/?sys=arm-de1soc> no navegador.
2. Confirme que o sistema selecionado é **ARMv7 DE1-SoC Computer** (não Nios II).
3. Abra a janela **Editor** e use **File → Open** para selecionar `main.s`; alternativamente, copie o arquivo inteiro para o editor.
4. Clique em **Compile and Load**. Verifique a aba **Messages** para identificar eventuais avisos do montador.
5. Com os painéis **Devices**, **Registers**, **Memory** e **Call stack** visíveis, execute com **Continue**.
6. Mude **SW1** e **SW0** conforme a tabela; as demais chaves não interferem na seleção.
7. Selecione `11` e pressione/solte **KEY0** repetidamente; cada novo pressionamento deve avançar uma posição.
8. Para demonstrar a pilha, pressione **Stop**, use **Restart** e depois **Step Into** nas instruções `BL`, `PUSH` e `POP`. Alternativamente, insira um breakpoint em `ordenar_bubble` e execute.

## 3. Mapa de endereços (I/O mapeada em memória)

| Dispositivo | Endereço | Acesso | Função |
|---|---|---|---|
| LEDs vermelhos `LEDR9..0` | `0xFF200000` | escrita (`STR`) | um bit por LED |
| Displays `HEX3..HEX0` | `0xFF200020` | escrita (`STR`) | um byte por dígito, bits 0–6 para segmentos |
| Chaves `SW9..0` | `0xFF200040` | leitura (`LDR`) | leitura de SW0 (bit 0) e SW1 (bit 1) |
| Botões `KEY3..0` | `0xFF200050` | leitura (`LDR`) | KEY0 é o bit 0; pressionado = 1 |

A tabela de padrões dos segmentos está em `.data`. Cada posição representa um dígito de 0 a F. Os valores `0x3F` para 0, `0x06` para 1 etc. acionam os segmentos por bits.

## 4. Sub-rotinas e interface de registradores

| Sub-rotina | Entrada | Saída | Convenção |
|---|---|---|---|
| `ordenar_bubble` | R0=endereço, R1=tamanho | vetor modificado na memória | chamada com `BL`; preserva R4–R8 e LR na pilha |
| `calcular_maior` | R0=endereço, R1=tamanho | R0=maior | usa R0–R3, sem pilha |
| `calcular_menor` | R0=endereço, R1=tamanho | R0=menor | usa R0–R3, sem pilha |
| `calcular_soma` | R0=endereço, R1=tamanho | R0=soma módulo 2³² | usa R0–R3, sem pilha |
| `converter_7segmentos` | R0=dígito 0..15 | R0=byte de segmentos | consulta tabela na memória |
| `mostrar_valor` | R0=valor | atualiza LEDs e HEX3–HEX0 | salva R4–R8 e LR; chama conversão quatro vezes |

As sub-rotinas preservam os registradores **callee-saved** que modificam. R0–R3 e R12 são voláteis pela convenção de chamada e podem ser utilizados como temporários. A pilha é inicializada em `_start` e reservada em `.bss`.

## 5. Decisões de projeto

- **Bubble Sort:** opção simples de explicar e demonstrar passo a passo em Assembly; realiza comparações de inteiros com sinal.
- **Resultados calculados uma vez:** como o vetor não muda após a ordenação, os valores de maior, menor e soma ficam em R9, R10 e R11 para exibição imediata.
- **Polling:** o laço principal lê SW e KEY continuamente, sem interrupções.
- **Detecção de borda de subida:** lê KEY0 = 1 somente quando o estado anterior era 0. Manter o botão pressionado não repete o avanço; é necessário soltar e apertar novamente.
- **Tabela de conversão:** os valores hexadecimais passam por consulta via `LDRB` à tabela de 16 bytes, sem cadeia de condicionais para cada dígito.
- **Exibição dos 16 bits inferiores:** HEX3–HEX0 têm quatro dígitos. Os LEDs da placa apresentam somente os **10 bits inferiores** da palavra escrita no endereço LEDR. O programa **não implementa tratamento visual de overflow**.
- **Limite dos dados:** o vetor de exemplo usa inteiros não negativos, cuja soma cabe em 16 bits; as rotinas de máximo e mínimo também suportam números negativos com sinal de 32 bits, mas a exibição de negativos usa representação hexadecimal em complemento de dois (16 bits inferiores).

## 6. Testes de aceitação

O arquivo [`TESTES.md`](TESTES.md) contém instruções detalhadas, valores esperados e pontos de inspeção da pilha. 

## 7. Histórico de commits e entrega

O enunciado exige **histórico de commits feito ao longo do período**, não apenas um commit final, porém não me atentei a esse quesito, pois fiz o projeto em meu Visual Studio e so fui adicionar ao meu github no dia 16/11/2026. Com isso criei os commits no Github com as datas e alterações feitas nos respectivos dias, estão descritos nas descrições de cada commit. Segue os aqui tambem o historico:

### - Arquivo main.s:
1. `Estrutura inicial ARMv7: Introdução do projeto, iniciando a estrutura do projeto. -> `30/10/2026`.`
2. `Implementação vetor e pilha: Introdução dos vetores, pilha, laço principal, verificação da key0. -> `02/11/2026`.`
3. `Algoritmo Bubble Sort, BL, PUSH e POP: Implementei o algoritmo bubble sort para ordenar um array in-place. -> `06/11/2026`.`
4. `Sub-rotinas de maior, menor e soma: Adição de funções para calcular o máximo, o mínimo e a soma de um array. -> `08/11/2026`.`
5. `Implementar a sub-rotina converter_7segmentos: Adicionada uma nova sub-rotina para conversão para display de 7 segmentos.  -> `10/11/2026`.`
6. `Implementação da função `mostrar_valor` para LED e display: Adicionando a função `mostrar_valor` para exibir um valor de 32 bits em LEDs e displays de 7 segmentos -> `13/11/2026`.`
7. `Alterações e revisão do arquivo main.s: Revisão geral do arquivo -> `16/11/2026`.`

### - Arquivo README.md:
1. `Adicionando o README: Adicionando um arquivo README com detalhes e instruções do projeto -> `16/11/2026`.`
2. `Ajustando e complementando: Adicionando Histórico e Declaração de utilização de IA -> `16/11/2026`.`

### - Arquivo TESTES.md:
1. `Adicionados planos de testes para CPUlator ARMv7: Documentação do plano de testes para CPUlator ARMv7 / DE1-SoC, incluindo preparação, casos funcionais, sequência completa do modo 11, inspeção de sub-rotinas e critérios de aprovação -> `13/11/2026`.`

### - Gravação do Vídeo:
1. `Gravação do Vídeo -> `16/11/2026`.`

## 8. Declaração de uso de inteligência artificial

Foi utilizada inteligência artificial (ChatGPT, OpenAI) para **auxiliar na estruturação inicial do código ARMv7 como orientação, planejamento de testes e preparação da documentação**. A compilação local do arquivo Assembly foi verificada com o assembler do Clang para alvo ARMv7. O autor do trabalho deve revisar, interpretar, executar, elaborar, entender, ajustar, organizar, testar e assumir responsabilidade pelo material apresentado.

## 9. Fontes técnicas

- CPUlator — simulador ARMv7 DE1-SoC: <https://cpulator.01xz.net/?sys=arm-de1soc>
- CPUlator — documentação oficial: <https://cpulator.01xz.net/doc/>
- MALVINO, A. P. Microcomputadores e microprocessadores. McGraw-Hill, 1985 — capítulos sobre arquitetura e programação.
Material da disciplina: slides “Introdução à Programação Assembly” e lista de exercícios no CPUlator.
- ARM Developer — “Arm Architecture Reference Manual, ARMv7-A”, seção do conjunto de instruções.
