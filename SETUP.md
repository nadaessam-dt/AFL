# DALTEX Asia Fruit Logistica 2026 — PWA Setup Guide

## What's included
- `index.html` — Full PWA (single file, works anywhere)
- `sw.js` — Service Worker (offline support)
- `manifest.json` — PWA manifest (installable on phones)
- `supabase_schema.sql` — Database schema (run once)
- This guide

---

## Step 1: Supabase Setup (5 min)

1. Go to [supabase.com](https://supabase.com) → New Project
2. Name it `daltex-afl`, pick a strong password, choose closest region
3. Wait for project to spin up (~2 min)
4. Go to **SQL Editor** → paste the entire `supabase_schema.sql` → click Run
5. Go to **Project Settings → API**:
   - Copy `Project URL` → paste into `index.html` as `SUPABASE_URL`
   - Copy `anon public` key → paste as `SUPABASE_ANON_KEY`

---

## Step 2: Create Users

In Supabase Dashboard → **Authentication → Users → Invite user**:

1. Invite `admin@daltex.com` (or your email)
2. After they accept, run in SQL Editor:
   ```sql
   UPDATE public.profiles SET role = 'admin', full_name = 'Admin Name' WHERE email = 'admin@daltex.com';
   ```
3. Invite each salesperson. Their role defaults to `sales`.
4. Update their names:
   ```sql
   UPDATE public.profiles SET full_name = 'Sara Ahmed' WHERE email = 'sara@daltex.com';
   ```

**Tip:** Disable email confirmation for faster login:
- Authentication → Settings → uncheck "Enable email confirmations"

---

## Step 3: Deploy (2 options)

### Option A — Vercel (Recommended, free)
1. Push files to GitHub repo
2. Go to [vercel.com](https://vercel.com) → Import project
3. Deploy — done. You'll get `https://your-app.vercel.app`

### Option B — Netlify (Drag & Drop)
1. Go to [netlify.com](https://netlify.com) → Sites → Drag your folder
2. Instant deploy, free SSL

### Option C — Any web host
Upload `index.html`, `sw.js`, `manifest.json` to any web server with HTTPS.

---

## Step 4: Install on Phones

### iPhone (iOS):
1. Open the app URL in Safari
2. Tap the **Share** button → **Add to Home Screen**
3. Tap Add — it installs like a native app

### Android:
1. Open in Chrome
2. Tap the **⋮ menu** → **Install app** (or Add to Home Screen)
3. Tap Install

### Desktop (Chrome/Edge):
- Look for the install icon (📲) in the address bar → click it

---

## Demo Mode (No Supabase needed)

If you haven't configured Supabase yet, the app runs in demo mode:
- **Admin login:** `admin@daltex.com` / `admin123`
- **Sales login:** `sales@daltex.com` / `sales123`
- Data is pre-loaded with sample meetings for testing

---

## Icons (Add for full PWA experience)

Create two PNG icons and place in the same folder:
- `icon-192.png` (192×192px)
- `icon-512.png` (512×512px)

Use the DALTEX logo on a navy blue (`#002B5B`) background.

---

## Feature Summary

| Feature | Status |
|---|---|
| Visitor counter with undo | ✅ |
| Meeting registration form | ✅ |
| Business card OCR scanner | ✅ |
| QR badge scanner | ✅ |
| Real-time dashboard | ✅ |
| Lead quality tracking | ✅ |
| Multi-BL selection | ✅ |
| Follow-up tracking | ✅ |
| Excel export (ExcelJS) | ✅ |
| PDF export (jsPDF) | ✅ |
| CSV export | ✅ |
| Offline support + sync | ✅ |
| Dark mode | ✅ |
| PWA installable | ✅ |
| Admin vs Sales roles | ✅ |
| Notification reminders | ✅ |
| Mobile-first responsive | ✅ |

---

## Folder Structure
```
daltex-afl/
├── index.html          ← Main app (edit SUPABASE_URL here)
├── sw.js               ← Service worker (offline)
├── manifest.json       ← PWA manifest
├── icon-192.png        ← Add your icon
├── icon-512.png        ← Add your icon
├── supabase_schema.sql ← Run once in Supabase SQL Editor
└── SETUP.md            ← This guide
```

---

## Troubleshooting

**"Camera not available" on scanner:**
- The app must be served over HTTPS for camera access
- Localhost works for testing

**Data not syncing:**
- Check Supabase URL and anon key in index.html
- Check browser console for errors

**Export not downloading:**
- Chrome/Edge work best for file downloads
- On iOS, use Share → Save to Files

---

*Built by DALTEX Marketing Ops · Nada · 2026*
