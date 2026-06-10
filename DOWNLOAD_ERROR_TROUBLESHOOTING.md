# Download Error: TypeError - Failed to Fetch

## Issue
When clicking download, getting error: `TypeError: Failed to fetch`

## Root Causes & Solutions

### 1. **CORS Issue (Most Common)**
Firebase Storage requires proper CORS headers.

**Check your CORS configuration:**

```bash
gsutil cors get gs://your-bucket-name
```

**If CORS not set, create `cors.json`:**

```json
[
  {
    "origin": ["http://localhost:*", "https://*.firebaseapp.com", "https://yourdomain.com"],
    "method": ["GET", "HEAD", "DELETE"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"],
    "maxAgeSeconds": 3600
  }
]
```

**Apply CORS:**
```bash
gsutil cors set cors.json gs://your-bucket-name
```

### 2. **Firebase Security Rules Block Download**
Check `storage.rules` - rules might be too restrictive.

**Current rules likely require authentication:**
```
allow read: if request.auth != null
```

**For web downloads, ensure rules allow:**
```
allow read: if request.auth != null || isSignedUrl()
```

### 3. **Invalid or Expired URL**
Firebase Storage URLs can expire or be malformed.

**Check in browser console (F12 → Network):**
- Right-click document download button
- Inspect Element
- Go to Network tab
- Attempt download
- Look for the request
- Check response headers

**Look for:**
- 403 Forbidden - permissions issue
- 404 Not Found - URL invalid/expired
- CORS error - configuration issue

### 4. **Network/Connectivity Issue**
Internet connection or firewall blocking.

**Test:**
```javascript
// In browser console (F12)
fetch('https://your-storage-url/file.pdf')
  .then(r => console.log('Status:', r.status))
  .catch(e => console.error('Error:', e))
```

---

## Quick Fix Steps

### Step 1: Enable Proper CORS

```bash
# Create cors.json file
cat > cors.json << 'EOF'
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "DELETE"],
    "responseHeader": ["Content-Type"],
    "maxAgeSeconds": 3600
  }
]
EOF

# Apply to your Firebase bucket
gsutil cors set cors.json gs://your-firebase-project.appspot.com
```

### Step 2: Update Storage Rules

Edit `storage.rules`:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow reads for authenticated users
    match /{allPaths=**} {
      allow read: if request.auth != null;
    }
  }
}
```

Deploy:
```bash
firebase deploy --only storage
```

### Step 3: Test in Browser Console

Open browser DevTools (F12) → Console:

```javascript
// Test fetch with CORS
fetch('https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/path%2Fto%2Ffile.pdf?alt=media', {
  mode: 'cors',
  credentials: 'omit'
})
.then(r => {
  console.log('Status:', r.status);
  console.log('OK:', r.ok);
  return r.blob();
})
.then(blob => console.log('Blob size:', blob.size))
.catch(e => console.error('Fetch error:', e));
```

---

## Debugging Steps

### 1. Check Browser Console Errors
- Press **F12** in browser
- Go to **Console** tab
- Try downloading again
- Look for detailed error messages

### 2. Check Network Tab
- Open **F12** → **Network**
- Click download
- Find failed request
- Check:
  - Status code (should be 200)
  - Response headers (look for CORS headers)
  - Request headers (look for auth tokens)

### 3. Check Firebase Storage Rules
```bash
firebase storage:rules
```

Should allow reads for your users:
```
allow read: if request.auth != null;
```

### 4. Test Direct URL Access
Copy the document URL and paste in browser:
- If it opens/downloads → URL is valid
- If 403/404 → URL or permissions issue
- If CORS error → CORS not configured

---

## Code Update Applied ✅

Your download method now includes:
1. **Fetch API with CORS mode**: `{mode: 'cors', credentials: 'omit'}`
2. **Fallback to direct download**: If fetch fails, tries direct anchor element
3. **Debug logging**: Console logs show exact error and download progress
4. **Better error messages**: Shows what failed and why

**To debug:**
1. Open browser console (F12)
2. Attempt download
3. Check console for logs like:
   - `📥 Downloading document: filename.pdf`
   - `🔗 URL: https://...`
   - `❌ Fetch failed with status: 403` (permission error)
   - `⚠️ Fetch API error: TypeError: Failed to fetch` (CORS error)
   - `🔄 Trying direct download fallback...`

---

## Solution Matrix

| Error | Likely Cause | Fix |
|-------|--------------|-----|
| `TypeError: Failed to fetch` | CORS issue | Apply CORS config to bucket |
| `403 Forbidden` | Permission issue | Update storage.rules |
| `404 Not Found` | Invalid URL | Check document URL in Firestore |
| No error but no download | Fallback triggered | Check browser download folder |
| Empty file | Fetch succeeded but blob is empty | Check file in storage |

---

## Firebase Console Checklist

- [ ] Storage bucket accessible
- [ ] Files visible in Firebase Console Storage
- [ ] CORS configured on bucket
- [ ] Storage rules allow authenticated reads
- [ ] Firebase project has Storage enabled
- [ ] Web domain is whitelisted (if applicable)

---

## Testing

### Test 1: Direct Download
1. Go to Firebase Console → Storage
2. Find a document file
3. Click the file
4. Copy the download URL
5. Paste in browser address bar
6. If it downloads → URL is valid
7. If CORS error → Configure CORS

### Test 2: Fetch API
```javascript
// In browser console
const url = 'your-firebase-url-here';
fetch(url, {mode: 'cors'})
  .then(r => console.log('Fetch OK:', r.ok))
  .catch(e => console.error('Fetch failed:', e.message))
```

### Test 3: App Download
1. Navigate to Manage Documents
2. Open browser console (F12)
3. Click download on any document
4. Check console for logs
5. Verify file appears in Downloads folder

---

## Recommended Next Steps

1. **Enable detailed logging:**
   - Code already includes console.log statements
   - Check browser console for debug messages

2. **Configure CORS:**
   ```bash
   # Run this if CORS not already set
   gsutil cors set cors.json gs://your-project.appspot.com
   ```

3. **Verify Storage Rules:**
   ```bash
   firebase storage:get rules
   ```

4. **Test with simple file:**
   - Upload a small text file
   - Try to download
   - Should work immediately

---

## Additional Resources

- [Firebase CORS Guide](https://firebase.google.com/docs/storage/web/download-files#cors_configuration)
- [Storage Rules Documentation](https://firebase.google.com/docs/storage/security)
- [Browser Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API)
- [Firebase Storage Web Guide](https://firebase.google.com/docs/storage/web/start)
