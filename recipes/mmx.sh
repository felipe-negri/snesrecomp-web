# Mega Man X: port do mstan (SNESRecomp), versão pinada.
REPO=https://github.com/mstan/MegaManXSNESRecomp
COMMIT=3055becd46fa430f79a44778abfb724f32bd168c
EXE=MegaManXSNESRecomp
recipe_regen() { cp "$ROM" mmx.sfc; bash tools/regen.sh --no-tests; }
recipe_patch() { snes_host_main_edits; }
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL2 -DSNESRECOMP_SDL_GLES2_ONLY=ON
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF)
