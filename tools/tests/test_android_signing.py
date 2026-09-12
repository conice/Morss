import base64
import itertools
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "prepare_android_signing.py"
KEYSTORE = b"\xfe\xed\xfe\xed synthetic CI keystore fixture\x00\xff"
SECRETS = {
    "ANDROID_KEYSTORE_BASE64": base64.encodebytes(KEYSTORE).decode("ascii"),
    "ANDROID_KEYSTORE_PASSWORD": " leading space\\equals=colon:密钥🔑\nnext line ",
    "ANDROID_KEY_ALIAS": "release alias",
    "ANDROID_KEY_PASSWORD": "key-password-!#\t尾部 ",
}


class AndroidSigningTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.project = self.root / "project"
        (self.project / "android").mkdir(parents=True)
        self.runner_temp = self.root / "runner"
        self.runner_temp.mkdir()
        self.output = self.root / "github-output"
        self.properties = self.project / "android" / "key.properties"
        self.keystore = self.runner_temp / "morss-android-signing" / "release.jks"

    def run_preparation(self, secrets):
        environment = dict(os.environ)
        for name in SECRETS:
            environment.pop(name, None)
        environment.update(
            RUNNER_TEMP=str(self.runner_temp),
            GITHUB_OUTPUT=str(self.output),
        )
        environment.update(secrets)
        return subprocess.run(
            [sys.executable, str(SCRIPT)],
            cwd=self.project,
            env=environment,
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )

    def assert_no_signing_material(self):
        self.assertFalse(self.properties.exists())
        self.assertFalse(self.keystore.exists())
        self.assertFalse(self.output.exists())

    def test_no_secrets_selects_debug_without_creating_signing_files(self):
        result = self.run_preparation({})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.output.read_text(), "mode=debug\n")
        self.assertFalse(self.properties.exists())
        self.assertFalse(self.keystore.exists())

    def test_complete_secrets_select_release_and_preserve_credentials(self):
        self.output.write_text("existing-output=keep\n")
        result = self.run_preparation(SECRETS)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.output.read_text(), "existing-output=keep\nmode=release\n"
        )
        self.assertEqual(self.keystore.read_bytes(), KEYSTORE)
        self.assertEqual(stat.S_IMODE(self.keystore.stat().st_mode), 0o600)
        self.assertEqual(stat.S_IMODE(self.properties.stat().st_mode), 0o600)

        # Decode Properties' Unicode escapes with Python's independent codecs.
        # The UTF-16 round trip joins surrogate pairs for non-BMP characters.
        properties = {}
        for line in self.properties.read_text("ascii").splitlines():
            name, value = line.split("=", 1)
            decoded = value.encode("ascii").decode("unicode_escape")
            properties[name] = decoded.encode(
                "utf-16", errors="surrogatepass"
            ).decode("utf-16")
        self.assertEqual(
            properties,
            {
                "storeFile": str(self.keystore.resolve()),
                "storePassword": SECRETS["ANDROID_KEYSTORE_PASSWORD"],
                "keyAlias": SECRETS["ANDROID_KEY_ALIAS"],
                "keyPassword": SECRETS["ANDROID_KEY_PASSWORD"],
            },
        )
        for value in SECRETS.values():
            self.assertNotIn(value, result.stdout + result.stderr)

    def test_every_partial_configuration_fails_without_falling_back(self):
        for flags in itertools.product((False, True), repeat=len(SECRETS)):
            if not any(flags) or all(flags):
                continue
            configured = {
                name: value
                for (name, value), present in zip(SECRETS.items(), flags)
                if present
            }
            with self.subTest(configured=list(configured)):
                result = self.run_preparation(configured)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Incomplete Android signing configuration", result.stderr)
                for name in SECRETS.keys() - configured.keys():
                    self.assertIn(name, result.stderr)
                self.assert_no_signing_material()

    def test_invalid_base64_fails_without_printing_secrets(self):
        secrets = dict(SECRETS, ANDROID_KEYSTORE_BASE64="invalid-keystore-%%%")
        result = self.run_preparation(secrets)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("valid Base64", result.stderr)
        self.assert_no_signing_material()
        for value in secrets.values():
            self.assertNotIn(value, result.stdout + result.stderr)

    def test_whitespace_only_keystore_is_rejected(self):
        result = self.run_preparation(dict(SECRETS, ANDROID_KEYSTORE_BASE64=" \n\t"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("empty keystore", result.stderr)
        self.assert_no_signing_material()

    def test_existing_local_properties_are_preserved(self):
        self.properties.write_text("existing configuration")
        result = self.run_preparation(SECRETS)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.properties.read_text(), "existing configuration")
        self.assertFalse(self.keystore.exists())
        self.assertFalse(self.output.exists())

    def test_existing_keystore_is_preserved(self):
        self.keystore.parent.mkdir()
        self.keystore.write_bytes(b"existing keystore")
        result = self.run_preparation(SECRETS)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.keystore.read_bytes(), b"existing keystore")
        self.assertFalse(self.properties.exists())
        self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
