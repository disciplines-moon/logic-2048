% Motor de regras do 2048. O tabuleiro é uma lista de N linhas (listas de N
% inteiros, 0 = vazio), com N de 3 a 6. O Prolog é puro: não sorteia peças.
:- module(game, [move/4, game_won/1, game_lost/1]).

%! move(+Board, +Dir, -NewBoard, -Score) is det.
%  Dir é left, right, up ou down. Score é a pontuação ganha nesta jogada.
%  TODO(esqueleto): devolve o tabuleiro sem alterações.
move(Board, _Dir, Board, 0).

%! game_won(+Board) is semidet.
%  TODO(#4): a peça de vitória depende de N (256, 2048, 4096, 8192) e vale >=.
game_won(Board) :-
    member(Row, Board),
    member(2048, Row), !.

%! game_lost(+Board) is semidet.
%  TODO(esqueleto): nunca perde.
game_lost(_) :- fail.
