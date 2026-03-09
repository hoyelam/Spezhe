## Release Setup

This repo keeps DMG and GitHub release automation, but sensitive release credentials are not tracked.

### DMG and GitHub releases

Required environment variables:

- `SPEZHE_DEVELOPER_IDENTITY`
  Example: `Developer ID Application: Your Name (TEAMID)`

Optional environment variables:

- `SPEZHE_NOTARY_PROFILE`
  Default: `AC_PASSWORD`
- `SPEZHE_GITHUB_REPO`
  Default: `hoyelam/Spezhe`

Required external setup:

- `gh` authenticated for release creation
- `xcrun notarytool` keychain profile created locally
- Sparkle signing tool available at `App/.build/artifacts/sparkle/Sparkle/bin/sign_update`

Example:

```sh
export SPEZHE_DEVELOPER_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export SPEZHE_NOTARY_PROFILE="AC_PASSWORD"
bundle exec fastlane mac dmg bump_marketing:true
```

### TestFlight / App Store metadata

Use App Store Connect API key environment variables supported by fastlane:

- `APP_STORE_CONNECT_API_KEY_KEY_ID`
- `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_KEY_CONTENT`
  or `APP_STORE_CONNECT_API_KEY_KEY_FILEPATH`

Optional fastlane environment variables:

- `FASTLANE_APPLE_ID`
- `FASTLANE_ITC_TEAM_ID`
- `FASTLANE_TEAM_ID`
- `FASTLANE_APP_IDENTIFIER`

The tracked files in `fastlane/metadata/review_information/` are intentionally blank in the public repo. Fill them locally before uploading App Store metadata if your workflow requires review contact information.
