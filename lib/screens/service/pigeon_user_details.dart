import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user in the Pigeon application with all essential details.
/// 
/// This model class handles conversion between Firestore documents and Dart objects,
/// including proper timestamp conversion and null safety.
class PigeonUserDetails {
  /// Unique identifier for the user (matches Firebase Auth UID)
  final String id;

  /// User's email address
  final String email;

  /// URL to the user's profile image (nullable)
  final String? profileImage;

  /// User's full name (nullable)
  final String? fullName;

  /// When the user account was created
  final DateTime? createdAt;

  /// When the user details were last updated
  final DateTime? lastUpdated;

  /// Creates a new PigeonUserDetails instance
  const PigeonUserDetails({
    required this.id,
    required this.email,
    this.profileImage,
    this.fullName,
    this.createdAt,
    this.lastUpdated,
  });

  /// Creates a PigeonUserDetails from a Firestore document map
  factory PigeonUserDetails.fromJson(Map<String, dynamic> json) {
    return PigeonUserDetails(
      id: json['id'] as String,
      email: json['email'] as String,
      profileImage: json['profileImage'] as String?,
      fullName: json['fullName'] as String?,
      createdAt: _parseTimestamp(json['createdAt']),
      lastUpdated: _parseTimestamp(json['lastUpdated']),
    );
  }

  /// Helper method to safely parse Firestore Timestamps
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return null;
  }

  /// Converts the user details to a Firestore-compatible map
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'profileImage': profileImage,
        'fullName': fullName,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      };

  /// Creates a copy of this user with updated fields
  PigeonUserDetails copyWith({
    String? id,
    String? email,
    String? profileImage,
    String? fullName,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return PigeonUserDetails(
      id: id ?? this.id,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Override toString for better debugging
  @override
  String toString() {
    return 'PigeonUserDetails('
        'id: $id, '
        'email: $email, '
        'fullName: $fullName, '
        'profileImage: ${profileImage != null ? 'set' : 'null'}, '
        'createdAt: ${createdAt?.toIso8601String()}, '
        'lastUpdated: ${lastUpdated?.toIso8601String()})';
  }

  /// Override equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PigeonUserDetails &&
        other.id == id &&
        other.email == email &&
        other.profileImage == profileImage &&
        other.fullName == fullName &&
        other.createdAt == createdAt &&
        other.lastUpdated == lastUpdated;
  }

  /// Override hashcode
  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      profileImage,
      fullName,
      createdAt,
      lastUpdated,
    );
  }
}
