import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

import '../core/constants.dart';
import '../models/call_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();
  
  final Logger _logger = Logger();
  Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, AppConstants.dbName);
      
      _logger.i('Initializing database at: $path');
      
      return await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      _logger.e('Error initializing database: $e');
      rethrow;
    }
  }
  
  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE ${DatabaseTables.calls} (
          id TEXT PRIMARY KEY,
          phone_number TEXT NOT NULL,
          contact_name TEXT NOT NULL,
          is_incoming INTEGER NOT NULL,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          duration INTEGER,
          status TEXT NOT NULL,
          recording_path TEXT,
          is_scam_suspected INTEGER NOT NULL DEFAULT 0,
          scam_confidence REAL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');
      
      await db.execute('''
        CREATE TABLE ${DatabaseTables.recordings} (
          id TEXT PRIMARY KEY,
          call_id TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_size INTEGER,
          duration INTEGER,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          FOREIGN KEY (call_id) REFERENCES ${DatabaseTables.calls} (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE TABLE ${DatabaseTables.analysisResults} (
          id TEXT PRIMARY KEY,
          call_id TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          type TEXT NOT NULL,
          confidence REAL NOT NULL,
          details TEXT NOT NULL,
          is_scam_indicator INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          FOREIGN KEY (call_id) REFERENCES ${DatabaseTables.calls} (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE TABLE ${DatabaseTables.contacts} (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          phone_number TEXT NOT NULL,
          is_blocked INTEGER NOT NULL DEFAULT 0,
          is_trusted INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');
      
      await db.execute('''
        CREATE TABLE ${DatabaseTables.scamReports} (
          id TEXT PRIMARY KEY,
          call_id TEXT NOT NULL,
          phone_number TEXT NOT NULL,
          report_type TEXT NOT NULL,
          description TEXT,
          confidence REAL,
          reported_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          FOREIGN KEY (call_id) REFERENCES ${DatabaseTables.calls} (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE INDEX idx_calls_phone_number ON ${DatabaseTables.calls} (phone_number)
      ''');
      
      await db.execute('''
        CREATE INDEX idx_calls_start_time ON ${DatabaseTables.calls} (start_time)
      ''');
      
      await db.execute('''
        CREATE INDEX idx_analysis_call_id ON ${DatabaseTables.analysisResults} (call_id)
      ''');
      
      _logger.i('Database tables created successfully');
    } catch (e) {
      _logger.e('Error creating database tables: $e');
      rethrow;
    }
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('Upgrading database from version $oldVersion to $newVersion');
    // Handle database upgrades here
  }
  
  // Call operations
  Future<int> insertCall(CallModel call) async {
    try {
      final db = await database;
      
      final result = await db.insert(
        DatabaseTables.calls,
        {
          'id': call.id,
          'phone_number': call.phoneNumber,
          'contact_name': call.contactName,
          'is_incoming': call.isIncoming ? 1 : 0,
          'start_time': call.startTime.millisecondsSinceEpoch,
          'end_time': call.endTime?.millisecondsSinceEpoch,
          'duration': call.duration?.inMilliseconds,
          'status': call.status.toString(),
          'recording_path': call.recordingPath,
          'is_scam_suspected': call.isScamSuspected ? 1 : 0,
          'scam_confidence': call.scamConfidence,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      _logger.i('Call inserted: ${call.id}');
      return result;
    } catch (e) {
      _logger.e('Error inserting call: $e');
      rethrow;
    }
  }
  
  Future<List<CallModel>> getCalls({int? limit, int? offset}) async {
    try {
      final db = await database;
      
      String query = '''
        SELECT * FROM ${DatabaseTables.calls}
        ORDER BY start_time DESC
      ''';
      
      if (limit != null) {
        query += ' LIMIT $limit';
        if (offset != null) {
          query += ' OFFSET $offset';
        }
      }
      
      final List<Map<String, dynamic>> maps = await db.rawQuery(query);
      
      return maps.map((map) => _callFromMap(map)).toList();
    } catch (e) {
      _logger.e('Error getting calls: $e');
      return [];
    }
  }
  
  Future<CallModel?> getCall(String id) async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseTables.calls,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (maps.isNotEmpty) {
        return _callFromMap(maps.first);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting call: $e');
      return null;
    }
  }
  
  // Analysis results operations
  Future<int> insertAnalysisResult(AnalysisResult result) async {
    try {
      final db = await database;
      
      final insertResult = await db.insert(
        DatabaseTables.analysisResults,
        {
          'id': result.id,
          'call_id': result.callId,
          'timestamp': result.timestamp.millisecondsSinceEpoch,
          'type': result.type.toString(),
          'confidence': result.confidence,
          'details': result.details.toString(),
          'is_scam_indicator': result.isScamIndicator ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      _logger.i('Analysis result inserted: ${result.id}');
      return insertResult;
    } catch (e) {
      _logger.e('Error inserting analysis result: $e');
      rethrow;
    }
  }
  
  Future<List<AnalysisResult>> getAnalysisResults(String callId) async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseTables.analysisResults,
        where: 'call_id = ?',
        whereArgs: [callId],
        orderBy: 'timestamp ASC',
      );
      
      return maps.map((map) => _analysisResultFromMap(map)).toList();
    } catch (e) {
      _logger.e('Error getting analysis results: $e');
      return [];
    }
  }
  
  // Utility methods
  CallModel _callFromMap(Map<String, dynamic> map) {
    return CallModel(
      id: map['id'],
      phoneNumber: map['phone_number'],
      contactName: map['contact_name'],
      isIncoming: map['is_incoming'] == 1,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time']),
      endTime: map['end_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'])
          : null,
      duration: map['duration'] != null 
          ? Duration(milliseconds: map['duration'])
          : null,
      status: CallStatus.values.firstWhere(
        (status) => status.toString() == map['status'],
        orElse: () => CallStatus.ended,
      ),
      recordingPath: map['recording_path'],
      isScamSuspected: map['is_scam_suspected'] == 1,
      scamConfidence: map['scam_confidence']?.toDouble(),
    );
  }
  
  AnalysisResult _analysisResultFromMap(Map<String, dynamic> map) {
    return AnalysisResult(
      id: map['id'],
      callId: map['call_id'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      type: AnalysisType.values.firstWhere(
        (type) => type.toString() == map['type'],
        orElse: () => AnalysisType.deepfakeDetection,
      ),
      confidence: map['confidence'],
      details: map['details'] as Map<String, dynamic>,
      isScamIndicator: map['is_scam_indicator'] == 1,
    );
  }
  
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}