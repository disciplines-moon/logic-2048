from fastapi.testclient import TestClient

from main import app

client = TestClient(app)
EMPTY = [[0] * 4 for _ in range(4)]


def test_move_devolve_formato_do_contrato():
    r = client.post("/api/move", json={"board": EMPTY, "direction": "left"})
    assert r.status_code == 200
    assert set(r.json()) == {"board", "score", "moved", "won", "lost"}


def test_direcao_invalida():
    r = client.post("/api/move", json={"board": EMPTY, "direction": "diagonal"})
    assert r.status_code == 422


def test_tabuleiro_com_tamanho_errado():
    r = client.post("/api/move", json={"board": [[0]], "direction": "left"})
    assert r.status_code == 422
