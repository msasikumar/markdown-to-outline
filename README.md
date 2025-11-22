# Markdown-to-Outline Synchronization

Automated synchronization system that seamlessly syncs local markdown files with an [Outline](https://www.getoutline.com/) knowledge base using [n8n](https://n8n.io/) workflow automation.

## Overview

This project provides a robust, scalable solution for keeping your local markdown documentation synchronized with an Outline server. It monitors your file system for changes and automatically creates, updates, or organizes documents in Outline based on your local markdown structure.

### Key Features

- **Real-time Synchronization**: Automatic detection and sync of markdown file changes
- **Batch Processing**: Scheduled bulk synchronization for existing documents
- **Smart Mapping**: Directory structure automatically maps to Outline collections
- **Metadata Support**: Front matter YAML for rich document metadata
- **Conflict Resolution**: Intelligent handling of concurrent modifications
- **Comprehensive Logging**: Full audit trail and monitoring capabilities

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   File System   │    │   n8n Workflow   │    │  Outline API    │
│   Monitoring    │───▶│   Orchestration  │───▶│  Integration    │
│   (inotify)     │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

The system consists of three main components:

1. **File System Monitoring**: Watches for markdown file changes using inotify
2. **n8n Workflow Engine**: Processes events and orchestrates document operations
3. **Outline API Integration**: Creates/updates documents in your Outline instance

For detailed architecture information, see [markdown-outline-sync-architecture.md](markdown-outline-sync-architecture.md).

## Quick Start

### Prerequisites

- An [Outline](https://www.getoutline.com/) server instance
- An [n8n](https://n8n.io/) instance (self-hosted or cloud)
- Outline API key ([how to get one](https://www.getoutline.com/developers))
- Node.js and npm (for local development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/msasikumar/markdown-to-outline.git
   cd markdown-to-outline
   ```

2. **Set up n8n workflows**
   ```bash
   cd n8n-workflows
   cp .env.template .env
   # Edit .env with your Outline API credentials
   ```

3. **Import workflows into n8n**
   - Open your n8n instance
   - Navigate to Settings → Import from file
   - Import these workflows:
     - `file-event-processor.json`
     - `document-processor-fixed.json`
     - `batch-processor.json`

4. **Configure workflows**
   - Update environment variables in each workflow
   - Set up Outline API credentials
   - Configure webhook URLs
   - Activate all workflows

For detailed setup instructions, see [n8n-workflows/README.md](n8n-workflows/README.md).

## Usage

### File Organization

Organize your markdown files in directories that map to Outline collections:

```
📁 /documents/
├── 📁 projects/         → Projects Collection in Outline
├── 📁 guides/           → Guides Collection
├── 📁 technical/        → Technical Documentation
├── 📁 personal/         → Personal Notes
└── 📁 research/         → Research Collection
```

### Markdown Front Matter

Add YAML front matter to your markdown files for enhanced metadata:

```yaml
---
title: "Getting Started Guide"
description: "Introduction to the markdown-to-outline sync system"
category: "guides"
tags: [tutorial, getting-started, documentation]
collection: "Guides"
visibility: "team"
---

# Your Content Here

Your markdown content goes here...
```

### Supported Front Matter Fields

- `title`: Document title (required)
- `description`: Brief summary for Outline
- `category`: Document category
- `tags`: Array of tags
- `collection`: Target Outline collection name
- `parent_doc`: Parent document ID for hierarchy
- `outline_id`: Existing document ID for updates
- `visibility`: Document visibility (private, team, public)
- `author`: Document author
- `created`: Creation date
- `modified`: Last modification date

## Workflows

### 1. File Event Processor
Receives file system events and validates markdown files for processing.

**Webhook**: `/webhook/markdown-file-event`

### 2. Document Processor
Processes markdown files, extracts metadata, and syncs to Outline.

**Webhook**: `/webhook/markdown-processor`

### 3. Batch Processor
Scheduled bulk processing of existing markdown files.

**Schedule**: Every 6 hours (configurable)

## Configuration

### Environment Variables

Create a `.env` file in the `n8n-workflows` directory:

```bash
OUTLINE_URL=https://your-outline-server.com
OUTLINE_API_KEY=your_api_key_here
N8N_WEBHOOK_URL=https://your-n8n-instance.com
MONITORING_API_KEY=your_monitoring_key
```

### Workflow Settings

Update each workflow's settings with:

```javascript
{
  "outlineApiUrl": "https://your-outline-server.com",
  "outlineApiKey": "your_outline_api_key",
  "markdownProcessorWebhook": "https://your-n8n.com/webhook/markdown-processor",
  "monitoringWebhook": "https://your-n8n.com/webhook/monitoring"
}
```

## Features in Detail

### Real-time Synchronization
- Monitors file system using inotify for instant change detection
- Processes create, modify, delete, and move events
- Minimal latency between local changes and Outline updates

### Conflict Resolution
- Detects concurrent modifications using content hashing
- Configurable resolution strategies (local wins, Outline wins, manual)
- Creates conflict copies when both sources have changes

### Error Handling
- Automatic retry with exponential backoff
- Dead letter queue for failed operations
- Comprehensive error logging and alerts

### Rate Limiting
- Respects Outline API rate limits
- Adaptive throttling based on response headers
- Queue-based processing to prevent overload

## Monitoring & Observability

### Metrics
- Files processed (total, success, failures)
- Processing duration and latency
- API response times
- Queue sizes and backlogs

### Health Checks
- Outline API connectivity
- n8n workflow status
- File monitoring service status

### Logging
All operations are logged with:
- Timestamp and severity level
- Event type and source file
- Outline document ID
- Processing duration
- Error details (if any)

## Troubleshooting

### Common Issues

**Workflow not triggering**
- Verify webhook URLs are correct
- Check that workflows are activated
- Test webhook endpoints manually

**API authentication errors**
- Verify Outline API key is valid
- Check API key has required permissions
- Test API connectivity with curl

**File not found errors**
- Ensure file monitoring service is running
- Verify file paths are correct
- Check file permissions

For more troubleshooting tips, see [n8n-workflows/README.md](n8n-workflows/README.md#-troubleshooting).

## Project Structure

```
markdown-to-outline/
├── README.md                              # This file
├── markdown-outline-sync-architecture.md  # Detailed architecture
└── n8n-workflows/                         # n8n workflow files
    ├── README.md                          # Workflow setup guide
    ├── DEPENDENCIES.md                    # Required dependencies
    ├── .env.template                      # Environment template
    ├── file-event-processor.json          # File monitoring workflow
    ├── document-processor-fixed.json      # Document processing workflow
    ├── document-processor.json            # Alternative processor
    ├── batch-processor.json               # Batch processing workflow
    ├── setup-workflows.sh                 # Setup script
    └── test-workflows.sh                  # Testing script
```

## Security Considerations

- **API Keys**: Store securely in environment variables with rotation
- **Webhook Security**: Use HMAC-SHA256 for webhook verification
- **TLS/SSL**: All API communications use TLS 1.3
- **Access Control**: Role-based access to monitored directories
- **Audit Logging**: Complete audit trail for compliance

## Contributing

Contributions are welcome! Please feel free to submit issues, fork the repository, and create pull requests.

## License

This project is open source. Please check the LICENSE file for details.

## Support

For issues or questions:
1. Check the [troubleshooting guide](n8n-workflows/README.md#-troubleshooting)
2. Review [detailed architecture documentation](markdown-outline-sync-architecture.md)
3. Open an issue on GitHub

## Roadmap

- [ ] Two-way synchronization (Outline → Local)
- [ ] Support for additional file formats
- [ ] Web UI for configuration and monitoring
- [ ] Docker compose for easy deployment
- [ ] Integration with additional knowledge bases
- [ ] Advanced conflict resolution UI

## Acknowledgments

Built with:
- [Outline](https://www.getoutline.com/) - Open source team knowledge base
- [n8n](https://n8n.io/) - Workflow automation platform
- [inotify](https://man7.org/linux/man-pages/man7/inotify.7.html) - Linux file system monitoring

---

**Version**: 1.0
**Last Updated**: 2025-01-22
**Maintained by**: [msasikumar](https://github.com/msasikumar)
