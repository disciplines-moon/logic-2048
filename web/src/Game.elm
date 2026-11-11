module Game exposing
    ( Board
    , Model
    , Msg(..)
    , Point
    , Snapshot
    , Status(..)
    , Tile
    , emptyBoard
    , emptyCells
    , init
    , keyMsgs
    , newTile
    , placeTiles
    , replayTicks
    , shown
    , startTiles
    , swipeDirection
    , tileValue
    , update
    )

{-| Estado do jogo na arquitetura TEA (issue #6): `Model`, `Msg` e `update`.

  - O estado só muda dentro de `update`, que é uma função pura: recebe a `Msg` e
    o `Model` antigo e devolve um `Model` novo (o antigo continua intacto).
  - A regra de jogo mora no Prolog: aqui só se manda o tabuleiro e se guarda a resposta.
  - O sorteio da peça nova é feito aqui, com `Random.Generator`. Um gerador é só a
    **descrição** de um sorteio; quem sorteia de fato é o runtime do Elm, que
    devolve o resultado numa `Msg` (`Spawned`). Assim o `update` continua puro.

Não conhece a apresentação nem o roteamento, e não desenha nada (a tela é `Game.View`).

-}

import Api exposing (Direction(..))
import Browser.Events
import Game.History as History exposing (History, Replay)
import Http
import Json.Decode as D
import Random exposing (Generator)
import Time



-- MODEL


{-| N linhas de N inteiros, 0 é casa vazia (veja `docs/contrato.md`).
-}
type alias Board =
    List (List Int)


{-| Uma peça sorteada: linha, coluna (a partir de 0) e valor (2 ou 4).
-}
type alias Tile =
    { row : Int
    , col : Int
    , value : Int
    }


{-| Posição do dedo na tela, em pixels (x, y).
-}
type alias Point =
    ( Float, Float )


{-| `Won` não trava o jogo: dá para continuar jogando depois de vencer.
-}
type Status
    = Playing
    | Won
    | Lost


{-| O estado inteiro do jogo. `waiting` é verdadeiro enquanto se espera a resposta
do servidor ou o sorteio: teclas nesse meio-tempo são ignoradas. `history` guarda o
jogo antes de cada jogada (#7) e `replay` existe só enquanto o replay está aberto.
-}
type alias Model =
    { board : Board
    , size : Int
    , score : Int
    , status : Status
    , waiting : Bool
    , error : Maybe String
    , touchStart : Maybe Point
    , history : History Snapshot
    , replay : Maybe (Replay Snapshot)
    }


{-| O que a tela mostra de um momento da partida. O tabuleiro já inclui a peça
sorteada, então desfazer e replay não sorteiam de novo.
-}
type alias Snapshot =
    { board : Board
    , score : Int
    , status : Status
    }


{-| Tudo o que pode acontecer. `GotMove` é a resposta do Prolog e `Spawned` são as
peças sorteadas pelo runtime (2 no início, 1 após cada jogada); as duas trazem o
tabuleiro em que foram pedidas, para descartar respostas atrasadas. `Undo` e as
`Replay*` são do histórico (#7); `ReplayTicked` vem do relógio (`replayTicks`).
`LoadBoard` troca o jogo por um tabuleiro pronto (os cenários da apresentação, #4).
-}
type Msg
    = Pressed Direction
    | GotMove Board (Result Http.Error Api.MoveResponse)
    | Spawned Board (List Tile)
    | NewGame
    | SizeChosen Int
    | TouchStarted Point
    | TouchEnded Point
    | Undo
    | ReplayStarted
    | ReplayTicked
    | ReplayPaused
    | ReplaySpeed Float
    | ReplayClosed
    | LoadBoard Board
    | NoOp


{-| Jogo novo 4×4. Começa vazio e já pede o sorteio das 2 peças iniciais.
-}
init : ( Model, Cmd Msg )
init =
    newGame 4


newGame : Int -> ( Model, Cmd Msg )
newGame n =
    let
        board =
            emptyBoard n
    in
    ( { board = board
      , size = n
      , score = 0
      , status = Playing
      , waiting = True
      , error = Nothing
      , touchStart = Nothing
      , history = History.empty
      , replay = Nothing
      }
    , Random.generate (Spawned board) (startTiles n)
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Pressed dir ->
            if model.waiting || model.status == Lost || model.replay /= Nothing then
                ( model, Cmd.none )

            else
                ( { model | waiting = True }, Api.postMove model.board dir (GotMove model.board) )

        GotMove sent result ->
            if not model.waiting || sent /= model.board then
                -- Resposta de um tabuleiro que já não está na tela (por exemplo, veio Novo jogo)
                -- ou que ninguém espera mais (um tabuleiro foi carregado com `LoadBoard`).
                ( model, Cmd.none )

            else
                gotMove result model

        Spawned target tiles ->
            if not model.waiting || target /= model.board then
                ( model, Cmd.none )

            else
                ( { model | board = placeTiles tiles model.board, waiting = False }, Cmd.none )

        NewGame ->
            newGame model.size

        SizeChosen n ->
            if n >= 3 && n <= 6 then
                newGame n

            else
                ( model, Cmd.none )

        TouchStarted point ->
            ( { model | touchStart = Just point }, Cmd.none )

        TouchEnded point ->
            case Maybe.andThen (\start -> swipeDirection start point) model.touchStart of
                Just dir ->
                    update (Pressed dir) { model | touchStart = Nothing }

                Nothing ->
                    ( { model | touchStart = Nothing }, Cmd.none )

        Undo ->
            if model.waiting || model.replay /= Nothing then
                ( model, Cmd.none )

            else
                ( undo model, Cmd.none )

        ReplayStarted ->
            if model.waiting || List.isEmpty model.history then
                ( model, Cmd.none )

            else
                ( { model | replay = Just (History.startReplay 500 model.history (snapshot model)) }, Cmd.none )

        ReplayTicked ->
            ( { model | replay = Maybe.map History.tick model.replay }, Cmd.none )

        ReplayPaused ->
            ( { model | replay = Maybe.map History.togglePause model.replay }, Cmd.none )

        ReplaySpeed interval ->
            ( { model | replay = Maybe.map (History.setInterval interval) model.replay }, Cmd.none )

        ReplayClosed ->
            ( { model | replay = Nothing }, Cmd.none )

        LoadBoard board ->
            loadBoard board model

        NoOp ->
            ( model, Cmd.none )


{-| Começa a jogar a partir de um tabuleiro pronto, sem sortear nada: score 0,
status `Playing`, teclado liberado, histórico vazio e replay fechado (é uma
partida nova: desfazer não volta para o jogo anterior). Respostas e sorteios
ainda pendentes são descartados, porque o jogo deixa de esperar
(`waiting = False`), mesmo que o tabuleiro carregado seja igual ao anterior.
Tamanho fora de 3 a 6 é ignorado, como em `SizeChosen`.
-}
loadBoard : Board -> Model -> ( Model, Cmd Msg )
loadBoard board model =
    let
        n =
            List.length board
    in
    if n >= 3 && n <= 6 && List.all (\row -> List.length row == n) board then
        ( { model
            | board = board
            , size = n
            , score = 0
            , status = Playing
            , waiting = False
            , error = Nothing
            , touchStart = Nothing
            , history = History.empty
            , replay = Nothing
          }
        , Cmd.none
        )

    else
        ( model, Cmd.none )


{-| O Prolog respondeu. Se o tabuleiro mudou, guarda a resposta e pede ao runtime
que sorteie a peça nova; se não mudou, nada é sorteado.
-}
gotMove : Result Http.Error Api.MoveResponse -> Model -> ( Model, Cmd Msg )
gotMove result model =
    case result of
        Ok res ->
            let
                answered =
                    { model
                        | score = model.score + res.score
                        , status = statusFrom res
                        , error = Nothing
                    }
            in
            if res.moved then
                ( { answered | board = res.board, waiting = True, history = remember model }
                , Random.generate (Spawned res.board) (newTile res.board)
                )

            else
                ( { answered | waiting = False }, Cmd.none )

        Err _ ->
            ( { model | waiting = False, error = Just "Erro ao falar com o servidor." }, Cmd.none )


statusFrom : Api.MoveResponse -> Status
statusFrom res =
    if res.lost then
        Lost

    else if res.won then
        Won

    else
        Playing



-- HISTÓRICO E REPLAY (#7)


{-| Guarda o jogo de antes da jogada no histórico. O `Model` antigo não muda, então
guardá-lo não exige cópia.
-}
remember : Model -> History Snapshot
remember model =
    History.push (snapshot model) model.history


{-| O momento atual da partida, para guardar no histórico.
-}
snapshot : Model -> Snapshot
snapshot model =
    { board = model.board, score = model.score, status = model.status }


{-| Volta ao estado anterior da lista: tabuleiro, pontos e status, com a peça que
tinha sido sorteada. Sem histórico, nada muda.
-}
undo : Model -> Model
undo model =
    case History.undo model.history of
        Just ( previous, older ) ->
            { model
                | board = previous.board
                , score = previous.score
                , status = previous.status
                , history = older
                , error = Nothing
            }

        Nothing ->
            model


{-| O que a tela mostra: no replay, o momento da vez; fora dele, o jogo.
-}
shown : Model -> Snapshot
shown model =
    case Maybe.andThen History.current model.replay of
        Just moment ->
            moment

        Nothing ->
            snapshot model


{-| Relógio do replay: uma `Msg` a cada `interval` ms, só enquanto toca.
-}
replayTicks : Model -> Sub Msg
replayTicks model =
    case model.replay of
        Just replay ->
            if replay.playing then
                Time.every replay.interval (\_ -> ReplayTicked)

            else
                Sub.none

        Nothing ->
            Sub.none



-- SORTEIO (funções puras: geradores e tabuleiros)


emptyBoard : Int -> Board
emptyBoard n =
    List.repeat n (List.repeat n 0)


{-| Casas vazias como (linha, coluna).
-}
emptyCells : Board -> List ( Int, Int )
emptyCells board =
    board
        |> List.indexedMap
            (\r row ->
                List.indexedMap
                    (\c v ->
                        if v == 0 then
                            Just ( r, c )

                        else
                            Nothing
                    )
                    row
            )
        |> List.concat
        |> List.filterMap identity


{-| Valor da peça nova: 2 com 90% de chance, 4 com 10%.
-}
tileValue : Generator Int
tileValue =
    Random.weighted ( 90, 2 ) [ ( 10, 4 ) ]


{-| Uma peça numa casa vazia qualquer. Tabuleiro cheio: nenhuma peça.
-}
newTile : Board -> Generator (List Tile)
newTile board =
    case emptyCells board of
        [] ->
            Random.constant []

        first :: rest ->
            Random.map2 (\( r, c ) v -> [ { row = r, col = c, value = v } ])
                (Random.uniform first rest)
                tileValue


{-| As 2 peças do início, em casas distintas: a segunda é sorteada no tabuleiro
que já tem a primeira.
-}
startTiles : Int -> Generator (List Tile)
startTiles n =
    newTile (emptyBoard n)
        |> Random.andThen
            (\first ->
                newTile (placeTiles first (emptyBoard n))
                    |> Random.map (\second -> first ++ second)
            )


{-| Devolve um tabuleiro novo com as peças colocadas. O antigo não muda.
-}
placeTiles : List Tile -> Board -> Board
placeTiles tiles board =
    List.foldl placeTile board tiles


placeTile : Tile -> Board -> Board
placeTile tile board =
    List.indexedMap
        (\r row ->
            List.indexedMap
                (\c v ->
                    if r == tile.row && c == tile.col then
                        tile.value

                    else
                        v
                )
                row
        )
        board



-- ENTRADA: teclado e swipe


{-| Teclas que jogam, mais Ctrl+Z (ou Cmd+Z) para desfazer. `arrows` diz se as setas
também valem (na apresentação elas navegam).
-}
keyMsgs : Bool -> Sub Msg
keyMsgs arrows =
    Sub.batch
        ((if arrows then
            [ Browser.Events.onKeyDown (D.map toMsg Api.keyDecoder) ]

          else
            []
         )
            ++ [ Browser.Events.onKeyDown (D.map toMsg Api.wasdDecoder)
               , Browser.Events.onKeyDown (D.map (\_ -> Undo) Api.undoDecoder)
               ]
        )


toMsg : Maybe Direction -> Msg
toMsg maybeDir =
    case maybeDir of
        Just dir ->
            Pressed dir

        Nothing ->
            NoOp


{-| Direção do arrasto do dedo, pelo eixo que andou mais. Menos de 30 px é toque, não swipe.
-}
swipeDirection : Point -> Point -> Maybe Direction
swipeDirection ( x0, y0 ) ( x1, y1 ) =
    let
        dx =
            x1 - x0

        dy =
            y1 - y0
    in
    if max (abs dx) (abs dy) < 30 then
        Nothing

    else if abs dx > abs dy then
        Just
            (if dx > 0 then
                Right

             else
                Left
            )

    else
        Just
            (if dy > 0 then
                Down

             else
                Up
            )
