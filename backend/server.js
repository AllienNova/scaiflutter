const express = require('express');
const multer = require('multer');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs-extra');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, 'uploads');
fs.ensureDirSync(uploadsDir);

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueName = `${Date.now()}-${uuidv4()}-${file.originalname}`;
    cb(null, uniqueName);
  }
});

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024 // 50MB limit
  },
  fileFilter: (req, file, cb) => {
    // Accept audio files
    if (file.mimetype.startsWith('audio/')) {
      cb(null, true);
    } else {
      cb(new Error('Only audio files are allowed!'), false);
    }
  }
});

// In-memory storage for analysis results (in production, use a database)
let analysisHistory = [];
let chunkAnalysisHistory = [];
let liveAnalysisSessions = new Map();

// Mock scam types and analysis logic
const SCAM_TYPES = [
  'ROBOCALL',
  'PHISHING',
  'TECH_SUPPORT',
  'IRS_SCAM',
  'LOTTERY_SCAM',
  'ROMANCE_SCAM',
  'INVESTMENT_FRAUD',
  'CHARITY_SCAM',
  'LEGITIMATE'
];

const RISK_LEVELS = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

// Generate mock analysis results
function generateMockAnalysis(audioFile) {
  const isScam = Math.random() > 0.6; // 40% chance of being a scam
  const confidenceScore = isScam
    ? Math.floor(Math.random() * 40) + 60  // 60-100 for scams
    : Math.floor(Math.random() * 60) + 10; // 10-70 for legitimate

  const scamType = isScam
    ? SCAM_TYPES[Math.floor(Math.random() * (SCAM_TYPES.length - 1))]
    : 'LEGITIMATE';

  const riskLevel = confidenceScore >= 80 ? 'CRITICAL' :
                   confidenceScore >= 60 ? 'HIGH' :
                   confidenceScore >= 40 ? 'MEDIUM' : 'LOW';

  return {
    id: uuidv4(),
    fileName: audioFile.filename,
    originalName: audioFile.originalname,
    confidenceScore,
    scamType,
    riskLevel,
    isScam,
    analysisTimestamp: new Date().toISOString(),
    fileSize: audioFile.size,
    duration: Math.floor(Math.random() * 300) + 30, // 30-330 seconds
    keywords: isScam ? ['suspicious', 'urgent', 'verify', 'account'] : ['normal', 'conversation'],
    flags: isScam ? ['SUSPICIOUS_KEYWORDS', 'PRESSURE_TACTICS'] : []
  };
}

// Generate mock chunk analysis results
function generateMockChunkAnalysis(audioFile, chunkNumber, totalChunks, callId) {
  const scamProbability = Math.random() * 100;
  const confidenceScore = 75 + Math.random() * 25; // 75-100

  const detectedPatterns = [];
  const riskIndicators = [];

  if (scamProbability > 50) {
    detectedPatterns.push({
      id: uuidv4(),
      name: 'Urgency Tactics',
      description: 'Caller using urgent language to pressure response',
      confidence: 0.8,
      detected_at: new Date().toISOString()
    });
    riskIndicators.push('Suspicious keywords detected');
  }

  if (scamProbability > 70) {
    detectedPatterns.push({
      id: uuidv4(),
      name: 'Authority Impersonation',
      description: 'Caller claiming to be from government or official organization',
      confidence: 0.9,
      detected_at: new Date().toISOString()
    });
    riskIndicators.push('Authority impersonation detected');
  }

  if (scamProbability > 80) {
    riskIndicators.push('Request for personal information');
  }

  return {
    chunk_analysis_id: uuidv4(),
    call_id: callId,
    chunk_number: chunkNumber,
    total_chunks: totalChunks,
    scam_probability: scamProbability,
    detected_patterns: detectedPatterns,
    confidence_score: confidenceScore,
    risk_indicators: riskIndicators,
    analyzed_at: new Date().toISOString(),
    chunk_duration_seconds: 10,
    file_name: audioFile.filename,
    file_size: audioFile.size
  };
}

// Logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.url}`);
  if (req.body && Object.keys(req.body).length > 0) {
    console.log('Request Body:', JSON.stringify(req.body, null, 2));
  }
  next();
});

// Routes

// Health check endpoint
app.get('/health', (req, res) => {
  console.log('Health check requested');
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    server: 'SCAI Backend v1.0.0'
  });
});

// Analyze audio endpoint
app.post('/analyze-audio', upload.single('audio'), async (req, res) => {
  try {
    console.log('=== AUDIO ANALYSIS REQUEST ===');
    console.log('File received:', req.file ? req.file.originalname : 'No file');
    console.log('Request metadata:', req.body);
    
    if (!req.file) {
      console.log('ERROR: No audio file provided');
      return res.status(400).json({ 
        error: 'No audio file provided',
        timestamp: new Date().toISOString()
      });
    }

    // Simulate processing time
    console.log('Processing audio file...');
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Generate mock analysis
    const analysis = generateMockAnalysis(req.file);
    
    // Add metadata from request
    if (req.body.phoneNumber) analysis.phoneNumber = req.body.phoneNumber;
    if (req.body.callType) analysis.callType = req.body.callType;
    if (req.body.callDuration) analysis.callDuration = parseInt(req.body.callDuration);
    if (req.body.timestamp) analysis.callTimestamp = req.body.timestamp;

    // Store in history
    analysisHistory.push(analysis);

    console.log('=== ANALYSIS COMPLETE ===');
    console.log('Analysis ID:', analysis.id);
    console.log('Confidence Score:', analysis.confidenceScore);
    console.log('Scam Type:', analysis.scamType);
    console.log('Risk Level:', analysis.riskLevel);
    console.log('==============================');

    res.json({
      success: true,
      analysis,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error analyzing audio:', error);
    res.status(500).json({ 
      error: 'Internal server error during analysis',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Analyze audio chunk endpoint for live analysis
app.post('/analyze-chunk', upload.single('audio'), async (req, res) => {
  try {
    console.log('=== CHUNK ANALYSIS REQUEST ===');
    console.log('File received:', req.file ? req.file.originalname : 'No file');
    console.log('Chunk metadata:', req.body);

    if (!req.file) {
      console.log('ERROR: No audio chunk provided');
      return res.status(400).json({
        error: 'No audio chunk provided',
        timestamp: new Date().toISOString()
      });
    }

    const { call_id, chunk_number, total_chunks } = req.body;

    if (!call_id || !chunk_number) {
      console.log('ERROR: Missing required chunk metadata');
      return res.status(400).json({
        error: 'Missing call_id or chunk_number',
        timestamp: new Date().toISOString()
      });
    }

    // Simulate processing time (shorter for chunks)
    console.log(`Processing chunk ${chunk_number} for call ${call_id}...`);
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Generate mock chunk analysis
    const chunkAnalysis = generateMockChunkAnalysis(
      req.file,
      parseInt(chunk_number),
      parseInt(total_chunks) || 0,
      call_id
    );

    // Add metadata from request
    if (req.body.phone_number) chunkAnalysis.phone_number = req.body.phone_number;
    if (req.body.is_incoming) chunkAnalysis.is_incoming = req.body.is_incoming === 'true';

    // Store in chunk history
    chunkAnalysisHistory.push(chunkAnalysis);

    // Update live session if exists
    if (liveAnalysisSessions.has(call_id)) {
      const session = liveAnalysisSessions.get(call_id);
      session.chunk_results.push(chunkAnalysis);
      session.processed_chunks = parseInt(chunk_number);
      session.last_updated = new Date().toISOString();
      liveAnalysisSessions.set(call_id, session);
    }

    console.log('=== CHUNK ANALYSIS COMPLETE ===');
    console.log('Chunk Analysis ID:', chunkAnalysis.chunk_analysis_id);
    console.log('Scam Probability:', chunkAnalysis.scam_probability);
    console.log('Patterns Detected:', chunkAnalysis.detected_patterns.length);
    console.log('================================');

    res.json({
      success: true,
      chunk_analysis: chunkAnalysis,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error analyzing chunk:', error);
    res.status(500).json({
      error: 'Internal server error during chunk analysis',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Start live analysis session endpoint
app.post('/start-live-analysis', (req, res) => {
  try {
    console.log('=== START LIVE ANALYSIS SESSION ===');
    console.log('Session data:', req.body);

    const { call_id, phone_number, is_incoming } = req.body;

    if (!call_id) {
      return res.status(400).json({
        error: 'Missing call_id',
        timestamp: new Date().toISOString()
      });
    }

    const session = {
      id: uuidv4(),
      call_id,
      phone_number: phone_number || 'Unknown',
      is_incoming: is_incoming || false,
      started_at: new Date().toISOString(),
      is_active: true,
      chunk_results: [],
      processed_chunks: 0,
      total_chunks: 0,
      last_updated: new Date().toISOString()
    };

    liveAnalysisSessions.set(call_id, session);

    console.log('Live analysis session started:', session.id);

    res.json({
      success: true,
      session,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error starting live analysis session:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Stop live analysis session endpoint
app.post('/stop-live-analysis', (req, res) => {
  try {
    console.log('=== STOP LIVE ANALYSIS SESSION ===');
    console.log('Request data:', req.body);

    const { call_id } = req.body;

    if (!call_id) {
      return res.status(400).json({
        error: 'Missing call_id',
        timestamp: new Date().toISOString()
      });
    }

    if (!liveAnalysisSessions.has(call_id)) {
      return res.status(404).json({
        error: 'Live analysis session not found',
        timestamp: new Date().toISOString()
      });
    }

    const session = liveAnalysisSessions.get(call_id);
    session.is_active = false;
    session.ended_at = new Date().toISOString();
    session.last_updated = new Date().toISOString();

    liveAnalysisSessions.set(call_id, session);

    console.log('Live analysis session stopped:', session.id);

    res.json({
      success: true,
      session,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error stopping live analysis session:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Get live analysis session endpoint
app.get('/live-analysis/:call_id', (req, res) => {
  try {
    console.log('=== GET LIVE ANALYSIS SESSION ===');
    console.log('Call ID:', req.params.call_id);

    const callId = req.params.call_id;

    if (!liveAnalysisSessions.has(callId)) {
      return res.status(404).json({
        error: 'Live analysis session not found',
        timestamp: new Date().toISOString()
      });
    }

    const session = liveAnalysisSessions.get(callId);

    res.json({
      success: true,
      session,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error getting live analysis session:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Get analysis history endpoint
app.get('/get-analysis-history', (req, res) => {
  console.log('=== ANALYSIS HISTORY REQUEST ===');
  console.log('Query parameters:', req.query);
  
  let filteredHistory = [...analysisHistory];
  
  // Apply filters
  if (req.query.limit) {
    const limit = parseInt(req.query.limit);
    filteredHistory = filteredHistory.slice(-limit);
  }
  
  if (req.query.scamOnly === 'true') {
    filteredHistory = filteredHistory.filter(item => item.isScam);
  }
  
  console.log(`Returning ${filteredHistory.length} analysis records`);
  
  res.json({
    success: true,
    history: filteredHistory.reverse(), // Most recent first
    total: analysisHistory.length,
    timestamp: new Date().toISOString()
  });
});

// Update analysis status endpoint
app.put('/update-analysis-status/:id', (req, res) => {
  console.log('=== UPDATE ANALYSIS STATUS ===');
  console.log('Analysis ID:', req.params.id);
  console.log('Update data:', req.body);
  
  const analysisId = req.params.id;
  const analysisIndex = analysisHistory.findIndex(item => item.id === analysisId);
  
  if (analysisIndex === -1) {
    console.log('ERROR: Analysis not found');
    return res.status(404).json({ 
      error: 'Analysis not found',
      timestamp: new Date().toISOString()
    });
  }
  
  // Update the analysis
  analysisHistory[analysisIndex] = {
    ...analysisHistory[analysisIndex],
    ...req.body,
    updatedAt: new Date().toISOString()
  };
  
  console.log('Analysis updated successfully');
  
  res.json({
    success: true,
    analysis: analysisHistory[analysisIndex],
    timestamp: new Date().toISOString()
  });
});

// Get specific analysis endpoint
app.get('/analysis/:id', (req, res) => {
  console.log('=== GET SPECIFIC ANALYSIS ===');
  console.log('Analysis ID:', req.params.id);
  
  const analysis = analysisHistory.find(item => item.id === req.params.id);
  
  if (!analysis) {
    console.log('ERROR: Analysis not found');
    return res.status(404).json({ 
      error: 'Analysis not found',
      timestamp: new Date().toISOString()
    });
  }
  
  console.log('Analysis found and returned');
  
  res.json({
    success: true,
    analysis,
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Server Error:', error);
  res.status(500).json({ 
    error: 'Internal server error',
    message: error.message,
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use((req, res) => {
  console.log(`404 - Route not found: ${req.method} ${req.url}`);
  res.status(404).json({ 
    error: 'Route not found',
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, () => {
  console.log('=================================');
  console.log('🚀 SCAI Backend Server Started');
  console.log(`📡 Server running on port ${PORT}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/health`);
  console.log(`📁 Uploads directory: ${uploadsDir}`);
  console.log('=================================');
});

module.exports = app;
