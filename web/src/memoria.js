// O que o jogo lembra entre sessões (#9): recorde por tamanho, tema e som.
// Fica no localStorage do navegador. Ler entra no Elm pelas flags; gravar chega
// pelos ports `saveBest`, `saveTheme` e `saveMuted`.

const CHAVES = {
  recordes: "logic2048.recordes", // {"3": 512, "4": 2048, ...}
  tema: "logic2048.tema", // "dark" ou "light"
  mudo: "logic2048.mudo", // "1" ou "0"
};

// O localStorage pode estar bloqueado (aba anônima, cookies desligados): nesse
// caso o jogo funciona igual, só não lembra nada.
function ler(chave) {
  try {
    return localStorage.getItem(chave);
  } catch {
    return null;
  }
}

function gravar(chave, valor) {
  try {
    localStorage.setItem(chave, valor);
  } catch {
    // sem armazenamento: nada a fazer
  }
}

function recordes() {
  try {
    return JSON.parse(ler(CHAVES.recordes) || "{}");
  } catch {
    return {};
  }
}

// O que vai nas flags. O decoder do Elm (Game.Effects.prefsDecoder) confere cada
// campo e usa o valor padrão se algo vier estranho.
export function lerPreferencias() {
  return {
    best: recordes(),
    theme: ler(CHAVES.tema) || "dark",
    muted: ler(CHAVES.mudo) === "1",
  };
}

export function salvarRecorde({ size, best }) {
  gravar(CHAVES.recordes, JSON.stringify({ ...recordes(), [size]: best }));
}

export function salvarTema(tema) {
  gravar(CHAVES.tema, tema);
}

export function salvarMudo(mudo) {
  gravar(CHAVES.mudo, mudo ? "1" : "0");
}
