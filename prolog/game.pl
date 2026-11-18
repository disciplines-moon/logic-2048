% Motor de regras do 2048. O tabuleiro é uma lista de N linhas (listas de N
% inteiros, 0 = vazio), com N de 3 a 6. O Prolog é puro: não sorteia peças.
:- module(game, [slide_left/3, move/4, available_moves/2, game_won/1, game_lost/1, move_trace/5, hint/4, challenge/4]).

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
%  Verdadeiro se alguma peça é >= à peça de vitória do N do tabuleiro. Continua
%  verdadeiro com peças maiores: o jogo segue depois de vencer (docs/contrato.md).
%  É uma pergunta, não um laço: o member/2 volta atrás (backtracking) por todas
%  as linhas e casas até achar uma que satisfaz o Tile >= Win.
game_won(Board) :-
    length(Board, N),                 % o tamanho decide a peça de vitória
    win_tile(N, Win),
    member(Row, Board),               % alguma linha...
    member(Tile, Row),                % ...tem alguma casa...
    Tile >= Win,                      % ...com peça grande o bastante?
    !.                                % achou uma: não precisa procurar outras

%  win_tile(?N, ?Win): peça de vitória por tamanho. 2048 é inalcançável no 3×3.
%  São só fatos: a tabela do contrato escrita como relação.
win_tile(3, 256).
win_tile(4, 2048).
win_tile(5, 4096).
win_tile(6, 8192).

%! can_move(+Board, ?Dir) is nondet.
%  Verdadeiro se jogar Dir muda o tabuleiro. Com Dir livre, o member/2 tenta as
%  quatro direções por backtracking e devolve só as que mudam alguma coisa.
can_move(Board, Dir) :-
    member(Dir, [left, right, up, down]),
    move(Board, Dir, NewBoard, _),
    NewBoard \== Board.               % o move/4 devolve o mesmo tabuleiro se nada muda

%! available_moves(+Board, -Dirs) is det.
%  Dirs são as direções que mudam o tabuleiro, na ordem left, right, up, down.
%  O findall/3 junta numa lista todas as respostas de can_move/2.
%  Ex.: [[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]] -> [left, right, down].
available_moves(Board, Dirs) :-
    findall(Dir, can_move(Board, Dir), Dirs).

%! game_lost(+Board) is semidet.
%  Perdeu quando não há casa vazia e nenhuma direção muda o tabuleiro (sem par
%  igual vizinho na linha ou na coluna). As duas condições usam negação por
%  falha: \+ Objetivo é verdadeiro quando o Prolog NÃO consegue provar Objetivo.
%  A casa vazia vem primeiro porque é a mais barata e já decide a maioria das
%  jogadas; ela também impede que o tabuleiro todo vazio conte como derrota.
game_lost(Board) :-
    \+ ( member(Row, Board), member(0, Row) ),   % não existe casa vazia...
    \+ can_move(Board, _).                       % ...nem direção que mude algo

%! move_trace(+Board, +Dir, -NewBoard, -Score, -Moves) is det.
%  Igual ao move/4, mas também conta o caminho de cada peça (#8), para a tela
%  deslizar as peças em vez de teletransportá-las. Moves tem um item por peça
%  do Board, na forma [LinhaDe, ColunaDe, LinhaPara, ColunaPara, Fundiu], com
%  linhas e colunas a partir de 0 e Fundiu = true se ela entrou numa fusão.
%  NewBoard e Score vêm do próprio move/4: o caminho só descreve o que ele fez.
%  Ex.: [[2,2,0],[0,0,0],[0,0,0]], left ->
%       Moves = [[0,0,0,0,true], [0,1,0,0,true]].
move_trace(Board, Dir, NewBoard, Score, Moves) :-
    move(Board, Dir, NewBoard, Score),
    positions(Board, Pos),                       % [[0-0, 0-1, ...], ...]
    maplist(maplist(cell), Board, Pos, Cells),   % cada casa vira Valor-Linha-Coluna
    orient(Dir, Cells, Rows),                    % a jogada vira "esquerda"
    orient(Dir, Pos, Dests),                     % e as casas de destino também
    maplist(trace_row, Rows, Dests, RowMoves),
    append(RowMoves, Moves).

%  orient(+Dir, ?Board, ?Rows): gira o tabuleiro para a jogada virar "esquerda",
%  como o move_dir/4 faz. Serve para qualquer conteúdo de casa.
orient(left, Board, Board).
orient(right, Board, Rows) :- mirror(Board, Rows).
orient(up, Board, Rows) :- transpose_board(Board, Rows).
orient(down, Board, Rows) :- transpose_board(Board, Cols), mirror(Cols, Rows).

%  positions(+Board, -Pos): a casa de cada posição, como R-C.
positions(Board, Pos) :-
    length(Board, N),
    Last is N - 1,
    findall(Row, ( between(0, Last, R),
                   findall(R-C, between(0, Last, C), Row) ), Pos).

cell(Value, R-C, Value-R-C).

%  trace_row(+Row, +Dests, -Moves): o slide_left contado peça por peça. As peças
%  ocupam as casas de destino na ordem; um par igual divide a mesma casa.
trace_row(Row, Dests, Moves) :-
    exclude(empty_cell, Row, Tiles),
    trace_merge(Tiles, Dests, Moves).

empty_cell(0-_-_).

trace_merge([], _, []).
trace_merge([X-R1-C1, X-R2-C2|T], [R-C|Dests], [[R1,C1,R,C,true], [R2,C2,R,C,true]|Ms]) :-
    !,                                % o mesmo par que o merge/3 funde
    trace_merge(T, Dests, Ms).
trace_merge([_-R1-C1|T], [R-C|Dests], [[R1,C1,R,C,false]|Ms]) :-
    trace_merge(T, Dests, Ms).

% Reexporta o challenge/4 (#19), que mora em challenge.pl (CLP(FD) e busca), e o
% hint/4 (#5), que mora em hint.pl (expectimax): o Python continua chamando
% game:challenge(...) e game:hint(...), e o contrato não muda. Fica no fim do
% arquivo para não mudar os números de linha que as cenas mostram.
:- use_module(challenge, [challenge/4]).
:- use_module(hint, [hint/4]).
