module Game.History exposing
    ( History
    , Replay
    , current
    , empty
    , push
    , setInterval
    , startReplay
    , tick
    , togglePause
    , undo
    )

{-| Histórico, desfazer e replay (issue #7). Só funções puras sobre listas de estados.

Em Elm nenhum valor muda depois de criado. Por isso guardar um estado antigo é só
guardar o próprio valor: ninguém vai alterá-lo depois, então não precisa de cópia
defensiva. Desfazer é pegar o estado anterior da lista; o replay é mostrar a lista
na ordem.

O módulo não conhece o `Game.Model`: guarda estados de qualquer tipo (`a`). Assim o
`Game` usa o histórico sem import circular.

-}

-- HISTÓRICO


{-| Estados anteriores, do mais recente para o mais antigo.
-}
type alias History a =
    List a


empty : History a
empty =
    []


{-| Guarda um estado no topo. O histórico antigo continua igual.
-}
push : a -> History a -> History a
push state history =
    state :: history


{-| O estado anterior e o histórico sem ele. Histórico vazio: nada a desfazer.
-}
undo : History a -> Maybe ( a, History a )
undo history =
    case history of
        previous :: older ->
            Just ( previous, older )

        [] ->
            Nothing



-- REPLAY


{-| Os estados da partida, do primeiro ao atual, e qual está na tela (`at`).
`interval` é o tempo entre jogadas, em milissegundos.
-}
type alias Replay a =
    { frames : List a
    , at : Int
    , playing : Bool
    , interval : Float
    }


{-| Começa do primeiro estado. Os estados já estão guardados: o replay só os mostra
de novo, sem sortear peça nem perguntar ao Prolog. Por isso a partida sai igual.
-}
startReplay : Float -> History a -> a -> Replay a
startReplay interval history now =
    { frames = List.reverse (now :: history)
    , at = 0
    , playing = True
    , interval = interval
    }


{-| Avança um estado. No último, para.
-}
tick : Replay a -> Replay a
tick replay =
    let
        last =
            List.length replay.frames - 1
    in
    if not replay.playing then
        replay

    else if replay.at + 1 >= last then
        { replay | at = last, playing = False }

    else
        { replay | at = replay.at + 1 }


{-| Pausa ou retoma. Se o replay já terminou, recomeça do início.
-}
togglePause : Replay a -> Replay a
togglePause replay =
    if replay.playing then
        { replay | playing = False }

    else if replay.at >= List.length replay.frames - 1 then
        { replay | at = 0, playing = True }

    else
        { replay | playing = True }


setInterval : Float -> Replay a -> Replay a
setInterval interval replay =
    { replay | interval = interval }


{-| O estado que o replay mostra agora.
-}
current : Replay a -> Maybe a
current replay =
    List.head (List.drop replay.at replay.frames)
