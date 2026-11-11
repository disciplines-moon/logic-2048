module Game.View exposing (view)

{-| Tabuleiro, placar e controles (issue #8). Só lê o `Game.Model`; nada de HTTP ou `Random` aqui.
-}

import Api exposing (Direction(..))
import Game
import Html exposing (Html, button, div, p, text)
import Html.Attributes exposing (class, classList, disabled, style)
import Html.Events exposing (on, onClick)
import Html.Keyed as Keyed
import Json.Decode as D


{-| Tabuleiro, placar e botões de direção. É o que a demo da apresentação mostra.
As peças são nós com chave (posição + valor): quando o valor muda o nó é novo e o
CSS dispara a animação "pop".
-}
view : Bool -> Game.Model -> Html Game.Msg
view inPresentation model =
    let
        -- No replay a tela mostra o momento da vez, não o jogo atual.
        screen =
            Game.shown model

        n =
            List.length screen.board
    in
    div [ class "demo-board" ]
        [ p [ class "score" ]
            [ text "Pontos: "
            , Html.span [ class "score-num", Html.Attributes.attribute "style" ("--n:" ++ String.fromInt screen.score) ] []
            , replayPosition model
            ]
        , Keyed.node "div"
            ([ class "board"
             , class ("n" ++ String.fromInt n)
             , style "grid-template-columns" ("repeat(" ++ String.fromInt n ++ ", auto)")
             ]
                ++ swipe
            )
            (screen.board
                |> List.indexedMap (\r row -> List.indexedMap (\c v -> viewTile r c v) row)
                |> List.concat
            )
        , if inPresentation then
            -- Na apresentação W A S D já jogam (o rodapé avisa); no lugar das setas
            -- ficam desfazer e replay, para a demo caber na tela.
            historyControls model

          else
            div [ class "dirs" ]
                (List.map (\( label, dir ) -> button [ onClick (Game.Pressed dir) ] [ text label ])
                    [ ( "A ←", Left ), ( "W ↑", Up ), ( "S ↓", Down ), ( "D →", Right ) ]
                )
        , if inPresentation && statusText model == "" then
            -- Na apresentação o rodapé já diz que W A S D jogam; a linha só aparece com vitória, derrota ou erro.
            text ""

          else if inPresentation then
            p [ class "status" ] [ text (statusText model) ]

          else
            p [ class "status" ] [ text ("Jogue com as setas ou com W A S D." ++ statusText model) ]
        , div [ class "controls" ]
            (button [ onClick Game.NewGame ] [ text "Novo jogo" ]
                :: List.map (sizeButton model.size) [ 3, 4, 5, 6 ]
            )
        , if inPresentation then
            text ""

          else
            historyControls model
        ]


{-| Durante o replay, qual jogada está na tela.
-}
replayPosition : Game.Model -> Html Game.Msg
replayPosition model =
    case model.replay of
        Just replay ->
            Html.span [ class "replay-pos" ]
                [ text (" · replay: jogada " ++ String.fromInt replay.at ++ " de " ++ String.fromInt (List.length replay.frames - 1)) ]

        Nothing ->
            text ""


{-| Desfazer e replay (#7). Durante o replay, os botões viram pausa, velocidade e sair.
-}
historyControls : Game.Model -> Html Game.Msg
historyControls model =
    case model.replay of
        Nothing ->
            div [ class "controls" ]
                [ button [ onClick Game.Undo, disabled (List.isEmpty model.history || model.waiting) ] [ text "↶ Desfazer" ]
                , button [ onClick Game.ReplayStarted, disabled (List.isEmpty model.history || model.waiting) ] [ text "▶ Replay" ]
                ]

        Just replay ->
            div [ class "controls" ]
                ([ button [ onClick Game.ReplayPaused, class "pause" ]
                    [ text
                        (if replay.playing then
                            "⏸ Pausar"

                         else if replay.at >= List.length replay.frames - 1 then
                            "↺ De novo"

                         else
                            "▶ Continuar"
                        )
                    ]
                 ]
                    ++ List.map (speedButton replay.interval) [ ( "0,5×", 1000 ), ( "1×", 500 ), ( "2×", 250 ) ]
                    ++ [ button [ onClick Game.ReplayClosed ] [ text "Sair" ] ]
                )


speedButton : Float -> ( String, Float ) -> Html Game.Msg
speedButton current ( label, interval ) =
    button
        [ onClick (Game.ReplaySpeed interval)
        , classList [ ( "size", True ), ( "active", interval == current ) ]
        ]
        [ text label ]


{-| Vitória, derrota ou erro. No replay vale o status da jogada na tela, sem o erro
do jogo atual.
-}
statusText : Game.Model -> String
statusText model =
    let
        error =
            if model.replay == Nothing then
                model.error

            else
                Nothing
    in
    case ( error, (Game.shown model).status ) of
        ( Just err, _ ) ->
            "  " ++ err

        ( Nothing, Game.Won ) ->
            "  Você venceu! Pode continuar jogando."

        ( Nothing, Game.Lost ) ->
            "  Fim de jogo."

        ( Nothing, Game.Playing ) ->
            ""


sizeButton : Int -> Int -> Html Game.Msg
sizeButton current n =
    button
        [ onClick (Game.SizeChosen n)
        , classList [ ( "size", True ), ( "active", n == current ) ]
        ]
        [ text (String.fromInt n ++ "×" ++ String.fromInt n) ]


{-| Swipe no celular: guarda onde o dedo encostou e decide a direção quando ele sai.
-}
swipe : List (Html.Attribute Game.Msg)
swipe =
    [ on "touchstart" (D.map Game.TouchStarted touchPoint)
    , on "touchend" (D.map Game.TouchEnded touchPoint)
    ]


touchPoint : D.Decoder Game.Point
touchPoint =
    D.map2 Tuple.pair
        (D.at [ "changedTouches", "0", "clientX" ] D.float)
        (D.at [ "changedTouches", "0", "clientY" ] D.float)


viewTile : Int -> Int -> Int -> ( String, Html Game.Msg )
viewTile r c v =
    ( String.fromInt r ++ "-" ++ String.fromInt c ++ "-" ++ String.fromInt v
    , div
        [ class "tile"
        , class
            (if v == 0 then
                "empty"

             else
                "v" ++ String.fromInt v
            )
        ]
        [ text
            (if v == 0 then
                ""

             else
                String.fromInt v
            )
        ]
    )
