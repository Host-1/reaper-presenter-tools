# Installing the presenter panel

Do this once per computer. You need **REAPER 7**.

## 1. ReaPack (installs REAPER add-ons)

1. Go to **reapack.com** and download the version for your system
   (Windows: `reaper_reapack-x64.dll`).
2. In REAPER: **Options > Show REAPER resource path in explorer/finder**.
3. Open the **UserPlugins** folder and copy the downloaded file into it.
4. Restart REAPER. An **Extensions** menu appears at the top.

## 2. ReaImGui (draws the panel)

1. **Extensions > ReaPack > Browse packages**.
2. Type `imgui` in the filter box.
3. Right-click **ReaImGui: ReaScript binding for Dear ImGui** > **Install**, then click **Apply**.
4. Restart REAPER.

## 3. The presenter panel

**If you were given a ReaPack link:**

1. **Extensions > ReaPack > Import repositories**, paste the link, click **OK**.
2. **Extensions > ReaPack > Browse packages**, filter `Presenter`, right-click > **Install** > **Apply**.

**If you were given the file** (`Presenter panel.lua`):

1. **Options > Show REAPER resource path in explorer/finder**, open **Scripts**,
   and copy the file into it.
2. **Actions > Show action list > New action > Load ReaScript…** and choose the file.

## 4. Open it

**Actions > Show action list**, search `Presenter panel`, select it and click **Run**.
Run it again to close the panel.

Tip: in the same window you can give it a keyboard shortcut, or add it to a toolbar.

## Updating

- **ReaPack link:** **Extensions > ReaPack > Synchronize packages**.
- **File:** replace the old file in the Scripts folder with the new one (same name), then
  close and reopen the panel.

## If something's wrong

- **"This script needs ReaImGui"** when opening: redo step 2 and restart REAPER.
- **"Needs ReaImGui 0.10 or newer":** **Extensions > ReaPack > Synchronize packages**, then restart.
- **No Extensions menu:** the ReaPack file isn't in UserPlugins, or REAPER wasn't restarted.

Next: [HOW_TO_USE.md](HOW_TO_USE.md).
