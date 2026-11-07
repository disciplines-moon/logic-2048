port module Ports exposing (toggleFullscreen)

{-| Único ponto de contato do Elm com o navegador para a apresentação.
Efeitos colaterais ficam em `main.js`; o Elm só manda a mensagem.
-}


port toggleFullscreen : () -> Cmd msg
