# Super Mario World: port do mstan (SNESRecomp), versão pinada.
REPO=https://github.com/mstan/SuperMarioWorldRecomp
COMMIT=9cae67dbafddf4ab91068771d7136559e8adbf2e
EXE=SuperMarioWorldSNESRecomp
recipe_regen() { cp "$ROM" smw.sfc; bash tools/regen.sh --stock --no-tests; }
recipe_patch() {
  # o laço principal dorme no ritmo do jogo: na web esse sono devolve o controle ao navegador
  python3 "$ROOT/recipes/edit.py" src/main.c \
    --prepend '#ifdef __EMSCRIPTEN__\n#include <emscripten.h>\n#endif\n' \
    --replace '        SDL_Delay(delta);\n      } else if (curTick - lastTick > 500) {\n        lastTick = curTick;\n      }\n    }\n' \
              '#ifdef __EMSCRIPTEN__\n        emscripten_sleep(delta);\n#else\n        SDL_Delay(delta);\n#endif\n      } else if (curTick - lastTick > 500) {\n        lastTick = curTick;\n      }\n    }\n#ifdef __EMSCRIPTEN__\n    else emscripten_sleep(0);\n#endif\n'
  python3 "$ROOT/recipes/edit.py" snesrecomp/lib/recomp-net/src/auth/rnet_auth.c \
    --replace '#include <netinet/in.h>\n' '#include <netinet/in.h>\n#include <sys/time.h>\n'
}
CMAKE_ARGS=(-DSNESRECOMP_SDL_BACKEND=SDL2 -DSNESRECOMP_SDL_GLES2_ONLY=ON -DSMW_BUNDLE_FALCON_CACHE_HELPER=OFF
            -DSNESRECOMP_ENABLE_NET=OFF -DSNESRECOMP_ENABLE_LUA=OFF -DSNESRECOMP_HD_GPU=OFF -DSMW_NETPLAY_ICE=OFF)
