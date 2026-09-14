class GoalDeadline {
  GoalDeadline({required DateTime date, this.bufferDays = 1})
      : assert(bufferDays >= 0 && bufferDays <= 3),
        date = DateTime(date.year, date.month, date.day);

  final DateTime date;
  final int bufferDays;

  DateTime get targetDate => date.subtract(Duration(days: bufferDays));
}
