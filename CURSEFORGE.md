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
- The addon files live at the **repo root**; the zip must contain exactly one
  top-level folder `DotsNHots/` with the `.toc` + `.lua` files inside.
- Build it with:
  ```powershell
  pwsh -File build.ps1
  ```
  This produces **`DotsNHots.zip`** in the repo root (it is git-ignored, since
  it is a build artifact).

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

The repo is already laid out for this: the addon files sit at the **repo root**,
with `.pkgmeta` and `.github/workflows/release.yml` next to them. (GitHub Actions
only runs workflows found at the repo root — that is why the addon is not kept in
a subfolder here. The packager re-creates the `DotsNHots/` folder in the zip via
`package-as`.)

1. Push the repo to GitHub (already done: `Felix-Helleckes/hotsndots`).
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
- [ ] Zip contains exactly the top-level `DotsNHots/` folder (`build.ps1`)
- [ ] Correct "Game Version" selected on upload

---

## Testing a local build

The repo root is not a valid addon folder by itself (WoW needs the files inside a
folder named `DotsNHots`). To test changes in-game, copy the addon files into:

```
World of Warcraft\_retail_\Interface\AddOns\DotsNHots\
```

Then `/reload` in game (a full restart is only needed when the `.toc` changes).
