module AssistTest exposing (suite)

import Api exposing (Direction(..))
import Expect
import Game.Assist as Assist exposing (Action(..), Ai(..), Msg(..))
import Test exposing (Test, describe, test)


board : List (List Int)
board =
    [ [ 2, 2, 0 ], [ 0, 0, 0 ], [ 0, 0, 0 ] ]


ctx : Assist.Context
ctx =
    { board = board, waiting = False, won = False, lost = False, failed = False, replaying = False }


hint : Maybe Direction -> Api.Hint
hint dir =
    { direction = dir, depth = 2, scores = [] }


step : Msg -> Assist.Context -> Assist.Assist -> ( Assist.Assist, Action )
step msg c a =
    let
        ( next, _, action ) =
            Assist.update msg c a
    in
    ( next, action )


{-| Liga a IA e passa um tique: ela fica esperando a dica.
-}
thinking : Assist.Assist
thinking =
    Assist.init
        |> step AiToggled ctx
        |> Tuple.first
        |> step AiTicked ctx
        |> Tuple.first


suite : Test
suite =
    describe "Game.Assist (#20)"
        [ describe "modo IA: máquina de estados"
            [ test "ligar não pede nada ainda: o primeiro tique pede a dica" <|
                \_ ->
                    Assist.init |> step AiToggled ctx |> Tuple.first |> .ai |> Expect.equal Playing
            , test "o tique pede a dica e espera (Thinking)" <|
                \_ -> thinking.ai |> Expect.equal Thinking
            , test "tique com a jogada em voo não faz nada" <|
                \_ ->
                    Assist.init
                        |> step AiToggled ctx
                        |> Tuple.first
                        |> step AiTicked { ctx | waiting = True }
                        |> Tuple.first
                        |> .ai
                        |> Expect.equal Playing
            , test "a dica chega e a IA joga a direção" <|
                \_ ->
                    thinking
                        |> step (GotHint board (Ok (hint (Just Left)))) ctx
                        |> Expect.all
                            [ Tuple.second >> Expect.equal (Play Left)
                            , Tuple.first >> .ai >> Expect.equal Playing
                            ]
            , test "sem jogada, a IA para, avisa e pede o fim de jogo ao Prolog" <|
                \_ ->
                    thinking
                        |> step (GotHint board (Ok (hint Nothing))) ctx
                        |> Expect.all
                            [ Tuple.second >> Expect.equal Settle
                            , Tuple.first >> .ai >> Expect.equal Off
                            , Tuple.first >> .note >> Expect.notEqual Nothing
                            ]
            , test "dica de outro tabuleiro é descartada e a IA pergunta de novo" <|
                \_ ->
                    thinking
                        |> step (GotHint [ [ 4 ] ] (Ok (hint (Just Left)))) ctx
                        |> Expect.all
                            [ Tuple.second >> Expect.equal None
                            , Tuple.first >> .ai >> Expect.equal Playing
                            ]
            , test "erro na dica para a IA e vira mensagem" <|
                \_ ->
                    thinking
                        |> step (GotHint board (Err Api.Network)) ctx
                        |> Tuple.first
                        |> Expect.all [ .ai >> Expect.equal Off, .error >> Expect.notEqual Nothing ]
            , test "perder para a IA no próximo tique" <|
                \_ ->
                    Assist.init
                        |> step AiToggled ctx
                        |> Tuple.first
                        |> step AiTicked { ctx | lost = True }
                        |> Tuple.first
                        |> .ai
                        |> Expect.equal Off
            , test "vencer nesta corrida para a IA" <|
                \_ ->
                    Assist.init
                        |> step AiToggled ctx
                        |> Tuple.first
                        |> step AiTicked { ctx | won = True }
                        |> Tuple.first
                        |> .ai
                        |> Expect.equal Off
            , test "ligada depois de vencer, a IA continua jogando" <|
                \_ ->
                    Assist.init
                        |> step AiToggled { ctx | won = True }
                        |> Tuple.first
                        |> step AiTicked { ctx | won = True }
                        |> Tuple.first
                        |> .ai
                        |> Expect.equal Thinking
            , test "com a IA ligada, as teclas de quem joga são ignoradas" <|
                \_ -> Assist.driving thinking |> Expect.equal True
            , test "pausar desliga" <|
                \_ -> thinking |> step AiToggled ctx |> Tuple.first |> .ai |> Expect.equal Off
            ]
        , describe "dica"
            [ test "a dica vale só para o tabuleiro em que foi pedida" <|
                \_ ->
                    Assist.init
                        |> step HintToggled ctx
                        |> Tuple.first
                        |> step (GotHint board (Ok (hint (Just Right)))) ctx
                        |> Tuple.first
                        |> Expect.all
                            [ Assist.currentHint board >> Maybe.andThen .direction >> Expect.equal (Just Right)
                            , Assist.currentHint [ [ 2 ] ] >> Expect.equal Nothing
                            ]
            , test "o botão Dica não joga" <|
                \_ ->
                    Assist.init
                        |> step HintToggled ctx
                        |> Tuple.first
                        |> step (GotHint board (Ok (hint (Just Right)))) ctx
                        |> Tuple.second
                        |> Expect.equal None
            , test "a dica liga e desliga; desligada, a seta some" <|
                \_ ->
                    Assist.init
                        |> step HintToggled ctx
                        |> Tuple.first
                        |> step (GotHint board (Ok (hint (Just Right)))) ctx
                        |> Tuple.first
                        |> step HintToggled ctx
                        |> Tuple.first
                        |> Expect.all
                            [ .hintsOn >> Expect.equal False
                            , Assist.currentHint board >> Expect.equal Nothing
                            ]
            , test "ligada, pede de novo quando o tabuleiro muda" <|
                \_ ->
                    Assist.init
                        |> step HintToggled ctx
                        |> Tuple.first
                        |> step (GotHint board (Ok (hint (Just Right)))) ctx
                        |> Tuple.first
                        |> step HintRefresh { ctx | board = [ [ 2, 0 ], [ 0, 2 ] ] }
                        |> Tuple.first
                        |> .asking
                        |> Expect.equal True
            , test "com erro, as dicas desligam (sem pedir sem parar)" <|
                \_ ->
                    Assist.init
                        |> step HintToggled ctx
                        |> Tuple.first
                        |> step (GotHint board (Err Api.Network)) ctx
                        |> Tuple.first
                        |> .hintsOn
                        |> Expect.equal False
            , test "com as dicas desligadas, a dica que sobrou da IA não aparece" <|
                \_ ->
                    { thinking | ai = Off, hint = Just ( board, hint (Just Right) ) }
                        |> Assist.shownHint board
                        |> Expect.equal Nothing
            , test "novo jogo guarda as dicas ligadas" <|
                \_ ->
                    Assist.init
                        |> step HintToggled ctx
                        |> Tuple.first
                        |> Assist.reset
                        |> .hintsOn
                        |> Expect.equal True
            ]
        , describe "desafios"
            [ test "escolher mostra o tabuleiro do desafio" <|
                \_ ->
                    Assist.init
                        |> step (ChallengeChosen desafio) ctx
                        |> Tuple.second
                        |> Expect.equal (Show desafio.board)
            , test "o passo aplica a resposta do Prolog, sem sortear" <|
                \_ ->
                    Assist.init
                        |> step (ChallengeChosen desafio) ctx
                        |> Tuple.first
                        |> step (GotSolution "c1" (Ok { solvable = True, moves = [ Left ] })) ctx
                        |> Tuple.first
                        |> step StepForward ctx
                        |> Tuple.first
                        |> step (GotStep board (Ok resposta)) ctx
                        |> Expect.all
                            [ Tuple.second >> Expect.equal (Step resposta)
                            , Tuple.first >> .active >> Maybe.map .at >> Expect.equal (Just 1)
                            ]
            , test "no desafio as teclas e o desfazer ficam travados" <|
                \_ ->
                    Assist.init
                        |> step (ChallengeChosen desafio) ctx
                        |> Tuple.first
                        |> Expect.all [ Assist.driving >> Expect.equal True, Assist.inChallenge >> Expect.equal True ]
            , test "sair do desafio volta a um jogo novo" <|
                \_ ->
                    Assist.init
                        |> step (ChallengeChosen desafio) ctx
                        |> Tuple.first
                        |> step ChallengesClosed ctx
                        |> Tuple.second
                        |> Expect.equal Restart
            ]
        ]


desafio : Api.Challenge
desafio =
    { id = "c1", title = "t", board = board, target = 4, maxMoves = 1 }


resposta : Api.MoveResponse
resposta =
    { board = [ [ 4, 0, 0 ], [ 0, 0, 0 ], [ 0, 0, 0 ] ], score = 4, moved = True, won = False, lost = False, moves = [] }
