#!/bin/bash
# n8n-vercel Deployment Verification Script
# ========================================
# Verify that all required configurations are in place for full functionality
#
# Usage: 
#   ./scripts/verify-deployment.sh          # Check configuration
#   ./scripts/verify-deployment.sh --local   # Check local development setup
#   ./scripts/verify-deployment.sh --vercel  # Check Vercel configuration (requires Vercel CLI)
#
# Exit codes:
#   0 - All checks passed
#   1 - Critical checks failed
#   2 - Warning checks failed

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

echo() {
    builtin echo "$@"
}

pass() {
    echo "  ${GREEN}✅ PASS${NC}: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo "  ${RED}❌ FAIL${NC}: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

warn() {
    echo "  ${YELLOW}⚠️  WARN${NC}: $1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

info() {
    echo "  ${BLUE}ℹ️  INFO${NC}: $1"
}

# Check if Vercel CLI is installed
VERCEL_CLI_INSTALLED=false
if command -v vercel >/dev/null 2>&1; then
    VERCEL_CLI_INSTALLED=true
fi

# Check if we're in the right directory
if [ ! -d ".git" ] || [ ! -f "Dockerfile" ] || [ ! -f "vercel.json" ]; then
    echo "${RED}❌ ERROR: Not in n8n-vercel repository${NC}"
    echo "Please cd to /home/tim/Fork/n8n-vercel and try again"
    exit 1
fi

echo "============================================"
echo "  n8n-vercel Deployment Verification"
echo "============================================"
echo

# Parse arguments
MODE="full"
if [ "$1" = "--local" ]; then
    MODE="local"
elif [ "$1" = "--vercel" ]; then
    MODE="vercel"
fi

# ============================================
# CHECK 1: Repository Configuration
# ============================================
echo "📁 CHECK 1: Repository Configuration"
echo "-----------------------------------"

# Check required files
REQUIRED_FILES=(
    "Dockerfile"
    "entrypoint.sh"
    "patch-fs.js"
    "patch-n8n-loading.js"
    "vercel.json"
    "docker-compose.yml"
    "Makefile"
    ".env.example"
    ".gitignore"
    "scripts/validate.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        pass "$file exists"
    else
        fail "$file is missing"
    fi
done

# Check no sensitive files in git
if git ls-files --error-unmatch .env .env.local .env.preview 2>/dev/null; then
    fail "Sensitive .env files are tracked by git"
else
    pass "No sensitive .env files in git"
fi

# Check .gitignore excludes .env files
if grep -q "^\.env$" .gitignore; then
    pass ".gitignore excludes .env files"
else
    warn ".gitignore may not properly exclude .env files"
fi

echo

# ============================================
# CHECK 2: Docker Configuration
# ============================================
echo "🐳 CHECK 2: Docker Configuration"
echo "-----------------------------------"

# Check Dockerfile has non-root user
if grep -q "n8nuser" Dockerfile; then
    pass "Dockerfile uses non-root user (n8nuser)"
else
    warn "Dockerfile may not have non-root user configured"
fi

# Check Dockerfile has security comment
if grep -q "TODO.*version" Dockerfile; then
    pass "Dockerfile has version check note"
else
    warn "Dockerfile missing version check note"
fi

# Check entrypoint.sh has user check
if grep -q "whoami" entrypoint.sh; then
    pass "Entrypoint has user context check"
else
    warn "Entrypoint missing user context check"
fi

# Check health check in Dockerfile
if grep -q "HEALTHCHECK" Dockerfile; then
    pass "Dockerfile has health check"
else
    fail "Dockerfile missing health check"
fi

echo

# ============================================
# CHECK 3: Docker Compose Configuration
# ============================================
echo "🐳 CHECK 3: Docker Compose Configuration"
echo "-----------------------------------"

# Check for resource limits
if grep -q "deploy:" docker-compose.yml && grep -q "limits:" docker-compose.yml; then
    pass "Docker compose has resource limits"
else
    warn "Docker compose may be missing resource limits"
fi

# Check for health checks
if grep -q "healthcheck:" docker-compose.yml; then
    pass "Docker compose has health checks"
else
    warn "Docker compose missing health checks"
fi

# Check for connection pooling
if grep -q "DB_POSTGRESDB_POOL" docker-compose.yml; then
    pass "Docker compose has connection pooling configuration"
else
    warn "Docker compose missing connection pooling"
fi

# Check n8n service exists
if grep -q "n8n:" docker-compose.yml; then
    pass "Docker compose has n8n service"
else
    fail "Docker compose missing n8n service"
fi

# Check postgres service exists
if grep -q "postgres:" docker-compose.yml; then
    pass "Docker compose has postgres service"
else
    warn "Docker compose missing postgres service"
fi

echo

# ============================================
# CHECK 4: Vercel Configuration
# ============================================
echo "☁️  CHECK 4: Vercel Configuration"
echo "-----------------------------------"

# Check vercel.json has health check
if grep -q "healthCheck" vercel.json; then
    pass "vercel.json has health check configuration"
else
    warn "vercel.json missing health check"
fi

# Check vercel.json framework
if grep -q '"framework": "container"' vercel.json; then
    pass "vercel.json has container framework"
else
    fail "vercel.json missing or incorrect framework"
fi

echo

# ============================================
# CHECK 5: Environment Configuration
# ============================================
echo "🌍 CHECK 5: Environment Configuration"
echo "-----------------------------------"

# Check .env.example exists
if [ -f ".env.example" ]; then
    pass ".env.example exists"
else
    fail ".env.example is missing"
fi

# Check .env.example has required variables
REQUIRED_VARS=(
    "N8N_PORT"
    "WEBHOOK_URL"
    "USE_POSTGRES"
    "DB_TYPE"
    "DB_POSTGRESDB_HOST"
    "DB_POSTGRESDB_DATABASE"
    "DB_POSTGRESDB_USER"
    "DB_POSTGRESDB_PASSWORD"
)

for var in "${REQUIRED_VARS[@]}"; do
    if grep -q "^$var=" .env.example; then
        pass "$var is in .env.example"
    else
        warn "$var not found in .env.example"
    fi
done

# Check .env.example has connection pooling
if grep -q "DB_POSTGRESDB_POOL" .env.example; then
    pass ".env.example has connection pooling variables"
else
    warn ".env.example missing connection pooling variables"
fi

# Check .env.example has security variables
if grep -q "N8N_BASIC_AUTH" .env.example && grep -q "N8N_ENCRYPTION_KEY" .env.example; then
    pass ".env.example has security variables"
else
    warn ".env.example missing security variables"
fi

echo

# ============================================
# CHECK 6: CI/CD Configuration
# ============================================
echo "🚀 CHECK 6: CI/CD Configuration"
echo "-----------------------------------"

# Check CI/CD workflow exists
if [ -f ".github/workflows/ci-cd.yml" ]; then
    pass "CI/CD workflow exists"
else
    fail "CI/CD workflow missing"
fi

# Check for preview deployment
if grep -q "Timothy191/palolo" .github/workflows/ci-cd.yml; then
    pass "CI/CD has preview deployment for palolo branch"
else
    warn "CI/CD may not have preview deployment for palolo"
fi

# Check for rollback job
if grep -q "rollback:" .github/workflows/ci-cd.yml; then
    pass "CI/CD has rollback job"
else
    warn "CI/CD missing rollback job"
fi

# Check for security scan
if grep -q "security-scan" .github/workflows/ci-cd.yml; then
    pass "CI/CD has security scanning"
else
    warn "CI/CD missing security scanning"
fi

echo

# ============================================
# CHECK 7: Scripts
# ============================================
echo "📝 CHECK 7: Scripts"
echo "-----------------------------------"

# Check validate.sh exists
if [ -f "scripts/validate.sh" ]; then
    pass "scripts/validate.sh exists"
else
    fail "scripts/validate.sh missing"
fi

# Check validate.sh is executable
if [ -x "scripts/validate.sh" ]; then
    pass "scripts/validate.sh is executable"
else
    warn "scripts/validate.sh is not executable"
fi

# Check entrypoint.sh is executable
if [ -x "entrypoint.sh" ]; then
    pass "entrypoint.sh is executable"
else
    fail "entrypoint.sh is not executable"
fi

echo

# ============================================
# CHECK 8: Local Development Test
# ============================================
echo "💻 CHECK 8: Local Development Setup"
echo "-----------------------------------"

# Only run if in local mode
if [ "$MODE" = "local" ] || [ "$MODE" = "full" ]; then
    # Check if .env.local exists
    if [ -f ".env.local" ]; then
        pass ".env.local exists for local development"
    else
        warn ".env.local not found - create from .env.example for local dev"
    fi

    # Check if docker is available
    if command -v docker >/dev/null 2>&1; then
        pass "Docker is installed"
    else
        warn "Docker is not installed - cannot test locally"
    fi

    # Check Makefile
    if command -v make >/dev/null 2>&1; then
        pass "make is available"
    else
        warn "make is not available"
    fi
fi

echo

# ============================================
# CHECK 9: Vercel Configuration (if CLI available)
# ============================================
echo "🔧 CHECK 9: Vercel Configuration"
echo "-----------------------------------"

if [ "$MODE" = "vercel" ] || [ "$MODE" = "full" ]; then
    if [ "$VERCEL_CLI_INSTALLED" = true ]; then
        info "Vercel CLI is installed"
        
        # Try to get project info
        if vercel inspect 2>/dev/null | grep -q "n8n-vercel"; then
            pass "Vercel project is configured"
        else
            warn "Cannot verify Vercel project configuration (not in project dir or not linked)"
        fi
        
        # Check if we can list environment variables
        info "To check Vercel environment variables, run:"
        info "  vercel env ls"
        
    else
        warn "Vercel CLI is not installed - cannot verify Vercel configuration"
        info "Install with: npm install -g vercel"
    fi
fi

echo

# ============================================
# SUMMARY
# ============================================
echo "============================================"
echo "  Verification Summary"
echo "============================================"
echo "  Passed: $PASS_COUNT"
echo "  Failed: $FAIL_COUNT"
echo "  Warnings: $WARN_COUNT"
echo

if [ $FAIL_COUNT -eq 0 ]; then
    if [ $WARN_COUNT -eq 0 ]; then
        echo "${GREEN}✅ ALL CHECKS PASSED!${NC}"
        echo ""
        echo "Your n8n-vercel project is configured for full functionality."
        echo ""
        if [ "$MODE" = "local" ]; then
            echo "Local development is ready. Run:"
            echo "  make validate && make dev"
        elif [ "$MODE" = "vercel" ]; then
            echo "Vercel configuration is ready."
        else
            echo "Everything is configured for deployment."
        fi
        exit 0
    else
        echo "${YELLOW}✅ ALL CRITICAL CHECKS PASSED (with warnings)${NC}"
        echo ""
        echo "Please review the warnings above."
        exit 0
    fi
else
    echo "${RED}❌ $FAIL_COUNT CRITICAL CHECKS FAILED${NC}"
    echo ""
    echo "Please fix the issues above before deployment."
    exit 1
fi
