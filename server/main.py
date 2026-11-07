"""API do Logic2048. Rode com `npm run api` na pasta web, ou `uv run fastapi dev main.py`.

    POST /api/move   { "board": [[...]], "direction": "left" }
"""

import logging
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Literal

import janus_swi as janus
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, StrictInt, field_validator

ROOT = Path(__file__).parent
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


@app.exception_handler(RequestValidationError)
async def entrada_invalida(_: Request, exc: RequestValidationError):
    """Contrato: entrada inválida é 422 com { "error": "<mensagem>" }."""
    msg = "; ".join(str(e.get("msg", "entrada inválida")) for e in exc.errors())
    return JSONResponse(status_code=422, content={"error": msg})


@app.exception_handler(Exception)
async def erro_interno(_: Request, exc: Exception):
    """Contrato: erro interno é 500 no mesmo formato."""
    logging.getLogger("uvicorn.error").exception("erro interno", exc_info=exc)
    return JSONResponse(status_code=500, content={"error": "erro interno no servidor"})


class MoveRequest(BaseModel):
    board: list[list[StrictInt]]
    direction: Literal["left", "right", "up", "down"]

    @field_validator("board")
    @classmethod
    def square(cls, board):
        n = len(board)
        if not MIN_N <= n <= MAX_N or any(len(row) != n for row in board):
            raise ValueError(f"o tabuleiro deve ser quadrado, de {MIN_N}x{MIN_N} a {MAX_N}x{MAX_N}")
        for v in (v for row in board for v in row):
            if v != 0 and (v < 2 or v & (v - 1) != 0):
                raise ValueError(f"valor inválido {v}: use 0 ou uma potência de 2 a partir de 2")
        return board


class MoveResponse(BaseModel):
    board: list[list[int]]
    score: int
    moved: bool
    won: bool
    lost: bool


@app.post("/api/move")
def move(req: MoveRequest) -> MoveResponse:
    r = janus.query_once(
        "game:move(B, D, N, S)", {"B": req.board, "D": req.direction}
    )
    if not r.get("truth", True) or "N" not in r:
        raise RuntimeError("game:move/4 falhou para este tabuleiro")
    new, score = r["N"], r["S"]
    won = janus.query_once("game:game_won(B)", {"B": new})["truth"]
    lost = janus.query_once("game:game_lost(B)", {"B": new})["truth"]
    return MoveResponse(
        board=new, score=score, moved=new != req.board, won=won, lost=lost
    )
