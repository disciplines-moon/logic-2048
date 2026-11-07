from fastapi import FastAPI
from fastapi.testclient import TestClient

from main import app, montar_interface

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


def test_serve_a_interface_compilada_sem_esconder_a_api(tmp_path):
    (tmp_path / "index.html").write_text("<h1>Logic2048</h1>")
    app_teste = FastAPI()

    @app_teste.get("/api/ping")
    def ping():
        return {"ok": True}

    montar_interface(app_teste, tmp_path)
    c = TestClient(app_teste)
    assert "Logic2048" in c.get("/").text
    assert c.get("/api/ping").json() == {"ok": True}
