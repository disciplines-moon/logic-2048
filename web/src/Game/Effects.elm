module Game.Effects exposing (Effect(..), Prefs, Sound(..), defaultPrefs, perform, prefsDecoder)

{-| Efeitos do jogo (#9): sons, confete e o que fica salvo no navegador.

Um `Effect` é só um valor que **descreve** um efeito. O `update` do `Game` decide
quais efeitos uma jogada causa (uma função pura, testada), e `perform` transforma
cada um num `Cmd` de port. Quem toca o som ou solta o confete é o JavaScript.

-}

import Dict exposing (Dict)
import Json.Decode as D
import Ports


type Effect
    = Sound Sound
    | Confetti
    | SaveBest Int Int
    | SaveTheme String
    | SaveMuted Bool


type Sound
    = Move
    | Merge
    | Victory
    | Defeat


{-| O único lugar onde um efeito vira `Cmd`: cada um sai pelo seu port.
-}
perform : Effect -> Cmd msg
perform effect =
    case effect of
        Sound sound ->
            Ports.playSound (soundName sound)

        Confetti ->
            Ports.celebrate ()

        SaveBest size best ->
            Ports.saveBest { size = size, best = best }

        SaveTheme theme ->
            Ports.saveTheme theme

        SaveMuted muted ->
            Ports.saveMuted muted


soundName : Sound -> String
soundName sound =
    case sound of
        Move ->
            "move"

        Merge ->
            "merge"

        Victory ->
            "win"

        Defeat ->
            "lose"



-- PREFERÊNCIAS SALVAS (entram pelas flags)


{-| O que o navegador lembra entre sessões: o recorde de cada tamanho (3 a 6), o
tema ("dark" ou "light") e se o som está desligado.
-}
type alias Prefs =
    { best : Dict Int Int
    , theme : String
    , muted : Bool
    }


defaultPrefs : Prefs
defaultPrefs =
    { best = Dict.empty, theme = "dark", muted = False }


{-| Lê as preferências que o `main.js` tirou do `localStorage`. Cada campo tem um
valor padrão: se faltar ou vier estragado, o jogo começa do jeito de sempre.
-}
prefsDecoder : D.Decoder Prefs
prefsDecoder =
    D.map3 Prefs
        (withDefault Dict.empty (D.field "best" bestDecoder))
        (withDefault "dark" (D.field "theme" D.string))
        (withDefault False (D.field "muted" D.bool))


{-| O JSON guarda as chaves como texto ({"4": 2048}); o Elm usa o N como `Int`.
-}
bestDecoder : D.Decoder (Dict Int Int)
bestDecoder =
    D.dict D.int
        |> D.map
            (Dict.foldl
                (\key value acc ->
                    case String.toInt key of
                        Just n ->
                            Dict.insert n value acc

                        Nothing ->
                            acc
                )
                Dict.empty
            )


withDefault : a -> D.Decoder a -> D.Decoder a
withDefault fallback decoder =
    D.oneOf [ decoder, D.succeed fallback ]
