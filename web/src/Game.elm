module Game exposing (Model, Msg(..), init, keyMsgs, update)

{-| Estado e regras de tela do jogo (issue #6). Não conhece a apresentação nem o roteamento.
A regra de jogo mora no Prolog: aqui só se manda o tabuleiro e se guarda a resposta.
-}

import Api exposing (Direction)
import Browser.Events
import Http
import Json.Decode as D


type alias Model =
    { board : List (List Int)
    , score : Int
    , status : String
    }


type Msg
    = Pressed Direction
    | GotMove (Result Http.Error Api.MoveResponse)
    | NoOp


init : Model
init =
    { board = [ [ 2, 0, 0, 2 ], [ 0, 0, 0, 0 ], [ 0, 4, 0, 0 ], [ 0, 0, 0, 0 ] ]
    , score = 0
    , status = ""
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Pressed dir ->
            ( model, Api.postMove model.board dir GotMove )

        GotMove (Ok res) ->
            -- TODO(#6): se res.moved, sortear uma peça nova; tratar res.won e res.lost.
            ( { model | board = res.board, score = model.score + res.score, status = "ok" }, Cmd.none )

        GotMove (Err _) ->
            ( { model | status = "Erro ao falar com o servidor." }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


{-| Teclas que jogam. `arrows` diz se as setas também valem (na apresentação elas navegam).
-}
keyMsgs : Bool -> Sub Msg
keyMsgs arrows =
    Sub.batch
        ((if arrows then
            [ Browser.Events.onKeyDown (D.map toMsg Api.keyDecoder) ]

          else
            []
         )
            ++ [ Browser.Events.onKeyDown (D.map toMsg Api.wasdDecoder) ]
        )


toMsg : Maybe Direction -> Msg
toMsg maybeDir =
    case maybeDir of
        Just dir ->
            Pressed dir

        Nothing ->
            NoOp
