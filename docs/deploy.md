# TestFlight Deployment Guide

Releases are automated via **fastlane** + **GitHub Actions**. Pushing a version tag triggers a build and uploads it to TestFlight automatically.

---

## How to trigger a release

```bash
git tag v1.0.0
git push origin v1.0.0
```

That's it. The workflow builds the app, increments the build number, and uploads to TestFlight.

---

## One-time setup (do this before the first release)

### 1. Install fastlane locally

```bash
bundle install
```

### 2. Create a private certs repo

Create a new **private** GitHub repository to store encrypted certificates and provisioning profiles (e.g. `github.com/you/markit-certs`). This is where `match` will store everything.

### 3. Bootstrap match

Run this once on your Mac to upload your distribution certificate and App Store provisioning profile to the certs repo:

```bash
bundle exec fastlane certificates
```

You will be prompted for:
- The git URL of your certs repo
- An encryption password (save this — it becomes `MATCH_PASSWORD`)

### 4. Add GitHub Secrets

Go to: **repo → Settings → Secrets and variables → Actions → New repository secret**

| Secret | What it is | How to get it |
|---|---|---|
| `MATCH_GIT_URL` | URL of your private certs repo | e.g. `https://github.com/you/markit-certs` |
| `MATCH_PASSWORD` | Encryption password set during `fastlane match init` | The password you typed in step 3 |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Base64-encoded `username:token` for accessing the certs repo | Run: `echo -n "github-username:personal-access-token" \| base64` |
| `APP_STORE_CONNECT_API_KEY_ID` | 10-character Key ID | App Store Connect → Users & Access → Integrations → Keys → create key with **App Manager** role |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer UUID shown at top of the Keys page | Same page as above |
| `APP_STORE_CONNECT_API_PRIVATE_KEY` | Base64-encoded `.p8` key file | Download `AuthKey_XXX.p8` when creating the key (only downloadable once), then run: `base64 -i AuthKey_XXX.p8 \| pbcopy` |

---

## What happens during CI

```
git tag v1.0.0
      │
      ▼
GitHub Actions (macos-latest)
      │
      ├─ setup-ruby → bundle install (cached)
      ├─ Install ASC API key
      │
      └─ bundle exec fastlane beta
            │
            ├─ match (sync_code_signing)   → pulls cert + profile from certs repo
            ├─ increment_build_number      → sets CFBundleVersion to GITHUB_RUN_NUMBER
            ├─ gym (build_app)             → xcodebuild archive + export IPA
            └─ pilot (upload_to_testflight)→ uploads to App Store Connect
```

Build appears in TestFlight within ~10 minutes of the upload completing.

---

## Fastlane lanes

| Lane | Command | Purpose |
|---|---|---|
| `beta` | `bundle exec fastlane beta` | Full CI lane — match + build + upload |
| `certificates` | `bundle exec fastlane certificates` | Local only — bootstrap or refresh certs in match repo |

---

## Xcode version note

This project requires **Xcode 26** (`IPHONEOS_DEPLOYMENT_TARGET = 26.2`). GitHub-hosted runners currently ship Xcode 16.x. Until GitHub ships a runner with Xcode 26, choose one of:

| Option | Steps |
|---|---|
| **Lower deployment target** (easiest) | In Xcode: project settings → iOS Deployment Target → set to **17.0** |
| **Self-hosted runner** | Install Xcode 26 on a Mac, register as a GitHub Actions runner, change `runs-on: macos-latest` to `runs-on: self-hosted` in `.github/workflows/deploy.yml` |
| **Wait** | Monitor [github/runner-images](https://github.com/actions/runner-images) for Xcode 26 availability |

---

## Troubleshooting

**`match` can't access the certs repo**
Check that `MATCH_GIT_BASIC_AUTHORIZATION` is correctly base64-encoded and the personal access token has `repo` scope.

**Build number conflict on App Store Connect**
Each upload must have a unique `CFBundleVersion`. The workflow uses `GITHUB_RUN_NUMBER` which is always increasing — this should not happen unless builds were uploaded outside CI. If it does, delete the conflicting build in App Store Connect.

**`pilot` upload times out**
The workflow sets `skip_waiting_for_build_processing: true` so the upload itself won't time out. Processing happens asynchronously on Apple's side (~5–15 min).

**Certificate expired**
Run `bundle exec fastlane certificates` locally to renew and re-upload to the match repo. CI will pick up the new cert on the next run.
