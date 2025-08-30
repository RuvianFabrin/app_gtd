GTD+ App: O seu Sistema GTD Completo em Flutter
GTD+ é uma aplicação móvel, construída com Flutter, que implementa a metodologia Getting Things Done (GTD) de David Allen de forma completa e intuitiva. O objetivo é oferecer uma ferramenta poderosa e offline-first para capturar, esclarecer, organizar, refletir e engajar com as suas tarefas e projetos, mantendo a sua mente livre e focada.

Funcionalidades Principais
1. Implementação Completa do Fluxo GTD
O núcleo da aplicação é um sistema fiel aos 5 passos do GTD:

Capturar: Uma Caixa de Entrada universal para todas as suas ideias, tarefas e lembretes.

Esclarecer: Um fluxo de trabalho guiado por perguntas que o ajuda a decidir o que fazer com cada item da sua caixa de entrada, transformando o caos em clareza.

Organizar: Mova os seus itens automaticamente para as listas corretas:

Próximas Ações: As suas tarefas imediatas.

Projetos: Gestão de objetivos maiores com múltiplas tarefas.

Aguardando: Itens que delegou a outras pessoas.

Calendário: Compromissos com data e hora específicas.

Algum Dia / Talvez: Ideias para o futuro.

Referência: Notas e informações importantes.

Refletir & Engajar: As listas organizadas fornecem a estrutura perfeita para a sua revisão semanal e para decidir no que trabalhar a seguir.

2. Gestão de Projetos
Crie projetos para agrupar tarefas complexas.

Adicione e acompanhe o tempo gasto em cada projeto.

Visualize as tarefas de cada projeto numa lista dedicada com checkboxes para marcar a sua conclusão.

3. Calendário e Alarmes Avançados
Agende tarefas com datas e horas específicas.

Crie alarmes recorrentes (diários ou semanais com dias selecionáveis).

Adicione múltiplos lembretes para um único evento (ex: 1 hora antes, 1 dia antes).

As notificações funcionam mesmo com a aplicação fechada, graças ao agendamento nativo no sistema.

4. Editor de Texto para Referências
A secção "Referência" conta com um editor de texto completo (Rich Text Editor).

Formate as suas notas com negrito, itálico, listas, links, cores e muito mais.

5. Backup e Restauro com Google Drive
Login seguro com Google: Autentique-se com a sua conta Google para ativar as funcionalidades na nuvem.

Backup no Google Drive: Guarde uma cópia de segurança de toda a sua base de dados diretamente no seu Google Drive, garantindo que os seus dados nunca se perdem.

Stack Tecnológica
Framework: Flutter 3.x

Base de Dados: SQLite (armazenamento local e offline-first)

Notificações: awesome_notifications

Editor de Texto: flutter_quill

Autenticação e Cloud: google_sign_in e googleapis

Interface: Material 3