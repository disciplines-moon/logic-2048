"""Rotas extras da API (issue #11): dica, desafios e lista de desafios.

    POST /api/hint        { "board": [[...]], "depth": 2 }
    POST /api/challenge   { "board": [[...]], "target": 16, "max_moves": 3 }
    GET  /api/challenges

Mesma ponte do /api/move: valida na borda, pergunta ao Prolog pelo janus e
traduz a resposta para o JSON do contrato. Nenhuma decisão de jogo mora aqui.
O main.py inclui este router no fim do arquivo, depois de definir o Board.
"""

import json
from pathlib import Path
from typing import Annotated

import janus_swi as janus
from fastapi import APIRouter, HTTPException
from pydantic import AfterValidator, BaseModel, StrictInt

from main import Board

router = APIRouter()

DATA = Path(__file__).parent / "data" / "challenges.json"


# ---------------------------------------------------------------------------
# Validação dos campos novos. O ValueError vira 422 com a frase daqui (o
# handler do main.py põe o nome do campo na frente).


def entre(menor: int, maior: int):
    def conferir(v: int) -> int:
        if not menor <= v <= maior:
            raise ValueError(f"use um número de {menor} a {maior}")
        return v

    return conferir


def potencia_de_2(v: int) -> int:
    if v < 2 or v & (v - 1) != 0:
        raise ValueError("use uma potência de 2 a partir de 2")
    return v


Depth = Annotated[StrictInt, AfterValidator(entre(1, 3))]
MaxMoves = Annotated[StrictInt, AfterValidator(entre(1, 6))]
Target = Annotated[StrictInt, AfterValidator(potencia_de_2)]


class HintRequest(BaseModel):
    board: Board
    depth: Depth = 2


class HintResponse(BaseModel):
    direction: str | None
    depth: int
    scores: dict[str, float]


class ChallengeRequest(BaseModel):
    board: Board
    target: Target
    max_moves: MaxMoves


class ChallengeResponse(BaseModel):
    solvable: bool
    moves: list[str]


class Challenge(BaseModel):
    id: str
    title: str
    board: Board
    target: Target
    max_moves: MaxMoves


# A lista é fixa: lida (e validada) uma vez, quando o servidor sobe.
CHALLENGES = [Challenge(**c) for c in json.loads(DATA.read_text(encoding="utf-8"))]


# ---------------------------------------------------------------------------
# Limite da dica. Cada nível do expectimax multiplica o trabalho: 4 jogadas
# vezes (casas vazias × 2 peças) sorteios. Com E casas vazias, a profundidade
# D custa perto de (4 · 2E)^D nós. Por isso o máximo depende de N, e com
# muitas casas vazias a profundidade cai para 2.


def profundidade_maxima(n: int) -> int:
    return 3 if n <= 4 else 2


def profundidade_usada(board: list[list[int]], depth: int) -> int:
    vazias = sum(v == 0 for row in board for v in row)
    return min(depth, 2) if vazias > 6 else depth


# ---------------------------------------------------------------------------
# Rotas. São `def` (não `async def`): o FastAPI as roda no pool de threads, e a
# chamada ao Prolog, que é síncrona, não trava o servidor.


@router.post("/api/hint")
def hint(req: HintRequest) -> HintResponse:
    limite = profundidade_maxima(len(req.board))
    if req.depth > limite:
        raise HTTPException(422, f"depth: no tabuleiro {len(req.board)}x{len(req.board)} o máximo é {limite}")
    depth = profundidade_usada(req.board, req.depth)
    r = janus.query_once("game:hint(B, D, Best, S)", {"B": req.board, "D": depth})
    if not r["truth"]:
        raise RuntimeError("game:hint/4 falhou para este tabuleiro")
    # Fronteira: o átomo none vira null, e a lista de pares left-12.5 (que o
    # janus entrega como tuplas) vira um objeto JSON.
    best = None if r["Best"] == "none" else r["Best"]
    scores = {d: float(v) for d, v in r["S"]}
    return HintResponse(direction=best, depth=depth, scores=scores)


@router.post("/api/challenge")
def challenge(req: ChallengeRequest) -> ChallengeResponse:
    r = janus.query_once(
        "game:challenge(B, T, M, Moves)", {"B": req.board, "T": req.target, "M": req.max_moves}
    )
    # Fronteira: no Prolog, "sem solução" é falhar. No JSON, é um booleano.
    if not r["truth"]:
        return ChallengeResponse(solvable=False, moves=[])
    return ChallengeResponse(solvable=True, moves=r["Moves"])


@router.get("/api/challenges")
def challenges() -> list[Challenge]:
    return CHALLENGES
