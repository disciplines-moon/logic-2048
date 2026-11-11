import "./styles/main.css";
import { Elm } from "./Main.elm";

// Arquivos do repositório que os slides mostram (bloco `Code`). A chave é o
// caminho a partir da raiz; para mostrar outro arquivo, importe-o aqui.
import gamePl from "../../prolog/game.pl?raw";
import mainPy from "../../server/main.py?raw";
import apiElm from "./Api.elm?raw";
import gameElm from "./Game.elm?raw";
import historyElm from "./Game/History.elm?raw";
import ciYml from "../../.github/workflows/ci.yml?raw";
import rodarSh from "../../scripts/rodar.sh?raw";

const sources = {
  "prolog/game.pl": gamePl,
  "server/main.py": mainPy,
  "web/src/Api.elm": apiElm,
  "web/src/Game.elm": gameElm,
  "web/src/Game/History.elm": historyElm,
  ".github/workflows/ci.yml": ciYml,
  "scripts/rodar.sh": rodarSh,
};

const app = Elm.Main.init({ flags: { sources } });

// Efeitos fora do Elm: só aqui mexemos no navegador.
app.ports.toggleFullscreen.subscribe(() => {
  if (document.fullscreenElement) document.exitFullscreen();
  else document.documentElement.requestFullscreen();
});
