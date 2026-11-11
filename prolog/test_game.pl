:- use_module(game).
:- use_module(library(plunit)).

:- begin_tests(fim_de_jogo).

% Testes da #4: vitória, derrota e jogadas válidas.

% Vitória: a peça de vitória depende de N (3->256, 4->2048, 5->4096, 6->8192).
test(vitoria) :-
    game_won([[2048,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]).
test(sem_vitoria, [fail]) :-
    game_won([[2,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]).
test(vitoria_n3) :-
    game_won([[0,0,0],[0,256,0],[0,0,0]]).
test(sem_vitoria_n3, [fail]) :-
    game_won([[128,128,64],[0,0,0],[0,0,0]]).
test(vitoria_n5) :-
    game_won([[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,4096]]).
test(sem_vitoria_n5_com_2048, [fail]) :-
    game_won([[2048,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]]).
test(vitoria_n6) :-
    game_won([[0,0,0,0,0,0],[0,0,0,0,0,0],[0,0,8192,0,0,0],
              [0,0,0,0,0,0],[0,0,0,0,0,0],[0,0,0,0,0,0]]).
test(sem_vitoria_n6_com_4096, [fail]) :-
    game_won([[4096,0,0,0,0,0],[0,0,0,0,0,0],[0,0,0,0,0,0],
              [0,0,0,0,0,0],[0,0,0,0,0,0],[0,0,0,0,0,0]]).
test(sem_vitoria_com_1024, [fail]) :-
    game_won([[1024,1024,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]).
% Vale >=: depois de vencer, o jogo continua e won segue verdadeiro.
test(vitoria_continua_com_peca_maior) :-
    game_won([[4096,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]).
test(vitoria_n3_com_2048) :-
    game_won([[2048,0,0],[0,0,0],[0,0,0]]).
test(vitoria_varias_pecas_uma_resposta) :-
    game_won([[2048,2048,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]).

% Derrota: só sem casa vazia e sem fusão (horizontal e vertical).
test(derrota_contrato) :-
    game_lost([[2,4,2,4],[4,2,4,2],[2,4,2,4],[4,2,4,2]]).
test(derrota_n3) :-
    game_lost([[2,4,8],[8,16,2],[2,4,8]]).
test(derrota_n6) :-
    game_lost([[2,4,2,4,2,4],[4,2,4,2,4,2],[2,4,2,4,2,4],
               [4,2,4,2,4,2],[2,4,2,4,2,4],[4,2,4,2,4,2]]).
test(cheio_com_fusao_horizontal, [fail]) :-
    game_lost([[2,2,4,8],[4,8,16,32],[8,16,32,64],[16,32,64,128]]).
test(cheio_com_fusao_vertical, [fail]) :-
    game_lost([[2,4,8,16],[2,8,16,32],[8,16,32,64],[16,32,64,128]]).
test(uma_casa_vazia, [fail]) :-
    game_lost([[2,4,2,4],[4,2,4,2],[2,4,0,4],[4,2,4,2]]).
test(vazio_nao_perde, [fail]) :-
    game_lost([[0,0,0],[0,0,0],[0,0,0]]).

% Jogadas válidas: só as direções que mudam o tabuleiro, em ordem fixa.
test(jogadas_exemplo_da_issue) :-
    available_moves([[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], D),
    D == [left, right, down].
test(jogadas_cheio_sem_fusao) :-
    available_moves([[2,4,2,4],[4,2,4,2],[2,4,2,4],[4,2,4,2]], D),
    D == [].
test(jogadas_cheio_com_fusao_horizontal) :-
    available_moves([[2,2,4,8],[4,8,16,32],[8,16,32,64],[16,32,64,128]], D),
    D == [left, right].
test(jogadas_cheio_com_fusao_vertical) :-
    available_moves([[2,4,8,16],[2,8,16,32],[8,16,32,64],[16,32,64,128]], D),
    D == [up, down].
test(jogadas_vazio) :-
    available_moves([[0,0,0],[0,0,0],[0,0,0]], D),
    D == [].
test(jogadas_todas) :-
    available_moves([[0,0,0,0],[0,2,0,0],[0,0,0,0],[0,0,0,0]], D),
    D == [left, right, up, down].
test(jogadas_n3) :-
    available_moves([[2,0,0],[0,0,0],[0,0,0]], D),
    D == [right, down].
test(jogadas_n5) :-
    available_moves([[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[2,4,8,16,32]], D),
    D == [up].
test(jogadas_n6) :-
    available_moves([[2,4,2,4,2,4],[4,2,4,2,4,2],[2,4,2,4,2,4],
                     [4,2,4,2,4,2],[2,4,2,4,2,4],[4,2,4,2,4,8]], D),
    D == [].
test(jogadas_tabuleiro_livre, [error(instantiation_error)]) :-
    available_moves(_, _).

% Os tabuleiros da cena da #4 (web/src/Cenas/Issue04.elm) são escritos à mão.
% Este teste garante que eles fazem o que a cena diz.
test(cena_issue04) :-
    Ex = [[2,2,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],
    move(Ex, left, [[4,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], _),
    move(Ex, right, [[0,0,0,4],[0,0,0,0],[0,0,0,0],[0,0,0,0]], _),
    move(Ex, up, Ex, _),
    move(Ex, down, [[0,0,0,0],[0,0,0,0],[0,0,0,0],[2,2,0,0]], _),
    game_won([[0,0,0],[0,256,0],[0,0,0]]),
    game_won([[4096,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]),
    % Quase perdido: só up e down mudam o tabuleiro, e depois de qualquer uma
    % delas, com qualquer peça sorteada (2 ou 4), o jogo está perdido.
    QuasePerdido = [[128,8,32,64],[8,64,16,32],[64,32,8,128],[64,16,128,64]],
    available_moves(QuasePerdido, [up, down]),
    \+ game_lost(QuasePerdido),
    forall(( member(D, [up, down]), move(QuasePerdido, D, Depois, _),
             com_peca_nova(Depois, ComPeca) ),
           ( \+ game_lost(Depois), game_lost(ComPeca) )),
    % Quase vencido: ainda não venceu, e A (left) funde e vence na mesma resposta.
    QuaseVencido = [[1024,1024,0,0],[4,8,2,0],[0,0,0,0],[0,0,0,0]],
    \+ game_won(QuaseVencido),
    move(QuaseVencido, left, V4, _),
    game_won(V4),
    \+ game_won([[128,128,0],[4,8,0],[0,0,0]]),
    move([[128,128,0],[4,8,0],[0,0,0]], left, V3, _),
    V3 == [[256,0,0],[4,8,0],[0,0,0]],
    game_won(V3).

% com_peca_nova(+Board, -ComPeca): coloca 2 ou 4 numa casa vazia, como o sorteio
% do Elm. No backtracking, devolve todas as casas e os dois valores.
com_peca_nova(Board, ComPeca) :-
    append(Board, Casas),
    nth0(K, Casas, 0, Resto),
    member(V, [2, 4]),
    nth0(K, Novas, V, Resto),
    length(Board, N),
    linhas(Novas, N, ComPeca).

linhas([], _, []).
linhas(Casas, N, [Linha|Linhas]) :-
    length(Linha, N),
    append(Linha, Resto, Casas),
    linhas(Resto, N, Linhas).

:- end_tests(fim_de_jogo).

% Propriedades da #4 em tabuleiros sorteados: 400 com casas vazias e 400
% cheios (100 de cada por N, 3 a 6). Os cheios usam poucas peças diferentes
% para aparecerem tabuleiros perdidos e quase perdidos.
:- begin_tests(fim_de_jogo_propriedades).

tabuleiros(Boards) :-
    set_random(seed(4)),
    findall(B, ( between(3, 6, N), between(1, 100, _),
                 member(Pecas, [[0,0,2,4,8,16], [2,4,8,16,32,64]]),
                 sorteado(N, Pecas, B) ),
            Boards).

sorteado(N, Pecas, B) :-
    length(B, N),
    maplist([Linha]>>(length(Linha, N), maplist([V]>>random_member(V, Pecas), Linha)), B).

% Definição da derrota sem usar o move/4: nenhum 0 e nenhum vizinho igual
% (na linha ou na coluna, olhando a casa da direita e a de baixo).
sem_vazio_e_sem_par(B) :-
    \+ ( member(L, B), member(0, L) ),
    length(B, N), Max is N - 1,
    \+ ( between(0, Max, I), between(0, Max, J),
         nth0(I, B, L), nth0(J, L, V),
         ( J < Max, J1 is J + 1, nth0(J1, L, V)
         ; I < Max, I1 is I + 1, nth0(I1, B, L1), nth0(J, L1, V) ) ).

test(derrota_bate_com_a_definicao) :-
    tabuleiros(Bs),
    forall(member(B, Bs),
           ( game_lost(B) -> sem_vazio_e_sem_par(B) ; \+ sem_vazio_e_sem_par(B) )).

test(derrota_quando_nao_ha_jogadas) :-
    tabuleiros(Bs),
    forall(member(B, Bs),
           ( available_moves(B, Ds), ( game_lost(B) -> Ds == [] ; Ds \== [] ) )).

test(jogadas_mudam_o_tabuleiro) :-
    tabuleiros(Bs),
    forall(( member(B, Bs), member(D, [left,right,up,down]) ),
           ( available_moves(B, Ds), move(B, D, B2, _),
             ( memberchk(D, Ds) -> B2 \== B ; B2 == B ) )).

% A amostra tem os dois casos: tabuleiros perdidos e não perdidos.
test(amostra_tem_derrotas) :-
    tabuleiros(Bs),
    include(game_lost, Bs, Perdidos),
    length(Perdidos, P), length(Bs, T),
    P > 0, P < T.

test(sempre_deterministico) :-
    tabuleiros(Bs),
    forall(member(B, Bs),
           ( call_cleanup(available_moves(B, _), Det = true), Det == true )).

:- end_tests(fim_de_jogo_propriedades).

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

% Testes da #3. Os tabuleiros esperados foram calculados à mão, coluna por
% coluna, e não com o próprio move/4. Como no slide_left, o plunit avisa se
% algum caso deixar ponto de escolha sobrando.
:- begin_tests(move).

% Os dois exemplos do contrato (issue #3 e docs/contrato.md).
test(contrato_left) :-
    move([[2,0,0,2],[0,0,0,0],[0,4,0,0],[0,0,0,0]], left, B, S),
    B == [[4,0,0,0],[0,0,0,0],[4,0,0,0],[0,0,0,0]], S == 4.
test(contrato_up) :-
    move([[2,0,0,2],[0,0,0,0],[0,4,0,0],[0,0,0,0]], up, B, S),
    B == [[2,4,0,2],[0,0,0,0],[0,0,0,0],[0,0,0,0]], S == 0.
% O mesmo tabuleiro nas outras duas direções.
test(contrato_right) :-
    move([[2,0,0,2],[0,0,0,0],[0,4,0,0],[0,0,0,0]], right, B, S),
    B == [[0,0,0,4],[0,0,0,0],[0,0,0,4],[0,0,0,0]], S == 4.
test(contrato_down) :-
    move([[2,0,0,2],[0,0,0,0],[0,4,0,0],[0,0,0,0]], down, B, S),
    B == [[0,0,0,0],[0,0,0,0],[0,0,0,0],[2,4,0,2]], S == 0.

% N = 3: as quatro direções no mesmo tabuleiro.
test(n3_left) :-
    move([[2,2,4],[0,4,4],[2,0,2]], left, B, S),
    B == [[4,4,0],[8,0,0],[4,0,0]], S == 16.
test(n3_right) :-
    move([[2,2,4],[0,4,4],[2,0,2]], right, B, S),
    B == [[0,4,4],[0,0,8],[0,0,4]], S == 16.
test(n3_up) :-
    move([[2,2,4],[0,4,4],[2,0,2]], up, B, S),
    B == [[4,2,8],[0,4,2],[0,0,0]], S == 12.
test(n3_down) :-
    move([[2,2,4],[0,4,4],[2,0,2]], down, B, S),
    B == [[0,0,0],[0,2,8],[4,4,2]], S == 12.

% N = 5. Para cima e para baixo nada funde, mas as peças andam: Score = 0
% não quer dizer que o tabuleiro ficou igual.
test(n5_left) :-
    move([[2,2,2,2,2],[0,0,0,0,0],[4,0,4,0,8],[0,0,0,0,2],[8,8,0,0,0]], left, B, S),
    B == [[4,4,2,0,0],[0,0,0,0,0],[8,8,0,0,0],[2,0,0,0,0],[16,0,0,0,0]], S == 32.
test(n5_right) :-
    move([[2,2,2,2,2],[0,0,0,0,0],[4,0,4,0,8],[0,0,0,0,2],[8,8,0,0,0]], right, B, S),
    B == [[0,0,2,4,4],[0,0,0,0,0],[0,0,0,8,8],[0,0,0,0,2],[0,0,0,0,16]], S == 32.
test(n5_up) :-
    move([[2,2,2,2,2],[0,0,0,0,0],[4,0,4,0,8],[0,0,0,0,2],[8,8,0,0,0]], up, B, S),
    B == [[2,2,2,2,2],[4,8,4,0,8],[8,0,0,0,2],[0,0,0,0,0],[0,0,0,0,0]], S == 0.
test(n5_down) :-
    move([[2,2,2,2,2],[0,0,0,0,0],[4,0,4,0,8],[0,0,0,0,2],[8,8,0,0,0]], down, B, S),
    B == [[0,0,0,0,0],[0,0,0,0,0],[2,0,0,0,2],[4,2,2,0,8],[8,8,4,2,2]], S == 0.

% N = 6.
test(n6_left) :-
    move([[2,2,4,4,8,8],[2,0,0,0,0,2],[4,4,4,0,0,0],[0,0,0,0,0,0],[2,4,8,16,32,64],[2,0,0,0,0,0]], left, B, S),
    B == [[4,8,16,0,0,0],[4,0,0,0,0,0],[8,4,0,0,0,0],[0,0,0,0,0,0],[2,4,8,16,32,64],[2,0,0,0,0,0]],
    S == 40.
test(n6_right) :-
    move([[2,2,4,4,8,8],[2,0,0,0,0,2],[4,4,4,0,0,0],[0,0,0,0,0,0],[2,4,8,16,32,64],[2,0,0,0,0,0]], right, B, S),
    B == [[0,0,0,4,8,16],[0,0,0,0,0,4],[0,0,0,0,4,8],[0,0,0,0,0,0],[2,4,8,16,32,64],[0,0,0,0,0,2]],
    S == 40.
test(n6_up) :-
    move([[2,2,4,4,8,8],[2,0,0,0,0,2],[4,4,4,0,0,0],[0,0,0,0,0,0],[2,4,8,16,32,64],[2,0,0,0,0,0]], up, B, S),
    B == [[4,2,8,4,8,8],[4,8,8,16,32,2],[4,0,0,0,0,64],[0,0,0,0,0,0],[0,0,0,0,0,0],[0,0,0,0,0,0]],
    S == 24.
test(n6_down) :-
    move([[2,2,4,4,8,8],[2,0,0,0,0,2],[4,4,4,0,0,0],[0,0,0,0,0,0],[2,4,8,16,32,64],[2,0,0,0,0,0]], down, B, S),
    B == [[0,0,0,0,0,0],[0,0,0,0,0,0],[0,0,0,0,0,0],[4,0,0,0,0,8],[4,2,8,4,8,2],[4,8,8,16,32,64]],
    S == 24.

% Três iguais em fila: funde o par do lado para onde as peças vão.
test(tres_iguais_left) :-
    move([[2,2,2],[0,0,0],[0,0,0]], left, B, S), B == [[4,2,0],[0,0,0],[0,0,0]], S == 4.
test(tres_iguais_right) :-
    move([[2,2,2],[0,0,0],[0,0,0]], right, B, S), B == [[0,2,4],[0,0,0],[0,0,0]], S == 4.
test(tres_iguais_up) :-
    move([[2,0,0],[2,0,0],[2,0,0]], up, B, S), B == [[4,0,0],[2,0,0],[0,0,0]], S == 4.
test(tres_iguais_down) :-
    move([[2,0,0],[2,0,0],[2,0,0]], down, B, S), B == [[0,0,0],[2,0,0],[4,0,0]], S == 4.

% Cada peça funde uma vez só também nas colunas: [2,2,2,2] vira [4,4], não [8].
test(coluna_funde_uma_vez) :-
    move([[2,0,0,0],[2,0,0,0],[2,0,0,0],[2,0,0,0]], down, B, S),
    B == [[0,0,0,0],[0,0,0,0],[4,0,0,0],[4,0,0,0]], S == 8.

% Score é a soma dos pontos de TODAS as linhas: 4 + 16 + 16 + 32 = 68.
test(score_soma_as_linhas) :-
    move([[2,2,0,0],[4,4,4,4],[8,0,8,0],[0,16,16,0]], left, B, S),
    B == [[4,0,0,0],[8,8,0,0],[16,0,0,0],[32,0,0,0]], S == 68.
% O mesmo vale para as colunas: 4 + 8 + 16 = 28.
test(score_soma_as_colunas) :-
    move([[2,4,8],[2,4,8],[0,0,0]], up, B, S),
    B == [[4,8,16],[0,0,0],[0,0,0]], S == 28.

% Se nada muda, devolve o mesmo tabuleiro com Score = 0.
test(nada_muda_tabuleiro_vazio, [forall(member(D, [left,right,up,down]))]) :-
    Vazio = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],
    move(Vazio, D, B, S), B == Vazio, S == 0.
test(nada_muda_sem_fusao, [forall(member(D, [left,right,up,down]))]) :-
    Xadrez = [[2,4,2,4],[4,2,4,2],[2,4,2,4],[4,2,4,2]],
    move(Xadrez, D, B, S), B == Xadrez, S == 0.
test(nada_muda_ja_encostado) :-
    Encostado = [[2,4,0],[8,0,0],[0,0,0]],
    move(Encostado, left, B, S), B == Encostado, S == 0.
% ...mas o mesmo tabuleiro anda para a direita.
test(encostado_anda_para_o_outro_lado) :-
    move([[2,4,0],[8,0,0],[0,0,0]], right, B, S),
    B == [[0,2,4],[0,0,8],[0,0,0]], S == 0.

% Determinismo: uma resposta por direção, sem ponto de escolha.
test(deterministico, [forall(member(D, [left,right,up,down]))]) :-
    call_cleanup(move([[2,2,0],[0,2,0],[4,0,4]], D, _, _), Det = true),
    Det == true.

% Natureza relacional: com Dir livre, o mesmo predicado lista as 4 direções.
test(direcao_livre_enumera) :-
    findall(D-B-S, move([[2,2,0],[0,0,0],[2,0,0]], D, B, S), Respostas),
    Respostas == [ left-[[4,0,0],[0,0,0],[2,0,0]]-4,
                   right-[[0,0,4],[0,0,0],[0,0,2]]-4,
                   up-[[4,2,0],[0,0,0],[0,0,0]]-4,
                   down-[[0,0,0],[0,0,0],[4,2,0]]-4 ].
% ...inclusive as que não mudam nada: com a peça no canto, left e up devolvem o
% mesmo tabuleiro. Para achar só as jogadas válidas, é preciso comparar (#4).
test(direcao_livre_inclui_as_que_nao_mudam) :-
    B = [[2,0,0],[0,0,0],[0,0,0]],
    findall(D, move(B, D, _, _), Todas),
    findall(D, (move(B, D, NB, _), NB \== B), Validas),
    Todas == [left,right,up,down], Validas == [right,down].
% ...mas não ao contrário: o tabuleiro de entrada precisa vir pronto (+Board),
% porque o slide_left usa is/2, que só calcula com valores conhecidos.
test(tabuleiro_livre, [error(instantiation_error)]) :-
    move(_, left, [[4,0,0],[0,0,0],[0,0,0]], 4).
% Direção que não existe: não há cláusula, então falha.
test(direcao_invalida, [fail]) :-
    move([[2,2,0],[0,0,0],[0,0,0]], diagonal, _, _).

:- end_tests(move).

% Os auxiliares de transposição e reversão (não exportados: game:...).
:- begin_tests(move_auxiliares).

test(transpose_board_3x3) :-
    game:transpose_board([[1,2,3],[4,5,6],[7,8,9]], T), T == [[1,4,7],[2,5,8],[3,6,9]].
test(transpose_board_retangular) :-
    game:transpose_board([[1,2,3],[4,5,6]], T), T == [[1,4],[2,5],[3,6]].
test(transpose_board_vazio) :-
    game:transpose_board([], T), T == [].
test(transpose_board_duas_vezes_desfaz, [forall(between(3, 6, N))]) :-
    numlist(1, N, L), findall(Linha, (member(I, L), maplist([J,V]>>(V is I*10+J), L, Linha)), M),
    game:transpose_board(M, T), game:transpose_board(T, M2), M2 == M.
% Relacional: com a saída conhecida, o transpose_board acha a entrada.
test(transpose_board_ao_contrario) :-
    game:transpose_board(M, [[1,4],[2,5]]), M == [[1,2],[4,5]].
test(mirror) :-
    game:mirror([[2,0,4],[0,8,0]], M), M == [[4,0,2],[0,8,0]].
test(mirror_duas_vezes_desfaz) :-
    B = [[2,0,4,8],[0,0,0,2],[16,8,0,0],[0,4,0,4]],
    game:mirror(B, M), game:mirror(M, B2), B2 == B.
test(slide_rows_soma) :-
    game:slide_rows([[2,2,0],[4,4,4],[0,0,8]], R, S),
    R == [[4,0,0],[8,4,0],[8,0,0]], S == 12.

% Os tabuleiros que a cena da #3 (web/src/Cenas/Issue03.elm) mostra em cada
% etapa são escritos à mão. Este teste garante que eles batem com o Prolog.
test(cena_issue03) :-
    B = [[2,0,2,0],[2,4,0,0],[0,4,0,8],[4,0,0,8]],
    move(B, left, [[4,0,0,0],[2,4,0,0],[4,8,0,0],[4,8,0,0]], 4),
    game:mirror(B, [[0,2,0,2],[0,0,4,2],[8,0,4,0],[8,0,0,4]]),
    game:slide_rows([[0,2,0,2],[0,0,4,2],[8,0,4,0],[8,0,0,4]], [[4,0,0,0],[4,2,0,0],[8,4,0,0],[8,4,0,0]], 4),
    move(B, right, [[0,0,0,4],[0,0,2,4],[0,0,4,8],[0,0,4,8]], 4),
    game:transpose_board(B, T), T == [[2,2,0,4],[0,4,4,0],[2,0,0,0],[0,0,8,8]],
    move(T, left, [[4,4,0,0],[8,0,0,0],[2,0,0,0],[16,0,0,0]], 28),
    move(B, up, [[4,8,2,16],[4,0,0,0],[0,0,0,0],[0,0,0,0]], 28),
    move(T, right, [[0,0,4,4],[0,0,0,8],[0,0,0,2],[0,0,0,16]], 28),
    move(B, down, [[0,0,0,0],[0,0,0,0],[4,0,0,0],[4,8,2,16]], 28).

:- end_tests(move_auxiliares).

% Propriedades conferidas em 400 tabuleiros sorteados (100 por N, 3 a 6) nas
% 4 direções. A semente fixa deixa o teste reproduzível.
:- begin_tests(move_propriedades).

tabuleiros_sorteados(Boards) :-
    set_random(seed(2048)),
    findall(B, (between(3, 6, N), between(1, 100, _), tabuleiro_sorteado(N, B)), Boards).

tabuleiro_sorteado(N, B) :-
    length(B, N),
    maplist([Linha]>>(length(Linha, N), maplist(peca_sorteada, Linha)), B).

peca_sorteada(V) :-
    random_member(V, [0,0,0,2,2,2,4,4,8,16,32]).

pecas(B, Pecas) :- append(B, Todas), exclude(==(0), Todas, Pecas).

% Gira 90 graus no sentido horário, sem usar o transpose_board do game.pl:
% a casa (I, J) do giro é a casa (N-1-J, I) do original.
girar(B, G) :-
    length(B, N), Max is N - 1,
    findall(Linha,
            ( between(0, Max, I),
              findall(V, (between(0, Max, J), K is Max - J, nth0(K, B, L), nth0(I, L, V)), Linha) ),
            G).

test(continua_quadrado) :-
    tabuleiros_sorteados(Bs),
    forall(( member(B, Bs), member(D, [left,right,up,down]) ),
           ( move(B, D, NB, _),
             length(B, N), length(NB, N),
             forall(member(L, NB), length(L, N)) )).

% Fundir não cria nem destrói valor: a soma das peças se mantém.
test(soma_das_pecas_se_mantem) :-
    tabuleiros_sorteados(Bs),
    forall(( member(B, Bs), member(D, [left,right,up,down]) ),
           ( move(B, D, NB, _),
             pecas(B, P0), pecas(NB, P1),
             sum_list(P0, Soma), sum_list(P1, Soma) )).

% Cada fusão junta 2 peças em 1. Score = 0 exatamente quando nada fundiu, e
% cada fusão vale pelo menos 4 pontos (2+2).
test(score_conta_as_fusoes) :-
    tabuleiros_sorteados(Bs),
    forall(( member(B, Bs), member(D, [left,right,up,down]) ),
           ( move(B, D, NB, S),
             pecas(B, P0), pecas(NB, P1),
             length(P0, Antes), length(P1, Depois),
             Fusoes is Antes - Depois,
             ( Fusoes =:= 0 -> S =:= 0 ; S >= 4 * Fusoes ) )).

% Depois de mover, as peças ficam encostadas no lado escolhido: não sobra
% casa vazia antes de uma peça.
test(pecas_ficam_encostadas) :-
    tabuleiros_sorteados(Bs),
    forall(( member(B, Bs), member(D, [left,right,up,down]) ),
           ( move(B, D, NB, _),
             linhas_na_direcao(D, NB, Linhas),
             forall(member(L, Linhas), encostada(L)) )).

linhas_na_direcao(left, B, B).
linhas_na_direcao(right, B, Ls) :- maplist(reverse, B, Ls).
linhas_na_direcao(up, B, Ls) :- girar(B, G), maplist(reverse, G, Ls).  % colunas de cima para baixo
linhas_na_direcao(down, B, Ls) :- girar(B, Ls).                        % colunas de baixo para cima

encostada(L) :- append(Pecas, Zeros, L), maplist(\==(0), Pecas), maplist(==(0), Zeros), !.

% Girar o tabuleiro e mover é o mesmo que mover e girar, trocando a direção
% (esquerda vira cima, cima vira direita...). O giro não usa o transpose_board do
% game.pl, então isto confere as quatro direções umas contra as outras.
test(giro_troca_a_direcao) :-
    tabuleiros_sorteados(Bs),
    forall(( member(B, Bs), member(D-DG, [left-up, up-right, right-down, down-left]) ),
           ( move(B, D, NB, S), girar(NB, Esperado),
             girar(B, G), move(G, DG, NG, SG),
             NG == Esperado, SG == S )).

% Se nada fundiu, mover de novo na mesma direção não muda mais nada.
test(sem_fusao_estabiliza) :-
    tabuleiros_sorteados(Bs),
    forall(( member(B, Bs), member(D, [left,right,up,down]), move(B, D, NB, 0) ),
           ( move(NB, D, NB2, S2), NB2 == NB, S2 == 0 )).

test(sempre_deterministico) :-
    tabuleiros_sorteados(Bs),
    forall(( member(B, Bs), member(D, [left,right,up,down]) ),
           ( call_cleanup(move(B, D, _, _), Det = true), Det == true )).

:- end_tests(move_propriedades).
