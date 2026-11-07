:- use_module(game).
:- use_module(library(plunit)).

:- begin_tests(game).

test(vitoria) :-
    game_won([[2048,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]).
test(sem_vitoria, [fail]) :-
    game_won([[2,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]).

% TODO: testes de move/4 (fusão, deslize, pontuação) e game_lost/1.

:- end_tests(game).
