module Api exposing (Direction(..), MoveResponse, encodeMove, moveDecoder, postMove)

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
