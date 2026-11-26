#!/usr/bin/env bash
# Contrato "web-recomp" do Recompendium: prepara o checkout (Emscripten SDK) e confere as ferramentas
# que os ports do SNESRecomp pedem pra gerar o C (Python 3, CMake, Rust). Pode rodar de novo.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
EMSDK="${EMSDK:-$root/tools/emsdk}"
EMSDK_VERSION="7.0.1"
for t in git python3 cmake cargo; do
  command -v "$t" > /dev/null || { echo "erro: falta $t no PATH" >&2; exit 1; }
done
if [ ! -f "$EMSDK/emsdk_env.sh" ]; then
  echo "== instalando o Emscripten SDK $EMSDK_VERSION em $EMSDK"
  git clone -q https://github.com/emscripten-core/emsdk.git "$EMSDK"
  "$EMSDK/emsdk" install "$EMSDK_VERSION"
  "$EMSDK/emsdk" activate "$EMSDK_VERSION"
fi
echo "== ready"
