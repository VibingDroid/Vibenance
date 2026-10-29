#!/usr/bin/env python3
"""Apply the Vibenance iconset from the extracted favicon package."""
import os
import shutil
from pathlib import Path

try:
    import cairosvg
    from PIL import Image
except ImportError as e:
    raise SystemExit(f"Missing dependency: {e}. Install cairosvg and pillow.") from e

REPO = Path('/opt/data/Vibenance')
ZIP_DIR = Path('/opt/data/cache/scratch/favicon_pkg')
LOGO_SVG = ZIP_DIR / 'favicon.svg'


def render_svg(svg_path: Path, out_path: Path, size: int) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cairosvg.svg2png(
        url=str(svg_path),
        write_to=str(out_path),
        output_width=size,
        output_height=size,
    )


def render_svg_into_canvas(svg_path: Path, out_path: Path, canvas_size: int, content_scale: float = 0.8) -> None:
    content_size = int(round(canvas_size * content_scale))
    tmp = out_path.with_suffix('.tmp.png')
    render_svg(svg_path, tmp, content_size)
    fg = Image.open(tmp).convert('RGBA')
    canvas = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    offset = (canvas_size - content_size) // 2
    canvas.paste(fg, (offset, offset), fg)
    canvas.save(out_path)
    tmp.unlink()


def main() -> None:
    # Web / brand copies
    shutil.copy(LOGO_SVG, REPO / 'assets/images/logo.svg')
    shutil.copy(LOGO_SVG, REPO / 'web/favicon.svg')
    shutil.copy(ZIP_DIR / 'favicon.ico', REPO / 'web/favicon.ico')
    shutil.copy(ZIP_DIR / 'favicon-32x32.png', REPO / 'web/favicon.png')
    shutil.copy(ZIP_DIR / 'apple-touch-icon.png', REPO / 'web/apple-touch-icon.png')
    print('SVG/web copies done')

    # Standalone full-logo PNGs
    render_svg(LOGO_SVG, REPO / 'assets/images/logo.png', 1024)
    render_svg(LOGO_SVG, REPO / '.playstore/app_logo.png', 512)
    render_svg(LOGO_SVG, REPO / 'fastlane/metadata/android/en-US/images/icon.png', 512)

    # Web icons
    render_svg(LOGO_SVG, REPO / 'web/icons/Icon-192.png', 192)
    render_svg(LOGO_SVG, REPO / 'web/icons/Icon-512.png', 512)
    render_svg_into_canvas(LOGO_SVG, REPO / 'web/icons/Icon-maskable-192.png', 192, 0.80)
    render_svg_into_canvas(LOGO_SVG, REPO / 'web/icons/Icon-maskable-512.png', 512, 0.80)
    print('Standalone icons rendered')

    # Android adaptive foreground: bars only on transparent background
    bars_svg = REPO / 'assets/images/ic_launcher_foreground.svg'
    bars_svg.write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000" width="100%" height="100%">\n'
        '  <g fill="#FFFFFF">\n'
        '    <rect x="212" y="383.5" width="127" height="233" rx="63.5" />\n'
        '    <rect x="403" y="299" width="127" height="402" rx="63.5" />\n'
        '    <rect x="593.5" y="214" width="127" height="572" rx="63.5" />\n'
        '  </g>\n'
        '</svg>\n'
    )

    densities = {
        'mdpi': (48, 108),
        'hdpi': (72, 162),
        'xhdpi': (96, 216),
        'xxhdpi': (144, 324),
        'xxxhdpi': (192, 432),
    }

    for density, (launcher_sz, canvas_sz) in densities.items():
        mipmap = REPO / f'android/app/src/main/res/mipmap-{density}'
        mipmap.mkdir(parents=True, exist_ok=True)

        render_svg(LOGO_SVG, mipmap / 'ic_launcher.png', launcher_sz)
        render_svg(LOGO_SVG, mipmap / 'ic_launcher_round.png', launcher_sz)

        # Adaptive foreground (~66% safe zone)
        content_sz = int(round(canvas_sz * 0.66))
        tmp_fg = mipmap / 'fg.tmp.png'
        render_svg(bars_svg, tmp_fg, content_sz)
        fg = Image.open(tmp_fg).convert('RGBA')
        canvas = Image.new('RGBA', (canvas_sz, canvas_sz), (0, 0, 0, 0))
        offset = (canvas_sz - content_sz) // 2
        canvas.paste(fg, (offset, offset), fg)
        canvas.save(mipmap / 'ic_launcher_foreground.png')

        # Monochrome: same geometry, grayscale with alpha
        mono = canvas.convert('LA').convert('RGBA')
        mono.save(mipmap / 'ic_launcher_monochrome.png')
        tmp_fg.unlink()
        print(f'Generated mipmap-{density}')

    # Launcher background color
    (REPO / 'android/app/src/main/res/values/colors.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        '    <color name="ic_launcher_background">#090D16</color>\n'
        '</resources>\n'
    )
    print('Icon generation complete')


if __name__ == '__main__':
    main()
