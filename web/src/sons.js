// Sons do jogo (#9), sintetizados com Web Audio: nenhum arquivo de áudio.
// O Elm só manda o nome do som pelo port `playSound`; tocar é efeito, e fica aqui.

let contexto = null;

// O navegador só deixa tocar som depois de um gesto de quem joga (tecla ou
// clique). Como todo som vem de uma jogada, o contexto é criado na primeira vez.
function audio() {
  if (!contexto) {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return null;
    contexto = new AudioContext();
  }
  if (contexto.state === "suspended") contexto.resume();
  return contexto;
}

// Uma nota curta: sobe rápido e some, para não estalar.
function nota(c, frequencia, inicio, duracao, forma, volume) {
  const quando = c.currentTime + inicio;
  const osc = c.createOscillator();
  const ganho = c.createGain();
  osc.type = forma;
  osc.frequency.value = frequencia;
  ganho.gain.setValueAtTime(0.0001, quando);
  ganho.gain.exponentialRampToValueAtTime(volume, quando + 0.01);
  ganho.gain.exponentialRampToValueAtTime(0.0001, quando + duracao);
  osc.connect(ganho).connect(c.destination);
  osc.start(quando);
  osc.stop(quando + duracao + 0.02);
}

const SONS = {
  // Deslizar: um toque grave e curto.
  move: (c) => nota(c, 220, 0, 0.07, "triangle", 0.06),
  // Fundir: duas notas subindo.
  merge: (c) => {
    nota(c, 523, 0, 0.09, "sine", 0.14);
    nota(c, 784, 0.05, 0.12, "sine", 0.12);
  },
  // Vitória: uma fanfarra. Arpejo de dó maior subindo, o acorde inteiro soando
  // junto no fim e um brilho agudo por cima.
  win: (c) => {
    [523, 659, 784, 1047].forEach((f, i) => nota(c, f, i * 0.11, 0.26, "triangle", 0.15));
    [523, 659, 784, 1047].forEach((f) => nota(c, f, 0.48, 0.9, "triangle", 0.09));
    [2093, 2637, 3136].forEach((f, i) => nota(c, f, 0.5 + i * 0.07, 0.35, "sine", 0.03));
  },
  // Derrota: três notas descendo.
  lose: (c) => [392, 330, 262].forEach((f, i) => nota(c, f, i * 0.17, 0.3, "sine", 0.14)),
};

export function tocar(nome) {
  const c = audio();
  if (c && SONS[nome]) SONS[nome](c);
}
