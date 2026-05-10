class Student {
  final String id;
  final String? name;
  final String phone;

  const Student({required this.id, this.name, required this.phone});

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'] as String,
    name: json['name'] as String?,
    phone: json['phone'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone};

  String get displayName => name?.isNotEmpty == true ? name! : phone;
}
