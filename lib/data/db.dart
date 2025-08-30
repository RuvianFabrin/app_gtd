import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "GtdPlus.db";
  // MODIFICADO: Versão incrementada para 3
  static const _databaseVersion = 3;

  static const gtdItemsTable = 'gtd_items';
  static const projectsTable = 'projects'; // NOVO: Nome da tabela de projetos

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Cria a tabela de itens GTD
    await db.execute('''
      CREATE TABLE $gtdItemsTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        status INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        dueDate TEXT,
        project TEXT,
        recurrence INTEGER,
        reminderOffsets TEXT,
        weeklyRecurrenceDays TEXT
      )
    ''');
    // NOVO: Cria a tabela de projetos
    await db.execute('''
      CREATE TABLE $projectsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        totalMinutesSpent INTEGER NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $gtdItemsTable ADD COLUMN recurrence INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE $gtdItemsTable ADD COLUMN reminderOffsets TEXT');
      await db.execute('ALTER TABLE $gtdItemsTable ADD COLUMN weeklyRecurrenceDays TEXT');
    }
    // NOVO: Script de migração para a versão 3
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE $projectsTable (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          totalMinutesSpent INTEGER NOT NULL
        )
      ''');
    }
  }
}
