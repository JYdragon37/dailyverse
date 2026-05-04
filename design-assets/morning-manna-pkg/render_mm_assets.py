from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024


def hex_rgba(h, a=255):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (a,)


def make_vertical_gradient(size, top_colors):
    w, h = size
    img = Image.new('RGBA', size, (0, 0, 0, 0))
    px = img.load()
    stops = top_colors
    for y in range(h):
        t = y / max(h - 1, 1)
        for i in range(len(stops) - 1):
            p0, c0 = stops[i]
            p1, c1 = stops[i + 1]
            if p0 <= t <= p1:
                u = 0 if p1 == p0 else (t - p0) / (p1 - p0)
                c = tuple(int(c0[j] + (c1[j] - c0[j]) * u) for j in range(4))
                for x in range(w):
                    px[x, y] = c
                break
    return img


def add_soft_radial(base, center, radius_x, radius_y, color, alpha):
    w, h = base.size
    overlay = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    cx, cy = center
    steps = 40
    for i in range(steps, 0, -1):
        rx = radius_x * i / steps
        ry = radius_y * i / steps
        a = int(alpha * (i / steps) ** 2 * 0.5)
        draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=color[:3] + (a,))
    base.alpha_composite(overlay)


def rounded_rect_mask(size, box, radius):
    mask = Image.new('L', size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(box, radius=radius, fill=255)
    return mask


def draw_glow_line(base, box, fill, glow_fill, blur_small=6, blur_large=16, opacity_small=70, opacity_large=26, radius=6):
    w, h = base.size
    small = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    large = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    ds = ImageDraw.Draw(small)
    dl = ImageDraw.Draw(large)
    ds.rounded_rectangle(box, radius=radius, fill=glow_fill[:3] + (opacity_small,))
    dl.rounded_rectangle(box, radius=radius, fill=glow_fill[:3] + (opacity_large,))
    small = small.filter(ImageFilter.GaussianBlur(blur_small))
    large = large.filter(ImageFilter.GaussianBlur(blur_large))
    base.alpha_composite(large)
    base.alpha_composite(small)
    fg = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    dfg = ImageDraw.Draw(fg)
    dfg.rounded_rectangle(box, radius=radius, fill=fill)
    base.alpha_composite(fg)


def create_icon_png(path):
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    box = (72, 72, 952, 952)
    radius = 212

    gradient = make_vertical_gradient((SIZE, SIZE), [
        (0.00, hex_rgba('#78BEEB')),
        (0.48, hex_rgba('#BFD2EE')),
        (0.78, hex_rgba('#E8C8D4')),
        (1.00, hex_rgba('#F3B1B9')),
    ])
    mask = rounded_rect_mask((SIZE, SIZE), box, radius)
    clipped = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    clipped.paste(gradient, (0, 0), mask)
    img.alpha_composite(clipped)

    mist = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    add_soft_radial(mist, (516, 556), 330, 290, hex_rgba('#FFF9F1'), 70)
    mist_clipped = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    mist_clipped.paste(mist, (0, 0), mask)
    img.alpha_composite(mist_clipped)

    ivory = hex_rgba('#FFF8EF', 235)
    cool = hex_rgba('#EAFDFF', 255)
    cool_glow = hex_rgba('#8CEAFF', 255)
    warm = hex_rgba('#FFF4F5', 255)
    warm_glow = hex_rgba('#FF8F9D', 255)
    warm_vert = hex_rgba('#FFF7F7', 255)
    warm_vert_glow = hex_rgba('#FF9BA8', 255)

    draw_glow_line(img, (462, 152, 474, 460), cool, cool_glow, radius=6)
    draw_glow_line(img, (570, 360, 904, 372), cool, cool_glow, radius=6)
    draw_glow_line(img, (156, 540, 486, 552), warm, warm_glow, radius=6)
    draw_glow_line(img, (578, 462, 590, 874), warm_vert, warm_vert_glow, radius=6)
    draw_glow_line(img, (511, 204, 523, 824), ivory, hex_rgba('#FFF8EF'), blur_small=3, blur_large=8, opacity_small=40, opacity_large=12, radius=6)
    draw_glow_line(img, (250, 482, 770, 494), ivory, hex_rgba('#FFF8EF'), blur_small=3, blur_large=8, opacity_small=40, opacity_large=12, radius=6)

    img.save(path)


def create_logo_png(path):
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    arch_mask = Image.new('L', (SIZE, SIZE), 0)
    dm = ImageDraw.Draw(arch_mask)
    dm.rectangle((272, 392, 772, 864), fill=255)
    dm.pieslice((272, 142, 772, 642), 180, 360, fill=255)

    fill = make_vertical_gradient((SIZE, SIZE), [
        (0.00, (118, 189, 235, 184)),
        (0.45, (185, 201, 232, 122)),
        (0.72, (225, 184, 200, 138)),
        (1.00, (243, 175, 184, 173)),
    ])
    clipped = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    clipped.paste(fill, (0, 0), arch_mask)
    img.alpha_composite(clipped)

    mist = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    add_soft_radial(mist, (512, 570), 250, 210, hex_rgba('#FFF9F3'), 80)
    mist_clipped = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    mist_clipped.paste(mist, (0, 0), arch_mask)
    img.alpha_composite(mist_clipped)

    draw_glow_line(img, (244, 617, 421, 625), hex_rgba('#FFF3F5'), hex_rgba('#FF8F9F'), radius=4)
    draw_glow_line(img, (445, 213, 453, 396), hex_rgba('#F6FFFF'), hex_rgba('#A9F5FF'), radius=4)
    draw_glow_line(img, (560, 456, 786, 464), hex_rgba('#F6FFFF'), hex_rgba('#B4FAFF'), radius=4)
    draw_glow_line(img, (582, 536, 590, 864), hex_rgba('#FFF6F7'), hex_rgba('#FF96A3'), radius=4)
    draw_glow_line(img, (510, 392, 518, 864), hex_rgba('#FFF8EF', 239), hex_rgba('#FFF8EF'), blur_small=3, blur_large=8, opacity_small=40, opacity_large=12, radius=4)
    draw_glow_line(img, (294, 576, 748, 584), hex_rgba('#FFF8EF', 230), hex_rgba('#FFF8EF'), blur_small=3, blur_large=8, opacity_small=40, opacity_large=12, radius=4)

    stroke = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    ds = ImageDraw.Draw(stroke)
    ds.arc((272, 142, 772, 642), 180, 360, fill=(248, 242, 238, 210), width=16)
    ds.line((272, 392, 272, 864), fill=(248, 242, 238, 210), width=16)
    ds.line((772, 392, 772, 864), fill=(248, 242, 238, 210), width=16)
    ds.line((272, 864, 772, 864), fill=(248, 242, 238, 210), width=16)
    img.alpha_composite(stroke)
    img.save(path)


if __name__ == '__main__':
    create_icon_png('/home/ubuntu/morning_mana_app_icon_cutout.png')
    create_logo_png('/home/ubuntu/morning_mana_logo_transparent_safe.png')
