module Api exposing (Direction(..), MoveResponse, encodeMove, keyDecoder, moveDecoder, postMove, wasdDecoder)

import Http
import Json.Decode as D
import Json.Encode as E


type Direction
    = Left
    | Right
    | Up
    | Down


type alias MoveResponse =
    { board : List (List Int)
    , score : Int
    , moved : Bool
    , won : Bool
    , lost : Bool
    }


{-| Falha quando a tecla está sendo repetida (segurada), vem com Ctrl, Alt ou Meta
(Ctrl+Z é desfazer, não jogada) ou foi digitada num campo de texto.
-}
notRepeat : D.Decoder ()
notRepeat =
    D.map5
        (\r ctrl alt meta tag ->
            r || ctrl || alt || meta || List.member tag [ Just "INPUT", Just "TEXTAREA", Just "SELECT" ]
        )
        (D.field "repeat" D.bool)
        (D.field "ctrlKey" D.bool)
        (D.field "altKey" D.bool)
        (D.field "metaKey" D.bool)
        (D.maybe (D.at [ "target", "tagName" ] D.string))
        |> D.andThen
            (\bloqueada ->
                if bloqueada then
                    D.fail "tecla repetida ou com modificador"

                else
                    D.succeed ()
            )


{-| Setas do teclado viram direções. Outras teclas viram `Nothing`.
-}
keyDecoder : D.Decoder (Maybe Direction)
keyDecoder =
    notRepeat
        |> D.andThen (\_ -> D.field "key" D.string)
        |> D.map
            (\key ->
                case key of
                    "ArrowLeft" ->
                        Just Left

                    "ArrowRight" ->
                        Just Right

                    "ArrowUp" ->
                        Just Up

                    "ArrowDown" ->
                        Just Down

                    _ ->
                        Nothing
            )


{-| W, A, S, D também jogam (na apresentação, as setas navegam).
-}
wasdDecoder : D.Decoder (Maybe Direction)
wasdDecoder =
    notRepeat
        |> D.andThen (\_ -> D.field "key" D.string)
        |> D.map
            (\key ->
                case String.toLower key of
                    "a" ->
                        Just Left

                    "d" ->
                        Just Right

                    "w" ->
                        Just Up

                    "s" ->
                        Just Down

                    _ ->
                        Nothing
            )


directionToString : Direction -> String
directionToString dir =
    case dir of
        Left ->
            "left"

        Right ->
            "right"

        Up ->
            "up"

        Down ->
            "down"


encodeMove : List (List Int) -> Direction -> E.Value
encodeMove board dir =
    E.object
        [ ( "board", E.list (E.list E.int) board )
        , ( "direction", E.string (directionToString dir) )
        ]


moveDecoder : D.Decoder MoveResponse
moveDecoder =
    D.map5 MoveResponse
        (D.field "board" (D.list (D.list D.int)))
        (D.field "score" D.int)
        (D.field "moved" D.bool)
        (D.field "won" D.bool)
        (D.field "lost" D.bool)


postMove : List (List Int) -> Direction -> (Result Http.Error MoveResponse -> msg) -> Cmd msg
postMove board dir toMsg =
    Http.post
        { url = "/api/move"
        , body = Http.jsonBody (encodeMove board dir)
        , expect = Http.expectJson toMsg moveDecoder
        }
