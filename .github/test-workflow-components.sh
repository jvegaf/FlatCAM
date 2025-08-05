#!/bin/bash

# Workflow Component Test Script
# Tests critical components that the GitHub Actions workflow depends on

set -e

echo "🧪 Testing FlatCAM AppImage Workflow Components"
echo "=============================================="

# Test 1: Source code zip creation
echo "📦 Test 1: Source code zip creation"
if [[ -x "publish/create_zipapp.sh" ]]; then
    echo "✅ create_zipapp.sh is executable"
    # Test dry run
    echo "   Testing zip creation..."
    publish/create_zipapp.sh
    if [[ -f "_build/FlatCAM_2024_4.zip" ]]; then
        ZIP_SIZE=$(stat -c%s "_build/FlatCAM_2024_4.zip")
        echo "✅ Zip created successfully (${ZIP_SIZE} bytes)"
        rm -rf _build/
    else
        echo "❌ Zip creation failed"
        exit 1
    fi
else
    echo "❌ create_zipapp.sh not found or not executable"
    exit 1
fi

# Test 2: AppImage build script presence
echo ""
echo "🔧 Test 2: AppImage build infrastructure"
if [[ -x "publish/appimage/create_appimage.sh" ]]; then
    echo "✅ AppImage build script found and executable"
else
    echo "❌ AppImage build script not found or not executable"
    exit 1
fi

if [[ -f "publish/appimage/AppImageBuilder.yml" ]]; then
    echo "✅ AppImageBuilder configuration found"
else
    echo "❌ AppImageBuilder configuration not found"
    exit 1
fi

if [[ -f "publish/appimage/org.flatcam.FlatCAM.desktop" ]]; then
    echo "✅ Desktop file found"
else
    echo "❌ Desktop file not found"
    exit 1
fi

if [[ -f "publish/appimage/flatcam_icon256.png" ]]; then
    echo "✅ Icon file found"
else
    echo "❌ Icon file not found"
    exit 1
fi

# Test 3: Python project structure
echo ""
echo "🐍 Test 3: Python project structure"
if [[ -f "__main__.py" ]]; then
    echo "✅ Main entry point found"
else
    echo "❌ Main entry point not found"
    exit 1
fi

if [[ -f "FlatCAM/pyproject.toml" ]]; then
    echo "✅ pyproject.toml found"
    VERSION=$(grep '^version' FlatCAM/pyproject.toml | sed 's/version = "\(.*\)"/\1/' || echo "")
    if [[ -n "$VERSION" ]]; then
        echo "✅ Version detected: $VERSION"
    else
        echo "⚠️  Could not parse version from pyproject.toml"
    fi
else
    echo "❌ pyproject.toml not found"
    exit 1
fi

if [[ -d "FlatCAM" && -f "FlatCAM/__init__.py" ]]; then
    echo "✅ FlatCAM package structure valid"
else
    echo "❌ FlatCAM package structure invalid"
    exit 1
fi

# Test 4: GitHub Actions workflow
echo ""
echo "⚡ Test 4: GitHub Actions workflow"
if [[ -f ".github/workflows/build-appimage.yml" ]]; then
    echo "✅ Workflow file found"
    
    # Basic YAML validation
    if python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build-appimage.yml'))" 2>/dev/null; then
        echo "✅ YAML syntax valid"
    else
        echo "❌ YAML syntax invalid"
        exit 1
    fi
    
    # Check for required trigger events
    if grep -q "push:" .github/workflows/build-appimage.yml && 
       grep -q "workflow_dispatch:" .github/workflows/build-appimage.yml; then
        echo "✅ Required triggers present"
    else
        echo "❌ Missing required triggers"
        exit 1
    fi
    
    # Check for required permissions
    if grep -q "permissions:" .github/workflows/build-appimage.yml; then
        echo "✅ Permissions configured"
    else
        echo "❌ Permissions not configured"
        exit 1
    fi
else
    echo "❌ Workflow file not found"
    exit 1
fi

# Test 5: Required files for AppImage
echo ""
echo "📁 Test 5: Required AppImage files"
REQUIRED_FILES=(
    "FlatCAM/appCommon/Common.py"
    "FlatCAM/appGUI/GUIElements.py" 
    "FlatCAM/translate/__init__.py"
    "FlatCAM/requirements.txt"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file found"
    else
        echo "❌ $file not found"
        exit 1
    fi
done

echo ""
echo "🎉 All tests passed! Workflow components are ready."
echo ""
echo "📋 Next steps for testing:"
echo "1. Push to a feature branch to test build process"
echo "2. Create a test tag (e.g., v2024.4-test) to test releases"
echo "3. Test manual workflow dispatch from GitHub Actions tab"
echo "4. Verify AppImage functionality on Linux systems"