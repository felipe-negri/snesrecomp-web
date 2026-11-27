# Star Fox: port do mstan (SNESRecomp), versão pinada. Usa o host compartilhado.
REPO=https://github.com/mstan/StarFoxSNESRecomp
COMMIT=faac8d491cf144104c0e9904ed9a3493fbc27d9e
EXE=StarFoxSNESRecomp
recipe_regen() { cp "$ROM" starfox.sfc; sh tools/regen.sh --no-tests; }
recipe_patch() { snes_host_main_edits; }
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL2 -DSNESRECOMP_SDL_GLES2_ONLY=ON -DBUILD_TESTING=OFF
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF)
# PENDENTE (27/11 madrugada): compila e o jogo roda (log mostra quadros e áudio), mas a tela fica preta no navegador. Investigar o caminho de desenho (renderer "sdl" do host compartilhado) comparando com Super Metroid/Demon's Crest, que mostram imagem.
