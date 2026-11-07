# Logic2048: planejamento

Trabalho final de Paradigmas de Programação (34% da nota), em grupo de 7 pessoas.
O jogo 2048 usa **Prolog** para as regras, **Elm** para a interface e **Python**
como ponte. O formato dos dados e da API está em [`contrato.md`](contrato.md).

## Objetivo

Entregar um 2048 completo, em que cada paradigma tenha um papel claro e
explicável na apresentação. Quando todas as issues estiverem fechadas, o
sistema deve estar pronto, sem ajustes finais.

| Camada | Tecnologia | Papel |
|---|---|---|
| Interface | Elm (TEA) + Vite | Estado da tela, sorteio de peças, histórico, animações e ports (sons, confete, recorde) |
| Ponte | Python (`uv`, FastAPI, janus) | Valida a entrada, chama o Prolog e devolve JSON |
| Regras | SWI-Prolog (>= 9.1.12) | Mover, fundir, pontuar, vitória, derrota, dica e desafios |

## Arquitetura

```
Teclado ──> Elm ──(JSON/HTTP)──> Python ──(janus)──> Prolog
              ^                                        │
              └────────── resultado em JSON ───────────┘
```

O Prolog é puro e não sorteia nada. O Elm sorteia as peças novas e guarda o
histórico de estados, o que dá desfazer e replay de graça. Detalhes dos
endpoints e dos predicados estão no [contrato](contrato.md).

## Escopo

**Núcleo**
- Tabuleiro de 3×3 a 6×6.
- Mover, fundir, pontuar, vitória (>= 2048, com opção de continuar) e derrota.

**Extras que mostram os paradigmas**
- **Dica de jogada:** expectimax em Prolog, com backtracking e média sobre as peças possíveis.
- **IA joga sozinha:** o Elm pede dica e jogada em loop.
- **Desafios com CLP(FD):** alcançar uma peça alvo em até N jogadas, sem peças novas.
- **Desfazer e replay:** a imutabilidade do Elm deixa isso simples.

**Experiência (foco no desktop)**
- Animações de deslizar e fundir.
- Apresentação embutida no próprio app (`#/apresentacao`), com demo ao vivo no lugar de slides externos.
- Sons, confete e comemoração de vitória (ports, como no jogo da memória da aula).
- Recorde salvo por tamanho de tabuleiro e tema claro/escuro.
- Swipe no celular como extra.

## Issues, prazos e dependências

Cada pessoa fica com 2 issues, feitas em sequência, nunca em dupla. São 15 no total, e a #21 (apresentação embutida) é a que sobra: quem terminar antes pega. Os prazos
(Target date) e as dependências (Relationships) estão no
[GitHub Project](https://github.com/orgs/disciplines-moon/projects/1).

| # | Issue | Frente | Prazo | Bloqueada por |
|---|---|---|---|---|
| 2 | Deslizar e fundir uma linha | Prolog | 09/11 | |
| 3 | `move/4` nas 4 direções, N×N | Prolog | 11/11 | #2 |
| 4 | Vitória, derrota e jogadas disponíveis | Prolog | 12/11 | #3 |
| 5 | Dica com expectimax | Prolog | 16/11 | #3, #4 |
| 19 | Desafios com CLP(FD) | Prolog | 17/11 | #3, #4 |
| 6 | Estado, Random, teclado e tamanho | Elm | 11/11 | |
| 7 | Desfazer e replay | Elm | 15/11 | #6 |
| 8 | Interface, temas e animações | Elm | 16/11 | #6 |
| 9 | Sons, confete e recorde (ports) | Elm | 19/11 | #4, #8 |
| 20 | Dica, IA, desafios e erros na interface | Elm | 21/11 | #5, #7, #8, #11, #19 |
| 10 | `/api/move`, validação e erros | Python | 13/11 | #3 |
| 11 | `/api/hint`, `/api/challenge` e testes de ponta a ponta | Python | 19/11 | #5, #10, #19 |
| 13 | CI, template de PR, MkDocs, pnpm e um comando para rodar | Gestão | 13/11 | |
| 21 | Apresentação embutida no app, com demo ao vivo | Elm | 21/11 | #6, #8 |
| 14 | Integração final, QA e ensaio | Gestão | 22/11 | #7, #9, #11, #13, #20, #21 |

A #17 (esqueleto e contrato) é a base e não conta entre as 15.

## Equipe

| Nome | GitHub | Issues | Revisa |
|---|---|---|---|
| Victor Hugo Lima Schmidt | moonshinerd | a definir | a definir |
| Bianca Patrocínio Castro | BiancaPatrocinio7 | a definir | a definir |
| Davi de Aguiar Vieira | davi-aguiar-vieira | a definir | a definir |
| Kaio Macedo Santana | Bigkaio | a definir | a definir |
| Mateus de Castro Santos | mat054 | a definir | a definir |
| Mateus Henrique Queiroz Magalhães Sousa | Mateushqms | a definir | a definir |
| William Bernardo da Silva | willxbernardo | a definir | a definir |

**Revisão em círculo:** cada pessoa revisa os PRs da seguinte, e a última revisa
a primeira. Assim cada um revisa 2 issues, com carga igual. Quem revisa deve
conseguir explicar o que aprovou.

## Marcos

| Data | Marco |
|---|---|
| 09/11 a 13/11 | Regras básicas em Prolog, estado do Elm e `/api/move` funcionando, CI rodando |
| 16/11 a 17/11 | Dica, desafios, interface e animações |
| 18/11 | Prova de Elm (nenhuma issue vence nesse dia) |
| 19/11 a 21/11 | Ports, endpoints dos extras e a interface ligada aos extras |
| 22/11 | Integração final e QA |
| 23/11 | Código congelado. Só correções |
| 25/11, 27/11, 02/12 | Apresentações (a data do grupo será definida pelo professor) |

## Fluxo de trabalho

- **Todo PR deve ter uma issue relacionada**, com `Closes #<número>` na descrição.
- Branch por issue: `feat/<descricao-curta>`. Nada de commit direto na `main`.
- Todo PR precisa de aprovação do revisor designado.
- Commits em português, no imperativo: `Adiciona fusão de peças no Prolog`.
- Teste e formate antes de abrir o PR. Os comandos estão no [README](../README.md).
- Se o contrato mudar, atualize o [`contrato.md`](contrato.md) no mesmo PR e avise o grupo.
- Código copiado de fora ou de IA deve ser entendido por quem o enviou. O professor
  usa detecção de plágio e anula o trabalho, sem distinguir quem copiou de quem cedeu.

## Quem implementa explica

Ao concluir uma issue, a pessoa deve saber explicar como funciona, com foco no
paradigma (seção "Para explicar na apresentação" de cada issue). Na
apresentação, cada integrante fala das próprias issues.

## Estrutura do repositório

```
logic-2048/
├── docs/       planejamento, contrato e documentação
├── prolog/     motor de regras e testes (plunit)
├── server/     API em Python (FastAPI + janus)
└── web/        interface em Elm (Vite)
```

## Riscos

| Risco | Mitigação |
|---|---|
| `janus-swi` falha em gcc 14+ ou em outros sistemas | Documentado na issue #11 e no README. Confirmar a instalação de todos na primeira semana |
| Prova de Elm em 18/11 reduz o tempo | Issues de Elm pesadas vencem antes (#6, #7, #8). Nada vence em 18/11 |
| Integração só testada no fim | Esqueleto de ponta a ponta já pronto, contrato fechado e CI desde a #13 |
| Dica lenta com profundidade alta | Profundidade máxima 3 e desempenho exigido na #5 |
| Repositório privado no plano Free: sem proteção da `main` e sem GitHub Pages | Regras do fluxo acima e CI. O MkDocs roda só localmente |
