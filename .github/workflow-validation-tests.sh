#!/bin/bash

# Comprehensive Workflow Validation Test Suite
# Tests all aspects of the GitHub Actions Build workflow for FlatCAM
# This script validates workflow configuration, security, and functionality

set -e

echo "🔍 FlatCAM Build Workflow Comprehensive Test Suite"
echo "=================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "\n${BLUE}Test ${TOTAL_TESTS}: ${test_name}${NC}"
    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASS: ${test_name}${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ FAIL: ${test_name}${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Test 1: Workflow file structure validation
test_workflow_structure() {
    local workflow_file=".github/workflows/build-appimage.yml"
    
    # Check file exists and is readable
    [[ -f "$workflow_file" ]] || { echo "Workflow file not found"; return 1; }
    
    # Validate YAML syntax
    yaml_error=$(python3 -c "import yaml; yaml.safe_load(open('$workflow_file'))" 2>&1)
    if [ $? -ne 0 ]; then
        echo -e "${RED}Invalid YAML syntax:${NC}\n$yaml_error"
        return 1
    fi
    
    # Check required sections
    local required_sections=("name" "on" "jobs" "permissions")
    for section in "${required_sections[@]}"; do
        grep -q "^${section}:" "$workflow_file" || {
            echo "Missing required section: $section"; return 1;
        }
    done
    
    echo "Workflow structure is valid"
    return 0
}

# Test 2: Trigger configuration validation
test_trigger_configuration() {
    local workflow_file=".github/workflows/build-appimage.yml"
    
    # Check for required triggers using grep (more reliable for this case)
    grep -q "push:" "$workflow_file" || { echo "Missing push trigger"; return 1; }
    grep -q "workflow_dispatch:" "$workflow_file" || { echo "Missing workflow_dispatch trigger"; return 1; }
    
    # Check push trigger has both branches and tags using grep
    grep -A10 "push:" "$workflow_file" | grep -q "branches:" || {
        echo "Push trigger missing branches"; return 1;
    }
    grep -A10 "push:" "$workflow_file" | grep -q "tags:" || {
        echo "Push trigger missing tags"; return 1;
    }
    grep -A10 "push:" "$workflow_file" | grep -q "main" || {
        echo "Push trigger missing main branch"; return 1;
    }
    grep -A10 "push:" "$workflow_file" | grep -q "v\*" || {
        echo "Push trigger missing v* tag pattern"; return 1;
    }
    
    # Check workflow_dispatch has inputs
    grep -A10 "workflow_dispatch:" "$workflow_file" | grep -q "inputs:" || {
        echo "workflow_dispatch missing inputs"; return 1;
    }
    
    echo "Trigger configuration is valid"
    return 0
}

# Test 3: Security and permissions validation
test_security_permissions() {
    local workflow_file=".github/workflows/build-appimage.yml"
    
    # Check permissions are explicitly set
    grep -q "permissions:" "$workflow_file" || { echo "Missing permissions section"; return 1; }
    
    # Check specific permissions using grep
    grep -A5 "permissions:" "$workflow_file" | grep -q "contents: write" || {
        echo "contents permission should be write"; return 1;
    }
    grep -A5 "permissions:" "$workflow_file" | grep -q "actions: read" || {
        echo "actions permission should be read"; return 1;
    }
    
    # Check for dangerous permissions
    local dangerous_perms=("admin" "write-all" "repo")
    for perm in "${dangerous_perms[@]}"; do
        grep -q "$perm:" "$workflow_file" && {
            echo "Dangerous permission found: $perm"; return 1;
        }
    done
    
    echo "Permissions are properly configured"
    return 0
}

# Test 4: Job configuration validation
test_job_configuration() {
    local workflow_file=".github/workflows/build-appimage.yml"
    
    # Check for required jobs
    local required_jobs=("build-appimage" "create-release" "notify-success")
    for job_name in "${required_jobs[@]}"; do
        grep -q "$job_name:" "$workflow_file" || {
            echo "Missing required job: $job_name"; return 1;
        }
    done
    
    # Check for timeout configurations in all jobs
    for job_name in "${required_jobs[@]}"; do
        grep -A5 "$job_name:" "$workflow_file" | grep -q "timeout-minutes:" || {
            echo "Job $job_name missing timeout-minutes"; return 1;
        }
    done
    
    # Check for runs-on configurations
    for job_name in "${required_jobs[@]}"; do
        grep -A5 "$job_name:" "$workflow_file" | grep -q "runs-on: ubuntu-22.04" || {
            echo "Job $job_name should use ubuntu-22.04"; return 1;
        }
    done
    
    # Check job dependencies
    grep -A10 "create-release:" "$workflow_file" | grep -q "needs: build-appimage" || {
        echo "create-release job should depend on build-appimage"; return 1;
    }
    
    # Check conditional execution
    grep -A15 "create-release:" "$workflow_file" | grep -q "needs.build-appimage.result" || {
        echo "create-release job missing proper condition"; return 1;
    }
    
    echo "Job configuration is valid"
    return 0
}

# Test 5: Build environment validation
test_build_environment() {
    # Check Ubuntu version
    local workflow_file=".github/workflows/build-appimage.yml"
    
    grep -q "ubuntu-22.04" "$workflow_file" || {
        echo "Should use ubuntu-22.04 for consistency"; return 1;
    }
    
    # Check Python version setup
    grep -q "setup-python" "$workflow_file" || {
        echo "Missing Python setup"; return 1;
    }
    
    python3 -c "
import yaml
with open('$workflow_file') as f:
    w = yaml.safe_load(f)

build_job = w['jobs']['build-appimage']
steps = build_job.get('steps', [])

python_setup_found = False
checkout_found = False

for step in steps:
    if 'uses' in step:
        if 'actions/setup-python' in step['uses']:
            python_setup_found = True
            # Check Python version
            with_config = step.get('with', {})
            python_version = with_config.get('python-version', '')
            if '3.10' not in python_version:
                print('Should use Python 3.10 for compatibility'); exit(1)
        elif 'actions/checkout' in step['uses']:
            checkout_found = True
            # Check fetch-depth for proper git history
            with_config = step.get('with', {})
            fetch_depth = with_config.get('fetch-depth', 1)
            if fetch_depth != 0:
                print('Checkout should use fetch-depth: 0 for version detection'); exit(1)

if not python_setup_found:
    print('Missing Python setup step'); exit(1)
if not checkout_found:
    print('Missing checkout step'); exit(1)

print('Build environment is properly configured')
" || return 1
    
    return 0
}

# Test 6: Version detection validation
test_version_detection() {
    # Test version detection logic from pyproject.toml
    local version=$(grep '^version' FlatCAM/pyproject.toml | sed -E 's/version = *["'\'']?([^"'\'' ]+)["'\'']?/\1/' || echo "")
    
    [[ -n "$version" ]] || { echo "Cannot detect version from pyproject.toml"; return 1; }
    
    # Test version format
    [[ "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || {
        echo "Version format invalid: $version"; return 1;
    }
    
    echo "Version detection works: $version"
    return 0
}

# Test 7: Dependency installation validation
test_dependency_installation() {
    local workflow_file=".github/workflows/build-appimage.yml"
    
    # Check for system dependencies installation
    grep -q "apt-get" "$workflow_file" || {
        echo "Missing system dependencies installation"; return 1;
    }
    
    # Check for AppImage builder installation
    grep -q "appimage-builder" "$workflow_file" || {
        echo "Missing AppImage builder installation"; return 1;
    }
    
    # Validate critical system dependencies are included
    local required_deps=("python3-pip" "libfuse2" "build-essential" "libgdal-dev")
    for dep in "${required_deps[@]}"; do
        grep -q "$dep" "$workflow_file" || {
            echo "Missing critical dependency: $dep"; return 1;
        }
    done
    
    echo "Dependency installation is properly configured"
    return 0
}

# Test 8: Build artifacts validation
test_build_artifacts() {
    local workflow_file=".github/workflows/build-appimage.yml"
    
    # Check for artifact upload
    grep -q "actions/upload-artifact" "$workflow_file" || {
        echo "Missing artifact upload"; return 1;
    }
    
    python3 -c "
import yaml
with open('$workflow_file') as f:
    w = yaml.safe_load(f)

build_job = w['jobs']['build-appimage']
steps = build_job.get('steps', [])

artifact_upload_found = False
for step in steps:
    if 'uses' in step and 'actions/upload-artifact' in step['uses']:
        artifact_upload_found = True
        with_config = step.get('with', {})
        if 'name' not in with_config:
            print('Artifact upload missing name'); exit(1)
        if 'path' not in with_config:
            print('Artifact upload missing path'); exit(1)
        if 'retention-days' not in with_config:
            print('Artifact upload should specify retention-days'); exit(1)

if not artifact_upload_found:
    print('Missing artifact upload step'); exit(1)

print('Build artifacts configuration is valid')
" || return 1
    
    return 0
}

# Test 9: Error handling validation
test_error_handling() {
    local workflow_file=".github/workflows/build-appimage.yml"
    
    # Check for proper error handling in critical steps
    python3 -c "
import yaml
with open('$workflow_file') as f:
    w = yaml.safe_load(f)

build_job = w['jobs']['build-appimage']
steps = build_job.get('steps', [])

# Check for validation steps
validation_found = False
for step in steps:
    if 'name' in step and ('Test' in step['name'] or 'Verify' in step['name']):
        validation_found = True

# Check conditional job execution
create_release_job = w['jobs']['create-release']
if_condition = create_release_job.get('if', '')
if 'always()' not in if_condition or 'needs.build-appimage.result' not in if_condition:
    print('create-release job missing proper error handling condition'); exit(1)

notify_job = w['jobs']['notify-success']
if_condition = notify_job.get('if', '')
if 'always()' not in if_condition or 'needs.build-appimage.result' not in if_condition:
    print('notify-success job missing proper error handling condition'); exit(1)

print('Error handling is properly configured')
" || return 1
    
    return 0
}

# Test 10: Concurrency control validation
test_concurrency_control() {
    local workflow_file=".github/workflows/build-appimage.yml"
    
    python3 -c "
import yaml
with open('$workflow_file') as f:
    w = yaml.safe_load(f)

concurrency = w.get('concurrency', {})
if not concurrency:
    print('Missing concurrency configuration'); exit(1)

if 'group' not in concurrency:
    print('Concurrency missing group'); exit(1)

if 'cancel-in-progress' not in concurrency:
    print('Concurrency missing cancel-in-progress'); exit(1)

if not concurrency.get('cancel-in-progress', False):
    print('cancel-in-progress should be true'); exit(1)

print('Concurrency control is properly configured')
" || return 1
    
    return 0
}

# Test 11: Release process validation
test_release_process() {
    local workflow_file=".github/workflows/build-appimage.yml"
    
    # Check for release creation
    grep -q "softprops/action-gh-release" "$workflow_file" || {
        echo "Missing release creation action"; return 1;
    }
    
    python3 -c "
import yaml
with open('$workflow_file') as f:
    w = yaml.safe_load(f)

create_release_job = w['jobs']['create-release']
steps = create_release_job.get('steps', [])

release_step_found = False
for step in steps:
    if 'uses' in step and 'softprops/action-gh-release' in step['uses']:
        release_step_found = True
        with_config = step.get('with', {})
        
        required_fields = ['tag_name', 'name', 'body_path', 'files']
        for field in required_fields:
            if field not in with_config:
                print(f'Release step missing {field}'); exit(1)

if not release_step_found:
    print('Missing release creation step'); exit(1)

print('Release process is properly configured')
" || return 1
    
    return 0
}

# Test 12: AppImage specific validation
test_appimage_configuration() {
    # Check AppImage builder configuration
    local appimage_config="publish/appimage/AppImageBuilder.yml"
    
    [[ -f "$appimage_config" ]] || { echo "AppImageBuilder.yml not found"; return 1; }
    
    # Validate AppImage configuration syntax
    python3 -c "
import yaml
try:
    with open('$appimage_config') as f:
        config = yaml.safe_load(f)
    
    # Check required sections
    required_sections = ['AppDir', 'AppImage']
    for section in required_sections:
        if section not in config:
            print(f'AppImage config missing {section}'); exit(1)
    
    # Check app info
    app_info = config.get('AppDir', {}).get('app_info', {})
    if 'id' not in app_info:
        print('AppImage config missing app id'); exit(1)
    if 'name' not in app_info:
        print('AppImage config missing app name'); exit(1)
    
    print('AppImage configuration is valid')
except Exception as e:
    print(f'AppImage config validation failed: {e}'); exit(1)
" || return 1
    
    return 0
}

# Main test execution
main() {
    echo -e "${BLUE}Starting comprehensive workflow validation...${NC}"
    
    # Run all tests
    run_test "Workflow file structure validation" "test_workflow_structure"
    run_test "Trigger configuration validation" "test_trigger_configuration"
    run_test "Security and permissions validation" "test_security_permissions"
    run_test "Job configuration validation" "test_job_configuration"
    run_test "Build environment validation" "test_build_environment"
    run_test "Version detection validation" "test_version_detection"
    run_test "Dependency installation validation" "test_dependency_installation"
    run_test "Build artifacts validation" "test_build_artifacts"
    run_test "Error handling validation" "test_error_handling"
    run_test "Concurrency control validation" "test_concurrency_control"
    run_test "Release process validation" "test_release_process"
    run_test "AppImage configuration validation" "test_appimage_configuration"
    
    # Summary
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Total tests: ${TOTAL_TESTS}"
    echo -e "${GREEN}Passed: ${PASSED_TESTS}${NC}"
    echo -e "${RED}Failed: ${FAILED_TESTS}${NC}"
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 All tests passed! Workflow is ready for production use.${NC}"
        return 0
    else
        echo -e "\n${RED}❌ Some tests failed. Please review and fix the issues above.${NC}"
        return 1
    fi
}

# Run main function
main "$@"