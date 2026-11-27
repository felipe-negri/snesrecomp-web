# Demon's Crest: port da comunidade (magnopaz, SNESRecomp), versão pinada. Usa o host compartilhado.
REPO=https://github.com/magnopaz/DemonsCrestSNESRecomp
COMMIT=d162a55baf5bfbb831b3f97ed190a7016dc0d422
EXE=DemonsCrestSNESRecomp
recipe_regen() { bash tools/regen.sh --rom "$ROM"; }
recipe_patch() { snes_host_main_edits; }
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL2 -DSNESRECOMP_SDL_GLES2_ONLY=ON -DBUILD_TESTING=OFF
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF)
