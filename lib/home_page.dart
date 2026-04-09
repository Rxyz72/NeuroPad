import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'note_page.dart';
import 'note_model.dart';
import 'profile_page.dart';
import 'notification_page.dart';
import 'filter_bar.dart';
import 'notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isGrid = true;
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  String selectedFilter = 'All';

  final List<String> filters = ['All', 'Recent', 'Reminders', 'By Date', 'A-Z', 'Favorites', 'Archived'];

  void _toggleFavorite(Note note) async {
    if (note.docId == null) return;
    final docRef = FirebaseFirestore.instance.collection('notes').doc(note.docId);
    await docRef.update({'isFavorite': !note.isFavorite});
  }

  void _openNote({Note? note}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotePage(
          initialTitle: note?.title,
          initialContent: note?.content,
          initialReminder: note?.reminderDate,
          onSave: (title, content, reminder) async {
            final userId = FirebaseAuth.instance.currentUser!.uid;
            final notesCollection = FirebaseFirestore.instance.collection('notes');

            if (note?.docId != null) {
              await notesCollection.doc(note!.docId).update({
                'title': title,
                'content': content,
                'reminderDate': reminder,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            } else {
              await notesCollection.add({
                'title': title,
                'content': content,
                'reminderDate': reminder,
                'userId': userId,
                'createdAt': FieldValue.serverTimestamp(),
                'isFavorite': false,
              });
            }
          },
        ),
      ),
    );
  }

  void _deleteNote(Note note) async {
    if (note.docId == null) return;
    await FirebaseFirestore.instance.collection('notes').doc(note.docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 75,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      onClearData: () async {
                        final userId = FirebaseAuth.instance.currentUser!.uid;
                        final snapshots = await FirebaseFirestore.instance
                            .collection('notes')
                            .where('userId', isEqualTo: userId)
                            .get();
                        for (var doc in snapshots.docs) {
                          await doc.reference.delete();
                        }
                      },
                    ),
                  ),
                ),
                child: const CircleAvatar(
                  radius: 22.5,
                  backgroundImage: AssetImage('assets/images/profile_pic.jpg'),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 42,
                margin: const EdgeInsets.only(right: 15, left: 15),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: searchController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Search notes...",
                    hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: isDark ? Colors.white : Colors.grey),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationPage()),
                );
              },
              child: Icon(Icons.notifications, color: iconColor, size: 30),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          FilterBar(
            filters: filters,
            selectedFilter: selectedFilter,
            onFilterSelected: (f) => setState(() => selectedFilter = f),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 6),
            child: Row(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notes')
                      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Text(
                      "$count Notes",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    );
                  },
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => isGrid = !isGrid),
                  child: Icon(
                    isGrid ? Icons.grid_view : Icons.view_agenda_outlined,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notes')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: iconColor));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No notes found", style: TextStyle(color: Colors.grey)));
                }

                final firebaseNotes = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Note(
                    docId: doc.id,
                    title: data['title'] ?? 'Untitled',
                    content: data['content'] ?? '',
                    date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    isFavorite: data['isFavorite'] ?? false,
                    reminderDate: (data['reminderDate'] as Timestamp?)?.toDate(),
                    isSynced: true,
                  );
                }).toList();

                List<Note> filteredNotes = firebaseNotes.where((note) {
                  final matchesSearch = note.title.toLowerCase().contains(searchQuery) ||
                      note.content.toLowerCase().contains(searchQuery);

                  if (selectedFilter == 'Favorites') return matchesSearch && note.isFavorite;
                  if (selectedFilter == 'Reminders') return matchesSearch && note.reminderDate != null;

                  return matchesSearch;
                }).toList();

                if (selectedFilter == 'Recent') {
                  filteredNotes.sort((a, b) => b.date.compareTo(a.date));
                } else if (selectedFilter == 'A-Z') {
                  filteredNotes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                }

                if (filteredNotes.isEmpty) {
                  return const Center(child: Text("No matching notes", style: TextStyle(color: Colors.grey)));
                }

                return isGrid
                    ? GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1),
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) => _buildNoteCard(filteredNotes[index]),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) => _buildNoteListTile(filteredNotes[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 75.0, right: 15),
        child: FloatingActionButton(
          onPressed: () => _openNote(),
          backgroundColor: isDark ? Colors.white : Colors.black,
          child: Icon(Icons.add, color: isDark ? Colors.black : Colors.white, size: 35),
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _openNote(note: note),
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFf7f7f7),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleFavorite(note),
                  child: Icon(
                    note.isFavorite ? Icons.star : Icons.star_border,
                    color: note.isFavorite ? Colors.amber : Colors.grey,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              note.content,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (note.reminderDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.alarm, size: 10, color: Colors.blue),
                    const SizedBox(width: 2),
                    Text(
                      DateFormat('MMM d, HH:mm').format(note.reminderDate!),
                      style: const TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        DateFormat('d MMM yyyy').format(note.date),
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                      Icon(
                        note.isSynced ? Icons.cloud_done : Icons.cloud_off,
                        size: 12,
                        color: note.isSynced ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  onPressed: () => _deleteNote(note),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteListTile(Note note) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _openNote(note: note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFf7f7f7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(note.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                  if (note.reminderDate != null)
                    Text(" ${DateFormat('MMM d, HH:mm').format(note.reminderDate!)}",
                        style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Text(DateFormat('d MMM yyyy').format(note.date), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(width: 6),
                      Icon(note.isSynced ? Icons.cloud_done : Icons.cloud_off, size: 14, color: note.isSynced ? Colors.green : Colors.red),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _toggleFavorite(note),
              child: Icon(note.isFavorite ? Icons.star : Icons.star_border, color: note.isFavorite ? Colors.amber : Colors.grey, size: 26),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 26),
              onPressed: () => _deleteNote(note),
            ),
          ],
        ),
      ),
    );
  }
}