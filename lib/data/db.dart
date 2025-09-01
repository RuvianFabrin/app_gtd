import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "GtdPlus.db";
  // MODIFICADO: Versão incrementada para forçar a migração segura sem perda de dados.
  static const _databaseVersion = 9;

  static const gtdItemsTable = 'gtd_items';
  static const projectsTable = 'projects';

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

  // Define a estrutura correta e final das tabelas.
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $gtdItemsTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        status INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        lastUpdatedAt TEXT NOT NULL,
        dueDate TEXT,
        project TEXT,
        recurrence INTEGER,
        reminderOffsets TEXT,
        weeklyRecurrenceDays TEXT,
        tags TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE $projectsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        tags TEXT,
        createdAt TEXT NOT NULL,
        lastUpdatedAt TEXT NOT NULL,
        totalMinutesSpent INTEGER NOT NULL
      )
    ''');
  }

  // MODIFICADO: Este método agora executa uma migração segura que preserva os dados.
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 1. Cria uma tabela temporária com a estrutura final e correta.
    await db.execute('''
      CREATE TABLE projects_temp (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        tags TEXT,
        createdAt TEXT NOT NULL,
        lastUpdatedAt TEXT NOT NULL,
        totalMinutesSpent INTEGER NOT NULL
      )
    ''');
    
    // 2. Verifica as colunas que realmente existem na tabela antiga.
    final columns = (await db.rawQuery('PRAGMA table_info($projectsTable)'))
        .map((col) => col['name'] as String)
        .toList();
    
    // 3. Define valores padrão para as colunas que podem estar faltando.
    final String descriptionCol = columns.contains('description') ? 'description' : 'NULL';
    final String tagsCol = columns.contains('tags') ? 'tags' : 'NULL';
    final String createdAtCol = columns.contains('createdAt') ? 'createdAt' : "'${DateTime.now().toIso8601String()}'";
    final String lastUpdatedAtCol = columns.contains('lastUpdatedAt') ? 'lastUpdatedAt' : "'${DateTime.now().toIso8601String()}'";
    
    // 4. Copia os dados da tabela antiga para a nova, preenchendo os campos que faltam.
    await db.rawInsert('''
      INSERT INTO projects_temp (id, name, description, tags, createdAt, lastUpdatedAt, totalMinutesSpent)
      SELECT id, name, $descriptionCol, $tagsCol, $createdAtCol, $lastUpdatedAtCol, totalMinutesSpent 
      FROM $projectsTable
    ''');
    
    // 5. Apaga a tabela antiga e problemática.
    await db.execute('DROP TABLE $projectsTable');
    
    // 6. Renomeia a tabela temporária (que agora tem os dados corretos) para o nome original.
    await db.execute('ALTER TABLE projects_temp RENAME TO $projectsTable');
  }
}

