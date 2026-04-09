import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  // STATIC LIST: Accessible from NotePage
  static List<Map<String, String>> notifications = [];

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  Widget build(BuildContext context) {
    // Determine current theme state
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Let Scaffold background show through
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(
            color: iconColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                "${NotificationPage.notifications.length} Notifications",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: NotificationPage.notifications.isEmpty
                  ? Center(
                child: Text(
                  "No notifications yet",
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: NotificationPage.notifications.length,
                itemBuilder: (context, index) {
                  final item = NotificationPage.notifications[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      // Responsive card color
                      color: isDark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Note Title
                              Text(
                                item["title"] ?? "Untitled Note",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // 2. Reminder Time & Date
                              Row(
                                children: [
                                  const Icon(Icons.alarm, size: 14, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Reminder: ${item["reminderTime"]}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // 3. Notification Date
                              Text(
                                "Created on: ${item["notifDate"]}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white38 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 4. Delete Button
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                          onPressed: () {
                            setState(() {
                              NotificationPage.notifications.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}