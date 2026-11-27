# Mega Man X3: port do mstan (SNESRecomp), versão pinada. Usa o host compartilhado.
REPO=https://github.com/mstan/MegamanX3SNESRecomp
COMMIT=4ad560b450bff885e16e578cd72c7d16aa76ab74
EXE=MegaManX3SNESRecomp
recipe_regen() { cp "$ROM" mmx3.sfc; sh tools/regen.sh --no-tests; }
recipe_patch() { snes_host_main_edits; }
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL2 -DSNESRECOMP_SDL_GLES2_ONLY=ON -DBUILD_TESTING=OFF
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF)
# PENDENTE (27/11 madrugada): compila e o jogo roda (log mostra quadros e áudio), mas a tela fica preta no navegador. Investigar o caminho de desenho (renderer "sdl" do host compartilhado) comparando com Super Metroid/Demon's Crest, que mostram imagem.
