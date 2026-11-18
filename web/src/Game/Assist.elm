module Game.Assist exposing
    ( Action(..)
    , Active
    , Ai(..)
    , Assist
    , Context
    , Msg(..)
    , Panel(..)
    , clearNotes
    , currentHint
    , driving
    , inChallenge
    , init
    , reset
    , shownHint
    , speeds
    , ticks
    , update
    )

{-| Dica, modo IA e desafios na interface (issue #20).

Este módulo não conhece o `Game`: ele recebe um retrato do jogo (`Context`) e
devolve o novo estado, os pedidos HTTP (`Cmd`) e uma `Action`, que o `Game`
executa (jogar uma direção, mostrar um tabuleiro...). Tudo aqui é função pura,
e o estado mora num campo só do `Game.Model` (`assist`).

**Dicas**: um botão liga e desliga. Ligadas, a cada tabuleiro novo o `Assist`
pede a dica de novo (uma requisição por vez); desligadas, a seta some.

**Modo IA**: uma máquina de estados com no máximo uma requisição em voo.

    Off ──ligar──▶ Playing ──(intervalo)──▶ Thinking ──dica──▶ Playing ──…
                     │  joga a direção        pede /api/hint      │
                     └── espera a jogada voltar (o Game.waiting) ◀┘

O relógio (`Time.every`) só existe em `Playing` com o jogo parado (`waiting`
falso): nem a dica nem a jogada estão em voo. Ao vencer, perder, ficar sem
jogada ou dar erro, a IA volta a `Off` sozinha.

-}

import Api exposing (Direction)
import Http
import Time


type alias Board =
    List (List Int)


{-| O que o `Assist` precisa saber do jogo para decidir.
-}
type alias Context =
    { board : Board
    , waiting : Bool
    , won : Bool
    , lost : Bool
    , failed : Bool
    , replaying : Bool
    }


{-| `Thinking`: o pedido de dica está em voo. `Playing`: a jogada foi mandada (ou
a IA espera o intervalo para pedir a próxima dica).
-}
type Ai
    = Off
    | Thinking
    | Playing


{-| A tela de desafios: fechada, carregando, a lista ou o erro ao carregar.
-}
type Panel
    = Closed
    | Loading
    | Listing (List Api.Challenge)
    | Failed String


{-| O desafio aberto: a solução que o Prolog achou e em que passo ela está.
-}
type alias Active =
    { challenge : Api.Challenge
    , solution : Maybe (Result Api.Error Api.Solution)
    , at : Int
    , stepping : Bool
    }


{-| `hint` guarda a dica junto com o tabuleiro para o qual ela vale: se o
tabuleiro muda, a dica some sozinha (`currentHint`). `hintsOn`: as dicas estão
ligadas e acompanham cada tabuleiro novo. `wonBefore` diz se a partida
já tinha vencido quando a IA ligou (o `won` do Prolog segue verdadeiro depois de
vencer). `interval` é o tempo entre jogadas da IA, em ms. `note` diz por que a IA
parou (venceu, não há jogada, erro).
-}
type alias Assist =
    { hint : Maybe ( Board, Api.Hint )
    , hintsOn : Bool
    , asking : Bool
    , ai : Ai
    , wonBefore : Bool
    , interval : Float
    , panel : Panel
    , active : Maybe Active
    , error : Maybe String
    , note : Maybe String
    }


type Msg
    = HintToggled
    | HintRefresh
    | GotHint Board (Result Api.Error Api.Hint)
    | AiToggled
    | AiSpeed Float
    | AiTicked
    | ChallengesOpened
    | GotChallenges (Result Api.Error (List Api.Challenge))
    | ChallengeChosen Api.Challenge
    | GotSolution String (Result Api.Error Api.Solution)
    | StepForward
    | GotStep Board (Result Http.Error Api.MoveResponse)
    | ChallengeRestart
    | ChallengesClosed


{-| O que o `Game` precisa fazer depois. `Play` joga como uma tecla (com sorteio
de peça); `Step` aplica um passo do desafio SEM sortear peça; `Show` troca o
tabuleiro; `Restart` volta a um jogo novo. `Settle`: não há jogada, e o `Game`
pergunta ao Prolog uma última vez, para ele declarar o fim de jogo (`lost`).
-}
type Action
    = None
    | Play Direction
    | Step Api.MoveResponse
    | Show Board
    | Restart
    | Settle


init : Assist
init =
    { hint = Nothing
    , hintsOn = False
    , asking = False
    , ai = Off
    , wonBefore = False
    , interval = 300
    , panel = Closed
    , active = Nothing
    , error = Nothing
    , note = Nothing
    }


{-| Jogo novo ou tabuleiro trocado: desliga a IA e os desafios, mas guarda a
velocidade e se as dicas estão ligadas.
-}
reset : Assist -> Assist
reset assist =
    { init | interval = assist.interval, hintsOn = assist.hintsOn }


{-| Quem joga mexeu no tabuleiro (tecla ou desfazer): o aviso de por que a IA
parou e o erro da dica valiam para o tabuleiro de antes, e saem da tela.
-}
clearNotes : Assist -> Assist
clearNotes assist =
    { assist | note = Nothing, error = Nothing }


{-| Velocidades da IA: rótulo e intervalo entre jogadas (ms).
-}
speeds : List ( String, Float )
speeds =
    [ ( "0,5×", 600 ), ( "1×", 300 ), ( "2×", 150 ), ( "4×", 60 ) ]


{-| A IA ou o desafio estão no comando: as teclas de quem joga são ignoradas.
-}
driving : Assist -> Bool
driving assist =
    assist.ai /= Off || inChallenge assist


inChallenge : Assist -> Bool
inChallenge assist =
    assist.active /= Nothing


{-| A dica vale só para o tabuleiro em que foi pedida.
-}
currentHint : Board -> Assist -> Maybe Api.Hint
currentHint board assist =
    case assist.hint of
        Just ( b, hint ) ->
            if b == board then
                Just hint

            else
                Nothing

        Nothing ->
            Nothing


{-| A dica que aparece na tela: só com as dicas ligadas ou a IA jogando.
-}
shownHint : Board -> Assist -> Maybe Api.Hint
shownHint board assist =
    if assist.hintsOn || assist.ai /= Off then
        currentHint board assist

    else
        Nothing


{-| O relógio da IA: só com a IA jogando e nenhuma requisição em voo.
-}
ticks : Context -> Assist -> Sub Msg
ticks ctx assist =
    if assist.ai == Playing && not ctx.waiting then
        Time.every assist.interval (\_ -> AiTicked)

    else if hintStale ctx assist then
        -- Dicas ligadas e o tabuleiro mudou: pede a dica nova assim que o jogo parar.
        Time.every 50 (\_ -> HintRefresh)

    else
        Sub.none


{-| Dicas ligadas, sem pedido em voo e sem dica para o tabuleiro atual.
-}
hintStale : Context -> Assist -> Bool
hintStale ctx assist =
    assist.hintsOn
        && not assist.asking
        && not ctx.waiting
        && not ctx.replaying
        && assist.ai
        == Off
        && not (inChallenge assist)
        && currentHint ctx.board assist
        == Nothing


update : Msg -> Context -> Assist -> ( Assist, Cmd Msg, Action )
update msg ctx assist =
    case msg of
        HintToggled ->
            if assist.hintsOn then
                ( { assist | hintsOn = False, hint = Nothing, note = Nothing }, Cmd.none, None )

            else if assist.ai /= Off || inChallenge assist || ctx.replaying then
                -- Como o botão (desligado nesses casos): a IA pede as próprias dicas, uma por vez.
                ( assist, Cmd.none, None )

            else
                askHint ctx { assist | hintsOn = True, error = Nothing, note = Nothing }

        HintRefresh ->
            if hintStale ctx assist then
                askHint ctx assist

            else
                ( assist, Cmd.none, None )

        GotHint board result ->
            gotHint board result ctx { assist | asking = False }

        AiToggled ->
            if assist.ai /= Off then
                ( { assist | ai = Off, note = Nothing }, Cmd.none, None )

            else if ctx.lost || ctx.replaying || inChallenge assist then
                ( assist, Cmd.none, None )

            else
                -- Liga em Playing: o primeiro tique pede a primeira dica.
                ( { assist | ai = Playing, wonBefore = ctx.won, error = Nothing, note = Nothing }, Cmd.none, None )

        AiSpeed interval ->
            ( { assist | interval = interval }, Cmd.none, None )

        AiTicked ->
            if assist.ai /= Playing || ctx.waiting then
                ( assist, Cmd.none, None )

            else if ctx.lost || (ctx.won && not assist.wonBefore) || ctx.failed then
                -- Fim de jogo, vitória nesta corrida ou erro da jogada: a IA para sozinha e diz por quê.
                ( { assist | ai = Off, note = Just (stopReason ctx) }, Cmd.none, None )

            else
                ( { assist | ai = Thinking }, Api.postHint ctx.board (GotHint ctx.board), None )

        ChallengesOpened ->
            ( { assist | panel = Loading, ai = Off, error = Nothing }, Api.getChallenges GotChallenges, None )

        GotChallenges (Ok list) ->
            if assist.panel == Loading then
                ( { assist | panel = Listing list }, Cmd.none, None )

            else
                ( assist, Cmd.none, None )

        GotChallenges (Err error) ->
            if assist.panel == Loading then
                ( { assist | panel = Failed (Api.errorMessage error) }, Cmd.none, None )

            else
                ( assist, Cmd.none, None )

        ChallengeChosen challenge ->
            ( { assist | active = Just { challenge = challenge, solution = Nothing, at = 0, stepping = False }, ai = Off, hint = Nothing, error = Nothing }
            , Api.postChallenge challenge (GotSolution challenge.id)
            , Show challenge.board
            )

        GotSolution id result ->
            case assist.active of
                Just active ->
                    if active.challenge.id == id && active.solution == Nothing then
                        ( { assist | active = Just { active | solution = Just result } }, Cmd.none, None )

                    else
                        ( assist, Cmd.none, None )

                Nothing ->
                    ( assist, Cmd.none, None )

        StepForward ->
            case assist.active of
                Just active ->
                    case nextMove active of
                        Just dir ->
                            if active.stepping || ctx.waiting then
                                ( assist, Cmd.none, None )

                            else
                                ( { assist | active = Just { active | stepping = True } }, Api.postMove ctx.board dir (GotStep ctx.board), None )

                        Nothing ->
                            ( assist, Cmd.none, None )

                Nothing ->
                    ( assist, Cmd.none, None )

        GotStep board result ->
            case assist.active of
                Just active ->
                    if not active.stepping || board /= ctx.board then
                        ( assist, Cmd.none, None )

                    else
                        case result of
                            Ok res ->
                                -- O Prolog moveu; o Elm só mostra. Nenhuma peça é sorteada no desafio.
                                ( { assist | active = Just { active | stepping = False, at = active.at + 1 } }, Cmd.none, Step res )

                            Err error ->
                                ( { assist | active = Just { active | stepping = False }, error = Just (Api.errorMessage (fromHttp error)) }, Cmd.none, None )

                Nothing ->
                    ( assist, Cmd.none, None )

        ChallengeRestart ->
            case assist.active of
                Just active ->
                    ( { assist | active = Just { active | at = 0, stepping = False } }, Cmd.none, Show active.challenge.board )

                Nothing ->
                    ( assist, Cmd.none, None )

        ChallengesClosed ->
            ( { assist | panel = Closed, active = Nothing }
            , Cmd.none
            , if inChallenge assist then
                Restart

              else
                None
            )


{-| A resposta da dica. Ela serve para mostrar a seta (botão Dica) e, se a IA
está pensando, para jogar. Resposta de um tabuleiro antigo é descartada; se a IA
esperava por ela, volta a `Playing` e pergunta de novo no próximo tique.
-}
gotHint : Board -> Result Api.Error Api.Hint -> Context -> Assist -> ( Assist, Cmd Msg, Action )
gotHint board result ctx assist =
    if board /= ctx.board then
        ( { assist
            | ai =
                if assist.ai == Thinking then
                    Playing

                else
                    assist.ai
          }
        , Cmd.none
        , None
        )

    else
        case result of
            Ok hint ->
                let
                    stored =
                        { assist | hint = Just ( board, hint ) }
                in
                if assist.ai == Thinking then
                    case hint.direction of
                        Just dir ->
                            ( { stored | ai = Playing }, Cmd.none, Play dir )

                        Nothing ->
                            -- Sem jogada: a IA para, avisa, e o Prolog declara o fim de jogo.
                            ( { stored | ai = Off, note = Just noMove }, Cmd.none, Settle )

                else if hint.direction == Nothing then
                    ( { stored | note = Just noMove }, Cmd.none, None )

                else
                    ( stored, Cmd.none, None )

            Err error ->
                -- Com erro, a IA e as dicas desligam: nada fica pedindo de novo sem parar.
                ( { assist | ai = Off, hintsOn = False, error = Just (Api.errorMessage error) }, Cmd.none, None )


askHint : Context -> Assist -> ( Assist, Cmd Msg, Action )
askHint ctx assist =
    if assist.asking || ctx.waiting || ctx.replaying then
        ( assist, Cmd.none, None )

    else
        ( { assist | asking = True }, Api.postHint ctx.board (GotHint ctx.board), None )


noMove : String
noMove =
    "Nenhuma jogada muda o tabuleiro: daqui não dá para continuar."


stopReason : Context -> String
stopReason ctx =
    if ctx.lost then
        "Fim de jogo: nenhuma jogada possível."

    else if ctx.won then
        "A IA venceu! Ligue de novo para ela continuar."

    else
        "A IA parou: a jogada deu erro."


{-| O passo do desafio usa o `/api/move` da #6, que devolve `Http.Error`. Mesma
leitura do `Api.apiResult`: 502, 503 e 504 são o proxy do Vite sem a API, ou seja,
nenhuma resposta.
-}
fromHttp : Http.Error -> Api.Error
fromHttp error =
    case error of
        Http.BadStatus status ->
            if List.member status [ 502, 503, 504 ] then
                Api.Network

            else
                Api.Server status

        Http.BadBody _ ->
            Api.Invalid

        _ ->
            Api.Network


{-| A próxima direção da solução, se ainda houver.
-}
nextMove : Active -> Maybe Direction
nextMove active =
    case active.solution of
        Just (Ok solution) ->
            List.head (List.drop active.at solution.moves)

        _ ->
            Nothing
