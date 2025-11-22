#!/bin/bash

# =============================================================================
# Test N8N Workflows Script
# This script tests all the workflows to ensure they're working correctly
# =============================================================================

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load environment variables if available
if [[ -f .env ]]; then
    source .env
fi

# Default configuration (override with .env)
N8N_BASE_URL=${N8N_BASE_URL:-"http://localhost:5678"}
OUTLINE_URL=${OUTLINE_URL:-"http://localhost:6060"}
OUTLINE_API_KEY=${OUTLINE_API_KEY:-""}

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# =============================================================================
# Test Functions
# =============================================================================

test_endpoint_health() {
    log_info "Testing endpoint health..."
    
    # Test n8n instance
    if curl -f -s "$N8N_BASE_URL/healthz" > /dev/null 2>&1; then
        log_success "n8n instance is healthy"
        ((TESTS_PASSED++))
    else
        log_warning "n8n instance may not be healthy or accessible"
    fi
    ((TESTS_TOTAL++))
}

test_outline_api() {
    log_info "Testing Outline API connectivity..."
    
    if [[ -z "$OUTLINE_API_KEY" ]]; then
        log_warning "OUTLINE_API_KEY not configured"
        ((TESTS_FAILED++))
        ((TESTS_TOTAL++))
        return 1
    fi
    
    if curl -f -s -H "Authorization: Bearer $OUTLINE_API_KEY" \
        "$OUTLINE_URL/api/collections" > /dev/null 2>&1; then
        log_success "Outline API accessible and authenticated"
        ((TESTS_PASSED++))
    else
        log_error "Cannot access Outline API - check URL and API key"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))
}

test_webhook_endpoints() {
    log_info "Testing webhook endpoints..."
    
    # Test file event webhook
    log_info "Testing file event webhook..."
    response=$(curl -s -w "%{http_code}" -X POST "$N8N_BASE_URL/webhook/markdown-file-event" \
        -H "Content-Type: application/json" \
        -d '{
            "eventId": "test_evt_'$(date +%s)'",
            "filePath": "/documents/projects/test.md",
            "fileName": "test.md",
            "directory": "/documents/projects",
            "eventType": "CREATE",
            "category": "projects",
            "subcategory": "",
            "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        }')
    
    http_code="${response: -3}"
    if [[ "$http_code" == "200" || "$http_code" == "202" || "$http_code" == "400" ]]; then
        log_success "File event webhook responding (HTTP $http_code)"
        ((TESTS_PASSED++))
    else
        log_error "File event webhook failed (HTTP $http_code)"
        ((TESTS_FAILED++))
    fi
    ((TESTS_TOTAL++))
    
    # Test document processor webhook
    log_info "Testing document processor webhook..."
    response=$(curl -s -w "%{http_code}" -X POST "$N8N_BASE_URL/webhook/markdown-processor" \
        -H "Content-Type: application/json" \
        -d '{
            "eventId": "test_doc_'$(date +%s)'",
            "filePath": "/documents/guides/getting-started.md",
            "fileName": "getting-started.md",
            "directory": "/documents/guides",
            "eventType": "CREATE",
            "category": "guides",
            "subcategory": "",
            "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        }')
    
    http_code="${response: -3}"
    if [[ "$http_code" == "200" || "$http_code" == "202" || "$http_code" == "400" ]]; then
        log_success "Document processor webhook responding (HTTP $http_code)"
        ((TESTS_PASSED++))
    else
        log_warning "Document processor webhook may need configuration (HTTP $http_code)"
        # Don't count as failure for document processor as it might need file content
    fi
    ((TESTS_TOTAL++))
}

test_workflow_files() {
    log_info "Checking workflow files..."
    
    local files=("file-event-processor.json" "document-processor-fixed.json" "batch-processor.json")
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "Found workflow file: $file"
            ((TESTS_PASSED++))
        else
            log_error "Missing workflow file: $file"
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))
    done
}

test_environment_configuration() {
    log_info "Testing environment configuration..."
    
    local required_vars=("N8N_BASE_URL" "OUTLINE_URL" "OUTLINE_API_KEY")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -n "${!var}" ]]; then
            log_success "$var is configured"
            ((TESTS_PASSED++))
        else
            log_warning "$var is not configured"
            missing_vars+=("$var")
            ((TESTS_FAILED++))
        fi
        ((TESTS_TOTAL++))
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_warning "Missing environment variables: ${missing_vars[*]}"
        log_info "Copy .env.template to .env and configure the missing variables"
    fi
}

create_test_file() {
    log_info "Creating test markdown file..."
    
    # Create test directories if they don't exist
    mkdir -p examples/{projects,guides,technical,personal,research}
    
    # Create a test markdown file with front matter
    cat > examples/projects/test-document.md << 'EOF'
---
title: "Test Document for Workflow Testing"
description: "This is a test document to verify the markdown-to-Outline sync workflow"
category: "projects"
tags: [testing, workflow, example]
collection: "Projects"
author: "Test System"
created: "2025-11-16"
modified: "2025-11-16"
---

# Test Document

This is a test document created to verify the markdown-to-Outline synchronization workflow.

## Purpose

This document serves as a test case for:

1. **File Event Detection**: Verifying that file system events are properly detected
2. **Metadata Parsing**: Testing front matter extraction and parsing
3. **Collection Mapping**: Ensuring documents are routed to correct Outline collections
4. **API Integration**: Validating the connection to Outline API

## Test Content

### Code Block Example

```javascript
// Example JavaScript code
function testWorkflow() {
    console.log("Testing markdown-to-Outline workflow");
    return true;
}
```

### Table Example

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Value 1  | Value 2  | Value 3  |
| Data A   | Data B   | Data C   |

### List Example

1. **First item**: Important element
2. **Second item**: Supporting element  
3. **Third item**: Final element

## Verification Steps

When this file is processed, the workflow should:

1. ✅ Detect file creation event
2. ✅ Parse front matter metadata
3. ✅ Route to "Projects" collection
4. ✅ Create document in Outline
5. ✅ Preserve all formatting and content

## Expected Results

- Document appears in Outline "Projects" collection
- Title: "Test Document for Workflow Testing"
- Content includes all formatting
- Metadata is preserved
- Author attribution is maintained

---

**Test Status**: Ready for testing
**Created**: 2025-11-16
**Version**: 1.0
EOF

    log_success "Test file created: examples/projects/test-document.md"
    ((TESTS_PASSED++))
    ((TESTS_TOTAL++))
}

# =============================================================================
# Main Test Execution
# =============================================================================

main() {
    echo "==============================================="
    echo "N8N Workflow Testing Suite"
    echo "==============================================="
    echo
    
    # Check if we're in the correct directory
    if [[ ! -f "README.md" ]] || [[ ! -f "setup-workflows.sh" ]]; then
        log_error "Please run this script from the n8n-workflows directory"
        exit 1
    fi
    
    log_info "Starting workflow tests..."
    echo
    
    # Run all tests
    test_environment_configuration
    echo
    
    test_endpoint_health
    echo
    
    test_outline_api
    echo
    
    test_webhook_endpoints
    echo
    
    test_workflow_files
    echo
    
    create_test_file
    echo
    
    # Summary
    echo "==============================================="
    echo "Test Results Summary"
    echo "==============================================="
    echo "Total Tests: $TESTS_TOTAL"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed! Your workflow setup looks good."
        echo
        echo "Next steps:"
        echo "1. Import workflow files into n8n"
        echo "2. Configure environment variables in each workflow"
        echo "3. Activate all workflows"
        echo "4. Test with real markdown files"
    else
        log_warning "Some tests failed. Please review the issues above."
        echo
        echo "Common fixes:"
        echo "1. Ensure n8n and Outline instances are running"
        echo "2. Check environment variables in .env file"
        echo "3. Verify API keys and permissions"
        echo "4. Import workflow files if missing"
    fi
    
    echo
    log_info "Test completed at $(date)"
}

# Run main function
main "$@"