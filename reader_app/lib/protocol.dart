import 'dart:typed_data';

/// Mirrors backend/app/protocol.py. Do not change this independently.
const int tier1FormatVersion = 1;
const int unsignedPayloadLength = 15;
const int ecdsaSignatureLength = 64;
const int tier1TagPayloadLength = unsignedPayloadLength + ecdsaSignatureLength;

const Map<int, String> bloodTypes = {
  0: 'Unknown',
  1: 'A+',
  2: 'A-',
  3: 'B+',
  4: 'B-',
  5: 'AB+',
  6: 'AB-',
  7: 'O+',
  8: 'O-',
};

const Map<int, String> allergyFlags = {
  0: 'Penicillin',
  1: 'Sulfonamides',
  2: 'Aspirin / NSAIDs',
  3: 'Contrast dye',
  4: 'Latex',
  5: 'Peanuts',
  6: 'Tree nuts',
  7: 'Milk',
  8: 'Eggs',
  9: 'Shellfish',
  10: 'Soy',
  11: 'Wheat',
  12: 'Insect stings',
};

const Map<int, String> conditionFlags = {
  0: 'Diabetes',
  1: 'Epilepsy',
  2: 'Heart disease',
  3: 'Hypertension',
  4: 'Asthma',
  5: 'COPD',
  6: 'Kidney disease',
  7: 'Liver disease',
  8: 'On anticoagulants',
  9: 'Immunocompromised',
  10: 'Pregnancy',
};

class Tier1Payload {
  const Tier1Payload({
    required this.bloodType,
    required this.allergyMask,
    required this.conditionMask,
    required this.emergencyPhone,
    required this.tagId,
  });
  final int bloodType;
  final int allergyMask;
  final int conditionMask;
  final String emergencyPhone;
  final int tagId;

  String get bloodTypeName => bloodTypes[bloodType] ?? 'Invalid';
  List<String> get allergies => _decodeMask(allergyMask, allergyFlags);
  List<String> get conditions => _decodeMask(conditionMask, conditionFlags);

  static Tier1Payload decode(Uint8List bytes) {
    if (bytes.length != unsignedPayloadLength) {
      throw const FormatException('Tier 1 data must be exactly 15 bytes.');
    }
    if (bytes[0] != tier1FormatVersion) {
      throw FormatException('Unsupported tag format: ${bytes[0]}.');
    }
    if (!bloodTypes.containsKey(bytes[1])) {
      throw FormatException('Unknown blood type code: ${bytes[1]}.');
    }
    final data = ByteData.sublistView(bytes);
    return Tier1Payload(
      bloodType: bytes[1],
      allergyMask: data.getUint16(2, Endian.big),
      conditionMask: data.getUint16(4, Endian.big),
      emergencyPhone: _decodeBcd(bytes.sublist(6, 11)),
      tagId: data.getUint32(11, Endian.big),
    );
  }

  static String _decodeBcd(List<int> bcd) {
    if (bcd.length != 5) {
      throw const FormatException('Invalid emergency phone encoding.');
    }
    final digits = bcd.expand((byte) => [byte >> 4, byte & 0x0f]).join();
    if (!RegExp(r'^\d{10}$').hasMatch(digits)) {
      throw const FormatException('Invalid BCD emergency phone digits.');
    }
    return digits;
  }

  static List<String> _decodeMask(int mask, Map<int, String> assignments) => [
    for (final entry in assignments.entries)
      if ((mask & (1 << entry.key)) != 0) entry.value,
  ];
}
