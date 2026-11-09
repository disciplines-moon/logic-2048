module Cenas.Issue13 exposing (cenas)

import Cenas.Types exposing (Block(..), Scene)


cenas : List Scene
cenas =
    [ { issue = 13
      , title = "Gestão: ferramentas e CI"
      , steps =
            [ { notes = "Cada pasta é um paradigma e uma ferramenta diferente. Foi isso que a gente quis mostrar na disciplina."
              , blocks =
                    [ Pre "logic-2048/\n  prolog/   regras do jogo      swipl + plunit\n  server/   API (FastAPI+janus) uv + pytest\n  web/      interface           npm + elm-test\n  docs/     contrato e arquitetura\n  .github/  CI e template de PR"
                    ]
              }
            , { notes = "Três ferramentas do curso: uv gerencia o Python, npm gerencia o Elm e o Vite, swipl roda o Prolog. Nenhuma depende da outra para testar."
              , blocks =
                    [ Bullets
                        [ "uv: instala as dependências do Python e roda o pytest"
                        , "npm: instala o Elm, roda o elm-test, o elm-format e o build"
                        , "swipl: carrega o Prolog e roda os testes do plunit"
                        ]
                    ]
              }
            , { notes = "A main não tem proteção do GitHub porque o repositório é privado no plano Free. Quem protege é a CI: três jobs, um por camada, em todo PR."
              , blocks =
                    [ Clear
                    , Code { file = ".github/workflows/ci.yml", from = 9, to = 22, mark = [ 9, 20, 21 ] }
                    ]
              }
            , { notes = "O job do Elm roda o npm run check, que já junta formato, armadilhas conhecidas, testes e build. Se um teste quebra, o check fica vermelho e o PR não deve ser aprovado."
              , blocks =
                    [ Clear
                    , Code { file = ".github/workflows/ci.yml", from = 42, to = 57, mark = [ 57 ] }
                    ]
              }
            , { notes = "Um comando sobe tudo: compila a interface e o FastAPI serve a API e a interface juntas, num processo só. Esta apresentação roda assim também."
              , blocks =
                    [ Clear
                    , Code { file = "scripts/rodar.sh", from = 8, to = 12, mark = [ 12 ] }
                    ]
              }
            , { notes = "A documentação acompanha o código: contrato, arquitetura e esta apresentação, tudo no repositório."
              , blocks =
                    [ Clear
                    , Lead "A documentação é o próprio repositório."
                    , Bullets [ "docs/contrato.md e docs/arquitetura.md", "template de PR com checklist", "esta apresentação, em #/apresentacao" ]
                    ]
              }
            ]
      }
    ]
