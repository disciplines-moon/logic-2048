import { Elm } from "./Main.elm";

// Arquivos do repositório que os slides mostram (bloco `Code`). A chave é o
// caminho a partir da raiz; para mostrar outro arquivo, importe-o aqui.
import gamePl from "../../prolog/game.pl?raw";
import mainPy from "../../server/main.py?raw";
import apiElm from "./Api.elm?raw";

const sources = {
  "prolog/game.pl": gamePl,
  "server/main.py": mainPy,
  "web/src/Api.elm": apiElm,
};

const app = Elm.Main.init({ flags: { sources } });

// Efeitos fora do Elm: só aqui mexemos no navegador.
app.ports.toggleFullscreen.subscribe(() => {
  if (document.fullscreenElement) document.exitFullscreen();
  else document.documentElement.requestFullscreen();
});
