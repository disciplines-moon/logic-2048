:- use_module(game).
:- use_module(library(plunit)).
:- use_module(library(random)).
:- use_module(library(apply)).
:- use_module(library(clpfd)).

% Testes da #19: desafios com CLP(FD) e busca (challenge/4).
% Rode com: swipl -g "load_files('prolog/test_challenge.pl'),run_tests" -t halt

% Os três desafios do projeto. A #11 os serializa em server/data/challenges.json
% (o arquivo é dela). Todos começam com todas as peças menores que o alvo.
% desafio(Id, Titulo, Board, Target, MaxMoves, Solucao)
desafio(c1, "Chegue a 16 em 3 jogadas",
        [[2,2,4,8],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 16, 3,
        [left, left, left]).
desafio(c2, "Junte tudo num 16 em até 5 jogadas",
        [[4,0,2,0],[0,0,0,2],[2,0,0,0],[0,4,0,2]], 16, 5,
        [right, up, up, left]).
desafio(c3, "3×3: chegue a 16 em até 4 jogadas",
        [[2,4,0],[0,2,0],[4,0,4]], 16, 4,
        [left, up, left, up]).

:- begin_tests(challenge).

% Exemplos da issue e do contrato.
test(exemplo_da_issue, M == [left, left]) :-
    challenge([[2,2,4,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 8, 2, M).
test(exemplo_soma_menor_que_alvo, [fail]) :-
    challenge([[2,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 8, 5, _).

% Os três desafios: solução exata (a menor, com desempate left, right, up, down).
test(desafio_c1, M == S) :-
    desafio(c1, _, B, T, Max, S),
    challenge(B, T, Max, M).
test(desafio_c2, M == S) :-
    desafio(c2, _, B, T, Max, S),
    challenge(B, T, Max, M).
test(desafio_c3, M == S) :-
    desafio(c3, _, B, T, Max, S),
    challenge(B, T, Max, M).
% Um a menos que a solução: sem resposta (a solução é mesmo a menor).
test(desafios_sem_folga_falham) :-
    forall(desafio(_, _, B, T, _, S),
           ( length(S, L), L1 is L - 1, \+ challenge(B, T, L1, _) )).
% Regras do JSON: peças menores que o alvo, alvo <= soma, max_moves de 1 a 6.
test(desafios_respeitam_o_contrato) :-
    forall(desafio(_, _, B, T, Max, S),
           ( append(B, Cs), max_list(Cs, Maior), Maior < T,
             sum_list(Cs, Soma), T =< Soma,
             between(1, 6, Max), length(S, L), L =< Max )).
test(tres_desafios_com_ids_distintos) :-
    findall(Id, desafio(Id, _, _, _, _, _), Ids),
    sort(Ids, Unicos),
    length(Unicos, 3).

% Já tem peça >= Target: nenhuma jogada é preciso.
test(ja_tem_a_peca, M == []) :-
    challenge([[8,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 8, 3, M).
test(ja_tem_peca_maior, M == []) :-
    challenge([[0,0,0],[0,32,0],[0,0,0]], 16, 1, M).
test(ja_tem_a_peca_sem_jogada_possivel, M == []) :-
    % cheio e sem fusão: nenhuma direção muda nada, mas já venceu.
    challenge([[2,4,2,4],[4,2,4,2],[2,4,2,4],[4,2,4,16]], 16, 1, M).

% Vence com peça >= Target (não precisa ser igual).
test(vence_com_peca_maior_que_alvo, M == [left]) :-
    challenge([[8,8,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 12, 1, M).
test(alvo_que_nao_e_potencia_de_2, M == [left, left]) :-
    challenge([[2,2,4,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 5, 2, M).

% Sem solução: falha, não devolve lista vazia.
test(sem_jogada_possivel, [fail]) :-
    challenge([[2,4,2,4],[4,2,4,2],[2,4,2,4],[4,2,4,2]], 8, 6, _).
test(soma_basta_mas_jogadas_nao, [fail]) :-
    challenge([[2,0,0,2],[0,4,0,0],[0,0,0,0],[2,0,0,4]], 16, 4, _).
test(peca_isolada_nao_funde, [fail]) :-
    % soma 12 >= 8, mas 4 e 8 nunca viram 8 nem maior além do próprio 8...
    % aqui o alvo 16 exige fundir 8 com 8, e só há um 8.
    challenge([[8,0,0,0],[0,0,0,0],[0,0,0,4],[0,0,0,0]], 16, 6, _).
test(tabuleiro_vazio, [fail]) :-
    challenge([[0,0,0],[0,0,0],[0,0,0]], 2, 6, _).

% MaxMoves é limite superior: o mesmo desafio com folga dá a mesma resposta.
test(folga_nao_muda_a_resposta) :-
    forall(desafio(_, _, B, T, _, S),
           ( length(S, L),
             forall(between(L, 6, Max), challenge(B, T, Max, S)) )).
test(limite_de_uma_jogada, M == [left]) :-
    challenge([[2,2,0],[0,0,0],[0,0,0]], 4, 1, M).
test(todas_as_pecas_juntas, M == [left, left, up, up]) :-
    % soma 32: o 32 só sai se as 16 peças se juntarem, e não dá em 3 jogadas.
    Cheio = [[2,2,2,2],[2,2,2,2],[2,2,2,2],[2,2,2,2]],
    \+ challenge(Cheio, 32, 3, _),
    challenge(Cheio, 32, 6, M).

% Outros tamanhos (N de 3 a 6).
test(n3, M == [left]) :-
    challenge([[0,4,4],[0,0,0],[0,0,0]], 8, 1, M).
test(n5, M == [up, left]) :-
    challenge([[2,0,0,0,0],[0,0,0,0,0],[2,0,0,0,4],[0,0,0,0,0],[0,0,0,0,0]], 8, 3, M).
test(n6, M == [up]) :-
    challenge([[0,0,0,0,0,64],[0,0,0,0,0,0],[0,0,0,0,0,0],
               [0,0,0,0,0,0],[0,0,0,0,0,0],[0,0,0,0,0,64]], 128, 2, M).

% Det: uma resposta, sem ponto de escolha sobrando.
test(deterministico) :-
    forall(desafio(_, _, B, T, Max, _),
           ( call_cleanup(challenge(B, T, Max, _), Det = true), Det == true )).
test(deterministico_ja_vencido) :-
    call_cleanup(challenge([[8,0,0],[0,0,0],[0,0,0]], 8, 2, _), Det = true),
    Det == true.

% Exportado no module(game, [...]) (reexportado do módulo challenge).
test(exportado_por_game) :-
    module_property(game, exports(E)),
    memberchk(challenge/4, E).

% Os tabuleiros da cena (web/src/Cenas/Issue19.elm) são escritos à mão. Este
% teste confere que cada um é o move/4 do anterior, que a soma não muda e que
% a resposta do challenge/4 é a que a cena mostra.
test(cena_issue19) :-
    C1 = [[2,2,4,8],[0,0,0,0],[0,0,0,0],[0,0,0,0]],
    C1a = [[4,4,8,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],
    C1b = [[8,8,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],
    C1c = [[16,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]],
    desafio(c1, _, C1, 16, 3, [left, left, left]),
    passos(C1, [left, left, left], [C1a, C1b, C1c]),
    challenge(C1, 16, 3, [left, left, left]),
    forall(member(B, [C1, C1a, C1b, C1c]), soma(B, 16)),
    C3 = [[2,4,0],[0,2,0],[4,0,4]],
    desafio(c3, _, C3, 16, 4, [left, up, left, up]),
    passos(C3, [left, up, left, up],
           [ [[2,4,0],[2,0,0],[8,0,0]],
             [[4,4,0],[8,0,0],[0,0,0]],
             [[8,0,0],[8,0,0],[0,0,0]],
             [[16,0,0],[0,0,0],[0,0,0]] ]),
    \+ challenge(C3, 16, 3, _),
    % alvo impossível ao vivo: o c2 soma 16, então 32 falha antes da busca
    desafio(c2, _, C2, _, _, _),
    soma(C2, 16),
    \+ challenge(C2, 32, 6, _),
    challenge([[2,2,4,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 8, 2, [left, left]),
    \+ challenge([[2,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]], 8, 5, _).

:- end_tests(challenge).

passos(_, [], []).
passos(B, [D|Ds], [N|Ns]) :-
    move(B, D, N0, _),
    N0 == N,
    passos(N, Ds, Ns).

soma(Board, S) :-
    append(Board, Cs),
    sum_list(Cs, S).


% Poda: as restrições cortam antes da busca. Medimos inferências (passos do
% Prolog), que não dependem da máquina, contra a busca sem poda.
:- begin_tests(challenge_poda).

% Target > soma falha DE IMEDIATO: nenhuma jogada é simulada.
test(soma_falha_de_imediato) :-
    B = [[2,4,2,4,2,4],[4,2,4,2,4,2],[2,4,2,4,2,4],
         [4,2,4,2,4,0],[2,4,2,4,0,0],[4,2,4,0,0,0]],      % soma 90
    sem_estourar(challenge(B, 128, 6, _), 5000, R),
    R == falhou,
    % sem a poda, a mesma pergunta explora milhares de sequências
    inferencias(busca_pura(B, 128, 6, _), Pura),
    Pura > 100000.

% A maior peça no máximo dobra por jogada: 4 só vira 64 com 4 jogadas.
test(crescimento_falha_de_imediato) :-
    Quatros = [[4,4,4,4],[4,4,4,4],[4,4,4,4],[4,4,4,4]],    % soma 64: a soma deixa
    sem_estourar(challenge(Quatros, 64, 3, _), 5000, R),
    R == falhou.
test(crescimento_com_jogadas_suficientes, M == [left, left, up, up]) :-
    challenge([[4,4,4,4],[4,4,4,4],[4,4,4,4],[4,4,4,4]], 64, 4, M).

% Soma suficiente, mas o alvo é alto: a poda pelo crescimento corta no MEIO da
% busca (ramos em que a maior peça já não dobra até o alvo) e explora menos.
test(crescimento_poda_no_meio_da_busca) :-
    B = [[2,4,8,2],[4,2,4,8],[2,8,2,4],[8,2,4,0]],         % soma 64, alvo 64
    sem_estourar(challenge(B, 64, 6, _), 1000000, R),
    R == falhou,
    inferencias(challenge(B, 64, 6, _), Com),
    inferencias(busca_pura(B, 64, 6, _), Sem),
    Com < Sem.

% A busca ingênua (gera e testa) concorda com o challenge/4.
test(gera_e_testa_concorda) :-
    forall(desafio(_, _, B, T, Max, S), gera_e_testa(B, T, Max, S)).

% Honestidade: nos desafios com solução curta, a poda quase não corta nada e
% as restrições custam um pouco. A busca continua sendo o grosso do trabalho.
test(com_solucao_curta_custa_parecido) :-
    forall(desafio(_, _, B, T, Max, _),
           ( inferencias(challenge(B, T, Max, _), Com),
             inferencias(busca_pura(B, T, Max, _), Sem),
             Com =< 3 * Sem )).

:- end_tests(challenge_poda).


% Propriedades em tabuleiros sorteados (semente fixa: sempre os mesmos).
% O oráculo é a busca_pura/4: Prolog puro, sem CLP(FD) e sem poda, que tenta
% todas as sequências do tamanho 1 em diante na mesma ordem. Como a poda só
% descarta ramos sem solução, as duas têm de dar EXATAMENTE a mesma resposta.
:- begin_tests(challenge_propriedades).

test(igual_ao_oraculo) :-
    forall(caso(B, T, Max),
           (   busca_pura(B, T, Max, Esperado)
           ->  challenge(B, T, Max, M), M == Esperado
           ;   \+ challenge(B, T, Max, _)
           )).

% Cada jogada muda o tabuleiro, só o fim alcança o alvo e cabe no limite.
test(solucao_valida) :-
    forall(( caso(B, T, Max), challenge(B, T, Max, M) ),
           ( length(M, L), L =< Max,
             subset(M, [left, right, up, down]),
             aplica(M, B, T) )).

% Nenhuma sequência mais curta chega ao alvo (a resposta é a menor).
test(menor_sequencia) :-
    forall(( caso(B, T, Max), challenge(B, T, Max, M), M \== [] ),
           ( length(M, L), L1 is L - 1,
             \+ ( between(0, L1, K), length(S, K), sequencia(S, B, T) ) )).

% Soma das peças invariante: Target > soma sempre falha.
test(alvo_acima_da_soma_sempre_falha) :-
    forall(( caso(B, _, Max), append(B, Cs), sum_list(Cs, Soma), Soma > 0 ),
           ( Acima is Soma + 2, \+ challenge(B, Acima, Max, _) )).

:- end_tests(challenge_propriedades).


%  busca_pura(+Board, +Target, +Max, -Moves): oráculo sem restrições e sem poda.
busca_pura(Board, Target, _, []) :-
    tem_peca(Board, Target), !.
busca_pura(Board, Target, Max, Moves) :-
    between(1, Max, L),
    length(Moves, L),
    sequencia(Moves, Board, Target),
    !.

sequencia([], Board, Target) :-
    tem_peca(Board, Target).
sequencia([D|Ds], Board, Target) :-
    member(D, [left, right, up, down]),
    move(Board, D, Next, _),
    Next \== Board,
    sequencia(Ds, Next, Target).

tem_peca(Board, Target) :-
    member(Row, Board), member(T, Row), T > 0, T >= Target, !.

%  gera_e_testa(+Board, +Target, +Max, -Moves): a busca mais ingênua, para a
%  comparação da cena. Rotula a lista inteira de direções primeiro e só depois
%  simula, sem poda nenhuma (nem a de jogada sem efeito durante a busca).
gera_e_testa(Board, Target, _, []) :-
    tem_peca(Board, Target), !.
gera_e_testa(Board, Target, Max, Moves) :-
    between(1, Max, L),
    length(Codes, L),
    Codes ins 1..4,
    label(Codes),
    maplist(codigo, Codes, Moves),
    aplica(Moves, Board, Target),
    !.

codigo(C, D) :- nth1(C, [left, right, up, down], D).

%  comparar: imprime a tabela da cena (inferências e tempo). Rode com:
%  swipl -g "load_files('prolog/test_challenge.pl'),comparar" -t halt
comparar :-
    desafio(c2, _, C2, _, _, _),
    ignore(challenge(C2, 16, 5, _)),  % aquece: a primeira chamada do CLP(FD) custa mais
    forall(member(Nome-B-T-Max,
                  [ 'c2: alvo 16, 5 jogadas'-C2-16-5,
                    'c2: alvo 32 (soma 16)'-C2-32-6,
                    'misto: alvo 64, 6 jogadas'-[[2,4,8,2],[4,2,4,8],[2,8,2,4],[8,2,4,0]]-64-6 ]),
           ( format("~w~n", [Nome]),
             forall(member(Rotulo-G, [ 'CLP(FD) + busca'-challenge(B, T, Max, _),
                                       'busca sem poda'-busca_pura(B, T, Max, _),
                                       'gera e testa'-gera_e_testa(B, T, Max, _) ]),
                    ( inferencias(G, I), tempo(G, Ms),
                      format("  ~w~t~18|~t~D~12| inferências ~t~1f~8| ms~n", [Rotulo, I, Ms]) )) )).

tempo(Goal, Ms) :-
    get_time(T0),
    ( \+ \+ call(Goal) -> true ; true ),
    get_time(T1),
    Ms is (T1 - T0) * 1000.

%  aplica(+Moves, +Board, +Target): joga Moves, cada jogada muda o tabuleiro,
%  o alvo só aparece no fim.
aplica([], Board, Target) :-
    tem_peca(Board, Target).
aplica([D|Ds], Board, Target) :-
    \+ tem_peca(Board, Target),
    move(Board, D, Next, _),
    Next \== Board,
    aplica(Ds, Next, Target).

%  caso(-Board, -Target, -Max): 300 desafios sorteados, N de 3 a 5, poucas
%  peças pequenas, Max de 1 a 4. O alvo é a maior peça vezes 2, 4 ou 8, então
%  quase todos começam sem a peça (como os desafios do JSON) e cerca de 1 em 5
%  têm solução. Um em cada 10 usa um alvo qualquer de 2 a 64 (inclui já vencidos).
caso(Board, Target, Max) :-
    set_random(seed(19)),
    between(1, 300, I),
    random_between(3, 5, N),
    tabuleiro(N, Board),
    random_between(1, 4, Max),
    append(Board, Cs),
    max_list(Cs, Maior),
    (   ( I mod 10 =:= 0 ; Maior =:= 0 )
    ->  random_between(2, 64, Target)
    ;   random_between(1, 3, K),
        Target is Maior * 2^K
    ).

tabuleiro(N, Board) :-
    length(Board, N),
    maplist(linha(N), Board).

linha(N, Row) :-
    length(Row, N),
    maplist(casa, Row).

casa(V) :-
    random(X),
    (   X < 0.55 -> V = 0
    ;   X < 0.80 -> V = 2
    ;   X < 0.93 -> V = 4
    ;   V = 8
    ).

%  inferencias(+Goal, -N): quantas inferências o Goal gastou (tenha sucesso ou não).
inferencias(Goal, N) :-
    statistics(inferences, I0),
    ( \+ \+ call(Goal) -> true ; true ),
    statistics(inferences, I1),
    N is I1 - I0.

%  sem_estourar(+Goal, +Limite, -R): R = falhou, ok, ou estourou (passou do limite).
sem_estourar(Goal, Limite, R) :-
    (   call_with_inference_limit(Goal, Limite, R0)
    ->  ( R0 == inference_limit_exceeded -> R = estourou ; R = ok )
    ;   R = falhou
    ).
