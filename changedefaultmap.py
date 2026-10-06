#!/usr/bin/python3
from random import randint


def main():
    with open(
        "/home/l4d2/serverfiles/left4dead2/maplist.txt", "r", encoding="utf-8"
    ) as f:
        maps = f.read()

    maps = maps.split("\n")
    lens = len(maps)

    whichmap = ""
    while True:
        i = randint(0, lens - 1)
        l = maps[i]
        if len(maps[i]) < 4:
            continue
        if maps[i][0] == "c" and maps[i][2:4] == "m1":
            whichmap = maps[i]
            break

    with open(
        "/home/l4d2/lgsm/config-default/config-lgsm/l4d2server/_default.cfg",
        "r",
        encoding="utf-8",
    ) as f:
        s = f.read()

    lines = s.split("\n")
    for i, l in enumerate(lines):
        if l.startswith("defaultmap"):
            lines[i] = f"defaultmap={whichmap}"
            break

    with open(
        "/home/l4d2/lgsm/config-default/config-lgsm/l4d2server/_default.cfg",
        "w",
        encoding="utf-8",
    ) as f:
        f.write("\n".join(lines))

    print(f"map changed to {whichmap}")


if __name__ == "__main__":
    main()
