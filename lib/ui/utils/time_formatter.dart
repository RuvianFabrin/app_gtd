String formatDuration(int totalMinutes) {
  if (totalMinutes == 0) {
    return "0 minutos";
  }

  final duration = Duration(minutes: totalMinutes);

  int years = duration.inDays ~/ 365;
  int months = (duration.inDays % 365) ~/ 30;
  int days = (duration.inDays % 365) % 30;
  int hours = duration.inHours % 24;
  int minutes = duration.inMinutes % 60;

  List<String> parts = [];
  if (years > 0) parts.add("$years a");
  if (months > 0) parts.add("$months m");
  if (days > 0) parts.add("$days d");
  if (hours > 0) parts.add("$hours h");
  if (minutes > 0) parts.add("$minutes min");

  return parts.join(', ');
}
