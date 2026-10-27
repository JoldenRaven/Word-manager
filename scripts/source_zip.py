"""Package only source files; exclude generated files, personal data and keys."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
root = Path(__file__).resolve().parents[1]
out = root / 'dist/source/WordContacts_Source.zip'
out.parent.mkdir(parents=True, exist_ok=True)
excluded = {'.git', '.dart_tool', '.gradle', 'build', 'ephemeral', 'dist', '__pycache__'}
with ZipFile(out, 'w', ZIP_DEFLATED) as archive:
    for name in ('lib', 'android', 'windows', 'test', 'scripts', 'installer', 'docs', 'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'README.md', '.gitignore'):
        path = root / name
        if not path.exists():
            continue
        for file in ([path] if path.is_file() else path.rglob('*')):
            if not file.is_file() or excluded.intersection(file.relative_to(root).parts):
                continue
            if file.name in {'key.properties', 'local.properties'} or file.suffix in {'.db', '.jks', '.keystore'} or '.db-' in file.name:
                continue
            archive.write(file, 'WordContacts/' + str(file.relative_to(root)))
print(out)
