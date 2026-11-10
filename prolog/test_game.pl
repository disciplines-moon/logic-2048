:- use_module(game).
:- use_module(library(plunit)).

:- begin_tests(game).

test(vitoria) :-
    game_won([[2048,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]).
test(sem_vitoria, [fail]) :-
    game_won([[2,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]).

% TODO: testes de move/4 (fusão, deslize, pontuação) e game_lost/1.

:- end_tests(game).

% Testes da #2. O plunit também avisa se um teste deixar ponto de escolha
% sobrando, então cada caso abaixo já confere o determinismo.
:- begin_tests(slide_left).

% Os quatro exemplos do contrato (docs/contrato.md).
test(quatro_iguais) :-
    slide_left([2,2,2,2], L, P), L == [4,4,0,0], P == 8.
test(zero_no_meio) :-
    slide_left([2,0,2,4], L, P), L == [4,4,0,0], P == 4.
test(par_no_meio) :-
    slide_left([4,2,2,0], L, P), L == [4,4,0,0], P == 4.
test(nada_funde) :-
    slide_left([2,4,8,16], L, P), L == [2,4,8,16], P == 0.

% Cada peça funde uma vez só: o 4 recém-criado não funde com o 4 seguinte.
test(funde_uma_vez) :-
    slide_left([2,2,4,0], L, P), L == [4,4,0,0], P == 4.
% Três iguais: os dois primeiros fundem e o terceiro sobra.
test(tres_iguais) :-
    slide_left([2,2,2,0], L, P), L == [4,2,0,0], P == 4.
% Zeros vão para o final e a linha vazia continua vazia.
test(zeros_ao_final) :-
    slide_left([0,0,0,2], L, P), L == [2,0,0,0], P == 0.
test(linha_vazia) :-
    slide_left([0,0,0,0], L, P), L == [0,0,0,0], P == 0.

% Tamanhos de 3 a 6.
test(n3) :-
    slide_left([2,2,2], L, P), L == [4,2,0], P == 4.
test(n5) :-
    slide_left([8,8,0,4,4], L, P), L == [16,8,0,0,0], P == 24.
test(n6) :-
    slide_left([2,2,4,4,8,8], L, P), L == [4,8,16,0,0,0], P == 28.

% Determinismo explícito: call_cleanup só roda o segundo objetivo quando o
% primeiro termina SEM ponto de escolha.
test(deterministico) :-
    call_cleanup(slide_left([2,2,4,4], _, _), Det = true),
    Det == true.

% Row é entrada (+): com a linha livre, o must_be acusa o erro logo na entrada.
test(row_livre, [error(instantiation_error)]) :-
    slide_left(_, [4,0,0,0], 4).

:- end_tests(slide_left).
