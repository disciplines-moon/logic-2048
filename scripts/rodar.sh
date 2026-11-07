#!/bin/sh
# Sobe tudo com um comando: compila a interface e serve API + interface em
# http://localhost:8000 (apresentação em http://localhost:8000/#/apresentacao).
# Uso: sh scripts/rodar.sh [porta]
set -e
raiz=$(cd "$(dirname "$0")/.." && pwd)
porta=${1:-8000}

(cd "$raiz/web" && { [ -d node_modules ] || npm ci; } && npm run build)
cd "$raiz/server"
uv sync
exec uv run fastapi run main.py --host 127.0.0.1 --port "$porta"
