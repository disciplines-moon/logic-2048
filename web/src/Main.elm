module Main exposing (main)

import Browser
import Browser.Events
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Game
import Game.Effects
import Game.View
import Html exposing (Html, button, div, h1, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
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
    , game : Game.Model
    }


type Msg
    = GameMsg Game.Msg
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

        ( game, gameCmd ) =
            Game.init (prefsFrom flags)

        model =
            { key = key
            , page = page
            , presentation = presentation
            , sources = sourcesFrom flags
            , game = game
            }
    in
    -- Abriu direto num passo com `DemoCom` (link ou F5): o tabuleiro já entra pronto.
    if page == PresentationPage then
        enterStep model (Cmd.map GameMsg gameCmd)

    else
        ( model, Cmd.map GameMsg gameCmd )


{-| Arquivos do repositório (`?raw` do Vite) usados nos slides com `Code`.
-}
sourcesFrom : D.Value -> Dict String String
sourcesFrom flags =
    D.decodeValue (D.field "sources" (D.dict D.string)) flags
        |> Result.withDefault Dict.empty


{-| Recorde, tema e som salvos no navegador (#9): o `main.js` lê o `localStorage` e
manda nas flags. Sem nada salvo, o jogo começa com os valores padrão.
-}
prefsFrom : D.Value -> Game.Effects.Prefs
prefsFrom flags =
    D.decodeValue (D.field "prefs" Game.Effects.prefsDecoder) flags
        |> Result.withDefault Game.Effects.defaultPrefs


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
            Sub.batch
                [ Sub.map GameMsg (Game.keyMsgs True)
                , Sub.map GameMsg (Game.subscriptions model.game)
                ]

        PresentationPage ->
            -- Na apresentação as setas navegam e W, A, S, D jogam na demo. Fora de um
            -- passo com a demo, o jogo fica parado: sem teclas e sem o relógio da IA e
            -- do replay (voltando à demo, eles continuam de onde pararam).
            Sub.batch
                (Browser.Events.onKeyDown (D.map PresentationMsg Presentation.keyDecoder)
                    :: (if Presentation.showsDemo model.presentation then
                            [ Sub.map GameMsg (Game.keyMsgs False)
                            , Sub.map GameMsg (Game.subscriptions model.game)
                            ]

                        else
                            []
                       )
                )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GameMsg gmsg ->
            let
                -- Num passo com `DemoCom`, "Novo jogo" volta ao tabuleiro do passo
                -- (por exemplo quase vencido), para repetir a demonstração.
                actual =
                    case ( gmsg, model.page, Presentation.demoBoard model.presentation ) of
                        ( Game.NewGame, PresentationPage, Just board ) ->
                            Game.LoadBoard board

                        _ ->
                            gmsg

                ( game, cmd ) =
                    Game.update actual model.game
            in
            ( { model | game = game }, Cmd.map GameMsg cmd )

        StartPresentation ->
            ( model, Nav.pushUrl model.key (presentationUrl (Presentation.init 0 0)) )

        PresentationMsg Presentation.ToggleFullscreen ->
            ( model, Ports.toggleFullscreen () )

        PresentationMsg Presentation.Exit ->
            ( model, Nav.pushUrl model.key "#/" )

        PresentationMsg Presentation.Ignored ->
            ( model, Cmd.none )

        PresentationMsg ((Presentation.SendRequest body) as pmsg) ->
            ( { model | presentation = Presentation.update pmsg model.presentation }
            , Cmd.map PresentationMsg (Presentation.send body)
            )

        PresentationMsg ((Presentation.SendRequestTo url body) as pmsg) ->
            ( { model | presentation = Presentation.update pmsg model.presentation }
            , Cmd.map PresentationMsg (Presentation.sendTo url body)
            )

        PresentationMsg ((Presentation.GotResponse _ _ _) as pmsg) ->
            -- A resposta é guardada mesmo que a pessoa já tenha saído da apresentação;
            -- senão, ao voltar, o painel ficaria para sempre "esperando o servidor".
            ( { model | presentation = Presentation.update pmsg model.presentation }, Cmd.none )

        PresentationMsg pmsg ->
            let
                next =
                    Presentation.update pmsg model.presentation

                moved =
                    ( next.scene, next.step ) /= ( model.presentation.scene, model.presentation.step )
            in
            if model.page /= PresentationPage then
                ( model, Cmd.none )

            else if moved then
                enterStep { model | presentation = next } (Nav.replaceUrl model.key (presentationUrl next))

            else
                ( { model | presentation = next }, Cmd.none )

        UrlRequested (Browser.Internal url) ->
            ( model, Nav.pushUrl model.key (Url.toString url) )

        UrlRequested (Browser.External href) ->
            ( model, Nav.load href )

        UrlChanged url ->
            let
                ( page, presentation ) =
                    route url
            in
            -- A URL só guarda cena e passo: o resto do estado da apresentação passa adiante.
            let
                arrived =
                    { model
                        | page = page
                        , presentation =
                            { presentation
                                | showNotes = model.presentation.showNotes
                                , forward = model.presentation.forward
                                , request = model.presentation.request
                            }
                    }

                -- Entrou por link, recarregou ou digitou a URL. Pelas setas, o passo já
                -- mudou no PresentationMsg e o replaceUrl chega aqui sem mudança.
                entered =
                    page == PresentationPage && (model.page /= page || ( presentation.scene, presentation.step ) /= ( model.presentation.scene, model.presentation.step ))
            in
            if entered then
                enterStep arrived Cmd.none

            else
                ( arrived, Cmd.none )

        Ignored ->
            ( model, Cmd.none )


{-| Chegou a um passo novo da apresentação. O painel de pedidos começa vazio e,
se o passo tem `DemoCom`, o jogo da demo
carrega aquele tabuleiro e começa limpo, sem a dica nem a câmera lenta que
ficaram ligadas num slide anterior (o `LoadBoard` desliga a IA e o desafio, mas
guarda as duas).
-}
enterStep : Model -> Cmd Msg -> ( Model, Cmd Msg )
enterStep arrived cmd =
    let
        -- Cada passo começa zerado: a resposta de um pedido ao vivo (#11) não
        -- reaparece ao voltar ao slide.
        presentation =
            arrived.presentation

        model =
            { arrived | presentation = { presentation | request = Nothing } }
    in
    case Presentation.demoBoard model.presentation of
        Just board ->
            let
                current =
                    model.game

                assist =
                    current.assist

                ( game, gameCmd ) =
                    Game.update (Game.LoadBoard board) { current | slowMotion = False, assist = { assist | hintsOn = False, hint = Nothing } }
            in
            ( { model | game = game }, Cmd.batch [ cmd, Cmd.map GameMsg gameCmd ] )

        Nothing ->
            ( model, cmd )


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
                    , demo = Html.map GameMsg (Game.View.view True model.game)
                    , loadBoard = GameMsg << Game.LoadBoard
                    , sources = model.sources
                    }
                    model.presentation
        ]
    }


viewGame : Model -> Html Msg
viewGame model =
    div [ class "game" ]
        [ h1 [] [ text "Logic2048" ]
        , Html.map GameMsg (Game.View.view False model.game)
        , button [ onClick StartPresentation ] [ text "Apresentar" ]
        ]
