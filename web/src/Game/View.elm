module Game.View exposing (tileClasses, view)

{-| Tabuleiro, placar e controles (issue #8).

A `view` é uma função pura do `Game.Model`: o mesmo `Model` gera sempre a mesma
tela. Ela não guarda estado, não fala com o servidor e não sorteia nada; só lê o
`Model` e devolve `Html`. Quando o usuário clica, ela devolve uma `Msg`, e quem
muda o estado é o `update` do `Game`.

-}

import Api exposing (Direction(..))
import Game
import Game.Assist as Assist
import Game.Icons as Icons
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
        , if inPresentation && (statusText model == "" || model.assist.note /= Nothing) then
            -- Na apresentação o rodapé já diz que W A S D jogam; a linha só aparece com vitória,
            -- derrota ou erro, e uma linha só: se a IA avisou algo (#20), vale o aviso dela.
            text ""

          else if inPresentation then
            p [ class "status" ] [ text (statusText model) ]

          else
            p [ class "status" ] [ text ("Use as setas ou W A S D." ++ statusText model) ]
        , if inPresentation && model.assist.panel /= Assist.Closed then
            -- Na apresentação o painel de desafios ocupa o lugar desta linha.
            text ""

          else
            div [ class "controls sizes" ]
                [ button [ class "primary icon-btn", onClick Game.NewGame ] [ Icons.icon Icons.Restart, span [] [ text "Novo jogo" ] ]
                , div [ class "segmented", attribute "role" "group", attribute "aria-label" "Tamanho do tabuleiro" ]
                    (List.map (sizeButton model.size) [ 3, 4, 5, 6 ])
                ]
        , if inPresentation then
            text ""

          else
            historyControls inPresentation model
        , viewAssist inPresentation model
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
        , viewHintArrow model board
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
        ( which, label, hint ) =
            if muted then
                ( Icons.SoundOff, "Sem som", "Ligar os sons" )

            else
                ( Icons.SoundOn, "Som", "Desligar os sons" )
    in
    button
        [ class "theme icon-btn"
        , onClick Game.MuteToggled
        , title hint
        , attribute "aria-label" hint
        , attribute "aria-pressed" (boolText muted)
        ]
        (iconLabel compact which label)


{-| Na demo da apresentação o botão mostra só o ícone, para a barra caber; o nome
completo fica no `title` e no `aria-label`.
-}
iconLabel : Bool -> Icons.Icon -> String -> List (Html msg)
iconLabel compact which label =
    if compact then
        [ Icons.icon which ]

    else
        [ Icons.icon which, span [] [ text label ] ]


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
            button [ class "theme icon-btn", onClick (Game.ThemeChosen Game.Light), title "Usar o tema claro", attribute "aria-label" "Usar o tema claro" ] (iconLabel compact Icons.Sun "Claro")

        Game.Light ->
            button [ class "theme icon-btn", onClick (Game.ThemeChosen Game.Dark), title "Usar o tema escuro", attribute "aria-label" "Usar o tema escuro" ] (iconLabel compact Icons.Moon "Escuro")



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
        compact =
            inPresentation

        noHistory =
            List.isEmpty model.history || model.waiting || Assist.driving model.assist

        bar =
            div [ class "controls history", classList [ ( "toolbar", compact ) ] ]
    in
    case model.replay of
        Nothing ->
            if inPresentation && model.assist.panel /= Assist.Closed then
                -- Na apresentação o painel de desafios usa a mesma barra.
                bar (challengeTools model)

            else
                bar
                    ([ toolButton compact Icons.Undo "Desfazer" [ onClick Game.Undo, disabled noHistory ]
                     , toolButton compact Icons.Replay "Replay" [ onClick Game.ReplayStarted, disabled noHistory ]
                     ]
                        ++ (if inPresentation then
                                -- Na apresentação a dica, a IA e os desafios entram na mesma
                                -- barra, para a demo ter sempre o mesmo tamanho.
                                toolButton compact Icons.Slow "Câmera lenta" [ onClick Game.SlowMotionToggled, classList [ ( "active", model.slowMotion ) ] ]
                                    :: assistTools True model

                            else
                                []
                           )
                    )

        Just replay ->
            bar
                ([ toolButton compact
                    (if replay.playing then
                        Icons.Pause

                     else if replay.at >= List.length replay.frames - 1 then
                        Icons.Restart

                     else
                        Icons.Replay
                    )
                    (if replay.playing then
                        "Pausar"

                     else if replay.at >= List.length replay.frames - 1 then
                        "De novo"

                     else
                        "Continuar"
                    )
                    [ onClick Game.ReplayPaused, class "pause" ]
                 , speedCycle "Velocidade do replay" Game.ReplaySpeed replay.interval [ ( "0,5×", 1000 ), ( "1×", 500 ), ( "2×", 250 ) ]
                 , toolButton compact Icons.Close "Sair do replay" [ onClick Game.ReplayClosed, class "close" ]
                 ]
                    ++ (if inPresentation then
                            [ span [ class "bar-text" ] [ text ("jogada " ++ String.fromInt replay.at ++ " de " ++ String.fromInt (List.length replay.frames - 1)) ] ]

                        else
                            []
                       )
                )


{-| Um botão só para a velocidade: cada clique passa para a próxima. Tem sempre a
mesma largura, então a barra não muda de tamanho.
-}
speedCycle : String -> (Float -> Game.Msg) -> Float -> List ( String, Float ) -> Html Game.Msg
speedCycle hint toMsg current options =
    let
        index =
            options |> List.indexedMap Tuple.pair |> List.filter (\( _, ( _, v ) ) -> v == current) |> List.head |> Maybe.map Tuple.first |> Maybe.withDefault 0

        label =
            options |> List.drop index |> List.head |> Maybe.map Tuple.first |> Maybe.withDefault ""

        next =
            options |> List.drop (modBy (List.length options) (index + 1)) |> List.head |> Maybe.map Tuple.second |> Maybe.withDefault current
    in
    button [ class "speed", onClick (toMsg next), title hint, attribute "aria-label" (hint ++ ": " ++ label) ] [ text label ]


{-| Botão com ícone. Compacto (na apresentação), mostra só o ícone; o nome fica no
`title` e no `aria-label`.
-}
toolButton : Bool -> Icons.Icon -> String -> List (Html.Attribute Game.Msg) -> Html Game.Msg
toolButton compact which label attrs =
    button (class "icon-btn" :: title label :: attribute "aria-label" label :: attrs) (iconLabel compact which label)


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

        -- O erro da jogada vem primeiro; senão, o da dica ou dos desafios (#20).
        anyError =
            case error of
                Nothing ->
                    model.assist.error

                _ ->
                    error
    in
    case ( anyError, (Game.shown model).status ) of
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



-- DICA, IA E DESAFIOS (#20). A tela só lê o `model.assist`; quem decide é o
-- `Game.Assist`, e quem escolhe a jogada é o Prolog.


{-| A seta da dica, por cima do tabuleiro. Só aparece se a dica é deste tabuleiro.
-}
viewHintArrow : Game.Model -> Game.Board -> Html Game.Msg
viewHintArrow model board =
    case Assist.shownHint board model.assist |> Maybe.andThen .direction of
        Just dir ->
            if model.replay == Nothing then
                div [ class ("hint-arrow hint-" ++ Api.directionToString dir), attribute "aria-label" ("Dica: " ++ dirName dir) ]
                    [ text (arrowOf dir) ]

            else
                text ""

        Nothing ->
            text ""


{-| Os botões da dica, da IA (com a velocidade: um botão só, que alterna, sempre
visível) e dos desafios.
-}
assistTools : Bool -> Game.Model -> List (Html Game.Msg)
assistTools compact model =
    let
        a =
            model.assist

        aiOn =
            a.ai /= Assist.Off

        send msg =
            onClick (Game.AssistMsg msg)
    in
    [ -- Liga e desliga as dicas; ligadas, o botão fica aceso (como o da IA).
      toolButton compact
        Icons.Hint
        "Dica"
        [ classList [ ( "hint-button", True ), ( "active", a.hintsOn ) ]
        , attribute "aria-pressed" (boolText a.hintsOn)
        , send Assist.HintToggled
        , disabled (aiOn || model.replay /= Nothing || Assist.inChallenge a)
        ]
    , toolButton compact
        (if aiOn then
            Icons.Pause

         else
            Icons.Robot
        )
        (if aiOn then
            "Pausar IA"

         else
            "IA joga"
        )
        [ classList [ ( "ai-button", True ), ( "active", aiOn ) ], send Assist.AiToggled, disabled (not aiOn && (model.status == Game.Lost || model.replay /= Nothing || Assist.inChallenge a)) ]
    , speedCycle "Velocidade da IA" (Game.AssistMsg << Assist.AiSpeed) a.interval Assist.speeds
    , toolButton compact Icons.Target "Desafios" [ send Assist.ChallengesOpened, disabled (aiOn || model.replay /= Nothing || model.waiting) ]
    ]


{-| Dica, IA e desafios. Na página do jogo é um painel com nome nos botões; na
apresentação os botões já estão na barra, e aqui só aparece o painel de desafios.
-}
viewAssist : Bool -> Game.Model -> Html Game.Msg
viewAssist inPresentation model =
    if inPresentation then
        viewAssistLine model

    else
        viewAssistPanel model


{-| Na apresentação, uma linha curta de texto embaixo da barra (ou nada).
-}
viewAssistLine : Game.Model -> Html Game.Msg
viewAssistLine model =
    let
        a =
            model.assist

        line cls str =
            p [ class ("assist-line " ++ cls) ] [ text str ]
    in
    case ( a.panel, a.active ) of
        ( Assist.Closed, _ ) ->
            case a.note of
                Just note ->
                    line "" note

                Nothing ->
                    text ""

        ( Assist.Loading, _ ) ->
            line "" "Carregando os desafios…"

        ( Assist.Failed message, _ ) ->
            line "assist-error" message

        ( Assist.Listing _, Nothing ) ->
            line "" "Escolha um desafio: só deslizar e fundir, sem peças novas."

        ( Assist.Listing _, Just active ) ->
            case active.solution of
                Nothing ->
                    line "" "O Prolog está procurando a solução…"

                Just (Err error) ->
                    line "assist-error" (Api.errorMessage error)

                Just (Ok sol) ->
                    if not sol.solvable then
                        line "" "Sem solução: o Prolog provou que não dá."

                    else if active.at >= List.length sol.moves then
                        line "" (challengeLabel active.challenge ++ " · resolvido em " ++ String.fromInt (List.length sol.moves))

                    else
                        line "" (challengeLabel active.challenge ++ " · passo " ++ String.fromInt (active.at + 1) ++ " de " ++ String.fromInt (List.length sol.moves))


{-| Na página do jogo: o painel com nome nos botões.
-}
viewAssistPanel : Game.Model -> Html Game.Msg
viewAssistPanel model =
    let
        a =
            model.assist

        send msg =
            onClick (Game.AssistMsg msg)

        note =
            case a.note of
                Just text_ ->
                    p [ class "assist-note" ] [ text text_ ]

                Nothing ->
                    text ""
    in
    div [ class "assist" ]
        (case a.panel of
            Assist.Closed ->
                [ div [ class "controls assist-row" ] (assistTools False model)
                , note
                , viewScores model
                ]

            Assist.Loading ->
                [ p [ class "assist-note" ] [ text "Carregando os desafios…" ], closeButton False ]

            Assist.Failed message ->
                [ p [ class "assist-note assist-error" ] [ text message ], closeButton False ]

            Assist.Listing challenges ->
                case a.active of
                    Nothing ->
                        [ p [ class "assist-title" ] [ text "Desafios: só deslizar e fundir, sem peças novas." ]
                        , div [ class "challenge-list" ]
                            (List.map
                                (\c ->
                                    button [ class "challenge", send (Assist.ChallengeChosen c), title c.title ] [ text c.title ]
                                )
                                challenges
                            )
                        , closeButton False
                        ]

                    Just active ->
                        viewChallenge model active
        )


{-| Na barra da apresentação: a lista de desafios ou os passos do desafio aberto.
-}
challengeTools : Game.Model -> List (Html Game.Msg)
challengeTools model =
    let
        a =
            model.assist

        send msg =
            onClick (Game.AssistMsg msg)

        close =
            toolButton True Icons.Close "Fechar os desafios" [ send Assist.ChallengesClosed, class "close" ]
    in
    case ( a.panel, a.active ) of
        ( Assist.Listing challenges, Nothing ) ->
            List.map (\c -> button [ class "challenge", send (Assist.ChallengeChosen c), title c.title ] [ text (challengeLabel c) ]) challenges
                ++ [ close ]

        ( Assist.Listing _, Just active ) ->
            let
                finished =
                    case active.solution of
                        Just (Ok sol) ->
                            active.at >= List.length sol.moves

                        _ ->
                            True
            in
            [ toolButton True Icons.Step "Próximo passo" [ class "primary", send Assist.StepForward, disabled (active.stepping || model.waiting || finished) ]
            , toolButton True Icons.Restart "Recomeçar o desafio" [ send Assist.ChallengeRestart, disabled (active.at == 0) ]
            , case active.solution of
                Just (Ok sol) ->
                    if sol.solvable then
                        solutionStrip active sol.moves

                    else
                        text ""

                _ ->
                    text ""
            , toolButton True Icons.Close "Sair do desafio" [ send Assist.ChallengesClosed, class "close" ]
            ]

        _ ->
            [ close ]


{-| Rótulo curto de um desafio, para caber na demo: "3×3 · 16 em 4".
-}
challengeLabel : Api.Challenge -> String
challengeLabel c =
    let
        n =
            String.fromInt (List.length c.board)
    in
    n ++ "×" ++ n ++ " · " ++ String.fromInt c.target ++ " em " ++ String.fromInt c.maxMoves


{-| O desafio aberto: o alvo, as jogadas que o Prolog achou (a da vez em destaque)
e os botões para andar um passo.
-}
viewChallenge : Game.Model -> Assist.Active -> List (Html Game.Msg)
viewChallenge model active =
    let
        send msg =
            onClick (Game.AssistMsg msg)

        total =
            case active.solution of
                Just (Ok s) ->
                    List.length s.moves

                _ ->
                    0

        finished =
            active.at >= total

        progress =
            if finished then
                "resolvido em " ++ String.fromInt total ++ " jogadas"

            else
                "passo " ++ String.fromInt (active.at + 1) ++ " de " ++ String.fromInt total
    in
    [ p [ class "assist-title" ]
        [ text (active.challenge.title ++ " · alvo " ++ String.fromInt active.challenge.target) ]
    , case active.solution of
        Nothing ->
            p [ class "assist-note" ] [ text "O Prolog está procurando a solução…" ]

        Just (Err error) ->
            p [ class "assist-note assist-error" ] [ text (Api.errorMessage error) ]

        Just (Ok solution) ->
            if not solution.solvable then
                p [ class "assist-note" ] [ text "Sem solução: o Prolog provou que não dá." ]

            else
                div [ class "solution-row" ]
                    [ solutionStrip active solution.moves
                    , span [ class "assist-note" ] [ text progress ]
                    ]
    , div [ class "controls assist-row" ]
        [ toolButton False
            Icons.Step
            "Próximo passo"
            [ class "primary"
            , send Assist.StepForward
            , disabled (active.stepping || model.waiting || finished)
            ]
        , toolButton False Icons.Restart "Recomeçar" [ send Assist.ChallengeRestart, disabled (active.at == 0) ]
        , toolButton False Icons.Close "Sair do desafio" [ send Assist.ChallengesClosed ]
        ]
    ]


{-| As setas da solução do desafio: as já jogadas apagadas, a da vez em destaque.
-}
solutionStrip : Assist.Active -> List Api.Direction -> Html Game.Msg
solutionStrip active moves =
    div [ class "solution" ]
        (List.indexedMap
            (\i dir ->
                span [ classList [ ( "move", True ), ( "done", i < active.at ), ( "next", i == active.at ) ], title (dirName dir) ]
                    [ text (arrowOf dir) ]
            )
            moves
        )


closeButton : Bool -> Html Game.Msg
closeButton compact =
    toolButton compact Icons.Close "Fechar" [ onClick (Game.AssistMsg Assist.ChallengesClosed) ]


{-| O valor esperado de cada direção, como o Prolog calculou.
-}
viewScores : Game.Model -> Html Game.Msg
viewScores model =
    case Assist.shownHint model.board model.assist of
        Just hint ->
            p [ class "hint-scores" ]
                (text ("Dica (profundidade " ++ String.fromInt hint.depth ++ "): ")
                    :: (if List.isEmpty hint.scores then
                            [ text "nenhuma jogada possível." ]

                        else
                            List.map
                                (\( dir, v ) ->
                                    span [ classList [ ( "score-dir", True ), ( "best", Just dir == hint.direction ) ] ]
                                        [ text (arrowOf dir ++ " " ++ String.fromFloat (toFloat (round (v * 10)) / 10)) ]
                                )
                                hint.scores
                       )
                )

        Nothing ->
            text ""


arrowOf : Direction -> String
arrowOf dir =
    case dir of
        Left ->
            "←"

        Right ->
            "→"

        Up ->
            "↑"

        Down ->
            "↓"


dirName : Direction -> String
dirName dir =
    case dir of
        Left ->
            "esquerda"

        Right ->
            "direita"

        Up ->
            "cima"

        Down ->
            "baixo"


{-| `aria-pressed` de um botão que liga e desliga.
-}
boolText : Bool -> String
boolText on =
    if on then
        "true"

    else
        "false"
