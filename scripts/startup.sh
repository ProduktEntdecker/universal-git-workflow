#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 UNIVERSAL PROJECT STARTUP SCRIPT
# ═══════════════════════════════════════════════════════════════════════════════
# 
# Purpose: Intelligently initialize development sessions across any project type
# Author: Universal Git Workflow System
# Version: 2.0.0
# License: MIT
#
# This script automatically:
# • Detects your project type (Next.js, React, Node.js, Python, etc.)
# • Validates and installs dependencies
# • Starts required services (databases, Redis, dev servers)
# • Manages Git branches and pulls latest changes
# • Provides comprehensive project status and next steps
#
# Usage Examples:
#   startup                    # Basic session start on current branch
#   startup feature/auth       # Start on specific branch (creates if needed)
#   startup --fresh           # Fresh start with latest code and clean deps
#   startup --check           # Health check only, don't start services
#   startup --help            # Show detailed help information
#
# ═══════════════════════════════════════════════════════════════════════════════

# Enable strict error handling - script exits if any command fails
set -e

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🎨 VISUAL STYLING CONFIGURATION                                             │
# └─────────────────────────────────────────────────────────────────────────────┘

# Color codes for beautiful terminal output
readonly RED='\033[0;31m'      # For errors and warnings
readonly GREEN='\033[0;32m'    # For success messages
readonly BLUE='\033[0;34m'     # For information
readonly YELLOW='\033[1;33m'   # For progress updates
readonly PURPLE='\033[0;35m'   # For highlights
readonly CYAN='\033[0;36m'     # For secondary info
readonly NC='\033[0m'          # Reset to normal color

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ ⚙️ SCRIPT CONFIGURATION                                                     │
# └─────────────────────────────────────────────────────────────────────────────┘

readonly VERSION="2.0.0"
readonly SCRIPT_NAME="Universal Project Startup"
readonly SESSION_DATE=$(date "+%Y-%m-%d %H:%M:%S")
readonly TIMESTAMP=$(date "+%Y%m%d-%H%M%S")

# Configuration variables (can be overridden by environment)
BRANCH_NAME="${1:-}"                                    # Branch name from first argument
FRESH_START="${DEV_FRESH_START:-false}"                # Force fresh dependency install
HEALTH_CHECK_ONLY="${DEV_CHECK_ONLY:-false}"           # Only run health checks
SKIP_SERVICES="${DEV_SKIP_SERVICES:-false}"            # Skip service startup
SKIP_DEPS="${DEV_SKIP_DEPS:-false}"                    # Skip dependency installation
DEFAULT_BRANCH_PREFIX="${DEV_BRANCH_PREFIX:-feature/}" # Default prefix for new branches

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 📋 HELP AND VERSION INFORMATION                                             │
# └─────────────────────────────────────────────────────────────────────────────┘

show_help() {
    cat << EOF
🚀 Universal Project Startup Tool v${VERSION}

Initializes development sessions with environment setup, dependency management, and project status.

USAGE:
    startup [BRANCH_NAME] [OPTIONS]

ARGUMENTS:
    BRANCH_NAME         Optional: Create or switch to branch (default: current branch)

OPTIONS:
    -h, --help         Show this help message
    -v, --version      Show version information
    -c, --check        Only run health checks, don't start services
    -f, --fresh        Fresh start: pull latest, clean install dependencies
    -b, --branch NAME  Create new feature branch with specified name
    --skip-deps        Skip dependency installation
    --skip-services    Skip service startup (databases, Redis, etc.)

EXAMPLES:
    startup                              # Basic session start on current branch
    startup feature/auth-system          # Start session on specific branch
    startup -f                           # Fresh start with latest code
    startup -c                           # Health check only
    startup --branch user-management     # Create and switch to new branch

WHAT IT DOES:
    🔍 Project Detection    - Identifies project type and structure
    📋 Health Checks        - Verifies dependencies and environment
    🔀 Branch Management    - Creates/switches branches as needed
    📦 Dependencies         - Installs/updates project dependencies
    🏃 Service Startup      - Starts required services (DB, Redis, etc.)
    📊 Status Report        - Shows project status and next steps
    📝 Session Logging      - Creates startup log for reference

SUPPORTED PROJECT TYPES:
    • Next.js, React, Node.js (JavaScript/TypeScript)
    • Python (Django, Flask, FastAPI)
    • Rust (Cargo-based projects)
    • Go (Go modules)
    • Full-stack (Frontend + Backend)
    • Generic projects

REQUIREMENTS:
    • Git repository
    • Project dependencies defined (package.json, requirements.txt, etc.)
    • Optional: GitHub CLI for enhanced Git operations

EOF
}

show_version() {
    echo "${SCRIPT_NAME} v${VERSION}"
    echo "Compatible with: macOS, Linux, Windows (WSL)"
    echo "Supported shells: bash, zsh, fish"
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🔧 ARGUMENT PARSING                                                         │
# └─────────────────────────────────────────────────────────────────────────────┘

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        -c|--check)
            HEALTH_CHECK_ONLY=true
            shift
            ;;
        -f|--fresh)
            FRESH_START=true
            shift
            ;;
        -b|--branch)
            BRANCH_NAME="$2"
            shift 2
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --skip-services)
            SKIP_SERVICES=true
            shift
            ;;
        -*)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo "Use 'startup --help' for usage information."
            exit 1
            ;;
        *)
            # First non-option argument is branch name
            if [[ -z "$BRANCH_NAME" ]]; then
                BRANCH_NAME="$1"
            fi
            shift
            ;;
    esac
done

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🔍 PROJECT DETECTION FUNCTIONS                                              │
# └─────────────────────────────────────────────────────────────────────────────┘

# Detect the type of project we're working with
# This drives all subsequent behavior (dependencies, services, etc.)
detect_project_type() {
    # Full-stack projects (both frontend and backend directories)
    if [[ -d "frontend" && -d "backend" ]] || [[ -d "client" && -d "server" ]]; then
        echo "fullstack"
        return 0
    fi
    
    # JavaScript/TypeScript projects
    if [[ -f "package.json" ]]; then
        # Next.js projects
        if grep -q "next" package.json 2>/dev/null || [[ -f "next.config.js" ]] || [[ -f "next.config.ts" ]]; then
            echo "nextjs"
        # React projects  
        elif grep -q "react" package.json 2>/dev/null || [[ -d "src/components" ]]; then
            echo "react"
        # Node.js backend projects
        elif grep -q "express\|fastify\|koa" package.json 2>/dev/null; then
            echo "nodejs"
        else
            echo "javascript"
        fi
        return 0
    fi
    
    # Python projects
    if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "Pipfile" ]]; then
        if [[ -f "manage.py" ]] || grep -q "django" requirements.txt pyproject.toml 2>/dev/null; then
            echo "django"
        elif grep -q "flask" requirements.txt pyproject.toml 2>/dev/null; then
            echo "flask"
        elif grep -q "fastapi" requirements.txt pyproject.toml 2>/dev/null; then
            echo "fastapi"
        else
            echo "python"
        fi
        return 0
    fi
    
    # Rust projects
    if [[ -f "Cargo.toml" ]]; then
        echo "rust"
        return 0
    fi
    
    # Go projects
    if [[ -f "go.mod" ]] || [[ -f "go.sum" ]]; then
        echo "go"
        return 0
    fi
    
    # Java projects
    if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
        echo "java"
        return 0
    fi
    
    # Ruby projects
    if [[ -f "Gemfile" ]]; then
        echo "ruby"
        return 0
    fi
    
    # Default for unrecognized projects
    echo "generic"
}

# Check if required tools are available
check_dependencies() {
    local project_type="$1"
    local missing_deps=()
    
    echo -e "${BLUE}🔍 Checking system dependencies...${NC}"
    
    # Universal dependencies
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    # Project-specific dependencies
    case "$project_type" in
        "nextjs"|"react"|"nodejs"|"javascript"|"fullstack")
            if ! command -v node >/dev/null 2>&1; then
                missing_deps+=("node")
            fi
            if ! command -v npm >/dev/null 2>&1 && ! command -v yarn >/dev/null 2>&1; then
                missing_deps+=("npm or yarn")
            fi
            ;;
        "python"|"django"|"flask"|"fastapi")
            if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
                missing_deps+=("python3")
            fi
            if ! command -v pip >/dev/null 2>&1 && ! command -v pip3 >/dev/null 2>&1; then
                missing_deps+=("pip")
            fi
            ;;
        "rust")
            if ! command -v cargo >/dev/null 2>&1; then
                missing_deps+=("cargo (Rust toolchain)")
            fi
            ;;
        "go")
            if ! command -v go >/dev/null 2>&1; then
                missing_deps+=("go")
            fi
            ;;
        "java")
            if ! command -v java >/dev/null 2>&1; then
                missing_deps+=("java")
            fi
            if ! command -v mvn >/dev/null 2>&1 && ! command -v gradle >/dev/null 2>&1; then
                missing_deps+=("maven or gradle")
            fi
            ;;
        "ruby")
            if ! command -v ruby >/dev/null 2>&1; then
                missing_deps+=("ruby")
            fi
            if ! command -v bundle >/dev/null 2>&1; then
                missing_deps+=("bundler")
            fi
            ;;
    esac
    
    # Report missing dependencies
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "   ${RED}• ${dep}${NC}"
        done
        echo -e "${YELLOW}💡 Please install the missing dependencies and try again.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ All required dependencies are available${NC}"
    return 0
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🌿 GIT OPERATIONS                                                           │
# └─────────────────────────────────────────────────────────────────────────────┘

# Initialize or validate Git repository
init_git_repo() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${YELLOW}🔧 No Git repository found. Initializing...${NC}"
        git init
        
        # Create initial README if none exists
        if [[ ! -f "README.md" ]]; then
            local project_name=$(basename "$(pwd)")
            cat > README.md << EOF
# ${project_name}

## Getting Started

\`\`\`bash
# Start development session
startup

# End development session  
wrapup
\`\`\`

## Development

This project uses automated development workflows. Run \`startup\` to begin development and \`wrapup\` to end your session with proper documentation.
EOF
            git add README.md
            git commit -m "Initial commit with automated workflow setup"
        fi
        
        echo -e "${GREEN}✅ Git repository initialized${NC}"
    fi
}

# Handle branch operations
manage_branch() {
    local target_branch="$1"
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    
    # If no target branch specified, stay on current branch
    if [[ -z "$target_branch" ]]; then
        echo -e "${BLUE}🌿 Working on branch: ${current_branch}${NC}"
        return 0
    fi
    
    # Check if target branch exists
    if git show-ref --verify --quiet refs/heads/"$target_branch"; then
        echo -e "${BLUE}🔀 Switching to existing branch: ${target_branch}${NC}"
        git checkout "$target_branch"
    else
        echo -e "${BLUE}🆕 Creating new branch: ${target_branch}${NC}"
        git checkout -b "$target_branch"
    fi
    
    echo -e "${GREEN}✅ Branch ready: ${target_branch}${NC}"
}

# Pull latest changes if on tracking branch
sync_with_remote() {
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    # Check if we have a remote
    if ! git remote >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ No remote repository configured${NC}"
        return 0
    fi
    
    # Check if current branch tracks a remote branch
    if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
        echo -e "${BLUE}📥 Pulling latest changes...${NC}"
        if git pull; then
            echo -e "${GREEN}✅ Successfully synced with remote${NC}"
        else
            echo -e "${YELLOW}⚠️ Pull completed with conflicts - please resolve manually${NC}"
        fi
    else
        echo -e "${BLUE}ℹ️ Branch ${current_branch} is not tracking a remote branch${NC}"
    fi
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 📦 DEPENDENCY MANAGEMENT                                                    │
# └─────────────────────────────────────────────────────────────────────────────┘

# Install or update project dependencies
install_dependencies() {
    local project_type="$1"
    
    if [[ "$SKIP_DEPS" == "true" ]]; then
        echo -e "${BLUE}⏭️ Skipping dependency installation${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}📦 Managing dependencies...${NC}"
    
    case "$project_type" in
        "nextjs"|"react"|"nodejs"|"javascript")
            if [[ -f "package-lock.json" ]]; then
                if [[ "$FRESH_START" == "true" ]]; then
                    echo -e "${BLUE}🧹 Cleaning node_modules for fresh install...${NC}"
                    rm -rf node_modules package-lock.json
                    npm install
                else
                    npm ci 2>/dev/null || npm install
                fi
            elif [[ -f "yarn.lock" ]]; then
                if [[ "$FRESH_START" == "true" ]]; then
                    echo -e "${BLUE}🧹 Cleaning node_modules for fresh install...${NC}"
                    rm -rf node_modules yarn.lock
                    yarn install
                else
                    yarn install --frozen-lockfile 2>/dev/null || yarn install
                fi
            else
                npm install
            fi
            ;;
            
        "fullstack")
            # Handle both frontend and backend dependencies
            if [[ -d "frontend" && -f "frontend/package.json" ]]; then
                echo -e "${BLUE}📱 Installing frontend dependencies...${NC}"
                (cd frontend && npm install)
            fi
            if [[ -d "backend" && -f "backend/package.json" ]]; then
                echo -e "${BLUE}🖥️ Installing backend dependencies...${NC}"
                (cd backend && npm install)
            fi
            if [[ -d "client" && -f "client/package.json" ]]; then
                echo -e "${BLUE}📱 Installing client dependencies...${NC}"
                (cd client && npm install)
            fi
            if [[ -d "server" && -f "server/package.json" ]]; then
                echo -e "${BLUE}🖥️ Installing server dependencies...${NC}"
                (cd server && npm install)
            fi
            ;;
            
        "python"|"django"|"flask"|"fastapi")
            # Create virtual environment if it doesn't exist
            if [[ ! -d "venv" && ! -d ".venv" ]]; then
                echo -e "${BLUE}🐍 Creating Python virtual environment...${NC}"
                python3 -m venv venv 2>/dev/null || python -m venv venv
            fi
            
            # Activate virtual environment and install dependencies
            if [[ -d "venv" ]]; then
                source venv/bin/activate
            elif [[ -d ".venv" ]]; then
                source .venv/bin/activate
            fi
            
            if [[ -f "requirements.txt" ]]; then
                pip install -r requirements.txt
            elif [[ -f "pyproject.toml" ]]; then
                pip install -e .
            fi
            ;;
            
        "rust")
            if [[ "$FRESH_START" == "true" ]]; then
                cargo clean
            fi
            cargo build
            ;;
            
        "go")
            go mod download
            if [[ "$FRESH_START" == "true" ]]; then
                go clean -modcache
                go mod download
            fi
            ;;
            
        "java")
            if [[ -f "pom.xml" ]]; then
                mvn install -DskipTests
            elif [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
                ./gradlew build -x test 2>/dev/null || gradle build -x test
            fi
            ;;
            
        "ruby")
            bundle install
            ;;
            
        "generic")
            echo -e "${BLUE}ℹ️ Generic project - skipping automated dependency installation${NC}"
            ;;
    esac
    
    echo -e "${GREEN}✅ Dependencies ready${NC}"
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🏃 SERVICE MANAGEMENT                                                       │
# └─────────────────────────────────────────────────────────────────────────────┘

# Start required services for development
start_services() {
    local project_type="$1"
    
    if [[ "$SKIP_SERVICES" == "true" || "$HEALTH_CHECK_ONLY" == "true" ]]; then
        echo -e "${BLUE}⏭️ Skipping service startup${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}🚀 Starting development services...${NC}"
    
    # Check for common services that might be needed
    local services_started=()
    
    # Database services
    if [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.yaml" ]]; then
        echo -e "${BLUE}🐳 Starting Docker services...${NC}"
        docker-compose up -d 2>/dev/null || docker compose up -d 2>/dev/null || true
        services_started+=("Docker Compose")
    fi
    
    # Redis (common for caching and sessions)
    if command -v redis-server >/dev/null 2>&1; then
        if ! pgrep -x "redis-server" >/dev/null; then
            echo -e "${BLUE}🔴 Starting Redis server...${NC}"
            redis-server --daemonize yes 2>/dev/null || true
            services_started+=("Redis")
        fi
    fi
    
    # PostgreSQL (if commonly used)
    if command -v pg_ctl >/dev/null 2>&1; then
        if ! pgrep -x "postgres" >/dev/null; then
            echo -e "${BLUE}🐘 Starting PostgreSQL...${NC}"
            pg_ctl start -D /opt/homebrew/var/postgres 2>/dev/null || \
            pg_ctl start -D /usr/local/var/postgres 2>/dev/null || \
            sudo systemctl start postgresql 2>/dev/null || true
            services_started+=("PostgreSQL")
        fi
    fi
    
    # Project-specific services
    case "$project_type" in
        "nextjs")
            echo -e "${BLUE}▲ Next.js development server will be started with: npm run dev${NC}"
            ;;
        "react")  
            echo -e "${BLUE}⚛️ React development server will be started with: npm start${NC}"
            ;;
        "django")
            if [[ -d "venv" ]]; then source venv/bin/activate; fi
            echo -e "${BLUE}🌟 Django development server will be started with: python manage.py runserver${NC}"
            ;;
        "flask"|"fastapi")
            if [[ -d "venv" ]]; then source venv/bin/activate; fi
            echo -e "${BLUE}🌶️ Python web server ready - use your usual start command${NC}"
            ;;
    esac
    
    if [[ ${#services_started[@]} -gt 0 ]]; then
        echo -e "${GREEN}✅ Services started: ${services_started[*]}${NC}"
    else
        echo -e "${BLUE}ℹ️ No background services required${NC}"
    fi
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 📊 STATUS REPORTING                                                         │
# └─────────────────────────────────────────────────────────────────────────────┘

# Display comprehensive project status
show_project_status() {
    local project_type="$1"
    local project_name=$(basename "$(pwd)")
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    
    echo
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}🎯 SESSION READY - PROJECT STATUS${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${CYAN}📁 Project:${NC}     ${project_name}"
    echo -e "${CYAN}🔧 Type:${NC}        ${project_type}"
    echo -e "${CYAN}🌿 Branch:${NC}      ${current_branch}"
    echo -e "${CYAN}📅 Started:${NC}     ${SESSION_DATE}"
    echo
    
    # Show Git status
    echo -e "${BLUE}📊 Git Status:${NC}"
    git status --porcelain | head -5 | while read -r line; do
        echo -e "   ${YELLOW}${line}${NC}"
    done
    
    if [[ -z "$(git status --porcelain)" ]]; then
        echo -e "   ${GREEN}✅ Working directory clean${NC}"
    fi
    
    echo
    
    # Show recommended next steps
    echo -e "${BLUE}🚀 Next Steps:${NC}"
    case "$project_type" in
        "nextjs")
            echo -e "   ${GREEN}• Run:${NC} npm run dev ${CYAN}(Start Next.js development server)${NC}"
            echo -e "   ${GREEN}• Visit:${NC} http://localhost:3000 ${CYAN}(View your application)${NC}"
            ;;
        "react")
            echo -e "   ${GREEN}• Run:${NC} npm start ${CYAN}(Start React development server)${NC}"
            echo -e "   ${GREEN}• Visit:${NC} http://localhost:3000 ${CYAN}(View your application)${NC}"
            ;;
        "nodejs")
            echo -e "   ${GREEN}• Run:${NC} npm run dev ${CYAN}(Start Node.js server with hot reload)${NC}"
            echo -e "   ${GREEN}• Or:${NC} node index.js ${CYAN}(Start server normally)${NC}"
            ;;
        "django")
            echo -e "   ${GREEN}• Run:${NC} python manage.py runserver ${CYAN}(Start Django server)${NC}"
            echo -e "   ${GREEN}• Visit:${NC} http://localhost:8000 ${CYAN}(View your application)${NC}"
            ;;
        "fullstack")
            echo -e "   ${GREEN}• Frontend:${NC} cd frontend && npm run dev"
            echo -e "   ${GREEN}• Backend:${NC} cd backend && npm run dev"
            ;;
        *)
            echo -e "   ${GREEN}• Start your development server according to project documentation${NC}"
            ;;
    esac
    
    echo -e "   ${GREEN}• When done:${NC} wrapup ${CYAN}(End session with documentation)${NC}"
    echo
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}💚 Ready to code! Happy development! 🚀${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════${NC}"
    echo
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🎬 MAIN EXECUTION FLOW                                                      │
# └─────────────────────────────────────────────────────────────────────────────┘

main() {
    # Show startup banner
    echo -e "${BLUE}🚀 ${SCRIPT_NAME} v${VERSION}${NC}"
    echo -e "${PURPLE}Session Date: ${SESSION_DATE}${NC}"
    echo
    
    # Step 1: Initialize Git repository if needed
    init_git_repo
    
    # Step 2: Detect project type
    echo -e "${YELLOW}🔍 Detecting project type...${NC}"
    local project_type=$(detect_project_type)
    echo -e "${GREEN}✅ Project type: ${project_type}${NC}"
    echo
    
    # Step 3: Check system dependencies
    if ! check_dependencies "$project_type"; then
        exit 1
    fi
    echo
    
    # Step 4: Handle branch management
    if [[ -n "$BRANCH_NAME" ]]; then
        manage_branch "$BRANCH_NAME"
    else
        echo -e "${BLUE}🌿 Working on current branch: $(git rev-parse --abbrev-ref HEAD)${NC}"
    fi
    echo
    
    # Step 5: Sync with remote if fresh start requested
    if [[ "$FRESH_START" == "true" ]]; then
        sync_with_remote
        echo
    fi
    
    # Step 6: Install dependencies
    install_dependencies "$project_type"
    echo
    
    # Step 7: Start services (unless health check only)
    start_services "$project_type"
    echo
    
    # Step 8: Show final status and next steps
    show_project_status "$project_type"
    
    # Create session log for reference
    {
        echo "# Development Session Started"
        echo "Date: ${SESSION_DATE}"
        echo "Project Type: ${project_type}"
        echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
        echo "Arguments: $*"
        echo
        echo "Use 'wrapup' to end this session properly."
    } > ".dev-session-${TIMESTAMP}.log"
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🏁 SCRIPT ENTRY POINT                                                       │
# └─────────────────────────────────────────────────────────────────────────────┘

# Only run main function if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi