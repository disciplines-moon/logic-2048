module GameTest exposing (suite)

import Api exposing (Direction(..))
import Expect
import Fuzz
import Game exposing (Msg(..), Status(..))
import Http
import Random
import Test exposing (Test, describe, fuzz, test)


{-| Jogo 4×4 já com as duas peças iniciais, pronto para jogar.
-}
started : Game.Model
started =
    let
        ( model, _ ) =
            Game.init
    in
    Game.update (Spawned model.board [ tile 0 0 2, tile 0 1 2 ]) model
        |> Tuple.first


tile : Int -> Int -> Int -> Game.Tile
tile r c v =
    { row = r, col = c, value = v }


response : Game.Board -> Int -> Bool -> Api.MoveResponse
response board score moved =
    { board = board, score = score, moved = moved, won = False, lost = False }


movedBoard : Game.Board
movedBoard =
    [ [ 4, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]


{-| Manda a resposta de uma jogada pedida a partir do tabuleiro atual.
-}
answer : Api.MoveResponse -> Game.Model -> Game.Model
answer res model =
    Game.update (GotMove model.board (Ok res)) model |> Tuple.first


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
                    Game.init
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
                            answer { board = movedBoard, score = 0, moved = True, won = True, lost = False } started
                                |> .status
                                |> Expect.equal Won
                        , \_ ->
                            answer { board = started.board, score = 0, moved = False, won = False, lost = True } started
                                |> .status
                                |> Expect.equal Lost
                        ]
                        ()
            , test "depois de perder, as teclas não jogam" <|
                \_ ->
                    let
                        lost =
                            answer { board = started.board, score = 0, moved = False, won = False, lost = True } started
                    in
                    Game.update (Pressed Left) lost
                        |> Tuple.first
                        |> Expect.equal lost
            , test "erro de rede mostra mensagem e libera o teclado" <|
                \_ ->
                    started
                        |> Game.update (GotMove started.board (Err Http.NetworkError))
                        |> Tuple.first
                        |> Expect.all
                            [ .error >> Expect.notEqual Nothing
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
                        |> answer { board = first.board, score = 0, moved = False, won = False, lost = True }
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
                        |> answer { board = three.board, score = 0, moved = False, won = False, lost = True }
                        |> step ReplayStarted
                        |> Game.shown
                        |> .status
                        |> Expect.equal Playing
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
        ]
