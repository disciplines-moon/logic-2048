module Api exposing (Challenge, Direction(..), Error(..), Hint, Move, MoveResponse, RawResponse, Solution, apiResult, challengeDecoder, directionFromString, directionToString, encodeMove, errorMessage, expectApi, getChallenges, getRaw, hintDecoder, keyDecoder, moveDecoder, postChallenge, postHint, postMove, postRaw, rawResponse, solutionDecoder, undoDecoder, wasdDecoder)

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
    , moves : List Move
    }


{-| O caminho de uma peça, calculado pelo Prolog (`move_trace/5`, #8): de onde
saiu, onde chegou (linha, coluna) e se entrou numa fusão. A tela só lê.
-}
type alias Move =
    { from : ( Int, Int )
    , to : ( Int, Int )
    , merged : Bool
    }


{-| Falha quando a tecla está sendo repetida (segurada), vem com Ctrl, Alt ou Meta
(Ctrl+Z é desfazer, não jogada) ou foi digitada num campo de texto.
-}
notRepeat : D.Decoder ()
notRepeat =
    D.map5
        (\r ctrl alt meta typing -> r || ctrl || alt || meta || typing)
        (D.field "repeat" D.bool)
        (D.field "ctrlKey" D.bool)
        (D.field "altKey" D.bool)
        (D.field "metaKey" D.bool)
        inTextField
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
    D.map6 MoveResponse
        (D.field "board" (D.list (D.list D.int)))
        (D.field "score" D.int)
        (D.field "moved" D.bool)
        (D.field "won" D.bool)
        (D.field "lost" D.bool)
        -- Opcional: sem `moves`, as peças só aparecem no lugar novo.
        (D.oneOf [ D.field "moves" (D.list moveItemDecoder), D.succeed [] ])


moveItemDecoder : D.Decoder Move
moveItemDecoder =
    D.map3 Move
        (D.field "from" cellDecoder)
        (D.field "to" cellDecoder)
        (D.field "merged" D.bool)


{-| Uma casa como `[linha, coluna]`.
-}
cellDecoder : D.Decoder ( Int, Int )
cellDecoder =
    D.map2 Tuple.pair (D.index 0 D.int) (D.index 1 D.int)


postMove : List (List Int) -> Direction -> (Result Http.Error MoveResponse -> msg) -> Cmd msg
postMove board dir toMsg =
    Http.post
        { url = "/api/move"
        , body = Http.jsonBody (encodeMove board dir)
        , expect = Http.expectJson toMsg moveDecoder
        }


{-| Uma resposta HTTP como veio: o status e o corpo em texto, seja qual for o status.
-}
type alias RawResponse =
    { status : Int
    , body : String
    }


{-| Manda `body` exatamente como está escrito, mesmo que seja inválido de propósito,
e devolve a resposta crua. A apresentação da #10 usa isso para mostrar o
`{"error": ...}` do 422, que o `Http.expectJson` descartaria (veja `docs/contrato.md`).
-}
postRaw : String -> String -> (Result Http.Error RawResponse -> msg) -> Cmd msg
postRaw url body toMsg =
    Http.post
        { url = url
        , body = Http.stringBody "application/json" body
        , expect = Http.expectStringResponse toMsg rawResponse
        }


{-| Como o `postRaw`, para um GET (o `GET /api/challenges` na apresentação da #11).
-}
getRaw : String -> (Result Http.Error RawResponse -> msg) -> Cmd msg
getRaw url toMsg =
    Http.get { url = url, expect = Http.expectStringResponse toMsg rawResponse }


{-| Qualquer status com corpo é resposta (200, 422 ou 500). Só é erro quando não
chega resposta nenhuma: rede fora, tempo esgotado ou endereço inválido.
-}
rawResponse : Http.Response String -> Result Http.Error RawResponse
rawResponse response =
    case response of
        Http.GoodStatus_ meta body ->
            Ok { status = meta.statusCode, body = body }

        Http.BadStatus_ meta body ->
            Ok { status = meta.statusCode, body = body }

        Http.BadUrl_ url ->
            Err (Http.BadUrl url)

        Http.Timeout_ ->
            Err Http.Timeout

        Http.NetworkError_ ->
            Err Http.NetworkError


{-| Ctrl+Z (ou Cmd+Z no Mac) desfaz (#7). Como nas jogadas, tecla segurada e campo
de texto não contam; com Shift ou Alt também não (Ctrl+Shift+Z costuma ser refazer).
-}
undoDecoder : D.Decoder ()
undoDecoder =
    D.map7
        (\key ctrl meta shift alt r typing ->
            (String.toLower key == "z")
                && (ctrl || meta)
                && not (shift || alt || r || typing)
        )
        (D.field "key" D.string)
        (D.field "ctrlKey" D.bool)
        (D.field "metaKey" D.bool)
        (D.field "shiftKey" D.bool)
        (D.field "altKey" D.bool)
        (D.field "repeat" D.bool)
        inTextField
        |> D.andThen
            (\isUndo ->
                if isUndo then
                    D.succeed ()

                else
                    D.fail "não é Ctrl+Z"
            )


{-| A tecla foi digitada num campo de texto? Aí ela é do campo, não do jogo.
-}
inTextField : D.Decoder Bool
inTextField =
    D.maybe (D.at [ "target", "tagName" ] D.string)
        |> D.map (\tag -> List.member tag [ Just "INPUT", Just "TEXTAREA", Just "SELECT" ])



-- DICA E DESAFIOS (#20): hint, challenge e challenges, com erros legíveis


{-| A resposta de `POST /api/hint`. `direction` é `Nothing` quando não há jogada
(o `null` do JSON, que veio do `none` do Prolog).
-}
type alias Hint =
    { direction : Maybe Direction
    , depth : Int
    , scores : List ( Direction, Float )
    }


{-| Um desafio da lista fixa (`GET /api/challenges`).
-}
type alias Challenge =
    { id : String
    , title : String
    , board : List (List Int)
    , target : Int
    , maxMoves : Int
    }


{-| A resposta de `POST /api/challenge`: a menor sequência que chega ao alvo.
-}
type alias Solution =
    { solvable : Bool
    , moves : List Direction
    }


{-| Tudo o que pode dar errado ao falar com a API. É um tipo, então quem chama é
obrigado pelo compilador a tratar cada caso.

  - `Network`: nenhuma resposta (servidor fora, rede, tempo esgotado).
  - `Rejected`: 422, com a mensagem do `{"error": ...}` (em português).
  - `Server`: 500 ou outro status de erro.
  - `Invalid`: chegou 200, mas o corpo não tem o formato do contrato.

-}
type Error
    = Network
    | Rejected String
    | Server Int
    | Invalid


{-| Lê a resposta crua (status e corpo) e decide. O `Http.expectJson` descartaria o
corpo do 422 (`BadStatus 422`); com o `expectStringResponse` dá para ler o
`{"error": ...}` e mostrar a mensagem do servidor (veja `docs/contrato.md`).
-}
expectApi : (Result Error a -> msg) -> D.Decoder a -> Http.Expect msg
expectApi toMsg decoder =
    Http.expectStringResponse toMsg (apiResult decoder)


{-| Decide o que uma resposta crua quer dizer. Com a API parada, o proxy do Vite
responde 502 sem corpo: para quem joga, é o mesmo que nenhuma resposta.
-}
apiResult : D.Decoder a -> Http.Response String -> Result Error a
apiResult decoder response =
    case response of
        Http.GoodStatus_ _ body ->
            D.decodeString decoder body |> Result.mapError (\_ -> Invalid)

        Http.BadStatus_ meta body ->
            if meta.statusCode == 422 then
                Err (Rejected (D.decodeString (D.field "error" D.string) body |> Result.withDefault "pedido inválido"))

            else if List.member meta.statusCode [ 502, 503, 504 ] then
                Err Network

            else
                Err (Server meta.statusCode)

        _ ->
            Err Network


{-| A frase que a tela mostra para cada erro.
-}
errorMessage : Error -> String
errorMessage error =
    case error of
        Network ->
            "Sem resposta do servidor. A API está rodando?"

        Rejected message ->
            "O servidor recusou o pedido: " ++ message

        Server status ->
            "Erro no servidor (" ++ String.fromInt status ++ "). Tente de novo."

        Invalid ->
            "Resposta inválida do servidor."


directionFromString : String -> Maybe Direction
directionFromString s =
    case s of
        "left" ->
            Just Left

        "right" ->
            Just Right

        "up" ->
            Just Up

        "down" ->
            Just Down

        _ ->
            Nothing


directionDecoder : D.Decoder Direction
directionDecoder =
    D.string
        |> D.andThen
            (\s ->
                case directionFromString s of
                    Just dir ->
                        D.succeed dir

                    Nothing ->
                        D.fail ("direção desconhecida: " ++ s)
            )


hintDecoder : D.Decoder Hint
hintDecoder =
    D.map3 Hint
        (D.field "direction" (D.nullable directionDecoder))
        (D.field "depth" D.int)
        (D.field "scores" (D.keyValuePairs D.float)
            |> D.andThen
                (\pairs ->
                    -- Na ordem do contrato (left, right, up, down), não na do objeto JSON.
                    List.filterMap (\dir -> List.filter (\( k, _ ) -> k == directionToString dir) pairs |> List.head |> Maybe.map (\( _, v ) -> ( dir, v ))) [ Left, Right, Up, Down ]
                        |> (\scores ->
                                if List.length scores == List.length pairs then
                                    D.succeed scores

                                else
                                    D.fail "direção desconhecida em scores"
                           )
                )
        )


challengeDecoder : D.Decoder Challenge
challengeDecoder =
    D.map5 Challenge
        (D.field "id" D.string)
        (D.field "title" D.string)
        (D.field "board" (D.list (D.list D.int)))
        (D.field "target" D.int)
        (D.field "max_moves" D.int)


solutionDecoder : D.Decoder Solution
solutionDecoder =
    D.map2 Solution
        (D.field "solvable" D.bool)
        (D.field "moves" (D.list directionDecoder))


postHint : List (List Int) -> (Result Error Hint -> msg) -> Cmd msg
postHint board toMsg =
    Http.post
        { url = "/api/hint"
        , body = Http.jsonBody (E.object [ ( "board", E.list (E.list E.int) board ) ])
        , expect = expectApi toMsg hintDecoder
        }


getChallenges : (Result Error (List Challenge) -> msg) -> Cmd msg
getChallenges toMsg =
    Http.get { url = "/api/challenges", expect = expectApi toMsg (D.list challengeDecoder) }


postChallenge : Challenge -> (Result Error Solution -> msg) -> Cmd msg
postChallenge challenge toMsg =
    Http.post
        { url = "/api/challenge"
        , body =
            Http.jsonBody
                (E.object
                    [ ( "board", E.list (E.list E.int) challenge.board )
                    , ( "target", E.int challenge.target )
                    , ( "max_moves", E.int challenge.maxMoves )
                    ]
                )
        , expect = expectApi toMsg solutionDecoder
        }
