"""Testes de ponta a ponta das rotas extras (#11): o Prolog de verdade, sem mock."""

import inspect
import re
from pathlib import Path

import janus_swi as janus
from fastapi.testclient import TestClient

from main import app  # primeiro o main: ele inclui o router do extras no fim

import extras  # noqa: E402

client = TestClient(app)
DUAS = [[2, 2, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
TRAVADO = [[2, 4, 2], [4, 2, 4], [2, 4, 2]]  # cheio e sem fusões: nenhuma jogada
DIRECOES = {"left", "right", "up", "down"}


def vazio(n):
    return [[0] * n for _ in range(n)]


# --- /api/hint -------------------------------------------------------------


def test_hint_formato_do_contrato():
    r = client.post("/api/hint", json={"board": DUAS, "depth": 2})
    assert r.status_code == 200
    assert set(r.json()) == {"direction", "depth", "scores"}


def test_hint_exemplo_do_contrato():
    # Empate entre left e right: vale a primeira na ordem left, right, up, down.
    body = client.post("/api/hint", json={"board": DUAS}).json()
    assert body["direction"] == "left"
    assert body["depth"] == 2  # padrão
    # up não muda o tabuleiro (as peças já estão em cima), então fica de fora.
    assert set(body["scores"]) == {"left", "right", "down"}
    assert all(isinstance(v, float) for v in body["scores"].values())


def test_hint_scores_so_tem_jogadas_validas():
    board = [[2, 4, 8, 16], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
    body = client.post("/api/hint", json={"board": board, "depth": 1}).json()
    validas = janus.query_once("game:available_moves(B, Ds)", {"B": board})["Ds"]
    assert set(body["scores"]) == set(validas)
    assert body["direction"] in validas


def test_hint_sem_jogada_devolve_null():
    body = client.post("/api/hint", json={"board": TRAVADO}).json()
    assert body == {"direction": None, "depth": 2, "scores": {}}


def test_hint_e_deterministica():
    pedido = {"board": [[2, 0, 4, 0], [0, 2, 0, 0], [0, 0, 8, 0], [4, 0, 0, 2]], "depth": 2}
    respostas = [client.post("/api/hint", json=pedido).json() for _ in range(3)]
    assert respostas[0] == respostas[1] == respostas[2]


def test_hint_profundidade_fora_de_1_a_3_e_422():
    for depth in (0, 4, -1):
        r = client.post("/api/hint", json={"board": DUAS, "depth": depth})
        assert r.status_code == 422
        assert r.json() == {"error": "depth: use um número de 1 a 3"}


def test_hint_profundidade_acima_do_limite_do_n_e_422():
    for n in (5, 6):
        r = client.post("/api/hint", json={"board": vazio(n), "depth": 3})
        assert r.status_code == 422
        assert r.json() == {"error": f"depth: no tabuleiro {n}x{n} o máximo é 2"}


def test_hint_profundidade_3_vale_ate_4x4_com_poucas_vazias():
    # 4×4 com 6 casas vazias: a profundidade 3 é usada como veio.
    board = [[2, 4, 8, 16], [4, 8, 16, 2], [2, 0, 0, 0], [0, 0, 0, 4]]
    body = client.post("/api/hint", json={"board": board, "depth": 3}).json()
    assert body["depth"] == 3


def test_hint_com_mais_de_6_vazias_reduz_para_2():
    body = client.post("/api/hint", json={"board": DUAS, "depth": 3}).json()
    assert body["depth"] == 2
    body = client.post("/api/hint", json={"board": DUAS, "depth": 1}).json()
    assert body["depth"] == 1  # só reduz: nunca aumenta


def test_hint_conta_as_vazias_depois_da_jogada():
    # Revisão do PR #35: 6 vazias na entrada, mas o left funde e deixa 11.
    # Contar só a entrada mantinha a profundidade 3 (~15 s de CPU).
    board = [[2, 2, 2, 2], [2, 2, 2, 2], [4, 4, 0, 0], [0, 0, 0, 0]]
    body = client.post("/api/hint", json={"board": board, "depth": 3}).json()
    assert body["depth"] == 2


def test_hint_profundidade_precisa_ser_inteiro():
    r = client.post("/api/hint", json={"board": DUAS, "depth": "2"})
    assert r.status_code == 422
    assert r.json() == {"error": "depth: deve ser um número inteiro"}


def test_hint_reusa_a_validacao_do_tabuleiro():
    r = client.post("/api/hint", json={"board": [[2, 3, 0], [0, 0, 0], [0, 0, 0]]})
    assert r.status_code == 422
    assert r.json()["error"].startswith("board: valor inválido 3")


def test_hint_aceita_tamanhos_de_3_a_6():
    for n in (3, 4, 5, 6):
        board = vazio(n)
        board[0][0] = 2
        r = client.post("/api/hint", json={"board": board})
        assert r.status_code == 200
        assert r.json()["direction"] in DIRECOES


# --- /api/challenge --------------------------------------------------------


def test_challenge_exemplo_do_contrato():
    pedido = {"board": [[2, 2, 4, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]], "target": 8, "max_moves": 2}
    assert client.post("/api/challenge", json=pedido).json() == {"solvable": True, "moves": ["left", "left"]}


def test_challenge_sem_solucao_vira_solvable_false():
    # A soma das peças é 8: sem peças novas, 64 é impossível.
    pedido = {"board": [[2, 2, 4, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]], "target": 64, "max_moves": 6}
    assert client.post("/api/challenge", json=pedido).json() == {"solvable": False, "moves": []}


def test_challenge_ja_resolvido_nao_precisa_de_jogada():
    pedido = {"board": [[16, 0, 0], [0, 0, 0], [0, 0, 0]], "target": 16, "max_moves": 1}
    assert client.post("/api/challenge", json=pedido).json() == {"solvable": True, "moves": []}


def test_challenge_max_moves_fora_de_1_a_6_e_422():
    for m in (0, 7):
        pedido = {"board": DUAS, "target": 4, "max_moves": m}
        r = client.post("/api/challenge", json=pedido)
        assert r.status_code == 422
        assert r.json() == {"error": "max_moves: use um número de 1 a 6"}


def test_challenge_target_invalido_e_422():
    for t in (0, 1, 6, -4):
        r = client.post("/api/challenge", json={"board": DUAS, "target": t, "max_moves": 2})
        assert r.status_code == 422
        assert r.json() == {"error": "target: use uma potência de 2 a partir de 2"}


def test_challenge_campos_obrigatorios():
    r = client.post("/api/challenge", json={"board": DUAS})
    assert r.status_code == 422
    assert r.json() == {"error": "target: campo obrigatório; max_moves: campo obrigatório"}


# --- /api/challenges -------------------------------------------------------


def test_challenges_lista_do_contrato():
    lista = client.get("/api/challenges").json()
    assert [c["id"] for c in lista] == ["c1", "c2", "c3"]
    for c in lista:
        assert set(c) == {"id", "title", "board", "target", "max_moves"}


def test_todo_desafio_tem_solucao_confirmada_pelo_prolog():
    for c in client.get("/api/challenges").json():
        soma = sum(v for row in c["board"] for v in row)
        assert c["target"] <= soma, c["id"]  # sem peças novas, a soma não muda
        assert max(v for row in c["board"] for v in row) < c["target"], c["id"]
        r = client.post("/api/challenge", json={k: c[k] for k in ("board", "target", "max_moves")})
        assert r.json()["solvable"] is True, c["id"]
        assert 1 <= len(r.json()["moves"]) <= c["max_moves"], c["id"]


def test_solucoes_dos_desafios_da_issue_19():
    esperado = {
        "c1": ["left", "left", "left"],
        "c2": ["right", "up", "up", "left"],
        "c3": ["left", "up", "left", "up"],
    }
    for c in client.get("/api/challenges").json():
        r = client.post("/api/challenge", json={k: c[k] for k in ("board", "target", "max_moves")})
        assert r.json()["moves"] == esperado[c["id"]]


# --- forma das rotas ---------------------------------------------------------


def test_rotas_que_chamam_o_prolog_sao_sincronas():
    # async def rodaria o janus no laço de eventos e travaria o servidor.
    for rota in (extras.hint, extras.challenge, extras.challenges):
        assert not inspect.iscoroutinefunction(rota)


def test_metodo_errado_tambem_usa_error():
    r = client.get("/api/hint")
    assert r.status_code == 405
    assert r.json() == {"error": "método não permitido"}


# Primeira e última linha de cada bloco Code da cena da #11, como aparecem na tela.
RECORTES = {
    ("server/extras.py", 127, 131): ("    # Fronteira: o átomo none vira null", "    return HintResponse("),
}


def test_recortes_da_cena_issue11_continuam_no_lugar():
    """A cena mostra trechos destes arquivos por número de linha. Se o arquivo
    mudar e o trecho sair do lugar, este teste avisa."""
    raiz = Path(__file__).parent.parent
    cena = (raiz / "web/src/Cenas/Issue11.elm").read_text()
    blocos = set(re.findall(r'Code \{ file = "([^"]+)", from = (\d+), to = (\d+)', cena))
    assert {(f, str(a), str(b)) for f, a, b in RECORTES} == blocos
    for (arquivo, de, ate), (primeira, ultima) in RECORTES.items():
        linhas = (raiz / arquivo).read_text().splitlines()
        assert linhas[de - 1].startswith(primeira), (arquivo, de)
        assert linhas[ate - 1].startswith(ultima), (arquivo, ate)
