import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final bool protected;

  const StatusBadge({super.key, this.protected = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: protected ? Colors.green.withOpacity(0.1) : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: protected ? Colors.green : theme.dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield,
            color: protected ? Colors.green : theme.iconTheme.color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            protected ? 'Protected' : 'Status',
            style: theme.textTheme.bodySmall?.copyWith(
              color: protected ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}
