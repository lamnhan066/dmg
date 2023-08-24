# DMG

A Flutter package helps you to create, sign, notarize and staple a .DMG with a single command.

## Demo terminal output

``` terminal
dart run dmg --sign-certificate "Developer ID Application: <Your  Company>"
Building package executable... 
Built dmg:dmg.
Cleaning build...
Cleaned
Flutter release...
Released
Code signing for the APP...
Signed
Building DMG...
Built
Code signing for the DMG...
Signed
Notarizing...
Checking for the notary result...
Still in processing. Waiting...
Checking for the notary result...
Notarized
Stapling...
Stapled
Done everything. Output: ./build/macos/Build/Products/Release/<Name>.dmg
```

## Required

All this steps are needed for only the first app, you can reuse this setting in other apps.

### Install `dmgbuild` if you don't have

``` shell
pip install dmgbuild
```

### Create a `NotaryProfile` certificate

**1:** Go to [Appstoreconnect -> Users and Access -> Keys](https://appstoreconnect.apple.com/access/api)

**2:** Tap (+) to generate a new API key, input a Name (normally use `NotaryProfile`) and Access (noramally use `Admin`).

**3:** Download the generated file and save somewhere secure, also note the `Issuer ID` and `KEY ID`.

**4:** Open terminal and run `xcrun notarytool store-credentials` and input all the above data, you should input the name as `NotaryProfile`.

### Create a `Developer ID Application` certificate if you don't have

**1:** Open Xcode.

**2:** Go to `XCode` -> `Settings` -> `Account`.

**3:** Tap `Manage Certificates...` -> Tap (+) -> Choose `Developer ID Application` -> Done.

## Usage

Open a terminal on your current project then run:

``` shell
dart run dmg --sign-certificate "Developer ID Application: Your  Company"
```

Change the notary profile name if you don't use the default by adding:

``` shell
--notary-profile "NotaryProfile"
```

If you want to add a license (a window will shows up to ask for the acceptance before showing the installation for the .dmg), add this line to the above code:

``` shell
--license-path "./path/to/license.txt"
```

You can also add your own `setting.py` of [dmg-build](https://dmgbuild.readthedocs.io/en/latest/settings.html) by adding:

``` shell
--setting "./path/to/setting.py"
```

Note that the `--license-path` will not affect when you use your own `setting.py`.

Your output `DMG` is expected at: `build/macos/Build/Products/Release/<name>.dmg`.

## Contributions

This package still in the early stages, file an issue if you have one and PR is welcome.
