#!/usr/bin/env bash
# Instalação local testada em Debian 13 amd64, sem root. Não toca em arquivos de dados/código.
set -euo pipefail
TOOLS=/workspace/.tools
if [[ "$(uname -m)" != x86_64 ]] || ! [[ -f /usr/share/keyrings/debian-archive-keyring.gpg ]]; then
  echo 'Este instalador local requer Debian amd64 e o chaveiro Debian. Use R/Quarto do seu sistema.' >&2
  exit 1
fi
mkdir -p "$TOOLS"/apt/lists/partial "$TOOLS"/apt/archives/partial "$TOOLS"/root "$TOOLS"/bin
cat > "$TOOLS/apt/sources.list" <<'APT'
deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] https://deb.debian.org/debian trixie main
APT
cat > "$TOOLS/apt/apt.conf" <<'APT'
Dir::Etc::main "-";
Dir::Etc::parts "-";
Dir::Etc::sourcelist "/workspace/.tools/apt/sources.list";
Dir::Etc::sourceparts "-";
Dir::State::lists "/workspace/.tools/apt/lists";
Dir::Cache::archives "/workspace/.tools/apt/archives";
APT::Get::List-Cleanup "0";
APT
# Sem dpkg install: downloads autenticados pelos índices assinados, extraídos em pasta local.
if ! "$TOOLS/bin/Rscript" -e 'stopifnot(all(vapply(c("ncdf4","data.table","ggplot2","evd","knitr","rmarkdown","sn","numDeriv"),requireNamespace,quietly=TRUE,FUN.VALUE=logical(1))))' >/dev/null 2>&1; then
  APT_CONFIG="$TOOLS/apt/apt.conf" /usr/bin/apt-get update
  APT_CONFIG="$TOOLS/apt/apt.conf" /usr/bin/apt-get -o Debug::NoLocking=1 --download-only --no-install-recommends -y install \
    r-base-core r-cran-data.table r-cran-ncdf4 r-cran-ggplot2 r-cran-evd r-cran-knitr r-cran-rmarkdown r-cran-sn r-cran-numderiv
  for archive in "$TOOLS"/apt/archives/*.deb; do dpkg-deb -x "$archive" "$TOOLS/root"; done
  python3 - <<'PY'
from pathlib import Path
root=Path('/workspace/.tools/root')
for p in (root/'usr/lib/R/etc').iterdir():
    if p.is_symlink():
        target=root/str(p.readlink()).lstrip('/')
        p.unlink()
        if target.exists(): p.write_bytes(target.read_bytes())
(root/'usr/lib/R/etc/Renviron').write_bytes((root/'usr/lib/R/etc/Renviron.ucf').read_bytes())
PY
fi
cat > "$TOOLS/bin/R" <<'RWRAP'
#!/bin/sh
export R_HOME=/workspace/.tools/root/usr/lib/R
export R_SHARE_DIR=/workspace/.tools/root/usr/share/R/share
export R_INCLUDE_DIR=/workspace/.tools/root/usr/share/R/include
export R_DOC_DIR=/workspace/.tools/root/usr/share/doc/R
export R_LIBS_SITE=/workspace/.tools/root/usr/lib/R/site-library
export LD_LIBRARY_PATH=/workspace/.tools/root/usr/lib/R/lib:/workspace/.tools/root/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
exec "$R_HOME/bin/exec/R" "$@"
RWRAP
cp "$TOOLS/bin/R" "$TOOLS/root/usr/lib/R/bin/R"
python3 - <<'PY'
from pathlib import Path
p=Path('/workspace/.tools/bin/Rscript')
s=Path('/workspace/.tools/bin/R').read_text()
s=s.replace('export R_HOME=', 'export RHOME=/workspace/.tools/root/usr/lib/R\nexport R_HOME=')
s=s.replace('exec "$R_HOME/bin/exec/R" "$@"','exec /workspace/.tools/root/usr/bin/Rscript "$@"')
p.write_text(s)
PY
chmod +x "$TOOLS/bin/R" "$TOOLS/bin/Rscript"
if [[ ! -x "$TOOLS/quarto-1.7.32/bin/quarto" ]]; then
  curl -fL --retry 2 https://github.com/quarto-dev/quarto-cli/releases/download/v1.7.32/quarto-1.7.32-linux-amd64.tar.gz -o "$TOOLS/quarto.tar.gz"
  curl -fL --retry 2 https://github.com/quarto-dev/quarto-cli/releases/download/v1.7.32/quarto-1.7.32-checksums.txt -o "$TOOLS/quarto-checksums.txt"
  python3 - <<'PY'
import hashlib,pathlib
p=pathlib.Path('/workspace/.tools')
h=hashlib.sha256((p/'quarto.tar.gz').read_bytes()).hexdigest()
assert any(h in l and 'quarto-1.7.32-linux-amd64.tar.gz' in l for l in (p/'quarto-checksums.txt').read_text().splitlines()), 'SHA256 Quarto divergente'
PY
  tar -xzf "$TOOLS/quarto.tar.gz" -C "$TOOLS"
fi
cat > "$TOOLS/bin/quarto" <<'QWRAP'
#!/bin/sh
export XDG_CACHE_HOME=/workspace/.tools/cache
export XDG_DATA_HOME=/workspace/.tools/data
export XDG_CONFIG_HOME=/workspace/.tools/config
export QUARTO_R=/workspace/.tools/bin/R
export PATH=/workspace/.tools/bin:$PATH
exec /workspace/.tools/quarto-1.7.32/bin/quarto "$@"
QWRAP
chmod +x "$TOOLS/bin/quarto"
"$TOOLS/bin/Rscript" -e 'stopifnot(all(vapply(c("ncdf4","data.table","ggplot2","evd","knitr","rmarkdown","sn","numDeriv"),requireNamespace,quietly=TRUE,FUN.VALUE=logical(1)))); print(R.version.string)'
"$TOOLS/bin/quarto" --version
