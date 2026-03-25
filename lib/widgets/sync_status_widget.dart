import 'package:flutter/material.dart';
import '../services/local_database_service.dart';

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final LocalDatabaseService _localDb = LocalDatabaseService();
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _localDb.getCacheStats();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        final lastSync = stats['lastSync'] as DateTime?;
        final ticketCount = stats['ticketCount'] as int? ?? 0;

        String syncTimeText = 'Never synced';
        if (lastSync != null) {
          final now = DateTime.now();
          final difference = now.difference(lastSync);

          if (difference.inMinutes < 1) {
            syncTimeText = 'Just now';
          } else if (difference.inHours < 1) {
            syncTimeText = '${difference.inMinutes}m ago';
          } else if (difference.inHours < 24) {
            syncTimeText = '${difference.inHours}h ago';
          } else {
            syncTimeText = '${difference.inDays}d ago';
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.cloud_download_outlined,
                size: 18,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$ticketCount tickets cached',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      'Last sync: $syncTimeText',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
