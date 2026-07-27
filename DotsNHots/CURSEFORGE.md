# Publishing DotsNHots on CurseForge

There are two routes. **Route A (manual upload)** is fastest for the first
release. **Route B (GitHub + packager)** automates every future update.

> Note: uploading requires **your** CurseForge account, so the actual upload
> is something only you can do. Everything else (packaging, metadata, docs,
> workflow) is already prepared in this folder.

---

## One-time setup

1. Create/log in at https://www.curseforge.com
2. Become an author: https://authors.curseforge.com (accept the author terms).

---

## Route A — Manual upload (recommended to start)

### 1. Create the project
- Dashboard -> **Create a Project**
- **Game:** World of Warcraft
- **Name:** DotsNHots
- **Summary:** "Shows only your own DoTs (on enemies) and HoTs (on friends), big on nameplates and as movable bars."
- **Category:** *Buffs & Debuffs* (optionally also *Unit Frames*)
- **Project URL / slug:** dotsnhots (if available)

### 2. Description & images
- Paste the contents of `README.md` into the project **Description**.
- Add screenshots/GIFs once you have them (nameplate icons + bars in combat sell it best).

### 3. Build the release zip
- The zip must contain exactly one top-level folder `DotsNHots/` with the
  `.toc` + `.lua` files inside.
- The ready file is on your Desktop: **`DotsNHots.zip`**.

### 4. Upload
- Project page -> **Files** -> **Upload File** -> select the zip.
- **Release Type:** Release
- **Game Version:** the current Retail version (Midnight / 12.0.7) — must match
  `## Interface:` in the `.toc`.
- **Changelog:** paste from `CHANGELOG.md`.

### 5. Add the Project ID (recommended)
- Copy the **Project ID** from the project page.
- In `DotsNHots.toc` enable and fill: `## X-Curse-Project-ID: 123456`

---

## Route B — GitHub + automatic packager (for ongoing updates)

1. Create a GitHub repo and push the **contents** of the `DotsNHots` folder to
   the repo root (so `DotsNHots.toc`, `Core.lua`, ... sit at the top). The
   `.pkgmeta` and `.github/workflows/release.yml` are already included.
2. Create the CurseForge project (Route A, steps 1–2) and note the Project ID.
3. Create a CurseForge API token: https://legacy.curseforge.com/account/api-tokens
4. In the GitHub repo: *Settings -> Secrets and variables -> Actions* add:
   - `CF_API_KEY` = your CurseForge token
5. Put the Project ID into the `.toc`: `## X-Curse-Project-ID: <id>`
6. Cut a release by pushing a tag:
   ```bash
   git tag 1.0.0
   git push origin 1.0.0
   ```
   The BigWigsMods packager builds the zip from `.pkgmeta`, reads the version
   from the tag, and uploads it to CurseForge (and GitHub Releases).

---

## Pre-release checklist
- [ ] `## Version:` bumped in the `.toc`
- [ ] `## Interface:` matches the live game version
- [ ] `CHANGELOG.md` updated
- [ ] Zip contains exactly the top-level `DotsNHots/` folder
- [ ] Correct "Game Version" selected on upload
