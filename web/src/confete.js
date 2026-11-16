// Comemoração da vitória (#9), desenhada num <canvas> por cima da página.
// O Elm só manda o port `celebrate`; o desenho é efeito, e fica aqui.
//
// É um show em três atos, todos no mesmo canvas:
//   1. canhões: papéis disparados dos dois cantos de baixo, em leque;
//   2. fogos: três explosões de faíscas douradas no alto, uma depois da outra;
//   3. chuva: papéis e pequenas peças "2048" caindo do alto, girando.

// As cores da rampa das peças.
const CORES = ["#2468a3", "#136a5f", "#5cbf62", "#a6cc3a", "#f2c230", "#f39a2d", "#bd2b45", "#7340c2", "#ffd447"];
const OURO = ["#ffd447", "#ffe58a", "#f2c230", "#fff4c2"];
const DURACAO = 4800; // ms, do primeiro disparo até o canvas sumir
const GRAVIDADE = 0.22;

const sorteio = (min, max) => min + Math.random() * (max - min);
const qualquer = (lista) => lista[Math.floor(Math.random() * lista.length)];

// Um papel retangular que gira e balança como folha caindo.
function papel(x, y, vx, vy) {
  return {
    tipo: "papel", x, y, vx, vy,
    giro: sorteio(0, Math.PI), vgiro: sorteio(-0.3, 0.3),
    balanco: sorteio(0, Math.PI * 2),
    largura: sorteio(6, 13), cor: qualquer(CORES), vida: Infinity,
  };
}

// Uma faísca dos fogos: um ponto brilhante que perde força e some.
function faisca(x, y, angulo, velocidade) {
  return {
    tipo: "faisca", x, y,
    vx: Math.cos(angulo) * velocidade, vy: Math.sin(angulo) * velocidade,
    raio: sorteio(1.6, 3.2), cor: qualquer(OURO), vida: sorteio(900, 1400), idade: 0,
  };
}

// Uma pequena peça dourada com "2048": a cara do próprio jogo.
function peca(x, y) {
  return {
    tipo: "peca", x, y, vx: sorteio(-1.2, 1.2), vy: sorteio(1, 3),
    // Balança de um lado para o outro em vez de girar: o "2048" segue legível.
    fase: sorteio(0, Math.PI * 2), vfase: sorteio(0.04, 0.08),
    lado: sorteio(26, 38), vida: Infinity,
  };
}

export function soltarConfete() {
  // Quem pediu menos movimento no sistema não recebe o show.
  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  const canvas = document.createElement("canvas");
  canvas.className = "confete";
  canvas.setAttribute("aria-hidden", "true");
  document.body.appendChild(canvas);
  const ctx = canvas.getContext("2d");
  const escala = window.devicePixelRatio || 1;
  const W = innerWidth;
  const H = innerHeight;
  canvas.width = W * escala;
  canvas.height = H * escala;
  ctx.scale(escala, escala);

  const coisas = [];

  // Ato 1: os canhões, na hora.
  for (let i = 0; i < 220; i++) {
    const esquerda = i % 2 === 0;
    const angulo = ((esquerda ? -62 : -118) + sorteio(-22, 22)) * (Math.PI / 180);
    const velocidade = sorteio(11, 21);
    coisas.push(papel(esquerda ? 0 : W, H, Math.cos(angulo) * velocidade, Math.sin(angulo) * velocidade));
  }

  // Ato 2: três fogos no alto, um a cada 450 ms (os disparos ficam na agenda).
  const fogos = [0.3, 0.7, 0.5].map((fx, i) => ({ quando: 350 + i * 450, x: W * fx, y: H * sorteio(0.18, 0.32), feito: false }));

  // Ato 3: a chuva começa logo depois e dura 2,2 s.
  const chuva = { inicio: 600, fim: 2800, pecas: 0 };

  const inicio = performance.now();
  let anterior = inicio;

  function quadro(agora) {
    const t = agora - inicio;
    const dt = Math.min(agora - anterior, 40);
    anterior = agora;

    for (const f of fogos) {
      if (!f.feito && t >= f.quando) {
        f.feito = true;
        for (let k = 0; k < 90; k++) coisas.push(faisca(f.x, f.y, (k / 90) * Math.PI * 2, sorteio(2.5, 7.5)));
      }
    }
    if (t >= chuva.inicio && t <= chuva.fim) {
      for (let k = 0; k < 5; k++) coisas.push(papel(sorteio(0, W), -12, sorteio(-1, 1), sorteio(1, 3)));
      if (chuva.pecas < 18 && Math.random() < 0.12) {
        chuva.pecas++;
        coisas.push(peca(sorteio(W * 0.1, W * 0.9), -40));
      }
    }

    ctx.clearRect(0, 0, W, H);
    // Nos últimos 700 ms tudo esmaece junto.
    ctx.globalAlpha = t > DURACAO - 700 ? Math.max(0, (DURACAO - t) / 700) : 1;

    for (let i = coisas.length - 1; i >= 0; i--) {
      const c = coisas[i];
      if (c.tipo === "faisca") {
        c.idade += dt;
        c.vx *= 0.96;
        c.vy = c.vy * 0.96 + GRAVIDADE * 0.35;
        c.x += c.vx;
        c.y += c.vy;
        const resta = 1 - c.idade / c.vida;
        if (resta <= 0) { coisas.splice(i, 1); continue; }
        ctx.save();
        ctx.globalAlpha *= resta;
        ctx.fillStyle = c.cor;
        ctx.shadowColor = c.cor;
        ctx.shadowBlur = 8;
        ctx.beginPath();
        ctx.arc(c.x, c.y, c.raio, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
      } else if (c.tipo === "papel") {
        c.vy += GRAVIDADE;
        c.vx *= 0.99;
        c.vy = Math.min(c.vy, 6); // velocidade de queda máxima, como no ar
        c.balanco += 0.08;
        c.x += c.vx + Math.sin(c.balanco) * 0.6;
        c.y += c.vy;
        c.giro += c.vgiro;
        if (c.y > H + 30) { coisas.splice(i, 1); continue; }
        ctx.save();
        ctx.translate(c.x, c.y);
        ctx.rotate(c.giro);
        ctx.scale(1, Math.abs(Math.cos(c.balanco))); // o papel "vira" enquanto cai
        ctx.fillStyle = c.cor;
        ctx.fillRect(-c.largura / 2, -c.largura / 4, c.largura, c.largura / 2);
        ctx.restore();
      } else {
        c.vy = Math.min(c.vy + GRAVIDADE * 0.4, 4);
        c.x += c.vx;
        c.y += c.vy;
        c.fase += c.vfase;
        if (c.y > H + 60) { coisas.splice(i, 1); continue; }
        ctx.save();
        ctx.translate(c.x, c.y);
        ctx.rotate(Math.sin(c.fase) * 0.45);
        ctx.shadowColor = "rgba(255, 212, 71, 0.8)";
        ctx.shadowBlur = 14;
        ctx.fillStyle = "#ffd447";
        ctx.beginPath();
        ctx.roundRect(-c.lado / 2, -c.lado / 2, c.lado, c.lado, c.lado * 0.14);
        ctx.fill();
        ctx.shadowBlur = 0;
        ctx.fillStyle = "#2b2118";
        ctx.font = `800 ${c.lado * 0.3}px system-ui, sans-serif`;
        ctx.textAlign = "center";
        ctx.textBaseline = "middle";
        ctx.fillText("2048", 0, 1);
        ctx.restore();
      }
    }

    if (t < DURACAO) requestAnimationFrame(quadro);
    else canvas.remove();
  }
  requestAnimationFrame(quadro);
}
