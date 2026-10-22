#!/usr/bin/env bash
# Artefato de teste com marca explícita. Não gera relatorio.html de produção.
set -euo pipefail
if [[ ! -f testes/ultimo_diretorio.txt ]]; then
  echo 'Execute Rscript testes/testar.R antes.' >&2
  exit 1
fi
TESTE_DIR=$(cat testes/ultimo_diretorio.txt)
if [[ "$TESTE_DIR" != /tmp/goes_TESTE_ARTIFICIAL_* ]] || [[ ! -f "$TESTE_DIR/relatorio.qmd" ]]; then
  echo 'Diretório de teste inválido ou já removido.' >&2
  exit 1
fi
python3 - "$TESTE_DIR/relatorio.qmd" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]);s=p.read_text()
s=s.replace('title: "Análise de Valores Extremos','title: "TESTE ARTIFICIAL — NÃO USAR COMO RESULTADO SOLAR — Análise de Valores Extremos')
p.write_text(s)
PY
cd "$TESTE_DIR"
quarto render relatorio.qmd
[[ -s relatorio.html ]]
echo "HTML DE TESTE: $TESTE_DIR/relatorio.html"
