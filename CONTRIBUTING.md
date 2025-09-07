# Contributing to Universal Git Workflow

Thank you for your interest in contributing! This project aims to make development workflows more efficient for everyone.

## Quick Start

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a feature branch** from `main`
4. **Make your changes** with clear commit messages
5. **Test thoroughly** on your local projects
6. **Submit a pull request** with detailed description

## Development Setup

```bash
# Fork and clone
git clone https://github.com/your-username/universal-git-workflow.git
cd universal-git-workflow

# Create feature branch
git checkout -b feature/your-improvement

# Make changes and test
./scripts/startup.sh --help
./scripts/wrapup.sh --version

# Commit and push
git commit -m "feat: add support for Deno projects"
git push origin feature/your-improvement
```

## What We Need

### High Priority
- **New project type support** (Deno, PHP, C++, Swift, etc.)
- **Windows PowerShell compatibility**
- **GitLab/Bitbucket integration**
- **Bug fixes and stability improvements**

### Medium Priority  
- **Custom template systems**
- **Development metrics and analytics**
- **IDE/editor integrations**
- **Team collaboration features**

### Nice to Have
- **AI-enhanced commit messages**
- **Multi-language README generation**
- **Mobile app for project status**
- **Integration with project management tools**

## Code Standards

### Shell Scripting Guidelines
- **Use bash-compatible syntax** for maximum compatibility
- **Add comprehensive comments** for all functions
- **Include error handling** with meaningful messages
- **Follow existing code style** and naming conventions
- **Test on multiple platforms** when possible

### Example Function Structure
```bash
# Brief description of what this function does
# Arguments:
#   $1 - parameter description
#   $2 - another parameter description  
# Returns:
#   0 on success, 1 on error
function_name() {
    local param1="$1"
    local param2="$2"
    
    # Validate inputs
    if [[ -z "$param1" ]]; then
        echo "Error: param1 is required" >&2
        return 1
    fi
    
    # Implementation
    echo "Processing $param1..."
    
    # Return success
    return 0
}
```

### Documentation Standards
- **Update README.md** for user-facing changes
- **Add help text** for new command options
- **Include usage examples** for new features
- **Update project type table** when adding support

## Testing Guidelines

### Manual Testing Checklist
- [ ] Test installation script on fresh system
- [ ] Verify `startup --help` shows all options
- [ ] Verify `wrapup --help` shows all options  
- [ ] Test basic workflow: `startup` → make changes → `wrapup`
- [ ] Test with different project types
- [ ] Test error conditions and edge cases
- [ ] Verify generated documentation is correct

### Project Types to Test
- [ ] Next.js project with `next.config.js`
- [ ] React project with Create React App
- [ ] Node.js project with Express
- [ ] Python project with Django/Flask
- [ ] Rust project with Cargo.toml
- [ ] Go project with go.mod
- [ ] Full-stack project with frontend/backend dirs

## Adding New Project Types

### 1. Update Detection Logic
Add detection in both `scripts/startup.sh` and `scripts/wrapup.sh`:

```bash
# In detect_project_type() function
elif [[ -f "deno.json" ]] || [[ -f "deno.jsonc" ]]; then
    echo "deno"
    return 0
```

### 2. Add Dependencies Check
In `check_dependencies()` function:

```bash
"deno")
    if ! command -v deno >/dev/null 2>&1; then
        missing_deps+=("deno")
    fi
    ;;
```

### 3. Add Dependency Installation
In `install_dependencies()` function:

```bash
"deno")
    # Deno doesn't require traditional dependency installation
    # but we might want to cache dependencies
    deno cache deps.ts 2>/dev/null || true
    ;;
```

### 4. Add Cleanup Rules  
In `cleanup_project_files()` function:

```bash
"deno")
    # Clean Deno cache and temporary files
    rm -rf .deno_cache/ 2>/dev/null || true
    ;;
```

### 5. Update Documentation
- Add entry to project types table in README.md
- Include example usage for the new project type
- Update help text if needed

## Commit Message Format

Use conventional commits for clear history:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types
- `feat`: New feature
- `fix`: Bug fix  
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples
```
feat(startup): add support for Deno projects

- Add Deno project type detection
- Include deno cache command in dependency installation
- Update documentation with Deno examples

Closes #42
```

```
fix(wrapup): handle empty git repositories gracefully

Previously the script would fail when run in repositories
with no commits. Now it creates an initial commit automatically.

Fixes #38
```

## Pull Request Guidelines

### PR Title Format
Use the same format as commit messages:
```
feat(startup): add Windows PowerShell support
```

### PR Description Template
```markdown
## Summary
Brief description of what this PR does.

## Changes Made
- [ ] Added new feature X
- [ ] Fixed bug in component Y  
- [ ] Updated documentation

## Testing
- [ ] Tested on macOS
- [ ] Tested on Linux
- [ ] Tested on Windows (if applicable)
- [ ] Added/updated tests
- [ ] Verified backward compatibility

## Screenshots (if applicable)
Include screenshots of new features or UI changes.

## Breaking Changes
List any breaking changes and migration steps.

## Related Issues
Closes #123
References #456
```

### Review Process
1. **Automated checks** must pass (linting, basic tests)
2. **Manual review** by maintainer
3. **Testing** on different platforms if needed
4. **Approval and merge** when ready

## Documentation Contributions

### README Updates
- Keep language clear and concise
- Include practical examples
- Update tables and lists as needed
- Maintain consistent formatting

### New Documentation Files
- Place in `docs/` directory
- Use clear, descriptive filenames
- Include table of contents for long documents
- Link from main README when appropriate

## Community Guidelines

### Be Respectful
- Use welcoming and inclusive language
- Respect different viewpoints and experiences
- Accept constructive criticism gracefully
- Focus on what's best for the community

### Ask Questions
- No question is too basic
- Use GitHub Discussions for general questions
- Use GitHub Issues for bug reports and feature requests
- Be patient with responses

### Help Others
- Answer questions when you can
- Review pull requests
- Share your use cases and success stories
- Mentor new contributors

## Getting Help

- **Documentation**: Check README.md and docs/ first
- **Discussions**: Use GitHub Discussions for questions
- **Issues**: Use GitHub Issues for bugs and feature requests  
- **Email**: Contact maintainers for security issues

## Recognition

Contributors are recognized in:
- Git commit history
- GitHub contributors page
- Release notes for significant contributions
- README acknowledgments section

Thank you for helping make development workflows better for everyone!