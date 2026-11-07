module ApiTest exposing (suite)

import Api exposing (Direction(..))
import Expect
import Json.Decode as D
import Json.Encode as E
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Api"
        [ test "codifica o pedido de movimento" <|
            \_ ->
                Api.encodeMove [ [ 2, 0 ] ] Left
                    |> E.encode 0
                    |> Expect.equal "{\"board\":[[2,0]],\"direction\":\"left\"}"
        , test "decodifica a resposta" <|
            \_ ->
                D.decodeString Api.moveDecoder
                    "{\"board\":[[4]],\"score\":4,\"moved\":true,\"won\":false,\"lost\":false}"
                    |> Expect.equal
                        (Ok { board = [ [ 4 ] ], score = 4, moved = True, won = False, lost = False })
        ]
