#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 UNIVERSAL PROJECT WRAPUP SCRIPT
# ═══════════════════════════════════════════════════════════════════════════════
# 
# Purpose: Professionally conclude development sessions with comprehensive handovers
# Author: Universal Git Workflow System
# Version: 2.0.0
# License: MIT
#
# This script automatically:
# • Cleans up temporary files and build artifacts
# • Commits all changes with descriptive messages
# • Creates pull requests with detailed descriptions
# • Generates comprehensive handover documentation
# • Extracts and lists all TODOs from the codebase
# • Updates project documentation and timestamps
#
# Usage Examples:
#   wrapup                         # Basic wrap-up with auto-generated branch/PR
#   wrapup feature/auth            # Custom branch name
#   wrapup feature/auth "Add login system"  # Custom branch + PR title
#   wrapup --help                  # Show detailed help information
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
readonly SCRIPT_NAME="Universal Project Wrapup"
readonly SESSION_DATE=$(date "+%Y-%m-%d %H:%M:%S")
readonly TIMESTAMP=$(date "+%Y%m%d-%H%M%S")

# Configuration variables (can be overridden by environment)
BRANCH_NAME="${1:-}"                                    # Branch name from first argument
PR_TITLE="${2:-}"                                      # PR title from second argument
SKIP_PR="${DEV_SKIP_PR:-false}"                        # Skip PR creation
SKIP_CLEANUP="${DEV_SKIP_CLEANUP:-false}"              # Skip file cleanup
DEFAULT_BRANCH_PREFIX="${DEV_BRANCH_PREFIX:-feature/session-}" # Default prefix for new branches
HANDOVER_FILE="${DEV_HANDOVER_FILE:-HANDOVER.md}"      # Name of handover document

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 📋 HELP AND VERSION INFORMATION                                             │
# └─────────────────────────────────────────────────────────────────────────────┘

show_help() {
    cat << EOF
🎯 Universal Project Wrapup Script v${VERSION}

Professionally concludes development sessions with comprehensive cleanup and documentation.

USAGE:
    wrapup [BRANCH_NAME] [PR_TITLE] [OPTIONS]

ARGUMENTS:
    BRANCH_NAME    Optional: Name for feature branch (default: auto-generated)
    PR_TITLE       Optional: Title for pull request (default: auto-generated)

OPTIONS:
    -h, --help      Show this help message
    -v, --version   Show version information
    --no-pr         Skip pull request creation
    --no-cleanup    Skip file cleanup
    --dry-run       Show what would be done without making changes

EXAMPLES:
    wrapup                                    # Basic wrap-up with auto-generated names
    wrapup feature/user-auth                  # Custom branch name
    wrapup feature/auth "Add authentication"  # Custom branch and PR title
    wrapup --no-pr                           # Commit changes but skip PR creation

WHAT IT DOES:
    🧹 File Cleanup       - Removes temporary files and build artifacts
    📚 Documentation      - Updates README timestamps and project docs
    💾 Git Operations     - Commits all changes with descriptive messages
    🔀 Pull Request       - Creates PR with comprehensive description
    📄 Handover Doc       - Generates detailed HANDOVER.md with project status
    🔍 TODO Extraction    - Finds and lists all TODOs in the codebase
    📊 Project Analysis   - Analyzes changes and provides session summary

GENERATED FILES:
    HANDOVER.md           - Comprehensive handover document
    .wrapup-session.log   - Session log for reference

REQUIREMENTS:
    • Git repository with changes to commit
    • Git user configuration (name and email)
    • GitHub CLI (gh) for automatic PR creation (optional)

EOF
}

show_version() {
    echo "${SCRIPT_NAME} v${VERSION}"
    echo "Compatible with: macOS, Linux, Windows (WSL)"
    echo "Supported project types: Next.js, React, Node.js, Python, Rust, Go, Java, Ruby, and more"
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
        --no-pr)
            SKIP_PR=true
            shift
            ;;
        --no-cleanup)
            SKIP_CLEANUP=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -*)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo "Use 'wrapup --help' for usage information."
            exit 1
            ;;
        *)
            # First argument is branch name, second is PR title
            if [[ -z "$BRANCH_NAME" ]]; then
                BRANCH_NAME="$1"
            elif [[ -z "$PR_TITLE" ]]; then
                PR_TITLE="$1"
            fi
            shift
            ;;
    esac
done

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🔍 PROJECT DETECTION FUNCTIONS                                              │
# └─────────────────────────────────────────────────────────────────────────────┘

# Detect the type of project we're working with (same logic as startup script)
detect_project_type() {
    # Full-stack projects (both frontend and backend directories)
    if [[ -d "frontend" && -d "backend" ]] || [[ -d "client" && -d "server" ]]; then
        echo "fullstack"
        return 0
    fi
    
    # JavaScript/TypeScript projects
    if [[ -f "package.json" ]]; then
        if grep -q "next" package.json 2>/dev/null || [[ -f "next.config.js" ]] || [[ -f "next.config.ts" ]]; then
            echo "nextjs"
        elif grep -q "react" package.json 2>/dev/null || [[ -d "src/components" ]]; then
            echo "react"
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
    
    # Other project types
    if [[ -f "Cargo.toml" ]]; then echo "rust"; return 0; fi
    if [[ -f "go.mod" ]]; then echo "go"; return 0; fi
    if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then echo "java"; return 0; fi
    if [[ -f "Gemfile" ]]; then echo "ruby"; return 0; fi
    
    echo "generic"
}

# Get project information for documentation
get_project_info() {
    PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
    PROJECT_TYPE=$(detect_project_type)
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    REPO_URL=$(git config --get remote.origin.url 2>/dev/null || echo "No remote repository")
    GIT_USER=$(git config user.name 2>/dev/null || echo "Unknown Developer")
    
    # Try to get current version from package.json or other version files
    if [[ -f "package.json" ]]; then
        PROJECT_VERSION=$(grep '"version"' package.json | sed 's/.*"version": "\([^"]*\)".*/\1/' 2>/dev/null || echo "1.0.0")
    elif [[ -f "Cargo.toml" ]]; then
        PROJECT_VERSION=$(grep '^version' Cargo.toml | sed 's/version = "\([^"]*\)"/\1/' 2>/dev/null || echo "1.0.0")
    elif [[ -f "pyproject.toml" ]]; then
        PROJECT_VERSION=$(grep '^version' pyproject.toml | sed 's/version = "\([^"]*\)"/\1/' 2>/dev/null || echo "1.0.0")
    else
        PROJECT_VERSION="1.0.0"
    fi
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🧹 FILE CLEANUP FUNCTIONS                                                   │
# └─────────────────────────────────────────────────────────────────────────────┘

# Intelligently clean up project-specific temporary files and build artifacts
cleanup_project_files() {
    local project_type="$1"
    
    if [[ "$SKIP_CLEANUP" == "true" ]]; then
        echo -e "${BLUE}⏭️ Skipping file cleanup${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}🧹 Cleaning up project files...${NC}"
    
    # Universal cleanup (applies to all project types)
    find . -name ".DS_Store" -type f -delete 2>/dev/null || true
    find . -name "Thumbs.db" -type f -delete 2>/dev/null || true
    find . -name "*.log" -type f -not -path "./.git/*" -delete 2>/dev/null || true
    find . -name "*.tmp" -type f -delete 2>/dev/null || true
    
    # Project-specific cleanup
    case "$project_type" in
        "nextjs"|"react"|"nodejs"|"javascript"|"fullstack")
            # Node.js cleanup
            rm -rf .next/ 2>/dev/null || true
            rm -rf dist/ 2>/dev/null || true
            rm -rf build/ 2>/dev/null || true
            find . -name "node_modules" -type d -exec rm -rf {}/\.cache 2>/dev/null \; || true
            
            # Clean up frontend/backend if fullstack
            if [[ "$project_type" == "fullstack" ]]; then
                rm -rf frontend/.next/ frontend/dist/ frontend/build/ 2>/dev/null || true
                rm -rf backend/dist/ backend/build/ 2>/dev/null || true
                rm -rf client/.next/ client/dist/ client/build/ 2>/dev/null || true
                rm -rf server/dist/ server/build/ 2>/dev/null || true
            fi
            ;;
            
        "python"|"django"|"flask"|"fastapi")
            # Python cleanup
            find . -name "*.pyc" -delete 2>/dev/null || true
            find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
            find . -name "*.pyo" -delete 2>/dev/null || true
            rm -rf .pytest_cache/ 2>/dev/null || true
            rm -rf .coverage 2>/dev/null || true
            rm -rf htmlcov/ 2>/dev/null || true
            ;;
            
        "rust")
            # Rust cleanup - be careful not to remove the entire target directory
            rm -rf target/debug/incremental/ 2>/dev/null || true
            rm -rf target/release/incremental/ 2>/dev/null || true
            ;;
            
        "go")
            # Go cleanup
            go clean -cache 2>/dev/null || true
            ;;
            
        "java")
            # Java cleanup
            rm -rf target/ 2>/dev/null || true
            rm -rf build/ 2>/dev/null || true
            find . -name "*.class" -delete 2>/dev/null || true
            ;;
            
        "ruby")
            # Ruby cleanup
            rm -rf tmp/ 2>/dev/null || true
            ;;
    esac
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 📚 DOCUMENTATION FUNCTIONS                                                  │
# └─────────────────────────────────────────────────────────────────────────────┘

# Update project documentation with current timestamp
update_documentation() {
    echo -e "${YELLOW}📚 Updating documentation...${NC}"
    
    # Update README.md if it exists
    if [[ -f "README.md" ]]; then
        # Add or update last updated timestamp
        if grep -q "Last updated:" README.md; then
            sed -i.bak "s/Last updated:.*/Last updated: ${SESSION_DATE}/" README.md
            rm README.md.bak 2>/dev/null || true
        else
            echo "" >> README.md
            echo "*Last updated: ${SESSION_DATE}*" >> README.md
        fi
    fi
    
    echo -e "${BLUE}📦 Current Version: ${PROJECT_VERSION}${NC}"
    echo -e "${GREEN}✅ Documentation updated${NC}"
}

# Extract all TODO comments from the codebase
extract_todos() {
    echo -e "${BLUE}🔍 Extracting TODOs from codebase...${NC}"
    
    # Common TODO patterns in different comment styles
    local todo_patterns=(
        "TODO"
        "FIXME" 
        "HACK"
        "XXX"
        "BUG"
        "NOTE"
    )
    
    local todos_found=()
    
    # Search for TODOs in common source files
    for pattern in "${todo_patterns[@]}"; do
        while IFS= read -r line; do
            [[ -n "$line" ]] && todos_found+=("$line")
        done < <(grep -rn "$pattern" . \
            --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" \
            --include="*.py" --include="*.java" --include="*.rs" --include="*.go" \
            --include="*.rb" --include="*.php" --include="*.cpp" --include="*.c" \
            --include="*.h" --include="*.hpp" --include="*.vue" --include="*.svelte" \
            --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist \
            --exclude-dir=build --exclude-dir=target --exclude-dir=.next \
            2>/dev/null | head -20)
    done
    
    if [[ ${#todos_found[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Found ${#todos_found[@]} TODOs/notes in codebase${NC}"
        return 0
    else
        echo -e "${GREEN}No TODOs found - great job!${NC}"
        return 1
    fi
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🔍 CHANGE ANALYSIS                                                          │
# └─────────────────────────────────────────────────────────────────────────────┘

# Analyze what changes were made during the session
analyze_changes() {
    echo -e "${YELLOW}📊 Analyzing changed files...${NC}"
    
    # Count different types of changes
    local staged_files=$(git diff --cached --name-only | wc -l | xargs)
    local unstaged_files=$(git diff --name-only | wc -l | xargs)
    local untracked_files=$(git ls-files --others --exclude-standard | wc -l | xargs)
    
    echo -e "${BLUE}📈 Changes Summary:${NC}"
    echo -e "  • Staged files:        ${staged_files}"
    echo -e "  • Unstaged files:        ${unstaged_files}"
    echo -e "  • Untracked files:        ${untracked_files}"
    
    # Store change summary for later use
    CHANGES_SUMMARY="$((staged_files + unstaged_files + untracked_files)) files changed"
    
    return 0
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 📄 HANDOVER DOCUMENT GENERATION                                             │
# └─────────────────────────────────────────────────────────────────────────────┘

# Generate comprehensive handover documentation
generate_handover_document() {
    echo -e "${YELLOW}📄 Creating handover document...${NC}"
    
    # Create comprehensive handover document
    cat > "$HANDOVER_FILE" << EOF
# Development Session Handover

**Project:** ${PROJECT_NAME}  
**Session Date:** ${SESSION_DATE}  
**Developer:** ${GIT_USER}  
**Branch:** ${CURRENT_BRANCH}  
**Project Type:** ${PROJECT_TYPE}  
**Version:** ${PROJECT_VERSION}

## 🎯 Session Summary

Development session completed on ${SESSION_DATE}. This handover document provides a comprehensive overview of the work completed, current project status, and next steps for continuing development.

**Key Changes:** ${CHANGES_SUMMARY}

## 📝 Changes Made

### Modified Files
\`\`\`
$(git diff --name-only HEAD | head -10)
$(git ls-files --others --exclude-standard | head -5)
\`\`\`

### Git Status
\`\`\`
$(git status --porcelain)
\`\`\`

## 🔗 Pull Request

$(if [[ "$SKIP_PR" != "true" && -n "$PR_URL" ]]; then
    echo "- **Status:** Created and ready for review"
    echo "- **URL:** $PR_URL"
    echo "- **Title:** $PR_TITLE"
else
    echo "- **Status:** No pull request created in this session"
    echo "- **Next Step:** Run \`gh pr create\` to create pull request manually"
fi)

## 📋 Outstanding TODOs

$(if extract_todos >/dev/null 2>&1; then
    echo "The following TODOs were found in the codebase:"
    echo "\`\`\`"
    extract_todos 2>/dev/null | head -10
    echo "\`\`\`"
else
    echo "✅ No outstanding TODOs found in the codebase."
fi)

## 🏗 Current Project Architecture

**Project Type:** ${PROJECT_TYPE}

$(case "$PROJECT_TYPE" in
    "nextjs")
        echo "- **Framework:** Next.js with React"
        echo "- **Build System:** Next.js built-in"
        echo "- **Development:** \`npm run dev\` on port 3000"
        ;;
    "react")
        echo "- **Framework:** React"  
        echo "- **Build System:** Create React App or Vite"
        echo "- **Development:** \`npm start\` on port 3000"
        ;;
    "nodejs")
        echo "- **Runtime:** Node.js"
        echo "- **Framework:** Express.js or similar"
        echo "- **Development:** \`npm run dev\` or \`node index.js\`"
        ;;
    "python")
        echo "- **Language:** Python 3.x"
        echo "- **Framework:** Django, Flask, or FastAPI"
        echo "- **Development:** Virtual environment recommended"
        ;;
    "fullstack")
        echo "- **Architecture:** Full-stack application"
        echo "- **Frontend:** Located in frontend/ or client/"
        echo "- **Backend:** Located in backend/ or server/"
        ;;
    *)
        echo "- **Type:** $PROJECT_TYPE"
        echo "- **Structure:** Standard project layout"
        ;;
esac)

### Key Directories
\`\`\`
$(ls -la | grep "^d" | head -10)
\`\`\`

## ⚡ Next Steps

### Immediate Actions
1. **Code Review:** Review and merge any pending pull requests
2. **Testing:** Run test suite to ensure all changes work correctly
3. **Documentation:** Update any relevant documentation for new features

### Development Environment Setup
\`\`\`bash
# Clone repository (if needed)
git clone ${REPO_URL}
cd ${PROJECT_NAME}

# Install dependencies
$(case "$PROJECT_TYPE" in
    "nextjs"|"react"|"nodejs"|"javascript")
        echo "npm install          # Install Node.js dependencies"
        echo "npm run dev         # Start development server"
        ;;
    "python")
        echo "python3 -m venv venv # Create virtual environment"
        echo "source venv/bin/activate  # Activate virtual environment" 
        echo "pip install -r requirements.txt  # Install Python dependencies"
        ;;
    "rust")
        echo "cargo build         # Build Rust project"
        echo "cargo run          # Run the application"
        ;;
    "go")
        echo "go mod download    # Download Go dependencies"
        echo "go run main.go     # Run the application"
        ;;
    *)
        echo "# Follow project-specific setup instructions"
        ;;
esac)

# Start development session
startup

# End development session
wrapup
\`\`\`

### Future Enhancements
- [ ] Review and implement any TODOs listed above
- [ ] Consider adding automated testing if not present
- [ ] Update documentation for new features
- [ ] Performance optimization review
- [ ] Security audit for production readiness

## 📊 Project Statistics

- **Repository:** ${REPO_URL}
- **Last Commit:** \`$(git log -1 --pretty=format:"%h - %s (%cr)" 2>/dev/null || echo "No commits yet")\`
- **Branch Status:** ${CURRENT_BRANCH}
- **Files Changed:** ${CHANGES_SUMMARY}

## 🚀 Development Workflow

This project uses automated development workflows:

- **Start Session:** \`startup [branch-name]\`
- **End Session:** \`wrapup [branch-name] [pr-title]\`
- **Health Check:** \`startup --check\`
- **Fresh Start:** \`startup --fresh\`

## 📞 Contact & Support

**Developer:** ${GIT_USER}  
**Session Completed:** ${SESSION_DATE}

---

*This handover document was automatically generated by the Universal Git Workflow System v${VERSION}*  
*For questions about this workflow, refer to the project documentation or contact the development team.*
EOF

    echo -e "${GREEN}✅ Handover document created: ${HANDOVER_FILE}${NC}"
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🔀 GIT OPERATIONS                                                           │
# └─────────────────────────────────────────────────────────────────────────────┘

# Commit all changes with a comprehensive commit message
commit_changes() {
    echo -e "${YELLOW}💾 Committing changes...${NC}"
    
    # Stage all changes
    git add -A
    
    # Check if there are any changes to commit
    if git diff --cached --quiet; then
        echo -e "${BLUE}ℹ️ No changes to commit${NC}"
        return 0
    fi
    
    # Generate commit message
    local commit_message="Session: ${SESSION_DATE} - ${CHANGES_SUMMARY}

Development session completed with the following changes:
$(git diff --cached --name-only | head -5 | sed 's/^/- /')

Generated handover document: ${HANDOVER_FILE}
Project type: ${PROJECT_TYPE}
Branch: ${CURRENT_BRANCH}

🤖 Generated with Universal Git Workflow v${VERSION}"

    # Commit the changes
    git commit -m "$commit_message"
    
    echo -e "${GREEN}✅ Changes committed${NC}"
}

# Create a pull request with comprehensive description
create_pull_request() {
    if [[ "$SKIP_PR" == "true" ]]; then
        echo -e "${BLUE}⏭️ Skipping pull request creation${NC}"
        return 0
    fi
    
    # Check if GitHub CLI is available
    if ! command -v gh >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ GitHub CLI (gh) not found. Skipping PR creation.${NC}"
        echo -e "${BLUE}💡 Install GitHub CLI to enable automatic PR creation: https://cli.github.com${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}🔀 Creating pull request...${NC}"
    
    # Generate branch name if not provided
    if [[ -z "$BRANCH_NAME" ]]; then
        BRANCH_NAME="${DEFAULT_BRANCH_PREFIX}${TIMESTAMP}"
    fi
    
    # Generate PR title if not provided  
    if [[ -z "$PR_TITLE" ]]; then
        PR_TITLE="Development Session: ${SESSION_DATE}"
    fi
    
    # Create new branch if we're on main/master
    if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
        echo -e "${BLUE}📝 Creating new branch for changes...${NC}"
        git checkout -b "$BRANCH_NAME"
        git push -u origin "$BRANCH_NAME" 2>/dev/null || true
    fi
    
    # Create PR with comprehensive description
    local pr_description="## 🎯 Session Summary

Development session completed on ${SESSION_DATE} for project **${PROJECT_NAME}**.

### 📊 Changes Overview
- **Project Type:** ${PROJECT_TYPE}
- **Files Modified:** ${CHANGES_SUMMARY}
- **Developer:** ${GIT_USER}

### 📝 What was done
$(git log --oneline -5 | head -3)

### 🔍 Files Changed
$(git diff --name-only HEAD~1 | head -8 | sed 's/^/- /')

### 📄 Documentation
- Generated comprehensive handover document: \`${HANDOVER_FILE}\`
- Updated project documentation timestamps
- Extracted and documented any TODOs found

### ✅ Next Steps
1. Review the changes in this PR
2. Check the generated handover document for context
3. Test the changes in a development environment
4. Merge when ready

### 🤖 Automation
This PR was created automatically using the Universal Git Workflow System v${VERSION}.
See \`${HANDOVER_FILE}\` for detailed session information and next steps.

---

*Session completed: ${SESSION_DATE}*"

    # Create the pull request
    if PR_URL=$(gh pr create --title "$PR_TITLE" --body "$pr_description" 2>/dev/null); then
        echo -e "${GREEN}✅ Pull request created: ${PR_URL}${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to create pull request: $(gh pr create --title "$PR_TITLE" --body "$pr_description" 2>&1 || echo "Unknown error")${NC}"
        return 1
    fi
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 📊 FINAL SUMMARY                                                            │
# └─────────────────────────────────────────────────────────────────────────────┘

# Show final summary of the wrapup session
show_final_summary() {
    echo
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}✨ SESSION WRAPUP COMPLETED${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${CYAN}📁 Project:${NC}        ${PROJECT_NAME}"
    echo -e "${CYAN}🔧 Type:${NC}           ${PROJECT_TYPE}" 
    echo -e "${CYAN}🌿 Branch:${NC}         ${CURRENT_BRANCH}"
    echo -e "${CYAN}👨‍💻 Developer:${NC}      ${GIT_USER}"
    echo -e "${CYAN}📅 Completed:${NC}      ${SESSION_DATE}"
    echo
    echo -e "${GREEN}📄 Handover document: ${HANDOVER_FILE}${NC}"
    
    if [[ -n "$PR_URL" ]]; then
        echo -e "${GREEN}🔀 Pull request: ${PR_URL}${NC}"
    else
        echo -e "${YELLOW}🔀 Pull request: ${SKIP_PR:+Skipped}${SKIP_PR:-No PR created}${NC}"
    fi
    
    echo
    echo -e "${BLUE}💡 Next developer can use this handover to continue development${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════${NC}"
    echo
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🎬 MAIN EXECUTION FLOW                                                      │
# └─────────────────────────────────────────────────────────────────────────────┘

main() {
    # Show startup banner
    echo -e "${BLUE}🎯 ${SCRIPT_NAME} v${VERSION}${NC}"
    echo -e "${PURPLE}Session Date: ${SESSION_DATE}${NC}"
    
    # Validate we're in a Git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${RED}❌ Error: Not in a git repository${NC}"
        echo -e "${BLUE}💡 Initialize with: git init${NC}"
        exit 1
    fi
    
    # Step 1: Get project information
    get_project_info
    echo -e "${BLUE}📁 Project: ${PROJECT_NAME}${NC}"
    echo -e "${BLUE}🌿 Current Branch: ${CURRENT_BRANCH}${NC}"
    echo -e "${BLUE}🔧 Project Type: ${PROJECT_TYPE}${NC}"
    
    # Step 2: Show what we're about to do
    echo -e "${PURPLE}🎯 Starting comprehensive project wrap-up for ${PROJECT_NAME}${NC}"
    
    # Step 3: Clean up project files
    cleanup_project_files "$PROJECT_TYPE"
    
    # Step 4: Update documentation
    update_documentation
    
    # Step 5: Analyze changes
    analyze_changes
    
    # Step 6: Generate handover document (before committing so it gets included)
    generate_handover_document
    
    # Step 7: Commit all changes
    commit_changes
    
    # Step 8: Regenerate handover document with final commit info
    generate_handover_document
    
    # Step 9: Create pull request
    create_pull_request
    
    # Step 10: Show final summary
    show_final_summary
    
    # Create session log for reference
    {
        echo "# Development Session Wrapup"
        echo "Date: ${SESSION_DATE}"
        echo "Project: ${PROJECT_NAME} (${PROJECT_TYPE})"
        echo "Branch: ${CURRENT_BRANCH}"
        echo "Developer: ${GIT_USER}"
        echo "Changes: ${CHANGES_SUMMARY}"
        echo "Handover: ${HANDOVER_FILE}"
        echo "PR URL: ${PR_URL:-Not created}"
        echo "Arguments: $*"
    } > ".wrapup-session-${TIMESTAMP}.log"
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🏁 SCRIPT ENTRY POINT                                                       │
# └─────────────────────────────────────────────────────────────────────────────┘

# Only run main function if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi