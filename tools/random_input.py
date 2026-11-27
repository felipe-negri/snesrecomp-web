"""Button schedule for a profiling run (nes_game --input): random play with START now and then."""
import random, sys

frames, seed = int(sys.argv[1]), int(sys.argv[2])
rng = random.Random(seed)
moves = ["RIGHT", "LEFT", "UP", "DOWN", "RIGHT+A", "RIGHT+B", "LEFT+A", "A", "B", "RIGHT+A+B", "DOWN+A"]
f = 30
while f < frames:
    if rng.random() < 0.08:
        print(f"{f} START"); print(f"{f + 6} -"); f += 40; continue
    if rng.random() < 0.03:
        print(f"{f} SELECT"); print(f"{f + 6} -"); f += 20; continue
    print(f"{f} {rng.choice(moves)}")
    f += rng.randint(8, 90)
    print(f"{f} -"); f += rng.randint(1, 12)
