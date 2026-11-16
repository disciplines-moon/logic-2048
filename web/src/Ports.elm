port module Ports exposing (celebrate, playSound, saveBest, saveMuted, saveTheme, toggleFullscreen)

{-| Os únicos pontos de contato do Elm com o navegador. Cada `port` é uma saída
tipada: o Elm só manda a mensagem, e quem executa o efeito é o JavaScript
(`main.js`, `sons.js`, `confete.js` e `memoria.js`).
-}


{-| Tela cheia da apresentação.
-}
port toggleFullscreen : () -> Cmd msg


{-| Toca um som: "move", "merge", "win" ou "lose" (#9).
-}
port playSound : String -> Cmd msg


{-| Solta o confete da vitória (#9).
-}
port celebrate : () -> Cmd msg


{-| Guarda o recorde de um tamanho de tabuleiro (#9).
-}
port saveBest : { size : Int, best : Int } -> Cmd msg


{-| Guarda o tema: "dark" ou "light" (#9).
-}
port saveTheme : String -> Cmd msg


{-| Guarda se o som está desligado (#9).
-}
port saveMuted : Bool -> Cmd msg
