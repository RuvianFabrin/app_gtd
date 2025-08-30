import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/gtd_service.dart';
import 'project_detail_page.dart';
import 'utils/time_formatter.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  void _addTime(BuildContext context, String projectId) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Tempo'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Minutos gastos"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                context.read<GtdService>().addTimeToProject(projectId, minutes);
                Navigator.pop(context);
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
    final projects = context.watch<GtdService>().projects;

    // MODIFICADO: Removido o Scaffold e o FloatingActionButton
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), // Padding para o botão principal
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(project.name),
            subtitle: Text('Tempo gasto: ${formatDuration(project.totalMinutesSpent)}'),
            trailing: IconButton(
              icon: const Icon(Icons.more_time),
              onPressed: () => _addTime(context, project.id),
              tooltip: 'Adicionar tempo',
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectDetailPage(project: project),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
