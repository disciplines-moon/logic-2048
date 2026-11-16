module Game.View exposing (tileClasses, view)

{-| Tabuleiro, placar e controles (issue #8).

A `view` é uma função pura do `Game.Model`: o mesmo `Model` gera sempre a mesma
tela. Ela não guarda estado, não fala com o servidor e não sorteia nada; só lê o
`Model` e devolve `Html`. Quando o usuário clica, ela devolve uma `Msg`, e quem
muda o estado é o `update` do `Game`.

-}

import Api exposing (Direction(..))
import Game
import Html exposing (Html, button, div, p, span, text)
import Html.Attributes exposing (attribute, class, classList, disabled, title)
import Html.Events exposing (on, onClick)
import Html.Keyed as Keyed
import Json.Decode as D


{-| Tabuleiro, placar e controles. É também o que a demo da apresentação mostra
(`inPresentation = True`).
-}
view : Bool -> Game.Model -> Html Game.Msg
view inPresentation model =
    let
        -- No replay a tela mostra o momento da vez, não o jogo atual.
        screen =
            Game.shown model
    in
    div
        [ class "demo-board"
        , class (themeClass model.theme)
        , classList [ ( "slow", model.slowMotion ) ]
        ]
        [ div [ class "topbar" ]
            [ viewScore screen.score model
            , div [ class "toggles" ] [ muteButton inPresentation model.muted, themeButton inPresentation model.theme ]
            ]
        , viewBoard model screen.board
        , if inPresentation then
            -- Na apresentação W A S D já jogam (o rodapé avisa); no lugar das setas
            -- ficam desfazer, replay e câmera lenta, para a demo caber na tela.
            historyControls inPresentation model

          else
            viewKeys
        , if inPresentation && statusText model == "" then
            -- Na apresentação o rodapé já diz que W A S D jogam; a linha só aparece com vitória, derrota ou erro.
            text ""

          else if inPresentation then
            p [ class "status" ] [ text (statusText model) ]

          else
            p [ class "status" ] [ text ("Use as setas ou W A S D." ++ statusText model) ]
        , div [ class "controls sizes" ]
            [ button [ class "primary", onClick Game.NewGame ] [ text "Novo jogo" ]
            , div [ class "segmented", attribute "role" "group", attribute "aria-label" "Tamanho do tabuleiro" ]
                (List.map (sizeButton model.size) [ 3, 4, 5, 6 ])
            ]
        , if inPresentation then
            text ""

          else
            historyControls inPresentation model
        ]



-- TABULEIRO


{-| O tabuleiro tem duas camadas: embaixo, a grade de casas vazias, que não
muda; em cima, as peças, cada uma num nó com chave (`Html.Keyed`).

Cada peça mora numa vaga fixa (`slot`) e a chave é o `id` dela, que não muda
enquanto ela vive. Na tela seguinte o Elm
compara as chaves: a mesma peça é o mesmo nó do navegador, só com outra linha e
coluna, e a `transition` do CSS desliza o nó da casa antiga para a nova. Sem a
chave, o Elm reaproveitaria os nós pela ordem, e as peças trocariam de número no
lugar em vez de andar.

No replay não há caminho (o histórico guarda só tabuleiros), então as peças
saem direto do tabuleiro da vez.

-}
viewBoard : Game.Model -> Game.Board -> Html Game.Msg
viewBoard model board =
    let
        n =
            List.length board

        pieces =
            if model.replay == Nothing then
                model.pieces

            else
                replayPieces board
    in
    div (class "board" :: class ("n" ++ String.fromInt n) :: swipe)
        [ div [ class "cells" ] (List.repeat (n * n) (div [ class "tile empty" ] []))
        , div [ class "pieces" ] (List.map (viewSlot pieces) (List.range 0 (slotCount n pieces - 1)))
        , if model.replay == Nothing && model.status == Game.Lost then
            gameOver

          else if model.replay == Nothing && model.showWin then
            victory (List.maximum (List.concat board) |> Maybe.withDefault 0)

          else
            text ""
        ]


{-| Vitória (#9). Quem decide que venceu é o Prolog (`won`); a tela só mostra a
maior peça do tabuleiro. O jogo continua: dá para seguir jogando ou começar outro.
-}
victory : Int -> Html Game.Msg
victory biggest =
    div [ class "board-over board-win" ]
        [ p [ class "over-title" ] [ text "Você venceu!" ]
        , p [ class "over-text" ] [ text ("Você chegou a " ++ String.fromInt biggest ++ ".") ]
        , div [ class "over-actions" ]
            [ button [ class "primary", onClick Game.WinDismissed ] [ text "Continuar jogando" ]
            , button [ onClick Game.NewGame ] [ text "Novo jogo" ]
            ]
        ]


{-| Fim de jogo: uma camada sobre o tabuleiro, com o caminho para recomeçar.
-}
gameOver : Html Game.Msg
gameOver =
    div [ class "board-over" ]
        [ p [ class "over-title" ] [ text "Fim de jogo" ]
        , p [ class "over-text" ] [ text "Nenhuma direção muda o tabuleiro." ]
        , button [ class "primary", onClick Game.NewGame ] [ text "Novo jogo" ]
        ]


{-| Uma vaga da lista de nós: um `Keyed` com a peça que mora nela (ou nada). A
lista de vagas tem sempre o mesmo tamanho e a mesma ordem, então o Elm compara as
vagas pela posição e nunca move um nó de lugar: mover cancelaria o deslize.
-}
viewSlot : List Game.Piece -> Int -> Html Game.Msg
viewSlot pieces slot =
    Keyed.node "div" [ class "slot" ] (pieces |> List.filter (\p -> p.slot == slot) |> List.map viewPiece)


{-| Vagas suficientes para as peças, as fantasmas e as que acabaram de nascer.
-}
slotCount : Int -> List Game.Piece -> Int
slotCount n pieces =
    max (3 * n * n) (1 + Maybe.withDefault 0 (List.maximum (List.map .slot pieces)))


{-| Uma peça, com a chave que dá identidade ao nó. A posição vai em classes
(`r2`, `c0`): o CSS transforma linha e coluna em deslocamento.
-}
viewPiece : Game.Piece -> ( String, Html Game.Msg )
viewPiece piece =
    ( String.fromInt piece.id
    , div
        (List.map class
            (tileClasses piece.value
                ++ [ "piece"
                   , "r" ++ String.fromInt piece.row
                   , "c" ++ String.fromInt piece.col
                   , kindClass piece.kind
                   ]
            )
            ++ [ classList [ ( "ghost", piece.ghost ) ] ]
        )
        [ text (String.fromInt piece.value) ]
    )


kindClass : Game.PieceKind -> String
kindClass kind =
    case kind of
        Game.Plain ->
            "plain"

        Game.Born ->
            "born"

        Game.Merged ->
            "merged"


{-| Peças do replay: uma por casa ocupada, com chave própria (não é `id` de peça).
-}
replayPieces : Game.Board -> List Game.Piece
replayPieces board =
    board
        |> List.indexedMap (\r row -> List.indexedMap (\c v -> { id = -1 - (r * 10 + c) - 100 * v, value = v, row = r, col = c, kind = Game.Plain, ghost = False, age = 0, slot = r * 10 + c }) row)
        |> List.concat
        |> List.filter (\p -> p.value /= 0)


{-| Classes de uma peça: a cor vem do valor (`v2`, `v4`, ...), o tamanho da letra
do número de dígitos (`d3`, `d4`, ...) e as peças a partir de 2048 brilham
(`super`). Casa vazia é só `tile empty`.
-}
tileClasses : Int -> List String
tileClasses v =
    if v == 0 then
        [ "tile", "empty" ]

    else
        [ "tile"
        , if v <= 8192 then
            "v" ++ String.fromInt v

          else
            "vbig"
        , "d" ++ String.fromInt (String.length (String.fromInt v))
        ]
            ++ (if v >= 2048 then
                    [ "super" ]

                else
                    []
               )



-- PLACAR E TEMA


viewScore : Int -> Game.Model -> Html Game.Msg
viewScore score model =
    div [ class "scores" ]
        [ p [ class "score" ]
            [ span [ class "score-label" ] [ text "Pontos" ]

            -- O número é um contador CSS, para o placar "contar" até o valor novo.
            , span [ class "score-num", attribute "style" ("--n:" ++ String.fromInt score) ] []
            , replayPosition model
            ]

        -- Recorde deste tamanho (#9), salvo no navegador entre sessões.
        , p [ class "score score-best" ]
            [ span [ class "score-label" ] [ text ("Recorde " ++ String.fromInt model.size ++ "×" ++ String.fromInt model.size) ]
            , span [ class "best-num" ] [ text (String.fromInt (Game.bestFor model.size model)) ]
            ]
        ]


{-| Som ligado ou desligado (#9). A escolha fica salva no navegador.
-}
muteButton : Bool -> Bool -> Html Game.Msg
muteButton compact muted =
    let
        ( icon, label, hint ) =
            if muted then
                ( "🔇", "Sem som", "Ligar os sons" )

            else
                ( "🔊", "Som", "Desligar os sons" )
    in
    button
        [ class "theme"
        , onClick Game.MuteToggled
        , title hint
        , attribute "aria-label" hint
        , attribute "aria-pressed"
            (if muted then
                "true"

             else
                "false"
            )
        ]
        [ text (iconLabel compact icon label) ]


{-| Na demo da apresentação o botão mostra só o ícone, para a barra caber; o nome
completo fica no `title` e no `aria-label`.
-}
iconLabel : Bool -> String -> String -> String
iconLabel compact icon label =
    if compact then
        icon

    else
        icon ++ " " ++ label


themeClass : Game.Theme -> String
themeClass theme =
    case theme of
        Game.Dark ->
            "theme-dark"

        Game.Light ->
            "theme-light"


{-| O tema é só mais um campo do `Model`: o botão manda `ThemeChosen` com o outro tema.
-}
themeButton : Bool -> Game.Theme -> Html Game.Msg
themeButton compact theme =
    case theme of
        Game.Dark ->
            button [ class "theme", onClick (Game.ThemeChosen Game.Light), title "Usar o tema claro", attribute "aria-label" "Usar o tema claro" ] [ text (iconLabel compact "☀" "Claro") ]

        Game.Light ->
            button [ class "theme", onClick (Game.ThemeChosen Game.Dark), title "Usar o tema escuro", attribute "aria-label" "Usar o tema escuro" ] [ text (iconLabel compact "☾" "Escuro") ]



-- CONTROLES


{-| W A S D na cruz do teclado, como teclas de verdade: a mesma forma das peças.
-}
viewKeys : Html Game.Msg
viewKeys =
    div [ class "keys", attribute "role" "group", attribute "aria-label" "Direções" ]
        (List.map
            (\( letter, arrow, dir ) ->
                button [ class ("wasd wasd-" ++ letter), onClick (Game.Pressed dir), title (arrow ++ " ou " ++ letter) ]
                    [ span [ class "wasd-letter" ] [ text letter ], span [ class "wasd-arrow" ] [ text arrow ] ]
            )
            [ ( "W", "↑", Up ), ( "A", "←", Left ), ( "S", "↓", Down ), ( "D", "→", Right ) ]
        )


{-| Durante o replay, qual jogada está na tela.
-}
replayPosition : Game.Model -> Html Game.Msg
replayPosition model =
    case model.replay of
        Just replay ->
            span [ class "replay-pos" ]
                [ text ("replay: jogada " ++ String.fromInt replay.at ++ " de " ++ String.fromInt (List.length replay.frames - 1)) ]

        Nothing ->
            text ""


{-| Desfazer e replay (#7). Durante o replay, os botões viram pausa, velocidade e sair.
Na apresentação entra também a câmera lenta das animações.
-}
historyControls : Bool -> Game.Model -> Html Game.Msg
historyControls inPresentation model =
    let
        slow =
            if inPresentation then
                [ button
                    [ onClick Game.SlowMotionToggled
                    , classList [ ( "size", True ), ( "active", model.slowMotion ) ]
                    , title "Animações 6 vezes mais lentas"
                    ]
                    [ text "🐢 Câmera lenta" ]
                ]

            else
                []
    in
    case model.replay of
        Nothing ->
            div [ class "controls history" ]
                ([ button [ onClick Game.Undo, disabled (List.isEmpty model.history || model.waiting) ] [ text "↶ Desfazer" ]
                 , button [ onClick Game.ReplayStarted, disabled (List.isEmpty model.history || model.waiting) ] [ text "▶ Replay" ]
                 ]
                    ++ slow
                )

        Just replay ->
            div [ class "controls history" ]
                ([ button [ onClick Game.ReplayPaused, class "pause" ]
                    [ text
                        (if replay.playing then
                            "⏸ Pausar"

                         else if replay.at >= List.length replay.frames - 1 then
                            "↺ De novo"

                         else
                            "▶ Continuar"
                        )
                    ]
                 ]
                    ++ List.map (speedButton replay.interval) [ ( "0,5×", 1000 ), ( "1×", 500 ), ( "2×", 250 ) ]
                    ++ [ button [ onClick Game.ReplayClosed ] [ text "Sair" ] ]
                )


speedButton : Float -> ( String, Float ) -> Html Game.Msg
speedButton current ( label, interval ) =
    button
        [ onClick (Game.ReplaySpeed interval)
        , classList [ ( "size", True ), ( "active", interval == current ) ]
        ]
        [ text label ]


{-| Vitória, derrota ou erro. No replay vale o status da jogada na tela, sem o erro
do jogo atual.
-}
statusText : Game.Model -> String
statusText model =
    let
        error =
            if model.replay == Nothing then
                model.error

            else
                Nothing
    in
    case ( error, (Game.shown model).status ) of
        ( Just err, _ ) ->
            "  " ++ err

        ( Nothing, Game.Won ) ->
            "  Você venceu! Pode continuar jogando."

        ( Nothing, Game.Lost ) ->
            "  Fim de jogo."

        ( Nothing, Game.Playing ) ->
            ""


sizeButton : Int -> Int -> Html Game.Msg
sizeButton current n =
    button
        [ onClick (Game.SizeChosen n)
        , classList [ ( "size", True ), ( "active", n == current ) ]
        ]
        [ text (String.fromInt n ++ "×" ++ String.fromInt n) ]


{-| Swipe no celular: guarda onde o dedo encostou e decide a direção quando ele sai.
-}
swipe : List (Html.Attribute Game.Msg)
swipe =
    [ on "touchstart" (D.map Game.TouchStarted touchPoint)
    , on "touchend" (D.map Game.TouchEnded touchPoint)
    ]


touchPoint : D.Decoder Game.Point
touchPoint =
    D.map2 Tuple.pair
        (D.at [ "changedTouches", "0", "clientX" ] D.float)
        (D.at [ "changedTouches", "0", "clientY" ] D.float)
