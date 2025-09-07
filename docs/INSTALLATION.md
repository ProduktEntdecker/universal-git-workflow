# Installation Guide

Complete installation instructions for Universal Git Workflow on all supported platforms.

## Quick Installation (Recommended)

The fastest way to get started:

```bash
curl -sSL https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/install.sh | bash
```

This will:
- Download and install the latest scripts
- Configure your shell environment
- Verify the installation
- Show usage instructions

## Platform-Specific Instructions

### macOS

#### Option 1: Automated Installer
```bash
curl -sSL https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/install.sh | bash
```

#### Option 2: Homebrew (Coming Soon)
```bash
# Future release
brew install universal-git-workflow
```

#### Option 3: Manual Installation
```bash
# Download to /usr/local/bin (requires admin)
sudo curl -o /usr/local/bin/startup https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/scripts/startup.sh
sudo curl -o /usr/local/bin/wrapup https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/scripts/wrapup.sh
sudo chmod +x /usr/local/bin/{startup,wrapup}
```

### Linux

#### Ubuntu/Debian
```bash
# Install prerequisites
sudo apt update
sudo apt install curl git

# Install Universal Git Workflow
curl -sSL https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/install.sh | bash
```

#### CentOS/RHEL/Fedora  
```bash
# Install prerequisites
sudo yum install curl git  # CentOS/RHEL
# OR
sudo dnf install curl git  # Fedora

# Install Universal Git Workflow
curl -sSL https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/install.sh | bash
```

#### Arch Linux
```bash
# Install prerequisites
sudo pacman -S curl git

# Install Universal Git Workflow
curl -sSL https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/install.sh | bash
```

### Windows

#### Windows Subsystem for Linux (WSL)
```bash
# From within WSL
curl -sSL https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/install.sh | bash
```

#### Git Bash
```bash
# From Git Bash terminal
curl -sSL https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/install.sh | bash
```

#### PowerShell (Experimental)
```powershell
# Note: PowerShell support is experimental
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/install.sh" | bash
```

## Manual Installation Methods

### Method 1: Clone Repository
```bash
# Clone the repository
git clone https://github.com/ProduktEntdecker/universal-git-workflow.git
cd universal-git-workflow

# Run installer
chmod +x install.sh
./install.sh
```

### Method 2: Direct Download
```bash
# Create directory
mkdir -p ~/.local/bin

# Download scripts
curl -o ~/.local/bin/startup https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/scripts/startup.sh
curl -o ~/.local/bin/wrapup https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/scripts/wrapup.sh

# Make executable
chmod +x ~/.local/bin/{startup,wrapup}

# Add to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Method 3: System-Wide Installation
```bash
# Download to system location (requires sudo)
sudo curl -o /usr/local/bin/startup https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/scripts/startup.sh
sudo curl -o /usr/local/bin/wrapup https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/scripts/wrapup.sh
sudo chmod +x /usr/local/bin/{startup,wrapup}
```

## Post-Installation Setup

### 1. Verify Installation
```bash
# Check if commands are available
startup --version
wrapup --version

# Test help systems
startup --help
wrapup --help
```

### 2. Configure Git (if not already done)
```bash
# Set your name and email
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 3. Install GitHub CLI (Optional but Recommended)
The GitHub CLI enables automatic pull request creation:

#### macOS
```bash
brew install gh
gh auth login
```

#### Linux
```bash
# Ubuntu/Debian
sudo apt install gh

# CentOS/RHEL/Fedora
sudo yum install gh  # or dnf install gh

# Arch
sudo pacman -S github-cli

# Authenticate
gh auth login
```

#### Windows
```bash
# From within WSL or Git Bash
winget install GitHub.cli
gh auth login
```

### 4. Optional Dependencies

#### Docker (for containerized projects)
```bash
# macOS
brew install docker

# Ubuntu
sudo apt install docker.io

# Enable and start
sudo systemctl enable docker
sudo systemctl start docker
```

#### Development Tools by Project Type

**Node.js Projects:**
```bash
# Install Node.js and npm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install --lts
```

**Python Projects:**
```bash
# Ubuntu/Debian
sudo apt install python3 python3-pip python3-venv

# macOS
brew install python
```

**Rust Projects:**
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

**Go Projects:**
```bash
# macOS  
brew install go

# Linux
sudo apt install golang-go  # Ubuntu
sudo yum install golang     # CentOS/RHEL
```

## Shell Configuration

### Bash
The installer automatically adds configuration to `~/.bashrc` or `~/.bash_profile`:

```bash
# Universal Git Workflow - Added by installer
export PATH="$HOME/.local/bin:$PATH"
```

### Zsh
For zsh users, configuration is added to `~/.zshrc`:

```bash
# Universal Git Workflow - Added by installer  
export PATH="$HOME/.local/bin:$PATH"
```

### Fish
For fish shell users, create `~/.config/fish/conf.d/universal-git-workflow.fish`:

```fish
# Universal Git Workflow
set -gx PATH $HOME/.local/bin $PATH
```

### Manual Shell Configuration
If the installer doesn't detect your shell correctly:

```bash
# Add to your shell's profile file
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc

# Reload your shell
source ~/.bashrc  # or ~/.zshrc
```

## Installation Locations

The installer tries these locations in order:

1. **`/opt/homebrew/bin`** - macOS with Homebrew (Apple Silicon)
2. **`/usr/local/bin`** - macOS with Homebrew (Intel) / Linux system-wide
3. **`$HOME/.local/bin`** - User-local installation (fallback)
4. **`$HOME/bin`** - Alternative user-local

You can override the installation location:

```bash
# Install to custom location
INSTALL_DIR=/my/custom/path ./install.sh
```

## Environment Variables

Customize behavior with these environment variables:

```bash
# Installation configuration
export INSTALL_DIR="/usr/local/bin"           # Custom install location
export SKIP_SHELL_CONFIG="true"               # Don't modify shell files
export SKIP_PATH_UPDATE="true"                # Don't update PATH

# Runtime configuration  
export DEV_BRANCH_PREFIX="feature/"           # Default branch prefix
export DEV_PR_LABELS="enhancement,docs"       # Default PR labels
export DEV_SKIP_SERVICES="true"              # Skip service startup
export DEV_SKIP_CLEANUP="true"               # Skip file cleanup
```

## Troubleshooting Installation

### Commands Not Found After Installation

1. **Reload your shell:**
```bash
source ~/.bashrc  # or ~/.zshrc
```

2. **Check PATH:**
```bash
echo $PATH | grep -o '[^:]*\.local/bin\|[^:]*homebrew/bin'
```

3. **Manually add to PATH:**
```bash
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### Permission Denied Errors

```bash
# Fix script permissions
chmod +x ~/.local/bin/{startup,wrapup}

# Or for system-wide installation
sudo chmod +x /usr/local/bin/{startup,wrapup}
```

### Installation Directory Not Writable

The installer will automatically try alternative locations, but you can specify:

```bash
# Install to home directory
mkdir -p ~/.local/bin
INSTALL_DIR="$HOME/.local/bin" ./install.sh
```

### GitHub CLI Not Working

```bash
# Install GitHub CLI
brew install gh        # macOS
sudo apt install gh    # Ubuntu

# Authenticate
gh auth login

# Verify
gh auth status
```

### Curl/Wget Not Available

```bash
# Install curl
sudo apt install curl          # Ubuntu/Debian  
sudo yum install curl          # CentOS/RHEL
brew install curl              # macOS

# Or use wget as alternative
wget -O - https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/install.sh | bash
```

## Uninstallation

To remove Universal Git Workflow:

### Automatic Removal
```bash
# Download and run uninstaller
curl -sSL https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/uninstall.sh | bash
```

### Manual Removal
```bash
# Remove scripts
rm -f ~/.local/bin/{startup,wrapup}
rm -f /usr/local/bin/{startup,wrapup}

# Remove shell configuration (optional)
# Edit your ~/.bashrc or ~/.zshrc to remove the PATH addition
```

## Updating

### Automatic Update
Re-run the installer to get the latest version:

```bash
curl -sSL https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/install.sh | bash
```

### Manual Update
```bash
# Download latest versions
curl -o ~/.local/bin/startup https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/scripts/startup.sh
curl -o ~/.local/bin/wrapup https://raw.githubusercontent.com/ProduktEntdecker/universal-git-workflow/main/scripts/wrapup.sh
chmod +x ~/.local/bin/{startup,wrapup}
```

## Verification

After installation, verify everything works:

```bash
# Test version commands
startup --version
wrapup --version

# Test help systems  
startup --help
wrapup --help

# Test in a real project
cd your-project
startup --check  # Health check only
```

## Next Steps

1. **Read the main [README.md](../README.md)** for usage examples
2. **Try the workflow** on a test project
3. **Join the community** and share feedback
4. **Contribute** improvements and new features

## Getting Help

- 📖 **Documentation**: Check [docs/](../docs/) directory
- 🐛 **Issues**: [GitHub Issues](https://github.com/ProduktEntdecker/universal-git-workflow/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/ProduktEntdecker/universal-git-workflow/discussions)