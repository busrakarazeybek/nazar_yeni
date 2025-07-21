enum MatchProposalStatus {
  pending,
  candidateAccepted,
  targetCandidateAccepted,
  candidate1Accepted,
  candidate2Accepted,
  bothAccepted,
  rejected
}

enum AcceptanceStatus { pending, accepted, rejected }

class MatchProposal {
  final String id;
  final String selectorId;
  final String candidateId;
  final String targetCandidateId;
  final AcceptanceStatus status;
  final AcceptanceStatus targetStatus;
  final MatchProposalStatus statusEnum;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? estimatedResponseTime;

  // Profile information
  final String? selectorName;
  final String? selectorImageUrl;
  final String? candidateName;
  final String? candidateImageUrl;
  final String? candidateBio;
  final String? targetCandidateName;
  final String? targetCandidateImageUrl;
  final String? targetCandidateBio;

  // Computed properties for backward compatibility
  String get candidate1Id => candidateId;
  String get candidate2Id => targetCandidateId;
  String? get candidate1Name => candidateName;
  String? get candidate2Name => targetCandidateName;
  String? get candidate1ImageUrl => candidateImageUrl;
  String? get candidate2ImageUrl => targetCandidateImageUrl;
  String? get candidate1Bio => candidateBio;
  String? get candidate2Bio => targetCandidateBio;

  AcceptanceStatus get status1 => status;
  AcceptanceStatus get status2 => targetStatus;

  MatchProposalStatus get finalStatus => statusEnum;

  MatchProposal({
    required this.id,
    required this.selectorId,
    required this.candidateId,
    required this.targetCandidateId,
    required this.status,
    required this.targetStatus,
    required this.statusEnum,
    required this.createdAt,
    this.updatedAt,
    this.estimatedResponseTime,
    this.selectorName,
    this.selectorImageUrl,
    this.candidateName,
    this.candidateImageUrl,
    this.candidateBio,
    this.targetCandidateName,
    this.targetCandidateImageUrl,
    this.targetCandidateBio,
  });

  factory MatchProposal.fromJson(Map<String, dynamic> json) {
    return MatchProposal(
      id: json['id'] as String,
      selectorId: json['selector_id'] as String,
      candidateId: json['candidate_id'] as String,
      targetCandidateId: json['target_candidate_id'] as String,
      status: _parseAcceptanceStatus(json['status'] as String?),
      targetStatus: _parseAcceptanceStatus(json['target_status'] as String?),
      statusEnum: _parseMatchProposalStatus(
          json['status'] as String?, json['target_status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      estimatedResponseTime: json['estimated_response_time'] != null
          ? DateTime.parse(json['estimated_response_time'] as String)
          : null,
      selectorName: json['selector']?['full_name'] as String?,
      selectorImageUrl: json['selector']?['image_url'] as String?,
      candidateName: json['candidate']?['full_name'] as String?,
      candidateImageUrl: json['candidate']?['image_url'] as String?,
      candidateBio: json['candidate']?['bio'] as String?,
      targetCandidateName: json['target_candidate']?['full_name'] as String?,
      targetCandidateImageUrl:
          json['target_candidate']?['image_url'] as String?,
      targetCandidateBio: json['target_candidate']?['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'selector_id': selectorId,
      'candidate_id': candidateId,
      'target_candidate_id': targetCandidateId,
      'status': status.toString().split('.').last,
      'target_status': targetStatus.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'estimated_response_time': estimatedResponseTime?.toIso8601String(),
    };
  }

  static AcceptanceStatus _parseAcceptanceStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return AcceptanceStatus.accepted;
      case 'rejected':
        return AcceptanceStatus.rejected;
      case 'pending':
      default:
        return AcceptanceStatus.pending;
    }
  }

  static MatchProposalStatus _parseMatchProposalStatus(
      String? status, String? targetStatus) {
    final statusEnum = _parseAcceptanceStatus(status);
    final targetStatusEnum = _parseAcceptanceStatus(targetStatus);

    if (statusEnum == AcceptanceStatus.rejected ||
        targetStatusEnum == AcceptanceStatus.rejected) {
      return MatchProposalStatus.rejected;
    } else if (statusEnum == AcceptanceStatus.accepted &&
        targetStatusEnum == AcceptanceStatus.accepted) {
      return MatchProposalStatus.bothAccepted;
    } else if (statusEnum == AcceptanceStatus.accepted) {
      return MatchProposalStatus.candidateAccepted;
    } else if (targetStatusEnum == AcceptanceStatus.accepted) {
      return MatchProposalStatus.targetCandidateAccepted;
    } else {
      return MatchProposalStatus.pending;
    }
  }

  // Progress calculations
  double get progressPercentage {
    switch (statusEnum) {
      case MatchProposalStatus.pending:
        return 0.25;
      case MatchProposalStatus.candidateAccepted:
      case MatchProposalStatus.targetCandidateAccepted:
      case MatchProposalStatus.candidate1Accepted:
      case MatchProposalStatus.candidate2Accepted:
        return 0.65;
      case MatchProposalStatus.bothAccepted:
        return 1.0;
      case MatchProposalStatus.rejected:
        return 0.0;
    }
  }

  String get statusDescription {
    switch (statusEnum) {
      case MatchProposalStatus.pending:
        return 'Öneri Gönderildi';
      case MatchProposalStatus.candidateAccepted:
      case MatchProposalStatus.candidate1Accepted:
        return 'İlk Onay Alındı';
      case MatchProposalStatus.targetCandidateAccepted:
      case MatchProposalStatus.candidate2Accepted:
        return 'İlk Onay Alındı';
      case MatchProposalStatus.bothAccepted:
        return 'Eşleşme Tamamlandı';
      case MatchProposalStatus.rejected:
        return 'Reddedildi';
    }
  }

  String get nextStepDescription {
    switch (statusEnum) {
      case MatchProposalStatus.pending:
        return 'Her iki adayın yanıtı bekleniyor';
      case MatchProposalStatus.candidateAccepted:
      case MatchProposalStatus.candidate1Accepted:
        return 'İkinci adayın onayı bekleniyor: ${targetCandidateName ?? 'Aday'}';
      case MatchProposalStatus.targetCandidateAccepted:
      case MatchProposalStatus.candidate2Accepted:
        return 'İkinci adayın onayı bekleniyor: ${candidateName ?? 'Aday'}';
      case MatchProposalStatus.bothAccepted:
        return 'Sohbet başlatılabilir';
      case MatchProposalStatus.rejected:
        return 'Eşleşme sona erdi';
    }
  }

  bool get canStartChat => statusEnum == MatchProposalStatus.bothAccepted;
  bool get isPending =>
      statusEnum == MatchProposalStatus.pending ||
      statusEnum == MatchProposalStatus.candidateAccepted ||
      statusEnum == MatchProposalStatus.targetCandidateAccepted ||
      statusEnum == MatchProposalStatus.candidate1Accepted ||
      statusEnum == MatchProposalStatus.candidate2Accepted;
  bool get isRejected => statusEnum == MatchProposalStatus.rejected;
  bool get isCompleted => statusEnum == MatchProposalStatus.bothAccepted;

  String? get waitingForCandidateName {
    if (status == AcceptanceStatus.pending &&
        targetStatus == AcceptanceStatus.accepted) {
      return candidateName;
    } else if (targetStatus == AcceptanceStatus.pending &&
        status == AcceptanceStatus.accepted) {
      return targetCandidateName;
    } else if (status == AcceptanceStatus.pending &&
        targetStatus == AcceptanceStatus.pending) {
      return 'Her iki aday';
    }
    return null;
  }

  Duration? get timeRemaining {
    if (estimatedResponseTime != null) {
      final remaining = estimatedResponseTime!.difference(DateTime.now());
      return remaining.isNegative ? null : remaining;
    }
    return null;
  }

  MatchProposal copyWith({
    AcceptanceStatus? status,
    AcceptanceStatus? targetStatus,
    MatchProposalStatus? statusEnum,
    DateTime? updatedAt,
    DateTime? estimatedResponseTime,
  }) {
    return MatchProposal(
      id: id,
      selectorId: selectorId,
      candidateId: candidateId,
      targetCandidateId: targetCandidateId,
      status: status ?? this.status,
      targetStatus: targetStatus ?? this.targetStatus,
      statusEnum: statusEnum ?? this.statusEnum,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedResponseTime:
          estimatedResponseTime ?? this.estimatedResponseTime,
      selectorName: selectorName,
      selectorImageUrl: selectorImageUrl,
      candidateName: candidateName,
      candidateImageUrl: candidateImageUrl,
      candidateBio: candidateBio,
      targetCandidateName: targetCandidateName,
      targetCandidateImageUrl: targetCandidateImageUrl,
      targetCandidateBio: targetCandidateBio,
    );
  }

  @override
  String toString() {
    return 'MatchProposal(id: $id, statusEnum: $statusEnum, candidate: $candidateName, targetCandidate: $targetCandidateName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchProposal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
