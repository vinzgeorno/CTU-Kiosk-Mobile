import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();

    return FutureBuilder<Map<String, dynamic>>(
      future: supabaseService.getLiveStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final status = snapshot.data!;
        final isConnected = status['isConnected'] as bool? ?? false;
        final lastRefresh = status['lastSuccessfulRefresh'] as DateTime?;

        final accent = isConnected ? Colors.green : Colors.orange;
        final background = isConnected
            ? Colors.green.shade50
            : Colors.orange.shade50;
        final border = isConnected
            ? Colors.green.shade200
            : Colors.orange.shade200;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isConnected
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                size: 18,
                color: accent.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isConnected
                          ? 'Live Supabase data source active'
                          : 'Supabase is currently unreachable',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent.shade700,
                      ),
                    ),
                    Text(
                      lastRefresh == null
                          ? 'No successful refresh yet'
                          : 'Last successful refresh: ${_formatElapsed(lastRefresh)}',
                      style: TextStyle(fontSize: 11, color: accent.shade600),
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

  static String _formatElapsed(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }
}
