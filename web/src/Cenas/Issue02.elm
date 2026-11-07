module Cenas.Issue02 exposing (cenas)

import Cenas.Types exposing (Scene, pending)


cenas : List Scene
cenas =
    [ pending 2 "Prolog: deslizar e fundir uma linha" "Montar a cena interativa: slide_left/3 e a recursão sobre listas." ]
