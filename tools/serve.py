#!/usr/bin/env python3
"""Serve the Flutter web build or the selected A reference on localhost."""
import argparse
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

REPO = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", choices=("flutter", "reference"), nargs="?", default="flutter")
    parser.add_argument("--port", type=int)
    parser.add_argument("--host", default="127.0.0.1")
    args = parser.parse_args()
    reference = args.target == "reference"
    directory = REPO / ("design/reference-a" if reference else "build/web")
    port = args.port or (8787 if reference else 8788)
    if not (directory / "index.html").is_file():
        parser.error("Run `flutter build web --release` first.")

    class Handler(SimpleHTTPRequestHandler):
        def __init__(self, *handler_args, **kwargs):
            super().__init__(*handler_args, directory=str(directory), **kwargs)

        def translate_path(self, path):
            if reference and urlsplit(path).path.startswith("/assets/"):
                self.directory = str(REPO)
                try:
                    return super().translate_path(path)
                finally:
                    self.directory = str(directory)
            return super().translate_path(path)

        def log_message(self, format, *values):
            if len(values) > 1 and str(values[1]) != "200":
                super().log_message(format, *values)

    server = ThreadingHTTPServer((args.host, port), Handler)
    print(f"Morss {'A reference' if reference else 'Flutter'} → http://{args.host}:{port}/", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
