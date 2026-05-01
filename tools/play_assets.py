"""
Generates Play Store visual assets for Wardly.

Layout philosophy (after design feedback):
  - Solid brand colours, no gradient mess.
  - One brand language across every slide: deep-navy canvas, a brand
    header bar at the top (W-in-blue-square logo + WARDLY wordmark
    + thin divider), then the slide-specific content below.
  - 7 slides total, same count for phone / 7-inch / 10-inch tablet:
      1. Brand intro (hero text, no phone)
      2. Problem statement (pain cards, no phone)
      3-7. Feature slides — headline + phone-frame containing the
           actual app UI.
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path
import platform
import os

# ── Palette ──────────────────────────────────────────────────────────────
# Brand primary blue used by the app icon and the wardly tutorial.
PRIMARY = (10, 92, 138)
PRIMARY_HI = (14, 122, 184)
ACCENT = (0, 200, 150)
DANGER = (216, 59, 59)
SURFACE = (245, 247, 251)
CARD = (255, 255, 255)
DIVIDER = (227, 232, 240)
TEXT_PRIMARY = (28, 35, 51)
TEXT_SECONDARY = (108, 122, 142)
TEXT_TERTIARY = (165, 175, 188)

# Deep navy canvas for marketing slides — keeps the brand feeling
# premium and lets the in-frame phone screen "pop" against it.
SLIDE_BG = (10, 22, 40)
SLIDE_BG_2 = (16, 30, 52)

OUT_DIR = Path(__file__).resolve().parent.parent / "play-assets"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# ── Fonts ─────────────────────────────────────────────────────────────────
def find_font(weight: str = "regular") -> str:
    candidates = []
    if platform.system() == "Windows":
        win = Path(os.environ.get("WINDIR", r"C:\Windows")) / "Fonts"
        candidates += [
            win / ("seguibl.ttf" if weight == "black" else
                   "seguisb.ttf" if weight == "semibold" else
                   "segoeuib.ttf" if weight == "bold" else
                   "segoeui.ttf"),
            win / "arial.ttf",
        ]
    candidates += [
        Path("/Library/Fonts/Arial.ttf"),
        Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    ]
    for c in candidates:
        if c.exists():
            return str(c)
    return ""

FONT_REG = find_font("regular")
FONT_BOLD = find_font("bold") or FONT_REG
FONT_BLACK = find_font("black") or FONT_BOLD
FONT_SEMI = find_font("semibold") or FONT_BOLD


def font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    path = {"regular": FONT_REG, "bold": FONT_BOLD,
            "black": FONT_BLACK, "semibold": FONT_SEMI}[weight]
    if not path:
        return ImageFont.load_default()
    return ImageFont.truetype(path, size)


# ── Drawing helpers ──────────────────────────────────────────────────────
def tint(rgb, alpha):
    """Mix rgb with white at the given alpha (0-255)."""
    return tuple(int(c + (255 - c) * (1 - alpha / 255)) for c in rgb)


def darken(rgb, factor):
    """Darken rgb by `factor` (0..1; 0.2 = 20% darker)."""
    return tuple(int(c * (1 - factor)) for c in rgb)


def rounded(draw, xy, r, fill=None, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=width)


def text_size(draw, text, fnt):
    bbox = draw.textbbox((0, 0), text, font=fnt)
    return bbox[2] - bbox[0], bbox[3] - bbox[1]


def text_centered(draw, xy, w, h, text, fnt, fill):
    tw, th = text_size(draw, text, fnt)
    draw.text((xy[0] + (w - tw) / 2, xy[1] + (h - th) / 2 - 1),
              text, font=fnt, fill=fill)


def fit_font(draw, text, base_size, max_width, weight="black", min_size=18):
    """Return a font sized so `text` fits within `max_width`."""
    s = base_size
    while s > min_size:
        f = font(s, weight)
        if text_size(draw, text, f)[0] <= max_width:
            return f
        s -= 4
    return font(min_size, weight)


# ── App icon: 512×512, solid blue, big W, WARDLY below ──────────────────
def make_icon():
    SIZE = 512
    img = Image.new("RGB", (SIZE, SIZE), PRIMARY)
    d = ImageDraw.Draw(img)

    # Big W in the upper ~65% of the icon. Centred horizontally, with
    # the bottom of the glyph leaving room for the wordmark below.
    w_top = 70                # padding above the W
    w_max_h = 280              # how tall the W is allowed to be
    w_font = font(w_max_h, "black")
    tw, th = text_size(d, "W", w_font)
    # Pillow's textbbox returns the visual height; centre using that.
    d.text(((SIZE - tw) / 2, w_top - int(th * 0.15)),
           "W", font=w_font, fill=(255, 255, 255))

    # WARDLY wordmark — letter-spaced, in the lower band.
    wm_size = 48
    wm_font = font(wm_size, "black")
    wm = "WARDLY"
    spacing = 14
    letters = list(wm)
    widths = [text_size(d, c, wm_font)[0] for c in letters]
    total_w = sum(widths) + spacing * (len(letters) - 1)
    x = (SIZE - total_w) // 2
    wm_y = SIZE - 95
    for c, lw in zip(letters, widths):
        d.text((x, wm_y), c, font=wm_font, fill=(255, 255, 255))
        x += lw + spacing

    img.save(OUT_DIR / "icon-512.png", "PNG")


# ── Brand header (top of every marketing slide) ──────────────────────────
def draw_brand_header(d, w, h):
    """Draws the WARDLY header bar at the top of a slide."""
    pad = int(w * 0.05)
    logo_size = int(h * 0.06)
    logo_y = int(h * 0.04)

    # Rounded white-on-blue logo square
    rounded(d, (pad, logo_y,
                pad + logo_size, logo_y + logo_size),
            r=int(logo_size * 0.22), fill=PRIMARY_HI)
    text_centered(d, (pad, logo_y), logo_size, logo_size,
                  "W", font(int(logo_size * 0.7), "black"),
                  (255, 255, 255))

    # WARDLY wordmark
    wm_size = int(logo_size * 0.55)
    wm_y = logo_y + (logo_size - wm_size) // 2 - 4
    d.text((pad + logo_size + int(logo_size * 0.4), wm_y),
           "WARDLY",
           font=font(wm_size, "black"),
           fill=(255, 255, 255))

    # Thin divider line below the header
    div_y = logo_y + logo_size + int(h * 0.02)
    d.line([(pad, div_y), (w - pad, div_y)],
           fill=(40, 60, 90), width=2)
    return div_y


# ── Slide canvas (deep navy) ─────────────────────────────────────────────
def slide_canvas(w, h):
    img = Image.new("RGB", (w, h), SLIDE_BG)
    # Subtle vignette glow in one corner for depth.
    glow = Image.new("RGB", (w, h), SLIDE_BG)
    gd = ImageDraw.Draw(glow)
    cx, cy = int(w * 0.15), int(h * 0.95)
    radius = int(min(w, h) * 0.7)
    gd.ellipse((cx - radius, cy - radius, cx + radius, cy + radius),
               fill=PRIMARY)
    glow = glow.filter(ImageFilter.GaussianBlur(120))
    img = Image.blend(img, glow, 0.18)
    return img


# ── Feature graphic: 1024×500, clean composition ─────────────────────────
def make_feature_graphic():
    W, H = 1024, 500
    img = Image.new("RGB", (W, H), PRIMARY)
    d = ImageDraw.Draw(img)

    # Subtle radial light from the right
    glow = Image.new("RGB", (W, H), PRIMARY)
    gd = ImageDraw.Draw(glow)
    gd.ellipse((W - 480, -120, W + 240, H + 120),
               fill=PRIMARY_HI)
    glow = glow.filter(ImageFilter.GaussianBlur(120))
    img = Image.blend(img, glow, 0.45)
    d = ImageDraw.Draw(img)

    pad = 56

    # ── Left half: brand block ─────────────────────────────────────
    # Logo square
    logo_size = 100
    logo_y = 96
    rounded(d, (pad, logo_y,
                pad + logo_size, logo_y + logo_size),
            r=22, fill=(255, 255, 255))
    text_centered(d, (pad, logo_y), logo_size, logo_size,
                  "W", font(76, "black"), PRIMARY)

    # WARDLY wordmark next to logo
    wm_x = pad + logo_size + 28
    d.text((wm_x, logo_y + 4),
           "WARDLY", font=font(58, "black"),
           fill=(255, 255, 255))
    d.text((wm_x, logo_y + 70),
           "Ward, connected.",
           font=font(24, "regular"),
           fill=(200, 220, 240))

    # Tagline below — sized to fit within left half (max ~520 px wide)
    line1 = "One live feed for the"
    line2 = "whole ward team."
    title_font = fit_font(d, line2, 50, 520, "black")
    d.text((pad, 280), line1, font=title_font, fill=(255, 255, 255))
    d.text((pad, 280 + title_font.size + 6), line2,
           font=title_font, fill=(255, 255, 255))

    sub_font = font(20, "regular")
    d.text((pad, 280 + (title_font.size + 6) * 2 + 14),
           "Real-time clinical notes. Acknowledged on the record.",
           font=sub_font, fill=(200, 220, 240))

    # ── Right half: ack pill (no clipped note card) ────────────────
    # Keeping this ELEMENT TIGHT so it never bleeds outside the canvas.
    pill_x = W - 380
    pill_y = 130
    pill_w = 320
    rounded(d, (pill_x, pill_y, pill_x + pill_w, pill_y + 240),
            r=20, fill=(255, 255, 255))
    # Priority pill
    rounded(d, (pill_x + 18, pill_y + 18,
                pill_x + 132, pill_y + 56),
            r=10, fill=tint(DANGER, 60))
    d.ellipse((pill_x + 28, pill_y + 28,
               pill_x + 46, pill_y + 46),
              fill=DANGER)
    d.text((pill_x + 56, pill_y + 26), "Urgent",
           font=font(18, "bold"), fill=DANGER)
    # Body
    d.text((pill_x + 18, pill_y + 76),
           "BP dropping — please review.",
           font=font(17, "bold"), fill=TEXT_PRIMARY)
    d.text((pill_x + 18, pill_y + 104),
           "Started fluids, awaiting\ncardiology callback.",
           font=font(15, "regular"),
           fill=TEXT_SECONDARY,
           spacing=6)
    # Author
    d.text((pill_x + 18, pill_y + 168),
           "Dr. Pew Pew · 2 min ago",
           font=font(13, "regular"), fill=TEXT_SECONDARY)
    # Ack stripe
    rounded(d, (pill_x + 18, pill_y + 196,
                pill_x + pill_w - 18, pill_y + 224),
            r=8, fill=tint(ACCENT, 60))
    d.ellipse((pill_x + 26, pill_y + 200,
               pill_x + 42, pill_y + 216),
              outline=ACCENT, width=2)
    d.line([(pill_x + 30, pill_y + 209),
            (pill_x + 33, pill_y + 212),
            (pill_x + 38, pill_y + 205)],
           fill=ACCENT, width=2)
    d.text((pill_x + 50, pill_y + 199),
           "Acknowledged by Sunil",
           font=font(13, "bold"), fill=ACCENT)

    img.save(OUT_DIR / "feature-graphic-1024x500.png", "PNG")


# ── Phone-frame helper used INSIDE the in-app screen mocks ───────────────
def app_frame(width, height, content_drawer):
    img = Image.new("RGB", (width, height), SURFACE)
    d = ImageDraw.Draw(img)

    sb = max(60, height // 32)
    d.rectangle((0, 0, width, sb), fill=PRIMARY)
    d.text((width // 2 - 36, sb // 2 - 12), "9:41",
           font=font(int(sb * 0.4), "semibold"),
           fill=(255, 255, 255))
    for i, w in enumerate([6, 8, 10, 12]):
        d.rectangle((width - 160 + i * 14, sb // 2 + 4 - w,
                     width - 160 + i * 14 + 8, sb // 2 + 4),
                    fill=(255, 255, 255))
    rounded(d, (width - 90, sb // 2 - 8, width - 30, sb // 2 + 8),
            r=4, fill=(255, 255, 255))

    ab_h = max(110, height // 18)
    d.rectangle((0, sb, width, sb + ab_h), fill=PRIMARY)

    bn_h = max(140, height // 14)
    bn_y = height - bn_h
    d.rectangle((0, bn_y, width, height), fill=CARD)
    d.line([(0, bn_y), (width, bn_y)], fill=DIVIDER, width=2)

    content_drawer(d, 0, sb + ab_h, width, height - sb - ab_h - bn_h, img)
    return img, sb, ab_h, bn_h


def draw_bottom_nav(d, w, h, bn_h, active_idx, items):
    bn_y = h - bn_h
    seg = w / len(items)
    for i, label in enumerate(items):
        cx = int(seg * (i + 0.5))
        is_active = (i == active_idx)
        clr = PRIMARY if is_active else TEXT_TERTIARY
        r = 9
        d.ellipse((cx - r, bn_y + bn_h // 2 - r - 18,
                   cx + r, bn_y + bn_h // 2 + r - 18), fill=clr)
        fnt = font(20 if w > 1200 else 18,
                   "bold" if is_active else "regular")
        tw, _ = text_size(d, label, fnt)
        d.text((cx - tw / 2, bn_y + bn_h // 2 + 6),
               label, font=fnt, fill=clr)


def draw_appbar_title(d, sb, ab_h, w, title, badge=None):
    d.text((40, sb + ab_h // 2 - 18),
           title, font=font(32, "bold"),
           fill=(255, 255, 255))
    if badge:
        bw, bh = text_size(d, badge, font(16, "bold"))
        bx = w - 50 - bw - 24
        by = sb + ab_h // 2 - bh // 2 - 4
        rounded(d, (bx, by, bx + bw + 24, by + bh + 12),
                r=10, fill=DANGER)
        d.text((bx + 12, by + 5), badge,
               font=font(16, "bold"), fill=(255, 255, 255))


# ── App-screen mocks (content for slides 3-7) ────────────────────────────
def screen_ward_feed(width, height):
    def content(d, x, y, w, h, img):
        d.text((40, y + 24), "Live ward feed",
               font=font(28, "bold"), fill=TEXT_PRIMARY)
        d.text((40, y + 64), "ICU Ward A · 8 members online",
               font=font(20, "regular"), fill=TEXT_SECONDARY)

        cards = [
            ("Urgent", DANGER, "Bed 12 · Mr. R. Kumar",
             "BP dropping — please review. Started fluids, awaiting cardiology callback.",
             "Dr. Pew Pew · 2 min ago", True, "Sunil Mulgund"),
            ("Normal", PRIMARY, "Bed 18 · Ms. A. Shah",
             "Plan for tomorrow: repeat CBC at 6 am, hold metoprolol if HR <55.",
             "Dr. Pew Pew · 12 min ago", False, None),
            ("Low", TEXT_SECONDARY, "Bed 24 · Mr. S. Iyer",
             "Reassuring labs back. Continue current regimen.",
             "Dr. Smith · 32 min ago", True, "Pew Pew"),
        ]
        cy = y + 130
        for prio, prio_clr, who, body, foot, acked, by in cards:
            cx, cw, ch = 30, w - 60, 320
            rounded(d, (cx, cy, cx + cw, cy + ch), r=22,
                    fill=CARD, outline=DIVIDER, width=2)
            rounded(d, (cx + 22, cy + 22, cx + 150, cy + 60),
                    r=10, fill=tint(prio_clr, 30))
            d.ellipse((cx + 32, cy + 32, cx + 50, cy + 50),
                      fill=prio_clr)
            d.text((cx + 60, cy + 28), prio,
                   font=font(18, "bold"), fill=prio_clr)
            d.text((cx + 170, cy + 30), who,
                   font=font(18, "regular"), fill=TEXT_SECONDARY)
            d.text((cx + 22, cy + 78), body,
                   font=font(22, "regular"), fill=TEXT_PRIMARY)
            d.text((cx + 22, cy + 200), foot,
                   font=font(16, "regular"), fill=TEXT_SECONDARY)
            if acked:
                rounded(d, (cx + 22, cy + 240,
                            cx + cw - 22, cy + 280),
                        r=8, fill=tint(ACCENT, 30))
                d.ellipse((cx + 32, cy + 250, cx + 56, cy + 274),
                          outline=ACCENT, width=3)
                d.line([(cx + 38, cy + 263), (cx + 44, cy + 269),
                        (cx + 52, cy + 257)], fill=ACCENT, width=3)
                d.text((cx + 64, cy + 250),
                       f"Acknowledged by {by}",
                       font=font(16, "bold"), fill=ACCENT)
            cy += ch + 30

    img, sb, ab_h, bn_h = app_frame(width, height, content)
    d = ImageDraw.Draw(img)
    draw_appbar_title(d, sb, ab_h, width, "Wardly", badge="3 unack")
    draw_bottom_nav(d, width, height, bn_h, 3,
                    ["Home", "Wards", "Patients", "Notes", "Profile"])
    return img


def screen_wards(width, height):
    def content(d, x, y, w, h, img):
        d.text((40, y + 24), "My wards",
               font=font(28, "bold"), fill=TEXT_PRIMARY)
        d.text((40, y + 64),
               "Tap a 5-digit code to copy and share.",
               font=font(20, "regular"), fill=TEXT_SECONDARY)

        wards = [
            ("ICU Ward A", "47291", "3rd floor", True, "You"),
            ("Cardiology", "82046", "5th floor", False, "Dr. Pew Pew"),
            ("Postop Recovery", "13957", "2nd floor", False, "Dr. Smith"),
        ]
        cy = y + 130
        for name, code, floor, is_owner, owner_name in wards:
            cx, cw, ch = 30, w - 60, 280
            rounded(d, (cx, cy, cx + cw, cy + ch), r=22,
                    fill=CARD, outline=DIVIDER, width=2)
            rounded(d, (cx + 24, cy + 24, cx + 90, cy + 90),
                    r=14, fill=PRIMARY)
            text_centered(d, (cx + 24, cy + 24), 66, 66,
                          "W", font(36, "black"), (255, 255, 255))
            d.text((cx + 110, cy + 28), name,
                   font=font(26, "bold"), fill=TEXT_PRIMARY)
            d.text((cx + 110, cy + 64), floor,
                   font=font(18, "regular"), fill=TEXT_SECONDARY)
            if is_owner:
                rounded(d, (cx + cw - 220, cy + 28,
                            cx + cw - 24, cy + 68), r=10,
                        fill=tint(ACCENT, 60))
                d.text((cx + cw - 210, cy + 36), "OWNED BY YOU",
                       font=font(14, "bold"), fill=ACCENT)
            d.text((cx + 24, cy + 110),
                   f"Owned by {owner_name}",
                   font=font(20, "regular"), fill=TEXT_PRIMARY)
            rounded(d, (cx + 24, cy + 150, cx + cw - 24, cy + 220),
                    r=14, fill=SURFACE, outline=DIVIDER, width=2)
            d.text((cx + 40, cy + 168), f"Code: {code}",
                   font=font(28, "bold"), fill=TEXT_PRIMARY)
            d.text((cx + cw - 130, cy + 178), "tap to copy",
                   font=font(16, "regular"), fill=TEXT_SECONDARY)
            cy += ch + 30

        by = h + y - 110
        bw = (w - 90) // 2
        rounded(d, (30, by, 30 + bw, by + 80), r=14,
                outline=PRIMARY, width=3)
        text_centered(d, (30, by), bw, 80, "Join Ward",
                      font(24, "bold"), PRIMARY)
        rounded(d, (60 + bw, by, w - 30, by + 80), r=14,
                fill=PRIMARY)
        text_centered(d, (60 + bw, by), bw, 80, "Create New Ward",
                      font(24, "bold"), (255, 255, 255))

    img, sb, ab_h, bn_h = app_frame(width, height, content)
    d = ImageDraw.Draw(img)
    draw_appbar_title(d, sb, ab_h, width, "Wards")
    draw_bottom_nav(d, width, height, bn_h, 1,
                    ["Home", "Wards", "Patients", "Notes", "Profile"])
    return img


def screen_patients(width, height):
    def content(d, x, y, w, h, img):
        rounded(d, (30, y + 24, w - 30, y + 100), r=18,
                fill=CARD, outline=DIVIDER, width=2)
        d.ellipse((50, y + 50, 78, y + 78),
                  outline=PRIMARY, width=4)
        d.line([(72, y + 72), (96, y + 96)], fill=PRIMARY, width=4)
        d.text((110, y + 50), "kumar",
               font=font(24, "regular"), fill=TEXT_PRIMARY)
        d.text((w - 90, y + 50), "✕",
               font=font(24, "bold"), fill=TEXT_SECONDARY)

        d.text((40, y + 130), "2 matches · across 3 wards",
               font=font(18, "bold"), fill=TEXT_SECONDARY)

        patients = [
            ("RK", "Mr. Ramesh Kumar", "kumar",
             "Bed 12 · ICU Ward A", "Sepsis · IV antibiotics"),
            ("PK", "Ms. Priya Kumari", "kumar",
             "Bed 7 · Cardiology", "Post-stent · stable"),
        ]
        cy = y + 180
        for initials, full_name, hi, sub, dx in patients:
            cx, cw, ch = 30, w - 60, 220
            rounded(d, (cx, cy, cx + cw, cy + ch), r=22,
                    fill=CARD, outline=PRIMARY, width=3)
            rounded(d, (cx + 24, cy + 30, cx + 124, cy + 130),
                    r=50, fill=tint(PRIMARY, 50))
            text_centered(d, (cx + 24, cy + 30), 100, 100,
                          initials, font(36, "bold"), PRIMARY)
            lo = full_name.lower()
            i = lo.find(hi)
            if i >= 0:
                prefix = full_name[:i]
                match = full_name[i:i + len(hi)]
                suffix = full_name[i + len(hi):]
                fnt = font(26, "bold")
                tx = cx + 144
                ty = cy + 36
                d.text((tx, ty), prefix, font=fnt, fill=TEXT_PRIMARY)
                pw, _ = text_size(d, prefix, fnt)
                mw, _ = text_size(d, match, fnt)
                rounded(d, (tx + pw - 4, ty - 4,
                            tx + pw + mw + 6, ty + 38),
                        r=6, fill=tint(PRIMARY, 70))
                d.text((tx + pw, ty), match, font=fnt,
                       fill=PRIMARY)
                d.text((tx + pw + mw, ty), suffix, font=fnt,
                       fill=TEXT_PRIMARY)
            else:
                d.text((cx + 144, cy + 36), full_name,
                       font=font(26, "bold"), fill=TEXT_PRIMARY)
            d.text((cx + 144, cy + 80), sub,
                   font=font(20, "regular"), fill=TEXT_SECONDARY)
            d.text((cx + 144, cy + 130), dx,
                   font=font(20, "regular"), fill=TEXT_PRIMARY)
            rounded(d, (cx + 144, cy + 170, cx + 250, cy + 200),
                    r=8, fill=tint(ACCENT, 60))
            d.text((cx + 156, cy + 174), "Active",
                   font=font(15, "bold"), fill=ACCENT)
            cy += ch + 24

    img, sb, ab_h, bn_h = app_frame(width, height, content)
    d = ImageDraw.Draw(img)
    draw_appbar_title(d, sb, ab_h, width, "Patients")
    draw_bottom_nav(d, width, height, bn_h, 2,
                    ["Home", "Wards", "Patients", "Notes", "Profile"])
    return img


def screen_thread(width, height):
    def content(d, x, y, w, h, img):
        cy = y + 30
        cx, cw, ch = 30, w - 60, 240
        rounded(d, (cx, cy, cx + cw, cy + ch), r=22,
                fill=CARD, outline=DIVIDER, width=2)
        rounded(d, (cx + 22, cy + 22, cx + 150, cy + 60),
                r=10, fill=tint(DANGER, 30))
        d.ellipse((cx + 32, cy + 32, cx + 50, cy + 50),
                  fill=DANGER)
        d.text((cx + 60, cy + 28), "Urgent",
               font=font(18, "bold"), fill=DANGER)
        d.text((cx + 22, cy + 78),
               "Do death summary",
               font=font(28, "bold"), fill=TEXT_PRIMARY)
        d.text((cx + 22, cy + 130),
               "Family been informed. Need MLC paperwork before EOD.",
               font=font(20, "regular"), fill=TEXT_PRIMARY)
        d.text((cx + 22, cy + 190),
               "Note by Dr. Pew Pew · a moment ago",
               font=font(16, "regular"), fill=TEXT_SECONDARY)

        cy += ch + 30
        cx, cw, ch = 30, w - 60, 200
        rounded(d, (cx, cy, cx + cw, cy + ch), r=22,
                fill=(245, 254, 251), outline=ACCENT, width=3)
        rounded(d, (cx + 22, cy + 22, cx + 70, cy + 70),
                r=24, fill=tint(ACCENT, 50))
        d.text((cx + 30, cy + 32), "SM",
               font=font(20, "bold"), fill=ACCENT)
        d.text((cx + 80, cy + 22), "Sunil Mulgund",
               font=font(22, "bold"), fill=TEXT_PRIMARY)
        rounded(d, (cx + 270, cy + 24, cx + 360, cy + 54),
                r=8, fill=tint(PRIMARY, 60))
        d.text((cx + 282, cy + 28), "Doctor",
               font=font(15, "bold"), fill=PRIMARY)
        d.ellipse((cx + 80, cy + 70, cx + 102, cy + 92),
                  outline=ACCENT, width=3)
        d.line([(cx + 86, cy + 81), (cx + 91, cy + 86),
                (cx + 98, cy + 75)], fill=ACCENT, width=3)
        d.text((cx + 110, cy + 70),
               "Acknowledged by Sunil Mulgund",
               font=font(16, "bold"), fill=ACCENT)
        d.text((cx + 80, cy + 110),
               "On it — calling on-call admin now.",
               font=font(22, "regular"), fill=TEXT_PRIMARY)
        d.text((cx + 80, cy + 150), "now",
               font=font(15, "regular"), fill=TEXT_SECONDARY)

        cy = h + y - 110
        rounded(d, (30, cy, w - 200, cy + 80), r=18,
                fill=SURFACE, outline=DIVIDER, width=2)
        d.text((54, cy + 26), "Write a reply…",
               font=font(20, "regular"), fill=TEXT_SECONDARY)
        rounded(d, (w - 180, cy, w - 105, cy + 80),
                r=18, fill=tint(ACCENT, 60))
        d.ellipse((w - 162, cy + 14, w - 122, cy + 54),
                  outline=ACCENT, width=4)
        d.line([(w - 153, cy + 36), (w - 144, cy + 45),
                (w - 130, cy + 25)], fill=ACCENT, width=4)
        rounded(d, (w - 90, cy, w - 30, cy + 80),
                r=18, fill=PRIMARY)
        d.polygon([(w - 70, cy + 24), (w - 50, cy + 40),
                   (w - 70, cy + 56)], fill=(255, 255, 255))

    img, sb, ab_h, bn_h = app_frame(width, height, content)
    d = ImageDraw.Draw(img)
    draw_appbar_title(d, sb, ab_h, width, "Thread")
    draw_bottom_nav(d, width, height, bn_h, 3,
                    ["Home", "Wards", "Patients", "Notes", "Profile"])
    return img


def screen_profile(width, height):
    def content(d, x, y, w, h, img):
        cy = y + 30
        rounded(d, (30, cy, w - 30, cy + 280), r=22,
                fill=CARD, outline=DIVIDER, width=2)
        d.ellipse((w // 2 - 70, cy + 30, w // 2 + 70, cy + 170),
                  fill=tint(PRIMARY, 50))
        text_centered(d, (w // 2 - 70, cy + 30), 140, 140,
                      "SM", font(60, "black"), PRIMARY)
        text_centered(d, (0, cy + 180), w, 40,
                      "Sunil Mulgund", font(28, "bold"),
                      TEXT_PRIMARY)
        text_centered(d, (0, cy + 226), w, 30,
                      "Cardiologist", font(20, "bold"),
                      PRIMARY)

        cy += 320
        # Each row pairs a small coloured tile (with a single letter) with
        # a label — emoji glyphs were rendering as tofu boxes on Windows.
        rows = [
            ("E", "Edit profile", "Update name and specialty", PRIMARY),
            ("N", "Notification setup", "Re-run the reliability wizard", PRIMARY),
            ("?", "Help & FAQs", "Quick answers to the basics", PRIMARY),
            ("★", "Rate on Play Store", "Help other ward teams find Wardly", (229, 127, 0)),
            ("!", "Report a bug", "Auto-fills version + platform", DANGER),
        ]
        rounded(d, (30, cy, w - 30, cy + len(rows) * 110),
                r=22, fill=CARD, outline=DIVIDER, width=2)
        for i, (ico, t, sub, ico_color) in enumerate(rows):
            ry = cy + i * 110
            # Coloured tile with letter
            tile_size = 56
            tile_x, tile_y = 50, ry + 27
            rounded(d, (tile_x, tile_y,
                        tile_x + tile_size, tile_y + tile_size),
                    r=14, fill=tint(ico_color, 60))
            text_centered(d, (tile_x, tile_y), tile_size, tile_size,
                          ico, font(28, "black"), ico_color)
            d.text((130, ry + 22), t,
                   font=font(22, "bold"), fill=TEXT_PRIMARY)
            d.text((130, ry + 56), sub,
                   font=font(18, "regular"), fill=TEXT_SECONDARY)
            d.text((w - 70, ry + 38), "›",
                   font=font(36, "bold"), fill=TEXT_TERTIARY)
            if i < len(rows) - 1:
                d.line([(110, ry + 109),
                        (w - 30, ry + 109)],
                       fill=DIVIDER, width=2)

    img, sb, ab_h, bn_h = app_frame(width, height, content)
    d = ImageDraw.Draw(img)
    draw_appbar_title(d, sb, ab_h, width, "Profile")
    draw_bottom_nav(d, width, height, bn_h, 4,
                    ["Home", "Wards", "Patients", "Notes", "Profile"])
    return img


FEATURE_SCREENS = [
    ("ward-feed", screen_ward_feed,
     "Real-time ward feed",
     "Every note, live, to the whole team."),
    ("wards", screen_wards,
     "5-digit ward codes",
     "Share a code — your team is in."),
    ("patients", screen_patients,
     "Search across every ward",
     "Find any patient in one tap."),
    ("thread", screen_thread,
     "Acknowledged, on the record",
     "See who handled what, when."),
    ("profile", screen_profile,
     "Yours, end to end",
     "Settings, FAQs, feedback — all in one place."),
]


# ── Phone-frame mock for marketing slides (Android-style) ───────────────
def render_phone_in_frame(inner_img, frame_w, frame_h, corner_r=64,
                          bezel=14, frame_color=(20, 25, 40)):
    """
    Draws an Android-style device frame: thin uniform bezel, generous
    rounded corners, a small punch-hole camera at the top centre. No
    iPhone notch. Side-rail buttons (volume + power) are rendered as
    subtle slivers along the right edge.
    """
    img = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Outer phone body
    d.rounded_rectangle((0, 0, frame_w, frame_h),
                        radius=corner_r, fill=frame_color)

    # Side-rail subtle highlight (gives the body some dimension)
    d.rounded_rectangle((1, 1, frame_w - 1, frame_h - 1),
                        radius=corner_r - 1,
                        outline=(40, 50, 70), width=2)

    # Side buttons on the right edge
    btn_x = frame_w - 4
    # power
    d.rounded_rectangle((btn_x, int(frame_h * 0.18),
                         btn_x + 6, int(frame_h * 0.22)),
                        radius=2, fill=(60, 70, 90))
    # volume up
    d.rounded_rectangle((btn_x, int(frame_h * 0.28),
                         btn_x + 6, int(frame_h * 0.33)),
                        radius=2, fill=(60, 70, 90))
    # volume down
    d.rounded_rectangle((btn_x, int(frame_h * 0.34),
                         btn_x + 6, int(frame_h * 0.39)),
                        radius=2, fill=(60, 70, 90))

    # Inner screen
    sx, sy = bezel, bezel
    sw, sh = frame_w - bezel * 2, frame_h - bezel * 2
    inner_resized = inner_img.resize((sw, sh), Image.LANCZOS)
    mask = Image.new("L", (sw, sh), 0)
    mk = ImageDraw.Draw(mask)
    mk.rounded_rectangle((0, 0, sw, sh),
                         radius=corner_r - bezel, fill=255)
    img.paste(inner_resized, (sx, sy), mask)

    # Punch-hole front camera (Galaxy S-style, top-centre, just inside
    # the screen).
    cam_d = max(20, int(frame_w * 0.025))
    cx = frame_w // 2
    cy = bezel + int(cam_d * 1.4)
    # Outer dark ring
    d.ellipse((cx - cam_d // 2, cy - cam_d // 2,
               cx + cam_d // 2, cy + cam_d // 2),
              fill=(15, 18, 25))
    # Lens highlight
    inset = max(2, cam_d // 6)
    d.ellipse((cx - cam_d // 2 + inset, cy - cam_d // 2 + inset,
               cx + cam_d // 2 - inset, cy + cam_d // 2 - inset),
              fill=(35, 40, 55))
    return img


# ── Slide layouts ────────────────────────────────────────────────────────
def slide_intro(w, h):
    """Slide 1: brand hero. No phone. Just brand + tagline."""
    img = slide_canvas(w, h)
    d = ImageDraw.Draw(img)
    div_y = draw_brand_header(d, w, h)

    # Big logo block, centred
    logo_size = int(min(w, h) * 0.34)
    lx = (w - logo_size) // 2
    ly = int(h * 0.22)
    rounded(d, (lx, ly, lx + logo_size, ly + logo_size),
            r=int(logo_size * 0.22), fill=PRIMARY)
    text_centered(d, (lx, ly), logo_size, logo_size,
                  "W", font(int(logo_size * 0.7), "black"),
                  (255, 255, 255))

    # Hero copy
    title_y = ly + logo_size + int(h * 0.05)
    title = "Ward, connected."
    title_font = fit_font(d, title, int(h * 0.07),
                          int(w * 0.86), "black")
    tw, th = text_size(d, title, title_font)
    d.text(((w - tw) // 2, title_y), title,
           font=title_font, fill=(255, 255, 255))

    sub_y = title_y + th + int(h * 0.02)
    subtitle = "Real-time clinical notes for ward teams."
    sub_font = font(int(h * 0.026), "regular")
    sw_, _ = text_size(d, subtitle, sub_font)
    d.text(((w - sw_) // 2, sub_y), subtitle,
           font=sub_font, fill=(180, 200, 220))

    # Feature pills
    pills = ["Real-time", "Acknowledged", "Ward-private"]
    pill_y = sub_y + int(h * 0.08)
    pill_font = font(int(h * 0.022), "bold")
    pads_x, pads_y = int(h * 0.02), int(h * 0.012)
    spaces = int(w * 0.025)
    sizes = [text_size(d, p, pill_font)[0] + pads_x * 2 for p in pills]
    total = sum(sizes) + spaces * (len(pills) - 1)
    x = (w - total) // 2
    for i, p in enumerate(pills):
        sw_p = sizes[i]
        rounded(d, (x, pill_y, x + sw_p,
                    pill_y + int(h * 0.05)),
                r=int(h * 0.025),
                fill=PRIMARY)
        text_centered(d, (x, pill_y), sw_p, int(h * 0.05),
                      p, pill_font, (255, 255, 255))
        x += sw_p + spaces

    return img


def slide_problem(w, h):
    """Slide 2: pain points. No phone."""
    img = slide_canvas(w, h)
    d = ImageDraw.Draw(img)
    div_y = draw_brand_header(d, w, h)

    # Eyebrow — dark red text on a light pink pill so it's actually
    # legible against the navy background.
    eb_y = div_y + int(h * 0.04)
    eb = "THE PROBLEM"
    eb_font = font(int(h * 0.018), "black")
    ew, eh = text_size(d, eb, eb_font)
    rounded(d, ((w - ew) // 2 - 18, eb_y,
                (w + ew) // 2 + 18, eb_y + eh + 14),
            r=10, fill=(255, 230, 230))
    d.text(((w - ew) // 2, eb_y + 6), eb,
           font=eb_font, fill=DANGER)

    # Headline (auto-shrink)
    title = "Updates lost in chaos."
    title_y = eb_y + eh + int(h * 0.05)
    title_font = fit_font(d, title, int(h * 0.058),
                          int(w * 0.9), "black")
    tw, th = text_size(d, title, title_font)
    d.text(((w - tw) // 2, title_y), title,
           font=title_font, fill=(255, 255, 255))

    sub = "Every shift, critical info slips through the cracks."
    sub_font = font(int(h * 0.022), "regular")
    sw_, sh_ = text_size(d, sub, sub_font)
    d.text(((w - sw_) // 2, title_y + th + int(h * 0.013)),
           sub, font=sub_font, fill=(180, 200, 220))

    pains = [
        # (number, title, body) — numbered tiles render reliably across
        # platforms; emoji glyphs were falling back to tofu boxes.
        ("01", "WhatsApp burial", "Urgent updates buried in group chats."),
        ("02", "Lost paper notes", "Plans never reach the next shift."),
        ("03", "No ack trail", "Did you see the new plan? Nobody knows."),
        ("04", "Phone tag", "Nurse calls doctor, doctor calls back."),
        ("05", "Broken handover", "Next team comes in blind."),
    ]
    card_x = int(w * 0.08)
    card_w = int(w * 0.84)
    card_h = int(h * 0.082)
    gap = int(h * 0.014)
    start_y = title_y + th + int(h * 0.13)
    for i, (num, t, s) in enumerate(pains):
        cy = start_y + i * (card_h + gap)
        rounded(d, (card_x, cy, card_x + card_w, cy + card_h),
                r=int(card_h * 0.18),
                fill=(255, 255, 255))
        d.rectangle((card_x, cy, card_x + 6, cy + card_h),
                    fill=DANGER)
        ico_size = int(card_h * 0.55)
        ix = card_x + int(card_h * 0.18)
        iy = cy + (card_h - ico_size) // 2
        rounded(d, (ix, iy, ix + ico_size, iy + ico_size),
                r=int(ico_size * 0.22),
                fill=DANGER)
        text_centered(d, (ix, iy), ico_size, ico_size,
                      num, font(int(ico_size * 0.4), "black"),
                      (255, 255, 255))
        tx = ix + ico_size + int(card_h * 0.2)
        d.text((tx, cy + int(card_h * 0.18)), t,
               font=font(int(card_h * 0.27), "bold"),
               fill=TEXT_PRIMARY)
        d.text((tx, cy + int(card_h * 0.55)), s,
               font=font(int(card_h * 0.21), "regular"),
               fill=TEXT_SECONDARY)

    # Closing arrow
    foot = "→ Wardly fixes that."
    foot_font = font(int(h * 0.024), "bold")
    fw, fh = text_size(d, foot, foot_font)
    d.text(((w - fw) // 2, h - fh - int(h * 0.05)),
           foot, font=foot_font, fill=ACCENT)
    return img


def slide_feature(inner_img, w, h, headline, subtitle):
    """Slides 3-7: brand header + headline + phone frame."""
    img = slide_canvas(w, h)
    d = ImageDraw.Draw(img)
    div_y = draw_brand_header(d, w, h)

    # Headline
    title_y = div_y + int(h * 0.035)
    title_font = fit_font(d, headline, int(h * 0.045),
                          int(w * 0.9), "black")
    tw, th = text_size(d, headline, title_font)
    d.text(((w - tw) // 2, title_y), headline,
           font=title_font, fill=(255, 255, 255))

    # Subtitle
    sub_y = title_y + th + int(h * 0.012)
    sub_font = font(int(h * 0.022), "regular")
    sw_, sh_ = text_size(d, subtitle, sub_font)
    d.text(((w - sw_) // 2, sub_y),
           subtitle, font=sub_font, fill=(180, 200, 220))

    # Phone-frame area
    phone_top = sub_y + sh_ + int(h * 0.045)
    phone_bottom_pad = int(h * 0.04)
    phone_h = h - phone_top - phone_bottom_pad
    phone_w = int(phone_h * (9 / 18))
    if phone_w > w * 0.78:
        phone_w = int(w * 0.78)
        phone_h = int(phone_w * (18 / 9))
    phone_x = (w - phone_w) // 2

    # Drop shadow
    blur = 50
    shadow = Image.new("RGBA",
                       (phone_w + blur * 4, phone_h + blur * 4),
                       (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        (blur * 2, blur * 2 + 30,
         blur * 2 + phone_w, blur * 2 + phone_h + 30),
        radius=72, fill=(0, 0, 0, 140),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    img.paste(shadow, (phone_x - blur * 2, phone_top - blur * 2),
              shadow)

    framed = render_phone_in_frame(inner_img, phone_w, phone_h)
    img.paste(framed, (phone_x, phone_top), framed)
    return img


# ── Producers ────────────────────────────────────────────────────────────
def make_set(out_w, out_h, prefix):
    inner_w, inner_h = 1080, 1920
    slide_intro(out_w, out_h).save(
        OUT_DIR / f"{prefix}-1-intro.png", "PNG")
    slide_problem(out_w, out_h).save(
        OUT_DIR / f"{prefix}-2-problem.png", "PNG")
    for i, (name, fn, head, sub) in enumerate(FEATURE_SCREENS, start=3):
        inner = fn(inner_w, inner_h).convert("RGB")
        slide_feature(inner, out_w, out_h, head, sub).save(
            OUT_DIR / f"{prefix}-{i}-{name}.png", "PNG")


def make_phone_screens():
    make_set(1080, 1920, "phone")


def make_tablet_7_screens():
    make_set(1200, 1920, "tablet-7")


def make_tablet_10_screens():
    make_set(1800, 2880, "tablet-10")


# ── Run ──────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("Generating Play Store assets...")
    # Wipe stale screenshots so old filenames don't linger.
    for f in OUT_DIR.glob("*.png"):
        f.unlink()
    make_icon()
    print("  + icon-512.png")
    make_feature_graphic()
    print("  + feature-graphic-1024x500.png")
    make_phone_screens()
    print("  + 7 phone screenshots")
    make_tablet_7_screens()
    print("  + 7 tablet-7 screenshots")
    make_tablet_10_screens()
    print("  + 7 tablet-10 screenshots")
    print(f"\nAll assets in: {OUT_DIR}")
