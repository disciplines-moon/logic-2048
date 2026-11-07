import { defineConfig } from "vite";
import elmPlugin from "vite-plugin-elm";

// Em desenvolvimento, o Vite repassa /api para o servidor Python (server/main.py).
export default defineConfig({
  base: "./",
  plugins: [elmPlugin()],
  server: {
    proxy: { "/api": "http://localhost:8000" },
    // Os slides importam arquivos de fora de web/ (prolog/ e server/) com ?raw.
    fs: { allow: [".."] },
  },
});
