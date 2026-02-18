# Releasing Ghostly

## Prerequisites

### Generate EdDSA Signing Keys (one-time)

After cloning, resolve SPM packages and run Sparkle's key generator:

```bash
cd .derivedData/SourcePackages/artifacts/sparkle/Sparkle/bin
./generate_keys
```

Copy the **public key** into `Ghostly/Info.plist` under `SUPublicEDKey` (replacing `PLACEHOLDER`).

Store the **private key** securely — it's needed for every release.

## Release Workflow

1. **Bump version** in Xcode project settings (`MARKETING_VERSION`) and `CFBundleVersion` in Info.plist

2. **Archive** the app with Developer ID signing:
   ```bash
   xcodebuild archive -project Ghostly.xcodeproj -scheme Ghostly -archivePath build/Ghostly.xcarchive
   ```

3. **Export** the archive and create a zip:
   ```bash
   cd build/Ghostly.xcarchive/Products/Applications
   zip -r ../../../../Ghostly.zip Ghostly.app
   ```

4. **Sign the update** with Sparkle:
   ```bash
   .derivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update build/Ghostly.zip
   ```

5. **Update the appcast** — run `generate_appcast` on the folder containing the zip:
   ```bash
   .derivedData/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast build/
   cp build/appcast.xml appcast.xml
   ```

6. **Create GitHub Release** — upload `Ghostly.zip` to a new release on GitHub

7. **Update appcast.xml** — ensure the `<enclosure url="...">` points to the GitHub Release download URL

8. **Commit and push** the updated `appcast.xml`

The raw GitHub URL (`https://raw.githubusercontent.com/Gabko14/Ghostly/main/appcast.xml`) serves the appcast to Sparkle automatically.
