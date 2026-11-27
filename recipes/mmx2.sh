# Mega Man X2: port do mstan (SNESRecomp), versão pinada. Usa o host compartilhado.
REPO=https://github.com/mstan/MegaManX2Recomp
COMMIT=622aa882881a07c8238ce17a14381c7d75a979d7
EXE=MegaManX2SNESRecomp
recipe_regen() { cp "$ROM" mmx2.sfc; sh tools/regen.sh --no-tests; }
recipe_patch() { snes_host_main_edits; snes_fiber_web; }
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL2 -DSNESRECOMP_SDL_GLES2_ONLY=ON -DBUILD_TESTING=OFF
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF)
ASYNCIFY_MODE="-sASYNCIFY_STACK_SIZE=1048576"
