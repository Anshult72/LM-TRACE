import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AuditEvent {
  final String id;
  final String eventId;
  final String eventType;
  final String action;
  final String actorId;
  final String actorName;
  final String role;
  final String resourceType;
  final String resourceId;
  final String targetType;
  final String targetId;
  final String? inspectionId;
  final String result;
  final String description;
  final DateTime? timestamp;
  final String rawTimestamp;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final Map<String, dynamic>? beforeData;
  final Map<String, dynamic>? afterData;
  final Map<String, dynamic>? metadata;
  final String? correlationId;
  final String source;

  const AuditEvent({
    required this.id,
    required this.eventId,
    required this.eventType,
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.role,
    required this.resourceType,
    required this.resourceId,
    required this.targetType,
    required this.targetId,
    this.inspectionId,
    required this.result,
    required this.description,
    this.timestamp,
    required this.rawTimestamp,
    this.oldValue,
    this.newValue,
    this.beforeData,
    this.afterData,
    this.metadata,
    this.correlationId,
    required this.source,
  });

  factory AuditEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDt;
    final tsRaw = json['timestamp'] ?? json['created_at'] ?? '';
    if (tsRaw is String && tsRaw.isNotEmpty) {
      try {
        parsedDt = DateTime.parse(tsRaw).toUtc();
      } catch (_) {}
    }

    final id = (json['id'] ?? '').toString();
    final eventId = (json['event_id'] ?? (id.isNotEmpty ? 'AUD-${id.substring(0, id.length > 8 ? 8 : id.length).toUpperCase()}' : 'AUD-UNKNOWN')).toString();
    final action = (json['action'] ?? 'UNKNOWN_ACTION').toString();
    final resType = (json['resource_type'] ?? json['target_type'] ?? 'SYSTEM').toString();
    final meta = json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : null;
    final eventType = (json['event_type'] ?? meta?['event_type'] ?? resType).toString();

    return AuditEvent(
      id: id,
      eventId: eventId,
      eventType: eventType,
      action: action,
      actorId: (json['actor_id'] ?? json['user_id'] ?? 'system').toString(),
      actorName: (json['actor_name'] ?? json['user_id'] ?? 'System Process').toString(),
      role: (json['role'] ?? 'SYSTEM').toString(),
      resourceType: resType,
      resourceId: (json['resource_id'] ?? json['target_id'] ?? '0').toString(),
      targetType: (json['target_type'] ?? resType).toString(),
      targetId: (json['target_id'] ?? json['resource_id'] ?? '0').toString(),
      inspectionId: json['inspection_id']?.toString(),
      result: (json['result'] ?? 'SUCCESS').toString().toUpperCase(),
      description: (json['description'] ?? '$action on $resType').toString(),
      timestamp: parsedDt,
      rawTimestamp: tsRaw.toString(),
      oldValue: json['old_value'] is Map ? Map<String, dynamic>.from(json['old_value']) : null,
      newValue: json['new_value'] is Map ? Map<String, dynamic>.from(json['new_value']) : null,
      beforeData: json['before_data'] is Map ? Map<String, dynamic>.from(json['before_data']) : null,
      afterData: json['after_data'] is Map ? Map<String, dynamic>.from(json['after_data']) : null,
      metadata: meta,
      correlationId: json['correlation_id']?.toString(),
      source: (json['source'] ?? 'LM-TRACE').toString(),
    );
  }

  /// Formatted IST timestamp (UTC + 5:30)
  String get formattedIST {
    if (timestamp == null) {
      return rawTimestamp.isNotEmpty ? rawTimestamp : 'N/A';
    }
    final ist = timestamp!.add(const Duration(hours: 5, minutes: 30));
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = ist.day.toString().padLeft(2, '0');
    final month = months[ist.month - 1];
    final year = ist.year;
    final hour24 = ist.hour;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final minute = ist.minute.toString().padLeft(2, '0');
    final second = ist.second.toString().padLeft(2, '0');
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    return '$day $month $year, ${hour12.toString().padLeft(2, '0')}:$minute:$second $ampm IST';
  }

  String get actionTitle {
    return action.replaceAll('_', ' ');
  }

  Color get resultColor {
    switch (result) {
      case 'SUCCESS':
        return AppColors.successGreen;
      case 'FAILURE':
        return AppColors.alertRed;
      case 'WARNING':
        return AppColors.warningAmber;
      default:
        return AppColors.steelBlue;
    }
  }

  Color get categoryColor {
    final t = eventType.toUpperCase();
    if (t.contains('INSPECT')) return AppColors.primaryNavy;
    if (t.contains('EVID')) return AppColors.inspectionGreen;
    if (t.contains('OCR')) return AppColors.steelBlue;
    if (t.contains('CV') || t.contains('VISION')) return AppColors.inspectionGreen;
    if (t.contains('CALIB')) return AppColors.accentGold;
    if (t.contains('RULE') || t.contains('STATUT')) return AppColors.primaryNavy;
    if (t.contains('COMPLIANCE')) return AppColors.successGreen;
    if (t.contains('FINDING') || t.contains('VIOL')) return AppColors.warningAmber;
    if (t.contains('REPORT')) return AppColors.primaryNavy;
    if (t.contains('AUTH') || t.contains('SEC')) return AppColors.alertRed;
    return AppColors.steelBlue;
  }

  IconData get categoryIcon {
    final t = eventType.toUpperCase();
    if (t.contains('INSPECT')) return Icons.assignment_outlined;
    if (t.contains('EVID')) return Icons.image_search_outlined;
    if (t.contains('OCR')) return Icons.document_scanner_outlined;
    if (t.contains('CV') || t.contains('VISION')) return Icons.visibility_outlined;
    if (t.contains('CALIB')) return Icons.straighten_outlined;
    if (t.contains('RULE') || t.contains('STATUT')) return Icons.gavel_outlined;
    if (t.contains('COMPLIANCE')) return Icons.verified_user_outlined;
    if (t.contains('FINDING') || t.contains('VIOL')) return Icons.warning_amber_outlined;
    if (t.contains('REPORT')) return Icons.picture_as_pdf_outlined;
    if (t.contains('AUTH') || t.contains('SEC')) return Icons.security_outlined;
    return Icons.history_toggle_off;
  }
}

class AuditSummary {
  final int totalEvents;
  final int todayEvents;
  final int inspectionEvents;
  final int securityEvents;
  final int systemEvents;

  const AuditSummary({
    required this.totalEvents,
    required this.todayEvents,
    required this.inspectionEvents,
    required this.securityEvents,
    required this.systemEvents,
  });

  factory AuditSummary.fromJson(Map<String, dynamic> json) {
    return AuditSummary(
      totalEvents: (json['total_events'] ?? 0) as int,
      todayEvents: (json['today_events'] ?? 0) as int,
      inspectionEvents: (json['inspection_events'] ?? 0) as int,
      securityEvents: (json['security_events'] ?? 0) as int,
      systemEvents: (json['system_events'] ?? 0) as int,
    );
  }

  factory AuditSummary.empty() {
    return const AuditSummary(
      totalEvents: 0,
      todayEvents: 0,
      inspectionEvents: 0,
      securityEvents: 0,
      systemEvents: 0,
    );
  }
}

class ChainOfCustodyStage {
  final String stageKey;
  final String stageName;
  final String status; // COMPLETED, PENDING, SKIPPED, FAILED
  final String? actor;
  final String? role;
  final String? timestamp;
  final String? eventId;
  final String? details;
  final Map<String, dynamic>? metadata;

  const ChainOfCustodyStage({
    required this.stageKey,
    required this.stageName,
    required this.status,
    this.actor,
    this.role,
    this.timestamp,
    this.eventId,
    this.details,
    this.metadata,
  });

  factory ChainOfCustodyStage.fromJson(Map<String, dynamic> json) {
    return ChainOfCustodyStage(
      stageKey: (json['stage_key'] ?? '').toString(),
      stageName: (json['stage_name'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      actor: json['actor']?.toString(),
      role: json['role']?.toString(),
      timestamp: json['timestamp']?.toString(),
      eventId: json['event_id']?.toString(),
      details: json['details']?.toString(),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

  bool get isCompleted => status == 'COMPLETED';
}

class ChainOfCustodyData {
  final String inspectionId;
  final String inspectionCode;
  final List<ChainOfCustodyStage> stages;
  final List<AuditEvent> events;

  const ChainOfCustodyData({
    required this.inspectionId,
    required this.inspectionCode,
    required this.stages,
    required this.events,
  });

  factory ChainOfCustodyData.fromJson(Map<String, dynamic> json) {
    final stList = (json['stages'] as List?)?.map((s) => ChainOfCustodyStage.fromJson(s as Map<String, dynamic>)).toList() ?? [];
    final evList = (json['events'] as List?)?.map((e) => AuditEvent.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    return ChainOfCustodyData(
      inspectionId: (json['inspection_id'] ?? '').toString(),
      inspectionCode: (json['inspection_code'] ?? json['inspection_id'] ?? '').toString(),
      stages: stList,
      events: evList,
    );
  }
}
