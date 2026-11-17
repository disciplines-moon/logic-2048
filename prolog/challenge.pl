% Desafios (#19): dado um tabuleiro, chegar a uma peça >= Target em até
% MaxMoves jogadas, SEM peças novas (só deslizar e fundir o que já está lá).
%
% O predicado mistura dois estilos, e cada trecho diz qual é:
%   RESTRIÇÕES (library(clpfd)): declaramos o que uma resposta precisa cumprir
%     (domínios com `in`/`ins`, contas com `#=`, `#=<`, `#>=`). O solver usa
%     isso para cortar casos impossíveis sem simular nenhuma jogada.
%   BUSCA (labeling + backtracking): o efeito de uma jogada é o move/4, que não
%     é uma conta linear. O CLP(FD) não sabe prever o tabuleiro, então quem
%     escolhe as direções é o labeling, tentando uma a uma e voltando atrás.
:- module(challenge, [challenge/4]).

:- use_module(library(clpfd)).
:- use_module(game, [move/4]).

%! challenge(+Board, +Target, +MaxMoves, -Moves) is semidet.
%  Moves é a MENOR lista de direções (left, right, up, down) que deixa alguma
%  peça >= Target, com no máximo MaxMoves jogadas. Jogada que não muda o
%  tabuleiro não conta e nunca entra em Moves. Se o tabuleiro já tem a peça,
%  Moves = []. Sem solução, FALHA (o Python traduz para solvable: false).
%  Entre sequências do mesmo tamanho, vale a primeira na ordem left, right, up,
%  down (a mesma do available_moves/2 e do desempate da dica).
%  Ex.: challenge([[2,2,4,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 8, 2, M) -> M = [left, left].
challenge(Board, Target, MaxMoves, Moves) :-
    must_be(list, Board),             % entradas: precisam vir prontas
    must_be(integer, Target),
    must_be(integer, MaxMoves),
    (   has_tile(Board, Target)       % já venceu: nenhuma jogada é preciso
    ->  Moves = []
    ;   solve(Board, Target, MaxMoves, Moves)
    ).

%  solve(+Board, +Target, +MaxMoves, -Moves): primeiro as restrições, depois a busca.
solve(Board, Target, MaxMoves, Moves) :-
    append(Board, Cells),             % todas as casas numa lista só
    % ---- RESTRIÇÕES ---------------------------------------------------------
    % Sem peças novas, deslizar e fundir não cria nem destrói valor: 2+2 vira 4.
    % A soma das peças é INVARIANTE. Uma peça >= Target precisa de Target <= soma.
    % Se não, falha aqui, antes de qualquer jogada (poda pela soma).
    sum(Cells, #=, Sum),
    Target #=< Sum,
    % Quantas jogadas: de 1 a MaxMoves. Cada jogada no máximo DOBRA a maior peça
    % (uma peça só funde uma vez por jogada), então com Len jogadas ela chega a
    % no máximo Max * 2^Len. Tamanhos curtos demais caem sem simular nada.
    max_list(Cells, Max),
    Len in 1..MaxMoves,
    Max * 2^Len #>= Target,
    % ---- BUSCA --------------------------------------------------------------
    % labeling de Len em ordem crescente: tenta 1 jogada, depois 2, ... (busca
    % em aprofundamento iterativo). A primeira resposta é a MENOR sequência.
    once(( labeling([up], [Len]),
           length(Codes, Len),        % Len variáveis, uma por jogada...
           Codes ins 1..4,            % ...cada uma é uma direção (1..4)
           play(Codes, Board, Target) )),
    maplist(code_dir, Codes, Moves).

%  play(+Codes, +Board, +Target): escolhe cada direção (labeling) e joga com o
%  move/4. As restrições entram de novo a cada passo para podar a árvore.
play([], Board, Target) :-
    has_tile(Board, Target).          % acabaram as jogadas: chegou ao alvo?
play([Code|Codes], Board, Target) :-
    length(Codes, Rest),              % jogadas que sobram depois desta
    append(Board, Cells),
    max_list(Cells, Max),
    Max * 2^(Rest + 1) #>= Target,    % RESTRIÇÃO: ainda dá para chegar? Se não, poda
    labeling([], [Code]),             % BUSCA: tenta 1, 2, 3, 4 por backtracking
    code_dir(Code, Dir),
    move(Board, Dir, Next, _),
    Next \== Board,                   % jogada sem efeito não conta: volta atrás. A menor
                                      % sequência nunca teria uma (tirá-la dá uma menor),
                                      % então isso só poda a busca, sem mudar a resposta.
    play(Codes, Next, Target).

%  code_dir(?Code, ?Dir): o CLP(FD) só trabalha com inteiros, então cada
%  direção é um número. A ordem é a do available_moves/2.
code_dir(1, left).
code_dir(2, right).
code_dir(3, up).
code_dir(4, down).

%  has_tile(+Board, +Target): existe uma peça (casa não vazia) >= Target.
has_tile(Board, Target) :-
    member(Row, Board),
    member(Tile, Row),
    Tile > 0,
    Tile >= Target,
    !.
