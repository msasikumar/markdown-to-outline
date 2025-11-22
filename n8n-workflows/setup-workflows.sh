#!/bin/bash

# =============================================================================
# N8N Workflow Setup Script
# This script helps set up the markdown-to-Outline synchronization workflows
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

# Configuration
N8N_INSTANCE_URL=""
OUTLINE_INSTANCE_URL=""
API_KEY=""

# =============================================================================
# Interactive Setup
# =============================================================================

interactive_setup() {
    echo "==============================================="
    echo "N8N Workflow Setup - Markdown-to-Outline Sync"
    echo "==============================================="
    echo
    
    log_info "This script will help you set up the n8n workflows."
    echo
    
    # Get n8n instance URL
    read -p "Enter your n8n instance URL (e.g., https://n8n.yourdomain.com): " N8N_INSTANCE_URL
    if [[ -z "$N8N_INSTANCE_URL" ]]; then
        log_error "n8n instance URL is required"
        exit 1
    fi
    
    # Get Outline instance URL
    read -p "Enter your Outline instance URL (e.g., https://outline.yourdomain.com): " OUTLINE_INSTANCE_URL
    if [[ -z "$OUTLINE_INSTANCE_URL" ]]; then
        log_error "Outline instance URL is required"
        exit 1
    fi
    
    # Get Outline API key
    read -s -p "Enter your Outline API key: " API_KEY
    echo
    if [[ -z "$API_KEY" ]]; then
        log_error "Outline API key is required"
        exit 1
    fi
    
    log_success "Configuration collected"
}

# =============================================================================
# Create Environment Configuration
# =============================================================================

create_environment_config() {
    log_info "Creating environment configuration..."
    
    cat > .env << EOF
# N8N Workflow Configuration
N8N_BASE_URL=$N8N_INSTANCE_URL
FILE_EVENT_WEBHOOK_URL=$N8N_INSTANCE_URL/webhook/markdown-file-event
DOCUMENT_PROCESSOR_WEBHOOK_URL=$N8N_INSTANCE_URL/webhook/markdown-processor
MONITORING_WEBHOOK_URL=$N8N_INSTANCE_URL/webhook/monitoring
BATCH_PROCESSOR_WEBHOOK_URL=$N8N_INSTANCE_URL/webhook/batch-processor

# Outline Configuration
OUTLINE_URL=$OUTLINE_INSTANCE_URL
OUTLINE_API_KEY=$API_KEY

# File Monitoring
MONITORED_DIRECTORIES=/home/user/documents,/home/user/documents/projects,/home/user/documents/guides,/home/user/documents/technical,/home/user/documents/personal
INCLUDE_PATTERNS=*.md,*.markdown,*.mdx
EXCLUDE_PATTERNS=.git,node_modules,.cache,.DS_Store

# Processing Configuration
BATCH_SIZE=10
MAX_FILE_SIZE_MB=50
EVENT_DEBOUNCE_SECONDS=2
QUEUE_MAX_SIZE=1000

# Rate Limiting
OUTLINE_REQUESTS_PER_MINUTE=100
OUTLINE_REQUESTS_PER_HOUR=5000
WEBHOOK_REQUESTS_PER_MINUTE=300

# Monitoring & Alerts
ERROR_RATE_THRESHOLD=0.1
PROCESSING_TIME_THRESHOLD=30
QUEUE_SIZE_THRESHOLD=100

# Security
WEBHOOK_SECRET=$(openssl rand -base64 32)
API_TIMEOUT_SECONDS=30
RETRY_ATTEMPTS=3

# Batch Processing
BATCH_CRON_SCHEDULE=0 */6 * * *
BATCH_ENABLED=true

# Logging
LOG_LEVEL=INFO
DEBUG_MODE=false
EOF

    log_success "Environment configuration created: .env"
}

# =============================================================================
# Test Workflow Endpoints
# =============================================================================

test_workflow_endpoints() {
    log_info "Testing workflow endpoints..."
    
    # Test file event webhook
    log_info "Testing file event webhook..."
    if curl -f -s -X POST "$N8N_INSTANCE_URL/webhook/markdown-file-event" \
        -H "Content-Type: application/json" \
        -d '{"test": true, "eventType": "CREATE", "filePath": "/test.md"}' > /dev/null; then
        log_success "File event webhook accessible"
    else
        log_warning "File event webhook may not be accessible (this is OK if workflows aren't imported yet)"
    fi
    
    # Test document processor webhook
    log_info "Testing document processor webhook..."
    if curl -f -s -X POST "$N8N_INSTANCE_URL/webhook/markdown-processor" \
        -H "Content-Type: application/json" \
        -d '{"test": true}' > /dev/null; then
        log_success "Document processor webhook accessible"
    else
        log_warning "Document processor webhook may not be accessible (this is OK if workflows aren't imported yet)"
    fi
    
    # Test Outline API connectivity
    log_info "Testing Outline API connectivity..."
    if curl -f -s -H "Authorization: Bearer $API_KEY" \
        "$OUTLINE_INSTANCE_URL/api/collections" > /dev/null; then
        log_success "Outline API accessible"
    else
        log_error "Cannot access Outline API. Please check your URL and API key."
        exit 1
    fi
}

# =============================================================================
# Generate Import Instructions
# =============================================================================

generate_import_instructions() {
    log_info "Generating import instructions..."
    
    cat > IMPORT_INSTRUCTIONS.md << EOF
# N8N Workflow Import Instructions

## Step 1: Import Workflow Files

1. Open your n8n instance: $N8N_INSTANCE_URL
2. Go to Settings → Import from file
3. Import the following workflows in order:

### 1. File Event Processor
- **File**: \`file-event-processor.json\`
- **Purpose**: Receives file system events
- **Webhook URL**: $N8N_INSTANCE_URL/webhook/markdown-file-event

### 2. Document Processor  
- **File**: \`document-processor-fixed.json\`
- **Purpose**: Processes markdown files and syncs to Outline
- **Webhook URL**: $N8N_INSTANCE_URL/webhook/markdown-processor

### 3. Batch Processor
- **File**: \`batch-processor.json\`
- **Purpose**: Batch processing on schedule
- **Schedule**: Every 6 hours

## Step 2: Configure Workflows

After importing each workflow:

1. **Open workflow settings**
2. **Update environment variables**:
   - \`outlineApiUrl\`: $OUTLINE_INSTANCE_URL
   - \`outlineApiKey\`: [Your API key]
   - \`markdownProcessorWebhook\`: $N8N_INSTANCE_URL/webhook/markdown-processor

3. **Create HTTP Header Auth credential**:
   - Name: \`Outline API Auth\`
   - Headers: 
     - Authorization: Bearer {{ \$workflow.settings.outlineApiKey }}
     - Content-Type: application/json

## Step 3: Activate Workflows

1. Open each imported workflow
2. Click "Activate" to enable
3. Test with sample data

## Step 4: Test Integration

Run the test script:
\`\`\`bash
./test-workflows.sh
\`\`\`

## Step 5: Configure File Monitor

Update your file monitoring service with the webhook URLs from the \`.env\` file.

EOF

    log_success "Import instructions created: IMPORT_INSTRUCTIONS.md"
}

# =============================================================================
# Create Test Script
# =============================================================================

create_test_script() {
    log_info "Creating test script..."
    
    cat > test-workflows.sh << 'EOF'
#!/bin/bash

# Test script for n8n workflows
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Load environment variables if .env exists
if [[ -f .env ]]; then
    source .env
fi

# Default URLs (override with .env)
N8N_BASE_URL=${N8N_BASE_URL:-"http://localhost:5678"}
OUTLINE_URL=${OUTLINE_URL:-"http://localhost:6060"}

# Test file event webhook
test_file_event_webhook() {
    log_info "Testing file event webhook..."
    
    response=$(curl -s -X POST "$N8N_BASE_URL/webhook/markdown-file-event" \
        -H "Content-Type: application/json" \
        -d '{
            "eventId": "test_evt_123",
            "filePath": "/documents/projects/test.md",
            "fileName": "test.md",
            "directory": "/documents/projects",
            "eventType": "CREATE",
            "category": "projects",
            "subcategory": "",
            "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        }')
    
    if echo "$response" | grep -q "accepted\|queued"; then
        log_success "File event webhook working"
    else
        log_error "File event webhook failed: $response"
        return 1
    fi
}

# Test document processor webhook
test_document_processor_webhook() {
    log_info "Testing document processor webhook..."
    
    response=$(curl -s -X POST "$N8N_BASE_URL/webhook/markdown-processor" \
        -H "Content-Type: application/json" \
        -d '{
            "eventId": "test_evt_456",
            "filePath": "/documents/guides/getting-started.md",
            "fileName": "getting-started.md",
            "directory": "/documents/guides",
            "eventType": "CREATE",
            "category": "guides",
            "subcategory": "",
            "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        }')
    
    if echo "$response" | grep -q "success\|processed"; then
        log_success "Document processor webhook working"
    else
        log_warning "Document processor webhook may need configuration: $response"
    fi
}

# Test Outline API connectivity
test_outline_api() {
    log_info "Testing Outline API connectivity..."
    
    if curl -f -s -H "Authorization: Bearer $OUTLINE_API_KEY" \
        "$OUTLINE_URL/api/collections" > /dev/null; then
        log_success "Outline API accessible"
    else
        log_error "Cannot access Outline API"
        return 1
    fi
}

# Main test function
main() {
    echo "==============================================="
    echo "N8N Workflow Testing"
    echo "==============================================="
    
    if [[ -z "$OUTLINE_API_KEY" ]]; then
        log_warning "OUTLINE_API_KEY not set in .env file"
    fi
    
    test_outline_api
    test_file_event_webhook
    test_document_processor_webhook
    
    echo
    log_success "Testing completed!"
    echo
    echo "Next steps:"
    echo "1. Import workflows into n8n"
    echo "2. Configure environment variables"
    echo "3. Activate workflows"
    echo "4. Test with real markdown files"
}

main "$@"
EOF

    chmod +x test-workflows.sh
    log_success "Test script created: test-workflows.sh"
}

# =============================================================================
# Create Example Files
# =============================================================================

create_example_files() {
    log_info "Creating example markdown files..."
    
    mkdir -p examples/{projects,guides,technical,personal,research}
    
    # Example project file
    cat > examples/projects/api-design-spec.md << 'EOF'
---
title: "API Design Specification"
description: "Comprehensive API design guidelines and standards"
category: "projects"
tags: [api, design, specification, standards]
collection: "Projects"
author: "John Doe"
created: "2025-11-16"
modified: "2025-11-16"
---

# API Design Specification

## Overview

This document outlines the design standards and specifications for all API endpoints in our system.

## Design Principles

### RESTful Architecture

Our APIs follow REST architectural principles:

- **Resources**: Each endpoint represents a resource
- **HTTP Methods**: Use appropriate HTTP methods (GET, POST, PUT, DELETE)
- **Status Codes**: Return appropriate HTTP status codes
- **URL Structure**: Clean, hierarchical URLs

### Consistency

All APIs must maintain consistency in:

- Request/response formats
- Error handling
- Authentication methods
- Rate limiting behavior

## API Standards

### Authentication

All APIs require authentication via Bearer tokens:

```http
Authorization: Bearer <token>
```

### Response Format

```json
{
  "success": true,
  "data": {},
  "message": "Operation successful"
}
```

### Error Handling

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input parameters",
    "details": []
  }
}
```

## Examples

### Create User

```http
POST /api/users
Content-Type: application/json
Authorization: Bearer <token>

{
  "name": "John Doe",
  "email": "john@example.com"
}
```

## Conclusion

This specification ensures all APIs are consistent, secure, and maintainable.
EOF

    # Example guide file
    cat > examples/guides/getting-started.md << 'EOF'
---
title: "Getting Started Guide"
description: "Complete guide to getting started with our platform"
category: "guides"
tags: [getting-started, tutorial, basics]
collection: "Guides"
author: "Documentation Team"
created: "2025-11-16"
---

# Getting Started Guide

Welcome to our platform! This guide will help you get up and running quickly.

## Prerequisites

Before you begin, ensure you have:

- A valid account
- Basic understanding of our API
- Required authentication credentials

## Quick Start

### Step 1: Authentication

First, you'll need to authenticate with our system:

```javascript
const token = await authenticate(credentials);
```

### Step 2: Make Your First API Call

```javascript
const response = await api.get('/users/me', {
  headers: { Authorization: `Bearer ${token}` }
});
```

### Step 3: Process Response

```javascript
if (response.success) {
  console.log('User data:', response.data);
} else {
  console.error('Error:', response.error);
}
```

## Common Tasks

### Creating Resources

Learn how to create and manage resources:

```javascript
// Create a new resource
const newResource = await api.post('/resources', {
  name: 'My Resource',
  description: 'A sample resource'
});
```

### Handling Errors

Always implement proper error handling:

```javascript
try {
  const result = await riskyOperation();
  processResult(result);
} catch (error) {
  handleError(error);
}
```

## Best Practices

1. **Always validate inputs**
2. **Handle errors gracefully**
3. **Use proper authentication**
4. **Follow rate limiting guidelines**

## Next Steps

- Read our [API Reference](./api-reference.md)
- Explore [Advanced Features](./advanced-features.md)
- Join our [Community Forum](https://forum.example.com)
EOF

    # Example technical file
    cat > examples/technical/architecture.md << 'EOF'
---
title: "System Architecture"
description: "Technical architecture documentation and design decisions"
category: "technical"
tags: [architecture, system-design, microservices]
collection: "Technical Documentation"
author: "Architecture Team"
created: "2025-11-16"
---

# System Architecture

## Overview

Our system is built using a microservices architecture to ensure scalability, maintainability, and fault tolerance.

## Architecture Diagram

```mermaid
graph TB
    A[Client Applications] --> B[API Gateway]
    B --> C[Authentication Service]
    B --> D[User Service]
    B --> E[Content Service]
    B --> F[Notification Service]
    
    C --> G[(User Database)]
    D --> H[(User Database)]
    E --> I[(Content Database)]
    F --> J[(Message Queue)]
```

## Core Services

### API Gateway

The API Gateway serves as the single entry point for all client requests:

- **Load Balancing**: Distributes requests across service instances
- **Authentication**: Handles token validation and user identification
- **Rate Limiting**: Implements request throttling
- **Monitoring**: Collects metrics and health checks

### Authentication Service

Manages user authentication and authorization:

- **Token Generation**: Issues JWT tokens
- **Session Management**: Handles user sessions
- **Permission Checks**: Validates user permissions

### User Service

Handles user-related operations:

- **User Management**: CRUD operations for user accounts
- **Profile Management**: User profile information
- **Preferences**: User settings and configurations

## Technology Stack

### Backend Services

- **Runtime**: Node.js with Express.js
- **Database**: PostgreSQL for relational data
- **Cache**: Redis for session storage
- **Message Queue**: RabbitMQ for async processing

### Infrastructure

- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **Load Balancer**: NGINX
- **Monitoring**: Prometheus + Grafana

## Design Patterns

### Circuit Breaker

Implements circuit breaker pattern for external service calls:

```javascript
const circuitBreaker = new CircuitBreaker(serviceCall, {
  timeout: 3000,
  errorThresholdPercentage: 50,
  resetTimeout: 30000
});
```

### Event Sourcing

Key domain events are stored as a sequence of events:

- User Registered
- Profile Updated
- Permissions Changed

## Security Considerations

### Authentication

- JWT tokens with short expiration
- Refresh token rotation
- HTTPS-only communication

### Authorization

- Role-based access control (RBAC)
- Principle of least privilege
- Resource-level permissions

### Data Protection

- Encryption at rest
- Encryption in transit (TLS 1.3)
- PII data anonymization

## Scalability

### Horizontal Scaling

- Stateless service design
- Database sharding
- CDN for static content

### Performance Optimization

- Database indexing
- Query optimization
- Caching strategies

## Monitoring & Observability

### Metrics

- Request/response times
- Error rates
- Resource utilization
- Business metrics

### Logging

- Structured logging (JSON)
- Centralized log aggregation
- Log retention policies

### Alerting

- Health check failures
- Performance degradation
- Security incidents

## Deployment Strategy

### CI/CD Pipeline

1. **Development**: Feature branches
2. **Testing**: Automated test suites
3. **Staging**: Production-like environment
4. **Production**: Blue-green deployments

### Environment Configuration

- **Development**: Local development
- **Staging**: Pre-production testing
- **Production**: Live environment

## Future Considerations

### Planned Improvements

- **Event-driven architecture**
- **GraphQL integration**
- **Machine learning capabilities**
- **Multi-region deployment**

### Technical Debt

- Database schema optimization
- API versioning strategy
- Legacy system migration
EOF

    # Example personal file
    cat > examples/personal/daily-notes.md << 'EOF'
---
title: "Daily Notes"
description: "Personal daily notes and reflections"
category: "personal"
tags: [personal, daily, notes, reflection]
collection: "Personal Notes"
author: "Personal"
created: "2025-11-16"
---

# Daily Notes - 2025-11-16

## Today's Goals

- [x] Complete system architecture documentation
- [x] Review n8n workflow configurations
- [x] Set up monitoring dashboard
- [ ] Update user documentation
- [ ] Test batch processing workflow

## Key Insights

### System Design Decisions

After reviewing the requirements, I decided to:

1. **Use event-driven architecture** for better scalability
2. **Implement queue-based processing** to handle load spikes
3. **Add comprehensive monitoring** for operational visibility

### Technical Challenges

**Challenge**: Handling file system events reliably across different scenarios

**Solution**: Implemented debouncing and deduplication logic with Redis-backed queues

**Lesson Learned**: Always plan for edge cases in file monitoring systems

## Ideas & Thoughts

### Future Enhancements

- **Smart categorization** using ML for automatic document tagging
- **Multi-format support** for other document types (Word, PDF)
- **Real-time collaboration** features

### Personal Growth

Learning more about:
- Event-driven architectures
- Monitoring and observability
- Security best practices

## Tomorrow's Focus

1. Complete user documentation
2. Set up automated testing
3. Prepare deployment scripts
4. Plan performance testing

## Gratitude

Grateful for:
- Opportunity to work on interesting technical challenges
- Resources available for learning and development
- Supportive team environment

---

*Remember: Small consistent steps lead to big achievements.*
EOF

    log_success "Example files created in examples/ directory"
}

# =============================================================================
# Create Deployment Checklist
# =============================================================================

create_deployment_checklist() {
    log_info "Creating deployment checklist..."
    
    cat > DEPLOYMENT_CHECKLIST.md << 'EOF'
# Deployment Checklist

## Pre-Deployment

- [ ] **Environment Setup**
  - [ ] Copy `.env.template` to `.env`
  - [ ] Update all environment variables
  - [ ] Test environment configuration

- [ ] **n8n Instance Preparation**
  - [ ] Ensure n8n instance is running
  - [ ] Verify webhook endpoints are accessible
  - [ ] Check available memory and storage

- [ ] **Outline Instance Setup**
  - [ ] Verify Outline instance is running
  - [ ] Generate API key with appropriate permissions
  - [ ] Test API connectivity

## Workflow Import

- [ ] **Import Workflow Files**
  - [ ] Import `file-event-processor.json`
  - [ ] Import `document-processor-fixed.json`
  - [ ] Import `batch-processor.json`

- [ ] **Configure Each Workflow**
  - [ ] Update environment variables in each workflow
  - [ ] Create HTTP Header Auth credential
  - [ ] Configure webhook URLs
  - [ ] Set up rate limiting parameters

- [ ] **Test Workflow Import**
  - [ ] Activate all workflows
  - [ ] Test webhook endpoints
  - [ ] Verify execution logs

## Integration Testing

- [ ] **File Event Processing**
  - [ ] Create test markdown file
  - [ ] Verify file event is triggered
  - [ ] Check event processing workflow
  - [ ] Validate API calls to Outline

- [ ] **Document Processing**
  - [ ] Test markdown parsing
  - [ ] Verify collection mapping
  - [ ] Check document creation in Outline
  - [ ] Validate metadata preservation

- [ ] **Batch Processing**
  - [ ] Test batch workflow trigger
  - [ ] Verify batch processing logic
  - [ ] Check completion notifications

## Monitoring Setup

- [ ] **Health Checks**
  - [ ] Configure health check endpoints
  - [ ] Set up monitoring alerts
  - [ ] Test notification system

- [ ] **Performance Monitoring**
  - [ ] Set up execution time tracking
  - [ ] Configure queue size monitoring
  - [ ] Enable error rate alerts

## Security Configuration

- [ ] **Authentication**
  - [ ] Secure API key storage
  - [ ] Configure webhook authentication
  - [ ] Set up rate limiting

- [ ] **Network Security**
  - [ ] Configure firewall rules
  - [ ] Set up HTTPS for all endpoints
  - [ ] Implement CORS policies

## Production Deployment

- [ ] **File Monitoring Service**
  - [ ] Deploy file monitoring service
  - [ ] Configure monitored directories
  - [ ] Test real-time file detection

- [ ] **System Services**
  - [ ] Set up systemd services
  - [ ] Configure log rotation
  - [ ] Set up backup procedures

## Post-Deployment

- [ ] **Verification Tests**
  - [ ] Run end-to-end tests
  - [ ] Verify all workflows are active
  - [ ] Check monitoring dashboard

- [ ] **Documentation**
  - [ ] Update operational procedures
  - [ ] Train operations team
  - [ ] Document known issues

- [ ] **Monitoring**
  - [ ] Watch system metrics for 24 hours
  - [ ] Verify no critical alerts
  - [ ] Review performance metrics

## Rollback Plan

- [ ] **Backup Procedures**
  - [ ] Verify backup of current state
  - [ ] Document rollback steps
  - [ ] Test rollback procedure

- [ ] **Emergency Contacts**
  - [ ] List of technical contacts
  - [ ] On-call procedures
  - [ ] Escalation procedures

## Sign-off

- [ ] **Technical Lead Approval**
- [ ] **Operations Team Approval**
- [ ] **Security Team Approval**
- [ ] **Project Manager Approval**

---

**Deployment Date**: _______________
**Deployed By**: _______________
**Approved By**: _______________
EOF

    log_success "Deployment checklist created: DEPLOYMENT_CHECKLIST.md"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    interactive_setup
    create_environment_config
    test_workflow_endpoints
    generate_import_instructions
    create_test_script
    create_example_files
    create_deployment_checklist
    
    echo
    log_success "==============================================="
    log_success "N8N Workflow Setup Complete!"
    log_success "==============================================="
    echo
    log_info "Next Steps:"
    echo "1. Review the generated files:"
    echo "   - .env (your configuration)"
    echo "   - IMPORT_INSTRUCTIONS.md"
    echo "   - DEPLOYMENT_CHECKLIST.md"
    echo
    echo "2. Import workflows into n8n"
    echo "3. Configure environment variables"
    echo "4. Test with: ./test-workflows.sh"
    echo
    log_info "Files created:"
    ls -la | grep -E "(\.env|IMPORT_INSTRUCTIONS|test-workflows|DEPLOYMENT_CHECKLIST|examples)"
}

main "$@"