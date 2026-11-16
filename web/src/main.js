import "./styles/main.css";
import { Elm } from "./Main.elm";
import { tocar } from "./sons.js";
import { soltarConfete } from "./confete.js";
import { lerPreferencias, salvarRecorde, salvarTema, salvarMudo } from "./memoria.js";

// Arquivos do repositório que os slides mostram (bloco `Code`). A chave é o
// caminho a partir da raiz; para mostrar outro arquivo, importe-o aqui.
import gamePl from "../../prolog/game.pl?raw";
import mainPy from "../../server/main.py?raw";
import testMainPy from "../../server/test_main.py?raw";
import apiElm from "./Api.elm?raw";
import gameElm from "./Game.elm?raw";
import historyElm from "./Game/History.elm?raw";
import viewElm from "./Game/View.elm?raw";
import effectsElm from "./Game/Effects.elm?raw";
import portsElm from "./Ports.elm?raw";
import mainJs from "./main.js?raw";
import sonsJs from "./sons.js?raw";
import memoriaJs from "./memoria.js?raw";
import mainCss from "./styles/main.css?raw";
import ciYml from "../../.github/workflows/ci.yml?raw";
import rodarSh from "../../scripts/rodar.sh?raw";

const sources = {
  "prolog/game.pl": gamePl,
  "server/main.py": mainPy,
  "server/test_main.py": testMainPy,
  "web/src/Api.elm": apiElm,
  "web/src/Game.elm": gameElm,
  "web/src/Game/History.elm": historyElm,
  "web/src/Game/View.elm": viewElm,
  "web/src/Game/Effects.elm": effectsElm,
  "web/src/Ports.elm": portsElm,
  "web/src/main.js": mainJs,
  "web/src/sons.js": sonsJs,
  "web/src/memoria.js": memoriaJs,
  "web/src/styles/main.css": mainCss,
  ".github/workflows/ci.yml": ciYml,
  "scripts/rodar.sh": rodarSh,
};

// O estado inicial entra no Elm pelas flags: os arquivos da apresentação e o que
// o navegador lembra (recorde por tamanho, tema e som).
const app = Elm.Main.init({ flags: { sources, prefs: lerPreferencias() } });

// Efeitos fora do Elm: só aqui mexemos no navegador. Cada port é uma porta de
// saída tipada; o Elm manda a mensagem e o JavaScript executa.
app.ports.toggleFullscreen.subscribe(() => {
  if (document.fullscreenElement) document.exitFullscreen();
  else document.documentElement.requestFullscreen();
});
app.ports.playSound.subscribe(tocar);
app.ports.celebrate.subscribe(soltarConfete);
app.ports.saveBest.subscribe(salvarRecorde);
app.ports.saveTheme.subscribe(salvarTema);
app.ports.saveMuted.subscribe(salvarMudo);
