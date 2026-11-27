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
  # sem port pronto: recomp genérico próprio (projeto genérico do SNESRecomp + rodadas de perfil)
  echo "   sem port pronto (SHA-1 $sha): usando o recomp genérico"
  exec "$ROOT/scripts/generic.sh" "$name" "$ROM"
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
emcmake cmake -S . -B build -DCMAKE_BUILD_TYPE=Release "-DPython3_EXECUTABLE=$(command -v python3)" "${CMAKE_ARGS[@]}" > "$work/web.log" 2>&1 \
  && cmake build "-DCMAKE_EXE_LINKER_FLAGS=$ldflags" >> "$work/web.log" 2>&1 \
  || { grep -A5 'CMake Error' "$work/web.log" >&2; exit 1; }
cmake --build build --parallel --target "$EXE" >> "$work/web.log" 2>&1 || { grep -m5 -E 'error:|Error [0-9]' "$work/web.log" >&2; exit 1; }

# WebAssembly não perdoa chamada sem protótipo: o wasm-ld troca a função por uma armadilha
# (ALLOWED_MISMATCH na receita lista as que foram conferidas e não fazem mal)
bad=$(grep -o 'function signature mismatch: [A-Za-z0-9_]*' "$work/web.log" | awk '{print $4}' | sort -u \
      | grep -vxF -f <(tr ' ' '\n' <<< "${ALLOWED_MISMATCH:-}") || true)
if [ -n "$bad" ]; then
  echo "erro: funções chamadas com assinatura errada (o jogo travaria no navegador): $bad" >&2; exit 1
fi

echo "== [5/5] publicando"
rm -rf "$out"; mkdir -p "$out"
# OUT_NAME (receita): nome do arquivo quando o alvo define OUTPUT_NAME; publica sempre como $EXE.*
o="${OUT_NAME:-$EXE}"
cp "build/$o.wasm" "$out/$EXE.wasm"; cp "build/$o.data" "$out/$EXE.data"
sed -e "s|$o\.wasm|$EXE.wasm|g" -e "s|$o\.data|$EXE.data|g" "build/$o.js" > "$out/$EXE.js"
scripts="<script async src=\"$EXE.js\"></script>"
# STAGE_DIRS (receita): pastas que o build nativo deixa ao lado do executável (assets, mods...) viram um
# pacote extra carregado antes do jogo
if [ -n "${STAGE_DIRS:-}" ]; then
  pk=(); for d in $STAGE_DIRS; do pk+=("build/$d@/$d"); done
  python3 "$EMSDK/upstream/emscripten/tools/file_packager.py" "$out/$EXE-assets.data" --preload "${pk[@]}" \
    --js-output="$out/$EXE-assets.js" > /dev/null
  scripts="<script src=\"$EXE-assets.js\"></script><script src=\"$EXE.js\"></script>"
fi
sed "s|{{{ SCRIPT }}}|$scripts|" "$ROOT/web/shell.html" > "$out/index.html"
# WEB_ARGS (receita): argumentos do jogo, se não forem os de sempre
if [ -n "${WEB_ARGS:-}" ]; then
  sed -i "s|arguments: \['--no-launcher', '/game.sfc'\]|arguments: [$WEB_ARGS]|" "$out/index.html"
fi
cd "$ROOT"; rm -rf "$work/src"   # o port com o C gerado é grande e sai de novo a cada build
