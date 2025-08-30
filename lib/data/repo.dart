import 'models.dart';
import 'db.dart';

class GtdRepository {
  final dbHelper = DatabaseHelper.instance;

  // --- Métodos para GtdItem ---
  Future<GtdItem> createItem(GtdItem item) async {
    final db = await dbHelper.database;
    await db.insert(DatabaseHelper.gtdItemsTable, item.toMap());
    return item;
  }

  Future<List<GtdItem>> getAllItems() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseHelper.gtdItemsTable);
    return List.generate(maps.length, (i) => GtdItem.fromMap(maps[i]));
  }

  Future<int> updateItem(GtdItem item) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.gtdItemsTable,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(String id) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.gtdItemsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- NOVO: Métodos para Project ---
  Future<Project> createProject(Project project) async {
    final db = await dbHelper.database;
    await db.insert(DatabaseHelper.projectsTable, project.toMap());
    return project;
  }

  Future<List<Project>> getAllProjects() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseHelper.projectsTable);
    return List.generate(maps.length, (i) => Project.fromMap(maps[i]));
  }

  Future<int> updateProject(Project project) async {
    final db = await dbHelper.database;
    return await db.update(
      DatabaseHelper.projectsTable,
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> deleteProject(String id) async {
    final db = await dbHelper.database;
    return await db.delete(
      DatabaseHelper.projectsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
