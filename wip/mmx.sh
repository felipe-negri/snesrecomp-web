# Mega Man X: port do mstan (SNESRecomp), versão pinada.
REPO=https://github.com/mstan/MegaManXSNESRecomp
COMMIT=3055becd46fa430f79a44778abfb724f32bd168c
EXE=MegaManXSNESRecomp
recipe_regen() { cp "$ROM" mmx.sfc; bash tools/regen.sh --no-tests; }
recipe_patch() {
  snes_host_main_edits
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
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL2 -DSNESRECOMP_SDL_GLES2_ONLY=ON -DBUILD_TESTING=OFF
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF)
# PENDENTE (27/11): o Mega Man X roda o jogo numa fibra (fiber_compat.c com ucontext, que o Emscripten não
# tem). Precisa de um backend com emscripten_fiber + Asyncify completo; o Super Metroid com Asyncify
# completo deu 88 MB de WASM e derrubou a aba, então isso exige limitar o Asyncify (ASYNCIFY_ADD/ONLY).
