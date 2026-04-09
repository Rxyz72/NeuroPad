import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_page.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

class NotePage extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final DateTime? initialReminder;
  final Function(String title, String content, DateTime? reminder)? onSave;

  const NotePage({
    super.key,
    this.onSave,
    this.initialTitle,
    this.initialContent,
    this.initialReminder,
  });

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  late TextEditingController titleController;
  late QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  int _currentWordCount = 0;
  bool _hasReminder = false;
  DateTime? _reminderDateTime;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle ?? "");

    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      _quillController = QuillController(
        document: Document()..insert(0, widget.initialContent),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      _quillController = QuillController.basic();
    }

    _reminderDateTime = widget.initialReminder;
    _hasReminder = widget.initialReminder != null;

    _quillController.addListener(_updateWordCount);
    _editorFocusNode.addListener(() {
      if (mounted) setState(() => _isEditing = _editorFocusNode.hasFocus);
    });
    _updateWordCount();
  }

  void _updateWordCount() {
    final text = _quillController.document.toPlainText().trim();
    final count = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    if (count != _currentWordCount) setState(() => _currentWordCount = count);
  }

  bool _hasChanges() {
    final currentTitle = titleController.text.trim();
    final currentContent = _quillController.document.toPlainText().trim();
    return currentTitle != (widget.initialTitle ?? "") ||
        currentContent != (widget.initialContent ?? "").trim() ||
        _reminderDateTime != widget.initialReminder;
  }

  void _handleSave() {
    final title = titleController.text.trim().isEmpty ? "Untitled Note" : titleController.text.trim();
    final content = _quillController.document.toPlainText().trim();

    if (widget.onSave != null) {
      widget.onSave!(title, content, _hasReminder ? _reminderDateTime : null);
    }

    if (_hasReminder && _reminderDateTime != null) {
      String now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
      String reminderStr = DateFormat('dd MMM yyyy, hh:mm a').format(_reminderDateTime!);

      NotificationPage.notifications.insert(0, {
        "title": title,
        "reminderTime": reminderStr,
        "notifDate": now,
      });

      NotificationService().scheduleNotification(
        id: _reminderDateTime!.millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: "Reminder: $title",
        scheduledDateTime: _reminderDateTime!,
      );
    }
  }

  Future<bool> _showExitDialog() async {
    if (!_hasChanges()) return true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Save Changes?",
            style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Discard", style: TextStyle(color: Colors.red))),
          ElevatedButton(
            onPressed: () { _handleSave(); Navigator.pop(context, true); },
            style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white),
            child: const Text("Save"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickReminderTime() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: isDark ? ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.white, onPrimary: Colors.black, surface: Color(0xFF1E1E1E)),
        ) : ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.black, onPrimary: Colors.white, onSurface: Colors.black),
        ),
        child: child!,
      ),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderDateTime ?? DateTime.now()),
      builder: (context, child) => Theme(
        data: isDark ? ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.white, surface: Color(0xFF1E1E1E)),
        ) : ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.black, onSurface: Colors.black),
        ),
        child: child!,
      ),
    );

    if (pickedTime != null) {
      setState(() {
        _hasReminder = true;
        _reminderDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mainColor = isDark ? Colors.white : Colors.black;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _showExitDialog() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: mainColor),
            onPressed: () async { if (await _showExitDialog()) Navigator.pop(context); },
          ),
          actions: [
            Center(child: Text('$_currentWordCount words', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey[700], fontSize: 13))),
            IconButton(
              icon: Icon(Icons.alarm, color: _hasReminder ? Colors.blue : mainColor),
              onPressed: _pickReminderTime,
            ),
            TextButton(
              onPressed: () { _handleSave(); Navigator.pop(context); },
              child: Text("Save", style: TextStyle(color: mainColor, fontWeight: FontWeight.bold)),
            ),
            PopupMenuButton<String>(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              surfaceTintColor: Colors.transparent,
              icon: Icon(Icons.more_vert, color: mainColor),
              onSelected: (val) {
                if (val == 'remove_timer') setState(() { _hasReminder = false; _reminderDateTime = null; });
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'archive', child: Text("Archive", style: TextStyle(color: mainColor))),
                PopupMenuItem(value: 'remove_timer', child: Text("Remove Timer", style: TextStyle(color: mainColor))),
                const PopupMenuItem(value: 'discard', child: Text("Discard", style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: titleController,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: mainColor),
                decoration: InputDecoration(
                    hintText: "Note Title",
                    hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
                    border: InputBorder.none
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: QuillEditor.basic(
                  controller: _quillController,
                  focusNode: _editorFocusNode,
                  config: QuillEditorConfig(
                    placeholder: 'Start typing...',
                    scrollable: true,
                    expands: true,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            if (_isEditing)
              Container(
                decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12))
                ),
                child: QuillSimpleToolbar(
                  controller: _quillController,
                  config: QuillSimpleToolbarConfig(
                    multiRowsDisplay: false,
                    showFontFamily: false,
                    showFontSize: false,
                    showSearchButton: false,
                    color: Colors.transparent,
                    buttonOptions: QuillSimpleToolbarButtonOptions(
                      base: QuillToolbarBaseButtonOptions(
                        iconTheme: QuillIconTheme(
                          iconButtonUnselectedData: IconButtonData(style: IconButton.styleFrom(foregroundColor: mainColor)),
                          iconButtonSelectedData: IconButtonData(
                            style: IconButton.styleFrom(
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              backgroundColor: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}