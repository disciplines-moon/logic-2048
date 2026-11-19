module Game.Icons exposing (Icon(..), icon)

{-| Ícones dos botões do jogo (#20), desenhados em SVG com traço na cor do texto
(`currentColor`): seguem o tema claro e o escuro e ficam nítidos em qualquer tamanho.
-}

import Html exposing (Html)
import Svg exposing (circle, path, rect, svg)
import Svg.Attributes as A


type Icon
    = Undo
    | Replay
    | Slow
    | Hint
    | Robot
    | Pause
    | Target
    | Step
    | Restart
    | Close
    | SoundOn
    | SoundOff
    | Sun
    | Moon


icon : Icon -> Html msg
icon which =
    svg
        [ A.viewBox "0 0 24 24"
        , A.class "icon"
        , A.fill "none"
        , A.stroke "currentColor"
        , A.strokeWidth "2"
        , A.strokeLinecap "round"
        , A.strokeLinejoin "round"
        ]
        (shapes which)


shapes : Icon -> List (Svg.Svg msg)
shapes which =
    case which of
        Undo ->
            [ path [ A.d "M9 14 4 9l5-5" ] [], path [ A.d "M4 9h10.5a5.5 5.5 0 0 1 0 11H11" ] [] ]

        Replay ->
            [ path [ A.d "M7 4.5v15l12-7.5z" ] [] ]

        Slow ->
            -- Um relógio: as animações mais devagar.
            [ circle [ A.cx "12", A.cy "13", A.r "8" ] [], path [ A.d "M12 9v4l2.5 2.5M10 2h4" ] [] ]

        Hint ->
            -- Uma lâmpada.
            [ path [ A.d "M9 18h6M10 21h4" ] [], path [ A.d "M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.2 1 2V16h5v-.1c0-.8.4-1.5 1-2A6 6 0 0 0 12 3z" ] [] ]

        Robot ->
            [ rect [ A.x "5", A.y "8", A.width "14", A.height "11", A.rx "2.5" ] [], path [ A.d "M12 8V4.5M9.5 13h0M14.5 13h0M9.5 16.5h5M2.5 13v2M21.5 13v2" ] [], circle [ A.cx "12", A.cy "3.5", A.r "1" ] [] ]

        Pause ->
            [ path [ A.d "M9 5v14M15 5v14" ] [] ]

        Target ->
            [ circle [ A.cx "12", A.cy "12", A.r "9" ] [], circle [ A.cx "12", A.cy "12", A.r "5" ] [], circle [ A.cx "12", A.cy "12", A.r "1" ] [] ]

        Step ->
            [ path [ A.d "M6 5v14l9-7z" ] [], path [ A.d "M19 5v14" ] [] ]

        Restart ->
            [ path [ A.d "M3 12a9 9 0 1 0 2.6-6.4L3 8" ] [], path [ A.d "M3 3v5h5" ] [] ]

        Close ->
            [ path [ A.d "M6 6l12 12M18 6 6 18" ] [] ]

        SoundOn ->
            [ path [ A.d "M4 9.5h3.5L12 5.5v13l-4.5-4H4z" ] [], path [ A.d "M15.5 9a4 4 0 0 1 0 6M18.5 6.5a7.5 7.5 0 0 1 0 11" ] [] ]

        SoundOff ->
            [ path [ A.d "M4 9.5h3.5L12 5.5v13l-4.5-4H4z" ] [], path [ A.d "M16 9.5l5 5M21 9.5l-5 5" ] [] ]

        Sun ->
            [ circle [ A.cx "12", A.cy "12", A.r "4" ] [], path [ A.d "M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" ] [] ]

        Moon ->
            [ path [ A.d "M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z" ] [] ]
