module Presentation exposing (Model, Msg(..), init, keyDecoder, sceneCount, update, view)

{-| Página `#/apresentacao`: a apresentação roda dentro do próprio app.

O estado é (cena, passo). Cada passo ACRESCENTA blocos na tela, então o
apresentador vai revelando conforme fala. As anotações de cada passo aparecem
no painel do apresentador (tecla `n`).

-}

import Cenas
import Cenas.Types exposing (Block(..), Scene, Step, visibleBlocks)
import Dict exposing (Dict)
import Html exposing (Html, button, div, h1, h2, li, p, pre, small, text, ul)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Json.Decode as D


type alias Model =
    { scene : Int
    , step : Int
    , showNotes : Bool
    }


type Msg
    = Next
    | Prev
    | NextScene
    | PrevScene
    | First
    | Last
    | ToggleNotes
    | ToggleFullscreen
    | Exit
    | Ignored


type alias Config msg =
    { toMsg : Msg -> msg
    , demo : Html msg
    , sources : Dict String String
    }


scenes : List ( String, Scene )
scenes =
    List.concatMap (\( section, list ) -> List.map (Tuple.pair section) list) Cenas.sections


sceneCount : Int
sceneCount =
    List.length scenes


stepCount : Int -> Int
stepCount scene =
    case List.head (List.drop scene scenes) of
        Just ( _, s ) ->
            List.length s.steps

        Nothing ->
            0


init : Int -> Int -> Model
init scene step =
    let
        s =
            clamp 0 (sceneCount - 1) scene
    in
    { scene = s, step = clamp 0 (stepCount s - 1) step, showNotes = True }


update : Msg -> Model -> Model
update msg model =
    case msg of
        Next ->
            if model.step < stepCount model.scene - 1 then
                { model | step = model.step + 1 }

            else if model.scene < sceneCount - 1 then
                { model | scene = model.scene + 1, step = 0 }

            else
                model

        Prev ->
            if model.step > 0 then
                { model | step = model.step - 1 }

            else if model.scene > 0 then
                { model | scene = model.scene - 1, step = stepCount (model.scene - 1) - 1 }

            else
                model

        NextScene ->
            if model.scene < sceneCount - 1 then
                { model | scene = model.scene + 1, step = 0 }

            else
                model

        PrevScene ->
            if model.scene > 0 then
                { model | scene = model.scene - 1, step = 0 }

            else
                model

        First ->
            { model | scene = 0, step = 0 }

        Last ->
            { model | scene = sceneCount - 1, step = stepCount (sceneCount - 1) - 1 }

        ToggleNotes ->
            { model | showNotes = not model.showNotes }

        _ ->
            model


keyDecoder : D.Decoder Msg
keyDecoder =
    D.field "key" D.string
        |> D.map
            (\key ->
                case key of
                    "ArrowRight" ->
                        Next

                    " " ->
                        Next

                    "PageDown" ->
                        Next

                    "ArrowLeft" ->
                        Prev

                    "PageUp" ->
                        Prev

                    "ArrowDown" ->
                        NextScene

                    "ArrowUp" ->
                        PrevScene

                    "Home" ->
                        First

                    "End" ->
                        Last

                    "n" ->
                        ToggleNotes

                    "f" ->
                        ToggleFullscreen

                    "Escape" ->
                        Exit

                    _ ->
                        Ignored
            )


view : Config msg -> Model -> Html msg
view config model =
    case List.head (List.drop model.scene scenes) of
        Nothing ->
            text "Sem cenas."

        Just ( section, scene ) ->
            let
                current =
                    List.head (List.drop model.step scene.steps)
            in
            div
                [ style "font-family" "sans-serif"
                , style "min-height" "100vh"
                , style "box-sizing" "border-box"
                , style "padding" "2rem 4rem"
                , style "background" "#fbf8f3"
                , style "display" "flex"
                , style "flex-direction" "column"
                ]
                [ small [ style "color" "#8f7a66" ] [ text (String.toUpper section) ]
                , h1 [ style "font-size" "2.6rem", style "margin" "0.3rem 0 1rem" ] [ text scene.title ]
                , div [ style "flex" "1", style "font-size" "1.5rem" ]
                    (List.map (viewBlockAt config model.step) (visibleBlocks model.step scene))
                , if model.showNotes then
                    viewNotes current

                  else
                    text ""
                , viewFooter config model scene
                ]


viewBlockAt : Config msg -> Int -> ( Int, Block ) -> Html msg
viewBlockAt config currentStep ( born, block ) =
    div
        [ style "opacity"
            (if born == currentStep then
                "1"

             else
                "0.85"
            )
        ]
        [ viewBlock config block ]


viewNotes : Maybe Step -> Html msg
viewNotes maybeStep =
    div
        [ style "border-top" "1px solid #d8cbb8"
        , style "margin-top" "1rem"
        , style "padding" "0.6rem 0"
        , style "font-size" "1rem"
        , style "color" "#5c4a3a"
        ]
        [ small [] [ text "ANOTAÇÃO DO APRESENTADOR (n): " ]
        , text (Maybe.map .notes maybeStep |> Maybe.withDefault "")
        ]


viewFooter : Config msg -> Model -> Scene -> Html msg
viewFooter config model scene =
    div [ style "display" "flex", style "gap" "0.5rem", style "align-items" "center" ]
        [ button [ onClick (config.toMsg Prev) ] [ text "←" ]
        , button [ onClick (config.toMsg Next) ] [ text "→" ]
        , button [ onClick (config.toMsg ToggleNotes) ] [ text "Notas (n)" ]
        , button [ onClick (config.toMsg ToggleFullscreen) ] [ text "Tela cheia (f)" ]
        , button [ onClick (config.toMsg Exit) ] [ text "Sair (Esc)" ]
        , small [ style "margin-left" "auto", style "color" "#8f7a66" ]
            [ text
                ("issue #"
                    ++ String.fromInt scene.issue
                    ++ "  |  cena "
                    ++ String.fromInt (model.scene + 1)
                    ++ "/"
                    ++ String.fromInt sceneCount
                    ++ "  passo "
                    ++ String.fromInt (model.step + 1)
                    ++ "/"
                    ++ String.fromInt (List.length scene.steps)
                )
            ]
        ]


viewBlock : Config msg -> Block -> Html msg
viewBlock config block =
    case block of
        Paragraph s ->
            p [] [ text s ]

        Bullets items ->
            ul [] (List.map (\i -> li [] [ text i ]) items)

        Pre s ->
            pre codeStyle [ text s ]

        Code { file, from, to, mark } ->
            pre codeStyle (excerpt config.sources file from to mark)

        Demo ->
            config.demo

        Clear ->
            text ""

        Pending hint ->
            div
                [ style "border" "2px dashed #c0392b"
                , style "padding" "1rem"
                , style "color" "#c0392b"
                ]
                [ h2 [ style "margin" "0 0 0.5rem" ] [ text "Cena pendente" ]
                , text hint
                ]


codeStyle : List (Html.Attribute msg)
codeStyle =
    [ style "background" "#2b2b2b"
    , style "color" "#eee"
    , style "padding" "1rem"
    , style "font-size" "1.1rem"
    , style "overflow" "auto"
    ]


excerpt : Dict String String -> String -> Int -> Int -> List Int -> List (Html msg)
excerpt sources file from to mark =
    case Dict.get file sources of
        Nothing ->
            [ text ("(arquivo não encontrado: " ++ file ++ ")") ]

        Just content ->
            let
                lines =
                    String.lines content

                start =
                    max 1 from

                last =
                    if to <= 0 then
                        List.length lines

                    else
                        to
            in
            lines
                |> List.indexedMap (\i l -> ( i + 1, l ))
                |> List.filter (\( n, _ ) -> n >= start && n <= last)
                |> List.map
                    (\( n, l ) ->
                        div
                            (if List.member n mark then
                                [ style "background" "#6b5b1f" ]

                             else
                                []
                            )
                            [ text (l ++ " ") ]
                    )
