"""Small carved-stone cornices (drawn at 3x, shown at 1/3) for the invisible church ledges at Rynek Podgorski."""
import random
from PIL import Image, ImageDraw

OUT = "assets/game/lvl4/podgorze/ledge_stone_%d.png"
LIP, FACE, SHADE, DARK, OUTLINE = (228, 216, 196), (198, 182, 160), (150, 132, 116), (112, 96, 88), (70, 58, 54)


def make(w_game: int, h_game: int = 9) -> None:
    random.seed(w_game)
    W, H = w_game * 3, h_game * 3
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    taper = 4 * 3  # corbel: the underside steps in
    d.rectangle([0, 0, W - 1, H - taper - 1], fill=FACE)
    for i in range(3):  # underside steps
        inset = (i + 1) * 3 * 2
        d.rectangle([inset, H - taper + i * 4, W - 1 - inset, H - taper + i * 4 + 3], fill=SHADE if i < 2 else DARK)
    d.rectangle([0, 0, W - 1, 5], fill=LIP)  # lit top edge
    d.rectangle([0, 6, W - 1, 8], fill=(214, 200, 178))
    d.rectangle([0, H - taper - 4, W - 1, H - taper - 1], fill=SHADE)
    for _ in range(W // 4):  # stone grain
        x, y = random.randrange(W), random.randrange(9, H - taper - 4)
        d.point((x, y), fill=SHADE)
    for x in range(14, W - 6, 30):  # joints
        d.line([(x, 9), (x, H - taper - 5)], fill=SHADE)
    d.rectangle([0, 0, W - 1, H - taper - 1], outline=OUTLINE)
    im.save(OUT % w_game)


for w in (23, 30, 52):
    make(w)
