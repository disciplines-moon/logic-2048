module GameTest exposing (suite)

import Api exposing (Direction(..))
import Dict
import Expect
import Fuzz
import Game exposing (Msg(..), PieceKind(..), Status(..), Theme(..))
import Game.Assist as Assist
import Game.Effects as Effects exposing (Effect(..), Sound(..))
import Game.View
import Json.Decode as D
import Random
import Test exposing (Test, describe, fuzz, test)


{-| Jogo 4×4 já com as duas peças iniciais, pronto para jogar.
-}
started : Game.Model
started =
    let
        ( model, _ ) =
            Game.init Effects.defaultPrefs
    in
    Game.update (Spawned model.board [ tile 0 0 2, tile 0 1 2 ]) model
        |> Tuple.first


tile : Int -> Int -> Int -> Game.Tile
tile r c v =
    { row = r, col = c, value = v }


response : Game.Board -> Int -> Bool -> Api.MoveResponse
response board score moved =
    { board = board, score = score, moved = moved, won = False, lost = False, moves = [] }


movedBoard : Game.Board
movedBoard =
    [ [ 4, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


{-| Manda a resposta de uma jogada pedida a partir do tabuleiro atual. Como no
jogo de verdade, a resposta chega com o jogo esperando (`waiting`), como depois
de uma tecla.
-}
answer : Api.MoveResponse -> Game.Model -> Game.Model
answer res model =
    Game.update (GotMove model.board (Ok res)) { model | waiting = True } |> Tuple.first


{-| Tabuleiro 3×3 quase cheio, como os cenários da apresentação (#4).
-}
cenario3 : Game.Board
cenario3 =
    [ [ 2, 4, 8 ], [ 8, 16, 2 ], [ 2, 4, 0 ] ]


nonZero : Game.Board -> List Int
nonZero board =
    List.concat board |> List.filter ((/=) 0)


{-| Uma jogada completa: o Prolog responde que mexeu e o runtime sorteia a peça.
-}
play : Game.Board -> Int -> Game.Tile -> Game.Model -> Game.Model
play board score spawned model =
    let
        answered =
            answer (response board score True) model
    in
    Game.update (Spawned board [ spawned ]) answered |> Tuple.first


{-| As 3 jogadas do exemplo da issue #7.
-}
first : Game.Model
first =
    play [ [ 4, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ] 4 (tile 3 3 2) started


three : Game.Model
three =
    first
        |> play [ [ 0, 0, 0, 4 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 2 ] ] 0 (tile 0 0 4)
        |> play [ [ 4, 0, 0, 4 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 2 ] ] 0 (tile 2 2 2)


step : Game.Msg -> Game.Model -> Game.Model
step msg model =
    Game.update msg model |> Tuple.first


suite : Test
suite =
    describe "Game"
        [ describe "sorteio"
            [ fuzz Fuzz.int "o jogo começa com exatamente 2 peças (2 ou 4) em casas distintas" <|
                \seed ->
                    let
                        ( tiles, _ ) =
                            Random.step (Game.startTiles 4) (Random.initialSeed seed)

                        board =
                            Game.placeTiles tiles (Game.emptyBoard 4)
                    in
                    Expect.all
                        [ \_ -> Expect.equal 2 (List.length (nonZero board))
                        , \_ -> Expect.equal True (List.all (\v -> v == 2 || v == 4) (nonZero board))
                        ]
                        ()
            , fuzz (Fuzz.intRange 3 6) "funciona em qualquer N de 3 a 6" <|
                \n ->
                    Random.step (Game.startTiles n) (Random.initialSeed n)
                        |> Tuple.first
                        |> (\tiles -> Game.placeTiles tiles (Game.emptyBoard n))
                        |> Expect.all
                            [ List.length >> Expect.equal n
                            , List.all (\row -> List.length row == n) >> Expect.equal True
                            , nonZero >> List.length >> Expect.equal 2
                            ]
            , test "2 sai em ~90% das vezes e 4 em ~10%" <|
                \_ ->
                    let
                        ( values, _ ) =
                            Random.step (Random.list 10000 Game.tileValue) (Random.initialSeed 42)

                        twos =
                            List.length (List.filter ((==) 2) values)
                    in
                    Expect.all
                        [ \_ -> Expect.atLeast 8800 twos
                        , \_ -> Expect.atMost 9200 twos
                        , \_ -> Expect.equal 10000 (List.length (List.filter (\v -> v == 2 || v == 4) values))
                        ]
                        ()
            , fuzz Fuzz.int "a peça nova cai numa casa vazia" <|
                \seed ->
                    let
                        board =
                            [ [ 2, 4, 8 ], [ 16, 0, 32 ], [ 64, 128, 256 ] ]
                    in
                    Random.step (Game.newTile board) (Random.initialSeed seed)
                        |> Tuple.first
                        |> List.map (\t -> ( t.row, t.col ))
                        |> Expect.equal [ ( 1, 1 ) ]
            , test "tabuleiro cheio não recebe peça" <|
                \_ ->
                    Random.step (Game.newTile [ [ 2, 4, 2 ], [ 4, 2, 4 ], [ 2, 4, 2 ] ]) (Random.initialSeed 0)
                        |> Tuple.first
                        |> Expect.equal []
            ]
        , describe "update"
            [ test "jogo novo começa vazio, esperando o sorteio, com score 0" <|
                \_ ->
                    Game.init Effects.defaultPrefs
                        |> Tuple.first
                        |> Expect.all
                            [ .board >> Expect.equal (Game.emptyBoard 4)
                            , .score >> Expect.equal 0
                            , .waiting >> Expect.equal True
                            ]
            , test "as peças sorteadas entram no tabuleiro e liberam o teclado" <|
                \_ ->
                    started
                        |> Expect.all
                            [ .board >> nonZero >> Expect.equal [ 2, 2 ]
                            , .waiting >> Expect.equal False
                            ]
            , test "jogada com moved = true troca o tabuleiro, soma o score e espera a peça nova" <|
                \_ ->
                    started
                        |> answer (response movedBoard 4 True)
                        |> Expect.all
                            [ .board >> Expect.equal movedBoard
                            , .score >> Expect.equal 4
                            , .waiting >> Expect.equal True
                            ]
            , test "jogada com moved = false não sorteia e libera o teclado" <|
                \_ ->
                    started
                        |> answer (response started.board 0 False)
                        |> Expect.all
                            [ .board >> Expect.equal started.board
                            , .waiting >> Expect.equal False
                            ]
            , test "a pontuação acumula o score de cada jogada" <|
                \_ ->
                    let
                        spawn m =
                            Game.update (Spawned m.board [ tile 3 3 2 ]) m |> Tuple.first
                    in
                    started
                        |> answer (response movedBoard 4 True)
                        |> spawn
                        |> answer (response [ [ 8, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 2 ] ] 8 True)
                        |> .score
                        |> Expect.equal 12
            , test "tecla durante a espera é ignorada" <|
                \_ ->
                    let
                        waiting =
                            Game.update (Pressed Left) started |> Tuple.first
                    in
                    Game.update (Pressed Right) waiting
                        |> Tuple.first
                        |> Expect.equal waiting
            , test "resposta de outro tabuleiro (pedida antes do Novo jogo) é descartada" <|
                \_ ->
                    started
                        |> Game.update (GotMove [ [ 8 ] ] (Ok (response movedBoard 4 True)))
                        |> Tuple.first
                        |> Expect.equal started
            , test "won e lost viram o status" <|
                \_ ->
                    Expect.all
                        [ \_ ->
                            answer { board = movedBoard, score = 0, moved = True, won = True, lost = False, moves = [] } started
                                |> .status
                                |> Expect.equal Won
                        , \_ ->
                            answer { board = started.board, score = 0, moved = False, won = False, lost = True, moves = [] } started
                                |> .status
                                |> Expect.equal Lost
                        ]
                        ()
            , test "depois de perder, as teclas não jogam" <|
                \_ ->
                    let
                        lost =
                            answer { board = started.board, score = 0, moved = False, won = False, lost = True, moves = [] } started
                    in
                    Game.update (Pressed Left) lost
                        |> Tuple.first
                        |> Expect.equal lost
            , test "erro de rede mostra mensagem e libera o teclado" <|
                \_ ->
                    { started | waiting = True }
                        |> Game.update (GotMove started.board (Err Api.Network))
                        |> Tuple.first
                        |> Expect.all
                            [ .error >> Expect.equal (Just (Api.errorMessage Api.Network))
                            , .waiting >> Expect.equal False
                            ]
            , test "Novo jogo zera o score e esvazia o tabuleiro do mesmo tamanho" <|
                \_ ->
                    started
                        |> answer (response movedBoard 4 True)
                        |> Game.update NewGame
                        |> Tuple.first
                        |> Expect.all
                            [ .score >> Expect.equal 0
                            , .board >> Expect.equal (Game.emptyBoard 4)
                            , .status >> Expect.equal Playing
                            ]
            , test "trocar o tamanho reinicia o jogo com o N escolhido" <|
                \_ ->
                    started
                        |> Game.update (SizeChosen 6)
                        |> Tuple.first
                        |> Expect.all
                            [ .size >> Expect.equal 6
                            , .board >> Expect.equal (Game.emptyBoard 6)
                            ]
            , test "tamanho fora de 3 a 6 é ignorado" <|
                \_ ->
                    started
                        |> Game.update (SizeChosen 7)
                        |> Tuple.first
                        |> Expect.equal started
            , test "carregar tabuleiro troca o jogo, zera o score e libera o teclado" <|
                \_ ->
                    started
                        |> answer (response movedBoard 4 True)
                        |> Game.update (LoadBoard cenario3)
                        |> Tuple.first
                        |> Expect.all
                            [ .board >> Expect.equal cenario3
                            , .size >> Expect.equal 3
                            , .score >> Expect.equal 0
                            , .status >> Expect.equal Playing
                            , .waiting >> Expect.equal False
                            ]
            , test "carregar tabuleiro depois de perder volta a jogar" <|
                \_ ->
                    answer { board = started.board, score = 0, moved = False, won = False, lost = True, moves = [] } started
                        |> Game.update (LoadBoard cenario3)
                        |> Tuple.first
                        |> .status
                        |> Expect.equal Playing
            , test "carregar tabuleiro descarta a peça sorteada para o tabuleiro anterior" <|
                \_ ->
                    let
                        loaded =
                            started
                                |> answer (response movedBoard 4 True)
                                |> Game.update (LoadBoard cenario3)
                                |> Tuple.first
                    in
                    Game.update (Spawned movedBoard [ tile 1 1 2 ]) loaded
                        |> Tuple.first
                        |> Expect.equal loaded
            , test "recarregar o mesmo tabuleiro descarta a jogada que estava a caminho" <|
                \_ ->
                    let
                        loaded =
                            Game.update (LoadBoard cenario3) started |> Tuple.first

                        reloaded =
                            Game.update (Pressed Up) loaded
                                |> Tuple.first
                                |> Game.update (LoadBoard cenario3)
                                |> Tuple.first
                    in
                    Game.update (GotMove cenario3 (Ok (response [ [ 2, 4, 8 ], [ 8, 16, 4 ], [ 2, 4, 0 ] ] 0 True))) reloaded
                        |> Tuple.first
                        |> Expect.equal reloaded
            , test "carregar tabuleiro com tamanho inválido é ignorado" <|
                \_ ->
                    Expect.all
                        [ \_ -> Game.update (LoadBoard [ [ 2, 4 ], [ 4, 2 ] ]) started |> Tuple.first |> Expect.equal started
                        , \_ -> Game.update (LoadBoard [ [ 2, 4, 2 ], [ 4, 2 ], [ 2, 4, 2 ] ]) started |> Tuple.first |> Expect.equal started
                        ]
                        ()
            ]
        , describe "desfazer (#7)"
            [ test "jogada que mexe guarda o jogo de antes no histórico" <|
                \_ ->
                    (first.history |> List.map .board)
                        |> Expect.equal [ started.board ]
            , test "jogada que não mexe não guarda nada" <|
                \_ ->
                    answer (response started.board 0 False) started
                        |> .history
                        |> Expect.equal []
            , test "3 jogadas e 2 desfazer voltam ao estado após a 1ª, com a peça sorteada" <|
                \_ ->
                    three
                        |> step Undo
                        |> step Undo
                        |> Expect.all
                            [ .board >> Expect.equal first.board
                            , .score >> Expect.equal first.score
                            , .history >> Expect.equal first.history
                            ]
            , test "desfazer sem histórico não muda nada" <|
                \_ -> step Undo started |> Expect.equal started
            , test "desfazer durante a espera do servidor é ignorado" <|
                \_ ->
                    let
                        waiting =
                            step (Pressed Left) first
                    in
                    step Undo waiting |> Expect.equal waiting
            , test "desfazer depois de perder volta a jogar" <|
                \_ ->
                    first
                        |> answer { board = first.board, score = 0, moved = False, won = False, lost = True, moves = [] }
                        |> step Undo
                        |> Expect.all
                            [ .status >> Expect.equal Playing
                            , .board >> Expect.equal started.board
                            ]
            , test "Novo jogo e troca de tamanho zeram o histórico" <|
                \_ ->
                    Expect.all
                        [ \m -> step NewGame m |> .history |> Expect.equal []
                        , \m -> step (SizeChosen 5) m |> .history |> Expect.equal []
                        ]
                        three
            , test "carregar tabuleiro zera o histórico e fecha o replay (#4)" <|
                \_ ->
                    Expect.all
                        [ \m -> step (LoadBoard cenario3) m |> .history |> Expect.equal []
                        , \m -> step (LoadBoard cenario3) m |> step Undo |> .board |> Expect.equal cenario3
                        , \m -> step ReplayStarted m |> step (LoadBoard cenario3) |> .replay |> Expect.equal Nothing
                        ]
                        three
            ]
        , describe "replay (#7)"
            [ test "começa no primeiro estado e avança um por tick até o atual" <|
                \_ ->
                    let
                        replay =
                            step ReplayStarted three
                    in
                    Expect.all
                        [ \m -> Game.shown m |> .board |> Expect.equal started.board
                        , \m -> step ReplayTicked m |> Game.shown |> .board |> Expect.equal first.board
                        , \m -> List.foldl (\_ acc -> step ReplayTicked acc) m (List.range 1 5) |> Game.shown |> .board |> Expect.equal three.board
                        , \m -> List.foldl (\_ acc -> step ReplayTicked acc) m (List.range 1 3) |> .replay |> Maybe.map .playing |> Expect.equal (Just False)
                        ]
                        replay
            , test "o replay não mexe no jogo: ao sair, a tela volta ao estado atual" <|
                \_ ->
                    three
                        |> step ReplayStarted
                        |> step ReplayTicked
                        |> step ReplayClosed
                        |> Expect.equal three
            , test "pausado, o tick não avança; ao retomar, avança" <|
                \_ ->
                    let
                        paused =
                            three |> step ReplayStarted |> step ReplayPaused
                    in
                    Expect.all
                        [ \m -> step ReplayTicked m |> Game.shown |> .board |> Expect.equal started.board
                        , \m -> m |> step ReplayPaused |> step ReplayTicked |> Game.shown |> .board |> Expect.equal first.board
                        ]
                        paused
            , test "a velocidade muda o intervalo do relógio" <|
                \_ ->
                    three
                        |> step ReplayStarted
                        |> step (ReplaySpeed 250)
                        |> .replay
                        |> Maybe.map .interval
                        |> Expect.equal (Just 250)
            , test "durante o replay, teclas e desfazer não mexem no jogo" <|
                \_ ->
                    let
                        replay =
                            step ReplayStarted three
                    in
                    Expect.all
                        [ \m -> Game.update (Pressed Left) m |> Expect.equal ( m, Cmd.none )
                        , \m -> step Undo m |> Expect.equal m
                        ]
                        replay
            , test "no replay, o status é o da jogada na tela, não o do jogo atual" <|
                \_ ->
                    three
                        |> answer { board = three.board, score = 0, moved = False, won = False, lost = True, moves = [] }
                        |> step ReplayStarted
                        |> Game.shown
                        |> .status
                        |> Expect.equal Playing
            , describe "trocar o tamanho no meio do replay (bug relatado no PR #35)"
                (let
                    -- Replay tocando de uma partida 4×4 e, no meio, troca para 6×6.
                    trocado =
                        three |> step ReplayStarted |> step ReplayTicked |> step (SizeChosen 6)

                    seis =
                        [ tile 4 1 2, tile 2 2 4 ]

                    -- O runtime sorteia as duas peças do 6×6.
                    comecado =
                        step (Spawned trocado.board seis) trocado

                    pecas m =
                        List.filter (not << .ghost) m.pieces
                 in
                 [ test "o replay fecha e o histórico da partida passada some" <|
                    \_ ->
                        Expect.all
                            [ .replay >> Expect.equal Nothing
                            , .history >> Expect.equal []
                            , .size >> Expect.equal 6
                            , .board >> List.length >> Expect.equal 6
                            ]
                            trocado
                 , test "um tique atrasado do relógio do replay não mexe no 6×6" <|
                    \_ -> comecado |> step ReplayTicked |> Expect.equal comecado
                 , test "o sorteio atrasado da partida passada é descartado" <|
                    \_ ->
                        comecado
                            |> step (Spawned three.board [ tile 0 0 2 ])
                            |> Expect.equal comecado
                 , test "a resposta atrasada de uma jogada da partida passada é descartada" <|
                    \_ ->
                        { comecado | waiting = True }
                            |> step (GotMove three.board (Ok (response movedBoard 4 True)))
                            |> .board
                            |> Expect.equal comecado.board
                 , test "o 6×6 começa com duas peças, cada uma numa casa" <|
                    \_ ->
                        Expect.all
                            [ pecas >> List.length >> Expect.equal 2
                            , pecas >> List.map (\pc -> ( pc.row, pc.col )) >> List.sort >> Expect.equal [ ( 2, 2 ), ( 4, 1 ) ]
                            , \m -> Game.shown m |> .board |> nonZero |> List.sort |> Expect.equal [ 2, 4 ]
                            ]
                            comecado
                 , test "um replay novo no 6×6 só mostra jogadas do 6×6" <|
                    \_ ->
                        comecado
                            |> play
                                (List.repeat 6 (List.repeat 6 0)
                                    |> List.indexedMap
                                        (\r row ->
                                            if r == 4 then
                                                [ 2, 0, 0, 0, 0, 0 ]

                                            else if r == 2 then
                                                [ 4, 0, 0, 0, 0, 0 ]

                                            else
                                                row
                                        )
                                )
                                0
                                (tile 0 5 2)
                            |> step ReplayStarted
                            |> Game.shown
                            |> .board
                            |> List.length
                            |> Expect.equal 6
                 ]
                )
            , test "sem jogadas não há replay" <|
                \_ -> step ReplayStarted started |> .replay |> Expect.equal Nothing
            ]
        , describe "swipe"
            [ test "arrasto para a esquerda" <|
                \_ -> Game.swipeDirection ( 200, 100 ) ( 100, 110 ) |> Expect.equal (Just Left)
            , test "arrasto para baixo" <|
                \_ -> Game.swipeDirection ( 100, 100 ) ( 110, 220 ) |> Expect.equal (Just Down)
            , test "toque curto não é swipe" <|
                \_ -> Game.swipeDirection ( 100, 100 ) ( 110, 105 ) |> Expect.equal Nothing
            ]
        , describe "tela (#8)"
            [ test "as peças sorteadas no início nascem com id, vaga e aparecem (Born)" <|
                \_ ->
                    started.pieces
                        |> List.map (\p -> ( p.id, ( p.row, p.col, p.value ), ( p.kind, p.slot ) ))
                        |> Expect.equal [ ( 0, ( 0, 0, 2 ), ( Born, 0 ) ), ( 1, ( 0, 1, 2 ), ( Born, 1 ) ) ]
            , test "o caminho do Prolog leva cada peça para a casa nova, com o mesmo id" <|
                \_ ->
                    mergedTwos
                        |> .pieces
                        |> List.map (\p -> ( p.id, ( p.row, p.col, p.value ), ( p.kind, p.ghost ) ))
                        |> Expect.equal
                            [ ( 0, ( 0, 0, 2 ), ( Born, True ) )
                            , ( 1, ( 0, 0, 2 ), ( Born, True ) )
                            , ( 2, ( 0, 0, 4 ), ( Merged, False ) )
                            ]
            , test "a entrada de uma peça nunca muda: a animação não é cortada nem recomeça" <|
                \_ ->
                    started
                        |> answer
                            { board = [ [ 0, 0, 2, 2 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
                            , score = 0
                            , moved = True
                            , won = False
                            , lost = False
                            , moves = [ move ( 0, 0 ) ( 0, 2 ) False, move ( 0, 1 ) ( 0, 3 ) False ]
                            }
                        |> .pieces
                        |> List.map (\p -> ( p.id, p.col, p.kind ))
                        |> Expect.equal [ ( 0, 2, Born ), ( 1, 3, Born ) ]
            , test "cada peça mantém a sua vaga; a sorteada pega a menor vaga livre" <|
                \_ ->
                    mergedTwos
                        |> step (Spawned movedBoard [ tile 3 3 2 ])
                        |> .pieces
                        |> List.map (\p -> ( p.id, p.slot ))
                        |> Expect.equal [ ( 0, 0 ), ( 1, 1 ), ( 2, 2 ), ( 3, 3 ) ]
            , test "a fantasma continua na tela nas duas jogadas seguintes e sai na terceira" <|
                \_ ->
                    let
                        ghosts m =
                            m.pieces |> List.filter .ghost |> List.length

                        stay m =
                            answer { board = m.board, score = 0, moved = False, won = False, lost = False, moves = List.map (\p -> move ( p.row, p.col ) ( p.row, p.col ) False) (List.filter (not << .ghost) m.pieces) } m

                        one =
                            stay mergedTwos

                        two =
                            stay one
                    in
                    [ mergedTwos, one, two, stay two ]
                        |> List.map ghosts
                        |> Expect.equal [ 2, 2, 2, 0 ]
            , test "as peças sempre formam o mesmo tabuleiro do jogo" <|
                \_ ->
                    [ started, first, three, mergedTwos ]
                        |> List.map (\m -> Game.piecesBoard m.size m.pieces == m.board)
                        |> Expect.equal [ True, True, True, True ]
            , test "sem caminho na resposta, as peças são refeitas do tabuleiro" <|
                \_ ->
                    answer (response movedBoard 4 True) started
                        |> (\m -> ( Game.piecesBoard 4 m.pieces == m.board, List.map .kind m.pieces ))
                        |> Expect.equal ( True, [ Plain ] )
            , test "caminho que não bate com o tabuleiro: as peças são refeitas" <|
                \_ ->
                    started
                        |> answer
                            { board = movedBoard
                            , score = 4
                            , moved = True
                            , won = False
                            , lost = False
                            , moves = [ move ( 0, 0 ) ( 0, 3 ) False, move ( 0, 1 ) ( 0, 2 ) False ]
                            }
                        |> (\m -> Game.piecesBoard 4 m.pieces == m.board)
                        |> Expect.equal True
            , test "desfazer refaz as peças do tabuleiro anterior, sem animação e sem fantasmas" <|
                \_ ->
                    step Undo first
                        |> (\m -> ( Game.piecesBoard 4 m.pieces == m.board, List.all (\p -> p.kind == Plain && not p.ghost) m.pieces ))
                        |> Expect.equal ( True, True )
            , test "o tema é só mais um campo do Model" <|
                \_ -> step (ThemeChosen Light) started |> .theme |> Expect.equal Light
            , test "Novo jogo e trocar o tamanho mantêm o tema e a câmera lenta" <|
                \_ ->
                    let
                        chosen =
                            started |> step (ThemeChosen Light) |> step SlowMotionToggled
                    in
                    Expect.all
                        [ \m -> step NewGame m |> (\g -> ( g.theme, g.slowMotion, g.pieces )) |> Expect.equal ( Light, True, [] )
                        , \m -> step (SizeChosen 5) m |> (\g -> ( g.theme, g.slowMotion, g.size )) |> Expect.equal ( Light, True, 5 )
                        ]
                        chosen
            , test "classes da peça: cor pelo valor, letra pelos dígitos" <|
                \_ -> Game.View.tileClasses 128 |> Expect.equal [ "tile", "v128", "d3" ]
            , test "de 2048 em diante a peça brilha" <|
                \_ -> Game.View.tileClasses 2048 |> Expect.equal [ "tile", "v2048", "d4", "super" ]
            , test "acima de 8192 vale a mesma cor (vbig), com 5 dígitos" <|
                \_ -> Game.View.tileClasses 16384 |> Expect.equal [ "tile", "vbig", "d5", "super" ]
            , test "casa vazia" <|
                \_ -> Game.View.tileClasses 0 |> Expect.equal [ "tile", "empty" ]
            ]
        , describe "comemorações (#9)"
            [ test "jogada que só desliza toca o som de mover" <|
                \_ ->
                    react (response movedBoard 0 True) started
                        |> Tuple.second
                        |> Expect.equal [ Sound Move ]
            , test "jogada que funde (fez pontos) toca o som de fundir e bate o recorde" <|
                \_ ->
                    react (response movedBoard 4 True) started
                        |> Tuple.second
                        |> Expect.equal [ Sound Merge, SaveBest 4 4 ]
            , test "jogada que não mexe não toca nada" <|
                \_ ->
                    react (response started.board 0 False) started
                        |> Tuple.second
                        |> Expect.equal []
            , test "a vitória do Prolog (won) dispara som, confete e a tela de vitória" <|
                \_ ->
                    react (won (response movedBoard 0 True)) started
                        |> Expect.all
                            [ Tuple.second >> Expect.equal [ Sound Victory, Confetti ]
                            , Tuple.first >> .showWin >> Expect.equal True
                            , Tuple.first >> .celebrated >> Expect.equal True
                            ]
            , test "a comemoração acontece uma única vez por partida, mesmo com won seguindo true" <|
                \_ ->
                    let
                        afterWin =
                            Tuple.first (react (won (response movedBoard 0 True)) started)
                    in
                    react (won (response movedBoard 0 True)) afterWin
                        |> Tuple.second
                        |> Expect.equal [ Sound Move ]
            , test "a derrota toca o som só na primeira vez" <|
                \_ ->
                    let
                        lost =
                            { board = started.board, score = 0, moved = False, won = False, lost = True, moves = [] }

                        once =
                            react lost started
                    in
                    [ Tuple.second once, Tuple.second (react lost (Tuple.first once)) ]
                        |> Expect.equal [ [ Sound Defeat ], [] ]
            , test "sem som: nenhum som, mas o confete e o recorde continuam" <|
                \_ ->
                    react (won (response movedBoard 8 True)) { started | muted = True }
                        |> Tuple.second
                        |> Expect.equal [ Confetti, SaveBest 4 8 ]
            , test "o recorde é guardado por tamanho e só quando é batido" <|
                \_ ->
                    let
                        withBest =
                            { started | best = Dict.fromList [ ( 4, 100 ), ( 3, 7 ) ] }
                    in
                    [ react (response movedBoard 8 True) withBest |> Tuple.second
                    , react (response movedBoard 8 True) { withBest | score = 96 } |> Tuple.second
                    ]
                        |> Expect.equal [ [ Sound Merge ], [ Sound Merge, SaveBest 4 104 ] ]
            , test "tabuleiro pronto (cenário da apresentação) não conta para o recorde" <|
                \_ ->
                    step (LoadBoard [ [ 1024, 1024, 0 ], [ 0, 0, 0 ], [ 0, 0, 0 ] ]) started
                        |> react (response [ [ 2048, 0, 0 ], [ 0, 0, 0 ], [ 0, 0, 0 ] ] 2048 True)
                        |> Tuple.second
                        |> Expect.equal [ Sound Merge ]
            , test "partida em que a IA jogou não conta para o recorde; Novo jogo volta a contar (revisão do PR #35)" <|
                \_ ->
                    let
                        withAi =
                            step (AssistMsg Assist.AiToggled) started

                        aiOff =
                            step (AssistMsg Assist.AiToggled) withAi
                    in
                    [ withAi.ranked
                    , aiOff.ranked
                    , aiOff |> react (response movedBoard 4 True) |> Tuple.second |> List.member (SaveBest 4 4)
                    , (step NewGame aiOff).ranked
                    ]
                        |> Expect.equal [ False, False, False, True ]
            , test "Continuar jogando fecha a tela de vitória; Novo jogo recomeça a comemoração" <|
                \_ ->
                    let
                        afterWin =
                            Tuple.first (react (won (response movedBoard 0 True)) started)
                    in
                    [ step WinDismissed afterWin |> (\m -> ( m.showWin, m.celebrated ))
                    , step NewGame afterWin |> (\m -> ( m.showWin, m.celebrated ))
                    ]
                        |> Expect.equal [ ( False, True ), ( False, False ) ]
            , test "Novo jogo e trocar o tamanho mantêm os recordes e o som desligado" <|
                \_ ->
                    let
                        chosen =
                            { started | best = Dict.fromList [ ( 4, 512 ) ], muted = True }
                    in
                    [ step NewGame chosen, step (SizeChosen 5) chosen ]
                        |> List.map (\m -> ( Dict.toList m.best, m.muted ))
                        |> Expect.equal [ ( [ ( 4, 512 ) ], True ), ( [ ( 4, 512 ) ], True ) ]
            , test "as preferências salvas entram pelas flags" <|
                \_ ->
                    Game.init { best = Dict.fromList [ ( 4, 2048 ) ], theme = "light", muted = True }
                        |> Tuple.first
                        |> (\m -> ( Dict.toList m.best, m.theme, m.muted ))
                        |> Expect.equal ( [ ( 4, 2048 ) ], Light, True )
            , test "o decoder das flags lê o JSON do localStorage" <|
                \_ ->
                    D.decodeString Effects.prefsDecoder "{\"best\":{\"4\":2048,\"6\":12},\"theme\":\"light\",\"muted\":true}"
                        |> Result.map (\p -> ( Dict.toList p.best, p.theme, p.muted ))
                        |> Expect.equal (Ok ( [ ( 4, 2048 ), ( 6, 12 ) ], "light", True ))
            , test "flags vazias ou estragadas viram os valores padrão" <|
                \_ ->
                    [ D.decodeString Effects.prefsDecoder "{}", D.decodeString Effects.prefsDecoder "{\"best\":\"x\",\"muted\":3}" ]
                        |> Expect.equal [ Ok Effects.defaultPrefs, Ok Effects.defaultPrefs ]
            ]
        ]


move : ( Int, Int ) -> ( Int, Int ) -> Bool -> Api.Move
move from to merged =
    { from = from, to = to, merged = merged }


{-| Os dois 2 do início fundem num 4 (resposta com o caminho do Prolog).
-}
mergedTwos : Game.Model
mergedTwos =
    started
        |> answer
            { board = movedBoard
            , score = 4
            , moved = True
            , won = False
            , lost = False
            , moves = [ move ( 0, 0 ) ( 0, 0 ) True, move ( 0, 1 ) ( 0, 0 ) True ]
            }


{-| Uma resposta do Prolog seguida dos efeitos que ela causa (a função pura do #9).
O `answer` passa pelo `update` inteiro, que já aplica as reações; para testar a
função sozinha, os três campos que ela muda voltam ao valor de antes.
-}
react : Api.MoveResponse -> Game.Model -> ( Game.Model, List Effect )
react res model =
    let
        after =
            answer res model
    in
    Game.reactions res model { after | best = model.best, celebrated = model.celebrated, showWin = model.showWin }


won : Api.MoveResponse -> Api.MoveResponse
won res =
    { res | won = True }
