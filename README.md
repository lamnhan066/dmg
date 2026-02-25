# DMG

A Flutter package that helps you create, sign, notarize, and staple a .DMG with a single command.

## Features

- **Easy to use**: Streamline the entire process with one command
- **Comprehensive**: Handles building, signing, notarizing, and stapling
- **Error handling**: Robust error handling with detailed logging
- **Security**: Ensures your .DMG files are signed and notarized as per Apple's requirements
- **Flexible**: Supports custom settings, license files, and build configurations
- **CI-friendly**: Create unsigned DMGs for testing without Apple Developer certificates

## Requirements

All these steps are needed only for the first app. You can reuse these settings in other apps.

### For all builds

- Python (version 3.x or later)
- Flutter
- `dmgbuild` (see installation below)

### For signed/notarized builds (production)

- Xcode (for macOS)
- A valid Apple Developer account with certificates

### Install `dmgbuild` if you haven't ([documentation](https://dmgbuild.readthedocs.io/en/latest/))

```shell
pip install dmgbuild
```

### Create a `NotaryProfile`

**1.** Go to [App Store Connect -> Users and Access -> Integrations -> App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api).

**2.** Click (+) to generate a new API key, input a Name (normally use `NotaryProfile`) and Access (normally use `Admin`).

**3.** Download the generated file and save it somewhere secure. Also, note the `Issuer ID` and `Key ID`.

**4.** Open the terminal and run `xcrun notarytool store-credentials`. Input all the above data, ensuring the name is input as `NotaryProfile`.

### Create a `Developer ID Application` certificate if you don't have one

**1.** Open Xcode.

**2.** Go to `Xcode` -> `Preferences` -> `Accounts`.

**3.** Click `Manage Certificates...` -> Click (+) -> Choose `Developer ID Application` -> Click `Done`.

## Usage

Add this package to your development dependency:

```shell
flutter pub add --dev dmg
```

### Basic Usage

#### Production Build (Signed & Notarized)

Open a terminal in your Flutter project root, then run:

```shell
dart run dmg
```

This will automatically:

1. Clean the build directory (optional)
2. Run `flutter build macos --release --obfuscate --split-debug-info=debug-macos-info`
3. Code sign the .app bundle
4. Create a DMG file
5. Code sign the DMG
6. Submit for notarization
7. Wait for notarization to complete
8. Staple the notarized DMG

#### Build With Flavor

If your Flutter macOS app uses flavors, pass the flavor name:

```shell
dart run dmg --flavor production
```

When `--flavor` is provided, this package builds with:

```shell
flutter build macos --release --flavor production --obfuscate --split-debug-info=build/debug-macos-info
```

And reads the app from:

```shell
build/macos/Build/Products/Release-production/
```

#### Test Build (Unsigned)

For quick testing or CI environments without Apple Developer certificates:

```shell
dart run dmg --no-sign --no-notarization
```

**Note:** Unsigned DMGs should not be distributed to end users and will show security warnings when opened.

### Advanced Options

#### Skip Signing and Notarization

For test builds without Apple Developer certificates:

```shell
dart run dmg --no-sign --no-notarization
```

Or skip only notarization (still signs the DMG):

```shell
dart run dmg --no-notarization
```

#### Custom Signing Certificate

The package will automatically retrieve and select your Developer ID certificate. If multiple certificates are available, you'll be prompted to choose one. To specify a certificate manually:

```shell
--sign-certificate "Developer ID Application: Your Company"
```

**Note**: Sometimes you may need to add extra spaces between words, e.g., `"Your  Company"`.

#### Build a Specific Flavor

Use this when your macOS app has Flutter flavors:

```shell
--flavor "production"
```

The package will automatically run `flutter build macos --release --obfuscate --split-debug-info=debug-macos-info`. If you want to do it yourself, you can pass this flag to the command:

```shell
--no-build
```

If you also use `--flavor`, build the same flavor yourself before running `dmg`, or keep `--build` enabled.

When the package runs the `build` command, it will also clean the `build/macos` folder to ensure the output files is valid. If you want to skip this behavior, you can pass this flag:

```shell
--no-clean-build
```

Change the notary profile name if you haven't used the default by adding:

```shell
--notary-profile "NotaryProfile"
```

If you want to add a license (a window will show up asking for acceptance before showing the installation for the .dmg), add this line to the above code:

```shell
--license-path "./path/to/license.txt"
```

You can also add your own `settings.py` from [dmg-build](https://dmgbuild.readthedocs.io/en/latest/settings.html) by adding:

```shell
--settings "./path/to/settings.py"
```

Note that the `--license-path` will be ignored when you use your own `settings.py`.

Your output `DMG` is expected at:

- `build/macos/Build/Products/Release/<name>.dmg` (default)
- `build/macos/Build/Products/Release-<flavor>/<name>.dmg` (when using `--flavor`)

## Contributions

This package is still in the early stages. File an issue if you have one, and PRs are welcome.
