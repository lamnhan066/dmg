
# DMG

A Flutter package that helps you create, sign, notarize, and staple a .DMG with a single command.

# Features

- Easy to use: Streamline the entire process with one command.
- Security: Ensures your .DMG files are signed and notarized as per Apple's requirements.

## Requirements

All these steps are needed only for the first app. You can reuse these settings in other apps.

### Before installation, ensure you have the following

- Python (version 3.x or later)
- Flutter
- Xcode (for macOS)

### Install `dmgbuild` if you haven't ([documentation](https://dmgbuild.readthedocs.io/en/latest/))

```shell
pip install dmgbuild
```

### Create a `NotaryProfile`

**1.** Go to [App Store Connect -> Users and Access -> Keys](https://appstoreconnect.apple.com/access/api).

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

Open a terminal in your current project, then run:

```shell
dart run dmg
```

This package will automatically retrieve Developer ID certificate for code signing. If multiple valid certificates are available, a list of options will be displayed, and you have to select one. If you want to set it yourself, you can add this option:

```shell
--sign-certificate "Developer ID Application: Your Company"
```

Sometimes, it is necessary to add two spaces between the words "Your" and "Company" like "Your  Company".

The package will automatically run `flutter build macos --release --obfuscate --split-debug-info=debug-macos-info`. If you want to do it yourself, you can pass this flag to the command:

```shell
--no-build
```

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

Your output `DMG` is expected at `build/macos/Build/Products/Release/<name>.dmg`.

## Contributions

This package is still in the early stages. File an issue if you have one, and PRs are welcome.
