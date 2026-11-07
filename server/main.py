"""API do Logic2048. Rode com `pnpm api` na pasta web, ou `uv run fastapi dev main.py`.

    POST /api/move   { "board": [[...]], "direction": "left" }
"""

from pathlib import Path
from typing import Literal

import janus_swi as janus
from fastapi import FastAPI
from pydantic import BaseModel, field_validator

ROOT = Path(__file__).parent
janus.consult(str(ROOT.parent / "prolog" / "game.pl"))

SIZE = 4

app = FastAPI(title="Logic2048")


class MoveRequest(BaseModel):
    board: list[list[int]]
    direction: Literal["left", "right", "up", "down"]

    @field_validator("board")
    @classmethod
    def square(cls, board):
        if len(board) != SIZE or any(len(row) != SIZE for row in board):
            raise ValueError(f"o tabuleiro deve ser {SIZE}x{SIZE}")
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
    new, score = r["N"], r["S"]
    won = janus.query_once("game:game_won(B)", {"B": new})["truth"]
    lost = janus.query_once("game:game_lost(B)", {"B": new})["truth"]
    return MoveResponse(
        board=new, score=score, moved=new != req.board, won=won, lost=lost
    )
