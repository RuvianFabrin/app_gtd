import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../logic/gtd_service.dart';
import 'task_editor.dart';

class ProjectDetailPage extends StatelessWidget {
  final Project project;
  const ProjectDetailPage({super.key, required this.project});

  void _addTask(BuildContext context, String projectId) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nova Tarefa do Projeto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Nome da tarefa"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                // MODIFICADO: Captura o Navigator e o Service do contexto correto
                final navigator = Navigator.of(dialogContext);
                final service = context.read<GtdService>();
                final messenger = ScaffoldMessenger.of(context);

                final newItem = GtdItem(
                  title: controller.text,
                  status: GtdStatus.projectTask,
                  project: projectId,
                );
                
                try {
                  await service.addItem(newItem);
                } catch (e) {
                  debugPrint("Erro ao adicionar tarefa: $e");
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Ocorreu um erro ao adicionar a tarefa.')),
                  );
                } finally {
                  // Garante que o diálogo fecha sempre
                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                }
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectTasks = context.watch<GtdService>().items.where((item) {
      return item.project == project.id &&
          (item.status == GtdStatus.projectTask || item.status == GtdStatus.done);
    }).toList();

    projectTasks.sort((a, b) {
      if (a.status == GtdStatus.done && b.status != GtdStatus.done) {
        return 1;
      }
      if (a.status != GtdStatus.done && b.status == GtdStatus.done) {
        return -1;
      }
      return a.createdAt.compareTo(b.createdAt);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        itemCount: projectTasks.length,
        itemBuilder: (context, index) {
          final task = projectTasks[index];
          final isDone = task.status == GtdStatus.done;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: Checkbox(
                value: isDone,
                onChanged: (bool? value) {
                  if (value != null) {
                    task.status = value ? GtdStatus.done : GtdStatus.projectTask;
                    context.read<GtdService>().updateItem(task);
                  }
                },
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  color: isDone ? Colors.grey : null,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              onTap: () {
                 Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskEditorScreen(item: task),
                    ),
                  );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(context, project.id),
        child: const Icon(Icons.add_task),
        tooltip: 'Nova Tarefa',
      ),
    );
  }
}
