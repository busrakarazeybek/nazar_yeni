enum MatchStatus { pending, accepted, rejected }

class Match {
  final String id;
  final String selectorId;
  final String candidateId;
  final String targetCandidateId;
  final MatchStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Additional profile information
  final String? selectorName;
  final String? selectorImageUrl;
  final String? candidateName;
  final String? candidateImageUrl;
  final String? targetCandidateName;
  final String? targetCandidateImageUrl;

  Match({
    required this.id,
    required this.selectorId,
    required this.candidateId,
    required this.targetCandidateId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.selectorName,
    this.selectorImageUrl,
    this.candidateName,
    this.candidateImageUrl,
    this.targetCandidateName,
    this.targetCandidateImageUrl,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      selectorId: json['selector_id'] as String,
      candidateId: json['candidate_id'] as String,
      targetCandidateId: json['target_candidate_id'] as String,
      status: _parseMatchStatus(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      selectorName: json['selector']?['full_name'] as String?,
      selectorImageUrl: json['selector']?['image_url'] as String?,
      candidateName: json['candidate']?['full_name'] as String?,
      candidateImageUrl: json['candidate']?['image_url'] as String?,
      targetCandidateName: json['target_candidate']?['full_name'] as String?,
      targetCandidateImageUrl:
          json['target_candidate']?['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'selector_id': selectorId,
      'candidate_id': candidateId,
      'target_candidate_id': targetCandidateId,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Match copyWith({
    MatchStatus? status,
    DateTime? updatedAt,
    String? selectorName,
    String? selectorImageUrl,
    String? candidateName,
    String? candidateImageUrl,
    String? targetCandidateName,
    String? targetCandidateImageUrl,
  }) {
    return Match(
      id: id,
      selectorId: selectorId,
      candidateId: candidateId,
      targetCandidateId: targetCandidateId,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      selectorName: selectorName ?? this.selectorName,
      selectorImageUrl: selectorImageUrl ?? this.selectorImageUrl,
      candidateName: candidateName ?? this.candidateName,
      candidateImageUrl: candidateImageUrl ?? this.candidateImageUrl,
      targetCandidateName: targetCandidateName ?? this.targetCandidateName,
      targetCandidateImageUrl:
          targetCandidateImageUrl ?? this.targetCandidateImageUrl,
    );
  }

  static MatchStatus _parseMatchStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return MatchStatus.pending;
      case 'accepted':
        return MatchStatus.accepted;
      case 'rejected':
        return MatchStatus.rejected;
      default:
        return MatchStatus.pending;
    }
  }

  // Convenience getters
  String get displayStatus {
    switch (status) {
      case MatchStatus.pending:
        return 'Bekliyor';
      case MatchStatus.accepted:
        return 'Kabul Edildi';
      case MatchStatus.rejected:
        return 'Reddedildi';
    }
  }

  bool get isPending => status == MatchStatus.pending;
  bool get isAccepted => status == MatchStatus.accepted;
  bool get isRejected => status == MatchStatus.rejected;
  bool get isMatched => status == MatchStatus.accepted;

  @override
  String toString() {
    return 'Match(id: $id, status: $status, selectorId: $selectorId, candidateId: $candidateId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Match && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
