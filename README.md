# snesrecomp-web

Builds for the browser (Emscripten) of published [SNESRecomp](https://github.com/RetroPortingToolKit/snesrecomp)
game ports, for the Recompendium hub. Each SNES title needs its own analysis configuration, so only the
games in `games.tsv` are accepted, recognised by the ROM's SHA-1; each recipe in `recipes/` pins the
game's port repository and lists the small web edits.

```sh
scripts/setup.sh                       # Emscripten SDK; needs git, python3, cmake, cargo
scripts/port.sh smw "Super Mario World (USA).sfc"   # -> build/web-smw/index.html
```

Supported: Super Mario World (USA), The Legend of Zelda: A Link to the Past (USA). See `games.tsv`.

```
```

No ROM or generated code is stored here. The ports and the framework are under the PolyForm
Noncommercial license with their PERMISSIONS.md; this recipe repository adds no game data.
