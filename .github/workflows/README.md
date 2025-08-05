# GitHub Actions AppImage Workflow

This document describes the automated GitHub Actions workflow for building and releasing FlatCAM AppImage builds.

## Workflow Overview

The workflow (`build-appimage.yml`) automates the following process:

1. **Build AppImage**: Creates a standalone Linux AppImage of FlatCAM
2. **Create Releases**: Automatically publishes releases with the AppImage artifact
3. **Multi-trigger Support**: Responds to tag pushes, main branch pushes, and manual triggers

## Triggers

### Automatic Triggers
- **Tag push**: When a tag matching `v*` pattern is pushed (e.g., `v2024.4`, `v1.0.0`)
- **Main branch push**: When code is pushed to the `main` branch

### Manual Trigger
- **workflow_dispatch**: Can be manually triggered from the GitHub Actions tab
  - Optional parameter: `create_release` (boolean) - Forces release creation even for non-tag builds

## Workflow Jobs

### 1. build-appimage
**Purpose**: Build the FlatCAM AppImage

**Steps**:
- Checkout repository with full history
- Set up Python 3.10 environment
- Install system dependencies (Qt, graphics libraries, etc.)
- Install AppImage Builder tools
- Create source code zip package
- Build AppImage using existing configuration
- Test AppImage functionality
- Upload AppImage as build artifact

**Outputs**:
- `version`: The determined version string
- `appimage-path`: Path to the built AppImage file

### 2. create-release
**Purpose**: Create GitHub releases with AppImage assets

**Conditions**:
- Only runs if AppImage build succeeded
- Runs for tag pushes or manual triggers with `create_release=true`

**Steps**:
- Download built AppImage artifact
- Generate release notes with installation instructions
- Create GitHub release with AppImage attachment
- Handle both stable releases (tags) and development releases

### 3. notify-success
**Purpose**: Provide build status notifications

**Steps**:
- Report successful build completion
- Indicate release creation status

## Release Types

### Stable Releases (Tags)
- **Trigger**: Push tag like `v2024.4`
- **Release Name**: "FlatCAM 2024.4"
- **Prerelease**: No
- **File Name**: `FlatCAM-2024.4-x86_64.AppImage`

### Development Releases (Main Branch)
- **Trigger**: Push to main branch or manual trigger with release creation
- **Release Name**: "FlatCAM 2024.4-dev.abc1234 (Development Build)"
- **Prerelease**: Yes
- **File Name**: `FlatCAM-2024.4-dev.abc1234-x86_64.AppImage`

## Version Determination

1. **Tag builds**: Extract version from git tag (removes 'v' prefix)
2. **Non-tag builds**: 
   - Read version from `FlatCAM/pyproject.toml`
   - Append `-dev.{short-commit-hash}`
   - Fallback to "2024.4" if pyproject.toml parsing fails

## Build Requirements

### System Dependencies
- Ubuntu 22.04 (runner)
- Python 3.10
- Qt5 and graphics libraries
- AppImage builder tools
- GDAL/GEOS libraries
- Various development tools

### AppImage Configuration
The workflow uses the existing AppImage configuration:
- `publish/appimage/AppImageBuilder.yml`: Complete AppImage build configuration
- `publish/create_zipapp.sh`: Source code preparation
- `publish/appimage/create_appimage.sh`: AppImage build script

## Best Practices Implemented

### Security
- **Minimal permissions**: Only `contents: write` and `actions: read`
- **No secret exposure**: Uses built-in `GITHUB_TOKEN`

### Efficiency
- **Concurrency control**: Cancels previous runs for same ref
- **Modular jobs**: Separate concerns (build, release, notify)
- **Conditional execution**: Smart job dependencies and conditions

### Reliability
- **Artifact handling**: Proper upload/download with retention
- **Error handling**: Graceful failure modes
- **Testing**: Basic AppImage functionality verification

## Usage Examples

### Create a Release
```bash
# Create and push a version tag
git tag v2024.5
git push origin v2024.5
```

### Manual Development Build
1. Go to GitHub Actions tab
2. Select "Build and Release AppImage" workflow
3. Click "Run workflow"
4. Set "Create a new release" to true (optional)
5. Click "Run workflow"

### Monitor Build
- Check the Actions tab for workflow progress
- Download artifacts from completed runs
- Check Releases page for published releases

## Troubleshooting

### Common Issues

1. **AppImage build fails**
   - Check system dependency installation
   - Verify AppImageBuilder.yml configuration
   - Check source zip creation

2. **Release creation fails**
   - Verify GitHub token permissions
   - Check if tag already exists
   - Verify artifact download

3. **Version detection issues**
   - Check pyproject.toml format
   - Verify git tag format
   - Review version extraction logic

### Debug Information
- Build logs include detailed dependency installation
- AppImage build shows complete packaging process
- Version detection is logged for verification