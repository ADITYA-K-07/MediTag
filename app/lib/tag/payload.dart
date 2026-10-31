// Mirrors functions/src/core/payload.ts and schema/tag-payload.schema.json.

class TagContact {
  const TagContact({required this.name, this.relation, required this.phone});
  final String name;
  final String? relation;
  final String phone;

  factory TagContact.fromJson(Map<String, dynamic> j) =>
      TagContact(name: j['n'] as String, relation: j['r'] as String?, phone: j['p'] as String);
}

class TagPayload {
  const TagPayload({
    required this.tagId,
    required this.name,
    required this.signedAt,
    this.dob,
    this.sex,
    this.bloodGroup,
    this.allergies = const [],
    this.conditions = const [],
    this.medications = const [],
    this.organDonor,
    this.contacts = const [],
  });

  final String tagId;
  final String name;
  final DateTime signedAt;
  final String? dob;
  final String? sex;
  final String? bloodGroup;
  final List<String> allergies;
  final List<String> conditions;
  final List<String> medications;
  final bool? organDonor;
  final List<TagContact> contacts;

  factory TagPayload.fromJson(Map<String, dynamic> j) {
    if (j['v'] != 1 || j['n'] is! String || j['tid'] is! String || j['ts'] is! int) {
      throw const FormatException('not a v1 MediTag payload');
    }
    List<String> strings(String key) => (j[key] as List<dynamic>?)?.cast<String>() ?? const [];
    return TagPayload(
      tagId: j['tid'] as String,
      name: j['n'] as String,
      signedAt: DateTime.fromMillisecondsSinceEpoch((j['ts'] as int) * 1000, isUtc: true),
      dob: j['dob'] as String?,
      sex: j['sx'] as String?,
      bloodGroup: j['bg'] as String?,
      allergies: strings('al'),
      conditions: strings('cc'),
      medications: strings('med'),
      organDonor: j['org'] as bool?,
      contacts: [for (final c in (j['ec'] as List<dynamic>? ?? const [])) TagContact.fromJson(c as Map<String, dynamic>)],
    );
  }

  int? ageOn(DateTime now) {
    final parts = dob?.split('-').map(int.tryParse).toList();
    if (parts == null || parts.length != 3 || parts.contains(null)) return null;
    var age = now.year - parts[0]!;
    if (now.month < parts[1]! || (now.month == parts[1]! && now.day < parts[2]!)) age--;
    return age;
  }

  String describe(DateTime now) {
    final age = ageOn(now);
    return [
      if (age != null) '$age yrs',
      if (sex != null) const {'M': 'Male', 'F': 'Female', 'O': 'Other'}[sex] ?? sex!,
      if (organDonor == true) 'Organ donor',
    ].join(' · ');
  }

  String get initials => name.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0].toUpperCase()).join();
}
