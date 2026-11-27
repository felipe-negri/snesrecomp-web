# Super Metroid: port do mstan (SNESRecomp), versão pinada.
REPO=https://github.com/mstan/SuperMetroidRecomp
COMMIT=192aa995113f2407fa03c70bf471ea06d25f41f5
EXE=SuperMetroidSNESRecomp
recipe_regen() { bash tools/regen.sh --rom "$ROM"; }
recipe_patch() { snes_host_main_edits; }
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL2 -DSNESRECOMP_SDL_GLES2_ONLY=ON
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF)
