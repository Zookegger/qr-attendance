import 'package:flutter/material.dart';
import 'package:qr_attendance_frontend/src/models/Notification.dart';

class NotificationScreen extends StatelessWidget {
  final List<AppNotification> notifications;

  const NotificationScreen({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: notifications.isEmpty
          ? const Center(child: Text("No notifications"))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (ctx, i) {
                final n = notifications[i];
                return ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(n.title),
                  subtitle: Text(n.body),
                  trailing: Text(
                    "${n.time.hour}:${n.time.minute.toString().padLeft(2, '0')}",
                  ),
                );
              },
            ),
    );
  }
}
