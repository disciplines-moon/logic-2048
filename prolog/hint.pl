% Dica (#5): expectimax. O Prolog simula jogadas à frente e sugere a melhor.
%
% Depois de cada jogada nasce uma peça ao acaso (quem sorteia é o Elm, não o
% Prolog). A busca não sabe qual vai nascer, então pensa em TODAS:
%   nó de MÁXIMO (a nossa jogada): fica com a direção de maior valor;
%   nó de SORTEIO (a peça nova):   faz a MÉDIA sobre todas as casas vazias,
%                                  com peça 2 (90%) e peça 4 (10%).
% No fim da busca (profundidade 0), uma heurística dá nota ao tabuleiro.
% Nada aqui é aleatório: o mesmo tabuleiro dá sempre a mesma dica.
:- module(hint, [hint/4, evaluate/2]).

:- use_module(game, [move/4, available_moves/2]).

% Compila as contas (is/2, >/2) direto, sem chamar predicado: a heurística
% roda dezenas de milhares de vezes por dica.
:- set_prolog_flag(optimise, true).

%! hint(+Board, +Depth, -Best, -Scores) is det.
%  Best é a direção de maior valor esperado (ou none, se nenhuma jogada muda o
%  tabuleiro). Scores = [left-V, right-V, ...] só com as direções do
%  available_moves/2, na ordem left, right, up, down, e V arredondado a 2 casas.
%  Depth é quantas jogadas nossas a busca olha à frente: de 1 a 3 (padrão 2, que
%  o Python aplica). O máximo por N (3 se N <= 4, 2 se N >= 5) e a redução para
%  2 com mais de 6 casas vazias são feitos no Python (docs/contrato.md).
%  Empate: vale a primeira na ordem left, right, up, down.
%  Ex.: hint([[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 2, B, S) -> B = left
%       (left e right empatam: os tabuleiros são o espelho um do outro).
%
%  Quantos tabuleiros a busca avalia (folhas da árvore)? Cada nível da busca é
%  uma jogada nossa (até 4 direções) seguida de uma peça nova (E casas vazias ×
%  2 peças possíveis). Então cada nível multiplica o trabalho por até 4 × 2E:
%    profundidade 1:  4 × 2E      4×4 com E = 14:  4 × 28            =       112
%    profundidade 2: (4 × 2E)²                    (4 × 28)²          =    12 544
%    profundidade 3: (4 × 2E)³                    (4 × 28)³          ≈ 1,4 milhão
%  (E cai 1 a cada peça nova, então a conta exata é um pouco menor.) Com E <= 6,
%  a profundidade 3 fica em no máximo (4 × 12)³ ≈ 110 mil folhas: por isso o
%  Python reduz para 2 quando há mais de 6 casas vazias.
hint(Board, Depth, Best, Scores) :-
    must_be(list, Board),             % entradas: precisam vir prontas
    must_be(between(1, 3), Depth),
    available_moves(Board, Dirs),     % só direções que mudam o tabuleiro (#4)
    findall(Dir-V,                    % para cada direção válida, por backtracking...
            ( member(Dir, Dirs),
              move(Board, Dir, Next, _),
              chance_value(Next, Depth, V0),   % ...a média do que pode nascer
              V is round(V0 * 100) / 100.0 ),   % sempre float, 2 casas
            Scores),
    best(Scores, Best).

%  best(+Scores, -Best): a direção de maior valor; none se a lista é vazia.
%  O member/2 percorre na ordem left, right, up, down e o once/1 fica com a
%  primeira que alcança o máximo: assim o empate vai para a primeira da ordem.
best([], none).
best(Scores, Best) :-
    Scores = [_|_],
    aggregate_all(max(V), member(_-V, Scores), Max),
    once(( member(Best-V, Scores), V =:= Max )).

%  max_value(+Board, +Depth, -V): nó de MÁXIMO, a nossa vez de jogar.
%  Sem profundidade sobrando, ou sem jogada possível, avalia o tabuleiro.
max_value(Board, 0, V) :-
    !,
    evaluate(Board, V).
max_value(Board, Depth, V) :-
    findall(Next, child(Board, Next), Children),
    (   Children == []
    ->  evaluate(Board, V)            % perdeu: a nota já sai baixa (0 casas vazias)
    ;   aggregate_all(max(V1),        % o melhor entre os filhos (backtracking no member)
                      ( member(Next, Children),
                        chance_value(Next, Depth, V1) ),
                      V)
    ).

%  child(+Board, -Next): uma jogada que muda o tabuleiro. É o can_move/2 do
%  available_moves/2 (#4), mas guardando o tabuleiro novo: assim cada direção
%  roda o move/4 uma vez só, e não duas.
child(Board, Next) :-
    member(Dir, [left, right, up, down]),
    move(Board, Dir, Next, _),
    Next \== Board.

%  chance_value(+Board, +Depth, -V): nó de SORTEIO, logo depois da nossa jogada.
%  V é a MÉDIA ponderada sobre todas as casas vazias e as duas peças possíveis:
%  cada casa tem a mesma chance (1/E), e a peça é 2 com 90% e 4 com 10%.
%  Depois da peça nova, a vez é nossa de novo, com uma jogada a menos (Depth-1).
chance_value(Board, Depth, V) :-
    empty_cells(Board, Empty),
    length(Empty, E),
    D1 is Depth - 1,
    (   E =:= 0                       % não cabe peça nova (não acontece depois de
    ->  max_value(Board, D1, V)       % uma jogada válida, mas fica seguro)
    ;   aggregate_all(sum(P * V1),
                      ( member(R-C, Empty),
                        spawn(Tile, Prob),
                        P is Prob / E,
                        place(Board, R, C, Tile, Next),
                        max_value(Next, D1, V1) ),
                      V)
    ).

%  spawn(?Tile, ?Prob): a peça que nasce e a chance dela (igual ao sorteio do Elm).
spawn(2, 0.9).
spawn(4, 0.1).

%  empty_cells(+Board, -Cells): as casas vazias como Linha-Coluna, a partir de 0.
empty_cells(Board, Cells) :-
    findall(R-C, ( nth0(R, Board, Row), nth0(C, Row, 0) ), Cells).

%  place(+Board, +R, +C, +Tile, -NewBoard): o mesmo tabuleiro com Tile na casa R-C.
%  O nth0/4 tira (ou põe) um elemento e devolve o resto da lista.
place(Board, R, C, Tile, NewBoard) :-
    nth0(R, Board, Row, OtherRows),
    nth0(C, Row, _, OtherCells),
    nth0(C, NewRow, Tile, OtherCells),
    nth0(R, NewBoard, NewRow, OtherRows).

% ---- HEURÍSTICA -------------------------------------------------------------
% No fim da busca não sabemos quem vai ganhar, então damos uma nota ao
% tabuleiro. Três ideias de quem joga bem 2048:
%   1. CASAS VAZIAS: mais espaço = mais tempo até perder.
%   2. MONOTONICIDADE: cada linha e coluna em ordem (crescendo ou decrescendo)
%      junta as peças grandes num lado e facilita fundir.
%   3. MAIOR PEÇA NO CANTO: a peça grande no meio atrapalha tudo em volta.
% As peças entram como log2 (2 -> 1, 4 -> 2, 1024 -> 10): o 2048 dobra a cada
% fusão, e o log deixa as diferenças em passos iguais.
% A nota não depende de qual lado é "o bom": espelhar ou transpor o tabuleiro
% dá a mesma nota. Por isso left e right empatam no exemplo da issue.

%! evaluate(+Board, -Score) is det.
%  Nota = 10 × casas vazias − 2 × desordem + 4 × log2(maior peça), se no canto.
%  O log2 é calculado uma vez por casa (Logs) e as três ideias usam o resultado.
evaluate(Board, Score) :-
    maplist(maplist(log2), Board, Logs),
    append(Logs, Cells),
    count_empty(Cells, E),
    disorder(Logs, Dis),
    corner_bonus(Logs, Cells, Corner),
    Score is 10 * E - 2 * Dis + 4 * Corner.

%  count_empty(+Cells, -E): quantas casas valem 0 (vazias).
count_empty([], 0).
count_empty([X|Xs], E) :-
    count_empty(Xs, E0),
    ( X =:= 0 -> E is E0 + 1 ; E = E0 ).

%  disorder(+Logs, -D): o quanto as linhas e colunas fogem de uma ordem.
%  Para cada linha (e cada coluna), soma as subidas e as descidas (em log2) e
%  fica com a menor das duas: uma linha toda crescente ou toda decrescente dá 0.
disorder(Logs, D) :-
    game:transpose_board(Logs, Cols), % colunas viram linhas (o mesmo do move/4)
    append(Logs, Cols, Lines),
    foldl(add_line_disorder, Lines, 0, D).

add_line_disorder([X|Xs], D0, D) :-
    steps(Xs, X, 0, 0, Up, Down),
    D is D0 + min(Up, Down).

%  steps(+Rest, +Prev, +Up0, +Down0, -Up, -Down): soma das subidas e das
%  descidas entre vizinhos, com acumuladores (recursão de cauda).
steps([], _, Up, Down, Up, Down).
steps([B|T], A, Up0, Down0, Up, Down) :-
    (   B > A -> Up1 is Up0 + B - A, Down1 = Down0
    ;   Up1 = Up0, Down1 is Down0 + A - B
    ),
    steps(T, B, Up1, Down1, Up, Down).

%  corner_bonus(+Logs, +Cells, -B): log2 da maior peça se ela está num dos 4 cantos.
corner_bonus(Logs, Cells, B) :-
    max_list(Cells, Max),
    Logs = [First|_],
    last(Logs, Last),
    (   member(Row, [First, Last]),
        ( Row = [Max|_] ; last(Row, Max) )
    ->  B = Max
    ;   B = 0
    ).

%  log2(+Tile, -L): 0 para casa vazia, senão o expoente (msb: bit mais alto).
log2(0, 0) :- !.
log2(Tile, L) :- L is msb(Tile).
