#!/usr/bin/env bash
# Contrato "web-recomp" do Recompendium: scripts/port.sh <nome> <rom.sfc|rom.smc>
# Gera a página em build/web-<nome>/ (index.html + .js/.wasm/.data).
# No SNES cada jogo precisa de config de análise própria, então só entram os jogos de games.tsv,
# reconhecidos pelo SHA-1 da ROM; cada um usa o port publicado do jogo, numa versão pinada.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
name="$1"; ROM="$(realpath "$2")"
EMSDK="${EMSDK:-$ROOT/tools/emsdk}"
work="$ROOT/games/$name"; out="$ROOT/build/web-$name"

echo "== [1/5] identificando a ROM"
size=$(stat -c %s "$ROM")
if [ $((size % 1024)) -eq 512 ]; then sha=$(tail -c +513 "$ROM" | sha1sum | cut -c1-40)  # cabeçalho de copiadora
else sha=$(sha1sum "$ROM" | cut -c1-40); fi
recipe=$(awk -F'\t' -v s="$sha" '$1==s {print $2}' "$ROOT/games.tsv")
if [ -z "$recipe" ]; then
  echo "erro: jogo não suportado (SHA-1 $sha). Suportados:" >&2
  grep -v '^#' "$ROOT/games.tsv" | cut -f3 | sed 's/^/  - /' >&2
  exit 2
fi
# shellcheck disable=SC1091
source "$ROOT/recipes/common.sh"
# shellcheck disable=SC1090
source "$ROOT/recipes/$recipe.sh"
echo "   $recipe ($REPO @ ${COMMIT:0:7})"

echo "== [2/5] baixando o port"
src="$ROOT/games/.src/$recipe-$COMMIT"
if [ ! -d "$src/.git" ]; then
  rm -rf "$src"; mkdir -p "$src"
  git -C "$src" init -q
  git -C "$src" fetch -q --depth 1 "$REPO" "$COMMIT"
  git -C "$src" checkout -q FETCH_HEAD
  git -C "$src" submodule update -q --init --recursive --depth 1 || git -C "$src" submodule update -q --init --recursive
fi
rm -rf "$work"; mkdir -p "$work"
cp "$ROM" "$work/game.sfc"; ROM="$work/game.sfc"   # caminho sem espaços p/ os flags de link
cp -a "$src" "$work/src"
cd "$work/src"

echo "== [3/5] gerando o C recompilado"
recipe_regen > "$work/regen.log" 2>&1 || { tail -20 "$work/regen.log" >&2; exit 1; }
recipe_patch

echo "== [4/5] compilando WASM"
# shellcheck disable=SC1091
source "$EMSDK/emsdk_env.sh" > /dev/null 2>&1
ldflags="-sASYNCIFY ${ASYNCIFY_MODE:--sASYNCIFY_IGNORE_INDIRECT} -sALLOW_MEMORY_GROWTH -sINITIAL_MEMORY=256MB -sSTACK_SIZE=2MB \
-sEXIT_RUNTIME=0 -lidbfs.js -sFORCE_FILESYSTEM -sMAX_WEBGL_VERSION=2 --pre-js=$ROOT/web/pre.js \
--preload-file=$ROM@/game.sfc"
# primeiro sem os flags de link: com eles os testes de configuração (pthread etc.) falham
emcmake cmake -S . -B build -DCMAKE_BUILD_TYPE=Release "${CMAKE_ARGS[@]}" > "$work/web.log" 2>&1 \
  && cmake build "-DCMAKE_EXE_LINKER_FLAGS=$ldflags" >> "$work/web.log" 2>&1 \
  || { grep -A5 'CMake Error' "$work/web.log" >&2; exit 1; }
cmake --build build --parallel --target "$EXE" >> "$work/web.log" 2>&1 || { grep -m5 'error' "$work/web.log" >&2; exit 1; }

# WebAssembly não perdoa chamada sem protótipo: o wasm-ld troca a função por uma armadilha
# (ALLOWED_MISMATCH na receita lista as que foram conferidas e não fazem mal)
bad=$(grep -o 'function signature mismatch: [A-Za-z0-9_]*' "$work/web.log" | awk '{print $4}' | sort -u \
      | grep -vxF -f <(tr ' ' '\n' <<< "${ALLOWED_MISMATCH:-}") || true)
if [ -n "$bad" ]; then
  echo "erro: funções chamadas com assinatura errada (o jogo travaria no navegador): $bad" >&2; exit 1
fi

echo "== [5/5] publicando"
rm -rf "$out"; mkdir -p "$out"
cp "build/$EXE.js" "build/$EXE.wasm" "build/$EXE.data" "$out/"
sed "s|{{{ SCRIPT }}}|<script async src=\"$EXE.js\"></script>|" "$ROOT/web/shell.html" > "$out/index.html"
cd "$ROOT"; rm -rf "$work/src"   # o port com o C gerado é grande e sai de novo a cada build
