/// A saved address of a client (used for service bookings).
///
/// Stored in `users/{uid}.addresses` (a list of maps) — only the owner
/// can write their user document (enforced by firestore.rules), so no
/// dedicated collection or rules change is needed.
class Address {
  /// Human-readable label, e.g. "Maison", "Bureau".
  final String label;

  /// Full street address (required).
  final String fullAddress;

  /// Optional city / notes / district.
  final String? notes;

  const Address({
    required this.label,
    required this.fullAddress,
    this.notes,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      label: (map['label'] as String?) ?? '',
      fullAddress: (map['address'] as String?) ?? '',
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'address': fullAddress,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
      };

  Address copyWith({String? label, String? fullAddress, String? notes}) {
    return Address(
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address &&
          other.label == label &&
          other.fullAddress == fullAddress &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(label, fullAddress, notes);

  @override
  String toString() => 'Address($label, $fullAddress)';
}
