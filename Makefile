# Atalhos para as tarefas mais comuns. Uso: `make <alvo>`.
# Cada linha de receita roda num shell separado; por isso `cd pasta && comando`.

.PHONY: install dev api web rodar test test-prolog test-backend test-web validar

install:            ## instala as dependências da API e da interface
	cd server && uv sync
	cd web && npm install

dev:                ## API (8000) e interface (5173) juntas; Ctrl+C encerra as duas
	$(MAKE) -j2 api web

api:
	cd server && uv run fastapi dev main.py --port 8000

web:
	cd web && npm run dev

rodar:              ## um comando só: compila a interface e serve tudo em http://localhost:8000
	sh scripts/rodar.sh

test: test-prolog test-backend test-web

test-prolog:        ## plunit: regras, dica e desafios
	for f in prolog/test_*.pl; do swipl --on-error=status -g "load_files('$$f'),run_tests" -t halt || exit 1; done

test-backend:       ## pytest da API (chama o Prolog de verdade, sem mock)
	cd server && uv run pytest

test-web:           ## elm-format, armadilhas, elm-test e build
	cd web && npm run check

validar:            ## confere a forma do RELATORIO.md (validador do professor)
	uv run scripts/validar_entrega.py RELATORIO.md
