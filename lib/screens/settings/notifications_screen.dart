import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _dailyReminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('notifications'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Rappel quotidien'),
            subtitle: const Text('N\'oubliez pas d\'enregistrer vos transactions'),
            value: _dailyReminder,
            onChanged: (val) {
              setState(() => _dailyReminder = val);
            },
            secondary: const Icon(Icons.notifications_active, color: Colors.amber),
          ),
          if (_dailyReminder)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Heure du rappel'),
              trailing: Text('${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}'),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _reminderTime,
                );
                if (picked != null && picked != _reminderTime) {
                  setState(() {
                    _reminderTime = picked;
                  });
                }
              },
            ),
        ],
      ),
    );
  }
}
