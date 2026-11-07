module Cenas exposing (all, pendingCount, sections)

{-| Ordem da apresentação. Cada issue edita só o próprio `Cenas/IssueNN.elm`,
então ninguém mexe no arquivo de outra pessoa.
-}

import Cenas.Intro
import Cenas.Issue02
import Cenas.Issue03
import Cenas.Issue04
import Cenas.Issue05
import Cenas.Issue06
import Cenas.Issue07
import Cenas.Issue08
import Cenas.Issue09
import Cenas.Issue10
import Cenas.Issue11
import Cenas.Issue13
import Cenas.Issue14
import Cenas.Issue19
import Cenas.Issue20
import Cenas.Types exposing (Scene, isPending)


sections : List ( String, List Scene )
sections =
    [ ( "Início", Cenas.Intro.cenas )
    , ( "Prolog"
      , List.concat
            [ Cenas.Issue02.cenas
            , Cenas.Issue03.cenas
            , Cenas.Issue04.cenas
            , Cenas.Issue05.cenas
            , Cenas.Issue19.cenas
            ]
      )
    , ( "Python", Cenas.Issue10.cenas ++ Cenas.Issue11.cenas )
    , ( "Elm"
      , List.concat
            [ Cenas.Issue06.cenas
            , Cenas.Issue07.cenas
            , Cenas.Issue08.cenas
            , Cenas.Issue09.cenas
            , Cenas.Issue20.cenas
            ]
      )
    , ( "Projeto", Cenas.Issue13.cenas )
    , ( "Fim", Cenas.Issue14.cenas )
    ]


all : List Scene
all =
    List.concatMap Tuple.second sections


pendingCount : Int
pendingCount =
    List.length (List.filter isPending all)
