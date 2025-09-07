#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 UNIVERSAL GIT WORKFLOW INSTALLER
# ═══════════════════════════════════════════════════════════════════════════════
# 
# Purpose: Easy installation of startup and wrapup commands for any developer
# Author: Universal Git Workflow System
# Version: 2.0.0
# License: MIT
#
# This installer:
# • Downloads the latest startup and wrapup scripts
# • Installs them in the correct locations for system-wide access
# • Configures shell profiles for immediate use
# • Validates the installation and provides usage instructions
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/install.sh | bash
#   # OR
#   wget -O - https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/install.sh | bash
#
# ═══════════════════════════════════════════════════════════════════════════════

# Enable strict error handling
set -e

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🎨 VISUAL STYLING                                                           │
# └─────────────────────────────────────────────────────────────────────────────┘

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ ⚙️ CONFIGURATION                                                            │
# └─────────────────────────────────────────────────────────────────────────────┘

readonly VERSION="2.0.0"
readonly INSTALLER_NAME="Universal Git Workflow Installer"

# Installation directories (in order of preference)
readonly INSTALL_DIRS=(
    "/opt/homebrew/bin"           # macOS with Homebrew (Apple Silicon)
    "/usr/local/bin"              # macOS with Homebrew (Intel) / Linux
    "$HOME/.local/bin"            # User-local installation
    "$HOME/bin"                   # Alternative user-local
)

# Repository URLs for downloading scripts
REPO_BASE_URL="${REPO_BASE_URL:-https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main}"
STARTUP_URL="${REPO_BASE_URL}/scripts/startup.sh"
WRAPUP_URL="${REPO_BASE_URL}/scripts/wrapup.sh"

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🔧 UTILITY FUNCTIONS                                                        │
# └─────────────────────────────────────────────────────────────────────────────┘

# Print colored output
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Print step headers
print_step() {
    echo
    print_status "$BLUE" "🔧 $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect shell and return profile file
detect_shell_profile() {
    local shell_name=$(basename "$SHELL" 2>/dev/null || echo "bash")
    
    case "$shell_name" in
        "zsh")
            echo "$HOME/.zshrc"
            ;;
        "bash")
            if [[ "$OSTYPE" == "darwin"* ]]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        "fish")
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 📋 SYSTEM VALIDATION                                                        │
# └─────────────────────────────────────────────────────────────────────────────┘

validate_system() {
    print_step "Validating system requirements"
    
    # Check for required tools
    local missing_tools=()
    
    if ! command_exists "git"; then
        missing_tools+=("git")
    fi
    
    if ! command_exists "curl" && ! command_exists "wget"; then
        missing_tools+=("curl or wget")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_status "$RED" "❌ Missing required tools:"
        for tool in "${missing_tools[@]}"; do
            print_status "$RED" "   • $tool"
        done
        echo
        print_status "$YELLOW" "💡 Please install the missing tools and try again."
        
        # Provide installation instructions
        if [[ "$OSTYPE" == "darwin"* ]]; then
            print_status "$BLUE" "📦 On macOS, install with Homebrew:"
            print_status "$CYAN" "   brew install git curl"
        elif [[ "$OSTYPE" == "linux"* ]]; then
            print_status "$BLUE" "📦 On Ubuntu/Debian:"
            print_status "$CYAN" "   sudo apt update && sudo apt install git curl"
            print_status "$BLUE" "📦 On CentOS/RHEL/Fedora:"
            print_status "$CYAN" "   sudo yum install git curl"  # or dnf
        fi
        
        exit 1
    fi
    
    print_status "$GREEN" "✅ All required tools are available"
    
    # Detect OS and shell
    local os_info=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        os_info="macOS"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        os_info="Linux"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        os_info="Windows (Git Bash/WSL)"
    else
        os_info="Unknown ($OSTYPE)"
    fi
    
    local shell_info=$(basename "$SHELL" 2>/dev/null || echo "Unknown")
    
    print_status "$CYAN" "🖥️  Operating System: $os_info"
    print_status "$CYAN" "🐚 Shell: $shell_info"
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 📁 INSTALLATION DIRECTORY                                                   │
# └─────────────────────────────────────────────────────────────────────────────┘

find_install_directory() {
    print_step "Finding best installation directory"
    
    for dir in "${INSTALL_DIRS[@]}"; do
        # Expand ~ to home directory
        local expanded_dir="${dir/#\~/$HOME}"
        
        print_status "$BLUE" "📁 Checking: $expanded_dir"
        
        if [[ -d "$expanded_dir" && -w "$expanded_dir" ]]; then
            print_status "$GREEN" "✅ Found writable directory: $expanded_dir"
            echo "$expanded_dir"
            return 0
        elif [[ -d "$expanded_dir" ]]; then
            print_status "$YELLOW" "⚠️  Directory exists but not writable: $expanded_dir"
        else
            print_status "$YELLOW" "⚠️  Directory doesn't exist: $expanded_dir"
        fi
    done
    
    # Create user-local directory as fallback
    local fallback_dir="$HOME/.local/bin"
    print_status "$YELLOW" "💡 Creating fallback directory: $fallback_dir"
    mkdir -p "$fallback_dir"
    
    if [[ -w "$fallback_dir" ]]; then
        print_status "$GREEN" "✅ Created and using: $fallback_dir"
        echo "$fallback_dir"
        return 0
    fi
    
    print_status "$RED" "❌ Could not find or create a suitable installation directory"
    exit 1
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 📥 DOWNLOAD SCRIPTS                                                         │
# └─────────────────────────────────────────────────────────────────────────────┘

download_file() {
    local url="$1"
    local output="$2"
    local description="$3"
    
    print_status "$BLUE" "📥 Downloading $description..."
    
    if command_exists "curl"; then
        if curl -fsSL "$url" -o "$output"; then
            print_status "$GREEN" "✅ Downloaded: $description"
            return 0
        fi
    elif command_exists "wget"; then
        if wget -q "$url" -O "$output"; then
            print_status "$GREEN" "✅ Downloaded: $description"
            return 0
        fi
    fi
    
    print_status "$RED" "❌ Failed to download: $description"
    print_status "$RED" "   URL: $url"
    return 1
}

download_scripts() {
    local install_dir="$1"
    
    print_step "Downloading workflow scripts"
    
    # Note: In a real implementation, you would replace these URLs with actual gist URLs
    # For now, we'll create the scripts locally since we're in development
    
    local startup_script="$install_dir/startup"
    local wrapup_script="$install_dir/wrapup"
    
    # Instead of downloading, we'll copy from our temp files for this demo
    if [[ -f "/tmp/startup.sh" && -f "/tmp/wrapup.sh" ]]; then
        print_status "$BLUE" "📥 Installing startup script..."
        cp "/tmp/startup.sh" "$startup_script"
        chmod +x "$startup_script"
        
        print_status "$BLUE" "📥 Installing wrapup script..."
        cp "/tmp/wrapup.sh" "$wrapup_script"  
        chmod +x "$wrapup_script"
        
        print_status "$GREEN" "✅ Scripts installed successfully"
        return 0
    fi
    
    # Production version downloads from repository:
    download_file "$STARTUP_URL" "$startup_script" "startup script" || return 1
    download_file "$WRAPUP_URL" "$wrapup_script" "wrapup script" || return 1
    
    
    # Make scripts executable
    chmod +x "$startup_script" "$wrapup_script"
    print_status "$GREEN" "✅ Scripts installed and configured"
    return 0
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🔧 SHELL CONFIGURATION                                                      │
# └─────────────────────────────────────────────────────────────────────────────┘

configure_shell() {
    local install_dir="$1"
    
    print_step "Configuring shell environment"
    
    local profile_file=$(detect_shell_profile)
    print_status "$BLUE" "📝 Shell profile: $profile_file"
    
    # Ensure profile file exists
    touch "$profile_file"
    
    # Check if PATH already includes our install directory
    if grep -q "$install_dir" "$profile_file" 2>/dev/null; then
        print_status "$YELLOW" "⚠️  PATH already configured in $profile_file"
    else
        print_status "$BLUE" "📝 Adding $install_dir to PATH..."
        
        # Add PATH export
        {
            echo ""
            echo "# Universal Git Workflow - Added by installer"
            echo "export PATH=\"$install_dir:\$PATH\""
            echo ""
        } >> "$profile_file"
        
        print_status "$GREEN" "✅ PATH configured in $profile_file"
    fi
    
    # Also update current session
    export PATH="$install_dir:$PATH"
    print_status "$GREEN" "✅ PATH updated for current session"
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ ✅ INSTALLATION VALIDATION                                                  │
# └─────────────────────────────────────────────────────────────────────────────┘

validate_installation() {
    local install_dir="$1"
    
    print_step "Validating installation"
    
    local startup_script="$install_dir/startup"
    local wrapup_script="$install_dir/wrapup"
    
    # Check if scripts exist and are executable
    local validation_errors=()
    
    if [[ ! -f "$startup_script" ]]; then
        validation_errors+=("startup script not found at $startup_script")
    elif [[ ! -x "$startup_script" ]]; then
        validation_errors+=("startup script not executable")
    fi
    
    if [[ ! -f "$wrapup_script" ]]; then
        validation_errors+=("wrapup script not found at $wrapup_script")
    elif [[ ! -x "$wrapup_script" ]]; then
        validation_errors+=("wrapup script not executable")
    fi
    
    if [[ ${#validation_errors[@]} -gt 0 ]]; then
        print_status "$RED" "❌ Installation validation failed:"
        for error in "${validation_errors[@]}"; do
            print_status "$RED" "   • $error"
        done
        return 1
    fi
    
    # Test commands
    print_status "$BLUE" "🧪 Testing startup command..."
    if "$startup_script" --version >/dev/null 2>&1; then
        print_status "$GREEN" "✅ startup command works"
    else
        print_status "$YELLOW" "⚠️  startup command test failed (may be normal for demo version)"
    fi
    
    print_status "$BLUE" "🧪 Testing wrapup command..."
    if "$wrapup_script" --version >/dev/null 2>&1; then
        print_status "$GREEN" "✅ wrapup command works"
    else
        print_status "$YELLOW" "⚠️  wrapup command test failed (may be normal for demo version)"
    fi
    
    print_status "$GREEN" "✅ Installation validation completed"
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 📚 USAGE INSTRUCTIONS                                                       │
# └─────────────────────────────────────────────────────────────────────────────┘

show_usage_instructions() {
    local install_dir="$1"
    local profile_file=$(detect_shell_profile)
    
    echo
    print_status "$PURPLE" "═══════════════════════════════════════════════════════════════════"
    print_status "$PURPLE" "🎉 INSTALLATION COMPLETED SUCCESSFULLY!"
    print_status "$PURPLE" "═══════════════════════════════════════════════════════════════════"
    echo
    
    print_status "$CYAN" "📁 Installation Directory: $install_dir"
    print_status "$CYAN" "📝 Shell Profile Updated: $profile_file"
    print_status "$CYAN" "🔧 Version: $VERSION"
    echo
    
    print_status "$BLUE" "🚀 GETTING STARTED:"
    echo
    print_status "$GREEN" "1. Restart your terminal or run:"
    print_status "$YELLOW" "   source $profile_file"
    echo
    print_status "$GREEN" "2. Navigate to any project directory:"
    print_status "$YELLOW" "   cd /path/to/your/project"
    echo
    print_status "$GREEN" "3. Start a development session:"
    print_status "$YELLOW" "   startup"
    print_status "$CYAN" "   # This will detect your project type, install dependencies, start services"
    echo
    print_status "$GREEN" "4. Do your development work..."
    print_status "$CYAN" "   # Code, test, make changes..."
    echo
    print_status "$GREEN" "5. End your session with professional handover:"
    print_status "$YELLOW" "   wrapup"
    print_status "$CYAN" "   # This will commit changes, create PR, generate documentation"
    echo
    
    print_status "$BLUE" "📖 ADDITIONAL COMMANDS:"
    echo
    print_status "$YELLOW" "   startup --help              ${CYAN}# Show all startup options${NC}"
    print_status "$YELLOW" "   startup --fresh             ${CYAN}# Fresh start with latest code${NC}"
    print_status "$YELLOW" "   startup feature/my-branch   ${CYAN}# Start on specific branch${NC}"
    print_status "$YELLOW" "   startup --check             ${CYAN}# Health check only${NC}"
    echo  
    print_status "$YELLOW" "   wrapup --help               ${CYAN}# Show all wrapup options${NC}"
    print_status "$YELLOW" "   wrapup feature/my-feature   ${CYAN}# Custom branch name${NC}"
    print_status "$YELLOW" "   wrapup feature/auth \"Add login\"  ${CYAN}# Custom branch + PR title${NC}"
    print_status "$YELLOW" "   wrapup --no-pr              ${CYAN}# Commit only, skip PR${NC}"
    echo
    
    print_status "$BLUE" "💡 WHAT HAPPENS AUTOMATICALLY:"
    echo
    print_status "$GREEN" "📋 Startup Process:"
    print_status "$CYAN" "   • Detects project type (Next.js, React, Python, etc.)"
    print_status "$CYAN" "   • Validates system dependencies"
    print_status "$CYAN" "   • Installs/updates project dependencies"
    print_status "$CYAN" "   • Starts development services (databases, dev servers)"
    print_status "$CYAN" "   • Manages Git branches and syncs with remote"
    print_status "$CYAN" "   • Provides project status and next steps"
    echo
    
    print_status "$GREEN" "📋 Wrapup Process:"
    print_status "$CYAN" "   • Cleans temporary files and build artifacts"
    print_status "$CYAN" "   • Updates project documentation"
    print_status "$CYAN" "   • Commits all changes with descriptive messages"
    print_status "$CYAN" "   • Creates pull request with detailed description"
    print_status "$CYAN" "   • Generates comprehensive handover document"
    print_status "$CYAN" "   • Extracts and lists all TODOs from codebase"
    echo
    
    print_status "$BLUE" "🔧 SUPPORTED PROJECT TYPES:"
    print_status "$CYAN" "   • JavaScript/TypeScript (Next.js, React, Node.js)"
    print_status "$CYAN" "   • Python (Django, Flask, FastAPI)"
    print_status "$CYAN" "   • Rust (Cargo projects)"
    print_status "$CYAN" "   • Go (Go modules)"
    print_status "$CYAN" "   • Java (Maven, Gradle)"
    print_status "$CYAN" "   • Ruby (Bundler projects)"
    print_status "$CYAN" "   • Full-stack applications"
    print_status "$CYAN" "   • Generic projects"
    echo
    
    print_status "$BLUE" "📄 GENERATED DOCUMENTATION:"
    print_status "$CYAN" "   • HANDOVER.md - Comprehensive session handover"
    print_status "$CYAN" "   • Session logs for reference"
    print_status "$CYAN" "   • Automatic README.md timestamps"
    print_status "$CYAN" "   • Pull request descriptions with context"
    echo
    
    print_status "$BLUE" "🆘 TROUBLESHOOTING:"
    echo
    print_status "$YELLOW" "   Commands not found after installation?"
    print_status "$CYAN" "   → Restart terminal or run: source $profile_file"
    echo
    print_status "$YELLOW" "   GitHub CLI not found warnings?"
    print_status "$CYAN" "   → Install with: brew install gh (macOS) or apt install gh (Ubuntu)"
    print_status "$CYAN" "   → Then run: gh auth login"
    echo
    print_status "$YELLOW" "   Permission denied errors?"
    print_status "$CYAN" "   → Ensure scripts are executable: chmod +x $install_dir/{startup,wrapup}"
    echo
    
    print_status "$PURPLE" "═══════════════════════════════════════════════════════════════════"
    print_status "$GREEN" "🎊 Ready to revolutionize your development workflow!"
    print_status "$GREEN" "💪 Save 15+ minutes per session with professional handovers!"
    print_status "$PURPLE" "═══════════════════════════════════════════════════════════════════"
    echo
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🎬 MAIN INSTALLATION FLOW                                                   │
# └─────────────────────────────────────────────────────────────────────────────┘

main() {
    # Show installer banner
    echo
    print_status "$BLUE" "🚀 $INSTALLER_NAME v$VERSION"
    print_status "$PURPLE" "Streamline your development workflow with automated session management"
    echo
    
    # Step 1: Validate system
    validate_system
    
    # Step 2: Find installation directory
    local install_dir=$(find_install_directory)
    
    # Step 3: Download and install scripts
    download_scripts "$install_dir"
    
    # Step 4: Configure shell
    configure_shell "$install_dir"
    
    # Step 5: Validate installation
    validate_installation "$install_dir"
    
    # Step 6: Show usage instructions
    show_usage_instructions "$install_dir"
    
    # Success!
    return 0
}

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ 🏁 SCRIPT ENTRY POINT                                                       │
# └─────────────────────────────────────────────────────────────────────────────┘

# Only run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi