module Presentation exposing (Model, Msg(..), Sent, init, keyDecoder, keyToMsg, sceneCount, send, sendTo, update, view)

{-| Página `#/apresentacao`: a apresentação roda dentro do próprio app.

O estado é (cena, passo). Cada passo ACRESCENTA blocos na tela, então o
apresentador vai revelando conforme fala. As anotações de cada passo aparecem
no painel do apresentador (tecla `n`).

-}

import Api
import Cenas
import Cenas.Equipe
import Cenas.Types exposing (Block(..), Etapa, FlowNode, Member, Pedido, Scene, Step, visibleBlocks)
import Dict exposing (Dict)
import Html exposing (Html, button, div, h1, h2, kbd, li, p, pre, span, text, ul)
import Html.Attributes exposing (attribute, class, classList, style)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Http
import Json.Decode as D
import Json.Encode as E
import Svg
import Svg.Attributes as SA


{-| `request` é o último pedido do bloco `Pedidos`. Ele não vem da URL, então o
`Main` o preserva quando a URL muda.
-}
type alias Model =
    { scene : Int
    , step : Int
    , showNotes : Bool
    , forward : Bool
    , request : Maybe Sent
    }


{-| Um pedido enviado pelo bloco `Pedidos`. `answer` é `Nothing` enquanto o
servidor não responde.
-}
type alias Sent =
    { url : String
    , body : String
    , answer : Maybe (Result Http.Error Api.RawResponse)
    }


{-| `SendRequest` marca o pedido como enviado; quem manda de fato é o `Main`, com
`send`, como faz com a tela cheia. `GotResponse` traz a rota e o corpo que responderam, para
descartar respostas atrasadas de outro pedido.
-}
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
    | SendRequest String
    | SendRequestTo String String
    | GotResponse String String (Result Http.Error Api.RawResponse)
    | Ignored


{-| `loadBoard` é a mensagem que troca o tabuleiro da `Demo` (blocos `Cenarios`).
-}
type alias Config msg =
    { toMsg : Msg -> msg
    , demo : Html msg
    , loadBoard : List (List Int) -> msg
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
    { scene = s, step = clamp 0 (stepCount s - 1) step, showNotes = True, forward = True, request = Nothing }


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

        SendRequest body ->
            update (SendRequestTo "/api/move" body) model

        SendRequestTo url body ->
            { model | request = Just { url = url, body = body, answer = Nothing } }

        GotResponse url body result ->
            case model.request of
                Just sent ->
                    -- Só vale a resposta do pedido atual: mesma rota e mesmo corpo.
                    if sent.url == url && sent.body == body then
                        { model | request = Just { sent | answer = Just result } }

                    else
                        model

                Nothing ->
                    model

        _ ->
            model


{-| Manda o corpo do bloco `Pedidos` ao `POST /api/move` de verdade.
-}
send : String -> Cmd Msg
send body =
    sendTo "/api/move" body


{-| O mesmo, para outra rota (bloco `PedidosEm`). Sem corpo, é um GET.
-}
sendTo : String -> String -> Cmd Msg
sendTo url body =
    if String.isEmpty body then
        Api.getRaw url (GotResponse url body)

    else
        Api.postRaw url body (GotResponse url body)


keyDecoder : D.Decoder Msg
keyDecoder =
    D.map5
        (\key ctrl alt meta repeat ->
            if ctrl || alt || meta || repeat then
                Ignored

            else
                keyToMsg key
        )
        (D.field "key" D.string)
        (D.field "ctrlKey" D.bool)
        (D.field "altKey" D.bool)
        (D.field "metaKey" D.bool)
        (D.field "repeat" D.bool)


{-| Setas, PageUp/Down, Home/End e Esc navegam; N e F (maiúsculas também) abrem notas e tela cheia.
O espaço não está ligado de propósito: com um botão focado ele também o acionaria.
-}
keyToMsg : String -> Msg
keyToMsg key =
    case key of
        "ArrowRight" ->
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

        "Escape" ->
            Exit

        _ ->
            case String.toLower key of
                "n" ->
                    ToggleNotes

                "f" ->
                    ToggleFullscreen

                _ ->
                    Ignored


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
                                (List.map (viewBlockAt config model) (visibleBlocks model.step scene))
                            ]
                      )
                    ]
                , if model.showNotes then
                    viewNotes scene.issue (List.head (List.drop model.step scene.steps))

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
viewBlockAt : Config msg -> Model -> ( Int, Block ) -> Html msg
viewBlockAt config model ( born, block ) =
    div [ classList [ ( "block", True ), ( "old", born /= model.step ) ] ]
        [ viewBlock config model.request block ]


{-| A fala do passo, com a foto e o nome de quem apresenta (o dono da issue).
-}
viewNotes : Int -> Maybe Step -> Html msg
viewNotes issue maybeStep =
    div [ class "notes" ]
        [ case Cenas.Equipe.apresentador issue of
            Just m ->
                -- Na mesma linha da fala, para não roubar largura do texto.
                span [ class "speaker" ]
                    [ span [ class "speaker-avatar" ]
                        [ span [ class "initial" ] [ text (String.left 1 m.name) ]
                        , Html.img [ Html.Attributes.src ("https://github.com/" ++ m.login ++ ".png?size=96"), Html.Attributes.alt "", Html.Attributes.attribute "referrerpolicy" "no-referrer" ] []
                        ]
                    , span [ class "speaker-name" ] [ text m.name ]
                    ]

            Nothing ->
                text ""
        , Html.b [] [ text "FALA" ]
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


viewBlock : Config msg -> Maybe Sent -> Block -> Html msg
viewBlock config request block =
    case block of
        Paragraph s ->
            p [] [ text s ]

        Bullets items ->
            ul [] (List.indexedMap (\k i -> li [ style "animation-delay" (String.fromInt (k * 120) ++ "ms") ] [ text i ]) items)

        Pre s ->
            pre [ class "pre" ] [ text s ]

        Code { file, from, to, mark } ->
            -- Trecho longo (mais de 18 linhas) usa letra menor, para a cena caber sem rolar.
            div [ class "code", classList [ ( "long", to - from + 1 > 18 ) ] ] (excerpt config.sources file from to mark)

        Demo ->
            div [ class "demo" ] [ config.demo ]

        Team members ->
            div [ class "team" ] (List.indexedMap viewMember members)

        Lead s ->
            p [ class "lead" ] [ text s ]

        Slide row ->
            viewSlide row

        Fases row ->
            viewFases row

        Corte ->
            viewCorte

        Etapas etapas ->
            viewEtapas etapas

        Tabuleiros etapas ->
            div [ class "eb-grid" ] (List.map viewMiniBoard etapas)

        Cenarios etapas ->
            div [ class "cenarios" ]
                (List.map
                    (\etapa -> button [ class "cenario", onClick (config.loadBoard etapa.board) ] [ viewMiniBoard etapa ])
                    etapas
                )

        Hero { title, subtitle, chips } ->
            div [ class "hero" ]
                [ div [ class "hero-title" ] [ text title ]
                , p [ class "hero-sub" ] [ text subtitle ]
                , div [ class "chips" ] (List.map (\c -> span [ class "chip" ] [ text c ]) chips)
                ]

        Flow { nodes, active, back } ->
            viewFlow nodes active back

        Pedidos pedidos ->
            viewPedidos config request "/api/move" pedidos

        PedidosEm url pedidos ->
            viewPedidos config request url pedidos

        Clear ->
            text ""

        Pending hint ->
            div [ class "pending" ]
                [ h2 [] [ text "Cena pendente" ]
                , text hint
                ]


{-| O que acontece com uma peça da linha ao deslizar para a esquerda.
`Stay` anda sem fundir; `Keep` é a primeira do par e vira o dobro; `Gone` é a
segunda do par e some dentro da primeira.
-}
type Fate
    = Stay
    | Keep
    | Gone


type alias Mover =
    { from : Int
    , to : Int
    , value : Int
    , fate : Fate
    }


{-| Mesmo algoritmo do `merge/3` do Prolog: percorre as peças não vazias e, se as
duas primeiras são iguais, funde as duas (e segue no resto, nunca na peça nova).
-}
planSlide : List Int -> List Mover
planSlide row =
    let
        go : List ( Int, Int ) -> Int -> List Mover
        go tiles slot =
            case tiles of
                ( i, x ) :: ( j, y ) :: rest ->
                    if x == y then
                        { from = i, to = slot, value = x, fate = Keep }
                            :: { from = j, to = slot, value = y, fate = Gone }
                            :: go rest (slot + 1)

                    else
                        { from = i, to = slot, value = x, fate = Stay } :: go (( j, y ) :: rest) (slot + 1)

                ( i, x ) :: [] ->
                    [ { from = i, to = slot, value = x, fate = Stay } ]

                [] ->
                    []
    in
    row
        |> List.indexedMap Tuple.pair
        |> List.filter (\( _, v ) -> v /= 0)
        |> (\tiles -> go tiles 0)


viewSlide : List Int -> Html msg
viewSlide row =
    let
        movers =
            planSlide row

        n =
            List.length row

        points =
            movers
                |> List.filter (\m -> m.fate == Keep)
                |> List.map (\m -> 2 * m.value)
                |> List.sum

        result =
            List.range 0 (n - 1)
                |> List.map
                    (\s ->
                        movers
                            |> List.filter (\m -> m.to == s && m.fate /= Gone)
                            |> List.head
                            |> Maybe.map
                                (\m ->
                                    m.value
                                        * (if m.fate == Keep then
                                            2

                                           else
                                            1
                                          )
                                )
                            |> Maybe.withDefault 0
                    )

        listText xs =
            "[" ++ String.join ", " (List.map String.fromInt xs) ++ "]"

        tile v extra =
            div [ class ("tile v" ++ String.fromInt v ++ extra) ] [ text (String.fromInt v) ]

        viewMover m =
            div
                [ class "sl-mover"
                , attribute "style" ("--i:" ++ String.fromInt m.from ++ ";--dx:" ++ String.fromInt (m.to - m.from))
                ]
                (case m.fate of
                    Keep ->
                        [ div [ class "sl-old" ] [ tile m.value "" ]
                        , div [ class "sl-new" ] [ tile (2 * m.value) "" ]
                        ]

                    Gone ->
                        [ div [ class "sl-gone" ] [ tile m.value "" ] ]

                    Stay ->
                        [ tile m.value "" ]
                )
    in
    div [ class "sl-wrap" ]
        [ div [ class "sl-caption" ]
            [ text (listText row ++ "  →  " ++ listText result) ]
        , div [ class "sl-loop", attribute "style" ("--n:" ++ String.fromInt n) ]
            (List.map (\_ -> div [ class "sl-cell" ] []) row
                ++ List.map viewMover movers
                ++ (if points > 0 then
                        [ div [ class "sl-points" ] [ text ("+" ++ String.fromInt points) ] ]

                    else
                        []
                   )
            )
        ]


{-| Quatro linhas que aparecem uma a uma: entrada, depois de `exclude`, depois de
`merge` e depois de `pad_zeros`. Cada linha nasce no seu momento do ciclo.
-}
viewFases : List Int -> Html msg
viewFases row =
    let
        tiles =
            List.filter (\v -> v /= 0) row

        merged =
            planSlide row
                |> List.filterMap
                    (\m ->
                        case m.fate of
                            Keep ->
                                Just (2 * m.value)

                            Stay ->
                                Just m.value

                            Gone ->
                                Nothing
                    )

        padded =
            merged ++ List.repeat (List.length row - List.length merged) 0

        tile v =
            if v == 0 then
                div [ class "sl-cell" ] []

            else
                div [ class ("tile v" ++ String.fromInt v) ] [ text (String.fromInt v) ]

        line k label values =
            div [ class ("fs-row fs" ++ String.fromInt k) ]
                [ div [ class "fs-label" ] [ text label ]
                , div [ class "fs-tiles" ] (List.map tile values)
                ]
    in
    div [ class "fs-loop" ]
        [ line 0 "Row" row
        , line 1 "exclude(==(0), Row, Tiles)" tiles
        , line 2 "merge(Tiles, Merged, Points)" merged
        , line 3 "pad_zeros(Row, Merged, NewRow)" padded
        ]


{-| Com e sem o `!`, a mesma linha `[2,2,0,0]`. As duas animações dividem o mesmo
ciclo de 6 s do bloco `Slide`.
-}
viewCorte : Html msg
viewCorte =
    let
        tile v =
            if v == 0 then
                div [ class "sl-cell" ] []

            else
                div [ class ("tile v" ++ String.fromInt v) ] [ text (String.fromInt v) ]

        -- Segunda resposta, pedida com `;`: com o corte não existe; sem o corte
        -- o Prolog volta atrás e entrega a linha sem fundir.
        second tag label row =
            div [ class ("ct-second " ++ tag) ]
                [ div [ class "ct-row" ] (List.map tile row)
                , div [ class "ct-verdict" ] [ text label ]
                ]

        panel title tag second_ =
            div [ class ("ct-panel " ++ tag) ]
                [ div [ class "ct-title" ] [ text title, span [ class "ct-bang" ] [ text "!" ] ]
                , viewSlide [ 2, 2, 0, 0 ]
                , second_
                ]

        -- Sem o corte: uma linha só. As duas peças tentam se fundir, tremem e
        -- voltam, porque o Prolog entrega a resposta sem fusão.
        semPanel =
            div [ class "ct-panel ct-sem" ]
                [ div [ class "ct-title" ] [ text "sem ", span [ class "ct-bang" ] [ text "!" ] ]
                , div [ class "sl-caption" ] [ text "[2, 2, 0, 0]  →  [2, 2, 0, 0]  (não fundiu)" ]
                , div [ class "ct-row ct-solo" ] (List.map tile [ 2, 2, 0, 0 ])
                , div [ class "ct-verdict" ] [ text "Sem o corte, o Prolog volta atrás (;), tenta a cláusula sem fusão e o par NÃO funde: L = [2,2,0,0], P = 0. Resposta errada." ]
                ]
    in
    div [ class "ct-wrap" ]
        [ panel "com " "ct-com" (second "ct-com" "pede outra (;): false. O corte fechou a porta, então só existe a resposta acima." [])
        , semPanel
        ]


{-| Um tabuleiro pequeno com legenda, nas mesmas cores de peça do jogo.
-}
viewMiniBoard : Etapa -> Html msg
viewMiniBoard etapa =
    let
        cell v =
            if v == 0 then
                div [ class "eb-cell" ] []

            else
                div [ class ("tile v" ++ String.fromInt v) ] [ text (String.fromInt v) ]
    in
    div [ class "eb" ]
        [ div [ class "eb-board", attribute "style" ("--n:" ++ String.fromInt (List.length etapa.board)) ]
            (List.concatMap (List.map cell) etapa.board)
        , div [ class "eb-label" ]
            [ text etapa.label
            , if etapa.note == "" then
                text ""

              else
                span [ class "eb-note" ] [ text etapa.note ]
            ]
        ]


{-| Tabuleiros ligados por setas. A etapa `k` (com a seta que chega nela) nasce
no seu momento do ciclo de 10 s (classes `et0` a `et4`, veja o `main.css`).
-}
viewEtapas : List Etapa -> Html msg
viewEtapas etapas =
    div [ class "et-chain" ]
        (List.indexedMap
            (\k etapa ->
                div [ class ("et-step et" ++ String.fromInt (min k 4)) ]
                    [ if k == 0 then
                        text ""

                      else
                        div [ class "et-arrow" ] [ text "→" ]
                    , viewMiniBoard etapa
                    ]
            )
            etapas
        )


viewFlow : List FlowNode -> Int -> String -> Html msg
viewFlow nodes active back =
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
                    back

                 else
                    ""
                )
            ]
        , div [ class "flow-detail" ] [ text detail ]
        , viewArt art
        ]


{-| Botões com pedidos prontos e, depois do primeiro clique, o pedido enviado ao
lado da resposta real do servidor.
-}
viewPedidos : Config msg -> Maybe Sent -> String -> List Pedido -> Html msg
viewPedidos config request url pedidos =
    let
        current =
            Maybe.map (\sent -> ( sent.url, sent.body )) request

        pedidoButton pedido =
            button
                [ classList [ ( "pd-button", True ), ( "on", current == Just ( url, pedido.body ) ) ]
                , onClick (config.toMsg (SendRequestTo url pedido.body))
                ]
                [ text pedido.label ]

        -- Um pedido feito em outra cena (outra rota) não aparece aqui.
        here =
            request
                |> Maybe.andThen
                    (\sent ->
                        if sent.url == url then
                            Just sent

                        else
                            Nothing
                    )
    in
    div [ class "pd" ]
        [ div [ class "pd-buttons" ] (List.map pedidoButton pedidos)
        , case here of
            Nothing ->
                div [ class "pd-hint" ] [ text "Clique num pedido: ele vai de verdade ao servidor." ]

            Just sent ->
                -- O `key` recria o painel do pedido quando o pedido muda, e o da resposta
                -- a cada estado novo (esperando, 200, 422...), para a animação de entrada rodar.
                Keyed.node "div"
                    [ class "pd-panes" ]
                    [ ( sent.body
                      , div [ class "pd-pane pd-request" ]
                            [ div [ class "pd-head" ] [ text (method sent.body ++ " " ++ sent.url) ]
                            , pre [ class "pd-json" ]
                                [ text
                                    (if String.isEmpty sent.body then
                                        "(sem corpo)"

                                     else
                                        sent.body
                                    )
                                ]
                            ]
                      )
                    , ( "seta", div [ class "pd-arrow" ] [ text "→" ] )
                    , ( sent.body ++ answerKey sent.answer, viewAnswer sent.answer )
                    ]
        ]


method : String -> String
method body =
    if String.isEmpty body then
        "GET"

    else
        "POST"


answerKey : Maybe (Result Http.Error Api.RawResponse) -> String
answerKey answer =
    case answer of
        Nothing ->
            "esperando"

        Just (Ok res) ->
            String.fromInt res.status

        Just (Err _) ->
            "sem resposta"


viewAnswer : Maybe (Result Http.Error Api.RawResponse) -> Html msg
viewAnswer answer =
    case answer of
        Nothing ->
            div [ class "pd-pane pd-wait" ]
                [ div [ class "pd-head" ] [ text "esperando o servidor…" ] ]

        Just (Ok res) ->
            div [ class ("pd-pane " ++ statusClass res.status) ]
                [ div [ class "pd-head" ] [ text (statusLine res.status) ]
                , pre [ class "pd-json" ]
                    [ text
                        (if res.status >= 500 && String.isEmpty res.body then
                            -- Com a API parada, o proxy do Vite responde 502 sem corpo.
                            apiDown

                         else
                            prettyJson res.body
                        )
                    ]
                ]

        Just (Err _) ->
            div [ class "pd-pane pd-down" ]
                [ div [ class "pd-head" ] [ text "sem resposta" ]
                , pre [ class "pd-json" ] [ text apiDown ]
                ]


apiDown : String
apiDown =
    "A API não respondeu. Ela está rodando? (npm run api)"


statusLine : Int -> String
statusLine status =
    case status of
        200 ->
            "200 OK"

        422 ->
            "422 Unprocessable Content"

        500 ->
            "500 Internal Server Error"

        502 ->
            "502 Bad Gateway"

        _ ->
            String.fromInt status


statusClass : Int -> String
statusClass status =
    if status < 300 then
        "pd-ok"

    else if status < 500 then
        "pd-bad"

    else
        "pd-down"


{-| Uma chave por linha, com cada valor numa linha só (o tabuleiro cabe inteiro).
Se o corpo não for um objeto JSON, mostra o texto como veio.
-}
prettyJson : String -> String
prettyJson body =
    case D.decodeString (D.keyValuePairs D.value) body of
        Ok pairs ->
            "{\n"
                ++ String.join ",\n" (List.map (\( k, v ) -> "  " ++ E.encode 0 (E.string k) ++ ": " ++ E.encode 0 v) pairs)
                ++ "\n}"

        Err _ ->
            case D.decodeString (D.list D.value) body of
                -- Uma lista (o GET /api/challenges): um item por linha.
                Ok items ->
                    "[\n" ++ String.join ",\n" (List.map (\v -> "  " ++ E.encode 0 v) items) ++ "\n]"

                Err _ ->
                    if String.isEmpty body then
                        "(sem corpo)"

                    else
                        body


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
                            [ ( "Msg", "" ), ( "update", "" ), ( "Model", "board + score" ), ( "view", "HTML na tela" ) ]
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


viewMember : Int -> Member -> Html msg
viewMember i m =
    div
        [ class ("member tc" ++ String.fromInt (modBy 7 i))
        , style "animation-delay" (String.fromInt (i * 140) ++ "ms")
        ]
        [ div [ class "avatar" ]
            [ span [ class "initial" ] [ text (String.left 1 m.name) ]
            , Html.img [ Html.Attributes.src ("https://github.com/" ++ m.login ++ ".png?size=240"), Html.Attributes.alt m.name, Html.Attributes.attribute "referrerpolicy" "no-referrer", Html.Attributes.attribute "loading" "lazy" ] []
            ]
        , div [ class "mname" ] [ text m.name ]
        , div [ class "mlogin" ] [ text ("@" ++ m.login) ]
        ]
