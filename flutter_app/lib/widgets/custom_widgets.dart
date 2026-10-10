import 'package:flutter/material.dart';

// Brand Colors
class CivicColors {
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color darkBg = Color(0xFF0F172A); // Slate 900
  static const Color cardBg = Color(0xFF1E293B); // Slate 800
  static const Color cardLight = Colors.white;
  static const Color accentEmerald = Color(0xFF10B981); // Emerald
  static const Color accentAmber = Color(0xFFF59E0B); // Amber
  static const Color accentRed = Color(0xFFEF4444); // Red
  static const Color border = Color(0xFF334155);
}

// Badge Widgets
class SeverityBadge extends StatelessWidget {
  final String severity;
  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    switch (severity.toUpperCase()) {
      case 'HIGH':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFF991B1B);
        break;
      case 'MEDIUM':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFF92400E);
        break;
      case 'LOW':
      default:
        bg = const Color(0xFFD1FAE5);
        text = const Color(0xFF065F46);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    switch (status.toUpperCase()) {
      case 'NEW':
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF1E40AF);
        break;
      case 'IN PROGRESS':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFF92400E);
        break;
      case 'RESOLVED':
        bg = const Color(0xFFD1FAE5);
        text = const Color(0xFF065F46);
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        text = const Color(0xFF374151);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}

class DepartmentBadge extends StatelessWidget {
  final String department;
  const DepartmentBadge({super.key, required this.department});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CivicColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CivicColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        department,
        style: const TextStyle(
          color: CivicColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// Timeline Tracker Widget (Overflow-Safe)
class TimelineTracker extends StatelessWidget {
  final String status;
  const TimelineTracker({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final upper = status.toUpperCase();
    const bool isSubmitted = true;
    final bool isAssigned = upper == 'NEW' || upper == 'IN PROGRESS' || upper == 'RESOLVED';
    final bool isInProgress = upper == 'IN PROGRESS' || upper == 'RESOLVED';
    final bool isResolved = upper == 'RESOLVED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildStep('Submitted', isSubmitted, true),
          _buildLine(isAssigned),
          _buildStep('Assigned', isAssigned, isAssigned),
          _buildLine(isInProgress),
          _buildStep('In Progress', isInProgress, isInProgress),
          _buildLine(isResolved),
          _buildStep('Resolved', isResolved, isResolved),
        ],
      ),
    );
  }

  Widget _buildStep(String title, bool active, bool done) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: done ? CivicColors.accentEmerald : (active ? CivicColors.primary : Colors.grey.shade300),
          child: done
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : Container(),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: 54,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: active ? CivicColors.accentEmerald : Colors.grey.shade300,
      ),
    );
  }
}
