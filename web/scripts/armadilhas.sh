#!/bin/sh
# Procura erros que já aconteceram neste projeto (veja AGENTS.md, "Erros que já aconteceram").
# Falha com código 1 se encontrar algum.
cd "$(dirname "$0")/.." || exit 1
erro=0

if grep -rn 'style "--' src tests 2>/dev/null; then
  echo "ERRO: Html.Attributes.style não define propriedade CSS customizada (--x)."
  echo "      Use classes ou Html.Attributes.attribute \"style\" \"--x:1\"."
  erro=1
fi

if grep -rnE 'animation-delay: *[0-9.]+s' src/styles 2>/dev/null | grep -vE 'animation-delay: *0s' | grep -q .; then
  echo "AVISO: animation-delay positivo em CSS. Em ciclos periódicos isso mostra o fim do ciclo anterior;"
  echo "       prefira delay 0 e o tempo da ação nos keyframes (AGENTS.md). Revise se for ciclo compartilhado."
fi

base=$(git rev-parse --verify -q main 2>/dev/null || git rev-parse --verify -q origin/main 2>/dev/null)
if [ -n "$base" ]; then
  if git log "$base"..HEAD --format=%B 2>/dev/null | grep -iq 'co-authored-by'; then
    echo "ERRO: commit com Co-Authored-By neste branch (proibido pelo AGENTS.md)."
    erro=1
  fi
fi

exit $erro
