import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ticket.dart';
import '../models/ticket_cache.dart';

class TicketValidationDialog extends StatefulWidget {
  final dynamic ticket; // Accepts both Ticket and TicketCache

  const TicketValidationDialog({super.key, required this.ticket});

  @override
  State<TicketValidationDialog> createState() => _TicketValidationDialogState();
}

class _TicketValidationDialogState extends State<TicketValidationDialog> {
  bool get _isFromCache => widget.ticket is TicketCache;

  String get _referenceNumber {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).referenceNumber;
    }
    return (widget.ticket as Ticket).referenceNumber;
  }

  int? get _age {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).age;
    }
    return (widget.ticket as Ticket).age;
  }

  String? get _ageCategory {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).ageCategory;
    }
    return (widget.ticket as Ticket).ageCategory;
  }

  String _getAgeDisplay() {
    // If age category is provided, use it
    if (_ageCategory != null && _ageCategory!.isNotEmpty) {
      return _ageCategory!;
    }
    // If age is provided, categorize it
    if (_age != null) {
      if (_age! <= 11) {
        return '11 and below';
      } else {
        return '12 and above';
      }
    }
    return 'Not specified';
  }

  String get _facility {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).facility;
    }
    return (widget.ticket as Ticket).facility;
  }

  double get _amountPaid {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).amount;
    }
    return (widget.ticket as Ticket).amountPaid;
  }

  double? get _amountDue {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).amountDue;
    }
    return (widget.ticket as Ticket).amountDue;
  }

  double? get _changeAmount {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).changeAmount;
    }
    return (widget.ticket as Ticket).changeAmount;
  }

  String? get _ticketType {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).ticketType;
    }
    return (widget.ticket as Ticket).ticketType;
  }

  bool? get _isClubMember {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).isClubMember;
    }
    return (widget.ticket as Ticket).isClubMember;
  }

  bool? get _isResident {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).isResident;
    }
    return (widget.ticket as Ticket).isResident;
  }

  int? get _totalPeople {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).totalPeople;
    }
    return (widget.ticket as Ticket).totalPeople;
  }

  int? get _peopleBelow12 {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).peopleBelow12;
    }
    return (widget.ticket as Ticket).peopleBelow12;
  }

  int? get _people12Above {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).people12Above;
    }
    return (widget.ticket as Ticket).people12Above;
  }

  DateTime get _createdAt {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).createdAt;
    }
    return (widget.ticket as Ticket).createdAt;
  }

  String get _status {
    if (widget.ticket is TicketCache) {
      return (widget.ticket as TicketCache).transactionStatus;
    }
    return (widget.ticket as Ticket).transactionStatus;
  }

  bool get _isMembershipFacility {
    final facilityLower = _facility.toLowerCase();
    return facilityLower.contains('badminton') ||
        facilityLower.contains('tennis') ||
        facilityLower.contains('water essence');
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final isValidStatus =
        _status.toLowerCase().contains('complete') ||
        _status.toLowerCase().contains('paid');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cache Badge
            if (_isFromCache)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.offline_bolt,
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'From Local Cache',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (_isFromCache) const SizedBox(height: 12),

            // Status Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isValidStatus
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isValidStatus ? Icons.check_circle : Icons.info,
                size: 64,
                color: isValidStatus ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),

            // Status Text
            Text(
              _status.toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isValidStatus ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 24),

            // Ticket Details
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow(
                      'Reference Number',
                      _referenceNumber,
                      Icons.confirmation_number,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow('Facility', _facility, Icons.location_on),
                    const Divider(height: 24),
                    // Age Display (using helper)
                    _buildDetailRow(
                      'Age Category',
                      _getAgeDisplay(),
                      Icons.person,
                    ),
                    const Divider(height: 24),
                    // Visit Information Section - Amount Details
                    _buildSectionHeader('Visit Information'),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Amount Paid',
                      '₱$_amountPaid',
                      Icons.attach_money,
                    ),
                    if (_amountDue != null && _amountDue! > 0) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Amount Due',
                        '₱$_amountDue',
                        Icons.receipt_long,
                      ),
                    ],
                    if (_changeAmount != null && _changeAmount! > 0) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Change Amount',
                        '₱$_changeAmount',
                        Icons.monetization_on,
                      ),
                    ],
                    // Ticket Information Section
                    const Divider(height: 24),
                    _buildSectionHeader('Ticket Information'),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Date Created',
                      dateFormat.format(_createdAt),
                      Icons.calendar_today,
                    ),
                    // Ticket Type
                    if (_ticketType != null) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Ticket Type',
                        _ticketType!.toUpperCase(),
                        Icons.sell,
                      ),
                      const Divider(height: 24),
                    ] else
                      const Divider(height: 24),
                    // Group Details
                    if (_totalPeople != null && _totalPeople! > 1) ...[
                      _buildDetailRow(
                        'Total People',
                        '$_totalPeople people',
                        Icons.people,
                      ),
                      const Divider(height: 24),
                      if (_peopleBelow12 != null)
                        _buildDetailRow(
                          'Below 12 years',
                          '$_peopleBelow12 person(s)',
                          Icons.child_care,
                        ),
                      if (_peopleBelow12 != null) const Divider(height: 24),
                      if (_people12Above != null)
                        _buildDetailRow(
                          '12 years & above',
                          '$_people12Above person(s)',
                          Icons.person_outline,
                        ),
                      if (_people12Above != null) const Divider(height: 24),
                    ],
                    // Membership Info
                    if (_isMembershipFacility) ...[
                      const Divider(height: 24),
                      if (_isClubMember != null)
                        _buildDetailRow(
                          'Club Member',
                          _isClubMember! ? '✓ Yes' : '✗ No',
                          Icons.card_membership,
                        ),
                      if (_isClubMember != null && _isResident != null)
                        const Divider(height: 24),
                      if (_isResident != null)
                        _buildDetailRow(
                          'Resident',
                          _isResident! ? '✓ Yes' : '✗ No',
                          Icons.home,
                        ),
                    ],
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Date Created',
                      dateFormat.format(_createdAt),
                      Icons.calendar_today,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValidStatus ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isValidStatus ? 'Accept & Close' : 'Close',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.blue.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Icon(icon, size: 20, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
