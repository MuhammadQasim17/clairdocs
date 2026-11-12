import 'dart:ffi';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import '../models/audit_record.dart';

/// Local SQLite persistence service backing ClairDocs' Audit Vault (`clairdocs_vault.db`).
class AuditDatabaseService {
  static const String databaseFileName = 'clairdocs_vault.db';
  static const String auditsTable = 'audits';
  static const int _schemaVersion = 1;

  static bool _ffiInitialized = false;

  final String? databasePathOverride;
  Database? _db;
  Future<Database>? _openingFuture;

  AuditDatabaseService({this.databasePathOverride});

  /// Initializes native SQLite runtime hooks (`sqlite3_flutter_libs`) and
  /// desktop FFI bindings before opening `clairdocs_vault.db`.
  static Future<void> ensureInitialized() => _ensurePlatformFactory();

  static Future<void> _ensurePlatformFactory() async {
    // Initialize sqlite3_flutter_libs runtime hook before opening any FFI DB.
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    if (Platform.isWindows || Platform.isLinux) {
      if (!_ffiInitialized) {
        if (Platform.isWindows) {
          _preloadBundledWindowsSqlite();
        }
        sqfliteFfiInit();
        _ffiInitialized = true;
      }
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Ensures the `sqlite3.dll` bundled by `sqlite3_flutter_libs` next to the
  /// Windows executable is loaded even when launched outside the build directory.
  static void _preloadBundledWindowsSqlite() {
    try {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      final bundledDll = File(p.join(exeDir, 'sqlite3.dll'));
      if (bundledDll.existsSync()) {
        DynamicLibrary.open(bundledDll.path);
      }
    } catch (_) {
      // Fall through to sqflite_common_ffi / hook asset DLL loading.
    }
  }

  Future<String> _resolveDatabasePath() async {
    final override = databasePathOverride;
    if (override != null && override.isNotEmpty) {
      if (override != inMemoryDatabasePath) {
        final parent = Directory(p.dirname(override));
        if (!await parent.exists()) {
          await parent.create(recursive: true);
        }
      }
      return override;
    }

    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null && localAppData.isNotEmpty) {
        final vaultDir = Directory(p.join(localAppData, 'ClairDocs'));
        if (!await vaultDir.exists()) {
          await vaultDir.create(recursive: true);
        }
        return p.join(vaultDir.path, databaseFileName);
      }
    }

    final dbRoot = await getDatabasesPath();
    final rootDir = Directory(dbRoot);
    if (!await rootDir.exists()) {
      await rootDir.create(recursive: true);
    }
    return p.join(dbRoot, databaseFileName);
  }

  Future<Database> _getDatabase() async {
    final existing = _db;
    if (existing != null && existing.isOpen) {
      return existing;
    }
    final pending = _openingFuture;
    if (pending != null) {
      return pending;
    }

    final future = _openAndMigrate();
    _openingFuture = future;
    try {
      final db = await future;
      _db = db;
      return db;
    } finally {
      if (identical(_openingFuture, future)) {
        _openingFuture = null;
      }
    }
  }

  Future<Database> _openAndMigrate() async {
    await _ensurePlatformFactory();
    final dbPath = await _resolveDatabasePath();
    return openDatabase(
      dbPath,
      version: _schemaVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $auditsTable (
            id TEXT PRIMARY KEY,
            timestamp TEXT NOT NULL,
            contract_name TEXT NOT NULL,
            invoice_name TEXT NOT NULL,
            vendor_name TEXT NOT NULL,
            invoiced_total REAL NOT NULL,
            contract_base REAL NOT NULL,
            total_variance REAL NOT NULL,
            findings_json TEXT NOT NULL,
            notice_text TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_audits_timestamp ON $auditsTable(timestamp DESC)
        ''');
      },
    );
  }

  Future<void> saveAuditRecord(AuditRecord record) async {
    final db = await _getDatabase();
    await db.insert(
      auditsTable,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AuditRecord>> fetchAllAudits() async {
    final db = await _getDatabase();
    final rows = await db.query(
      auditsTable,
      orderBy: 'timestamp DESC',
    );
    return rows.map(AuditRecord.fromMap).toList(growable: false);
  }

  Future<void> deleteAuditRecord(String id) async {
    final db = await _getDatabase();
    await db.delete(
      auditsTable,
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}
