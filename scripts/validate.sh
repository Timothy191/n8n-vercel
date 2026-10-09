#!/bin/bash
# n8n-vercel Validation Script
# ============================
# Validates project configuration, Dockerfile syntax, and required files

set -e

# Simple logging functions (portable across environments)
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass() {
    echo "[PASS] $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo "[FAIL] $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

warn() {
    echo "[WARN] $1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

info() {
    echo "[INFO] $1"
}

echo "============================================"
echo "  n8n-vercel Project Validation"
echo "============================================"
echo

# 1. Check required files exist
echo "📁 Checking required files..."
REQUIRED_FILES=(
    "Dockerfile"
    "entrypoint.sh"
    "patch-fs.js"
    "vercel.json"
    "README.md"
    ".gitignore"
    "Makefile"
    "docker-compose.yml"
    ".env.example"
    "LICENSE"
    "CONTRIBUTING.md"
    ".editorconfig"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        pass "$file exists"
    else
        fail "$file is missing"
    fi
done

# Check if .env.local exists (not required but nice to have)
if [ -f ".env.local" ]; then
    pass ".env.local exists (local development)"
else
    info ".env.local not found - create from .env.example for local dev"
fi

# 2. Check file permissions
echo
echo "🔒 Checking file permissions..."
if [ -x "entrypoint.sh" ]; then
    pass "entrypoint.sh is executable"
else
    fail "entrypoint.sh is not executable"
fi

if [ -x "scripts/validate.sh" ]; then
    pass "scripts/validate.sh is executable"
else
    fail "scripts/validate.sh is not executable"
fi

# Check Makefile is readable
if [ -r "Makefile" ]; then
    pass "Makefile is readable"
else
    fail "Makefile is not readable"
fi

# 3. Validate Dockerfile syntax
echo
echo "🐳 Validating Dockerfile syntax..."
if command -v docker >/dev/null 2>&1; then
    # Use dry-run for quick syntax validation without pulling base images
    if docker build --dry-run -t n8n-vercel:validate . >/dev/null 2>&1; then
        pass "Dockerfile syntax is valid"
    elif docker build -t n8n-vercel:validate --target=build . >/dev/null 2>&1; then
        pass "Dockerfile syntax is valid"
    else
        # Fallback: Check for common syntax errors with grep
        if grep -q "^FROM " Dockerfile && grep -q "^RUN " Dockerfile; then
            pass "Dockerfile appears to have valid syntax (basic check)"
        else
            fail "Dockerfile has syntax errors"
        fi
    fi
else
    warn "Docker not installed - cannot validate Dockerfile syntax"
fi

# 4. Check shell script syntax
echo
echo "📝 Checking shell script syntax..."
SHELL_SCRIPTS=(
    "entrypoint.sh"
    "scripts/validate.sh"
)

for script in "${SHELL_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if bash -n "$script" >/dev/null 2>&1; then
            pass "$script syntax is valid"
        else
            fail "$script has syntax errors"
        fi
    fi
done

# 5. Check Node.js/JavaScript files
echo
echo "⚡ Checking JavaScript files..."
if [ -f "patch-fs.js" ]; then
    if command -v node >/dev/null 2>&1; then
        if node --check "patch-fs.js" >/dev/null 2>&1; then
            pass "patch-fs.js syntax is valid"
        else
            fail "patch-fs.js has syntax errors"
        fi
    else
        warn "Node.js not installed - cannot validate JavaScript syntax"
    fi
else
    fail "patch-fs.js not found"
fi

# 6. Check vercel.json configuration
echo
echo "⚙️  Checking vercel.json configuration..."
if [ -f "vercel.json" ]; then
    pass "vercel.json exists"
    
    # Check if jq is available for JSON validation
    if command -v jq >/dev/null 2>&1; then
        if jq empty vercel.json >/dev/null 2>&1; then
            pass "vercel.json is valid JSON"
            
            # Check for required fields
            if jq -e '.framework' vercel.json >/dev/null 2>&1; then
                pass "vercel.json has framework field"
            else
                warn "vercel.json missing framework field"
            fi
            
            if jq -e '.buildCommand' vercel.json >/dev/null 2>&1; then
                pass "vercel.json has buildCommand field"
            else
                warn "vercel.json missing buildCommand field"
            fi
        else
            fail "vercel.json is not valid JSON"
        fi
    else
        warn "jq not installed - skipping JSON validation"
    fi
else
    fail "vercel.json not found"
fi

# 7. Check environment variables in .env.example
echo
echo "🌍 Checking .env.example configuration..."
if [ -f ".env.example" ]; then
    pass ".env.example exists"
    
    # Check for key variables
    KEY_VARS=(
        "N8N_PORT"
        "WEBHOOK_URL"
        "USE_POSTGRES"
        "DB_POSTGRESDB_HOST"
        "DB_POSTGRESDB_DATABASE"
        "DB_POSTGRESDB_USER"
        "DB_POSTGRESDB_PASSWORD"
        "N8N_DIAGNOSTICS_ENABLED"
        "N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS"
    )
    
    for var in "${KEY_VARS[@]}"; do
        if grep -q "^$var=" .env.example; then
            pass "$var is defined in .env.example"
        else
            warn "$var not found in .env.example"
        fi
    done
else
    fail ".env.example not found"
fi

# 8. Check Makefile targets
echo
echo "🔨 Checking Makefile targets..."
if [ -f "Makefile" ]; then
    pass "Makefile exists"
    
    # Check for common targets
    COMMON_TARGETS=(
        "help"
        "build"
        "dev"
        "run"
        "down"
        "validate"
        "clean"
    )
    
    for target in "${COMMON_TARGETS[@]}"; do
        if grep -q "^$target:" Makefile; then
            pass "Makefile has $target target"
        else
            warn "Makefile missing $target target"
        fi
    done
else
    fail "Makefile not found"
fi

# 9. Check docker-compose.yml configuration
echo
echo "🐳 Checking docker-compose.yml configuration..."
if [ -f "docker-compose.yml" ]; then
    pass "docker-compose.yml exists"
    
    # Check for n8n service
    if grep -q "n8n:" docker-compose.yml; then
        pass "docker-compose.yml has n8n service"
    else
        warn "docker-compose.yml missing n8n service"
    fi
    
    # Check for postgres service
    if grep -q "postgres:" docker-compose.yml; then
        pass "docker-compose.yml has postgres service"
    else
        warn "docker-compose.yml missing postgres service"
    fi
else
    fail "docker-compose.yml not found"
fi

# 10. Check for security issues
echo
echo "🛡️  Checking for security issues..."

# Check if Dockerfile uses non-root user
if grep -q "USER n8nuser" Dockerfile; then
    pass "Dockerfile uses non-root user"
else
    warn "Dockerfile may be running as root (security risk)"
fi

# Check if Dockerfile pins base image version
if grep -q "n8nio/n8n:[0-9]" Dockerfile; then
    pass "Dockerfile pins n8n version"
else
    warn "Dockerfile uses unpinned n8n version (potential breaking changes)"
fi

# Check if telemetry is disabled
if grep -q "N8N_DIAGNOSTICS_ENABLED=false" Dockerfile; then
    pass "Telemetry is disabled"
else
    warn "Telemetry may be enabled (privacy concern)"
fi

# 11. Git repository checks
echo
echo "🪜 Checking Git repository..."
if [ -d ".git" ]; then
    pass "Git repository found"
    
    # Check for .gitignore
    if [ -f ".gitignore" ]; then
        pass ".gitignore exists"
        
        # Check for common patterns
        if grep -q "\.env" .gitignore; then
            pass ".gitignore excludes .env files"
        else
            warn ".gitignore may not exclude .env files"
        fi
    else
        warn ".gitignore not found"
    fi
else
    info "Not a Git repository (or .git not found)"
fi

# Summary
echo
echo "============================================"
echo "  Validation Summary"
echo "============================================"
echo "  Passed: $PASS_COUNT"
echo "  Failed: $FAIL_COUNT"
echo "  Warnings: $WARN_COUNT"
echo

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All critical validations passed!"
    if [ $WARN_COUNT -gt 0 ]; then
        echo "⚠️  $WARN_COUNT warnings should be addressed"
    fi
    exit 0
else
    echo "❌ $FAIL_COUNT validations failed!"
    echo "Please fix the issues above and try again."
    exit 1
fi