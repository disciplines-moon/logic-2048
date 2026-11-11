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

%! move(+Board, ?Dir, -NewBoard, -Score) is nondet.
%  Dir é left, right, up ou down. Score é a pontuação ganha nesta jogada: a
%  soma dos pontos de todas as linhas. Se nada muda, NewBoard = Board e Score = 0.
%  Com Dir pronto, é det (uma resposta, sem ponto de escolha). Com Dir livre,
%  enumera as quatro direções (left, right, up, down), inclusive as que não
%  mudam o tabuleiro: quem quer só as jogadas válidas compara NewBoard com Board.
move(Board, Dir, NewBoard, Score) :-
    must_be(list, Board),             % Board é entrada: precisa vir pronto
    move_dir(Dir, Board, NewBoard, Score).

%  move_dir(?Dir, +Board, -NewBoard, -Score): uma regra por direção. Só a
%  esquerda desliza de verdade; as outras três são a esquerda vista de outro
%  ângulo. Dir vem primeiro para o Prolog escolher a cláusula pelo átomo.
move_dir(left, Board, NewBoard, Score) :-       % esquerda: direto, linha por linha
    slide_rows(Board, NewBoard, Score).
move_dir(right, Board, NewBoard, Score) :-      % direita: espelha, vai à esquerda, desespelha
    mirror(Board, Mirrored),
    slide_rows(Mirrored, Slid, Score),
    mirror(Slid, NewBoard).
move_dir(up, Board, NewBoard, Score) :-         % cima: colunas viram linhas, vai à esquerda
    transpose_board(Board, Cols),
    move_dir(left, Cols, Slid, Score),
    transpose_board(Slid, NewBoard).
move_dir(down, Board, NewBoard, Score) :-       % baixo: colunas viram linhas, vai à direita
    transpose_board(Board, Cols),
    move_dir(right, Cols, Slid, Score),
    transpose_board(Slid, NewBoard).

%  slide_rows(+Rows, -NewRows, -Score): slide_left em cada linha (maplist) e
%  Score é a soma dos pontos de cada uma.
slide_rows(Rows, NewRows, Score) :-
    maplist(slide_left, Rows, NewRows, Points),
    sum_list(Points, Score).

%  mirror(?Rows, ?Mirrored): inverte cada linha, como num espelho.
%  Ex.: [[2,0,4],[0,8,0]] <-> [[4,0,2],[0,8,0]]. Aplicar duas vezes desfaz.
mirror(Rows, Mirrored) :-
    maplist(reverse, Rows, Mirrored).

%  transpose_board(?Rows, ?Cols): troca linhas por colunas (a coluna I vira a
%  linha I). Não se chama transpose/2 para não colidir com o da library(clpfd).
%  Ex.: [[1,2],[3,4]] <-> [[1,3],[2,4]]. Aplicar duas vezes desfaz.
%  Não depende de N: cada passo tira a primeira peça de todas as linhas.
transpose_board([], []).
transpose_board([Row|Rows], Cols) :-
    transpose_board_(Row, [Row|Rows], Cols).

%  transpose_board_(?Guide, ?Rows, ?Cols): Guide só conta quantas colunas faltam.
transpose_board_([], Rows, []) :-         % acabaram as colunas...
    maplist(=([]), Rows).                 % ...e todas as linhas acabaram juntas
transpose_board_([_|Guide], Rows, [Col|Cols]) :-
    maplist(first_rest, Rows, Col, Rests), % Col = a primeira peça de cada linha
    transpose_board_(Guide, Rests, Cols).  % o resto das linhas dá as outras colunas

first_rest([X|Xs], X, Xs).

%! game_won(+Board) is semidet.
%  TODO(#4): a peça de vitória depende de N (256, 2048, 4096, 8192) e vale >=.
game_won(Board) :-
    member(Row, Board),
    member(2048, Row), !.

%! game_lost(+Board) is semidet.
%  TODO(esqueleto): nunca perde.
game_lost(_) :- fail.
