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
    --replace 'if(ANDROID)\n    include(android/dependencies.cmake)' 'if(ANDROID OR EMSCRIPTEN)\n    include(android/dependencies.cmake)'
  python3 "$ROOT/recipes/edit.py" android/dependencies.cmake \
    --replace 'add_subdirectory("${dep}/SDL" "${CMAKE_BINARY_DIR}/SDL" EXCLUDE_FROM_ALL)' \
              'if(NOT EMSCRIPTEN)\n    add_subdirectory("${dep}/SDL" "${CMAKE_BINARY_DIR}/SDL" EXCLUDE_FROM_ALL)\nendif()'
}
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL2 -DSNESRECOMP_SDL_GLES2_ONLY=ON -DBUILD_TESTING=OFF
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF)
