# Edições que os ports do mstan (SMW, ALttP…) precisam na web: o laço principal de src/main.c dorme no ritmo
# do jogo; na web esse sono devolve o controle ao navegador, e quando o jogo está atrasado ele cede mesmo assim.
snes_web_edits() {
  python3 "$ROOT/recipes/edit.py" src/main.c \
    --prepend '#ifdef __EMSCRIPTEN__\n#include <emscripten.h>\n#endif\n' \
    --replace '        SDL_Delay(delta);\n' '#ifdef __EMSCRIPTEN__\n        emscripten_sleep(delta);\n#else\n        SDL_Delay(delta);\n#endif\n' \
    --replace '      } else if (curTick - lastTick > 500) {\n        lastTick = curTick;\n      }\n    }\n' \
              '      } else if (curTick - lastTick > 500) {\n        lastTick = curTick;\n      }\n    }\n#ifdef __EMSCRIPTEN__\n    if (lastTick <= curTick) emscripten_sleep(0);\n#endif\n'
  local rnet=snesrecomp/lib/recomp-net/src/auth/rnet_auth.c
  if [ -f "$rnet" ] && ! grep -q '<sys/time.h>' "$rnet"; then
    python3 "$ROOT/recipes/edit.py" "$rnet" --replace '#include <netinet/in.h>\n' '#include <netinet/in.h>\n#include <sys/time.h>\n'
  fi
}
