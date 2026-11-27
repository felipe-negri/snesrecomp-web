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
}
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL2 -DSNESRECOMP_SDL_GLES2_ONLY=ON -DBUILD_TESTING=OFF
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF)
# PENDENTE (27/11): fora do Android o CMake do F-Zero exige libxml2, libpng, giflib e rapidjson do sistema
# (ferramentas de importar pistas). Pra web: reaproveitar android/dependencies.cmake (fontes pinadas via
# android/tools/fetch_sources.py) compiladas com Emscripten, ou ports do emsdk (-sUSE_LIBPNG/-sUSE_GIFLIB).
