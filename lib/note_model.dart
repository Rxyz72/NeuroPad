class Note {
  final String? docId;
  final String title;
  final String content;
  final DateTime date;
  final DateTime? reminderDate;
  bool isFavorite;
  bool isArchived;
  bool isSynced;

  Note({
    this.docId,
    required this.title,
    required this.content,
    required this.date,
    this.reminderDate,
    this.isFavorite = false,
    this.isArchived = false,
    this.isSynced = false,
  });
}