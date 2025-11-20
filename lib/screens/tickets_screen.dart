import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket_cache.dart';
import '../services/local_database_service.dart';
import 'ticket_detail_screen.dart';

class TicketsScreen extends StatefulWidget {
  final int selectedPeriod; // 0: Today, 1: Week, 2: Month
  final int selectedMonth;

  const TicketsScreen({
    super.key,
    required this.selectedPeriod,
    required this.selectedMonth,
  });

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final LocalDatabaseService _localDb = LocalDatabaseService();
  List<TicketCache> _tickets = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      List<TicketCache> tickets;
      final now = DateTime.now();

      switch (widget.selectedPeriod) {
        case 0: // Today
          tickets = await _localDb.getTodayTickets();
          break;
        case 1: // This Week
          tickets = await _localDb.getWeekTickets();
          break;
        case 2: // This Month
          tickets = await _localDb.getMonthTickets(now.year, widget.selectedMonth);
          break;
        default:
          tickets = [];
      }

      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tickets: $e')),
        );
      }
    }
  }

  List<TicketCache> get _filteredTickets {
    if (_searchQuery.isEmpty) return _tickets;
    
    return _tickets.where((ticket) {
      final query = _searchQuery.toLowerCase();
      return ticket.referenceNumber.toLowerCase().contains(query) ||
             ticket.name.toLowerCase().contains(query) ||
             ticket.facility.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Ticket Records'),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              await _localDb.syncFromSupabase(force: true);
              _loadTickets();
            },
            tooltip: 'Sync from server',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by reference, name, or facility...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Ticket Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredTickets.length} ticket${_filteredTickets.length != 1 ? 's' : ''} found',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Text(
                    'Filtered from ${_tickets.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Ticket List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTickets.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _localDb.syncFromSupabase(force: true);
                          await _loadTickets();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTickets.length,
                          itemBuilder: (context, index) {
                            return _buildTicketCard(_filteredTickets[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No tickets match your search' : 'No tickets found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Tickets will appear here when available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TicketCache ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketDetailScreen(ticket: ticket),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.referenceNumber,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: ticket.isValid ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ticket.isValid ? 'Valid' : 'Invalid',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ticket.isValid ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTicketInfo(
                        Icons.location_on_outlined,
                        'Facility',
                        ticket.facility,
                      ),
                    ),
                    Expanded(
                      child: _buildTicketInfo(
                        Icons.payments_outlined,
                        'Amount',
                        '₱${NumberFormat('#,##0.00').format(ticket.amount)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTicketInfo(
                        Icons.calendar_today_outlined,
                        'Date',
                        DateFormat('MMM dd, yyyy').format(ticket.visitDate),
                      ),
                    ),
                    Expanded(
                      child: _buildTicketInfo(
                        Icons.access_time_outlined,
                        'Time',
                        DateFormat('hh:mm a').format(ticket.visitDate),
                      ),
                    ),
                  ],
                ),
                if (ticket.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.image_outlined, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Has image',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
