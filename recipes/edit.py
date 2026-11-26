"""Source edit for a recipe: --prepend TEXT and/or --replace OLD NEW (\\n escapes), keeping the file's line endings.
Fails if OLD is missing, so a moved upstream line stops the build instead of silently skipping the edit."""
import sys

path, args = sys.argv[1], sys.argv[2:]
raw = open(path, "rb").read()
crlf = b"\r\n" in raw
text = raw.decode("utf-8").replace("\r\n", "\n")
unesc = lambda s: s.encode().decode("unicode_escape")
i = 0
while i < len(args):
    if args[i] == "--prepend":
        text = unesc(args[i + 1]) + text; i += 2
    elif args[i] == "--replace":
        old, new = unesc(args[i + 1]), unesc(args[i + 2])
        if old not in text:
            sys.exit(f"edit.py: trecho não encontrado em {path}: {old[:60]!r}")
        text = text.replace(old, new, 1); i += 3
    else:
        sys.exit(f"edit.py: argumento desconhecido {args[i]}")
if crlf:
    text = text.replace("\n", "\r\n")
open(path, "wb").write(text.encode("utf-8"))
