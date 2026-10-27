#!/usr/bin/env python3
"""Publica as três saídas atuais em docs/, servido pelo GitHub Pages.

Execute após renderizar HTML, PDF e DOCX. Não executa R nem baixa dados.
Recusa formatos ausentes, inválidos ou mais antigos que os fontes.
"""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

root = Path(__file__).resolve().parent.parent
fontes = [root / 'relatorio.qmd', root / '_quarto.yml', root / 'estilos.css',
          root / 'tema.scss', *root.glob('R/*.R'), *root.glob('formatos/*')]
ultima_edicao = max(p.stat().st_mtime for p in fontes if p.is_file())
arquivos = [('relatorio.html', 'index.html'), ('relatorio.pdf', 'relatorio.pdf'),
            ('relatorio.docx', 'relatorio.docx')]
for origem, _ in arquivos:
    p = root / origem
    if not p.is_file() or p.stat().st_size == 0:
        raise SystemExit(f'Renderize primeiro: {origem}')
    if p.stat().st_mtime < ultima_edicao:
        raise SystemExit(f'Saída desatualizada: {origem}. Renderize novamente.')
texto = (root / 'relatorio.html').read_text()
if 'href="relatorio.pdf"' not in texto or 'href="relatorio.docx"' not in texto:
    raise SystemExit('O HTML não contém os dois links relativos de download.')
if not (root / 'relatorio.pdf').read_bytes().startswith(b'%PDF-'):
    raise SystemExit('PDF inválido.')
with zipfile.ZipFile(root / 'relatorio.docx') as docx:
    if 'word/document.xml' not in docx.namelist():
        raise SystemExit('DOCX inválido.')
destino = root / 'docs'
destino.mkdir(exist_ok=True)
manifesto = {}
for origem, nome in arquivos:
    shutil.copyfile(root / origem, destino / nome)
    dados = (destino / nome).read_bytes()
    manifesto[nome] = {'bytes': len(dados), 'sha256': hashlib.sha256(dados).hexdigest()}
(destino / '.nojekyll').touch()
(destino / 'manifesto.json').write_text(json.dumps(manifesto, indent=2) + '\n')
print('Pages preparado: index.html, relatorio.pdf e relatorio.docx em docs/.')
