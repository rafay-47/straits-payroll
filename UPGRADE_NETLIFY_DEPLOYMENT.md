# 🔄 Upgrade/Update Netlify Deployment

## Quick Update Commands

### Step 1: Rebuild with Latest Changes

```bash
cd /Users/mac/Documents/straights_psyroll

# Clean and rebuild
flutter clean
flutter pub get
flutter build web --release --web-renderer canvaskit
```

### Step 2: Redeploy to Netlify

Choose your deployment method:

---

## 🚀 Deployment Methods

### Method 1: Netlify CLI (Recommended - Fastest)

```bash
# Deploy to production
netlify deploy --prod --dir=build/web

# Or deploy as draft first (to test)
netlify deploy --dir=build/web
```

**Benefits:**
- ✅ Fast deployment
- ✅ Can preview before going live
- ✅ Automatic cache invalidation

---

### Method 2: Drag & Drop (Quick Update)

1. **Build** (use commands above)
2. **Go to** [Netlify Dashboard](https://app.netlify.com)
3. **Find your site** → Click on it
4. **Go to** "Deploys" tab
5. **Drag & drop** the `build/web` folder
6. ✅ **Deployed!**

---

### Method 3: Git Push (Automatic - Best for CI/CD)

If your site is connected to Git:

```bash
# Commit your changes
git add .
git commit -m "Update: [describe your changes]"
git push origin main  # or your branch name

# Netlify will automatically:
# 1. Detect the push
# 2. Build using netlify.toml settings
# 3. Deploy to production
```

**Benefits:**
- ✅ Automatic deployment
- ✅ Build history
- ✅ Rollback capability

---

## 📋 Complete Upgrade Workflow

### One-Line Command:

```bash
cd /Users/mac/Documents/straights_psyroll && flutter clean && flutter pub get && flutter build web --release --web-renderer canvaskit && netlify deploy --prod --dir=build/web
```

### Step-by-Step:

```bash
# 1. Navigate to project
cd /Users/mac/Documents/straights_psyroll

# 2. Clean previous build
flutter clean

# 3. Get latest dependencies
flutter pub get

# 4. Build for production
flutter build web --release --web-renderer canvaskit

# 5. Verify build
ls -la build/web/

# 6. Deploy to Netlify
netlify deploy --prod --dir=build/web
```

---

## 🔍 Verify Update

After deployment:

1. **Check Netlify Dashboard**:
   - Go to your site
   - Check "Deploys" tab
   - Verify latest deploy shows "Published"

2. **Test Your Site**:
   - Visit your Netlify URL
   - Hard refresh (Ctrl+Shift+R or Cmd+Shift+R)
   - Test all features

3. **Check Browser Console**:
   - Press F12
   - Look for any errors
   - Verify new features work

---

## 🎯 Quick Reference

### Build Only:
```bash
flutter clean && flutter pub get && flutter build web --release --web-renderer canvaskit
```

### Deploy Only (if already built):
```bash
netlify deploy --prod --dir=build/web
```

### Build + Deploy:
```bash
flutter clean && flutter pub get && flutter build web --release --web-renderer canvaskit && netlify deploy --prod --dir=build/web
```

---

## ⚠️ Important Notes

1. **Cache Clearing**: 
   - Netlify automatically clears HTML cache
   - Static assets (JS/CSS) are cached for performance
   - Hard refresh browser to see changes immediately

2. **Environment Variables**:
   - If you added new env vars, set them in Netlify dashboard
   - Site settings → Environment variables

3. **Build Time**:
   - First build: ~5-10 minutes
   - Subsequent builds: ~3-5 minutes
   - Depends on your code changes

4. **Rollback**:
   - If something breaks, you can rollback in Netlify dashboard
   - Deploys → Previous deploy → "Publish deploy"

---

## 🐛 Troubleshooting

### Build Fails:

```bash
# Check Flutter version
flutter --version

# Check dependencies
flutter pub get

# Try verbose build
flutter build web --release --web-renderer canvaskit --verbose
```

### Deploy Fails:

```bash
# Check Netlify CLI
netlify --version

# Re-login
netlify logout
netlify login

# Check site link
netlify status
```

### Site Shows Old Version:

1. **Clear browser cache** (hard refresh)
2. **Check Netlify deploy status** (should be "Published")
3. **Wait 1-2 minutes** for CDN propagation
4. **Check deploy logs** in Netlify dashboard

---

## ✅ Success Checklist

- [ ] Code changes committed
- [ ] Build successful (`build/web` exists)
- [ ] Deployed to Netlify
- [ ] Site accessible
- [ ] Features tested
- [ ] No console errors

---

## 🚀 Ready to Upgrade!

Just run:

```bash
cd /Users/mac/Documents/straights_psyroll
flutter clean && flutter pub get && flutter build web --release --web-renderer canvaskit
netlify deploy --prod --dir=build/web
```

Your updated dashboard will be live in a few minutes! 🎉
