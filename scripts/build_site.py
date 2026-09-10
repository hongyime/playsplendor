"""Build the static Splendor guide and current Javadoc using the installed JDK."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import tempfile
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
CSS_URL = re.compile(r'''url\(\s*(?:(['"])(.*?)\1|([^'"\s][^)]*))\s*\)''', re.DOTALL)


def use_available_javadoc_fonts(output: Path) -> None:
    """Some Java 17 distributions reference DejaVu assets they do not ship."""
    stylesheet = output / 'docs/javadoc/stylesheet.css'
    fonts = output / 'docs/javadoc/resources/fonts/dejavu.css'
    if stylesheet.is_file() and not fonts.is_file():
        css = stylesheet.read_text(encoding='utf-8')
        css = css.replace("@import url('resources/fonts/dejavu.css');",
                          '/* Optional DejaVu assets are absent; use the existing system-font fallbacks. */')
        stylesheet.write_text(css, encoding='utf-8')


class Links(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.urls = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        self.urls.extend(value for name, value in attrs if name in ('href', 'src') and value)


def verify_links(output: Path) -> int:
    checked = 0
    for page in [*output.rglob('*.html'), *output.rglob('*.css')]:
        content = page.read_text(encoding='utf-8')
        if page.suffix == '.css':
            urls = [(match.group(2) or match.group(3)).strip() for match in CSS_URL.finditer(content)]
        else:
            links = Links()
            links.feed(content)
            urls = links.urls
        for url in urls:
            parsed = urlsplit(url)
            if parsed.scheme or parsed.netloc or not parsed.path:
                continue
            target = (page.parent / unquote(parsed.path)).resolve()
            if not target.is_relative_to(output.resolve()) or not target.exists():
                raise ValueError(f'Broken local link in {page.relative_to(output)}: {url}')
            checked += 1
    return checked


def build_site(output: Path) -> dict:
    output = output.resolve()
    if output.exists() and any(output.iterdir()):
        raise ValueError('Choose an empty output directory with --output to avoid mixing old and new files.')
    output.mkdir(parents=True, exist_ok=True)
    javadoc = shutil.which('javadoc')
    if not javadoc:
        raise RuntimeError('Install a JDK (Java 17 or later) so javadoc is available.')
    command = [javadoc, '-d', str(output / 'docs/javadoc'), '-sourcepath', str(ROOT / 'src'),
               '-subpackages', 'com.splendor', '-encoding', 'UTF-8', '-docencoding', 'UTF-8',
               '-charset', 'UTF-8', '-Xdoclint:all,-missing', '-quiet', '-notimestamp', '--release', '17',
               '-windowtitle', 'Splendor Java API']
    subprocess.run(command, cwd=ROOT, check=True, timeout=120)
    use_available_javadoc_fonts(output)
    shutil.copyfile(ROOT / 'index.html', output / 'index.html')
    shutil.copyfile(ROOT / 'site/style.css', output / 'style.css')
    shutil.copytree(ROOT / 'site/diagrams', output / 'diagrams')
    # Keep old documentation bookmarks useful without a redirect to a missing page.
    (output / 'docs/index.html').write_text(
        '<!doctype html><html lang="en"><meta charset="utf-8"><title>Splendor documentation</title>'
        '<p><a href="../index.html">Splendor project guide</a></p>'
        '<p><a href="javadoc/index.html">Current Java API documentation</a></p></html>\n', encoding='utf-8')
    checked = verify_links(output)
    sources = sorted((ROOT / 'src').rglob('*.java'))
    class_pages = []
    for source in sources:
        if source.name in ('package-info.java', 'module-info.java'):
            continue
        page = Path('docs/javadoc') / source.relative_to(ROOT / 'src').with_suffix('.html')
        if not (output / page).is_file():
            raise ValueError(f'Missing API documentation for {source.relative_to(ROOT)}')
        class_pages.append(page.as_posix())
    files = {p.relative_to(output).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
             for p in sorted(output.rglob('*')) if p.is_file()}
    result = {'commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              'java_sources': len(sources), 'class_pages': class_pages, 'local_links_checked': checked,
              'files': files, 'bytes': sum(p.stat().st_size for p in output.rglob('*') if p.is_file())}
    (output / 'release.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, help='Empty directory for the complete static site; defaults to a new temporary directory.')
    args = parser.parse_args()
    output = args.output or Path(tempfile.mkdtemp(prefix='splendor-site-'))
    result = build_site(output)
    print(json.dumps({'output': str(output.resolve()), 'java_sources': result['java_sources'],
                      'class_pages': len(result['class_pages']), 'local_links_checked': result['local_links_checked'],
                      'files': len(result['files']), 'bytes': result['bytes']}))


if __name__ == '__main__':
    main()
