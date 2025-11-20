import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/ticket_cache.dart';
import 'supabase_service.dart';

class LocalDatabaseService {
  static const String _ticketsBoxName = 'tickets_cache';
  static const String _lastSyncKey = 'last_sync';
  
  final SupabaseService _supabaseService = SupabaseService();
  Box<TicketCache>? _ticketsBox;
  Box? _metaBox;

  // Initialize Hive
  Future<void> initialize() async {
    try {
      debugPrint('Initializing Hive...');
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TicketCacheAdapter());
      }
      
      // Open boxes
      _ticketsBox = await Hive.openBox<TicketCache>(_ticketsBoxName);
      _metaBox = await Hive.openBox('metadata');
      
      debugPrint('Hive initialized successfully');
      debugPrint('Cached tickets: ${_ticketsBox?.length ?? 0}');
    } catch (e) {
      debugPrint('Error initializing Hive: $e');
      rethrow;
    }
  }

  // Sync data from Supabase to local database
  Future<void> syncFromSupabase({bool force = false}) async {
    try {
      debugPrint('Starting sync from Supabase...');
      
      // Check if we need to sync (every 5 minutes or forced)
      final lastSync = _metaBox?.get(_lastSyncKey) as DateTime?;
      final now = DateTime.now();
      
      if (!force && lastSync != null) {
        final difference = now.difference(lastSync);
        if (difference.inMinutes < 5) {
          debugPrint('Skipping sync - last sync was ${difference.inMinutes} minutes ago');
          return;
        }
      }
      
      // Fetch all tickets from Supabase
      final tickets = await _supabaseService.getAllTickets();
      debugPrint('Fetched ${tickets.length} tickets from Supabase');
      
      // Clear existing cache
      await _ticketsBox?.clear();
      
      // Store tickets in local database
      for (var ticket in tickets) {
        final cache = TicketCache(
          id: ticket.id.toString(),
          referenceNumber: ticket.referenceNumber,
          name: ticket.name,
          facility: ticket.facility,
          amount: ticket.amount,
          visitDate: ticket.visitDate,
          createdAt: ticket.createdAt,
          isValid: ticket.isValid,
          imageUrl: null, // Ticket model doesn't have imageUrl yet
          email: null, // Ticket model doesn't have email yet
          phone: null, // Ticket model doesn't have phone yet
        );
        await _ticketsBox?.put(ticket.id.toString(), cache);
      }
      
      // Update last sync time
      await _metaBox?.put(_lastSyncKey, now);
      
      debugPrint('Sync completed - ${tickets.length} tickets cached');
    } catch (e) {
      debugPrint('Error syncing from Supabase: $e');
      rethrow;
    }
  }

  // Get all tickets from local database
  Future<List<TicketCache>> getAllTickets() async {
    try {
      if (_ticketsBox == null) {
        await initialize();
      }
      
      final tickets = _ticketsBox?.values.toList() ?? [];
      debugPrint('Retrieved ${tickets.length} tickets from local cache');
      return tickets;
    } catch (e) {
      debugPrint('Error getting tickets from local cache: $e');
      return [];
    }
  }

  // Get tickets filtered by date range
  Future<List<TicketCache>> getTicketsByDateRange(DateTime start, DateTime end) async {
    try {
      final allTickets = await getAllTickets();
      
      final filtered = allTickets.where((ticket) {
        return ticket.visitDate.isAfter(start.subtract(const Duration(days: 1))) &&
               ticket.visitDate.isBefore(end.add(const Duration(days: 1)));
      }).toList();
      
      // Sort by visit date descending
      filtered.sort((a, b) => b.visitDate.compareTo(a.visitDate));
      
      debugPrint('Filtered ${filtered.length} tickets for date range');
      return filtered;
    } catch (e) {
      debugPrint('Error filtering tickets: $e');
      return [];
    }
  }

  // Get tickets for today
  Future<List<TicketCache>> getTodayTickets() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return getTicketsByDateRange(today, today);
  }

  // Get tickets for this week
  Future<List<TicketCache>> getWeekTickets() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    return getTicketsByDateRange(weekStart, today);
  }

  // Get tickets for a specific month
  Future<List<TicketCache>> getMonthTickets(int year, int month) async {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    return getTicketsByDateRange(monthStart, monthEnd);
  }

  // Get ticket by reference number
  Future<TicketCache?> getTicketByReference(String referenceNumber) async {
    try {
      final allTickets = await getAllTickets();
      return allTickets.firstWhere(
        (ticket) => ticket.referenceNumber == referenceNumber,
        orElse: () => throw Exception('Ticket not found'),
      );
    } catch (e) {
      debugPrint('Ticket not found in cache: $referenceNumber');
      return null;
    }
  }

  // Add or update a single ticket
  Future<void> upsertTicket(TicketCache ticket) async {
    try {
      await _ticketsBox?.put(ticket.id, ticket);
      debugPrint('Ticket cached: ${ticket.referenceNumber}');
    } catch (e) {
      debugPrint('Error caching ticket: $e');
    }
  }

  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final lastSync = _metaBox?.get(_lastSyncKey) as DateTime?;
    final ticketCount = _ticketsBox?.length ?? 0;
    
    return {
      'ticket_count': ticketCount,
      'last_sync': lastSync,
      'cache_size_kb': _ticketsBox?.length ?? 0 * 2, // Rough estimate
    };
  }

  // Clear all cache
  Future<void> clearCache() async {
    try {
      await _ticketsBox?.clear();
      await _metaBox?.delete(_lastSyncKey);
      debugPrint('Cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Close boxes
  Future<void> close() async {
    await _ticketsBox?.close();
    await _metaBox?.close();
  }
}
