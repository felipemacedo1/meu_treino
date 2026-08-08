#!/usr/bin/env python3
"""
Gera os ícones do aplicativo na identidade Neon Orange.

Desenha um raio escuro sobre gradiente laranja, o mesmo símbolo usado na tela
de login. Roda com Pillow, sem depender de ferramenta de design.

Uso: python3 scripts/generate_icons.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ANDROID_RES = ROOT / "app/android/app/src/main/res"
WEB = ROOT / "app/web"

PRIMARY = (255, 106, 0)       # #FF6A00
PRIMARY_VARIANT = (255, 158, 44)  # #FF9E2C
INK = (18, 6, 0)              # conteúdo sobre o laranja
SS = 4                        # supersampling

# Raio, em coordenadas normalizadas (0..1).
BOLT = [
    (0.60, 0.05),
    (0.27, 0.55),
    (0.46, 0.55),
    (0.40, 0.95),
    (0.75, 0.44),
    (0.55, 0.44),
]

ANDROID_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def gradient(size: int) -> Image.Image:
    """Gradiente diagonal laranja -> âmbar."""
    image = Image.new("RGB", (size, size))
    pixels = image.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            pixels[x, y] = (
                round(PRIMARY[0] + (PRIMARY_VARIANT[0] - PRIMARY[0]) * t),
                round(PRIMARY[1] + (PRIMARY_VARIANT[1] - PRIMARY[1]) * t),
                round(PRIMARY[2] + (PRIMARY_VARIANT[2] - PRIMARY[2]) * t),
            )
    return image


def icon(size: int, radius_factor: float = 0.22, content_scale: float = 1.0) -> Image.Image:
    """Ícone quadrado com cantos arredondados e o raio ao centro."""
    big = size * SS
    base = gradient(big).convert("RGBA")

    # máscara de cantos arredondados (0 = quadrado cheio, para maskable)
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, big - 1, big - 1],
        radius=int(big * radius_factor),
        fill=255,
    )
    base.putalpha(mask)

    # raio centralizado, com margem quando o ícone é "maskable"
    inset = (1 - content_scale) / 2
    points = [
        (
            (inset + x * content_scale) * big,
            (inset + y * content_scale) * big,
        )
        for x, y in BOLT
    ]
    ImageDraw.Draw(base).polygon(points, fill=INK + (255,))

    return base.resize((size, size), Image.LANCZOS)


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, "PNG")
    print(f"  {path.relative_to(ROOT)} ({image.width}x{image.height})")


def main() -> None:
    print("Android:")
    for folder, size in ANDROID_SIZES.items():
        save(icon(size), ANDROID_RES / folder / "ic_launcher.png")

    print("Web / PWA:")
    save(icon(192), WEB / "icons/Icon-192.png")
    save(icon(512), WEB / "icons/Icon-512.png")
    # maskable: sem cantos arredondados e com o conteúdo na área segura
    save(icon(192, radius_factor=0, content_scale=0.68), WEB / "icons/Icon-maskable-192.png")
    save(icon(512, radius_factor=0, content_scale=0.68), WEB / "icons/Icon-maskable-512.png")
    save(icon(64), WEB / "favicon.png")

    print("OK")


if __name__ == "__main__":
    main()
