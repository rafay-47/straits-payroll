# 🚀 Netlify Deployment Guide for Flutter Web Dashboard

## 📋 Prerequisites

1. **Flutter SDK** installed (version 3.6.2 or higher)
2. **Netlify account** (free tier works fine)
3. **Git repository** (GitHub, GitLab, or Bitbucket)

---

## 🔧 Step 1: Build Flutter Web App Locally

### Option A: Standard Build (Recommended)

```bash
# Navigate to project directory
cd /Users/mac/Documents/straights_psyroll

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web (production release)
flutter build web --release --web-renderer canvaskit
```

**Output Location**: `build/web/`

### Option B: Build with Custom Base URL (if needed)

If your app will be deployed to a subdirectory:

```bash
flutter build web --release --web-renderer canvaskit --base-href="/your-subdirectory/"
```

### Option C: Build with HTML Renderer (Smaller size, less features)

For smaller bundle size (may have compatibility issues):

```bash
flutter build web --release --web-renderer html
```

**Note**: CanvasKit renderer is recommended for better compatibility and features.

---

## 📦 Step 2: Verify Build Output

After building, verify the output:

```bash
# Check build directory exists
ls -la build/web/

# Expected files:
# - index.html
# - main.dart.js
# - assets/
# - canvaskit/ (if using CanvasKit renderer)
# - flutter_bootstrap.js
```

---

## 🌐 Step 3: Deploy to Netlify

### Method 1: Netlify CLI (Recommended)

#### Install Netlify CLI:

```bash
# Install globally via npm
npm install -g netlify-cli

# Or via Homebrew (macOS)
brew install netlify-cli
```

#### Login to Netlify:

```bash
netlify login
```

#### Deploy:

```bash
# Navigate to project root
cd /Users/mac/Documents/straights_psyroll

# Deploy build/web directory
netlify deploy --prod --dir=build/web

# Or for draft/preview deployment
netlify deploy --dir=build/web
```

**First Time Setup:**
```bash
# Link to existing site or create new
netlify init

# Follow prompts:
# - Create & configure a new site
# - Team: Select your team
# - Site name: straights-payroll (or your choice)
# - Build command: flutter build web --release --web-renderer canvaskit
# - Publish directory: build/web
```

---

### Method 2: Netlify Web UI (Git-based)

1. **Push code to Git repository**:
   ```bash
   git add .
   git commit -m "Prepare for Netlify deployment"
   git push origin main
   ```

2. **Connect to Netlify**:
   - Go to [Netlify Dashboard](https://app.netlify.com)
   - Click "Add new site" → "Import an existing project"
   - Connect your Git provider (GitHub/GitLab/Bitbucket)
   - Select your repository

3. **Configure Build Settings**:
   - **Build command**: `flutter build web --release --web-renderer canvaskit`
   - **Publish directory**: `build/web`
   - **Base directory**: (leave empty)

4. **Environment Variables** (if needed):
   - Go to Site settings → Environment variables
   - Add any Firebase config or API keys if required

5. **Deploy**:
   - Click "Deploy site"
   - Netlify will automatically build and deploy

---

### Method 3: Drag & Drop (Quick Test)

1. **Build locally**:
   ```bash
   flutter build web --release --web-renderer canvaskit
   ```

2. **Go to Netlify Dashboard**:
   - Visit [app.netlify.com](https://app.netlify.com)
   - Drag and drop the `build/web` folder

3. **Your site is live!**

---

## ⚙️ Step 4: Configure Netlify Settings

### Build Settings (Already in `netlify.toml`):

Your `netlify.toml` is already configured with:
- ✅ Build command
- ✅ Publish directory
- ✅ SPA redirects
- ✅ Security headers
- ✅ Cache headers

### Additional Settings (Optional):

#### Custom Domain:
1. Go to Site settings → Domain management
2. Add your custom domain
3. Follow DNS configuration instructions

#### Environment Variables:
If you need Firebase config or other secrets:

```bash
# Via CLI
netlify env:set FIREBASE_API_KEY "your-key"
netlify env:set FIREBASE_PROJECT_ID "your-project-id"

# Or via Web UI:
# Site settings → Environment variables → Add variable
```

#### Build Hooks:
For CI/CD automation:
- Site settings → Build & deploy → Build hooks
- Create a build hook URL
- Use it in your CI/CD pipeline

---

## 🔍 Step 5: Verify Deployment

### Check Build Logs:

```bash
# View recent deployments
netlify deploy:list

# View logs for specific deploy
netlify deploy:log
```

### Test Your Site:

1. Visit your Netlify URL: `https://your-site-name.netlify.app`
2. Check browser console (F12) for errors
3. Test all features:
   - Login
   - Dashboard
   - All admin functions

---

## 🐛 Troubleshooting

### Build Fails:

**Error**: Flutter not found
```bash
# Ensure Flutter is in PATH
export PATH="$PATH:/path/to/flutter/bin"
# Or add to ~/.zshrc or ~/.bashrc
```

**Error**: Dependencies not found
```bash
flutter clean
flutter pub get
flutter build web --release --web-renderer canvaskit
```

### Site Shows Blank Page:

1. **Check browser console** for errors
2. **Verify redirects** are working (check `netlify.toml`)
3. **Check base href** in `index.html`
4. **Verify Firebase config** is correct

### Routes Not Working:

Ensure `netlify.toml` has the SPA redirect:
```toml
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### Large Bundle Size:

- Use CanvasKit renderer (already configured)
- Enable compression in Netlify settings
- Check for unnecessary dependencies

---

## 📊 Quick Reference Commands

### Build Commands:

```bash
# Clean build
flutter clean && flutter pub get && flutter build web --release --web-renderer canvaskit

# Build with verbose output
flutter build web --release --web-renderer canvaskit --verbose

# Build with analysis
flutter build web --release --web-renderer canvaskit --analyze-size
```

### Netlify CLI Commands:

```bash
# Login
netlify login

# Deploy production
netlify deploy --prod --dir=build/web

# Deploy draft
netlify deploy --dir=build/web

# View site
netlify open:site

# View admin
netlify open:admin

# View logs
netlify logs

# List sites
netlify sites:list
```

---

## 🎯 Complete Deployment Workflow

### One-Time Setup:

```bash
# 1. Install Netlify CLI
npm install -g netlify-cli

# 2. Login
netlify login

# 3. Initialize (if not using Git)
netlify init
```

### Every Deployment:

```bash
# 1. Build
cd /Users/mac/Documents/straights_psyroll
flutter clean
flutter pub get
flutter build web --release --web-renderer canvaskit

# 2. Deploy
netlify deploy --prod --dir=build/web

# 3. Verify
netlify open:site
```

---

## 📝 Environment Variables (If Needed)

If your app needs environment variables, add them in Netlify:

**Via CLI:**
```bash
netlify env:set FIREBASE_API_KEY "your-key"
netlify env:set FIREBASE_PROJECT_ID "your-project-id"
netlify env:set FIREBASE_AUTH_DOMAIN "your-domain"
```

**Via Web UI:**
- Site settings → Environment variables
- Add each variable

**Access in Flutter:**
```dart
// Use from environment or Firebase config
final apiKey = const String.fromEnvironment('FIREBASE_API_KEY');
```

---

## ✅ Deployment Checklist

- [ ] Flutter SDK installed and in PATH
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Build successful (`flutter build web`)
- [ ] `build/web` directory contains files
- [ ] Netlify account created
- [ ] Netlify CLI installed (optional)
- [ ] Site connected to Git (if using Git)
- [ ] Build settings configured
- [ ] Environment variables set (if needed)
- [ ] Site deployed and accessible
- [ ] All features tested on deployed site

---

## 🚀 Quick Start (Copy & Paste)

```bash
# Navigate to project
cd /Users/mac/Documents/straights_psyroll

# Build
flutter clean && flutter pub get && flutter build web --release --web-renderer canvaskit

# Deploy (if Netlify CLI installed)
netlify deploy --prod --dir=build/web

# Or drag & drop build/web folder to Netlify dashboard
```

---

## 📚 Additional Resources

- [Netlify Documentation](https://docs.netlify.com/)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Netlify CLI Reference](https://cli.netlify.com/)

---

## 🎉 Success!

Once deployed, your Flutter web dashboard will be accessible at:
- **Netlify URL**: `https://your-site-name.netlify.app`
- **Custom Domain**: `https://your-domain.com` (if configured)

Your `netlify.toml` is already configured with all necessary settings for optimal performance and security! 🚀
