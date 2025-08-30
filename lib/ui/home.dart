import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../logic/gtd_service.dart';
import 'capture_sheet.dart';
import 'gtd_pages.dart';
import 'projects_page.dart';
import 'reference_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    InboxPage(),
    NextActionsPage(),
    CalendarPage(),
    ProjectsPage(),
    WaitingPage(),
    SomedayPage(),
    ReferencePage(),
  ];

  static const List<String> _appBarTitles = <String>[
    'Caixa de Entrada',
    'Próximas Ações',
    'Calendário',
    'Projetos',
    'Aguardando',
    'Algum dia / Talvez',
    'Referência',
  ];

  final Map<int, GtdStatus> _indexToStatus = {
    0: GtdStatus.inbox,
    1: GtdStatus.nextAction,
    2: GtdStatus.calendar,
    4: GtdStatus.waitingFor,
    5: GtdStatus.somedayMaybe,
    6: GtdStatus.reference,
  };

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addProject(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Projeto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Nome do projeto"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<GtdService>().addProject(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
  
  void _showGtdHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como Usar o Método GTD'),
        content: const SingleChildScrollView(
          child: Text(
            '1. CAPTURAR:\nUse o botão "+" para adicionar qualquer coisa à sua Caixa de Entrada.\n\n'
            '2. ESCLARECER:\nNa Caixa de Entrada, clique num item e responda às perguntas para decidir o que fazer com ele. É lixo? É uma referência? Exige ação?\n\n'
            '3. ORGANIZAR:\nAs suas respostas irão mover o item para a lista correta: Próximas Ações, Calendário, Projetos, etc.\n\n'
            '4. REFLETIR:\nReveja as suas listas regularmente (ex: uma vez por semana) para manter tudo atualizado.\n\n'
            '5. ENGAJAR:\nCom tudo organizado, escolha o que fazer a seguir com base no seu contexto, tempo e energia.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<GtdService>();
    final inboxCount = service.inboxItems.length;

    bool isProjectTab = _selectedIndex == 3;

    return Scaffold(
      appBar: AppBar(
        // MODIFICADO: O Row com o logótipo foi removido
        title: Text(_appBarTitles[_selectedIndex]),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showGtdHelp(context),
            tooltip: 'Ajuda GTD',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isProjectTab) {
            _addProject(context);
          } else {
            final currentStatus = _indexToStatus[_selectedIndex] ?? GtdStatus.inbox;
            CaptureSheet.show(context, preselectedStatus: currentStatus);
          }
        },
        tooltip: isProjectTab ? 'Novo Projeto' : 'Capturar',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: <Widget>[
          NavigationDestination(
            icon: Badge(
              label: Text('$inboxCount'),
              isLabelVisible: inboxCount > 0,
              child: const Icon(Icons.inbox_outlined),
            ),
            selectedIcon: Badge(
              label: Text('$inboxCount'),
              isLabelVisible: inboxCount > 0,
              child: const Icon(Icons.inbox),
            ),
            label: 'Caixa de Entrada',
          ),
          const NavigationDestination(
            icon: Icon(Icons.arrow_forward_outlined),
            selectedIcon: Icon(Icons.arrow_forward),
            label: 'Próximas Ações',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Calendário',
          ),
          const NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Projetos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: 'Aguardando',
          ),
          const NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Algum dia',
          ),
          const NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Referência',
          ),
        ],
      ),
    );
  }
}
