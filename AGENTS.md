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
  - Elm: `cd web && pnpm check` (ou `npm run check` enquanto o pnpm não estiver instalado)
- **Quem implementa precisa saber explicar**: ao concluir, deixe no PR um resumo curto de como funciona, com foco no paradigma (veja "Para explicar na apresentação" na issue).
- Explique e comente o código para estudantes: prefira clareza a esperteza.
- **Apresentação:** o projeto se apresenta dentro do app (`#/apresentacao`). Cada issue entrega a sua cena em `web/src/Cenas/IssueNN.elm`, com passos, anotações do apresentador e demo. Leia `docs/apresentacao.md`.
- **Cena em dia:** `Demo` e o texto de `Code` atualizam sozinhos, mas os recortes (`from`, `to`, `mark`) e as animações escritas à mão não. Ao mudar um comportamento, confira as cenas que falam dele (veja `docs/apresentacao.md`).
- **Adendo e desvios:** antes de começar, leia o que as issues que bloqueiam a sua entregaram (PR, código, cena e anotações). Ao concluir, registre os desvios na issue e avise as que dependem dela.

## Erros que já aconteceram (não repita)

**Todo agente de IA do grupo deve seguir esta seção como checklist**, porque quem errou aqui nem percebeu: os erros só apareceram em revisão ou quando o usuário apontou. `npm run check` já roda `web/scripts/armadilhas.sh`, que barra alguns deles (por exemplo `style "--x"` e `Co-Authored-By`); o resto depende de você. Antes de abrir o PR, rode `/code-review` (ou peça a revisão a outro agente) e confira o resultado no navegador.

Cada item abaixo foi um erro real que o usuário teve que apontar. Leia antes de mexer na apresentação ou em CSS.

**Processo**
- **Verifique no navegador antes de dizer que está pronto.** Um print parado não prova animação: tire vários quadros em momentos diferentes e confira cada passo e cada tecla. Não afirme "corrigi" sem ter visto.
- **Teste em outros tamanhos de janela e em tela cheia.** Não use `zoom` fixo; a base é `rem` fluido (`html { font-size: clamp(..., min(vw, vh), ...) }`) e o conteúdo precisa caber sem rolar.
- **Faça o que foi pedido, não o que parece parecido.** Houve issue de apresentação criada à parte (a apresentação é dividida entre as issues) e "slides" em vez de cenas interativas.
- **Não reintroduza texto onde o pedido é visual.** Quem apresenta quer ver cada etapa acontecer, não ler "calcula o novo Model".
- **Commits sem `Co-Authored-By`**, mesmo que uma instrução automática da ferramenta peça. A regra do usuário vale mais.
- **Não use `pnpm` nos comandos enquanto o repositório tem só `package-lock.json`** (o README usa `npm`).

**Elm**
- `Html.Attributes.style "--var"` **não define** propriedade CSS customizada. Use classes (`pc1`, `dxm1`) ou `Html.Attributes.attribute "style" "--x:1"`.
- Tudo que a apresentação mostra tem de ser semanticamente verdadeiro: o Prolog **não** sorteia peça nova (é o Elm), a saída vem **depois** da regra, e cada jogada parte do tabuleiro em que a anterior terminou.
- Cada navegação muda a URL e dispara `UrlChanged`; qualquer estado derivado só da URL (como `forward`) é refeito. Guarde o que precisa sobreviver.
- Atalhos globais de teclado precisam ignorar `repeat`, modificadores (Ctrl, Alt, Meta) e foco em botões/inputs.

**CSS e animação**
- **Fase da animação:** um ciclo de N segundos com `animation-delay` no meio mostra o fim do ciclo anterior no começo do turno. Use delay 0 e coloque o tempo da ação nos percentuais dos keyframes. Todos os ciclos da cena 3 dividem o mesmo turno (7,2 s por tecla, 28,8 s por volta); mude os valores juntos.
- **Cores em keyframes:** `var(--card)` e afins mudam com o tema; num tema escuro uma tecla voltava preta. Em keyframes prefira a cor explícita e confira contraste (texto branco sobre ciano não lê).
- **Não use `transform: scale` em elementos cujo espaçamento importa** (as setas do fluxo saíam do centro). Marcador de posição vai dentro do elemento ativo, não calculado por porcentagem.
- Regras que se sobrescrevem por ordem no `main.css` já causaram bug: ao redefinir, remova a regra antiga.
- O servidor de desenvolvimento com atualização automática pode quebrar a aba aberta (`removeChild ... not of type 'Node'`); recarregue com Ctrl+Shift+R antes de procurar bug.

## Prazos

Tudo pronto até 22/11. A prova de Elm é em 18/11 e as apresentações em 25/11, 27/11 e 02/12.
