module Main exposing (main)

import Api exposing (Direction(..), MoveResponse)
import Browser
import Browser.Events
import Html exposing (Html, div, h1, p, text)
import Html.Attributes exposing (style)
import Http
import Json.Decode as D


type alias Model =
    { board : List (List Int)
    , score : Int
    , status : String
    }


type Msg
    = Pressed Direction
    | GotMove (Result Http.Error MoveResponse)
    | Ignored


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( initialModel, Cmd.none )
        , update = update
        , view = view
        , subscriptions = \_ -> Browser.Events.onKeyDown keyDecoder
        }


initialModel : Model
initialModel =
    -- TODO: sortear duas peças iniciais com Random.
    { board = [ [ 2, 0, 0, 2 ], [ 0, 0, 0, 0 ], [ 0, 4, 0, 0 ], [ 0, 0, 0, 0 ] ]
    , score = 0
    , status = "Use as setas do teclado."
    }


keyDecoder : D.Decoder Msg
keyDecoder =
    D.field "key" D.string
        |> D.map
            (\key ->
                case key of
                    "ArrowLeft" ->
                        Pressed Left

                    "ArrowRight" ->
                        Pressed Right

                    "ArrowUp" ->
                        Pressed Up

                    "ArrowDown" ->
                        Pressed Down

                    _ ->
                        Ignored
            )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Pressed dir ->
            ( model, Api.postMove model.board dir GotMove )

        GotMove (Ok res) ->
            -- TODO: se res.moved, sortear uma peça nova; tratar res.won e res.lost.
            ( { model | board = res.board, score = model.score + res.score, status = "ok" }, Cmd.none )

        GotMove (Err _) ->
            ( { model | status = "Erro ao falar com o servidor." }, Cmd.none )

        Ignored ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div [ style "font-family" "sans-serif", style "padding" "2rem" ]
        [ h1 [] [ text "Logic2048" ]
        , p [] [ text ("Pontos: " ++ String.fromInt model.score) ]
        , div [] (List.map viewRow model.board)
        , p [] [ text model.status ]
        ]


viewRow : List Int -> Html Msg
viewRow row =
    div [ style "display" "flex" ] (List.map viewCell row)


viewCell : Int -> Html Msg
viewCell n =
    div
        [ style "width" "4rem"
        , style "height" "4rem"
        , style "margin" "2px"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "background" "#eee4da"
        ]
        [ text
            (if n == 0 then
                ""

             else
                String.fromInt n
            )
        ]
