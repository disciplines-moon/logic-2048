module Game exposing
    ( Board
    , Model
    , Msg(..)
    , Piece
    , PieceKind(..)
    , Point
    , Snapshot
    , Status(..)
    , Theme(..)
    , Tile
    , bestFor
    , emptyBoard
    , emptyCells
    , init
    , keyMsgs
    , newTile
    , piecesBoard
    , placeTiles
    , reactions
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
import Dict exposing (Dict)
import Game.Effects as Effects exposing (Effect(..), Sound(..))
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


{-| Tema da interface (#8). A persistência entre sessões é da #9: ela só precisa
mandar `ThemeChosen` com o tema salvo.
-}
type Theme
    = Dark
    | Light


{-| O estado inteiro do jogo. `waiting` é verdadeiro enquanto se espera a resposta
do servidor ou o sorteio: teclas nesse meio-tempo são ignoradas. `history` guarda o
jogo antes de cada jogada (#7) e `replay` existe só enquanto o replay está aberto.

Os quatro últimos campos são da tela (#8). `pieces` são as peças com identidade
(um `id` que não muda enquanto a peça vive), para a `view` deslizar cada uma de
uma casa para outra; `nextId` é o próximo `id` livre. O caminho de cada peça vem
do Prolog (`moves` da resposta): o Elm só o aplica, não calcula nada.

Os cinco últimos campos são das comemorações (#9). `best` é o recorde de cada
tamanho (3 a 6), lido do navegador pelas flags; `muted` desliga os sons;
`celebrated` diz que esta partida já comemorou a vitória (o `won` do Prolog segue
verdadeiro depois de vencer, e o confete não pode repetir); `showWin` mostra a
tela de vitória; `ranked` é falso nos tabuleiros prontos da apresentação, que não
contam para o recorde.

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
    , theme : Theme
    , pieces : List Piece
    , nextId : Int
    , slowMotion : Bool
    , best : Dict Int Int
    , muted : Bool
    , celebrated : Bool
    , showWin : Bool
    , ranked : Bool
    }


{-| Uma peça na tela (#8). O `id` é a identidade: é a chave do `Html.Keyed`, então
a mesma peça é o mesmo nó do navegador, e mudar `row` e `col` faz o CSS deslizá-la.

`kind` é como a peça entrou na tela e não muda enquanto ela vive: assim a
animação de entrada nunca é cortada nem recomeça. `ghost` diz que ela entrou numa
fusão: desliza até a casa e some. `slot` é a vaga fixa da peça na lista de nós da
tela, para o navegador nunca precisar mover o nó (mover cancela o deslize). `age`
conta as jogadas desde que ela virou fantasma: ela só sai da lista três jogadas
depois, quando com certeza já sumiu, mesmo com teclas muito rápidas.

-}
type alias Piece =
    { id : Int
    , value : Int
    , row : Int
    , col : Int
    , kind : PieceKind
    , ghost : Bool
    , age : Int
    , slot : Int
    }


{-| Como a peça entrou na tela.

  - `Plain`: já estava (ou o tabuleiro foi trocado de uma vez); não anima a entrada.
  - `Born`: o Elm sorteou; aparece depois que as outras deslizam.
  - `Merged`: nasceu de uma fusão; dá um pop quando as duas peças chegam.

-}
type PieceKind
    = Plain
    | Born
    | Merged


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
`ThemeChosen` e `SlowMotionToggled` são da tela (#8); `MuteToggled` e
`WinDismissed` (continuar jogando depois de vencer) são das comemorações (#9).
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
    | ThemeChosen Theme
    | SlowMotionToggled
    | MuteToggled
    | WinDismissed
    | NoOp


{-| Jogo novo 4×4. Começa vazio e já pede o sorteio das 2 peças iniciais. As
preferências salvas (recorde, tema e som) chegam pelas flags (#9).
-}
init : Effects.Prefs -> ( Model, Cmd Msg )
init prefs =
    let
        ( fresh, cmd ) =
            newGame 4
    in
    ( { fresh
        | best = prefs.best
        , muted = prefs.muted
        , theme =
            if prefs.theme == "light" then
                Light

            else
                Dark
      }
    , cmd
    )


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
      , theme = Dark
      , pieces = []
      , nextId = 0
      , slowMotion = False
      , best = Dict.empty
      , muted = False
      , celebrated = False
      , showWin = False
      , ranked = True
      }
    , Random.generate (Spawned board) (startTiles n)
    )


{-| Jogo novo que mantém as escolhas de quem joga: tema, câmera lenta, som e os
recordes. A comemoração recomeça: é outra partida.
-}
restart : Int -> Model -> ( Model, Cmd Msg )
restart n model =
    let
        ( fresh, cmd ) =
            newGame n
    in
    ( { fresh
        | theme = model.theme
        , slowMotion = model.slowMotion
        , nextId = model.nextId
        , best = model.best
        , muted = model.muted
      }
    , cmd
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
                gotMove result model |> react result model

        Spawned target tiles ->
            if not model.waiting || target /= model.board then
                ( model, Cmd.none )

            else
                ( born tiles { model | board = placeTiles tiles model.board, waiting = False }, Cmd.none )

        NewGame ->
            restart model.size model

        SizeChosen n ->
            if n >= 3 && n <= 6 then
                restart n model

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

        ThemeChosen theme ->
            ( { model | theme = theme }
            , Effects.perform
                (SaveTheme
                    (if theme == Light then
                        "light"

                     else
                        "dark"
                    )
                )
            )

        SlowMotionToggled ->
            ( { model | slowMotion = not model.slowMotion }, Cmd.none )

        MuteToggled ->
            ( { model | muted = not model.muted }, Effects.perform (SaveMuted (not model.muted)) )

        WinDismissed ->
            ( { model | showWin = False }, Cmd.none )

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
            , celebrated = False
            , showWin = False
            , ranked = False
          }
            |> rebuild
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
                ( slide res { answered | board = res.board, waiting = True, history = remember model }
                , Random.generate (Spawned res.board) (newTile res.board)
                )

            else
                ( slide res { answered | waiting = False }, Cmd.none )

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
            rebuild
                { model
                    | board = previous.board
                    , score = previous.score
                    , status = previous.status
                    , history = older
                    , error = Nothing
                    , showWin = False
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



-- COMEMORAÇÕES (#9): o que uma jogada causa fora do Elm


{-| Junta ao resultado de uma jogada os efeitos que ela causa (som, confete,
recorde), já como `Cmd` de port.
-}
react : Result Http.Error Api.MoveResponse -> Model -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
react result before ( after, cmd ) =
    case result of
        Ok res ->
            let
                ( reacted, effects ) =
                    reactions res before after
            in
            ( reacted, Cmd.batch (cmd :: List.map Effects.perform effects) )

        Err _ ->
            ( after, cmd )


{-| Os efeitos de uma jogada, como dados. É uma função pura: recebe a resposta do
Prolog, o jogo de antes e o de depois, e devolve o jogo e a lista de efeitos.

  - Vitória: `won` vem do Prolog. Ele continua verdadeiro depois de vencer, então
    a comemoração só acontece se a partida ainda não comemorou (`celebrated`).
  - Derrota: o `lost` do Prolog, na primeira vez em que aparece.
  - Fusão: a jogada fez pontos (só fusões fazem pontos).
  - Recorde: o placar passou o recorde do tamanho, numa partida que conta.
  - Mudo: nenhum som; o confete e o recorde continuam.

-}
reactions : Api.MoveResponse -> Model -> Model -> ( Model, List Effect )
reactions res before after =
    let
        win =
            res.won && not before.celebrated

        defeat =
            res.lost && before.status /= Lost

        record =
            after.ranked && after.score > bestFor after.size after

        sound =
            if win then
                [ Sound Victory ]

            else if defeat then
                [ Sound Defeat ]

            else if res.score > 0 then
                [ Sound Merge ]

            else if res.moved then
                [ Sound Move ]

            else
                []
    in
    ( { after
        | celebrated = after.celebrated || win
        , showWin = after.showWin || win
        , best =
            if record then
                Dict.insert after.size after.score after.best

            else
                after.best
      }
    , (if after.muted then
        []

       else
        sound
      )
        ++ (if win then
                [ Confetti ]

            else
                []
           )
        ++ (if record then
                [ SaveBest after.size after.score ]

            else
                []
           )
    )


{-| O recorde de um tamanho; 0 se ainda não há.
-}
bestFor : Int -> Model -> Int
bestFor size model =
    Dict.get size model.best |> Maybe.withDefault 0



-- PEÇAS NA TELA (#8): funções puras que mantêm `pieces` igual ao `board`


{-| Aplica o caminho que o Prolog mandou (`moves`). Cada peça sai da casa `from`
e vai para `to`; as duas de uma fusão viram `Ghost`, e nasce uma `Merged` com o
valor novo.

Nada é cortado no meio da animação, mesmo jogando rápido: o `kind` de uma peça
nunca muda, e a fantasma só sai da lista três jogadas depois de virar fantasma.

Se a resposta não trouxe o caminho, ou se o resultado não bate com o tabuleiro
novo, as peças são refeitas a partir do tabuleiro (sem deslizar).

-}
slide : Api.MoveResponse -> Model -> Model
slide res model =
    let
        aged =
            model.pieces
                |> List.map (\p -> { p | age = p.age + 1 })
                |> List.filter (\p -> not (p.ghost && p.age >= 3))

        follow piece =
            if piece.ghost then
                piece

            else
                case List.filter (\m -> m.from == ( piece.row, piece.col )) res.moves of
                    m :: _ ->
                        if m.merged then
                            { piece | row = Tuple.first m.to, col = Tuple.second m.to, ghost = True, age = 0 }

                        else
                            { piece | row = Tuple.first m.to, col = Tuple.second m.to }

                    [] ->
                        piece

        moved =
            List.map follow aged

        mergedCells =
            res.moves
                |> List.filter .merged
                |> List.map .to
                |> unique

        newborns =
            List.indexedMap
                (\i ( r, c ) -> { id = model.nextId + i, value = cellValue r c model.board, row = r, col = c, kind = Merged, ghost = False, age = 0, slot = 0 })
                mergedCells

        pieces =
            moved ++ withSlots moved newborns
    in
    if not (List.isEmpty res.moves) && piecesBoard (List.length model.board) pieces == model.board then
        { model | pieces = pieces, nextId = model.nextId + List.length newborns }

    else
        rebuild model


{-| Dá a cada peça nova a menor vaga livre (`slot`). As peças que já estão na tela
não mudam de vaga.
-}
withSlots : List Piece -> List Piece -> List Piece
withSlots existing new =
    let
        used =
            List.map .slot existing

        free =
            List.range 0 (List.length existing + List.length new)
                |> List.filter (\s -> not (List.member s used))
    in
    List.map2 (\p s -> { p | slot = s }) new free


{-| Peças novas sorteadas pelo Elm: aparecem (`Born`) com `id` novo, numa vaga livre.
-}
born : List Tile -> Model -> Model
born tiles model =
    let
        newborns =
            List.indexedMap (\i t -> { id = model.nextId + i, value = t.value, row = t.row, col = t.col, kind = Born, ghost = False, age = 0, slot = 0 }) tiles
    in
    { model
        | pieces = model.pieces ++ withSlots model.pieces newborns
        , nextId = model.nextId + List.length tiles
    }


{-| Refaz as peças a partir do tabuleiro, com `id`s novos e sem animação: para
desfazer, carregar um tabuleiro ou quando não veio o caminho.
-}
rebuild : Model -> Model
rebuild model =
    let
        cells =
            model.board
                |> List.indexedMap (\r row -> List.indexedMap (\c v -> ( r, c, v )) row)
                |> List.concat
                |> List.filter (\( _, _, v ) -> v /= 0)
    in
    { model
        | pieces = List.indexedMap (\i ( r, c, v ) -> { id = model.nextId + i, value = v, row = r, col = c, kind = Plain, ghost = False, age = 0, slot = i }) cells
        , nextId = model.nextId + List.length cells
    }


{-| O tabuleiro que as peças vivas formam (as fantasmas não contam). Serve para
conferir que a tela e o jogo dizem a mesma coisa.
-}
piecesBoard : Int -> List Piece -> Board
piecesBoard n pieces =
    List.range 0 (n - 1)
        |> List.map
            (\r ->
                List.range 0 (n - 1)
                    |> List.map
                        (\c ->
                            pieces
                                |> List.filter (\p -> not p.ghost && p.row == r && p.col == c)
                                |> List.map .value
                                |> List.sum
                        )
            )


cellValue : Int -> Int -> Board -> Int
cellValue r c board =
    board
        |> List.drop r
        |> List.head
        |> Maybe.andThen (List.drop c >> List.head)
        |> Maybe.withDefault 0


unique : List a -> List a
unique =
    List.foldl
        (\x acc ->
            if List.member x acc then
                acc

            else
                acc ++ [ x ]
        )
        []



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
