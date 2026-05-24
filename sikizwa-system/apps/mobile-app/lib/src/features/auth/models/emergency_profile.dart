class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
    required this.type,
  });

  final String name;
  final String phone;
  final String relationship;
  final String type;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'type': type,
    };
  }
}

class EmergencyProfile {
  const EmergencyProfile({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
    required this.contacts,
    required this.bloodGroup,
    required this.allergies,
    required this.medicalConditions,
    required this.location,
  });

  final String fullName;
  final String phone;
  final String? email;
  final String role;
  final List<EmergencyContact> contacts;
  final String? bloodGroup;
  final String? allergies;
  final String? medicalConditions;
  final String? location;

  factory EmergencyProfile.fromJson(Map<String, dynamic> json) {
    final rawContacts = json['contacts'];
    final contacts = rawContacts is List
        ? rawContacts
            .whereType<Map>()
            .map((entry) => EmergencyContact.fromJson(Map<String, dynamic>.from(entry)))
            .toList()
        : <EmergencyContact>[];

    return EmergencyProfile(
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? 'other',
      contacts: contacts,
      bloodGroup: json['bloodGroup']?.toString(),
      allergies: json['allergies']?.toString(),
      medicalConditions: json['medicalConditions']?.toString(),
      location: json['location']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'role': role,
      'contacts': contacts.map((contact) => contact.toJson()).toList(),
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'location': location,
    };
  }
}
