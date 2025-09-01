## 0.1.6

* Fix [dmgbuild #199](https://github.com/dmgbuild/dmgbuild/issues/199) caused the dmgbuild to crash.
* Update logs.

## 0.1.5

* Improve error handling and logging.
* Update README.

## 0.1.4

* Add `--no-clean-build` flag to skip the clean build behavior before running the build command (resolve [#3](https://github.com/lamnhan066/dmg/issues/3)).
* Ensure that the exit code is set to a non-zero value in case of any issues.

## 0.1.3

* Add `--strict` and `--entitlements=macos/Runner/Release.entitlements` to codesign process ([see more](https://github.com/juliansteenbakker/flutter_secure_storage/issues/804#issuecomment-2650518260)).
* Automatically retrieve Developer ID certificate for code signing (Only for `Developer ID Application` certificate).

## 0.1.2

* Add `--buid` and `--no-build` flags to enable/disable running `flutter build macos`, so you can run it yourself.

## 0.1.1

* Add `help` flag to show helps.
* Update helps.

## 0.1.0

* Renamed the parameter `setting` to `settings` for consistency.
* Add the `verbose` flag to print more useful logs.
* Update README.

## 0.0.5

* Update homepage URL.
* Improve log.

## 0.0.4

* Improve README
* Improve platform specific

## 0.0.3

* Initial release
