# Super Mario World: port do mstan (SNESRecomp), versão pinada.
REPO=https://github.com/mstan/SuperMarioWorldRecomp
COMMIT=9cae67dbafddf4ab91068771d7136559e8adbf2e
EXE=SuperMarioWorldSNESRecomp
recipe_regen() { cp "$ROM" smw.sfc; bash tools/regen.sh --stock --no-tests; }
recipe_patch() { snes_web_edits; }
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL2 -DSNESRECOMP_SDL_GLES2_ONLY=ON -DSMW_BUNDLE_FALCON_CACHE_HELPER=OFF
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF -DSMW_NETPLAY_ICE=OFF)
# só morre (Die) se o sprite $36, que não existe no jogo, for escolhido; na web a armadilha faz o mesmo
ALLOWED_MISMATCH="SmwRejectUnusedSprite36"
