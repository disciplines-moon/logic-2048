% Motor de regras do 2048. O tabuleiro é uma lista de N linhas (listas de N
% inteiros, 0 = vazio), com N de 3 a 6. O Prolog é puro: não sorteia peças.
:- module(game, [slide_left/3, move/4, game_won/1, game_lost/1]).

%! slide_left(+Row, -NewRow, -Points) is det.
%  Desliza uma linha para a esquerda, fundindo pares iguais vizinhos.
%  Points é a soma das peças criadas. Ex.: [2,2,2,2] -> [4,4,0,0], 8.
slide_left(Row, NewRow, Points) :-
    must_be(list, Row),               % Row é entrada: precisa vir pronta
    exclude(==(0), Row, Tiles),       % 1. tira os zeros:  [2,0,2,4] -> [2,2,4]
    merge(Tiles, Merged, Points),     % 2. funde os pares: [2,2,4]   -> [4,4]
    pad_zeros(Row, Merged, NewRow).   % 3. completa:       [4,4]     -> [4,4,0,0]

%  merge(+Tiles, -Merged, -Points): definida por casos, sem laço.
merge([], [], 0).                     % caso base: nada para fundir
merge([X,X|T], [Y|R], Points) :-      % dois iguais seguidos: o mesmo X casa duas vezes
    !,                                % achou o par: não tente as outras cláusulas
    Y is 2*X,                         % a peça nova vale o dobro...
    merge(T, R, Rest),                % ...e o resto continua de T, sem o Y
    Points is Rest + Y.               % ...e os pontos são o valor dela
merge([X|T], [X|R], Points) :-        % X não tem par: fica como está
    merge(T, R, Points).

%  pad_zeros(+Row, +Merged, -NewRow): Merged mais zeros até o tamanho de Row.
pad_zeros(Row, Merged, NewRow) :-
    length(Row, N),
    length(NewRow, N),
    append(Merged, Zeros, NewRow),
    maplist(=(0), Zeros).

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
