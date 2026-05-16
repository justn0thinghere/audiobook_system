import '_json_helpers.dart';

class Caregiver {
  final String caregiverId;
  final String name;
  final String? email;
  final String? mobileNumber;

  const Caregiver({
    required this.caregiverId,
    required this.name,
    this.email,
    this.mobileNumber,
  });

  factory Caregiver.fromJson(Map<String, dynamic> json) {
    return Caregiver(
      caregiverId: safeString(json['caregiver_id']),
      name: safeString(json['name']),
      email: safeNullableString(json['email']),
      mobileNumber: safeNullableString(json['mobile_number']),
    );
  }

  Map<String, dynamic> toJson() => {
        'caregiver_id': caregiverId,
        'name': name,
        'email': email,
        'mobile_number': mobileNumber,
      };
}
