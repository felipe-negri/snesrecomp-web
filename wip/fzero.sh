# F-Zero: port do mstan (SNESRecomp), versão pinada. Host próprio (src/sdl_main.c).
REPO=https://github.com/mstan/FZeroSNESRecomp
COMMIT=4dfb9cdbe55e483c777171013971858d4a2054ca
EXE=FZeroSNESRecomp
recipe_regen() { cp "$ROM" fzero.sfc; bash tools/regen.sh; }
recipe_patch() {
  # a espera por quadro do laço vira emscripten_sleep, e cede a vez mesmo quando o jogo está atrasado
  python3 "$ROOT/recipes/edit.py" src/sdl_main.c \
    --prepend '#ifdef __EMSCRIPTEN__\n#include <emscripten.h>\n#endif\n' \
    --replace 'static void wait_until(double deadline) {\n' \
              'static void wait_until(double deadline) {\n#ifdef __EMSCRIPTEN__\n  { double n = (double)SDL_GetPerformanceCounter() / (double)SDL_GetPerformanceFrequency();\n    emscripten_sleep(n < deadline ? (unsigned)((deadline - n) * 1000) : 0); return; }\n#endif\n'
  snes_rnet_edit
  # fora do Android o CMake pede libxml2/png/gif/rapidjson do sistema; na web usa o mesmo caminho do
  # Android (fontes pinadas por hash em android/sources.json), sem o SDL dele (o do Emscripten já serve)
  python3 android/tools/fetch_sources.py > "$work/deps.log" 2>&1
  # o rapidjson 1.1.0 pinado tem uma atribuição que o clang novo (do Emscripten) recusa; o upstream já a removeu
  python3 "$ROOT/recipes/edit.py" android/external/rapidjson/include/rapidjson/document.h \
    --replace '    GenericStringRef& operator=(const GenericStringRef& rhs) { s = rhs.s; length = rhs.length; }' \
              '    GenericStringRef& operator=(const GenericStringRef& rhs) = delete;'
  python3 "$ROOT/recipes/edit.py" CMakeLists.txt \
    --replace 'if(ANDROID)\n    include(android/dependencies.cmake)' 'if(EMSCRIPTEN)\n    include(android/dependencies.cmake)\nelseif(ANDROID)\n    include(android/dependencies.cmake)'
  python3 "$ROOT/recipes/edit.py" android/dependencies.cmake \
    --replace 'add_subdirectory("${dep}/SDL" "${CMAKE_BINARY_DIR}/SDL" EXCLUDE_FROM_ALL)' \
              'if(NOT EMSCRIPTEN)\n    add_subdirectory("${dep}/SDL" "${CMAKE_BINARY_DIR}/SDL" EXCLUDE_FROM_ALL)\nendif()'
}
# o renderizador GL do F-Zero usa a API do SDL3 fora do Android
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL3 -DSNESRECOMP_SDL3_FETCH=ON -DBUILD_TESTING=OFF "-DCMAKE_CXX_FLAGS=-Wno-error=deprecated-declarations"
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF)
OUT_NAME="F-Zero Forever"
STAGE_DIRS="assets mods"          # pacotes de veículos/pistas que o jogo lê na hora de abrir
WEB_ARGS="'/game.sfc'"            # o F-Zero não tem --no-launcher; com a ROM na linha de comando ele já entra no jogo
# PENDENTE (27/11 madrugada): compila (SDL3 + dependências pinadas do Android, 6,9 MB) e abre, mas para em
# FzeroTracksPrepare com "[vehicles]" e erro vazio: algum pacote de veículo/pista que o build nativo deixa
# ao lado do executável não chega certo no FS da página (STAGE_DIRS="assets mods"). Próximo passo: rodar o
# build nativo e comparar a árvore ao lado do executável com o que o file_packager empacota.
