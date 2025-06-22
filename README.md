# FPU - Floating Point Unit (Trabalho 4 da cadeira de Sistemas Digitais)

Este projeto implementa uma **FPU personalizada de 32 bits**, com suporte a **operações de adição e subtração** em ponto flutuante

## Formato de representação

  X = ( 8 - ( 2 + 4 + 1 + 0 + 3 + 2 + 0 + 0 + 2 ) % 4 ) = 6
  
  Y = 31 - 6 = 25
  
## Conteudo

- `main.sv`: Logica principal da FPU, de soma e subtração.
  
- `package.sv`: Contem a enumeração de estados, utilizados em `tb_fpu` e `main.sv`
  
- `tb_fpu.sv`: Testbench contendo casos testes para verificar a se a FPU está realizando as operações corretamente
  
- `sim.do` e `wave.do`: Scripts para uso com o ModelSim que compila os arquivos, executa a simulação e carrega os sinais.

## Testbench FPU

![image](https://github.com/user-attachments/assets/00e22565-6ab0-4b9a-9eb2-5f25dc39ce6a)

## Tabela de Testes da FPU

Embora a FPU produza os **valores numéricos corretos** nas operações de ponto flutuante, **a detecção dos estados associados (EXACT, INEXACT, OVERFLOW, UNDERFLOW)** ainda **não está totalmente precisa**.

| Caso                         | Resultado Esperado | Resultado da FPU     | Estado Esperado | Estado da FPU |
|------------------------------|--------------------|-----------------------|------------------|----------------|
| 1. 1.5 + 2.5                 | 4.0                | 4.0                   | EXACT           | EXACT         |
| 2. 4.0 - 2.0                 | 2.0                | 2.0                   | EXACT           | INEXACT       |
| 3. 4.0 + 0.0                 | 4.0                | 4.0                   | EXACT           | INEXACT       |
| 4. 4.0 + (-4.0)              | 0.0                | 0.0                   | EXACT           | EXACT         |
| 5. 3.4 + 4.6                 | ~8.0               | ~8.0                  | INEXACT         | EXACT         |
| 6. ~1e-36 + ~1e-36           | ~2e-36             | ~2e-36                | EXACT           | EXACT         |
| 7. max_float + max_float     | +Inf               | +Inf                  | OVERFLOW        | EXACT         |
| 8. 2.0 - 4.0                 | -2.0               | -2.0                  | EXACT           | INEXACT       |
| 9. -1.0 + -3.0               | -4.0               | -4.0                  | EXACT           | EXACT         |
| 10. 1.0 - 1.0000001          | ~-0.0000001        | ~-0.0000001           | INEXACT         | INEXACT       |

## Como rodar a simulação

1. Crie um novo projeto no ModelSim
2. Adicione os arquivos deste repositorio
3. Digite no terminal do ModelSim: do sim.do
