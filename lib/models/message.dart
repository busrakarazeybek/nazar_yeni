class Message {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Additional sender information
  final String? senderName;
  final String? senderImageUrl;

  Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.updatedAt,
    this.senderName,
    this.senderImageUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      matchId: json['match_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      senderName: json['sender']?['full_name'] as String?,
      senderImageUrl: json['sender']?['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'sender_id': senderId,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Message copyWith({
    String? content,
    bool? isRead,
    DateTime? updatedAt,
    String? senderName,
    String? senderImageUrl,
  }) {
    return Message(
      id: id,
      matchId: matchId,
      senderId: senderId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      senderName: senderName ?? this.senderName,
      senderImageUrl: senderImageUrl ?? this.senderImageUrl,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, matchId: $matchId, senderId: $senderId, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
