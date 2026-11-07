module Game.View exposing (view)

{-| Tabuleiro, placar e controles (issue #8). Só lê o `Game.Model`; nada de HTTP ou `Random` aqui.
-}

import Api exposing (Direction(..))
import Game
import Html exposing (Html, button, div, p, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed


{-| Tabuleiro, placar e botões de direção. É o que a demo da apresentação mostra.
As peças são nós com chave (posição + valor): quando o valor muda o nó é novo e o
CSS dispara a animação "pop".
-}
view : Bool -> Game.Model -> Html Game.Msg
view inPresentation model =
    let
        n =
            List.length model.board
    in
    div [ class "demo-board" ]
        [ p [ class "score" ]
            [ text "Pontos: "
            , Html.span [ class "score-num", Html.Attributes.attribute "style" ("--n:" ++ String.fromInt model.score) ] []
            ]
        , Keyed.node "div"
            [ class "board"
            , style "grid-template-columns" ("repeat(" ++ String.fromInt n ++ ", auto)")
            ]
            (model.board
                |> List.indexedMap (\r row -> List.indexedMap (\c v -> viewTile r c v) row)
                |> List.concat
            )
        , div [ class "dirs" ]
            (List.map (\( label, dir ) -> button [ onClick (Game.Pressed dir) ] [ text label ])
                [ ( "A ←", Left ), ( "W ↑", Up ), ( "S ↓", Down ), ( "D →", Right ) ]
            )
        , p [ class "status" ]
            [ text
                (if inPresentation then
                    "Jogue com W A S D."

                 else
                    "Jogue com as setas ou com W A S D."
                )
            , if model.status == "" || model.status == "ok" then
                text ""

              else
                text ("  " ++ model.status)
            ]
        ]


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
