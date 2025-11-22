# N8N Workflows for Markdown-to-Outline Synchronization

This folder contains all the n8n workflows needed to set up automated synchronization between local markdown files and an Outline server.

## 📋 Contents

- **Workflow Files**: Ready-to-import n8n workflow JSON files
- **Configuration Examples**: Environment variables and API setup
- **Documentation**: Setup guides and troubleshooting
- **Dependencies**: Required n8n nodes and packages

## 🚀 Quick Start

### 1. Import Workflows

1. Copy the workflow JSON files from this folder
2. In n8n: Settings → Import from file
3. Import each workflow:
   - `file-event-processor.json`
   - `document-processor.json` (use the fixed version)
   - `batch-processor.json`

### 2. Configure Environment Variables

Update these variables in each workflow's settings:

```javascript
outlineApiUrl: "https://your-outline-server.com"
outlineApiKey: "your_api_key_here"
markdownProcessorWebhook: "https://your-n8n-instance.com/webhook/markdown-processor"
monitoringWebhook: "https://your-n8n-instance.com/webhook/monitoring"
```

### 3. Set Up API Credentials

Create HTTP Header Auth credentials in n8n:
- **Name**: Outline API Auth
- **Headers**: 
  - Authorization: Bearer {{ $workflow.settings.outlineApiKey }}
  - Content-Type: application/json

### 4. Activate Workflows

1. Open each imported workflow
2. Click "Activate" to enable them
3. Test with a sample markdown file

## 📁 Workflow Descriptions

### 1. File Event Processor (`file-event-processor.json`)

- **Purpose**: Receives file system events from the monitoring service
- **Trigger**: Webhook endpoint
- **Function**: Validates events and routes to document processor
- **Webhook URL**: `https://your-n8n.com/webhook/markdown-file-event`

### 2. Document Processor (`document-processor.json`)

- **Purpose**: Processes markdown files and creates/updates Outline documents
- **Trigger**: Webhook from file event processor
- **Function**: Reads files, parses metadata, creates collections, syncs to Outline
- **Webhook URL**: `https://your-n8n.com/webhook/markdown-processor`

### 3. Batch Processor (`batch-processor.json`)

- **Purpose**: Handles bulk document processing on schedule
- **Trigger**: Cron schedule (every 6 hours)
- **Function**: Scans directories, processes multiple files efficiently
- **Schedule**: `0 */6 * * *` (every 6 hours)

## 🔧 Configuration Requirements

### Required Environment Variables

Update each workflow's settings with:

```javascript
{
  "outlineApiUrl": "https://your-outline-server.com",
  "outlineApiKey": "your_outline_api_key",
  "markdownProcessorWebhook": "https://your-n8n-instance.com/webhook/markdown-processor",
  "monitoringWebhook": "https://your-n8n-instance.com/webhook/monitoring",
  "fileSystemApiUrl": "http://localhost:8080",
  "monitoringApiKey": "your_monitoring_api_key"
}
```

### Outline API Setup

1. Get your Outline API key from your Outline instance
2. Ensure the API key has permissions for:
   - Reading collections
   - Creating/updating documents
   - Creating collections (if needed)

### File Structure

The workflows expect this directory structure:

```
📁 /documents/
├── 📁 projects/         → Projects Collection
├── 📁 guides/           → Guides Collection
├── 📁 technical/        → Technical Documentation
├── 📁 personal/         → Personal Notes
└── 📁 research/         → Research Collection
```

## 🔄 Workflow Flow

```
File Created/Modified
       ↓
File Monitor Service
       ↓
File Event Processor (Webhook)
       ↓
Document Processor
       ↓
Markdown Content Parsing
       ↓
Collection Mapping
       ↓
Outline API Integration
       ↓
Document Created/Updated
       ↓
Audit Logging
```

## 🛠️ Testing

### Test File Event Processor

Send a test webhook:

```bash
curl -X POST https://your-n8n.com/webhook/markdown-file-event \
  -H "Content-Type: application/json" \
  -d '{
    "filePath": "/documents/projects/test.md",
    "fileName": "test.md",
    "directory": "/documents/projects",
    "eventType": "CREATE",
    "category": "projects",
    "timestamp": "2025-11-16T16:42:19Z"
  }'
```

### Test Document Processor

Create a test markdown file:

```markdown
---
title: "Test Document"
description: "A test document"
category: "projects"
---

# Test Document

This is a test document for the workflow.
```

## 🐛 Troubleshooting

### Common Issues

1. **Workflow not triggering**
   - Check webhook URLs are correct
   - Verify workflow is activated
   - Test webhook endpoint
2. **API authentication errors**
   - Verify Outline API key is correct
   - Check API key permissions
   - Test API connectivity
3. **File not found errors**
   - Ensure file monitoring service is running
   - Check file paths are correct
   - Verify file permissions

### Debug Mode

Enable debug logging in each workflow:
1. Open workflow settings
2. Add: `debug: true`
3. Check execution logs for details

## 📊 Monitoring

Each workflow includes:
- Execution time tracking
- Success/failure metrics
- Error logging and reporting
- Performance monitoring

Access execution data in n8n's executions panel.

## 🔒 Security

- API keys stored securely in n8n credentials
- Webhook endpoints protected
- Rate limiting implemented
- Audit logging for all operations

## 📞 Support

For issues:
1. Check n8n execution logs
2. Verify configuration settings
3. Test API connectivity
4. Review file monitoring service status

## 📝 Notes

- Workflows are designed for production use
- Include error handling and retry logic
- Support both real-time and batch processing
- Maintain audit trail for compliance

---

**Version**: 1.0  
**Last Updated**: 2025-11-16  
**n8n Compatibility**: v1.0+