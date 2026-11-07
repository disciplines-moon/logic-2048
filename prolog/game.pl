% Motor de regras do 2048. O tabuleiro é uma lista de 4 linhas (listas de 4
% inteiros, 0 = vazio). O Prolog é puro: não sorteia peças.
:- module(game, [move/4, game_won/1, game_lost/1]).

%! move(+Board, +Dir, -NewBoard, -Score) is det.
%  Dir é left, right, up ou down. Score é a pontuação ganha nesta jogada.
%  TODO(esqueleto): devolve o tabuleiro sem alterações.
move(Board, _Dir, Board, 0).

%! game_won(+Board) is semidet.
game_won(Board) :-
    member(Row, Board),
    member(2048, Row), !.

%! game_lost(+Board) is semidet.
%  TODO(esqueleto): nunca perde.
game_lost(_) :- fail.
