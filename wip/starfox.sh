# Star Fox: port do mstan (SNESRecomp), versão pinada. Usa o host compartilhado.
REPO=https://github.com/mstan/StarFoxSNESRecomp
COMMIT=faac8d491cf144104c0e9904ed9a3493fbc27d9e
EXE=StarFoxSNESRecomp
recipe_regen() { cp "$ROM" starfox.sfc; sh tools/regen.sh --no-tests; }
recipe_patch() { snes_host_main_edits; snes_fiber_web; }
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL2 -DSNESRECOMP_SDL_GLES2_ONLY=ON -DBUILD_TESTING=OFF
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF)
ASYNCIFY_MODE="-sASYNCIFY_STACK_SIZE=1048576"   # o jogo roda numa fibra do host (tela preta sem isso)
# PENDENTE (27/11): nem com fibras + Asyncify completo (que resolveu o X1/X2) sai imagem; X3 roda (log), Star Fox derruba a aba.
