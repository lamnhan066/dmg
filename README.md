# DMG

A Flutter package helps you to create, sign, notarize and staple a .DMG.

## Usage

### Create a `NotaryProfile` certificate

**1:** Go to (Appstoreconnect -> Users and Access -> Keys)[https://appstoreconnect.apple.com/access/api]

**2:** Tap (+) to generate a new API key, input a Name (normally use `NotaryProfile`) and Access (noramally use `Admin`).

**3:** Download the generated file and save somewhere secure, also note the `Issuer ID` and `KEY ID`.

**4:** Open terminal and run `xcrun notarytool store-credentials` and input all the above data, you should input the name as `NotaryProfile`.

### Create a `Developer ID Application` certificate if you don't have

**1:** Open Xcode.

**2:** Go to `XCode` -> `Settings` -> `Account`.

**3:** Tap `Manage Certificates...` -> Tap (+) -> Choose `Developer ID Application` -> Done.

### Build the DMG

Install `dmgbuild` if you don't have:

``` shell
pip install dmgbuild
```

Open a terminal on your current project then run:

``` shell
dart run build_dmg --app "./path/to/name.app" --volume-name "name" --dmg "./path/to/name.dmg" --sign-certificate "Developer ID Application: Your  Company" --notary-profile "NotaryProfile"
```

If you want to add a license (a window will show up to ask for the acceptance before able to install the .dmg), add this line to the above code:

``` shell
--license-path "./path/to/license.txt"
```

You can also add your own `setting.py` of (dmg-build)[https://dmgbuild.readthedocs.io/en/latest/settings.html] by adding:

``` shell
--setting "./path/to/setting.py
```

Note that the `--license-path` will not affect when you use your own `setting.py`.