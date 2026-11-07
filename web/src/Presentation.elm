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
import Html.Keyed as Keyed
import Json.Decode as D
import Svg
import Svg.Attributes as SA


type alias Model =
    { scene : Int
    , step : Int
    , showNotes : Bool
    , forward : Bool
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
    { scene = s, step = clamp 0 (stepCount s - 1) step, showNotes = True, forward = True }


update : Msg -> Model -> Model
update msg model =
    case msg of
        Next ->
            if model.step < stepCount model.scene - 1 then
                { model | step = model.step + 1, forward = True }

            else if model.scene < sceneCount - 1 then
                { model | scene = model.scene + 1, step = 0, forward = True }

            else
                model

        Prev ->
            if model.step > 0 then
                { model | step = model.step - 1, forward = False }

            else if model.scene > 0 then
                { model | scene = model.scene - 1, step = stepCount (model.scene - 1) - 1, forward = False }

            else
                model

        NextScene ->
            if model.scene < sceneCount - 1 then
                { model | scene = model.scene + 1, step = 0, forward = True }

            else
                model

        PrevScene ->
            if model.scene > 0 then
                { model | scene = model.scene - 1, step = 0, forward = False }

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
                , Keyed.node "div"
                    [ class "scene" ]
                    [ ( String.fromInt model.scene
                      , div [ class "scene-in", classList [ ( "back", not model.forward ) ] ]
                            [ span [ class "pres-section" ] [ text (String.toUpper section) ]
                            , if scene.title == "" then
                                text ""

                              else
                                h1 [] [ text scene.title ]
                            , div [ class "pres-body" ]
                                (List.map (viewBlockAt config model.step) (visibleBlocks model.step scene))
                            ]
                      )
                    ]
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
            ul [] (List.indexedMap (\k i -> li [ style "animation-delay" (String.fromInt (k * 120) ++ "ms") ] [ text i ]) items)

        Pre s ->
            pre [ class "pre" ] [ text s ]

        Code { file, from, to, mark } ->
            div [ class "code" ] (excerpt config.sources file from to mark)

        Demo ->
            div [ class "demo" ] [ config.demo ]

        Lead s ->
            p [ class "lead" ] [ text s ]

        Hero { title, subtitle, chips } ->
            div [ class "hero" ]
                [ div [ class "hero-title" ] [ text title ]
                , p [ class "hero-sub" ] [ text subtitle ]
                , div [ class "chips" ] (List.map (\c -> span [ class "chip" ] [ text c ]) chips)
                ]

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
                [ if i == active then
                    div [ class "node-dot" ] []

                  else
                    text ""
                , div [ class "node-logo" ] [ nodeLogo n.art ]
                , div [ class "node-num" ] [ text (nodeNumber i) ]
                , div [ class "label" ] [ text n.label ]
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

        current =
            nodes |> List.drop active |> List.head

        detail =
            current |> Maybe.map .detail |> Maybe.withDefault ""

        art =
            current |> Maybe.map .art |> Maybe.withDefault ""
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
        , viewArt art
        ]


plTile : String -> Int -> Int -> String -> Int -> Html msg
plTile kind r c v dx =
    div
        [ class ("pt " ++ kind ++ " pv" ++ v ++ " pr" ++ String.fromInt r ++ " pc" ++ String.fromInt c ++ " pd" ++ String.fromInt (abs dx))
        ]
        [ text v ]


type alias Variant =
    { key : String
    , tiles : List MiniTile
    , after : List Int
    , before : Int
    , score : Int
    }


type alias MiniTile =
    { r : Int
    , c : Int
    , v : Int
    , dr : Int
    , dc : Int
    , kind : String
    }



-- Sequência real de 2048 (W, A, S, D): cada jogada parte do tabuleiro em que a anterior terminou.


variants : List Variant
variants =
    [ { key = "W", tiles = [ { r = 0, c = 0, v = 2, dr = 0, dc = 0, kind = "move" }, { r = 2, c = 1, v = 4, dr = -2, dc = 0, kind = "move" }, { r = 0, c = 2, v = 2, dr = 0, dc = 0, kind = "move" }, { r = 3, c = 3, v = 2, dr = -3, dc = 0, kind = "move" }, { r = 3, c = 0, v = 2, dr = 0, dc = 0, kind = "spawn" } ], after = [ 2, 4, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0 ], before = 0, score = 0 }
    , { key = "A", tiles = [ { r = 0, c = 0, v = 2, dr = 0, dc = 0, kind = "move" }, { r = 0, c = 1, v = 4, dr = 0, dc = 0, kind = "move" }, { r = 0, c = 2, v = 2, dr = 0, dc = 0, kind = "gone" }, { r = 0, c = 3, v = 2, dr = 0, dc = -1, kind = "gone" }, { r = 0, c = 2, v = 4, dr = 0, dc = 0, kind = "merged" }, { r = 3, c = 0, v = 2, dr = 0, dc = 0, kind = "move" }, { r = 1, c = 3, v = 2, dr = 0, dc = 0, kind = "spawn" } ], after = [ 2, 4, 4, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0 ], before = 0, score = 4 }
    , { key = "S", tiles = [ { r = 3, c = 0, v = 2, dr = 0, dc = 0, kind = "gone" }, { r = 0, c = 0, v = 2, dr = 3, dc = 0, kind = "gone" }, { r = 3, c = 0, v = 4, dr = 0, dc = 0, kind = "merged" }, { r = 0, c = 1, v = 4, dr = 3, dc = 0, kind = "move" }, { r = 0, c = 2, v = 4, dr = 3, dc = 0, kind = "move" }, { r = 1, c = 3, v = 2, dr = 2, dc = 0, kind = "move" }, { r = 0, c = 3, v = 4, dr = 0, dc = 0, kind = "spawn" } ], after = [ 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 4, 4, 4, 2 ], before = 4, score = 8 }
    , { key = "D", tiles = [ { r = 0, c = 3, v = 4, dr = 0, dc = 0, kind = "move" }, { r = 3, c = 3, v = 2, dr = 0, dc = 0, kind = "move" }, { r = 3, c = 2, v = 4, dr = 0, dc = 0, kind = "gone" }, { r = 3, c = 1, v = 4, dr = 0, dc = 1, kind = "gone" }, { r = 3, c = 2, v = 8, dr = 0, dc = 0, kind = "merged" }, { r = 3, c = 0, v = 4, dr = 0, dc = 1, kind = "move" }, { r = 2, c = 0, v = 2, dr = 0, dc = 0, kind = "spawn" } ], after = [ 0, 0, 0, 4, 0, 0, 0, 0, 2, 0, 0, 0, 0, 4, 8, 2 ], before = 8, score = 16 }
    ]


slotStack : (Variant -> Html msg) -> Html msg
slotStack f =
    div [ class "slot-stack" ]
        (List.indexedMap
            (\j vt ->
                div
                    [ class "slot-v"
                    , style "animation-delay"
                        (String.fromFloat
                            (if j == 0 then
                                0

                             else
                                toFloat j * 7.2 - 28.8
                            )
                            ++ "s"
                        )
                    ]
                    [ f vt ]
            )
            variants
        )


miniTile : MiniTile -> Html msg
miniTile t =
    div
        [ class ("mt mt-" ++ t.kind ++ " mv" ++ String.fromInt t.v ++ " mr" ++ String.fromInt t.r ++ " mc" ++ String.fromInt t.c)
        , Html.Attributes.attribute "style" ("--dx:" ++ String.fromInt t.dc ++ ";--dy:" ++ String.fromInt t.dr)
        ]
        [ text (String.fromInt t.v) ]


miniBoard : List (Html msg) -> Html msg
miniBoard tiles =
    div [ class "mb" ] (List.map (\_ -> div [ class "mb-cell" ] []) (List.range 1 16) ++ tiles)


stageVis : Int -> Html msg
stageVis i =
    case i of
        0 ->
            slotStack
                (\vt ->
                    div [ class "msg-vis" ]
                        [ div [ class "msg-label" ] [ text (moveLabel vt.key) ]
                        , div [ class "msg-big" ] [ text (moveArrow vt.key) ]
                        ]
                )

        1 ->
            slotStack
                (\vt ->
                    div [ class "upd" ]
                        [ miniBoard (List.map miniTile vt.tiles)
                        , div [ class "upd-cap" ]
                            [ span [ class "cap-pl" ] [ text "Prolog move" ]
                            , span [ class "cap-elm" ] [ text "Elm sorteia" ]
                            ]
                        ]
                )

        2 ->
            slotStack
                (\vt ->
                    div [ class "mdl" ]
                        [ span [ class "mdl-k" ] [ text "score" ]
                        , div [ class "mdl-nums" ]
                            [ span [ class "mdl-val sv-old" ] [ text (String.fromInt vt.before) ]
                            , span [ class "mdl-val sv-new" ] [ text (String.fromInt vt.score) ]
                            ]
                        , span [ class "mdl-gain sv-gain" ] [ text ("+" ++ String.fromInt (vt.score - vt.before) ++ " Prolog") ]
                        , span [ class "mdl-meta" ] [ text ("jogada " ++ moveNumber vt.key ++ " de 4") ]
                        ]
                )

        3 ->
            slotStack
                (\vt ->
                    div [ class "sv-screen" ]
                        [ div [ class "sv-pop" ]
                            [ miniBoard
                                (List.indexedMap
                                    (\k v ->
                                        if v == 0 then
                                            text ""

                                        else
                                            miniTile { r = k // 4, c = modBy 4 k, v = v, dr = 0, dc = 0, kind = "static" }
                                    )
                                    vt.after
                                )
                            ]
                        ]
                )

        _ ->
            text ""


moveLabel : String -> String
moveLabel key =
    moves |> List.filter (\( k, _ ) -> k == key) |> List.head |> Maybe.map Tuple.second |> Maybe.withDefault ""


moveArrow : String -> String
moveArrow key =
    case key of
        "W" ->
            "↑"

        "A" ->
            "←"

        "S" ->
            "↓"

        _ ->
            "→"


outTile : MiniTile -> Html msg
outTile t =
    div
        [ class
            ("pt po-"
                ++ t.kind
                ++ " pv"
                ++ String.fromInt t.v
                ++ " pr"
                ++ String.fromInt t.r
                ++ " pc"
                ++ String.fromInt t.c
                ++ " "
                ++ axisClass "dx" t.dc
                ++ " "
                ++ axisClass "dy" t.dr
            )
        ]
        [ text (String.fromInt t.v) ]


axisClass : String -> Int -> String
axisClass axis n =
    axis
        ++ (if n < 0 then
                "m"

            else
                "p"
           )
        ++ String.fromInt (abs n)


dirName : String -> String
dirName key =
    case key of
        "W" ->
            "up"

        "A" ->
            "left"

        "S" ->
            "down"

        _ ->
            "right"


moveNumber : String -> String
moveNumber key =
    case key of
        "W" ->
            "1"

        "A" ->
            "2"

        "S" ->
            "3"

        _ ->
            "4"


moves : List ( String, String )
moves =
    [ ( "W", "↑ Move Up" ), ( "A", "← Move Left" ), ( "S", "↓ Move Down" ), ( "D", "→ Move Right" ) ]


pressKeyFast : String -> Int -> Html msg
pressKeyFast label i =
    div [ class "key press fast", style "animation-delay" (String.fromFloat (toFloat i * 1.2) ++ "s") ] [ text label ]


pressKey : String -> Int -> Html msg
pressKey label i =
    div [ class "key press", style "animation-delay" (String.fromFloat (toFloat i * 7.2) ++ "s") ] [ text label ]


viewArt : String -> Html msg
viewArt kind =
    case kind of
        "keyboard" ->
            div [ class "art art-keyboard" ]
                [ div [ class "key-row" ] [ pressKeyFast "W" 0 ]
                , div [ class "key-row" ] [ pressKeyFast "A" 1, pressKeyFast "S" 2, pressKeyFast "D" 3 ]
                ]

        "elm" ->
            div [ class "art art-elm" ]
                [ div [ class "mini-kb" ]
                    [ div [ class "key-row" ] [ pressKey "W" 0 ]
                    , div [ class "key-row" ] [ pressKey "A" 1, pressKey "S" 2, pressKey "D" 3 ]
                    ]
                , div [ class "msg-lane" ]
                    (List.indexedMap
                        (\i ( k, msg ) -> div [ class "msg-chip", style "animation-delay" (String.fromFloat (toFloat i * 7.2) ++ "s") ] [ span [ class "chip-key" ] [ text k ], text msg ])
                        moves
                    )
                , div [ class "elm-box" ]
                    [ div [ class "elm-title" ] [ elmLogo, text "Elm" ]
                    , div [ class "elm-loop" ]
                        (List.indexedMap
                            (\i ( label, hint ) ->
                                div [ class "cycle", style "animation-delay" (String.fromFloat (2.8 + toFloat i * 1.0) ++ "s") ]
                                    [ span [ class "cycle-name" ] [ text label ]
                                    , stageVis i
                                    ]
                            )
                            [ ( "Msg", "" ), ( "update", "calcula o novo Model" ), ( "Model", "board + score" ), ( "view", "HTML na tela" ) ]
                        )
                    ]
                ]

        "python" ->
            div [ class "art art-py" ]
                [ div [ class "pcard in-card" ]
                    [ div [ class "pcard-head" ] [ text "POST /api/move  ·  JSON" ]
                    , div [ class "tok" ] [ span [ class "p" ] [ text "{" ] ]
                    , div [ class "tok ind board-row" ]
                        [ span [ class "k" ] [ text "\"board\"" ]
                        , span [ class "p" ] [ text ": " ]
                        , div [ class "mini-grid" ]
                            (List.map (\v -> div [ class "mg", classList [ ( "mg-on", v /= "" ) ] ] [ text v ]) [ "2", "", "", "2", "", "", "", "", "", "", "4", "", "", "", "", "" ])
                        ]
                    , div [ class "tok ind" ] [ span [ class "k" ] [ text "\"direction\"" ], span [ class "p" ] [ text ": " ], span [ class "s" ] [ text "\"right\"" ] ]
                    , div [ class "tok" ] [ span [ class "p" ] [ text "}" ] ]
                    ]
                , div [ class "py-box" ]
                    [ pythonLogo
                    , div [ class "py-title" ] [ text "Python" ]
                    , div [ class "py-check" ] [ text "✓ entrada válida" ]
                    , div [ class "py-sub" ] [ text "JSON → termo Prolog" ]
                    ]
                , div [ class "pcard out-card" ]
                    [ div [ class "pcard-head" ] [ text "consulta Prolog" ]
                    , div [ class "tok" ] [ span [ class "f" ] [ text "move" ], span [ class "p" ] [ text "(" ] ]
                    , div [ class "tok ind" ] [ span [ class "n" ] [ text "[[2,0,0,2], ..., [0,0,0,0]]" ], span [ class "p" ] [ text "," ] ]
                    , div [ class "tok ind" ] [ span [ class "s" ] [ text "right" ], span [ class "p" ] [ text "," ] ]
                    , div [ class "tok ind" ] [ span [ class "v" ] [ text "Novo" ], span [ class "p" ] [ text ", " ], span [ class "v" ] [ text "Pontos" ] ]
                    , div [ class "tok" ] [ span [ class "p" ] [ text ")." ] ]
                    ]
                ]

        "prolog" ->
            div [ class "art art-pl" ]
                [ div [ class "pl-col" ]
                    [ div [ class "pl-label" ] [ span [ class "v" ] [ text "Board" ], text "  o que o Elm mandou" ]
                    , slotStack
                        (\vt ->
                            div [ class "pl-in-wrap" ]
                                [ div [ class "pboard" ]
                                    (List.map (\_ -> div [ class "pcell" ] []) (List.range 1 16)
                                        ++ (vt.tiles
                                                |> List.filter (\t -> t.kind == "move" || t.kind == "gone")
                                                |> List.map (\t -> plTile "pt-in" t.r t.c (String.fromInt t.v) 0)
                                           )
                                    )
                                , div [ class "pl-dir" ] [ span [ class "chip-key" ] [ text vt.key ], text (" = " ++ moveArrow vt.key ++ " " ++ dirName vt.key) ]
                                ]
                        )
                    ]
                , div [ class "pl-arrow" ] [ text "→" ]
                , slotStack
                    (\vt ->
                        div [ class "pcard pl-clause" ]
                            [ div [ class "pcard-head" ] [ text ("regra, direção " ++ dirName vt.key) ]
                            , div [ class "tok" ] [ span [ class "f" ] [ text "move" ], span [ class "p" ] [ text "(" ], span [ class "v" ] [ text "Board" ], span [ class "p" ] [ text ", " ], span [ class "s" ] [ text (dirName vt.key) ], span [ class "p" ] [ text ", " ], span [ class "v" ] [ text "New" ], span [ class "p" ] [ text ", " ], span [ class "v" ] [ text "Score" ], span [ class "p" ] [ text ") :-" ] ]
                            , div [ class "tok ind ln ln1" ] [ span [ class "f" ] [ text "slide_rows" ], span [ class "p" ] [ text "(...)," ], span [ class "ln-note" ] [ text ("  % encosta tudo para " ++ dirName vt.key) ] ]
                            , div [ class "tok ind ln ln2" ] [ span [ class "f" ] [ text "merge_equal" ], span [ class "p" ] [ text "(...)." ], span [ class "ln-note" ] [ text "  % junta iguais e soma" ] ]
                            ]
                    )
                , div [ class "pl-arrow" ] [ text "→" ]
                , div [ class "pl-col" ]
                    [ div [ class "pl-label" ] [ span [ class "v" ] [ text "New" ], text "  resposta" ]
                    , slotStack
                        (\vt ->
                            div [ class "pl-in-wrap" ]
                                [ div [ class "pboard" ]
                                    (List.map (\_ -> div [ class "pcell" ] []) (List.range 1 16)
                                        ++ (vt.tiles
                                                |> List.filter (\t -> t.kind /= "spawn")
                                                |> List.map outTile
                                           )
                                    )
                                , div [ class "pl-label pl-scoreline" ] [ span [ class "v" ] [ text "Score" ], text " = ", span [ class "pl-score" ] [ text ("+" ++ String.fromInt (vt.score - vt.before)) ] ]
                                ]
                        )
                    , div [ class "pl-label pl-note" ] [ text "sem peça nova: quem sorteia é o Elm" ]
                    ]
                ]

        _ ->
            text ""


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
                        div
                            [ classList [ ( "line", True ), ( "mark", List.member n mark ) ]
                            , style "animation-delay" (String.fromInt (min 600 ((n - start) * 30)) ++ "ms")
                            ]
                            [ span [ class "no" ] [ text (String.fromInt n) ]
                            , text (l ++ " ")
                            ]
                    )


pythonLogo : Html msg
pythonLogo =
    Svg.svg [ SA.viewBox "0 0 40 40", SA.class "logo" ]
        [ Svg.path [ SA.d "M20 3 C11 3 11 7 11 7 V12 H21 V14 H8 C8 14 3 14 3 22 C3 30 8 30 8 30 H11 V26 C11 26 11 21 16 21 H25 C25 21 29 21 29 17 V8 C29 8 30 3 20 3 Z", SA.fill "#3776ab" ] []
        , Svg.path [ SA.d "M20 37 C29 37 29 33 29 33 V28 H19 V26 H32 C32 26 37 26 37 18 C37 10 32 10 32 10 H29 V14 C29 14 29 19 24 19 H15 C15 19 11 19 11 23 V32 C11 32 10 37 20 37 Z", SA.fill "#ffd43b" ] []
        , Svg.circle [ SA.cx "16", SA.cy "8", SA.r "1.5", SA.fill "#fff" ] []
        , Svg.circle [ SA.cx "24", SA.cy "32", SA.r "1.5", SA.fill "#fff" ] []
        ]


elmLogo : Html msg
elmLogo =
    Svg.svg [ SA.viewBox "0 0 32 32", SA.class "logo logo-sm" ]
        [ Svg.polygon [ SA.points "0,0 16,0 8,8", SA.fill "#f0ad00" ] []
        , Svg.polygon [ SA.points "18,0 32,0 32,14 25,7", SA.fill "#7fd13b" ] []
        , Svg.polygon [ SA.points "0,2 14,16 0,30", SA.fill "#5a6378" ] []
        , Svg.polygon [ SA.points "16,18 32,18 32,32 16,32", SA.fill "#60b5cc" ] []
        , Svg.polygon [ SA.points "32,2 32,16 18,2", SA.fill "#60b5cc" ] []
        ]


nodeNumber : Int -> String
nodeNumber i =
    case i of
        0 ->
            "2"

        1 ->
            "8"

        2 ->
            "64"

        _ ->
            "2048"


nodeLogo : String -> Html msg
nodeLogo kind =
    case kind of
        "keyboard" ->
            keyboardLogo

        "elm" ->
            elmLogo

        "python" ->
            pythonLogo

        "prolog" ->
            prologLogo

        _ ->
            text ""


keyboardLogo : Html msg
keyboardLogo =
    Svg.svg [ SA.viewBox "0 0 40 40", SA.class "logo" ]
        [ Svg.rect [ SA.x "2", SA.y "9", SA.width "36", SA.height "22", SA.rx "4", SA.fill "#776e65" ] []
        , Svg.g [ SA.fill "#eee4da" ]
            [ Svg.rect [ SA.x "6", SA.y "13", SA.width "5", SA.height "5", SA.rx "1" ] []
            , Svg.rect [ SA.x "13", SA.y "13", SA.width "5", SA.height "5", SA.rx "1" ] []
            , Svg.rect [ SA.x "20", SA.y "13", SA.width "5", SA.height "5", SA.rx "1" ] []
            , Svg.rect [ SA.x "27", SA.y "13", SA.width "7", SA.height "5", SA.rx "1" ] []
            , Svg.rect [ SA.x "8", SA.y "21", SA.width "24", SA.height "6", SA.rx "1" ] []
            ]
        ]


prologLogo : Html msg
prologLogo =
    Svg.svg [ SA.viewBox "0 0 40 40", SA.class "logo" ]
        [ Svg.circle [ SA.cx "20", SA.cy "20", SA.r "18", SA.fill "#c0392b" ] []
        , Svg.text_ [ SA.x "20", SA.y "26", SA.textAnchor "middle", SA.fontSize "17", SA.fontWeight "800", SA.fill "#fff", SA.fontFamily "monospace" ] [ Svg.text ":-" ]
        ]
