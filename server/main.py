"""API do Logic2048. Rode com `npm run api` na pasta web, ou `uv run fastapi dev main.py`.

    POST /api/move   { "board": [[...]], "direction": "left" }

O Python é só a ponte (issue #10): valida a entrada, chama o Prolog pelo janus e
devolve JSON. Nenhuma regra de jogo mora aqui.
"""

import logging
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Annotated, Literal

import janus_swi as janus
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import AfterValidator, BaseModel, StrictInt
from starlette.exceptions import HTTPException

ROOT = Path(__file__).parent
# O Prolog é carregado uma vez só, quando este módulo é importado (antes da
# primeira requisição). Um erro no game.pl derruba a subida, não uma jogada.
janus.consult(str(ROOT.parent / "prolog" / "game.pl"))

MIN_N, MAX_N = 3, 6

DIST = ROOT.parent / "web" / "dist"


def montar_interface(app: FastAPI, pasta: Path) -> None:
    """Serve a interface já compilada (`npm run build`) em `/`, se ela existir."""
    ja_montada = any(getattr(r, "name", "") == "interface" for r in app.routes)
    if not ja_montada and (pasta / "index.html").is_file():
        app.mount("/", StaticFiles(directory=pasta, html=True), name="interface")


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Montar só na subida garante que "/" fique DEPOIS de todas as rotas /api,
    # mesmo as que outras issues acrescentarem mais abaixo neste arquivo.
    montar_interface(app, DIST)
    yield


app = FastAPI(title="Logic2048", lifespan=lifespan)


# ---------------------------------------------------------------------------
# Validação na borda: entrada inválida para aqui, com 422, e nunca chega ao
# Prolog. O Prolog assume entrada válida (docs/contrato.md).


def validar_tabuleiro(board: list[list[int]]) -> list[list[int]]:
    """N×N com N de 3 a 6, e cada casa 0 ou potência de 2 a partir de 2."""
    n = len(board)
    if not MIN_N <= n <= MAX_N or any(len(row) != n for row in board):
        raise ValueError(f"o tabuleiro deve ser quadrado, de {MIN_N}x{MIN_N} a {MAX_N}x{MAX_N}")
    for v in (v for row in board for v in row):
        # Uma potência de 2 tem um único bit ligado: v & (v - 1) apaga esse bit e dá 0.
        if v != 0 and (v < 2 or v & (v - 1) != 0):
            raise ValueError(f"valor inválido {v}: use 0 ou uma potência de 2 a partir de 2")
    return board


# Tipos da entrada, declarados uma vez. O pydantic confere o tipo primeiro
# (StrictInt recusa true, 2.0 e "2") e depois roda o validar_tabuleiro.
# A #11 reusa o Board em /api/hint e /api/challenge.
Board = Annotated[list[list[StrictInt]], AfterValidator(validar_tabuleiro)]
Direction = Literal["left", "right", "up", "down"]


class MoveRequest(BaseModel):
    board: Board
    direction: Direction


class MoveResponse(BaseModel):
    board: list[list[int]]
    score: int
    moved: bool
    won: bool
    lost: bool


# ---------------------------------------------------------------------------
# Erros no formato do contrato: { "error": "<mensagem>" }, nunca o
# { "detail": ... } padrão do FastAPI. O Elm mostra a mensagem do 422 a quem
# joga, então ela sai em português e diz qual campo está errado.

# Mensagens do pydantic traduzidas, pelo tipo do erro. Rota nova com outro tipo
# de campo (a #11, por exemplo)? Acrescente o tipo aqui; sem tradução, sai a
# mensagem do pydantic em inglês.
MENSAGENS = {
    "missing": "campo obrigatório",
    "list_type": "deve ser uma lista",
    "int_type": "deve ser um número inteiro",
    "model_attributes_type": "o corpo deve ser um objeto JSON",
}


def campo(loc: tuple) -> str:
    """Onde está o erro: ("body", "board", 2, 0) vira "board[2][0]"."""
    texto = ""
    for parte in loc[1:]:  # loc[0] é sempre "body"
        if isinstance(parte, int):
            texto += f"[{parte}]"
        else:
            texto += f".{parte}" if texto else parte
    return texto


def mensagem(erro: dict) -> str:
    """Um erro do pydantic em português, por exemplo "direction: use 'left', ... ou 'down'"."""
    tipo = erro["type"]
    if tipo == "json_invalid":
        return "JSON inválido"
    if tipo == "missing" and len(erro["loc"]) == 1:
        return "corpo vazio: envie um objeto JSON"
    if tipo == "value_error":  # o ValueError do validar_tabuleiro
        texto = str(erro["ctx"]["error"])
    elif tipo == "literal_error":
        texto = "use " + erro["ctx"]["expected"].replace(" or ", " ou ")
    else:
        texto = MENSAGENS.get(tipo, erro["msg"])
    onde = campo(erro["loc"])
    return f"{onde}: {texto}" if onde else texto


@app.exception_handler(RequestValidationError)
async def entrada_invalida(_: Request, exc: RequestValidationError):
    """Entrada inválida: 422 com todas as mensagens numa frase só."""
    return JSONResponse(status_code=422, content={"error": "; ".join(map(mensagem, exc.errors()))})


# Textos dos outros erros HTTP do FastAPI, traduzidos.
TRADUCOES = {
    "There was an error parsing the body": "não foi possível ler o corpo da requisição",
    "Not Found": "rota não encontrada",
    "Method Not Allowed": "método não permitido",
}


@app.exception_handler(HTTPException)
async def erro_http(_: Request, exc: HTTPException):
    """Os outros erros HTTP, como rota inexistente (404) e método errado (405),
    também saem como { "error" }. O contrato não usa 400: o FastAPI responde 400
    quando nem consegue ler o corpo (por exemplo, um número com milhares de
    dígitos), e isso é entrada inválida, então vira 422."""
    status = 422 if exc.status_code == 400 else exc.status_code
    texto = TRADUCOES.get(str(exc.detail), str(exc.detail))
    return JSONResponse(status_code=status, content={"error": texto}, headers=exc.headers)


@app.exception_handler(Exception)
async def erro_interno(_: Request, exc: Exception):
    """Qualquer outra exceção (por exemplo, um erro no Prolog) é 500 no mesmo
    formato. O detalhe vai para o log, não para quem joga."""
    logging.getLogger("uvicorn.error").exception("erro interno", exc_info=exc)
    return JSONResponse(status_code=500, content={"error": "erro interno no servidor"})


# ---------------------------------------------------------------------------
# Rotas. Quando a função roda, a entrada já foi validada.


@app.post("/api/move")
def move(req: MoveRequest) -> MoveResponse:
    # Ida: o janus converte cada valor Python num termo Prolog. A lista de
    # listas vira lista de listas, e a string "left" vira o átomo left.
    r = janus.query_once("game:move(B, D, N, S)", {"B": req.board, "D": req.direction})
    # Volta: um dict com as variáveis que o Prolog ligou (N e S) e "truth", que
    # diz se ele provou o objetivo. Falhar com entrada válida é bug: vira 500.
    if not r["truth"]:
        raise RuntimeError("game:move/4 falhou para este tabuleiro")
    new, score = r["N"], r["S"]
    # Perguntas de sim ou não: só o "truth" interessa.
    won = janus.query_once("game:game_won(B)", {"B": new})["truth"]
    lost = janus.query_once("game:game_lost(B)", {"B": new})["truth"]
    # moved só compara os dois tabuleiros: é dado, não regra de jogo.
    return MoveResponse(board=new, score=score, moved=new != req.board, won=won, lost=lost)
