# Signing and Keychain continuity

## Why this matters

macOS uses an app's code identity and designated requirement when deciding whether a new build is the same app that previously accessed a Keychain item. Ad-hoc signatures can change between builds and may trigger repeated authorization prompts even when the bundle identifier is unchanged.

## Personal machine

Use the login-Keychain identity named `Translate Quick Local Signing` by setting:

```bash
TRANSLATE_QUICK_SIGN_IDENTITY="Translate Quick Local Signing" ./Scripts/build-app.sh
```

The self-signed certificate is appropriate only for stable identity on this personal Mac. Trusting it as a Code Signing root is a persistent security setting and requires the user's explicit approval. Do not expand its trust purpose, export its private key, or distribute it to another machine.

Completed on this Mac on 2026-08-24:

- Identity: `Translate Quick Local Signing`
- Certificate SHA-1: `4A89092541DD3178D48B2E5F429C43E1E292E5CA`
- Certificate SHA-256: `CE63E56AD4E27514BA18A95E66AF3BE6C101C7044A5AFCCA38F0C91872F60472`
- Trust scope: Code Signing only, in the current user's trust settings.
- The private key remains in login Keychain and was not exported or copied into the project.

Release procedure:

1. Confirm `security find-identity -v -p codesigning` lists the identity.
2. Build with `TRANSLATE_QUICK_SIGN_IDENTITY` set.
3. Verify `codesign --verify --deep --strict` and inspect `codesign -d -r- -vv`.
4. Install the exact signed bundle and launch that path.
5. If the first real Groq request asks once because the existing password item's ACL came from an older ad-hoc build, choose **Always Allow**. App launch and merely opening Settings must not read the secret or prompt.

## Commercial distribution

Replace the local identity with an Apple Developer ID Application identity, enable Hardened Runtime, timestamp, notarize, and distribute the notarized artifact. Never ship the local self-signed certificate or rely on it as proof of publisher identity.

## Build behavior

`Scripts/build-app.sh` signs ad-hoc only when `TRANSLATE_QUICK_SIGN_IDENTITY` is unset. An agent must not call an ad-hoc candidate a stable-Keychain release.
