// Statutory Reference Domain Models for LM-TRACE

class StatutorySummaryModel {
  final int totalDocuments;
  final int activeDocuments;
  final int amendmentDocuments;
  final int scheduledDocuments;
  final int totalStatutoryRules;
  final int activeStatutoryRules;
  final int scheduledRules;
  final int automatedRulesCount;
  final int unautomatedRulesCount;
  final List<String> ruleFamilies;
  final String jurisdiction;
  final String lastStatutoryUpdate;

  StatutorySummaryModel({
    required this.totalDocuments,
    required this.activeDocuments,
    required this.amendmentDocuments,
    required this.scheduledDocuments,
    required this.totalStatutoryRules,
    required this.activeStatutoryRules,
    required this.scheduledRules,
    required this.automatedRulesCount,
    required this.unautomatedRulesCount,
    required this.ruleFamilies,
    required this.jurisdiction,
    required this.lastStatutoryUpdate,
  });

  factory StatutorySummaryModel.fromJson(Map<String, dynamic> json) {
    return StatutorySummaryModel(
      totalDocuments: json['total_documents'] as int? ?? 0,
      activeDocuments: json['active_documents'] as int? ?? 0,
      amendmentDocuments: json['amendment_documents'] as int? ?? 0,
      scheduledDocuments: json['scheduled_documents'] as int? ?? 0,
      totalStatutoryRules: json['total_statutory_rules'] as int? ?? 0,
      activeStatutoryRules: json['active_statutory_rules'] as int? ?? 0,
      scheduledRules: json['scheduled_rules'] as int? ?? 0,
      automatedRulesCount: json['automated_rules_count'] as int? ?? 0,
      unautomatedRulesCount: json['unautomated_rules_count'] as int? ?? 0,
      ruleFamilies: (json['rule_families'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      jurisdiction: json['jurisdiction'] as String? ?? 'Union of India',
      lastStatutoryUpdate: json['last_statutory_update'] as String? ?? '',
    );
  }
}

class StatutoryDocumentModel {
  final String id;
  final String title;
  final String shortTitle;
  final String documentType;
  final String authority;
  final String jurisdiction;
  final String? notificationNumber;
  final String? gazetteReference;
  final String publicationDate;
  final String effectiveDate;
  final String? expiryDate;
  final String status;
  final String? sourceUrl;
  final String? officialDocumentUrl;
  final String version;
  final String? parentDocumentId;
  final String ruleFamily;
  final String summary;
  final int rulesCount;

  StatutoryDocumentModel({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.documentType,
    required this.authority,
    required this.jurisdiction,
    this.notificationNumber,
    this.gazetteReference,
    required this.publicationDate,
    required this.effectiveDate,
    this.expiryDate,
    required this.status,
    this.sourceUrl,
    this.officialDocumentUrl,
    required this.version,
    this.parentDocumentId,
    required this.ruleFamily,
    required this.summary,
    required this.rulesCount,
  });

  bool get isScheduled => status.toUpperCase() == 'NOT_YET_EFFECTIVE' || status.toUpperCase() == 'SCHEDULED';
  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory StatutoryDocumentModel.fromJson(Map<String, dynamic> json) {
    return StatutoryDocumentModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      shortTitle: json['short_title'] as String? ?? '',
      documentType: json['document_type'] as String? ?? '',
      authority: json['authority'] as String? ?? '',
      jurisdiction: json['jurisdiction'] as String? ?? '',
      notificationNumber: json['notification_number'] as String?,
      gazetteReference: json['gazette_reference'] as String?,
      publicationDate: json['publication_date'] as String? ?? '',
      effectiveDate: json['effective_date'] as String? ?? '',
      expiryDate: json['expiry_date'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      sourceUrl: json['source_url'] as String?,
      officialDocumentUrl: json['official_document_url'] as String?,
      version: json['version'] as String? ?? '1.0',
      parentDocumentId: json['parent_document_id'] as String?,
      ruleFamily: json['rule_family'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      rulesCount: json['rules_count'] as int? ?? 0,
    );
  }
}

class StatutoryRuleModel {
  final String id;
  final String ruleCode;
  final String documentId;
  final String documentTitle;
  final String ruleFamily;
  final String ruleNumber;
  final String title;
  final String requirementSummary;
  final String subject;
  final String applicability;
  final String sourceReference;
  final String version;
  final String publicationDate;
  final String effectiveFrom;
  final String? effectiveTo;
  final String status;
  final String? mappedRuleEngineId;
  final String? mappedRuleEngineCode;
  final bool isAutomated;
  final String? officialUrl;
  final StatutoryDocumentModel? sourceDocument;

  StatutoryRuleModel({
    required this.id,
    required this.ruleCode,
    required this.documentId,
    required this.documentTitle,
    required this.ruleFamily,
    required this.ruleNumber,
    required this.title,
    required this.requirementSummary,
    required this.subject,
    required this.applicability,
    required this.sourceReference,
    required this.version,
    required this.publicationDate,
    required this.effectiveFrom,
    this.effectiveTo,
    required this.status,
    this.mappedRuleEngineId,
    this.mappedRuleEngineCode,
    required this.isAutomated,
    this.officialUrl,
    this.sourceDocument,
  });

  bool get isScheduled => status.toUpperCase() == 'NOT_YET_EFFECTIVE' || status.toUpperCase() == 'SCHEDULED';
  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory StatutoryRuleModel.fromJson(Map<String, dynamic> json) {
    return StatutoryRuleModel(
      id: json['id'] as String? ?? '',
      ruleCode: json['rule_code'] as String? ?? '',
      documentId: json['document_id'] as String? ?? '',
      documentTitle: json['document_title'] as String? ?? '',
      ruleFamily: json['rule_family'] as String? ?? '',
      ruleNumber: json['rule_number'] as String? ?? '',
      title: json['title'] as String? ?? '',
      requirementSummary: json['requirement_summary'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      applicability: json['applicability'] as String? ?? '',
      sourceReference: json['source_reference'] as String? ?? '',
      version: json['version'] as String? ?? '1.0',
      publicationDate: json['publication_date'] as String? ?? '',
      effectiveFrom: json['effective_from'] as String? ?? '',
      effectiveTo: json['effective_to'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      mappedRuleEngineId: json['mapped_rule_engine_id'] as String?,
      mappedRuleEngineCode: json['mapped_rule_engine_code'] as String?,
      isAutomated: json['is_automated'] as bool? ?? false,
      officialUrl: json['official_url'] as String?,
      sourceDocument: json['source_document'] != null && json['source_document'] is Map<String, dynamic>
          ? StatutoryDocumentModel.fromJson(json['source_document'] as Map<String, dynamic>)
          : null,
    );
  }
}

class StatutoryFamilyModel {
  final String id;
  final String name;
  final String description;
  final int ruleCount;
  final int documentCount;

  StatutoryFamilyModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ruleCount,
    required this.documentCount,
  });

  factory StatutoryFamilyModel.fromJson(Map<String, dynamic> json) {
    return StatutoryFamilyModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ruleCount: json['rule_count'] as int? ?? 0,
      documentCount: json['document_count'] as int? ?? 0,
    );
  }
}

class StatutoryTraceabilityModel {
  final String findingOrRuleCode;
  final StatutoryRuleModel statutoryRule;
  final StatutoryDocumentModel? parentDocument;
  final List<String> traceabilityChain;
  final String effectiveStatus;

  StatutoryTraceabilityModel({
    required this.findingOrRuleCode,
    required this.statutoryRule,
    this.parentDocument,
    required this.traceabilityChain,
    required this.effectiveStatus,
  });

  factory StatutoryTraceabilityModel.fromJson(Map<String, dynamic> json) {
    return StatutoryTraceabilityModel(
      findingOrRuleCode: json['finding_or_rule_code'] as String? ?? '',
      statutoryRule: StatutoryRuleModel.fromJson(json['statutory_rule'] as Map<String, dynamic>),
      parentDocument: json['parent_document'] != null && json['parent_document'] is Map<String, dynamic>
          ? StatutoryDocumentModel.fromJson(json['parent_document'] as Map<String, dynamic>)
          : null,
      traceabilityChain: (json['traceability_chain'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      effectiveStatus: json['effective_status'] as String? ?? 'ACTIVE',
    );
  }
}
