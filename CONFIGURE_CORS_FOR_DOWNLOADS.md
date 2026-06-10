# Fix: Configure CORS on Firebase Storage Bucket

## Problem
Downloads are failing because Firebase bucket doesn't have CORS configured. This prevents the Fetch API from working.

## Solution: Configure CORS

### Method 1: Using Google Cloud SDK (Recommended)

1. **Install gsutil** (if not already installed):
   ```bash
   # On Windows
   gcloud init
   gcloud components install gsutil
   ```

2. **Create `cors.json` file:**
   
   Create a file named `cors.json` in your project root:
   
   ```json
   [
     {
       "origin": ["http://localhost:*", "https://straights-payroll.firebaseapp.com", "https://straights-payroll.web.app"],
       "method": ["GET", "HEAD", "DELETE"],
       "responseHeader": ["Content-Type", "Content-Disposition", "Access-Control-Allow-Origin"],
       "maxAgeSeconds": 3600
     }
   ]
   ```

3. **Get your Firebase Storage bucket name:**
   - Open [Firebase Console](https://console.firebase.google.com)
   - Go to **Storage**
   - Find your bucket name (looks like: `straights-payroll.appspot.com`)

4. **Apply CORS configuration:**
   ```bash
   gsutil cors set cors.json gs://straights-payroll.appspot.com
   ```

5. **Verify it was applied:**
   ```bash
   gsutil cors get gs://straights-payroll.appspot.com
   ```

### Method 2: Using Firebase Console (GUI)

Unfortunately, Firebase Console doesn't have a CORS configuration UI. You must use gsutil (Method 1).

---

## Complete Setup Steps

### Step 1: Install Google Cloud SDK
```bash
# Download from: https://cloud.google.com/sdk/docs/install
# Or if you have brew/chocolatey:
choco install google-cloud-sdk  # Windows

# Initialize
gcloud init
```

### Step 2: Authenticate with Google Cloud
```bash
gcloud auth login
# This opens a browser to log in with your Google account
```

### Step 3: Set your project
```bash
# Find your Firebase project ID (in Firebase Console)
gcloud config set project YOUR-PROJECT-ID

# Example:
gcloud config set project straights-payroll
```

### Step 4: Create cors.json
Save this file in your project root as `cors.json`:

```json
[
  {
    "origin": [
      "http://localhost:*",
      "http://127.0.0.1:*",
      "https://straights-payroll.firebaseapp.com",
      "https://straights-payroll.web.app"
    ],
    "method": ["GET", "HEAD", "DELETE"],
    "responseHeader": [
      "Content-Type",
      "Content-Disposition",
      "Access-Control-Allow-Origin",
      "Access-Control-Allow-Credentials"
    ],
    "maxAgeSeconds": 3600
  }
]
```

### Step 5: Find your bucket name
```bash
gsutil ls
# Output will show: gs://straights-payroll.appspot.com
```

### Step 6: Apply CORS
```bash
gsutil cors set cors.json gs://straights-payroll.appspot.com
```

### Step 7: Verify
```bash
gsutil cors get gs://straights-payroll.appspot.com
```

Should show your CORS configuration.

---

## Troubleshooting gsutil

### "gsutil: command not found"
```bash
# Make sure Google Cloud SDK is installed
gcloud --version

# If not installed, download from:
# https://cloud.google.com/sdk/docs/install
```

### "Permission denied" when setting CORS
```bash
# Make sure you're logged in and project is set
gcloud auth login
gcloud config set project YOUR-PROJECT-ID

# Check current project
gcloud config get-value project
```

### "Bucket not found"
```bash
# List all buckets to find the correct name
gsutil ls

# Use the exact name from the output
gsutil cors set cors.json gs://BUCKET-NAME-FROM-OUTPUT
```

---

## Testing CORS Configuration

### Test 1: In Browser Console

Open browser DevTools (F12) → Console and run:

```javascript
fetch('https://firebasestorage.googleapis.com/v0/b/straights-payroll.appspot.com/o/companies%2FANC%2Fdocuments%2F1779263058642%2Fbank_statement%2F1779263101958_com.microvirt.launcher2.png?alt=media&token=35bec08e-d9f3-45d3-82d6-3cc07f582a9b', {
  mode: 'cors'
})
.then(r => console.log('✅ CORS working! Status:', r.status))
.catch(e => console.error('❌ CORS issue:', e.message))
```

Expected output if CORS is fixed:
```
✅ CORS working! Status: 200
```

### Test 2: Try Download Again
1. Navigate to Manage Documents
2. Click download button on any document
3. Check browser console (F12)
4. You should see:
   ```
   📥 Downloading document: filename.png
   ✅ Fetch fetch successful, blob size: 12345
   ✅ Download triggered for: filename.png
   ```

---

## CORS Configuration Explained

Your `cors.json` allows:

| Setting | Meaning |
|---------|---------|
| `origin` | Websites that can access your storage (localhost and your Firebase domains) |
| `method` | HTTP methods allowed (GET to download, DELETE for cleanup) |
| `responseHeader` | Headers to include in response (tells browser it's OK to access) |
| `maxAgeSeconds` | How long browser caches the CORS policy (1 hour = 3600 seconds) |

---

## After CORS is Configured

Your app will use the improved download flow:

1. **Try Fetch API** (works with CORS) ✅
2. **Try XMLHttpRequest** (fallback if Fetch fails)
3. **Direct download** (final fallback, opens in new window)

Most downloads will use **Fetch API** once CORS is configured.

---

## Important Notes

- ⚠️ CORS configuration is **bucket-level** - applies to entire bucket
- ✅ Can take **1-2 minutes** to take effect after applying
- 🔄 You may need to **refresh the app** after CORS is configured
- 🌐 Configuration is permanent until you change it

---

## Complete Firebase Storage Rules

Make sure your `storage.rules` also allows authenticated reads:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to read/download documents
    match /companies/{companyId}/documents/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && isCompanyAdmin();
      allow delete: if request.auth != null && isCompanyAdmin();
    }
  }

  function isCompanyAdmin() {
    return true; // Simplify for now, implement proper checks
  }
}
```

Deploy:
```bash
firebase deploy --only storage
```

---

## Summary

1. **Install Google Cloud SDK**: `choco install google-cloud-sdk`
2. **Create cors.json**: (use template above)
3. **Apply CORS**: `gsutil cors set cors.json gs://YOUR-BUCKET-NAME`
4. **Verify**: `gsutil cors get gs://YOUR-BUCKET-NAME`
5. **Refresh app**: Force refresh browser (Ctrl+Shift+R)
6. **Test download**: Should now download file instead of opening it

That's it! Downloads should work properly after CORS is configured.
