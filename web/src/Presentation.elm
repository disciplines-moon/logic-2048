module Presentation exposing (Model, Msg(..), init, keyDecoder, sceneCount, update, view)

{-| Página `#/apresentacao`: a apresentação roda dentro do próprio app.

O estado é (cena, passo). Cada passo ACRESCENTA blocos na tela, então o
apresentador vai revelando conforme fala. As anotações de cada passo aparecem
no painel do apresentador (tecla `n`).

-}

import Cenas
import Cenas.Types exposing (Block(..), FlowNode, Scene, Step, visibleBlocks)
import Dict exposing (Dict)
import Html exposing (Html, button, div, h1, h2, kbd, li, p, pre, span, text, ul)
import Html.Attributes exposing (class, classList, style)
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
    | GoStep Int
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

        GoStep i ->
            { model | step = clamp 0 (stepCount model.scene - 1) i }

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
            div [ class "pres" ]
                [ viewProgress model
                , span [ class "pres-section" ] [ text (String.toUpper section) ]
                , h1 [] [ text scene.title ]
                , div [ class "pres-body" ]
                    (List.map (viewBlockAt config model.step) (visibleBlocks model.step scene))
                , if model.showNotes then
                    viewNotes (List.head (List.drop model.step scene.steps))

                  else
                    text ""
                , viewFooter config model scene
                ]


{-| Barra de progresso da apresentação inteira (por passo, não por cena).
-}
viewProgress : Model -> Html msg
viewProgress model =
    let
        total =
            scenes |> List.map (\( _, sc ) -> List.length sc.steps) |> List.sum

        before =
            scenes |> List.take model.scene |> List.map (\( _, sc ) -> List.length sc.steps) |> List.sum

        pct =
            toFloat (before + model.step + 1) / toFloat (max 1 total) * 100
    in
    div [ class "pres-progress" ]
        [ div [ style "width" (String.fromFloat pct ++ "%") ] [] ]


{-| Um bloco só anima quando acaba de nascer neste passo; os antigos ficam quietos.
O `key` no endereço do passo faz o navegador recriar o nó e rodar a animação.
-}
viewBlockAt : Config msg -> Int -> ( Int, Block ) -> Html msg
viewBlockAt config currentStep ( born, block ) =
    div [ classList [ ( "block", True ), ( "old", born /= currentStep ) ] ]
        [ viewBlock config block ]


viewNotes : Maybe Step -> Html msg
viewNotes maybeStep =
    div [ class "notes" ]
        [ Html.b [] [ text "FALA" ]
        , text (Maybe.map .notes maybeStep |> Maybe.withDefault "")
        ]


viewFooter : Config msg -> Model -> Scene -> Html msg
viewFooter config model scene =
    div []
        [ div [ class "pres-footer" ]
            [ button [ onClick (config.toMsg Prev) ] [ text "←" ]
            , button [ onClick (config.toMsg Next) ] [ text "→" ]
            , div [ class "dots" ]
                (List.indexedMap
                    (\i _ ->
                        button
                            [ classList [ ( "on", i == model.step ) ]
                            , onClick (config.toMsg (GoStep i))
                            , Html.Attributes.title ("passo " ++ String.fromInt (i + 1))
                            ]
                            []
                    )
                    scene.steps
                )
            , button [ onClick (config.toMsg ToggleNotes) ] [ text "Notas" ]
            , button [ onClick (config.toMsg ToggleFullscreen) ] [ text "Tela cheia" ]
            , button [ onClick (config.toMsg Exit) ] [ text "Sair" ]
            , span [ class "where" ]
                [ text
                    ("issue #"
                        ++ String.fromInt scene.issue
                        ++ "  |  cena "
                        ++ String.fromInt (model.scene + 1)
                        ++ "/"
                        ++ String.fromInt sceneCount
                        ++ "  |  passo "
                        ++ String.fromInt (model.step + 1)
                        ++ "/"
                        ++ String.fromInt (List.length scene.steps)
                    )
                ]
            ]
        , div [ class "hint-keys" ]
            [ kbd [] [ text "→" ]
            , text " próximo  "
            , kbd [] [ text "←" ]
            , text " voltar  "
            , kbd [] [ text "↓" ]
            , text " próxima cena  "
            , kbd [] [ text "n" ]
            , text " notas  "
            , kbd [] [ text "f" ]
            , text " tela cheia  "
            , kbd [] [ text "W A S D" ]
            , text " jogam na demo"
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
            pre [ class "pre" ] [ text s ]

        Code { file, from, to, mark } ->
            div [ class "code" ] (excerpt config.sources file from to mark)

        Demo ->
            div [ class "demo" ] [ config.demo ]

        Flow { nodes, active } ->
            viewFlow nodes active

        Clear ->
            text ""

        Pending hint ->
            div [ class "pending" ]
                [ h2 [] [ text "Cena pendente" ]
                , text hint
                ]


viewFlow : List FlowNode -> Int -> Html msg
viewFlow nodes active =
    let
        node i n =
            div
                [ class "node"
                , class ("k" ++ String.fromInt i)
                , classList [ ( "active", i == active ), ( "done", i < active ) ]
                ]
                [ div [ class "label" ] [ text n.label ]
                , div [ class "sub" ] [ text n.sub ]
                ]

        arrow i =
            span [ classList [ ( "arrow", True ), ( "lit", i < active ) ] ] [ text "→" ]

        withArrows =
            nodes
                |> List.indexedMap
                    (\i n ->
                        [ node i n ]
                            ++ (if i < List.length nodes - 1 then
                                    [ arrow i ]

                                else
                                    []
                               )
                    )
                |> List.concat

        detail =
            nodes |> List.drop active |> List.head |> Maybe.map .detail |> Maybe.withDefault ""
    in
    div []
        [ div [ class "flow" ] withArrows
        , div [ class "flow-return" ]
            [ text
                (if active == List.length nodes - 1 then
                    "↩  o resultado volta pelo mesmo caminho, em JSON"

                 else
                    ""
                )
            ]
        , div [ class "flow-detail" ] [ text detail ]
        ]


excerpt : Dict String String -> String -> Int -> Int -> List Int -> List (Html msg)
excerpt sources file from to mark =
    case Dict.get file sources of
        Nothing ->
            [ div [ class "line" ] [ text ("(arquivo não encontrado: " ++ file ++ ")") ] ]

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
                        div [ classList [ ( "line", True ), ( "mark", List.member n mark ) ] ]
                            [ span [ class "no" ] [ text (String.fromInt n) ]
                            , text (l ++ " ")
                            ]
                    )
