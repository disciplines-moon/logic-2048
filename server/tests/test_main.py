import asyncio
import json
import re
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.testclient import TestClient

import main
from main import app, montar_interface

client = TestClient(app)
EMPTY = [[0] * 4 for _ in range(4)]


def test_move_devolve_formato_do_contrato():
    r = client.post("/api/move", json={"board": EMPTY, "direction": "left"})
    assert r.status_code == 200
    assert set(r.json()) == {"board", "score", "moved", "won", "lost", "moves"}


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
    assert sem_caminho(mover(CONTRATO, "left")) == {
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


# Testes da #10: validação na borda, formato dos erros e o caminho até o Prolog.
TRES = [[2, 2, 0], [0, 4, 4], [0, 0, 8]]
DIRECOES = "direction: use 'left', 'right', 'up' ou 'down'"
QUADRADO = "board: o tabuleiro deve ser quadrado, de 3x3 a 6x6"


def erro(corpo, status=422):
    """Manda um pedido que deve falhar e devolve a mensagem de { "error" }."""
    r = client.post("/api/move", json=corpo)
    assert r.status_code == status, r.text
    assert set(r.json()) == {"error"}
    return r.json()["error"]


def erro_cru(texto):
    """Como `erro`, mas manda o corpo como texto, sem converter para JSON."""
    r = client.post("/api/move", content=texto, headers={"content-type": "application/json"})
    assert r.status_code == 422, r.text
    assert set(r.json()) == {"error"}
    return r.json()["error"]


def test_exemplo_da_issue_3x3_left():
    assert sem_caminho(mover(TRES, "left")) == {
        "board": [[4, 0, 0], [8, 0, 0], [8, 0, 0]],
        "score": 12,
        "moved": True,
        "won": False,
        "lost": False,
    }


def tres_com(v):
    """O tabuleiro TRES com `v` na segunda casa da primeira linha."""
    return [[2, v, 0], [0, 4, 4], [0, 0, 8]]


def test_mensagens_em_portugues_com_o_campo():
    assert erro({"board": TRES, "direction": "diagonal"}) == DIRECOES
    assert erro({"board": tres_com(3), "direction": "left"}) == (
        "board: valor inválido 3: use 0 ou uma potência de 2 a partir de 2"
    )
    assert erro({"board": tres_com("2"), "direction": "left"}) == (
        "board[0][1]: deve ser um número inteiro"
    )
    assert erro({"board": [[2, 2, 0], [0, 4], [0, 0, 8]], "direction": "left"}) == QUADRADO
    assert erro({"board": "oi", "direction": "left"}) == "board: deve ser uma lista"
    assert erro({"board": TRES}) == "direction: campo obrigatório"


def test_varios_erros_numa_mensagem_so():
    assert erro({"board": [[3]], "direction": "x"}) == f"{QUADRADO}; {DIRECOES}"


def test_rejeita_formas_invalidas():
    tortas = [[0, 0, 0], [0, 0], [0, 0, 0]]
    retangular = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
    sete = [[0] * 7 for _ in range(7)]
    for board in ([], [[]], [[0, 0], [0, 0]], sete, tortas, retangular):
        assert erro({"board": board, "direction": "left"}) == QUADRADO, board


def test_direcao_precisa_ser_exata():
    for d in ("LEFT", "Left", " left", "", 1, None):
        assert erro({"board": TRES, "direction": d}) == DIRECOES, d


def test_corpo_que_nao_e_objeto():
    assert erro([1, 2]) == "o corpo deve ser um objeto JSON"
    assert erro_cru("null") == "o corpo deve ser um objeto JSON"
    assert erro_cru("") == "corpo vazio: envie um objeto JSON"


def test_json_quebrado():
    assert erro_cru('{"board": [[2,2,0]') == "JSON inválido"


def test_corpo_ilegivel_e_422_e_nunca_400():
    # O Python não lê inteiros com mais de 4300 dígitos, e o FastAPI responderia 400.
    gigante = '{"board": [[1' + "0" * 5000 + ',0,0],[0,0,0],[0,0,0]], "direction": "left"}'
    assert erro_cru(gigante) == "não foi possível ler o corpo da requisição"


def test_rota_e_metodo_errados_tambem_usam_error():
    r = client.get("/api/move")
    assert (r.status_code, r.json()) == (405, {"error": "método não permitido"})
    r = client.post("/api/nada", json={})
    assert (r.status_code, r.json()) == (404, {"error": "rota não encontrada"})


def jogada_com_prolog_quebrado(monkeypatch, falso_query_once):
    """Troca a chamada ao Prolog e faz uma jogada válida. Com
    raise_server_exceptions=False, o TestClient devolve a resposta 500 em vez
    de relançar a exceção no teste."""
    monkeypatch.setattr(main.janus, "query_once", falso_query_once)
    c = TestClient(app, raise_server_exceptions=False)
    return c.post("/api/move", json={"board": TRES, "direction": "left"})


def test_excecao_no_prolog_e_500_no_formato_do_contrato(monkeypatch):
    def quebra(*_args, **_kwargs):
        raise RuntimeError("Prolog fora do ar")

    r = jogada_com_prolog_quebrado(monkeypatch, quebra)
    assert (r.status_code, r.json()) == (500, {"error": "erro interno no servidor"})


def test_prolog_que_falha_e_500(monkeypatch):
    r = jogada_com_prolog_quebrado(monkeypatch, lambda *_args, **_kwargs: {"truth": False})
    assert (r.status_code, r.json()) == (500, {"error": "erro interno no servidor"})


def test_servidor_continua_de_pe_depois_dos_erros():
    erro({"board": TRES, "direction": "diagonal"})
    erro_cru("{")
    assert mover(TRES, "left")["moved"] is True


def test_won_e_lost_vem_do_prolog():
    # 3x3 vence com 256 (contrato): 128 + 128.
    assert mover([[128, 128, 0], [4, 8, 0], [0, 0, 0]], "left")["won"] is True
    # 4x4 só vence com 2048: o mesmo 256 não basta.
    assert mover([[128, 128, 0, 0], [0] * 4, [0] * 4, [0] * 4], "left")["won"] is False
    # Cheio e sem fusão: nada se move e não há saída.
    perdido = [[2, 4, 2], [4, 2, 4], [2, 4, 2]]
    assert sem_caminho(mover(perdido, "left")) == {
        "board": perdido,
        "score": 0,
        "moved": False,
        "won": False,
        "lost": True,
    }


def test_conversoes_do_janus_da_cena_issue10():
    # O que a cena da #10 mostra sobre o janus (web/src/Cenas/Issue10.elm).
    q = main.janus.query_once
    assert q("game:move(B, D, N, S)", {"B": TRES, "D": "left"}) == {
        "truth": True,
        "N": [[4, 0, 0], [8, 0, 0], [8, 0, 0]],
        "S": 12,
    }
    assert q("atom(D)", {"D": "left"}) == {"truth": True}
    assert q("is_list(B)", {"B": TRES}) == {"truth": True}
    assert q("X = left-12.5") == {"truth": True, "X": ("left", 12.5)}
    assert q("game:game_lost(B)", {"B": TRES}) == {"truth": False}



def test_400_lancado_por_uma_rota_vira_422_sem_perder_o_detalhe():
    # Nenhuma rota deve usar 400 (contrato), mas, se usar, a mensagem chega.
    r = asyncio.run(main.erro_http(None, HTTPException(400, "desafio inválido")))
    assert (r.status_code, json.loads(r.body)) == (422, {"error": "desafio inválido"})


# Primeira e última linha de cada bloco Code da cena da #10, como aparecem na tela.
# A cena compacta mostra o janus e a validação como animação (Converte), sem
# trechos de código; se um Code voltar à cena, ele entra aqui.
RECORTES_DA_CENA_ISSUE10: dict[tuple[str, int, int], tuple[str, str]] = {}


def test_recortes_da_cena_issue10_continuam_no_lugar():
    """A cena mostra trechos destes arquivos por número de linha, e esses números
    não se atualizam sozinhos. Se este teste falhar, o código mudou de lugar:
    corrija o from, to e mark em web/src/Cenas/Issue10.elm e as linhas acima."""
    raiz = Path(__file__).parents[2]  # server/tests/ -> raiz do repositório
    cena = (raiz / "web/src/Cenas/Issue10.elm").read_text()
    blocos = re.findall(r'Code \{ file = "([^"]+)", from = (\d+), to = (\d+)', cena)
    assert {(f, int(de), int(ate)) for f, de, ate in blocos} == set(RECORTES_DA_CENA_ISSUE10)
    for (arquivo, de, ate), (primeira, ultima) in RECORTES_DA_CENA_ISSUE10.items():
        linhas = (raiz / arquivo).read_text().splitlines()
        assert linhas[de - 1].startswith(primeira), (arquivo, de)
        assert linhas[ate - 1].startswith(ultima), (arquivo, ate)


# ---------------------------------------------------------------------------
# moves (#8): o caminho de cada peça, vindo do move_trace/5 do Prolog.


def sem_caminho(resposta):
    """A resposta sem o campo moves, para os testes que só olham o resto."""
    return {k: v for k, v in resposta.items() if k != "moves"}


def test_moves_conta_o_caminho_de_cada_peca():
    assert mover(TRES, "left")["moves"] == [
        {"from": [0, 0], "to": [0, 0], "merged": True},
        {"from": [0, 1], "to": [0, 0], "merged": True},
        {"from": [1, 1], "to": [1, 0], "merged": True},
        {"from": [1, 2], "to": [1, 0], "merged": True},
        {"from": [2, 2], "to": [2, 0], "merged": False},
    ]


def test_moves_sem_mudanca_ninguem_anda():
    encostado = [[2, 0, 0], [4, 0, 0], [0, 0, 0]]
    assert mover(encostado, "left")["moves"] == [
        {"from": [0, 0], "to": [0, 0], "merged": False},
        {"from": [1, 0], "to": [1, 0], "merged": False},
    ]


def test_moves_refaz_o_tabuleiro_nas_quatro_direcoes():
    """Somar as peças em cada destino dá o tabuleiro novo, e cada peça sai uma vez."""
    board = [[2, 2, 4, 0], [0, 4, 4, 8], [2, 0, 2, 2], [8, 8, 0, 16]]
    for direction in ("left", "right", "up", "down"):
        r = mover(board, direction)
        refeito = [[0] * 4 for _ in range(4)]
        for m in r["moves"]:
            (r0, c0), (r1, c1) = m["from"], m["to"]
            refeito[r1][c1] += board[r0][c0]
        assert refeito == r["board"], direction
        pecas = sum(v != 0 for row in board for v in row)
        assert len({tuple(m["from"]) for m in r["moves"]}) == pecas, direction
