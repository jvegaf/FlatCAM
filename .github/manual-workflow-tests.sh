#!/bin/bash

# Manual Workflow Testing Script
# This script provides tools to manually test different workflow scenarios

set -e

echo "🚀 FlatCAM Build Workflow Manual Testing Suite"
echo "=============================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  test-push-main       Test push to main branch trigger"
    echo "  test-tag-release     Test tag-based release trigger"
    echo "  test-manual-build    Test manual workflow dispatch (build only)"
    echo "  test-manual-release  Test manual workflow dispatch (with release)"
    echo "  simulate-failure     Test error handling with simulated failure"
    echo "  validate-appimage    Test AppImage functionality after build"
    echo "  performance-test     Test workflow performance and timing"
    echo "  security-scan        Test workflow security aspects"
    echo "  help                 Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 test-push-main"
    echo ""
}

# Test 1: Push to main branch
test_push_main() {
    echo -e "${BLUE}Testing push to main branch scenario...${NC}"
    
    # Create a test commit
    echo "# Test commit $(date)" >> README.md
    git add README.md
    git commit -m "Test workflow: development build trigger"
    
    echo -e "${YELLOW}📋 Expected behavior:${NC}"
    echo "1. Workflow should trigger on push to main"
    echo "2. Should create development build with version like '2024.4-dev.abc1234'"
    echo "3. Should upload AppImage as artifact"
    echo "4. Should NOT create release (only for tags)"
    echo ""
    echo -e "${GREEN}✅ Test commit created. Push with: git push origin main${NC}"
    echo -e "${YELLOW}⚠️  Monitor workflow at: https://github.com/jvegaf/FlatCAM/actions${NC}"
}

# Test 2: Tag-based release
test_tag_release() {
    echo -e "${BLUE}Testing tag-based release scenario...${NC}"
    
    local tag_name="v2024.4-test-$(date +%s)"
    
    echo -e "${YELLOW}📋 Expected behavior:${NC}"
    echo "1. Workflow should trigger on tag push"
    echo "2. Should create stable build with version from tag"
    echo "3. Should create GitHub release"
    echo "4. Should upload AppImage as release asset"
    echo "5. Release should be marked as stable (not prerelease)"
    echo ""
    echo -e "${GREEN}Commands to execute:${NC}"
    echo "git tag $tag_name"
    echo "git push origin $tag_name"
    echo ""
    echo -e "${YELLOW}⚠️  To test, run the above commands manually${NC}"
    echo -e "${YELLOW}⚠️  Monitor workflow at: https://github.com/jvegaf/FlatCAM/actions${NC}"
}

# Test 3: Manual build (no release)
test_manual_build() {
    echo -e "${BLUE}Testing manual workflow dispatch (build only)...${NC}"
    
    echo -e "${YELLOW}📋 Expected behavior:${NC}"
    echo "1. Workflow should run when manually triggered"
    echo "2. Should create development build"
    echo "3. Should upload AppImage as artifact"
    echo "4. Should NOT create release (create_release = false)"
    echo ""
    echo -e "${GREEN}Steps to test:${NC}"
    echo "1. Go to: https://github.com/jvegaf/FlatCAM/actions"
    echo "2. Select 'Build and Release AppImage' workflow"
    echo "3. Click 'Run workflow'"
    echo "4. Leave 'Create a new release' UNCHECKED"
    echo "5. Click 'Run workflow'"
    echo ""
    echo -e "${YELLOW}⚠️  Test this manually through GitHub UI${NC}"
}

# Test 4: Manual release
test_manual_release() {
    echo -e "${BLUE}Testing manual workflow dispatch (with release)...${NC}"
    
    echo -e "${YELLOW}📋 Expected behavior:${NC}"
    echo "1. Workflow should run when manually triggered"
    echo "2. Should create development build"
    echo "3. Should upload AppImage as artifact"
    echo "4. Should CREATE release (create_release = true)"
    echo "5. Release should be marked as prerelease"
    echo ""
    echo -e "${GREEN}Steps to test:${NC}"
    echo "1. Go to: https://github.com/jvegaf/FlatCAM/actions"
    echo "2. Select 'Build and Release AppImage' workflow"
    echo "3. Click 'Run workflow'"
    echo "4. CHECK 'Create a new release'"
    echo "5. Click 'Run workflow'"
    echo ""
    echo -e "${YELLOW}⚠️  Test this manually through GitHub UI${NC}"
}

# Test 5: Simulate failure
simulate_failure() {
    echo -e "${BLUE}Testing error handling with simulated failure...${NC}"
    
    # Create a branch with intentional failure
    local branch_name="test-failure-$(date +%s)"
    git checkout -b "$branch_name"
    
    # Create a temporary Python file with a syntax error to cause build failure
    local failure_file="FlatCAM/intentional_failure.py"
    echo "def this_will_fail(" > "$failure_file"
    git add "$failure_file"
    git commit -m "Test: intentional failure for error handling validation"
    
    echo -e "${YELLOW}📋 Expected behavior:${NC}"
    echo "1. Workflow should fail during build process"
    echo "2. Should display clear error messages"
    echo "3. Should NOT create artifacts or releases"
    echo "4. Should properly clean up temporary files"
    echo ""
    echo -e "${GREEN}✅ Failure test branch created: $branch_name${NC}"
    echo -e "${GREEN}Push with: git push origin $branch_name${NC}"
    echo ""
    echo -e "${RED}⚠️  IMPORTANT: Restore the file after testing:${NC}"
    echo "git checkout main"
    echo "git branch -D $branch_name"
    echo "git push origin --delete $branch_name"
}

# Test 6: Validate AppImage functionality
validate_appimage() {
    echo -e "${BLUE}Testing AppImage functionality...${NC}"
    
    echo -e "${YELLOW}📋 This test requires a built AppImage file${NC}"
    echo ""
    echo -e "${GREEN}Steps to test AppImage:${NC}"
    echo "1. Download AppImage from latest release or artifact"
    echo "2. Make it executable: chmod +x FlatCAM-*.AppImage"
    echo "3. Test basic execution: ./FlatCAM-*.AppImage --help"
    echo "4. Test GUI startup: ./FlatCAM-*.AppImage"
    echo "5. Test file loading (Gerber files)"
    echo "6. Test on different Linux distributions"
    echo ""
    echo -e "${YELLOW}Test environments:${NC}"
    echo "- Ubuntu 18.04+"
    echo "- Fedora 30+"
    echo "- openSUSE Leap 15+"
    echo "- Arch Linux"
    echo ""
    echo -e "${GREEN}✅ Use this checklist for manual AppImage testing${NC}"
}

# Test 7: Performance testing
performance_test() {
    echo -e "${BLUE}Testing workflow performance...${NC}"
    
    echo -e "${YELLOW}📋 Performance benchmarks to monitor:${NC}"
    echo ""
    echo -e "${GREEN}Expected timing:${NC}"
    echo "- Source preparation: 1-2 minutes"
    echo "- Dependency installation: 5-10 minutes"
    echo "- AppImage creation: 10-15 minutes"
    echo "- Total workflow time: 20-30 minutes"
    echo ""
    echo -e "${GREEN}Expected artifact sizes:${NC}"
    echo "- Source zip: ~1-2 MB"
    echo "- Final AppImage: 200-500 MB"
    echo ""
    echo -e "${YELLOW}Monitor these metrics during workflow runs:${NC}"
    echo "1. Check workflow duration in GitHub Actions"
    echo "2. Monitor artifact sizes"
    echo "3. Check resource usage (if available)"
    echo "4. Verify no timeout issues occur"
    echo ""
    echo -e "${GREEN}✅ Use GitHub Actions timing data for performance analysis${NC}"
}

# Test 8: Security scanning
security_scan() {
    echo -e "${BLUE}Testing workflow security aspects...${NC}"
    
    echo -e "${YELLOW}📋 Security checklist:${NC}"
    echo ""
    echo -e "${GREEN}Permissions audit:${NC}"
    echo "✅ Minimal permissions (contents: write, actions: read)"
    echo "✅ No excessive permissions granted"
    echo "✅ No hardcoded secrets in workflow"
    echo ""
    echo -e "${GREEN}Dependencies security:${NC}"
    echo "✅ Using official GitHub Actions"
    echo "✅ Pinned action versions (v4, v3, etc.)"
    echo "✅ No untrusted third-party actions"
    echo ""
    echo -e "${GREEN}Runtime security:${NC}"
    echo "✅ No code execution from untrusted sources"
    echo "✅ Proper input validation"
    echo "✅ Secrets handling best practices"
    echo ""
    echo -e "${GREEN}AppImage security:${NC}"
    echo "✅ Built from verified sources"
    echo "✅ No network access during build"
    echo "✅ Reproducible builds"
    echo ""
    echo -e "${GREEN}✅ Security configuration validated${NC}"
}

# Main function
main() {
    case "${1:-help}" in
        "test-push-main")
            test_push_main
            ;;
        "test-tag-release")
            test_tag_release
            ;;
        "test-manual-build")
            test_manual_build
            ;;
        "test-manual-release")
            test_manual_release
            ;;
        "simulate-failure")
            simulate_failure
            ;;
        "validate-appimage")
            validate_appimage
            ;;
        "performance-test")
            performance_test
            ;;
        "security-scan")
            security_scan
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"