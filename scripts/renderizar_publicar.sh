#!/usr/bin/env bash
# Gera todas as versões antes de atualizar a pasta publicada.
set -euo pipefail
RAIZ_PROJETO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$RAIZ_PROJETO"
for formato in html pdf docx; do
  quarto render relatorio.qmd --to "$formato"
done
python3 scripts/publicar_pages.py
