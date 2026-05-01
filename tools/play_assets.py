"""
Generates Play Store visual assets for Wardly:
  - icon-512.png            (512x512, app icon)
  - feature-graphic-1024x500.png
  - phone-1..5.png          (1080x1920, phone screenshots)
  - tablet-7-1..3.png       (1200x1920, 7-inch tablet)
  - tablet-10-1..3.png      (1800x2880, 10-inch tablet)

All output drops into ../play-assets/ relative to this script.

Mocks recreate the actual Wardly UI (5-digit ward codes, priority pills,
acknowledged-comment bubbles, ward chips) using brand colours so the
Play Store listing matches what users see in the app.
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path
import platform
import os

# ── Brand palette ─────────────────────────────────────────────────────────
PRIMARY = (10, 92, 138)        # dark blue
PRIMARY_2 = (14, 122, 184)
ACCENT = (0, 200, 150)         # green
DANGER = (216, 59, 59)
SURFACE = (245, 247, 251)
CARD = (255, 255, 255)
DIVIDER = (227, 232, 240)
TEXT_PRIMARY = (28, 35, 51)
TEXT_SECONDARY = (108, 122, 142)
TEXT_TERTIARY = (165, 175, 188)
WARM_AMBER = (229, 127, 0)

OUT_DIR = Path(__file__).resolve().parent.parent / "play-assets"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# ── Font loader ───────────────────────────────────────────────────────────
def find_font(weight: str = "regular") -> str:
    """Best-effort hunt for a clean sans font on Windows / Mac / Linux."""
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
    """Returns the RGB you'd see drawing rgb at `alpha` (0-255) over white.
    We're rendering on RGB images, so alpha gets thrown away by Pillow —
    we have to mix manually instead of passing (*color, alpha).
    """
    return tuple(int(c + (255 - c) * (1 - alpha / 255)) for c in rgb)


def rounded(draw: ImageDraw.ImageDraw, xy, r, fill=None, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=r, fill=fill, outline=outline, width=width)


def text_size(draw, text, fnt):
    bbox = draw.textbbox((0, 0), text, font=fnt)
    return bbox[2] - bbox[0], bbox[3] - bbox[1]


def text_centered(draw, xy, w, h, text, fnt, fill):
    tw, th = text_size(draw, text, fnt)
    draw.text((xy[0] + (w - tw) / 2, xy[1] + (h - th) / 2 - 1),
              text, font=fnt, fill=fill)


def shadow(size, radius=12, opacity=60):
    """Returns a soft drop-shadow PIL Image of the given size."""
    sw, sh = size
    img = Image.new("RGBA", (sw + radius * 4, sh + radius * 4),
                    (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(
        (radius * 2, radius * 2,
         radius * 2 + sw, radius * 2 + sh),
        radius=18, fill=(0, 0, 0, opacity),
    )
    return img.filter(ImageFilter.GaussianBlur(radius))


# ── Icon: 512x512 ─────────────────────────────────────────────────────────
def make_icon():
    SIZE = 512
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Rounded background with vertical gradient.
    grad = Image.new("RGBA", (SIZE, SIZE))
    gd = ImageDraw.Draw(grad)
    for y in range(SIZE):
        t = y / SIZE
        r = int(PRIMARY[0] * (1 - t) + PRIMARY_2[0] * t)
        g = int(PRIMARY[1] * (1 - t) + PRIMARY_2[1] * t)
        b = int(PRIMARY[2] * (1 - t) + PRIMARY_2[2] * t)
        gd.line([(0, y), (SIZE, y)], fill=(r, g, b, 255))
    mask = Image.new("L", (SIZE, SIZE), 0)
    mk = ImageDraw.Draw(mask)
    mk.rounded_rectangle((0, 0, SIZE, SIZE), radius=110, fill=255)
    img.paste(grad, (0, 0), mask)

    # Letter W
    w_font = font(360, "black")
    d = ImageDraw.Draw(img)
    tw, th = text_size(d, "W", w_font)
    d.text(((SIZE - tw) / 2, (SIZE - th) / 2 - 30),
           "W", font=w_font, fill=(255, 255, 255, 255))

    # Subtle accent dot at the bottom
    dot = 22
    cx = SIZE // 2
    d.ellipse((cx - dot, SIZE - 110 - dot,
               cx + dot, SIZE - 110 + dot),
              fill=ACCENT)

    img.save(OUT_DIR / "icon-512.png", "PNG")


# ── Feature graphic: 1024x500 ─────────────────────────────────────────────
def make_feature_graphic():
    W, H = 1024, 500
    img = Image.new("RGB", (W, H), PRIMARY)
    d = ImageDraw.Draw(img)

    # Soft accent glow on the right
    glow = Image.new("RGB", (W, H), PRIMARY)
    gd = ImageDraw.Draw(glow)
    for r in range(220, 0, -8):
        gd.ellipse((W - 250 - r, H // 2 - r,
                    W - 250 + r, H // 2 + r),
                   fill=(int(PRIMARY[0] + 12),
                         int(PRIMARY[1] + 12),
                         int(PRIMARY[2] + 14)))
    blurred = glow.filter(ImageFilter.GaussianBlur(60))
    img.paste(blurred, (0, 0))
    d = ImageDraw.Draw(img)

    # Logo block on the left
    logo_size = 120
    logo_x, logo_y = 80, (H - logo_size) // 2 - 70
    rounded(d, (logo_x, logo_y, logo_x + logo_size, logo_y + logo_size),
            r=24, fill=(255, 255, 255))
    text_centered(d, (logo_x, logo_y), logo_size, logo_size,
                  "W", font(86, "black"), PRIMARY)

    # Brand name
    d.text((logo_x + logo_size + 28, logo_y + 12),
           "WARDLY", font=font(58, "black"),
           fill=(255, 255, 255))
    d.text((logo_x + logo_size + 30, logo_y + 80),
           "Ward, connected.",
           font=font(26, "regular"),
           fill=(220, 232, 246))

    # Tagline below
    d.text((80, H - 170),
           "One live feed for the whole ward team.",
           font=font(36, "bold"),
           fill=(255, 255, 255))
    d.text((80, H - 120),
           "Real-time clinical notes. Acknowledged on the record.",
           font=font(22, "regular"),
           fill=(200, 215, 232))

    # A small mock note card on the right
    cx, cy, cw, ch = W - 360, H // 2 - 110, 290, 220
    rounded(d, (cx, cy, cx + cw, cy + ch), r=18,
            fill=CARD)
    # Priority pill
    rounded(d, (cx + 16, cy + 16, cx + 100, cy + 44), r=8,
            fill=(255, 235, 235))
    d.ellipse((cx + 24, cy + 24, cx + 36, cy + 36),
              fill=DANGER)
    d.text((cx + 42, cy + 22), "Urgent", font=font(13, "bold"),
           fill=DANGER)
    # Author
    d.text((cx + 110, cy + 24), "Bed 12 · R. Kumar",
           font=font(13, "regular"), fill=TEXT_SECONDARY)
    # Note body
    d.text((cx + 16, cy + 60),
           "BP dropping — please review.\nStarted fluids, awaiting\ncardiology callback.",
           font=font(15, "regular"),
           fill=TEXT_PRIMARY, spacing=6)
    # Footer + ack stripe
    d.text((cx + 16, cy + 158), "Dr. Pew Pew · 2 min ago",
           font=font(11, "regular"), fill=TEXT_SECONDARY)
    rounded(d, (cx + 16, cy + 184, cx + cw - 16, cy + 200), r=4,
            fill=tint(ACCENT, 60))
    d.text((cx + 22, cy + 184), "✓ Acknowledged by Sunil",
           font=font(11, "bold"), fill=ACCENT)

    img.save(OUT_DIR / "feature-graphic-1024x500.png", "PNG")


# ── Phone-frame helper for screenshots ───────────────────────────────────
def phone_frame(width, height, content_drawer):
    """
    Draws a phone-style screenshot at width x height, calling
    content_drawer(d, x, y, w, h) for the inner UI area.
    Returns a PIL Image.
    """
    img = Image.new("RGB", (width, height), SURFACE)
    d = ImageDraw.Draw(img)

    # Status bar
    sb = max(60, height // 32)
    d.rectangle((0, 0, width, sb), fill=PRIMARY)
    d.text((width // 2 - 36, sb // 2 - 12), "9:41",
           font=font(int(sb * 0.4), "semibold"),
           fill=(255, 255, 255))
    # Battery + signal as little bars on the right
    for i, w in enumerate([6, 8, 10, 12]):
        d.rectangle((width - 160 + i * 14, sb // 2 + 4 - w,
                     width - 160 + i * 14 + 8, sb // 2 + 4),
                    fill=(255, 255, 255))
    rounded(d, (width - 90, sb // 2 - 8, width - 30, sb // 2 + 8),
            r=4, fill=(255, 255, 255))

    # App bar
    ab_h = max(110, height // 18)
    d.rectangle((0, sb, width, sb + ab_h), fill=PRIMARY)

    # Bottom nav
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
        # tiny dot icon
        r = 9
        d.ellipse((cx - r, bn_y + bn_h // 2 - r - 18,
                   cx + r, bn_y + bn_h // 2 + r - 18), fill=clr)
        # label
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


# ── Phone screenshot 1: Ward feed (Notes tab) ─────────────────────────────
def screen_ward_feed(width, height):
    def content(d, x, y, w, h, img):
        # Title
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
            # priority pill
            rounded(d, (cx + 22, cy + 22, cx + 150, cy + 60),
                    r=10, fill=tint(prio_clr, 30))
            d.ellipse((cx + 32, cy + 32, cx + 50, cy + 50),
                      fill=prio_clr)
            d.text((cx + 60, cy + 28), prio,
                   font=font(18, "bold"), fill=prio_clr)
            d.text((cx + 170, cy + 30), who,
                   font=font(18, "regular"), fill=TEXT_SECONDARY)
            # body (wrap manually)
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

    img, sb, ab_h, bn_h = phone_frame(width, height, content)
    d = ImageDraw.Draw(img)
    draw_appbar_title(d, sb, ab_h, width, "Wardly", badge="3 unack")
    draw_bottom_nav(d, width, height, bn_h, 3,
                    ["Home", "Wards", "Patients", "Notes", "Profile"])
    return img


# ── Phone screenshot 2: Wards screen (5-digit codes) ──────────────────────
def screen_wards(width, height):
    def content(d, x, y, w, h, img):
        d.text((40, y + 24), "My wards",
               font=font(28, "bold"), fill=TEXT_PRIMARY)
        d.text((40, y + 64),
               "Tap a 5-digit code to copy and share with your team.",
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
            # icon
            rounded(d, (cx + 24, cy + 24, cx + 90, cy + 90),
                    r=14, fill=(220, 235, 250))
            d.text((cx + 38, cy + 32), "🏥",
                   font=font(36, "regular"))
            # name
            d.text((cx + 110, cy + 28), name,
                   font=font(26, "bold"), fill=TEXT_PRIMARY)
            d.text((cx + 110, cy + 64), floor,
                   font=font(18, "regular"), fill=TEXT_SECONDARY)
            if is_owner:
                rounded(d, (cx + cw - 220, cy + 28,
                            cx + cw - 24, cy + 68), r=10,
                        fill=tint(ACCENT, 36))
                d.text((cx + cw - 210, cy + 36), "OWNED BY YOU",
                       font=font(14, "bold"), fill=ACCENT)
            d.text((cx + 24, cy + 110),
                   f"Owned by {owner_name}",
                   font=font(20, "regular"), fill=TEXT_PRIMARY)
            # code chip
            rounded(d, (cx + 24, cy + 150, cx + cw - 24, cy + 220),
                    r=14, fill=SURFACE, outline=DIVIDER, width=2)
            d.text((cx + 40, cy + 168), f"Code: {code}",
                   font=font(28, "bold"), fill=TEXT_PRIMARY)
            d.text((cx + cw - 130, cy + 178), "tap to copy",
                   font=font(16, "regular"), fill=TEXT_SECONDARY)
            cy += ch + 30

        # Bottom buttons
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

    img, sb, ab_h, bn_h = phone_frame(width, height, content)
    d = ImageDraw.Draw(img)
    draw_appbar_title(d, sb, ab_h, width, "Wards")
    draw_bottom_nav(d, width, height, bn_h, 1,
                    ["Home", "Wards", "Patients", "Notes", "Profile"])
    return img


# ── Phone screenshot 3: Patients with search highlight ───────────────────
def screen_patients(width, height):
    def content(d, x, y, w, h, img):
        # Search bar
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
            # avatar
            rounded(d, (cx + 24, cy + 30, cx + 124, cy + 130),
                    r=50, fill=(220, 235, 250))
            text_centered(d, (cx + 24, cy + 30), 100, 100,
                          initials, font(36, "bold"), PRIMARY)
            # name with highlighted match (we just bold the whole name in mock)
            # split into prefix + match + suffix
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
                # highlighted span with background
                mw, _ = text_size(d, match, fnt)
                rounded(d, (tx + pw - 4, ty - 4,
                            tx + pw + mw + 6, ty + 38),
                        r=6, fill=tint(PRIMARY, 40))
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
            # status pill
            rounded(d, (cx + 144, cy + 170, cx + 250, cy + 200),
                    r=8, fill=tint(ACCENT, 36))
            d.text((cx + 156, cy + 174), "Active",
                   font=font(15, "bold"), fill=ACCENT)
            cy += ch + 24

    img, sb, ab_h, bn_h = phone_frame(width, height, content)
    d = ImageDraw.Draw(img)
    draw_appbar_title(d, sb, ab_h, width, "Patients")
    draw_bottom_nav(d, width, height, bn_h, 2,
                    ["Home", "Wards", "Patients", "Notes", "Profile"])
    return img


# ── Phone screenshot 4: Comment thread with acknowledgement ─────────────
def screen_thread(width, height):
    def content(d, x, y, w, h, img):
        # Original note
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

        # Reply 1 — acknowledgement
        cy += ch + 30
        cx, cw, ch = 30, w - 60, 200
        rounded(d, (cx, cy, cx + cw, cy + ch), r=22,
                fill=(245, 254, 251), outline=ACCENT, width=3)
        # avatar
        rounded(d, (cx + 22, cy + 22, cx + 70, cy + 70),
                r=24, fill=(220, 246, 240))
        d.text((cx + 30, cy + 32), "SM",
               font=font(20, "bold"), fill=ACCENT)
        d.text((cx + 80, cy + 22), "Sunil Mulgund",
               font=font(22, "bold"), fill=TEXT_PRIMARY)
        rounded(d, (cx + 270, cy + 24, cx + 360, cy + 54),
                r=8, fill=tint(PRIMARY, 30))
        d.text((cx + 282, cy + 28), "Doctor",
               font=font(15, "bold"), fill=PRIMARY)
        # ack banner
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

        # Reply box
        cy = h + y - 110
        rounded(d, (30, cy, w - 200, cy + 80), r=18,
                fill=SURFACE, outline=DIVIDER, width=2)
        d.text((54, cy + 26), "Write a reply…",
               font=font(20, "regular"), fill=TEXT_SECONDARY)
        # ack button
        rounded(d, (w - 180, cy, w - 105, cy + 80),
                r=18, fill=tint(ACCENT, 50))
        d.ellipse((w - 162, cy + 14, w - 122, cy + 54),
                  outline=ACCENT, width=4)
        d.line([(w - 153, cy + 36), (w - 144, cy + 45),
                (w - 130, cy + 25)], fill=ACCENT, width=4)
        # send button
        rounded(d, (w - 90, cy, w - 30, cy + 80),
                r=18, fill=PRIMARY)
        d.polygon([(w - 70, cy + 24), (w - 50, cy + 40),
                   (w - 70, cy + 56)], fill=(255, 255, 255))

    img, sb, ab_h, bn_h = phone_frame(width, height, content)
    d = ImageDraw.Draw(img)
    draw_appbar_title(d, sb, ab_h, width, "Thread")
    draw_bottom_nav(d, width, height, bn_h, 3,
                    ["Home", "Wards", "Patients", "Notes", "Profile"])
    return img


# ── Phone screenshot 5: Profile / settings ───────────────────────────────
def screen_profile(width, height):
    def content(d, x, y, w, h, img):
        # Avatar header
        cy = y + 30
        rounded(d, (30, cy, w - 30, cy + 280), r=22,
                fill=CARD, outline=DIVIDER, width=2)
        # avatar circle
        d.ellipse((w // 2 - 70, cy + 30, w // 2 + 70, cy + 170),
                  fill=(220, 235, 250))
        text_centered(d, (w // 2 - 70, cy + 30), 140, 140,
                      "SM", font(60, "black"), PRIMARY)
        text_centered(d, (0, cy + 180), w, 40,
                      "Sunil Mulgund", font(28, "bold"),
                      TEXT_PRIMARY)
        text_centered(d, (0, cy + 226), w, 30,
                      "Cardiologist", font(20, "bold"),
                      PRIMARY)

        # Tile list
        cy += 320
        rows = [
            ("✏", "Edit profile", "Update name and specialty"),
            ("🔔", "Notification setup", "Re-run the reliability wizard"),
            ("❓", "Help & FAQs", "Quick answers to the basics"),
            ("⭐", "Rate on Play Store", "Help other ward teams find Wardly"),
            ("🐞", "Report a bug", "Auto-fills version + platform"),
        ]
        rounded(d, (30, cy, w - 30, cy + len(rows) * 110),
                r=22, fill=CARD, outline=DIVIDER, width=2)
        for i, (ico, t, sub) in enumerate(rows):
            ry = cy + i * 110
            d.text((48, ry + 38), ico, font=font(28, "regular"))
            d.text((110, ry + 22), t,
                   font=font(22, "bold"), fill=TEXT_PRIMARY)
            d.text((110, ry + 56), sub,
                   font=font(18, "regular"), fill=TEXT_SECONDARY)
            d.text((w - 70, ry + 38), "›",
                   font=font(36, "bold"), fill=TEXT_TERTIARY)
            if i < len(rows) - 1:
                d.line([(110, ry + 109),
                        (w - 30, ry + 109)],
                       fill=DIVIDER, width=2)

    img, sb, ab_h, bn_h = phone_frame(width, height, content)
    d = ImageDraw.Draw(img)
    draw_appbar_title(d, sb, ab_h, width, "Profile")
    draw_bottom_nav(d, width, height, bn_h, 4,
                    ["Home", "Wards", "Patients", "Notes", "Profile"])
    return img


SCREENS = [
    # (name, render_fn, headline, subtitle, background_color)
    ("ward-feed", screen_ward_feed,
     "Real-time ward feed",
     "Every note. Live. To the whole team.",
     PRIMARY),
    ("wards", screen_wards,
     "5-digit ward codes",
     "Share a code, your team is in.",
     (44, 122, 92)),  # deep green
    ("patients", screen_patients,
     "Search across every ward",
     "Find any patient in one tap.",
     (138, 60, 100)),  # plum
    ("thread", screen_thread,
     "Acknowledged, on the record",
     "See who handled what, when.",
     (200, 90, 50)),  # warm orange
    ("profile", screen_profile,
     "Built for ward teams",
     "Your data. Your rules. Ward-private.",
     (60, 70, 110)),  # slate
]


def render_phone_in_frame(inner_img, frame_w, frame_h, corner_r=72,
                          bezel=18, frame_color=(20, 25, 40)):
    """
    Wraps an inner-UI image in a phone-style device frame: dark rounded
    bezel, screen inside with rounded corners, small notch on top.
    Returns an RGBA image of size (frame_w, frame_h).
    """
    img = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Outer phone body
    d.rounded_rectangle((0, 0, frame_w, frame_h),
                        radius=corner_r, fill=frame_color)

    # Inner screen area
    sx = bezel
    sy = bezel
    sw = frame_w - bezel * 2
    sh = frame_h - bezel * 2
    inner_resized = inner_img.resize((sw, sh), Image.LANCZOS)

    # Mask the inner content to rounded corners.
    mask = Image.new("L", (sw, sh), 0)
    mk = ImageDraw.Draw(mask)
    mk.rounded_rectangle((0, 0, sw, sh),
                         radius=corner_r - bezel, fill=255)
    img.paste(inner_resized, (sx, sy), mask)

    # Notch (a small pill at the top center of the screen)
    notch_w = int(frame_w * 0.28)
    notch_h = int(frame_h * 0.025)
    nx = (frame_w - notch_w) // 2
    ny = bezel + 8
    d.rounded_rectangle((nx, ny, nx + notch_w, ny + notch_h),
                        radius=notch_h // 2,
                        fill=(0, 0, 0))
    return img


def marketing_wrap(inner_img, canvas_w, canvas_h,
                   headline, subtitle, bg_color):
    """
    Lays out a Play-Store-style marketing screenshot:
    - Colored background
    - Headline + subtitle at the top
    - Phone frame containing the inner UI below

    The phone is sized so ~88% of its height fits in the canvas, leaving
    space for the title block above.
    """
    # Canvas with a soft vertical gradient (top brighter than bottom)
    canvas = Image.new("RGB", (canvas_w, canvas_h), bg_color)
    cd = ImageDraw.Draw(canvas)
    for y in range(canvas_h):
        t = y / canvas_h
        r = int(bg_color[0] * (1 - 0.18 * t))
        g = int(bg_color[1] * (1 - 0.18 * t))
        b = int(bg_color[2] * (1 - 0.18 * t))
        cd.line([(0, y), (canvas_w, y)], fill=(r, g, b))

    # Title block sizing
    title_pad_top = int(canvas_h * 0.07)
    title_size = int(canvas_h * 0.045)
    sub_size = int(canvas_h * 0.022)

    cd = ImageDraw.Draw(canvas)

    # Auto-shrink headline to fit within 92% of canvas width — keeps the
    # longest headlines (e.g. "Acknowledged, on the record") from
    # spilling past the edges at 1080px.
    max_title_w = int(canvas_w * 0.92)
    cur_size = title_size
    while cur_size > 18:
        title_font = font(cur_size, "black")
        tw, _ = text_size(cd, headline, title_font)
        if tw <= max_title_w:
            break
        cur_size -= 4
    title_font = font(cur_size, "black")
    sub_font = font(sub_size, "regular")

    # Manual centred draw
    def centred(text, fnt, y, color):
        tw, th = text_size(cd, text, fnt)
        cd.text(((canvas_w - tw) / 2, y), text, font=fnt, fill=color)
        return th

    th = centred(headline, title_font, title_pad_top, (255, 255, 255))
    sub_y = title_pad_top + th + int(canvas_h * 0.012)
    centred(subtitle, sub_font, sub_y, (255, 255, 255, 200))

    # Phone frame area — leave ~75% of canvas for the device, vertically
    # centred under the title.
    phone_top = sub_y + int(canvas_h * 0.07)
    phone_bottom_pad = int(canvas_h * 0.04)
    phone_h = canvas_h - phone_top - phone_bottom_pad
    # Keep the phone aspect ratio (~9:18) — width follows from height.
    phone_w = int(phone_h * (9 / 18))
    if phone_w > canvas_w * 0.85:
        phone_w = int(canvas_w * 0.85)
        phone_h = int(phone_w * (18 / 9))

    phone_x = (canvas_w - phone_w) // 2
    phone_y = phone_top

    # Soft drop shadow under the phone
    shadow_blur = 40
    shadow_img = Image.new("RGBA",
                           (phone_w + shadow_blur * 4,
                            phone_h + shadow_blur * 4),
                           (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow_img)
    sd.rounded_rectangle(
        (shadow_blur * 2, shadow_blur * 2 + 30,
         shadow_blur * 2 + phone_w, shadow_blur * 2 + phone_h + 30),
        radius=72, fill=(0, 0, 0, 120),
    )
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(shadow_blur))
    canvas.paste(shadow_img,
                 (phone_x - shadow_blur * 2,
                  phone_y - shadow_blur * 2),
                 shadow_img)

    framed = render_phone_in_frame(inner_img, phone_w, phone_h)
    canvas.paste(framed, (phone_x, phone_y), framed)
    return canvas


def make_phone_screens():
    W, H = 1080, 1920
    # The inner UI screen renders at the same shape so the resize inside
    # the frame is minimal — keeps text crisp.
    inner_w, inner_h = 1080, 1920
    for i, (name, fn, head, sub, bg) in enumerate(SCREENS, start=1):
        inner = fn(inner_w, inner_h).convert("RGB")
        out = marketing_wrap(inner, W, H, head, sub, bg)
        out.save(OUT_DIR / f"phone-{i}-{name}.png", "PNG")


def make_tablet_7_screens():
    W, H = 1200, 1920
    inner_w, inner_h = 1080, 1920
    for i, (name, fn, head, sub, bg) in enumerate(SCREENS[:3], start=1):
        inner = fn(inner_w, inner_h).convert("RGB")
        out = marketing_wrap(inner, W, H, head, sub, bg)
        out.save(OUT_DIR / f"tablet-7-{i}-{name}.png", "PNG")


def make_tablet_10_screens():
    W, H = 1800, 2880
    inner_w, inner_h = 1080, 1920
    for i, (name, fn, head, sub, bg) in enumerate(SCREENS[:3], start=1):
        inner = fn(inner_w, inner_h).convert("RGB")
        out = marketing_wrap(inner, W, H, head, sub, bg)
        out.save(OUT_DIR / f"tablet-10-{i}-{name}.png", "PNG")


# ── Run ──────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("→ Generating Play Store assets…")
    make_icon()
    print("  ✓ icon-512.png")
    make_feature_graphic()
    print("  ✓ feature-graphic-1024x500.png")
    make_phone_screens()
    print("  ✓ 5 phone screenshots")
    make_tablet_7_screens()
    print("  ✓ 3 7-inch tablet screenshots")
    make_tablet_10_screens()
    print("  ✓ 3 10-inch tablet screenshots")
    print(f"\nAll assets in: {OUT_DIR}")
