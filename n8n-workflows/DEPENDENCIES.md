# N8N Node Dependencies and Requirements

This document outlines the required n8n nodes, packages, and configurations needed to run the Markdown-to-Outline synchronization workflows.

## Required n8n Nodes

### Core Nodes Used

The workflows use the following n8n core nodes:

1. **Webhook Node** (`n8n-nodes-base.webhook`)
   - Purpose: Receive file system events
   - Required: All workflows
   - HTTP Methods: POST
   - Authentication: None (webhook endpoints)
2. **HTTP Request Node** (`n8n-nodes-base.httpRequest`)
   - Purpose: API calls to Outline server
   - Required: Document Processor, Batch Processor
   - Version: 4.1
   - Authentication: Generic Header Auth
3. **Code Node** (`n8n-nodes-base.code`)
   - Purpose: Data transformation and processing
   - Version: 2
   - Required: All workflows
   - Language: JavaScript
4. **IF Node** (`n8n-nodes-base.if`)
   - Purpose: Conditional logic and filtering
   - Version: 2
   - Required: All workflows
   - Conditions: String and Boolean
5. **Respond to Webhook Node** (`n8n-nodes-base.respondToWebhook`)
   - Purpose: Return responses from webhook handlers
   - Required: File Event Processor, Document Processor
   - Response Types: JSON, Status Codes
6. **Execute Command Node** (`n8n-nodes-base.executeCommand`)
   - Purpose: Execute shell commands for file operations
   - Required: Document Processor
   - Security: Restricted execution environment
7. **Set Node** (`n8n-nodes-base.set`)
   - Purpose: Set values in workflow data
   - Required: All workflows (implicitly)
8. **Merge Node** (`n8n-nodes-base.merge`)
   - Purpose: Merge data from multiple branches
   - Optional: Used for complex data flows
9. **Function Node** (Legacy - use Code Node instead)
   - Purpose: Custom JavaScript execution
   - Status: Legacy, use Code Node v2

### Optional Enhancement Nodes

For advanced features, consider adding these nodes:

1. **Cron Node** (`n8n-nodes-base.cron`)
   - Purpose: Scheduled workflow execution
   - Used for: Batch Processor schedule
   - Alternative: Use n8n's built-in scheduler
2. **Slack Node** (`n8n-nodes-base.slack`)
   - Purpose: Send notifications to Slack
   - Used for: Status notifications
   - Installation: @n8n/n8n-nodes-slack
3. **Email Node** (`n8n-nodes-base.emailSend`)
   - Purpose: Send email notifications
   - Used for: Alert notifications
   - SMTP Support: Built-in
4. **Redis Node** (`n8n-nodes-base.redis`)
   - Purpose: Cache and queue operations
   - Used for: Rate limiting, state management
   - Installation: @n8n/n8n-nodes-redis
5. **Webhook Trigger Node** (`n8n-nodes-base.webhook`)
   - Purpose: Additional webhook endpoints
   - Used for: External integrations

## Required Credentials

### 1. HTTP Header Auth

**Name**: `Outline API Auth`

**Configuration**:
```json
{
  "name": "Authorization",
  "value": "Bearer {{ $workflow.settings.outlineApiKey }}"
}
```

**Headers**:
- Authorization: Bearer {api_key}
- Content-Type: application/json
- User-Agent: Markdown-Sync/1.0

**Usage**: All Outline API calls

### 2. SMTP Credentials (Optional)

**Name**: `Alert Email Auth`

**Configuration**:
- SMTP Host: Your SMTP server
- Port: 587 (TLS) or 465 (SSL)
- Username: Your email
- Password: Your app password

**Usage**: Alert notifications

### 3. Redis Credentials (Optional)

**Name**: `Redis Auth`

**Configuration**:
- Host: Redis server address
- Port: 6379
- Database: 0
- Password: (if required)

**Usage**: Rate limiting, caching

## Environment Variables

### Required Settings

Configure these in each workflow's settings:

```javascript
{
  "outlineApiUrl": "https://your-outline-instance.com",
  "outlineApiKey": "your_api_key_here",
  "markdownProcessorWebhook": "https://your-n8n.com/webhook/markdown-processor",
  "monitoringWebhook": "https://your-n8n.com/webhook/monitoring",
  "fileSystemApiUrl": "http://localhost:8080"
}
```

### Optional Settings

```javascript
{
  "batchSize": 10,
  "maxFileSizeMB": 50,
  "eventDebounceSeconds": 2,
  "errorRateThreshold": 0.1,
  "processingTimeThreshold": 30,
  "logLevel": "INFO"
}
```

## Node Version Requirements

| Node Type          | Minimum Version | Recommended Version |
| ------------------ | --------------- | ------------------- |
| Webhook            | 1.0             | Latest              |
| HTTP Request       | 4.0             | 4.1+                |
| Code               | 2.0             | Latest              |
| IF                 | 2.0             | Latest              |
| Respond to Webhook | 1.0             | Latest              |
| Execute Command    | 1.0             | Latest              |

## Installation Steps

### 1. Install Required Nodes

Most required nodes are included in n8n core. For optional nodes:

```bash
# Install Redis node
npm install @n8n/n8n-nodes-redis

# Install Slack node  
npm install @n8n/n8n-nodes-slack

# Install additional utilities
npm install @n8n/n8n-nodes-utils
```

### 2. Configure Credentials

1. Go to n8n Settings → Credentials
2. Add HTTP Header Auth for Outline API
3. Add SMTP credentials for alerts (optional)
4. Add Redis credentials for caching (optional)

### 3. Set Environment Variables

1. Open each imported workflow
2. Go to workflow settings
3. Add the required environment variables
4. Save and activate the workflow

## Security Considerations

### API Key Management

- Store API keys in n8n credentials, not workflow settings
- Use environment variables for sensitive data
- Enable credential encryption in n8n settings
- Regularly rotate API keys

### Webhook Security

- Use HTTPS for all webhook endpoints
- Implement webhook signature verification
- Set up IP whitelisting if possible
- Monitor webhook access logs

### Data Processing

- Validate all input data
- Sanitize file paths and content
- Implement rate limiting
- Log all operations for audit

## Performance Optimization

### Node Configuration

1. **HTTP Request Node**:
   - Connection timeout: 30 seconds
   - Retry attempts: 3
   - Keep connections alive: true
2. **Code Node**:
   - Enable caching for repeated operations
   - Optimize JavaScript execution
   - Use async operations for I/O
3. **Batch Processing**:
   - Use smaller batches for better reliability
   - Implement progress tracking
   - Add error handling for each item

### Resource Management

- Monitor memory usage in large workflows
- Set appropriate execution timeouts
- Use queue-based processing for high volume
- Implement circuit breakers for external calls

## Troubleshooting

### Common Node Issues

1. **HTTP Request failures**:
   - Check API endpoint URLs
   - Verify authentication credentials
   - Test network connectivity
2. **Code Node errors**:
   - Check JavaScript syntax
   - Verify input data structure
   - Review execution logs
3. **Webhook timeouts**:
   - Increase timeout settings
   - Implement async processing
   - Add health check endpoints

### Node-Specific Issues

**Execute Command Node**:
- Ensure proper permissions
- Validate command inputs
- Check environment variables

**Webhook Node**:
- Verify endpoint URL
- Test HTTP methods
- Check CORS settings

## Testing Nodes

### Unit Testing

Each node can be tested individually:

1. Create test input data
2. Execute node in isolation
3. Verify output matches expectations
4. Check error handling

### Integration Testing

Test node interactions:

1. Create complete workflow paths
2. Test end-to-end flows
3. Verify data transformations
4. Check error propagation

### Performance Testing

Monitor node performance:

1. Execution time tracking
2. Memory usage monitoring
3. Resource consumption metrics
4. Throughput testing

## Version Compatibility

### n8n Version Support

- **Minimum**: n8n v1.0.0
- **Recommended**: Latest stable version
- **Tested**: n8n v1.20+

### Node Compatibility

- **Core Nodes**: Always compatible with n8n core
- **Community Nodes**: Check individual node documentation
- **Custom Nodes**: May require specific n8n versions

### API Compatibility

- **Outline API**: Tested with Outline v0.87+
- **Webhook Standards**: HTTP/1.1, HTTPS
- **Authentication**: Bearer token, API key

## Support and Maintenance

### Regular Updates

1. Update n8n to latest stable version
2. Update node packages regularly
3. Review and update API integrations
4. Monitor for security updates

### Monitoring

1. Track workflow execution success rates
2. Monitor node performance metrics
3. Review error logs regularly
4. Set up alerts for failures

### Backup

1. Regular workflow exports
2. Credential backups (securely)
3. Configuration documentation
4. Recovery procedures

---

**Last Updated**: 2025-11-16  
**Version**: 1.0  
**Compatibility**: n8n v1.0+