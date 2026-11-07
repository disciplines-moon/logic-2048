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
    assert "error" in r.json() and "detail" not in r.json()


def test_tabuleiro_com_tamanho_errado():
    r = client.post("/api/move", json={"board": [[0]], "direction": "left"})
    assert r.status_code == 422
    assert "error" in r.json()


def test_aceita_tamanhos_de_3_a_6():
    for n in (3, 4, 5, 6):
        board = [[0] * n for _ in range(n)]
        assert client.post("/api/move", json={"board": board, "direction": "left"}).status_code == 200


def test_rejeita_valores_invalidos():
    for bad in (-2, 1, 3, 6):
        board = [[0] * 4 for _ in range(4)]
        board[0][0] = bad
        r = client.post("/api/move", json={"board": board, "direction": "left"})
        assert r.status_code == 422, bad
        assert "error" in r.json()


def test_rejeita_tipos_que_nao_sao_inteiros():
    for bad in (False, True, 2.0, "2", None):
        board = [[0] * 4 for _ in range(4)]
        board[0][0] = bad
        r = client.post("/api/move", json={"board": board, "direction": "left"})
        assert r.status_code == 422, bad
        assert "error" in r.json()
