module Main exposing (main)

import Api exposing (Direction(..), MoveResponse)
import Browser
import Browser.Events
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Html exposing (Html, button, div, h1, p, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Http
import Json.Decode as D
import Ports
import Presentation
import Url exposing (Url)


type Page
    = GamePage
    | PresentationPage


type alias Model =
    { key : Nav.Key
    , page : Page
    , presentation : Presentation.Model
    , sources : Dict String String
    , board : List (List Int)
    , score : Int
    , status : String
    }


type Msg
    = Pressed Direction
    | GotMove (Result Http.Error MoveResponse)
    | PresentationMsg Presentation.Msg
    | StartPresentation
    | UrlRequested Browser.UrlRequest
    | UrlChanged Url
    | Ignored


main : Program D.Value Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }


init : D.Value -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( page, presentation ) =
            route url
    in
    ( { key = key
      , page = page
      , presentation = presentation
      , sources = sourcesFrom flags
      , board = [ [ 2, 0, 0, 2 ], [ 0, 0, 0, 0 ], [ 0, 4, 0, 0 ], [ 0, 0, 0, 0 ] ]
      , score = 0
      , status = "Use as setas do teclado."
      }
    , Cmd.none
    )


{-| Arquivos do repositório (`?raw` do Vite) usados nos slides com `Code`.
-}
sourcesFrom : D.Value -> Dict String String
sourcesFrom flags =
    D.decodeValue (D.field "sources" (D.dict D.string)) flags
        |> Result.withDefault Dict.empty


{-| `#/apresentacao` ou `#/apresentacao/N` (N de 1 em diante). Qualquer outra coisa é o jogo.
-}
route : Url -> ( Page, Presentation.Model )
route url =
    let
        number n =
            Maybe.withDefault 1 (String.toInt n) - 1
    in
    case String.split "/" (Maybe.withDefault "" url.fragment) of
        [ "", "apresentacao" ] ->
            ( PresentationPage, Presentation.init 0 0 )

        [ "", "apresentacao", c ] ->
            ( PresentationPage, Presentation.init (number c) 0 )

        [ "", "apresentacao", c, p ] ->
            ( PresentationPage, Presentation.init (number c) (number p) )

        _ ->
            ( GamePage, Presentation.init 0 0 )


presentationUrl : Presentation.Model -> String
presentationUrl m =
    "#/apresentacao/" ++ String.fromInt (m.scene + 1) ++ "/" ++ String.fromInt (m.step + 1)


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        GamePage ->
            Browser.Events.onKeyDown (D.map toGameMsg Api.keyDecoder)

        PresentationPage ->
            Browser.Events.onKeyDown (D.map PresentationMsg Presentation.keyDecoder)


toGameMsg : Maybe Direction -> Msg
toGameMsg maybeDir =
    case maybeDir of
        Just dir ->
            Pressed dir

        Nothing ->
            Ignored


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

        StartPresentation ->
            ( model, Nav.pushUrl model.key (presentationUrl (Presentation.init 0 0)) )

        PresentationMsg Presentation.ToggleFullscreen ->
            ( model, Ports.toggleFullscreen () )

        PresentationMsg Presentation.Exit ->
            ( model, Nav.pushUrl model.key "#/" )

        PresentationMsg pmsg ->
            let
                next =
                    Presentation.update pmsg model.presentation
            in
            ( { model | presentation = { next | showNotes = next.showNotes } }, Nav.replaceUrl model.key (presentationUrl next) )

        UrlRequested (Browser.Internal url) ->
            ( model, Nav.pushUrl model.key (Url.toString url) )

        UrlRequested (Browser.External href) ->
            ( model, Nav.load href )

        UrlChanged url ->
            let
                ( page, presentation ) =
                    route url
            in
            ( { model | page = page, presentation = { presentation | showNotes = model.presentation.showNotes } }, Cmd.none )

        Ignored ->
            ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    { title = "Logic2048"
    , body =
        [ case model.page of
            GamePage ->
                viewGame model

            PresentationPage ->
                Presentation.view
                    { toMsg = PresentationMsg
                    , demo = viewBoard model
                    , sources = model.sources
                    }
                    model.presentation
        ]
    }


viewGame : Model -> Html Msg
viewGame model =
    div [ style "font-family" "sans-serif", style "padding" "2rem" ]
        [ h1 [] [ text "Logic2048" ]
        , viewBoard model
        , button [ onClick StartPresentation ] [ text "Apresentar" ]
        ]


{-| Tabuleiro, placar e botões de direção. É o que a demo da apresentação mostra.
-}
viewBoard : Model -> Html Msg
viewBoard model =
    div []
        [ p [ style "font-size" "1.2rem" ] [ text ("Pontos: " ++ String.fromInt model.score) ]
        , div [] (List.map viewRow model.board)
        , div [ style "margin" "0.5rem 0" ]
            (List.map (\( label, dir ) -> button [ onClick (Pressed dir) ] [ text label ])
                [ ( "←", Left ), ( "↑", Up ), ( "↓", Down ), ( "→", Right ) ]
            )
        , p [ style "font-size" "1rem" ] [ text model.status ]
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
