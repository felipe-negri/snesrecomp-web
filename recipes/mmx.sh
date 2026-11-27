# Mega Man X: port do mstan (SNESRecomp), versão pinada.
REPO=https://github.com/mstan/MegaManXSNESRecomp
COMMIT=3055becd46fa430f79a44778abfb724f32bd168c
EXE=MegaManXSNESRecomp
recipe_regen() { cp "$ROM" mmx.sfc; bash tools/regen.sh --no-tests; }
recipe_patch() {
  snes_host_main_edits
  snes_fiber_web   # o jogo roda numa fibra
  # o som do Sabre do Zero é convertido por uma ferramenta que tem que rodar na máquina do build:
  # compila nativa, gera o cache aqui e o build web usa o caminho que o Android já tem (cache pronto)
  cc -O2 -Isrc/saber -Itools/saber tools/saber/mmx_saber_sfx_convert.c tools/saber/mmx_saber_sfx_codec.c \
     tools/saber/third_party/stb_vorbis.c -lm -o "$work/saber_sfx_convert"
  "$work/saber_sfx_convert" --source-dir assets/saber-zero/sfx --out "$work/saber-sfx-v2.bin"
  python3 "$ROOT/recipes/edit.py" cmake/saber.cmake \
    --replace 'if(NOT ANDROID)\nadd_executable(mmx_saber_sfx_convert' 'if(NOT ANDROID AND NOT EMSCRIPTEN)\nadd_executable(mmx_saber_sfx_convert' \
    --replace 'if(ANDROID)\n    set(MMX_SABER_SFX_CACHE' 'if(ANDROID OR EMSCRIPTEN)\n    set(MMX_SABER_SFX_CACHE'
  CMAKE_ARGS+=("-DMMX_SABER_SFX_CACHE=$work/saber-sfx-v2.bin")
}
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL2 -DSNESRECOMP_SDL_GLES2_ONLY=ON -DBUILD_TESTING=OFF "-DCMAKE_C_FLAGS=-include $ROOT/recipes/mmx-protos.h"
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF)
ASYNCIFY_MODE="-sASYNCIFY_STACK_SIZE=1048576"   # Asyncify completo: a fibra troca de dentro do código recompilado
