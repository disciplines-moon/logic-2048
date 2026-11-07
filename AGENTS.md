# Instruções para agentes

## Regras gerais

1. **Nunca** faça commits com `Co-Authored-By` ou qualquer outra linha de atribuição a IA, nem em PRs.
2. Seja sucinto e objetivo.
3. Leia `docs/contrato.md` (fonte única de verdade) e `docs/planejamento.md` antes de mexer no projeto.
4. Todo PR deve ter uma issue relacionada (`Closes #<número>` na descrição). Se não houver, crie a issue antes.
5. Nada de commit direto na `main`: branch por issue (`feat/<descricao-curta>`) e PR com revisão do revisor designado no GitHub Project.

## Projeto

Logic2048: 2048 com Prolog (regras), Python (ponte) e Elm (interface). Código em `prolog/`, `server/` e `web/`.

- **Prolog** é puro: mover, fundir, pontuar, vitória, derrota, dica (expectimax) e desafios (CLP(FD)). Não sorteia nada.
- **Python** só valida a entrada, chama o Prolog via janus e devolve JSON. Não tem regra de jogo.
- **Elm** cuida de estado, sorteio de peças (`Random`), histórico, animações e ports (sons, confete, recorde).
- Tabuleiro N×N com N de 3 a 6. Mudou formato de tabuleiro, endpoint ou predicado? Atualize `docs/contrato.md` no mesmo PR.

## Trabalho por issue

- São 14 issues de funcionalidade (#2 a #11, #13, #14, #19, #20), cada pessoa com 2 em sequência, e a #17 de estruturação. Dependências estão em *Relationships* e os prazos no Project (Target date).
- Cada issue tem critérios de aceite e exemplo de entrada e saída: cumpra todos e não amplie o escopo.
- Teste e formate antes do PR:
  - Prolog: `swipl -g "load_files('prolog/test_game.pl'),run_tests" -t halt`
  - Python: `cd server && uv run pytest` (se o `janus-swi` falhar no gcc 14+, use `CFLAGS="-Wno-error=incompatible-pointer-types"`)
  - Elm: `cd web && pnpm check`
- **Quem implementa precisa saber explicar**: ao concluir, deixe no PR um resumo curto de como funciona, com foco no paradigma (veja "Para explicar na apresentação" na issue).
- Explique e comente o código para estudantes: prefira clareza a esperteza.

## Prazos

Tudo pronto até 22/11. A prova de Elm é em 18/11 e as apresentações em 25/11, 27/11 e 02/12.
