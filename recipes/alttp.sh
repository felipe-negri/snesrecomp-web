# The Legend of Zelda: A Link to the Past: port do mstan (SNESRecomp), versão pinada.
REPO=https://github.com/mstan/ZeldaAlttPSNESRecomp
COMMIT=443edfd497c428fcc8a6845dad8f5ec6587bfb05
EXE=ZeldaALttPSNESRecomp
recipe_regen() { cp "$ROM" zelda.sfc; bash tools/regen.sh --no-tests; }
recipe_patch() { snes_web_edits; }
# o código do jogo usa a API do SDL3: o SDL3 é baixado e compilado pro navegador
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL3 -DSNESRECOMP_SDL3_FETCH=ON "-DCMAKE_C_FLAGS=-include $ROOT/recipes/alttp-protos.h"
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF)
