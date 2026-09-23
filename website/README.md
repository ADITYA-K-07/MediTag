# MediTag Web

The browser-based MediTag experience for emergency profile lookup, citizen
profile previews, and the clinician workspace. It complements the native
Flutter NFC reader; it does not replace the app's offline NFC flow.

## Routes

| Route | Purpose |
| --- | --- |
| `/` | Public access-code lookup and product overview |
| `/emergency/demo` | Public Tier 1 emergency profile preview |
| `/citizen` | Citizen sign-in preview |
| `/citizen/demo` | Citizen profile-management preview |
| `/doctor` | Clinician sign-in preview |
| `/doctor/demo` | Clinician workspace preview |

Authentication and profile data are currently demo-only. The production API
integration belongs in a later milestone.

## Local development

Requirements: Node.js 22.13 or newer.

```powershell
npm ci
npm run dev
```

The development server uses port 5173 by default.

## Quality checks

```powershell
npm run lint
npm run build
```

## Structure

- `app/` - route-level pages and global styles
- `components/` - shared product and UI components
- `hooks/` and `lib/` - reusable browser utilities
- `public/` - static fonts and icons
- `build/`, `scripts/`, and `vite.config.ts` - Vinext/Cloudflare build support

Generated directories such as `.next/`, `.vinext/`, `.wrangler/`, `dist/`, and
`node_modules/` are intentionally ignored.
