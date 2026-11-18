:- use_module(game).
:- use_module(hint).
:- use_module(library(plunit)).

% Testes da #5: dica com expectimax (hint/4).
% Rode com: swipl -g "load_files('prolog/test_hint.pl'),run_tests" -t halt

ex([[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]).

% Tabuleiro cheio, sem par vizinho: nenhuma jogada muda nada.
travado([[2,4,2,4],[4,2,4,2],[2,4,2,4],[4,2,4,2]]).

% A árvore da cena (profundidade 1): cada jogada deixa uma casa vazia só.
arvore([[2,0,4],[4,8,16],[2,32,64]]).

:- begin_tests(hint).

% Exemplo da issue: left e right empatam (um é o espelho do outro) e vale a
% primeira na ordem left, right, up, down. up não muda nada, então não aparece.
test(exemplo_da_issue) :-
    ex(B),
    hint(B, 2, Best, Scores),
    Best == left,
    pairs_keys(Scores, [left, right, down]),
    memberchk(left-L, Scores),
    memberchk(right-R, Scores),
    L =:= R.

test(sem_jogada_none) :-
    travado(B),
    hint(B, 2, Best, Scores),
    Best == none,
    Scores == [].

% Scores tem exatamente as direções do available_moves/2, na mesma ordem.
test(so_direcoes_validas) :-
    forall(member(B, [ [[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],
                       [[2,4,2,4],[4,2,4,2],[2,4,2,4],[4,2,4,0]],
                       [[0,0,0],[0,2,0],[0,0,0]],
                       [[2,0,4],[4,8,16],[2,32,64]] ]),
           ( available_moves(B, Dirs),
             hint(B, 1, Best, Scores),
             pairs_keys(Scores, Dirs),
             memberchk(Best, Dirs) )).

% Sem aleatoriedade: o mesmo tabuleiro dá sempre a mesma resposta.
test(deterministico) :-
    B = [[2,4,8,16],[4,8,16,2],[2,0,0,0],[0,0,0,4]],
    hint(B, 2, B1, S1),
    hint(B, 2, B2, S2),
    B1 == B2,
    S1 == S2.

% Profundidade de 1 a 3; fora disso é erro de quem chamou (o Python barra antes).
% A 3 usa um tabuleiro com 6 casas vazias, como o Python manda.
test(profundidade_1_a_3) :-
    B = [[2,4,8,16],[4,8,16,2],[2,0,0,0],[0,0,0,4]],
    forall(between(1, 3, D), ( hint(B, D, Best, _), Best \== none )).
test(profundidade_0, [error(type_error(_, 0))]) :-
    ex(B),
    hint(B, 0, _, _).
test(profundidade_4, [error(type_error(_, 4))]) :-
    ex(B),
    hint(B, 4, _, _).

% Espelhar o tabuleiro troca left com right e mantém os valores.
test(simetria_espelho) :-
    B = [[2,4,8,16],[4,8,16,2],[2,0,0,0],[0,0,0,4]],
    maplist(reverse, B, M),
    hint(B, 2, _, S),
    hint(M, 2, _, SM),
    memberchk(left-L, S), memberchk(right-RM, SM), L =:= RM,
    memberchk(right-R, S), memberchk(left-LM, SM), R =:= LM.

% Caso óbvio: a jogada que funde e mantém o 64 no canto ganha da que o tira.
test(obvio_canto) :-
    hint([[2,0,4],[4,8,16],[2,32,64]], 1, right, _).
test(obvio_fundir) :-
    hint([[2,2,4],[8,4,2],[16,8,0]], 2, left, _).

% Funciona de 3×3 a 6×6.
test(todos_os_tamanhos) :-
    forall(member(N, [3, 4, 5, 6]),
           ( length(B, N),
             maplist([Row]>>length(Row, N), B),
             B = [[2|_]|_],                     % um 2 no canto...
             append(B, Cells),
             maplist([C]>>(var(C) -> C = 0 ; true), Cells),   % ...e o resto vazio
             hint(B, 1, Best, _),
             Best \== none )).

:- end_tests(hint).

% O nó de sorteio: média sobre todas as casas vazias, peça 2 (90%) e 4 (10%).
:- begin_tests(hint_sorteio).

% Uma casa vazia: 0,9 × nota(com 2) + 0,1 × nota(com 4).
test(uma_casa_vazia) :-
    B = [[2,4,0],[4,8,16],[2,32,64]],          % o right da árvore da cena
    hint:chance_value(B, 1, V),
    evaluate([[2,4,2],[4,8,16],[2,32,64]], V2),
    evaluate([[2,4,4],[4,8,16],[2,32,64]], V4),
    abs(V - (0.9 * V2 + 0.1 * V4)) < 1e-9.

% Duas casas vazias: cada casa vale 1/2 e, dentro dela, 90% / 10%.
test(duas_casas_vazias) :-
    B = [[0,4,0],[4,8,16],[2,32,64]],
    hint:chance_value(B, 1, V),
    evaluate([[2,4,0],[4,8,16],[2,32,64]], A2),
    evaluate([[4,4,0],[4,8,16],[2,32,64]], A4),
    evaluate([[0,4,2],[4,8,16],[2,32,64]], B2),
    evaluate([[0,4,4],[4,8,16],[2,32,64]], B4),
    Esperado is 0.5 * (0.9 * A2 + 0.1 * A4) + 0.5 * (0.9 * B2 + 0.1 * B4),
    abs(V - Esperado) < 1e-9.

% A dica de profundidade 1 é exatamente o nó de sorteio depois de cada jogada.
test(profundidade_1_e_a_media) :-
    arvore(B),
    hint(B, 1, _, Scores),
    forall(member(Dir-V, Scores),
           ( move(B, Dir, Next, _),
             hint:chance_value(Next, 1, V0),
             V =:= round(V0 * 100) / 100 )).

:- end_tests(hint_sorteio).

% A heurística: casas vazias, monotonicidade e maior peça no canto.
:- begin_tests(hint_heuristica).

test(mais_vazias_e_melhor) :-
    evaluate([[2,0,0],[0,0,0],[0,0,0]], A),
    evaluate([[2,2,0],[0,0,0],[0,0,0]], B),
    A > B.
test(linha_em_ordem_e_melhor) :-
    evaluate([[16,8,4,2],[0,0,0,0],[0,0,0,0],[0,0,0,0]], Ordem),
    evaluate([[16,2,8,4],[0,0,0,0],[0,0,0,0],[0,0,0,0]], Baguncada),
    Ordem > Baguncada.
test(maior_no_canto_e_melhor) :-
    evaluate([[64,0,0],[0,2,0],[0,0,0]], Canto),
    evaluate([[2,0,0],[0,64,0],[0,0,0]], Meio),
    Canto > Meio.
% A nota é a mesma no espelho e na transposta: nenhum lado é "o bom".
test(nota_simetrica) :-
    B = [[2,4,8,16],[4,8,16,2],[2,0,0,0],[0,0,0,4]],
    evaluate(B, V),
    maplist(reverse, B, M), evaluate(M, VM),
    game:transpose_board(B, T), evaluate(T, VT),
    V =:= VM, V =:= VT.
% Valores fixos que a cena mostra.
test(valores_da_cena) :-
    evaluate([[2,4,2],[4,8,16],[2,32,64]], 20),
    evaluate([[2,4,4],[4,8,16],[2,32,64]], 22).

:- end_tests(hint_heuristica).

% Desempenho (critério da issue). Medido em tempo de CPU.
:- begin_tests(hint_desempenho).

test(n4_profundidade_2_ate_1s) :-
    forall(member(B, [ [[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],
                       [[2,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,2]],
                       [[2,4,8,16],[4,8,16,2],[2,0,0,0],[0,0,0,4]] ]),
           ( cpu(hint(B, 2, _, _), T), T < 1.0 )).
test(n6_profundidade_2_ate_3s) :-
    B = [[2,0,0,0,0,0],[0,0,0,0,0,0],[0,0,0,0,0,0],
         [0,0,0,0,0,0],[0,0,0,0,0,0],[0,0,0,0,0,2]],
    cpu(hint(B, 2, _, _), T),
    T < 3.0.
% Profundidade 3 só com até 6 casas vazias (o Python reduz acima disso).
test(n4_profundidade_3_com_6_vazias) :-
    B = [[2,4,8,16],[4,8,16,2],[2,0,0,0],[0,0,0,4]],
    cpu(hint(B, 3, _, _), T),
    T < 3.0.

:- end_tests(hint_desempenho).

% A cena da #5 (web/src/Cenas/Issue05.elm) mostra estes resultados escritos à
% mão: se o hint/4 mudar, este teste avisa que a cena precisa mudar junto.
:- begin_tests(hint_cena).

test(cena_issue05) :-
    arvore(B),
    move(B, left, [[2,4,0],[4,8,16],[2,32,64]], _),
    move(B, right, [[0,2,4],[4,8,16],[2,32,64]], _),
    move(B, up, [[2,8,4],[4,32,16],[2,0,64]], _),
    hint(B, 1, right, [left-20.2, right-22.0, up-14.0]),
    evaluate([[2,2,4],[4,8,16],[2,32,64]], 22),
    evaluate([[4,2,4],[4,8,16],[2,32,64]], 22),
    evaluate([[2,8,4],[4,32,16],[2,2,64]], 14),
    evaluate([[2,8,4],[4,32,16],[2,4,64]], 14),
    ex(Ex),
    move(Ex, left, [[4,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], _),
    move(Ex, right, [[0,0,0,4],[0,0,0,0],[0,0,0,0],[0,0,0,0]], _),
    move(Ex, down, [[0,0,0,0],[0,0,0,0],[0,0,0,0],[2,2,0,0]], _),
    hint(Ex, 2, left, [left-135.67, right-135.67, down-134.73]).

:- end_tests(hint_cena).

cpu(Goal, T) :-
    statistics(cputime, T0),
    once(Goal),
    statistics(cputime, T1),
    T is T1 - T0.

%  medir: imprime a tabela de tempos da cena (profundidade 1, 2 e 3). Rode com:
%  swipl -g "load_files('prolog/test_hint.pl'),medir" -t halt
medir :-
    forall(member(Nome-B, [ '4×4, 14 vazias'-[[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],
                            '4×4, 6 vazias'-[[2,4,8,16],[4,8,16,2],[2,0,0,0],[0,0,0,4]] ]),
           ( format("~w~n", [Nome]),
             forall(between(1, 3, D),
                    ( statistics(inferences, I0),
                      cpu(hint(B, D, _, _), T),
                      statistics(inferences, I1),
                      I is I1 - I0,
                      format("  profundidade ~w ~t~D~16| inferências ~t~3f~10| s~n", [D, I, T]) )) )).
