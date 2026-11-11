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


{-| Tabuleiro 3×3 quase cheio, como os cenários da apresentação (#4).
-}
cenario3 : Game.Board
cenario3 =
    [ [ 2, 4, 8 ], [ 8, 16, 2 ], [ 2, 4, 0 ] ]


nonZero : Game.Board -> List Int
nonZero board =
    List.concat board |> List.filter ((/=) 0)


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
                    answer { board = started.board, score = 0, moved = False, won = False, lost = True } started
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
            , test "carregar tabuleiro com tamanho inválido é ignorado" <|
                \_ ->
                    Expect.all
                        [ \_ -> Game.update (LoadBoard [ [ 2, 4 ], [ 4, 2 ] ]) started |> Tuple.first |> Expect.equal started
                        , \_ -> Game.update (LoadBoard [ [ 2, 4, 2 ], [ 4, 2 ], [ 2, 4, 2 ] ]) started |> Tuple.first |> Expect.equal started
                        ]
                        ()
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
