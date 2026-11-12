# ClairDocs Enterprise

Autonomous contract-to-invoice audit and formal dispute resolution desktop application built with Flutter.

## Development Setup

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

## Windows MSIX Packaging

ClairDocs uses the [`msix`](https://pub.dev/packages/msix) dev dependency configured under `msix_config` in `pubspec.yaml`:

- **Display Name**: `ClairDocs Enterprise`
- **Publisher Display Name**: `ClairDocs Corporation`
- **Identity Name**: `com.clairdocs.desktop`
- **MSIX Version**: `1.0.0.0`
- **Logo Path**: `assets/logo.png` (`msix_config.logo_path`)
- **URI Protocol Activation**: `clairdocs://` (`msix_config.protocol_activation`)
- **Capabilities**: `internetClient` (+ automatic `runFullTrust`)

### Prerequisites (Windows)

- Windows 10 (version 1809 / build 17763+) or Windows 11
- Flutter SDK with Windows desktop support (`flutter config --enable-windows-desktop`)
- Visual Studio with the **Desktop development with C++** workload

### Generate the MSIX Installer

Run the MSIX packager directly from the repository root:

```powershell
flutter pub get
flutter pub run msix:create
```

Or use the provided packaging script, which runs `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter pub run msix:create`:

```powershell
.\scripts\build_msix.ps1
```

#### Common Options

```powershell
# Skip preflight analysis/tests for a fast rebuild
.\scripts\build_msix.ps1 -SkipChecks

# Build without installing the self-signed test certificate into the local machine store
.\scripts\build_msix.ps1 -NoInstallCert

# Sign with a production EV/OV code-signing certificate
.\scripts\build_msix.ps1 -CertificatePath .\certs\clairdocs.pfx -CertificatePassword $env:MSIX_CERT_PASSWORD

# Package for Microsoft Store submission
.\scripts\build_msix.ps1 -Store
```

By default, `msix:create` builds the Windows release binary and writes the `.msix` installer under `build\windows\x64\runner\Release\clairdocs.msix` (or `build\windows\runner\Release\clairdocs.msix`), signed with a test certificate unless `-CertificatePath` / `-Store` is specified.
