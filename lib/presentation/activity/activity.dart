import 'package:flutter/material.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final events = [
      {'title': 'SOS triggered', 'time': 'Today 09:12', 'type': 'alert'},
      {'title': 'Motion detected', 'time': 'Yesterday 18:03', 'type': 'motion'},
      {
        'title': 'VoiceShield blocked call',
        'time': 'Jan 10 14:22',
        'type': 'voice',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                TextButton(onPressed: () {}, child: const Text('Filter')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final e = events[i];
                  Icon leading;
                  switch (e['type']) {
                    case 'motion':
                      leading = const Icon(
                        Icons.directions_run,
                        color: Colors.orange,
                      );
                      break;
                    case 'voice':
                      leading = const Icon(
                        Icons.record_voice_over,
                        color: Colors.blue,
                      );
                      break;
                    default:
                      leading = const Icon(Icons.warning, color: Colors.red);
                  }
                  return ListTile(
                    tileColor: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    leading: leading,
                    title: Text(e['title']!),
                    subtitle: Text(e['time']!),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {},
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
