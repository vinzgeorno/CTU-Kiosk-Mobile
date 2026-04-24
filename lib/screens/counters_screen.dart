import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket_counter.dart';
import '../services/supabase_service.dart';
import '../widgets/sync_status_widget.dart';

class CountersScreen extends StatefulWidget {
  const CountersScreen({super.key});

  @override
  State<CountersScreen> createState() => _CountersScreenState();
}

class _CountersScreenState extends State<CountersScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<TicketCounter> _counters = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounters();
  }

  Future<void> _loadCounters() async {
    setState(() => _isLoading = true);
    try {
      final counters = await _supabaseService.getTicketCounters();
      if (!mounted) {
        return;
      }
      setState(() {
        _counters = counters;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading counters: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _editCounter(TicketCounter counter) async {
    final controller = TextEditingController(text: '${counter.lastSequence}');

    final updated = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${counter.facilityCode} Counter'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Last sequence',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == null) {
      return;
    }

    try {
      await _supabaseService.updateTicketCounter(
        counter.copyWith(lastSequence: updated),
      );
      await _loadCounters();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save counter: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usingDerivedCounters = _counters.any((counter) => counter.isDerived);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Counters'),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadCounters,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusWidget(),
          if (usingDerivedCounters)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Text(
                'ticket_counters is not available in the current Supabase project. These values are derived from recent transactions and are read-only until the table exists.',
                style: TextStyle(color: Colors.orange.shade800, height: 1.35),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _counters.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadCounters,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _counters.length,
                      itemBuilder: (context, index) {
                        return _buildCounterCard(_counters[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterCard(TicketCounter counter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          foregroundColor: Colors.blue.shade700,
          child: Text(counter.facilityCode),
        ),
        title: Text(
          counter.facilityName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Last sequence: ${counter.lastSequence}'),
            if (counter.updatedAt != null)
              Text(
                'Updated: ${DateFormat('MMM dd, yyyy hh:mm a').format(counter.updatedAt!.toLocal())}',
              ),
            if (counter.isDerived)
              Text(
                'Derived from recent transactions',
                style: TextStyle(color: Colors.orange.shade700),
              ),
          ],
        ),
        trailing: IconButton(
          onPressed: counter.canEdit ? () => _editCounter(counter) : null,
          icon: const Icon(Icons.edit_outlined),
          tooltip: counter.canEdit ? 'Edit counter' : 'Read-only counter',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pin_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No counters available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add ticket_counters in Supabase or create more transactions so the app can derive current sequences.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
