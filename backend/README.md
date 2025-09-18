# SCAI Backend Server

A Node.js backend server for the SCAI Flutter app that provides audio analysis capabilities.

## Features

- Audio file upload and analysis
- Mock scam detection with confidence scores
- Analysis history management
- RESTful API endpoints
- Detailed logging and error handling

## Installation

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Start the server:
```bash
npm start
```

For development with auto-reload:
```bash
npm run dev
```

## API Endpoints

### Health Check
- **GET** `/health`
- Returns server status and timestamp

### Analyze Audio
- **POST** `/analyze-audio`
- Upload audio file for scam analysis
- Form data: `audio` (file), optional metadata
- Returns analysis results with confidence score

### Get Analysis History
- **GET** `/get-analysis-history`
- Query params: `limit`, `scamOnly`
- Returns list of previous analyses

### Update Analysis Status
- **PUT** `/update-analysis-status/:id`
- Update existing analysis record
- Body: JSON with fields to update

### Get Specific Analysis
- **GET** `/analysis/:id`
- Returns specific analysis by ID

## Server Configuration

- **Port**: 3000 (default)
- **Upload Limit**: 50MB
- **Supported Formats**: Audio files only
- **Storage**: Local filesystem + in-memory

## Testing

Test the server with curl:

```bash
# Health check
curl http://localhost:3000/health

# Upload audio file
curl -X POST -F "audio=@test.wav" http://localhost:3000/analyze-audio

# Get history
curl http://localhost:3000/get-analysis-history
```
