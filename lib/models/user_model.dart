class UserModel {
  final int? id;
  final String? name;
  final String? email;
  final String? image;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender; // 'male', 'female', 'other'
  final String? address;
  final bool? policyAccept; // Track terms and conditions acceptance

  UserModel({
    this.id,
    this.name,
    this.email,
    this.image,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.policyAccept,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      image: json['image'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      policyAccept: json['policy_accept'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'image': image,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address,
      'policy_accept': policyAccept,
    };
  }
}