"""Slide layouts and the page shell. Re-exports the house-style kit, so a deck
script imports everything from here."""

import os
import re
import sys

sys.path.insert(0, os.path.expanduser("~/.claude/skills/house-style"))
import palette  # noqa: E402
from kit import *  # noqa: E402,F401,F403
from kit import C, base_css, defs_svg, esc  # noqa: E402


def css():
    return base_css() + """
html, body { height: 100%; overflow: hidden; }
#deck { position: absolute; left: 0; top: 0; width: 1600px; height: 900px; transform-origin: 0 0; }
.slide { position: absolute; inset: 0; display: none; flex-direction: column; padding: 72px;
  background: var(--bg); overflow: hidden; }
.slide.on { display: flex; }
.kicker { font-size: 20px; line-height: 1.6; color: var(--ink); }
h1 { font-size: 60px; font-weight: 600; margin: 12px 0 40px; }
.body { display: flex; gap: 76px; flex: 1; min-height: 0; }
.points { width: 520px; flex: none; list-style: none; margin: 0; padding: 0; font-size: 30px;
  line-height: 1.3; letter-spacing: -.01em; color: var(--fg3); }
.points li { margin-bottom: 30px; }
.fig { flex: 1; min-width: 0; display: flex; align-items: center; justify-content: center; }
.fig svg { width: 100%; height: 100%; }
.center { justify-content: center; }
.statement { font-size: 124px; font-weight: 700; color: var(--fg); line-height: 1.02;
  letter-spacing: -.042em; margin-top: 28px; }
.dim { color: var(--fg4); }
.big { font-size: 184px; font-weight: 700; margin: 28px 0 0; letter-spacing: -.048em;
  line-height: .98; }
.sub { font-size: 36px; color: var(--fg3); margin-top: 40px; letter-spacing: -.012em; }
.flood { background: var(--accent); }
.flood .kicker, .flood .statement, .flood .num { color: var(--on); }
.flood .kicker, .flood .num { opacity: .7; }
.flood .dim { color: var(--on); opacity: .5; }
.flood .statement { font-size: 150px; }
.num { position: absolute; right: 72px; bottom: 30px; font-size: 16px; color: var(--fg4);
  font-variant-numeric: tabular-nums; }
.strip { position: absolute; left: 0; right: 0; bottom: 0; height: 18px; display: flex; }
.strip i { flex: 1; }
.minimap { position: absolute; right: 72px; top: 80px; display: flex; flex-direction: column;
  gap: 5px; }
.minimap i { width: 84px; height: 10px; border-radius: 3px; background: var(--bg4); }
.minimap i.on { background: var(--accent); }
"""


JS = """
const S = [...document.querySelectorAll('.slide')];
let i = 0;
function show(n) {
  i = Math.max(0, Math.min(S.length - 1, n));
  S.forEach((s, k) => s.classList.toggle('on', k === i));
  history.replaceState(null, '', '#' + (i + 1));
}
function fit() {
  const k = Math.min(innerWidth / 1600, innerHeight / 900);
  document.getElementById('deck').style.transform =
    `translate(${(innerWidth - 1600 * k) / 2}px, ${(innerHeight - 900 * k) / 2}px) scale(${k})`;
}
addEventListener('keydown', e => {
  if (['ArrowRight', 'ArrowDown', 'PageDown', ' '].includes(e.key)) show(i + 1);
  if (['ArrowLeft', 'ArrowUp', 'PageUp'].includes(e.key)) show(i - 1);
  if (e.key === 'Home') show(0);
  if (e.key === 'End') show(S.length - 1);
});
addEventListener('click', e => show(i + (e.clientX > innerWidth / 3 ? 1 : -1)));
addEventListener('resize', fit);
addEventListener('hashchange', () => show((+location.hash.slice(1) || 1) - 1));
fit();
show((+location.hash.slice(1) || 1) - 1);
"""


def inline(s):
    """Escapes `s`, then renders `code`, **bold**, ==gradient==, ~~dim~~, and
    line breaks."""
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", esc(s))
    s = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", s)
    s = re.sub(r"==([^=]+)==", r'<span class="grad">\1</span>', s)
    return re.sub(r"~~([^~]+)~~", r'<span class="dim">\1</span>', s).replace(
        "\n", "<br>"
    )


def hue(s, *accents):
    """Words in a concept's gradient, or in one that runs through several
    accents, for a statement passed with raw=True."""
    stops = (
        [C[a] for a in accents]
        if len(accents) > 1
        else [C[accents[0]], C[accents[0] + "_blend"]]
    )
    return (
        f'<span class="grad" style="--grad: linear-gradient(90deg, {", ".join(stops)})">'
        f"{esc(s)}</span>"
    )


def dim(s):
    """The quiet half of a two-tone statement passed with raw=True."""
    return f'<span class="dim">{esc(s)}</span>'


def _open(color, cls=""):
    return (
        f'<section class="slide {cls}" style="--accent: {C[color]}; '
        f'--accent-blend: {C[color + "_blend"]}; --on: {C[palette.on_solid(C, color)]}; '
        f'--ink: {C[palette.ink(C, color, large=True)]}">'
    )


def slide(fig, kicker=None, title=None, points=None, color="accent", minimap=None):
    """A figure. With a title it sits under a kicker and the claim. With
    points it sits beside them. With neither it has the whole slide.
    `minimap` is (layers, lit layer) and locates the slide in the
    architecture."""
    head = pts = mm = ""
    if title:
        assert len(title) <= 44, title
        head = f'<div class="kicker">{esc(kicker)}</div><h1>{esc(title)}</h1>'
    if points:
        assert 2 <= len(points) <= 3, title
        pts = (
            '<ul class="points">'
            + "".join(f"<li>{inline(p)}</li>" for p in points)
            + "</ul>"
        )
    if minimap:
        n, on = minimap
        mm = (
            '<div class="minimap">'
            + "".join(f'<i class="{"on" if k == on else ""}"></i>' for k in range(n))
            + "</div>"
        )
    return f'{_open(color)}{head}{mm}<div class="body">{pts}<div class="fig">{fig}</div></div>'


def statement(s, kicker, color="accent", raw=False):
    """One sentence alone on black: the question or the answer."""
    return (
        f'{_open(color, "center")}<div class="kicker">{esc(kicker)}</div>'
        f'<div class="statement">{s if raw else inline(s)}</div>'
    )


def flood(s, kicker, color="accent", raw=False):
    """One sentence on a slide filled with a concept's color: the idea, or
    the start of a section."""
    return (
        f'{_open(color, "center flood")}<div class="kicker">{esc(kicker)}</div>'
        f'<div class="statement">{s if raw else inline(s)}</div>'
    )


def title_slide(title, sub, kicker, color="accent", strip=(), raw=False):
    """Opens or closes the deck. `strip` names the accents of the color band
    along the bottom edge."""
    band = (
        (
            '<div class="strip">'
            + "".join(f'<i style="background: {C[a]}"></i>' for a in strip)
            + "</div>"
        )
        if strip
        else ""
    )
    return (
        f'{_open(color, "center")}<div class="kicker">{esc(kicker)}</div>'
        f'<h1 class="big">{title if raw else inline(title)}</h1>'
        f'<div class="sub">{esc(sub)}</div>{band}'
    )


def page(slides, title):
    body = "".join(
        f'{s}<div class="num">{k + 1}</div></section>' for k, s in enumerate(slides)
    )
    return (
        f'<!doctype html><html lang="en"><head><meta charset="utf-8"><title>{esc(title)}</title>'
        f'<style>{css()}</style></head><body><div id="deck">{body}</div>{defs_svg()}'
        f"<script>{JS}</script></body></html>"
    )
