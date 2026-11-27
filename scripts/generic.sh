#!/usr/bin/env bash
# Recomp genérico do SNES (chamado pelo port.sh quando a ROM não tem receita): o projeto genérico do
# SNESRecomp (tools/new_project) + rodadas de perfil, no molde do nesrecomp-web. Partidas headless com
# entrada aleatória registram o que rodou no interpretador (coverage capture); esse código vira raiz da
# análise e é recompilado antes do build web. Saída: build/web-<nome>/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
name="$1"; ROM="$(realpath "$2")"
EMSDK="${EMSDK:-$ROOT/tools/emsdk}"
FW_REPO=https://github.com/RetroPortingToolKit/snesrecomp
FW_COMMIT=7b3461a01c92f0a3cdb6d2be80855d4049e8a5cb
FRAMES="${SNESWEB_PROFILE_FRAMES:-12000}"
work="$ROOT/games/$name"; out="$ROOT/build/web-$name"
# shellcheck disable=SC1091
source "$ROOT/recipes/common.sh"

echo "== [1/6] preparando o framework (versão pinada)"
fw="$ROOT/games/.src/snesrecomp-$FW_COMMIT"
if [ ! -d "$fw/.git" ]; then
  rm -rf "$fw"; mkdir -p "$fw"
  git -C "$fw" init -q; git -C "$fw" remote add origin "$FW_REPO"
  git -C "$fw" fetch -q --depth 1 origin "$FW_COMMIT"; git -C "$fw" checkout -q -B main FETCH_HEAD  # o scaffold usa a branch main
fi
rm -rf "$work"; mkdir -p "$work"
cp "$ROM" "$work/game.sfc"; ROM="$work/game.sfc"

echo "== [2/6] criando o projeto genérico e gerando o C"
# o framework vem do cache local: o git precisa aceitar submódulo por caminho de arquivo
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=protocol.file.allow GIT_CONFIG_VALUE_0=always
if ! bash "$fw/tools/new_project/setup_project.sh" --rom "$ROM" --dir "$work" --name Game --players 2 \
     --no-ci --no-recomp-ui --no-netplay --no-fetch-boxart --no-github --no-generate --no-build --yes \
     --snesrecomp-url "$fw" > "$work/setup.log" 2>&1; then
  echo "erro: o SNESRecomp não suporta esta ROM (mapeamento ou chip especial); detalhe:" >&2
  tail -5 "$work/setup.log" >&2; exit 2
fi
proj=$(find "$work" -maxdepth 2 -name CMakeLists.txt -path '*SNESRecomp/*' -printf '%h\n' | head -1)
cd "$proj"
git submodule update -q --init --recursive
EXE=$(basename "$proj")
bash tools/regen.sh --rom "$ROM" --no-verify > "$work/regen.log" 2>&1 || { tail -20 "$work/regen.log" >&2; exit 1; }

echo "== [3/6] build nativo de análise"
cmake -S . -B "$work/native" -DCMAKE_BUILD_TYPE=Release -DSNESRECOMP_SDL_BACKEND=SDL2 \
  -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF > "$work/native.log" 2>&1
cmake --build "$work/native" --parallel --target "$EXE" >> "$work/native.log" 2>&1 \
  || { grep -m5 -E 'error:|Error [0-9]' "$work/native.log" >&2; exit 1; }

echo "== [4/6] perfil: 3 partidas com entrada aleatória"
manifests=()
for s in 1 2 3; do
  python3 "$ROOT/tools/random_input.py" "$FRAMES" "$s" > "$work/in-$s.txt"
  SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy SNESRECOMP_TIER2_MANIFEST="$work/cap-$s.json" \
    SNESRECOMP_TIER2_JOURNAL="$work/cap-$s.jsonl" "$work/native/$EXE" "$ROM" --no-launcher \
    --exit-at-frame "$FRAMES" --input-script "$work/in-$s.txt" --coverage-capture=on > "$work/run-$s.log" 2>&1 &
  manifests+=(--profile-manifest "$work/cap-$s.json" --profile-manifest "$work/cap-$s.jsonl")
done
wait
python3 snesrecomp/snesrecomp_cli.py generate --rom "$ROM" --cfg-dir recomp --out-dir src/gen \
  --funcs-h recomp/funcs.h --project-root . "${manifests[@]}" > "$work/regen2.log" 2>&1 \
  || { tail -20 "$work/regen2.log" >&2; exit 1; }
grep -E 'roots ->|AOT-eligible' "$work/regen2.log" | tail -2 | sed 's/^/   /'
rm -rf "$work/native"
snes_host_main_edits

echo "== [5/6] compilando WASM"
# shellcheck disable=SC1091
source "$EMSDK/emsdk_env.sh" > /dev/null 2>&1
ldflags="-sASYNCIFY -sASYNCIFY_IGNORE_INDIRECT -sALLOW_MEMORY_GROWTH -sINITIAL_MEMORY=256MB -sSTACK_SIZE=2MB \
-sEXIT_RUNTIME=0 -lidbfs.js -sFORCE_FILESYSTEM -sMAX_WEBGL_VERSION=2 --pre-js=$ROOT/web/pre.js --preload-file=$ROM@/game.sfc"
emcmake cmake -S . -B build -DCMAKE_BUILD_TYPE=Release "-DPython3_EXECUTABLE=$(command -v python3)" \
  -DSNESRECOMP_SDL_BACKEND=SDL2 -DSNESRECOMP_SDL_GLES2_ONLY=ON -DBUILD_TESTING=OFF -DSNESRECOMP_ENABLE_NET=OFF \
  -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF > "$work/web.log" 2>&1 \
  && cmake build "-DCMAKE_EXE_LINKER_FLAGS=$ldflags" >> "$work/web.log" 2>&1 \
  || { grep -A5 'CMake Error' "$work/web.log" >&2; exit 1; }
cmake --build build --parallel --target "$EXE" >> "$work/web.log" 2>&1 || { grep -m5 -E 'error:|Error [0-9]' "$work/web.log" >&2; exit 1; }
if grep -q 'function signature mismatch' "$work/web.log"; then
  echo "erro: funções chamadas com assinatura errada (travaria no navegador)" >&2; exit 1
fi

echo "== [6/6] publicando"
rm -rf "$out"; mkdir -p "$out"
cp "build/$EXE.js" "build/$EXE.wasm" "build/$EXE.data" "$out/"
sed "s|{{{ SCRIPT }}}|<script async src=\"$EXE.js\"></script>|" "$ROOT/web/shell.html" > "$out/index.html"
cd "$ROOT"; rm -rf "$work/src" "$proj/build"
