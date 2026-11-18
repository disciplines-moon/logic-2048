# QA ponta a ponta e apresentação (#14)

Roteiro para conferir o projeto inteiro antes da banca. Rode com o projeto de pé
(`sh scripts/rodar.sh` ou os dois terminais do README) e marque cada item em
**3×3, 4×4, 5×5 e 6×6**. Um item só vale depois de visto no navegador; animação
se confere em vários quadros, não num print parado.

## 1. Instalação numa máquina limpa

- [ ] Só com o README: SWI-Prolog, uv, Node e `make install` (ou `uv sync`, com o `CFLAGS` do gcc 14+ se precisar, e `npm ci`).
- [ ] `uv run python -c "import janus_swi as j; print(j.query_once('X is 1+1'))"` responde `{'truth': True, 'X': 2}`.
- [ ] Testes: `make test` (ou cada `prolog/test_*.pl`, `cd server && uv run pytest` e `cd web && npm run check`).
- [ ] Relatório: `make validar` sem erros.

## 2. Jogo (`#/`)

| Funcionalidade | O que conferir | 3×3 | 4×4 | 5×5 | 6×6 |
|---|---|---|---|---|---|
| Início (#6) | Duas peças sorteadas pelo Elm, em casas diferentes | [ ] | [ ] | [ ] | [ ] |
| Jogar (#3, #6) | Setas, W A S D e swipe; jogada que não muda nada não sorteia peça | [ ] | [ ] | [ ] | [ ] |
| Deslizar (#8) | Cada peça desliza de casa em casa; a fusão dá o pop | [ ] | [ ] | [ ] | [ ] |
| Vitória (#4, #9) | Peça de vitória do N (256, 2048, 4096, 8192): fanfarra, confete, "Você venceu!", e a festa não repete na mesma partida | [ ] | [ ] | [ ] | [ ] |
| Derrota (#4) | "Fim de jogo" sobre o tabuleiro, com Novo jogo | [ ] | [ ] | [ ] | [ ] |
| Desfazer (#7) | Botão e Ctrl+Z voltam tabuleiro, pontos e status, com a peça sorteada | [ ] | [ ] | [ ] | [ ] |
| Replay (#7) | Pausar, velocidade e fechar (✕) voltam ao jogo onde estava | [ ] | [ ] | [ ] | [ ] |
| Sons, tema, recorde (#9) | Som e tema voltam depois do F5; recorde separado por tamanho | [ ] | [ ] | [ ] | [ ] |
| Dica (#5, #11, #20) | O botão liga e desliga; ligada, a seta aparece e acompanha cada jogada; desligada, some; o valor de cada direção aparece | [ ] | [ ] | [ ] | [ ] |
| IA (#20) | Joga sozinha, assume de qualquer ponto (inclusive depois de desfazer), velocidade muda, pausa; teclas ignoradas enquanto joga | [ ] | [ ] | [ ] | [ ] |
| IA para sozinha | Ao vencer, ao perder e sem jogada, com o aviso do motivo | [ ] | [ ] | [ ] | [ ] |
| Desafios (#19, #11, #20) | c1, c2 e c3 resolvem passo a passo, sem nascer peça; Recomeçar e Sair | — | [ ] | — | — |
| Erros (#10, #20) | Com a API parada: "Sem resposta do servidor"; o jogo não trava e volta quando a API sobe | [ ] | [ ] | [ ] | [ ] |

O desafio c3 é 3×3; os outros são 4×4. "—" é tamanho sem desafio.

## 3. Apresentação (`#/apresentacao`)

- [ ] Nenhuma cena pendente (vermelha): `Cenas.pendingCount == 0`.
- [ ] Cada cena cabe na tela sem rolar, em 1280×720 e na tela cheia (`f`) da máquina da banca.
- [ ] Cada bloco `Code` aponta o trecho certo (`from`, `to`, `mark` contra o arquivo atual).
- [ ] Cada `Demo` funciona: dica, IA, desafios, replay (o ✕ fecha), e a demo não muda de tamanho.
- [ ] Os `Pedidos` vão ao servidor de verdade (cenas da #10 e da #11).
- [ ] O painel de notas (`n`) mostra a foto e o nome de quem fala em cada cena.

## 4. Quem explica o quê

Cada pessoa apresenta as próprias issues. A apresentação mostra a foto e o nome de
quem fala no painel de notas (`web/src/Cenas/Equipe.elm`).

| Bloco | Cenas (issues) | Quem apresenta |
|---|---|---|
| Abertura | Capa, equipe, "Primeiro, jogue", "Como uma jogada acontece", roteiro (#17) | Victor |
| Prolog | Deslizar e fundir (#2), dica com expectimax (#5) | Bianca |
| Prolog | Mover nas 4 direções (#3), desafios com CLP(FD) (#19) | Davi |
| Prolog e Python | Vitória e derrota (#4), dica e desafios na API (#11) | Kaio |
| Python e Elm | A ponte (#10), dica, IA e desafios na interface (#20) | William |
| Elm | Estado, Random e TEA (#6), desfazer e replay (#7) | Mateus Castro |
| Elm | Tela e animações (#8), comemorações e ports (#9) | Mateus Henrique |
| Projeto e fim | CI e um comando para rodar (#13), conclusão (#14) | Victor |

Uma frase por paradigma, para fechar:

- **Lógico (Prolog):** as regras são fatos e relações; a dica e os desafios são buscas que o Prolog faz por backtracking.
- **Funcional (Elm):** o estado só muda no `update`, uma função pura; efeitos (HTTP, sorteio, sons) são dados que o runtime executa.
- **A ponte (Python):** só valida e traduz formatos; nenhuma regra de jogo mora nela.

## 5. Plano B

| Se… | Então… |
|---|---|
| A API não sobe na máquina da banca | Usar o notebook de reserva já testado. Sem a API o jogo não move (as regras estão no Prolog), mas as cenas sem `Demo`/`Pedidos` funcionam só com a interface (`npm run dev`) |
| O janus-swi não compila | `CFLAGS="-Wno-error=incompatible-pointer-types -Wno-incompatible-pointer-types" uv sync`; se ainda falhar, recompilar com `--reinstall-package janus-swi --no-binary-package janus-swi --no-cache` (README) |
| A internet cair | As fotos da equipe e do painel de notas viram a inicial; o resto não depende de internet |
| A dica ou a IA demorarem | Dica em profundidade 2 (o padrão); a IA em 1× ou 2× |
| Uma demo travar | Recarregar com Ctrl+Shift+R (o endereço guarda a cena e o passo) |
| Som não tocar | O navegador só libera som depois do primeiro clique ou tecla: clicar na demo antes |
| O confete não aparecer | "Reduzir movimento" está ligado no sistema; o confete respeita essa preferência. Desligar antes de apresentar |
| Uma cena mostrar código antigo | Reiniciar a API e o `npm run dev` depois de mudar `prolog/` ou `server/` |

## 6. Máquina da apresentação

- [ ] Escolhida e com o projeto instalado do zero pelo README (janus incluído).
- [ ] Ensaio completo, cena por cena, com quem apresenta cada uma.
- [ ] Tela cheia (`f`) na resolução do projetor, sem rolagem em nenhuma cena.
- [ ] Recorde e preferências: em aba anônima começam do zero (é `localStorage`).
