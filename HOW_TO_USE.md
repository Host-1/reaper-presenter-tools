# Presenter panel: how to use it

Open it from the Action list ("Presenter panel"). Run the action again to close it.

## Two views (top left)

- **Overview** is the whole session, one tab per region.
- **Presentation** is a separate section the panel builds for you after the end of the session:
  a **PRESENTATION** folder of tracks, one region per section. You pick clips from Overview and
  copy them in. Your original session is never changed.

Both views play, A/B, loop and show notes the same way, and each remembers where you were.

## Set up the session

- **One region per test.** The region name becomes the tab. Regions inside a bigger region
  (e.g. "Round 1") get their own row of tabs.
- **One clip per track.** The track name is the button label. Name tracks A, B, C to keep it blind.
  Takes and lanes each become their own button.
- **Folders** become collapsible groups. **Track colours** carry over.

## Text

- **+ Text** (next to the region title) adds the big text above the clips. **Edit text** changes it.
  Start a line with `>` for the smaller "listen for" cue.
- The text is stored as an item on the top track ("Text"; the panel creates it if needed).
  The presentation has its own text, so overview text isn't copied over.
- Comment items on other tracks and a clip's Item notes show as notes, but are edited in REAPER
  (or with **+ Note**).

## Selecting, colouring and building a presentation

Every clip has a gold **tick box** at the left. Each view keeps its own ticks, and they stay as you
move between tabs. The bar above the clips works on whatever is ticked:

`3 selected | Select all in region | Colour... | Add to presentation... | Review | Clear`  (Overview)
`1 selected | Select all in section | Colour... | Remove | Clear`  (Presentation)

- **Colour...** recolours the ticked clips: pick a swatch, a custom colour, or **Track colour** to go back
  to the track's colour. In Presentation it only changes the copies, never the originals.
- **Right-click a clip** for the same things on just that clip: colour, select, and
  **Add to presentation...** (Overview) or **Remove from presentation** (Presentation).
  It also has **Rename track...** (the clip's button label) and **Rename take...**.
- **Right-click a folder header** to rename or recolour that folder.

To build the presentation:

1. In **Overview**, tick the clips you want and click **Add to presentation...**. Choose a new section
   (type its name) or an existing one. The clips are copied in, lined up at the section's start,
   each on its own track named after its source (e.g. "B | take 2").
   - **Folders:** by default the copies keep the session's folders, so Vendor A / Batch 2 / Turkish
     lands in PRESENTATION / Vendor A / Batch 2 / Turkish, with the folders' colours. Same-named folders
     from different places (e.g. "Batch 2" under two vendors) stay separate. Later adds reuse them.
     Or choose **No folders** to put the folder path in the track name instead
     ("Vendor A / Batch 2 / Turkish"). The choice is remembered.
2. Switch to **Presentation** to arrange it:
   - **+ Section / Rename section** for the sections (each one is a tab).
   - **+ Add N from Overview here** copies clips ticked in Overview into the section you're on.
   - **Tracks & folders** opens the track list: drag the **::** handle to reorder or drop onto a folder,
     click the colour **swatch** to colour a track, double-click a name to rename,
     **+ Track / + Folder** (**+ Subfolder** inside a folder), **x** deletes an empty track.
   - Hover over a clip to show its **x** at the right end, which removes that copy. Or tick several and use
     **Remove**.

Everything is a normal REAPER edit: saved with the project, **Ctrl+Z** undoes it.

## Playing

- Click a clip, or press **1–9**, to play only that clip. Click again to pause.
- **Space** plays or pauses the selected clip (gold outline).
- **|◀** restarts a clip. Click or drag on the waveform to play from that point.
- Colours: **green** = playing, **amber** box = paused, **blue** = A/B ready.

## A/B

`A/B [ Off | Default | Smooth ]`

- **Default:** switching clips keeps your place, with a tiny gap. Use it for different voices.
- **Smooth:** no gap. Use it for versions of the same recording that start at the same time.
- **A** turns A/B on/off. **S** switches between Default and Smooth.

## Loop

- **Loop** (or **L**) loops the playing clip.
- **Shift + drag** on the waveform loops just that section. Shift + click clears it.

## Markers and notes

- **+ Marker [M]** adds a (red) take marker at the current moment. It shows on the waveform and as a
  jump button.
- **+ Note [N]** adds a comment to the clip's notes.
- Click a marker button to jump there. The little **x** removes a marker or a note line.
- Images in item notes show in the note; click to enlarge.

## Getting around

- Click a **tab**, or use **← / →**, to change region.
- **Compact view** (top right, or **C**) shrinks the panel to tabs, controls and small clip buttons.
- **Expand all / Collapse all** opens or closes folders.

## Settings (top right, next to Compact view)

- Text, button, tab and waveform sizes.
- **Levels:** normalise this region or all clips in the view to a loudness target (default -23 LUFS).
  It warns if any clip would go above -1 dBTP.
- "Put active takes and lanes back when the panel closes" (on by default).

## Keys

| Key | Does |
|---|---|
| 1–9 | Play / pause clip |
| Space | Play / pause selected clip |
| ← / → | Previous / next region |
| A | A/B on / off |
| S | A/B Default / Smooth |
| L | Loop |
| C | Compact view |
| M | Add marker |
| N | Add note |

Keys work when the panel has focus. Click it once if they don't respond.


## Takes, lanes and Blind mode

- **Takes**: an item with several takes is one row. The takes are chips (`t1 t2 t3`) in front of the seek bar;
  click one to play it, click another to switch at the same point, or press Up/Down. The light outline is the
  item's active take; a paused take is amber.
- **Lanes**: a track with clips on several lanes is a slim header with one thin row per lane. Click a lane to
  switch to it at the same point; Up/Down step through the lanes.
- **Blind** (top right, violet): hides names, colours, notes, marker names, lengths and waveforms, flattens
  folders and shuffles the rows of each region (letters A, B, C). **Reveal this region...** and turning Blind off
  both ask first. Cover REAPER's own track view before sharing your screen: it still shows the names.
