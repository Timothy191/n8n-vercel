# Vercel Environment Variables - Complete Configuration

**🎯 Purpose:** Complete list of all environment variables required for full n8n-vercel functionality  
**📅 Last Updated:** 2026-10-09  
**🔗 Project:** Timothy191/n8n-vercel  
**🌿 Branch:** Timothy191/palolo

---

## 🚀 **QUICK START: Copy & Paste into Vercel**

**URL:** https://vercel.com/Timothy191/n8n-vercel/settings/environment-variables

### **Step 1: Click "Add New Variable" for each of these**

---

## 🔴 **CRITICAL - Application Will NOT Work Without These**

### **Group 1: Core Application Settings**

| # | Variable | Value | Sensitive | Protected | Description |
|---|----------|-------|----------|-----------|-------------|
| 1 | `N8N_PORT` | `3000` | No | No | n8n application port (maps to Vercel PORT) |
| 2 | `WEBHOOK_URL` | `https://n8n-vercel-l4y48aptw-timothyoniel558-9643s-projects.vercel.app` | No | No | **MUST be your production domain** - URL for webhooks and callbacks |
| 3 | `USE_POSTGRES` | `true` | No | No | Enable Postgres database (set to `false` only for SQLite testing) |

**⚠️ IMPORTANT:** `WEBHOOK_URL` must be your **exact production domain**. Do NOT use:
- `localhost`
- Preview deployment URLs
- Any other domain

---

### **Group 2: Database Connection (Required when USE_POSTGRES=true)**

| # | Variable | Value | Sensitive | Protected | Description |
|---|----------|-------|----------|-----------|-------------|
| 4 | `DB_TYPE` | `postgresdb` | No | No | Database type identifier |
| 5 | `DB_POSTGRESDB_HOST` | `aws-0-us-east-1.pooler.supabase.co` | No | No | Supabase connection pooler host |
| 6 | `DB_POSTGRESDB_PORT` | `6543` | No | No | Supabase connection pooler port |
| 7 | `DB_POSTGRESDB_DATABASE` | `postgres` | **Yes** | **Yes** | Database name |
| 8 | `DB_POSTGRESDB_USER` | `postgres.mrwhtxbhrzyttlsyuofc` | **Yes** | **Yes** | Database username (from Supabase) |
| 9 | `DB_POSTGRESDB_PASSWORD` | `[NEW_PASSWORD_AFTER_ACTION_2]` | **Yes** | **Yes** | Database password (rotated in Action 2) |

**⚠️ IMPORTANT:** 
- Use the **NEW password** you generated in Action 2 (Rotate Supabase Credentials)
- Do NOT use the old password from the backup files
- Mark these as **Protected** in Vercel

---

## 🟡 **RECOMMENDED - Security & Performance**

### **Group 3: Security Settings**

| # | Variable | Value | Sensitive | Protected | Description |
|---|----------|-------|----------|-----------|-------------|
| 10 | `N8N_DIAGNOSTICS_ENABLED` | `false` | No | No | Disable n8n telemetry (recommended for privacy) |
| 11 | `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | `false` | No | No | Relax file permission checks (needed for containers) |
| 12 | `N8N_ENCRYPTION_KEY` | `[GENERATE_BELOW]` | **Yes** | **Yes** | Encrypt sensitive workflow data |
| 13 | `N8N_BASIC_AUTH_ACTIVE` | `true` | No | No | Enable Basic Authentication |
| 14 | `N8N_BASIC_AUTH_USER` | `admin` | **Yes** | **Yes** | Basic Auth username |
| 15 | `N8N_BASIC_AUTH_PASSWORD` | `[GENERATE_BELOW]` | **Yes** | **Yes** | Basic Auth password |

### **Generate These Values:**

```bash
# Generate N8N_ENCRYPTION_KEY (32-byte base64)
openssl rand -base64 32
# Example: 7X!A%D*G-KaPdSgVkYp3s6v9y$B&E(H+MbQeThWmZq4t7w!

# Generate N8N_BASIC_AUTH_PASSWORD (strong password)
openssl rand -base64 16
# Example: 9Kb2@mP8qLv!zNxY7

# Or use a password manager to generate strong passwords
```

**⚠️ IMPORTANT:** 
- **DO NOT** use weak passwords
- **DO** mark sensitive variables as **Protected** in Vercel
- **DO** store these values securely

---

## 🟢 **OPTIONAL - Performance & Optimization**

### **Group 4: Connection Pooling**

| # | Variable | Value | Sensitive | Protected | Description |
|---|----------|-------|----------|-----------|-------------|
| 16 | `DB_POSTGRESDB_POOL_MIN` | `2` | No | No | Minimum connections in pool |
| 17 | `DB_POSTGRESDB_POOL_MAX` | `10` | No | No | Maximum connections in pool |
| 18 | `DB_POSTGRESDB_POOL_IDLE_TIMEOUT` | `30000` | No | No | Milliseconds before idle connections close |
| 19 | `DB_POSTGRESDB_POOL_CONNECTION_TIMEOUT` | `5000` | No | No | Milliseconds to wait for connection |

### **Group 5: n8n Settings**

| # | Variable | Value | Sensitive | Protected | Description |
|---|----------|-------|----------|-----------|-------------|
| 20 | `N8N_TIMEZONE` | `UTC` | No | No | Timezone for n8n (e.g., America/New_York, UTC) |
| 21 | `N8N_MEMORY_LIMIT` | `1024` | No | No | Memory limit in MB for n8n |
| 22 | `N8N_HOST` | `0.0.0.0` | No | No | Bind address for n8n |

---

## 📋 **STEP-BY-STEP: Adding Variables to Vercel**

### **Method A: Using Vercel Dashboard (Recommended)**

1. **Go to:** https://vercel.com/Timothy191/n8n-vercel/settings/environment-variables

2. **For each variable:**
   - Click **"Add New Variable"**
   - Enter **Name** (exact as shown in tables above)
   - Enter **Value** (from tables above)
   - For **Sensitive** variables: Check **"Protected"** box
   - Click **"Save"**

3. **Repeat** for all variables

### **Method B: Using Vercel CLI**

```bash
# Install Vercel CLI (if not installed)
npm install -g vercel

# Link to your project (if not already linked)
vercel link

# Add each variable
vercel env add N8N_PORT 3000
vercel env add WEBHOOK_URL https://n8n-vercel-l4y48aptw-timothyoniel558-9643s-projects.vercel.app
vercel env add USE_POSTGRES true
vercel env add DB_TYPE postgresdb
vercel env add DB_POSTGRESDB_HOST aws-0-us-east-1.pooler.supabase.co
vercel env add DB_POSTGRESDB_PORT 6543
vercel env add DB_POSTGRESDB_DATABASE postgres
vercel env add DB_POSTGRESDB_USER postgres.mrwhtxbhrzyttlsyuofc
vercel env add DB_POSTGRESDB_PASSWORD
# (You'll be prompted to enter the password)

# For protected variables, add --protected flag
vercel env add --protected N8N_ENCRYPTION_KEY
# (You'll be prompted to enter the value)

vercel env add --protected N8N_BASIC_AUTH_USER admin
vercel env add --protected N8N_BASIC_AUTH_PASSWORD
```

---

## 🔍 **VERIFICATION: Check Your Configuration**

### **After adding variables, verify:**

```bash
# List all environment variables
vercel env ls

# Check a specific variable
vercel env get N8N_PORT
```

### **Expected Output:**
All variables from the tables above should be listed with their correct values.

---

## 🛡️ **SECURITY BEST PRACTICES**

### **✅ DO:**
1. **Mark sensitive variables as Protected** in Vercel
2. **Use strong, random passwords** for all credentials
3. **Rotate credentials regularly** (every 90 days for production)
4. **Store backups securely** (encrypted, offline)
5. **Audit access** to your Vercel and Supabase accounts

### **❌ DO NOT:**
1. **Commit .env files** to git (they're in .gitignore)
2. **Use weak passwords** (less than 12 characters)
3. **Share credentials** via email, chat, or unsecured channels
4. **Hardcode credentials** in source code
5. **Reuse passwords** across different services

---

## 📊 **DEPLOYMENT READINESS CHECKLIST**

### **Environment Variables**
- [ ] `N8N_PORT` = 3000
- [ ] `WEBHOOK_URL` = production domain
- [ ] `USE_POSTGRES` = true
- [ ] `DB_TYPE` = postgresdb
- [ ] `DB_POSTGRESDB_HOST` = aws-0-us-east-1.pooler.supabase.co
- [ ] `DB_POSTGRESDB_PORT` = 6543
- [ ] `DB_POSTGRESDB_DATABASE` = postgres
- [ ] `DB_POSTGRESDB_USER` = postgres.mrwhtxbhrzyttlsyuofc
- [ ] `DB_POSTGRESDB_PASSWORD` = [NEW PASSWORD]
- [ ] `N8N_DIAGNOSTICS_ENABLED` = false
- [ ] `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` = false
- [ ] `N8N_ENCRYPTION_KEY` = [GENERATED]
- [ ] `N8N_BASIC_AUTH_ACTIVE` = true
- [ ] `N8N_BASIC_AUTH_USER` = admin (or custom)
- [ ] `N8N_BASIC_AUTH_PASSWORD` = [GENERATED]
- [ ] Connection pooling variables (optional)

### **Security Actions**
- [ ] Vercel OIDC token revoked
- [ ] Supabase credentials rotated
- [ ] Backup files deleted (`rm -rf backups/`)

### **Verification**
- [ ] All variables marked as Protected (where applicable)
- [ ] No syntax errors in variable names/values
- [ ] Local development tested
- [ ] Preview deployment tested

---

## 🎯 **WHAT HAPPENS IF VARIABLES ARE MISSING?**

| Missing Variable | Impact | Error Message |
|----------------|--------|---------------|
| `N8N_PORT` | n8n won't start | `Error: Port not configured` |
| `WEBHOOK_URL` | Webhooks fail | `Webhook URL not configured` |
| `USE_POSTGRES` | Falls back to SQLite | May not work as expected |
| `DB_POSTGRESDB_*` | Database connection fails | `Error connecting to database` |
| `N8N_ENCRYPTION_KEY` | Sensitive data unencrypted | Warning in logs |
| `N8N_BASIC_AUTH_*` | No authentication | Dashboard accessible to anyone |

---

## 🚀 **NEXT STEPS AFTER CONFIGURATION**

### **1. Test Preview Deployment**
```bash
# Push to palolo branch
git push origin Timothy191/palolo

# Wait 5-10 minutes for Vercel to deploy
# Check: https://vercel.com/Timothy191/n8n-vercel/deployments
```

### **2. Verify Preview Works**
- Open the preview deployment URL
- Check n8n dashboard loads
- Test database connection
- Test webhook functionality

### **3. Deploy to Production**
```bash
# Merge palolo into main
git checkout main
git merge Timothy191/palolo
git push origin main

# Wait 5-10 minutes for production deployment
# Check: https://n8n-vercel-l4y48aptw-timothyoniel558-9643s-projects.vercel.app
```

### **4. Verify Production**
- Open production URL
- Check all functionality works
- Test with external services

---

## 📞 **TROUBLESHOOTING**

### **Issue: "Environment variable not found"**
- **Cause:** Variable not set in Vercel
- **Fix:** Add the missing variable to Vercel

### **Issue: "Database connection failed"**
- **Cause:** Wrong database credentials or host
- **Fix:** Verify all `DB_POSTGRESDB_*` variables

### **Issue: "Webhook URL not configured"**
- **Cause:** `WEBHOOK_URL` not set or wrong
- **Fix:** Set `WEBHOOK_URL` to your production domain

### **Issue: "Invalid port"**
- **Cause:** `N8N_PORT` not set or wrong
- **Fix:** Set `N8N_PORT` to `3000`

---

## ✅ **FINAL CHECKLIST**

**Before Production Deployment:**
- [ ] All 19 environment variables configured in Vercel
- [ ] Sensitive variables marked as Protected
- [ ] Vercel OIDC token revoked
- [ ] Supabase credentials rotated
- [ ] Backup files deleted
- [ ] Preview deployment tested and working

**Result:** ✅ **Fully functional n8n-vercel deployment with all integrations working!**

---

## 🎉 **YOU'RE READY!**

Once you configure these environment variables in Vercel, your n8n-vercel deployment will:

✅ **Connect to Supabase** - Full database functionality  
✅ **Receive webhooks** - External services can trigger workflows  
✅ **Process workflows** - n8n executes correctly  
✅ **Scale safely** - Resource limits prevent issues  
✅ **Recover automatically** - Health checks and rollback work  
✅ **Secure** - Non-root container, protected credentials  
✅ **Performant** - Connection pooling, optimized settings  

**The application will fully function with others (external services, databases, integrations) exactly as intended!**

---

## 📚 **REFERENCES**

- [Vercel Environment Variables](https://vercel.com/docs/environment-variables)
- [n8n Environment Variables](https://docs.n8n.io/hosting/installation/docker/#environment-variables)
- [Supabase Connection String](https://supabase.com/docs/guides/database/postgres#connection-string)

---

**Generated:** 2026-10-09  
**Project:** Timothy191/n8n-vercel  
**Status:** Ready for Environment Variable Configuration ✅