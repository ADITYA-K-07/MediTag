# MediTag — Frontend Design

This document is the design spec for the MediTag reader/writer app (Flutter).
It exists because the first pass at the UI didn't work and is being rebuilt
from scratch against this spec, not patched. The visual language is adapted
from a design system the project owner liked (periwinkle page, floating white
cards, ink-tinted shadows, no borders) and re-applied to MediTag's own screens
and colour needs.

**Read this whole file before writing any widget.** Build the token file and
shared component library first; screens come after, and every screen is built
out of that library — no screen may reach for a raw Material widget with
default styling.

---

## 1. The one idea

> **The page is a pale tinted blue-grey. Cards are pure white and float on
> it. Ink is near-black indigo. Depth comes from a tinted value gap and one
> soft ink-tinted shadow — never from a border, never from a grey/black
> drop shadow.**

A white card on the tinted page separates itself by value alone, so it needs
no border. Radii are generous. This one rule is what was missing from the
first build — check every screen against it before calling it done.

---

## 2. Screens (information architecture)

Build in this order. Each screen is a state the app can be in after an NFC
tap, plus the two flows that don't start with a tap.

```
Home / Scan prompt       Idle state — "Tap a MediTag to read it"
Scanning                 Mid-tap, animated, brief
Tier 1 — Verified        Signature checked offline, valid → shows critical info
Tier 1 — Invalid         Signature check failed → hard warning, not a soft error
Tier 2 — Locked          Online + more detail exists, but user isn't authorized
Tier 2 — Full record     Authorized + online → full medical record
Admin — Issue tag        Write flow: enter patient data → sign → write to tag
Settings                 Language, about, public-key/version info
```

`Admin — Issue tag` is a separate flow, not a tab next to the others — someone
mid-write to a blank tag should not be looking at four unrelated
destinations. Same reasoning as keeping a wizard outside a main shell.

---

## 3. Colour

Define these as constants in one `tokens.dart` file. Nothing outside that
file may hardcode a hex value.

### Brand

| Token | Value | Role |
| --- | --- | --- |
| `inkBrand` | `#191A2E` | The ink everything presses — primary text, primary icons |
| `periwinkle` | `#6B85F0` | Primary brand hue, focus ring, primary buttons |
| `mint` | `#2FAE6A` | Success, "verified" |
| `amber` | `#E5B54E` | Warning |
| `clay` | `#E29448` | Secondary accent, non-critical tags |
| `orchid` | `#C77BEE` | Secondary accent, Tier 2 / "more detail" affordance |
| `criticalRed` | `#D64545` | Reserved *only* for signature-invalid and severe-allergy states — never used decoratively |

### Surfaces

| Token | Value |
| --- | --- |
| `surface` (page background) | `#DAE3FB` |
| `surfaceDim` | `#C6D2F3` |
| `card` | `#FFFFFF` |
| `cardMuted` | `#F4F6FD` |
| `container` | `#E6EBFA` |
| `containerHigh` | `#DCE3FB` |
| `line` (only where a boundary is truly needed, e.g. table rows) | `#E2E6F4` |

### Ink

| Token | Value |
| --- | --- |
| `ink` | `#1B1D2E` |
| `inkMuted` | `#5A6076` |
| `inkFaint` | `#5F6478` |

### Six tile tints (for allergy/condition badges)

navy, orchid, amber, blue, clay, mint — each a pale wash with a foreground
dark enough to clear 4.5:1 *on the wash itself*. Used to visually group
allergy/condition badges into families (e.g. drug allergies vs. food
allergies vs. chronic conditions) — never assign meaning by colour alone,
every tinted badge also carries an icon and a label (see §7 Accessibility).

### Six semantic tones

`neutral · info · success · warning · critical · gold` — every status in the
app resolves to exactly one of these six. `critical` is the *only* tone that
maps to `criticalRed`, and it is reserved for: signature verification
failure, and severe/life-threatening allergy or condition flags. Do not use
`critical` for ordinary form-validation errors — use `warning` for those.

---

## 4. Type

Two variable fonts, self-hosted (bundle the font files in the app — don't
depend on a system font being present):

- **DM Sans** — display and headline levels.
- **Inter** — titles, body, labels, and every number (blood type codes, tag
  IDs, phone numbers).

| Style | Size / leading | Weight |
| --- | --- | --- |
| `displayXl` | 48 / 56 | 700, −0.02em |
| `headlineXl` | 32 / 40 | 700, −0.02em |
| `headlineLg` | 24 / 32 | 600, −0.01em |
| `headlineMd` | 20 / 28 | 600 |
| `labelCaps` | 12 / 16, +0.05em, uppercase | 600 |
| `monoData` | 14 / 20, tabular figures | 500 |
| `statNumber` | 30 / 38, tabular figures | 700 |

`statNumber` is for the blood type / verification status tile on the Tier 1
screen. `monoData` is for the tag ID and any raw technical value shown in
Settings.

---

## 5. Shape, elevation, motion

**Radii:** `sm 10 · md 16 · lg 28 · xl 34 · pill`. The radius is what makes a
white rectangle read as an object, not a panel — don't default to Flutter's
Material `4.0` corner radius anywhere in this app.

**Elevation — always ink-tinted, never black:**

```
level1   0 8px 24px -10px rgba(25,26,46,.06), 0 2px 6px -2px rgba(25,26,46,.04)
level2   0 12px 28px -10px rgba(25,26,46,.12)
level3   0 14px 40px -12px rgba(25,26,46,.14), 0 2px 8px -2px rgba(25,26,46,.06)
glow     0 0 0 3px rgba(107,133,240,.18)     // focus ring, valid-scan pulse
```

Resting card = level1. A tappable card = level2 on press. A modal/sheet
(e.g. the "confirm tag write" dialog) = level3.

**Motion:** `curve = Cubic(.215,.61,.355,1)` · fast 140ms · medium 260ms ·
slow 360ms. Entrance animations animate **position/scale only, never
opacity** — a frozen first frame should look offset, not blank. A staggered
list (e.g. allergy badges appearing) staggers 60ms apart, capped at six
items. Respect the OS reduce-motion setting globally — collapse all
animation durations to near-zero when it's on.

---

## 6. Iconography

**One icon set, one stroke weight, everywhere.** Pick a single line-icon
family (e.g. Phosphor Icons, regular weight, 1.7 stroke on a 24-unit grid)
and use only that — no mixing default Material icons with a second icon pack
mid-app. This was one of the visible problems in the first build. Render at
20px by default.

Do not use emoji as icons anywhere in the UI.

---

## 7. Component library (build these before any screen)

Prefix every shared widget `MT` so it's unambiguous which widgets are the
design-system ones vs. raw Flutter widgets.

**Surfaces**
- `MTCard` (plain / flat / emphasised variants)
- `MTCardHeader`
- `MTSectionHeader`
- `MTPageHeading` (title + optional subtitle + optional trailing action)

**Actions**
- `MTButton` (primary / secondary / text variants)
- `MTIconButton`

**Status**
- `MTBadge` — tint-behind-dark-text at every size, never a saturated fill
  with white text
- `MTVerificationBanner` — the specific "✓ Verified offline" (mint) /
  "✕ Signature invalid — do not trust this tag" (criticalRed) banner that
  sits at the top of every Tier 1 read result. This is the single most
  important component in the app — get its two states pixel-correct before
  anything else.
- `MTTag`

**Data display**
- `MTStatTile` (blood type, tag ID)
- `MTTintTile` (allergy/condition badges, one of the six tile tints + icon +
  label — see §3)
- `MTTierLockCard` — the "more information available, sign in to view"
  card shown on the Tier 2 — Locked screen. Lock icon, one line of
  explanation, one button. Not a dead end — always explains *why* it's
  locked.

**States**
- `MTEmptyState` / `MTEmptyNote` — every empty/error state gets a 68px
  tinted circle icon at the top, so "nothing here" reads as designed, not
  broken (e.g. "no connection — showing offline data only").
- `MTSkeleton` — loading placeholder for the Tier 2 fetch.

**Interactive**
- `MTToggle`, `MTSelect` (for Settings — language switcher)
- `MTModal` (confirm-write dialog in the Admin flow)

**Layout**
- `MTEnter` — the staggered-entrance wrapper described in §5.

---

## 8. Screen-by-screen notes

**Home / Scan prompt** — Centered, generous whitespace, the scan icon
pulses gently (transform-only, respects reduce-motion). One line of
instruction text. No navigation chrome needed — this is effectively the
whole app when idle.

**Tier 1 — Verified** — `MTVerificationBanner` (mint) at the top, then blood
type as an `MTStatTile`, then allergy/condition badges as `MTTintTile`s
grouped and staggered in with `MTEnter`, then the emergency contact as a
tappable `MTCard` with a call action. If Tier 2 data might exist, show an
`MTTierLockCard` or a link at the bottom — don't hide the existence of more
detail.

**Tier 1 — Invalid** — `MTVerificationBanner` (criticalRed), full width,
first thing on screen, unmissable. Explain *why* in one plain sentence ("This
tag's data doesn't match its signature — it may have been altered.") — never
just fail silently or show a generic error.

**Tier 2 — Locked** — `MTTierLockCard`, explains what's missing and why
(no connection, or not authorized) as two visually distinct states, not one
vague "unavailable."

**Tier 2 — Full record** — Standard `MTCard` sections per record category
(conditions, medications, history, contacts). Use `MTSkeleton` while
fetching, never a spinner-only blank screen.

**Admin — Issue tag** — A short linear form (not a dashboard), primary
`MTButton` disabled until required fields are valid, `MTModal` to confirm
before the actual write-to-tag happens (a write is destructive to whatever
was on the tag before).

**Settings** — Plain list of `MTCard` rows: language, about, public key
version/fingerprint (for transparency — someone can confirm which signing
key their app trusts).

---

## 9. Accessibility rules

Constraints on the design, not a checklist applied after:

- **Colour is never the only signal.** Every `MTTintTile` and every
  `MTVerificationBanner` carries its own icon and its own words — a
  colourblind user or a black-and-white printout must still be able to tell
  a severe allergy badge from a routine one.
- **4.5:1 contrast on the tinted page**, not just against white — check
  foregrounds against `surface` (`#DAE3FB`), the tightest surface in the
  system.
- Focus is a 2px `periwinkle` outline at 2px offset, globally, never
  removed.
- Reduce-motion is honoured globally, not per-screen.
- The criticalRed invalid-signature state must also be readable by screen
  reader as a distinct, urgent announcement — not just a colour change.

---

## 10. Instructions for the rebuild

1. Delete/replace the current UI implementation — this is a rebuild against
   this spec, not a patch on top of the existing widget tree.
2. Create `lib/theme/tokens.dart` first, with every value in §3–§6 as a
   named constant. Nothing outside this file hardcodes a colour, radius, or
   shadow.
3. Build the full `MT*` component library from §7 next, in a `lib/widgets/`
   folder, before starting on any screen.
4. Build screens in the order listed in §2. Every screen is composed only
   from `MT*` components and Flutter layout primitives (`Column`, `Row`,
   `Padding`, etc.) — no raw `Card`, `ElevatedButton`, or `Container` with
   ad-hoc decoration in a screen file.
5. `MTVerificationBanner`'s two states (verified / invalid) are the most
   important pixels in the app — get those exactly right before polishing
   anything else.
6. When done, log the rebuild in `EDI.md`'s Session Log: what was built,
   which screens are complete, and which are still stubs.