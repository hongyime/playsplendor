"""Regression checks for broken CSS assets observed in the Java 17 Pages build."""

import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('build_site', Path(__file__).resolve().parents[1] / 'scripts/build_site.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class SiteAssets(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='splendor assets ')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.api = self.root / 'docs/javadoc'
        self.api.mkdir(parents=True)

    def test_missing_css_image_fails_the_build(self):
        (self.api / 'stylesheet.css').write_text("a { background: url('resources/missing.png') }", encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'missing.png'):
            builder.verify_links(self.root)

    def test_missing_optional_font_uses_existing_system_fallbacks(self):
        css = "@import url('resources/fonts/dejavu.css');\nbody {font-family: 'DejaVu Sans', Arial, sans-serif;}"
        (self.api / 'stylesheet.css').write_text(css, encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'dejavu.css'):
            builder.verify_links(self.root)
        builder.use_available_javadoc_fonts(self.root)
        builder.verify_links(self.root)
        self.assertIn("font-family: 'DejaVu Sans', Arial, sans-serif", (self.api / 'stylesheet.css').read_text(encoding='utf-8'))

    def test_available_font_import_is_preserved(self):
        font = self.api / 'resources/fonts/dejavu.css'
        font.parent.mkdir(parents=True)
        font.write_text('/* provided by the installed JDK */', encoding='utf-8')
        css = "@import url('resources/fonts/dejavu.css');"
        (self.api / 'stylesheet.css').write_text(css, encoding='utf-8')
        builder.use_available_javadoc_fonts(self.root)
        self.assertEqual(css, (self.api / 'stylesheet.css').read_text(encoding='utf-8'))
        self.assertEqual(1, builder.verify_links(self.root))

    def test_css_data_urls_and_local_queries_are_valid(self):
        (self.api / 'icon.svg').write_text('<svg/>', encoding='utf-8')
        (self.api / 'stylesheet.css').write_text('a {background: url(icon.svg?v=1#mark)} b {background: url("data:image/svg+xml,<svg/>")}', encoding='utf-8')
        self.assertEqual(1, builder.verify_links(self.root))


if __name__ == '__main__':
    unittest.main()
