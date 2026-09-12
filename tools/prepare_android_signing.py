"""Prepare CI-only Android signing files without exposing secret values."""

from __future__ import annotations

import base64
import binascii
from collections.abc import Mapping
import os
from pathlib import Path
import sys


SECRET_NAMES = (
    "ANDROID_KEYSTORE_BASE64",
    "ANDROID_KEYSTORE_PASSWORD",
    "ANDROID_KEY_ALIAS",
    "ANDROID_KEY_PASSWORD",
)


def property_value(value: str) -> str:
    # Java Properties reads ISO-8859-1 and UTF-16 Unicode escapes. Escaping every
    # code unit also preserves whitespace, backslashes and embedded newlines.
    encoded = value.encode("utf-16-be")
    return "".join(
        f"\\u{int.from_bytes(encoded[index:index + 2], 'big'):04x}"
        for index in range(0, len(encoded), 2)
    )


def write_private(path: Path, content: bytes) -> None:
    descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(descriptor, "wb") as output:
        output.write(content)


def prepare_signing(
    environment: Mapping[str, str], project: Path, runner_temp: Path
) -> str:
    values = {name: environment.get(name, "") for name in SECRET_NAMES}
    if not any(values.values()):
        return "debug"

    missing = [name for name, value in values.items() if not value]
    if missing:
        raise ValueError(
            "Incomplete Android signing configuration. Missing: " + ", ".join(missing)
        )

    try:
        keystore = base64.b64decode(
            "".join(values["ANDROID_KEYSTORE_BASE64"].split()), validate=True
        )
    except (binascii.Error, ValueError) as error:
        raise ValueError("ANDROID_KEYSTORE_BASE64 must contain valid Base64.") from error
    if not keystore:
        raise ValueError("ANDROID_KEYSTORE_BASE64 decoded to an empty keystore.")

    keystore_file = runner_temp.resolve() / "morss-android-signing" / "release.jks"
    properties_file = project / "android" / "key.properties"
    if properties_file.exists() or keystore_file.exists():
        raise ValueError("Refusing to overwrite existing Android signing files.")

    properties = {
        "storeFile": str(keystore_file),
        "storePassword": values["ANDROID_KEYSTORE_PASSWORD"],
        "keyAlias": values["ANDROID_KEY_ALIAS"],
        "keyPassword": values["ANDROID_KEY_PASSWORD"],
    }
    content = "".join(
        f"{name}={property_value(value)}\n" for name, value in properties.items()
    ).encode("ascii")
    keystore_file.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    write_private(keystore_file, keystore)
    write_private(properties_file, content)
    return "release"


def main() -> int:
    try:
        mode = prepare_signing(
            os.environ, Path.cwd(), Path(os.environ["RUNNER_TEMP"])
        )
        with Path(os.environ["GITHUB_OUTPUT"]).open("a", encoding="utf-8") as output:
            output.write(f"mode={mode}\n")
    except (OSError, ValueError, KeyError) as error:
        print(f"::error::{error}", file=sys.stderr)
        return 1
    print(f"Android build mode: {mode}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
