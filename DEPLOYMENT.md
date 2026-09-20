# 🚀 FINORYX Deployment & Distribution Guide

This guide walks you through deploying the **Finoryx Backend** to cloud hosting (Render or Vercel), configuring your **Supabase Database**, and distributing the **Android APK** to friends for testing via direct download links.

---

## Part 1: Git Repository Setup (`benisontr/Finoryx`)

Run the following commands in the project root to initialize and push the repository to GitHub:

```bash
git init
git add .
git commit -m "feat: complete Finoryx core engine, UI modernization, test suites & CI/CD workflows"
git branch -M main
git remote add origin git@github.com:benisontr/Finoryx.git
git push -u origin main
```

---

## Part 2: Backend Cloud Deployment

### Option A: Deploy on Render (Recommended Free Tier)

Render runs standard Docker web services with automatic TLS (HTTPS) and auto-deploys upon every GitHub commit.

1. Go to [**Render.com**](https://render.com/) and Sign in with your GitHub account.
2. Click **New +** $\rightarrow$ **Blueprint** (or **Web Service**).
3. Connect your repository: **`benisontr/Finoryx`**.
4. Render will automatically detect the [`render.yaml`](./render.yaml) blueprint!
5. In the **Environment Variables** section, set your Supabase secrets:
   - `SUPABASE_URL`: `https://your-supabase-project.supabase.co`
   - `SUPABASE_ANON_KEY`: `eyJhbGciOi...`
   - `SUPABASE_SERVICE_ROLE_KEY`: `eyJhbGciOi...`
   - `SUPABASE_JWT_SECRET`: `your-supabase-jwt-secret`
   - `GEMINI_API_KEY`: `AIzaSy...` (from [Google AI Studio](https://aistudio.google.com/))
6. Click **Apply / Deploy**.
7. Once deployed, your backend URL will be: `https://finoryx-backend.onrender.com/api/v1`
8. Verify health status: `https://finoryx-backend.onrender.com/api/v1/health`

---

### Option B: Deploy on Vercel (Alternative Serverless)

1. Go to [**Vercel.com**](https://vercel.com/) and click **Add New...** $\rightarrow$ **Project**.
2. Select your repository: **`benisontr/Finoryx`**.
3. Set **Root Directory** to `apps/backend`.
4. Add the Environment Variables (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `GEMINI_API_KEY`, etc.).
5. Click **Deploy**.

---

## Part 3: Automated Android APK Distribution for Friends

You do **not** need to publish to the Google Play Store to share the app with friends. Every build is automatically compiled and hosted directly on GitHub!

### How to Generate the Downloadable APK

#### Method 1: Automatic Release Tag
1. Create a release tag and push it:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. GitHub Actions will automatically compile the APK and create a **GitHub Release**!
3. Go to `https://github.com/benisontr/Finoryx/releases`.
4. Right-click `finoryx-release.apk` and copy the link (e.g. `https://github.com/benisontr/Finoryx/releases/download/v1.0.0/finoryx-release.apk`).
5. Send this link to your friends via WhatsApp / Telegram!

#### Method 2: Manual Trigger via GitHub Actions UI
1. Go to your repo on GitHub: `https://github.com/benisontr/Finoryx/actions`.
2. Click **Mobile Release APK Builder** in the left sidebar.
3. Click **Run workflow** $\rightarrow$ **Run workflow**.
4. When finished (~3-4 minutes), click the completed run.
5. Under **Artifacts**, download `finoryx-android-release-apk.zip` containing `finoryx-release.apk`.

---

### How Friends Install the APK on Their Android Phones

Send your friends these simple 3-step instructions:

1. **Download**: Open the APK download link on your Android phone browser.
2. **Install**: Tap the downloaded `finoryx-release.apk` file to start installation.
3. **Allow Permission**: If your phone displays *"For your security, your phone is not allowed to install unknown apps from this source"*:
   - Tap **Settings**
   - Toggle ON **"Allow from this source"**
   - Tap **Install**
4. **Launch**: Open **Finoryx**, sign in or create an account, and start managing finances!

---

## Part 4: Production Checklist Summary

- [ ] Repository pushed to `github.com/benisontr/Finoryx`.
- [ ] Backend deployed on Render with `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and `GEMINI_API_KEY`.
- [ ] Mobile API base URL in `apps/mobile/lib/core/network/api_client.dart` updated with your live Render backend URL (`https://finoryx-backend.onrender.com/api/v1`).
- [ ] Android release APK generated via GitHub Actions and shared with tester group.
