# LM-TRACE — Production Flutter Web Deployment Guide (Vercel)

This document provides complete instructions for building, configuring, and deploying the **LM-TRACE** Legal Metrology Inspection & Compliance Flutter application as a production Web application on **Vercel**, connecting over HTTPS to the **Railway FastAPI** backend.

---

## 1. Production Architecture Overview

```
                        User Browser (Chrome / Edge / Safari)
                                       │
                                       │ HTTPS (HTML5 SPA Routes)
                                       ▼
                       Vercel (Production Static Host)
                           Flutter Web Application
                           - Canvaskit / HTML Renderer
                           - GoRouter (Clean Path URL Strategy)
                           - Responsive Desktop / Tablet / Mobile
                                       │
                                       │ HTTPS REST API calls (JWT Bearer)
                                       ▼
                       Railway (FastAPI Backend Host)
                           - /api/auth/login, /api/inspections, etc.
                           - CORS Middleware (Vercel Origin Regex)
                           │
             ┌─────────────┼────────────────────────┐
             ▼             ▼                        ▼
       Neon Postgres   Cloudinary CDN           AI / OCR Services
       (Storage DB)    (Evidence Storage)       (Groq / Gemini)
```

> [!IMPORTANT]
> **Zero Secrets in Frontend Policy**:
> - The Flutter Web build is compiled to client-side JavaScript/Wasm. Anyone can inspect frontend code in their browser developer tools.
> - **Never** include `CLOUDINARY_API_SECRET`, `DATABASE_URL`, `GEMINI_API_KEY`, `GROQ_API_KEY`, or `JWT_SECRET` in Flutter Web builds or Vercel environment variables.
> - All sensitive operations (OCR, AI extraction, Cloudinary image upload, PDF/DOCX generation) happen strictly server-side on Railway.

---

## 2. Deployment Strategy Selected: Option A (GitHub Actions CI → Vercel)

### Why Option A was Selected:
1. **Flutter SDK Availability**: Vercel's standard serverless build containers run Node.js/Python on Amazon Linux and do **not** come with Flutter pre-installed. Attempting to clone and bootstrap the ~1.5 GB Flutter SDK inside Vercel's build step frequently exceeds Vercel Hobby build timeout limits.
2. **Reproducibility & Version Lock**: GitHub Actions uses `subosito/flutter-action@v2` with version pinning (`3.41.9`, channel `stable`) and action caching, producing identical, deterministic production builds in 2–3 minutes.
3. **Continuous Deployment**: Every push to the `main` branch automatically runs `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build web --release`, then securely deploys `build/web` to Vercel via `amondnet/vercel-action@v25`.

*(Note: Manual deployment using Vercel CLI is also fully supported via `vercel deploy --prod` after running `flutter build web --release`).*

---

## 3. Step-by-Step Deployment Instructions

### Step 3.1: Configure GitHub Repository Secrets
In your GitHub repository, navigate to **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:

| Secret Name | Description | Example / Where to Get |
|---|---|---|
| `VERCEL_TOKEN` | Vercel Personal Access Token | [vercel.com/account/tokens](https://vercel.com/account/tokens) |
| `VERCEL_ORG_ID` | Vercel Team / Account ID | Found in your Vercel Project Settings or `~/.vercel/project.json` |
| `VERCEL_PROJECT_ID` | Vercel Project ID | Found in **Vercel Project Settings** → **General** |
| `API_BASE_URL` | *(Optional)* Override Railway Backend URL | `https://maanak-production.up.railway.app` (Defaults to this if omitted) |

---

### Step 3.2: Configure Vercel Project Settings
When importing your repository in the [Vercel Dashboard](https://vercel.com/new):

1. **Framework Preset**: Select **Other**.
2. **Root Directory**: Select `frontend` (or leave as root if using the root `vercel.json`).
3. **Build & Output Settings**:
   - **Build Command**: Leave empty (handled by GitHub Actions) or `flutter build web --release` if building with custom builder.
   - **Output Directory**: `build/web` (if root directory is `frontend`) or `frontend/build/web` (if root directory is `.`).
4. **Environment Variables** in Vercel:
   - `API_BASE_URL`: `https://maanak-production.up.railway.app`

---

### Step 3.3: Configure Railway Backend CORS
The Railway FastAPI backend must permit cross-origin requests from your Vercel deployment.

In your Railway dashboard:
1. Open your FastAPI service.
2. Go to **Variables**.
3. Set `CORS_ORIGINS`:
   ```bash
   CORS_ORIGINS=https://your-app.vercel.app,http://localhost:*,http://127.0.0.1:*
   ```
   *(Or keep `CORS_ORIGINS=*` during initial staging).*
4. The backend [`main.py`](file:///c:/Users/tripa/Documents/Maanak/backend/app/main.py) includes automatic origin regex matching for all Vercel preview environments (`https://.*\.vercel\.app`).

---

## 4. Manual Local Build & Testing

### 4.1 Local Testing in Browser
To run the web app locally against the backend:
```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=https://maanak-production.up.railway.app
```

### 4.2 Production Build Generation
To generate the release build locally:
```bash
cd frontend
flutter pub get
flutter analyze
flutter build web --release --dart-define=API_BASE_URL=https://maanak-production.up.railway.app
```
Output directory: `frontend/build/web/`

### 4.3 Manual Deploy via Vercel CLI
If you have Vercel CLI installed (`npm i -g vercel`):
```bash
cd frontend
vercel login
vercel --prod
```
When prompted:
- Set output directory: `build/web`

---

## 5. Vercel SPA Routing & Asset Handling (`vercel.json`)

Flutter Web uses client-side routing (`GoRouter`). To ensure that refreshing pages like `/dashboard`, `/inspections`, `/scanner`, `/products`, or `/rules` doesn't produce a 404, [`vercel.json`](file:///c:/Users/tripa/Documents/Maanak/frontend/vercel.json) rewrites all application URLs to `/index.html`, while safeguarding static assets (`main.dart.js`, `flutter.js`, `canvaskit/*`, `assets/*`):

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "cleanUrls": false,
  "outputDirectory": "build/web",
  "rewrites": [
    {
      "source": "/((?!assets/|canvaskit/|icons/|.*\\.(?:js|json|wasm|png|jpg|jpeg|gif|svg|ico|ttf|otf|woff|woff2|css)).*)",
      "destination": "/index.html"
    }
  ]
}
```

---

## 6. Verification Checklist

After deploying to Vercel, verify the live URL:

- [ ] **Home & Login**: Open `https://your-domain.vercel.app/` — login screen loads cleanly.
- [ ] **Authentication**: Log in with demo credentials (`inspector@demo.gov.in` / `Inspector@123`).
- [ ] **Dashboard**: Verify stats and recent inspections fetch from Railway.
- [ ] **SPA Direct Navigation**: Open `https://your-domain.vercel.app/inspections` in a new tab — loads directly without 404.
- [ ] **Browser Refresh**: Press F5 on `/rules` and `/scanner` — page reloads successfully.
- [ ] **Image Capture / Upload**: Pick package image via file picker and submit for analysis.
- [ ] **Cloudinary Evidence**: Verify preprocessed crops display with Cloudinary CDN URLs (`https://res.cloudinary.com/...`).
- [ ] **Inspection Reports**: Download or preview DOCX report.
- [ ] **Mobile Android Preservation**: Confirm `flutter analyze` passes with 0 issues.
