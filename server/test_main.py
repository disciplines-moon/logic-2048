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


# Testes da #3: com o move/4 de verdade, a API devolve resultados reais sem
# nenhuma mudança no Python.
CONTRATO = [[2, 0, 0, 2], [0, 0, 0, 0], [0, 4, 0, 0], [0, 0, 0, 0]]


def mover(board, direction):
    r = client.post("/api/move", json={"board": board, "direction": direction})
    assert r.status_code == 200
    return r.json()


def test_move_exemplo_do_contrato_left():
    assert mover(CONTRATO, "left") == {
        "board": [[4, 0, 0, 0], [0, 0, 0, 0], [4, 0, 0, 0], [0, 0, 0, 0]],
        "score": 4,
        "moved": True,
        "won": False,
        "lost": False,
    }


def test_move_exemplo_do_contrato_nas_quatro_direcoes():
    esperado = {
        "left": ([[4, 0, 0, 0], [0, 0, 0, 0], [4, 0, 0, 0], [0, 0, 0, 0]], 4),
        "right": ([[0, 0, 0, 4], [0, 0, 0, 0], [0, 0, 0, 4], [0, 0, 0, 0]], 4),
        "up": ([[2, 4, 0, 2], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]], 0),
        "down": ([[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [2, 4, 0, 2]], 0),
    }
    for direction, (board, score) in esperado.items():
        r = mover(CONTRATO, direction)
        assert (r["board"], r["score"], r["moved"]) == (board, score, True), direction


def test_move_sem_mudanca_devolve_moved_false_e_score_zero():
    encostado = [[2, 4, 0], [8, 0, 0], [0, 0, 0]]
    r = mover(encostado, "left")
    assert (r["board"], r["score"], r["moved"]) == (encostado, 0, False)


def test_move_funciona_de_3_a_6():
    for n in (3, 4, 5, 6):
        board = [[0] * n for _ in range(n)]
        board[0][0] = board[0][n - 1] = 2
        r = mover(board, "right")
        assert r["board"][0] == [0] * (n - 1) + [4], n
        assert r["score"] == 4 and r["moved"] is True
