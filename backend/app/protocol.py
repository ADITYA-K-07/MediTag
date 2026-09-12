"""The stable binary contract shared by the issuer and the mobile reader.

The unsigned Tier 1 payload is exactly 15 bytes.  Appending the 64-byte raw
P-256 signature creates the 79-byte value stored in one NDEF record.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import IntEnum
import re
import struct


FORMAT_VERSION = 1
UNSIGNED_PAYLOAD_LENGTH = 15
SIGNATURE_LENGTH = 64
TAG_PAYLOAD_LENGTH = UNSIGNED_PAYLOAD_LENGTH + SIGNATURE_LENGTH


class BloodType(IntEnum):
    UNKNOWN = 0
    A_POSITIVE = 1
    A_NEGATIVE = 2
    B_POSITIVE = 3
    B_NEGATIVE = 4
    AB_POSITIVE = 5
    AB_NEGATIVE = 6
    O_POSITIVE = 7
    O_NEGATIVE = 8


BLOOD_TYPE_NAMES = {
    BloodType.UNKNOWN: "Unknown",
    BloodType.A_POSITIVE: "A+",
    BloodType.A_NEGATIVE: "A-",
    BloodType.B_POSITIVE: "B+",
    BloodType.B_NEGATIVE: "B-",
    BloodType.AB_POSITIVE: "AB+",
    BloodType.AB_NEGATIVE: "AB-",
    BloodType.O_POSITIVE: "O+",
    BloodType.O_NEGATIVE: "O-",
}


ALLERGY_FLAGS = {
    "penicillin": 0,
    "sulfonamides": 1,
    "aspirin_nsaids": 2,
    "contrast_dye": 3,
    "latex": 4,
    "peanuts": 5,
    "tree_nuts": 6,
    "milk": 7,
    "eggs": 8,
    "shellfish": 9,
    "soy": 10,
    "wheat": 11,
    "insect_stings": 12,
}

CONDITION_FLAGS = {
    "diabetes": 0,
    "epilepsy": 1,
    "heart_disease": 2,
    "hypertension": 3,
    "asthma": 4,
    "copd": 5,
    "kidney_disease": 6,
    "liver_disease": 7,
    "anticoagulants": 8,
    "immunocompromised": 9,
    "pregnancy": 10,
}


def encode_flags(values: list[str], assignments: dict[str, int], label: str) -> int:
    unknown = sorted(set(values) - set(assignments))
    if unknown:
        raise ValueError(f"Unknown {label}: {', '.join(unknown)}")
    return sum(1 << assignments[value] for value in set(values))


def decode_flags(value: int, assignments: dict[str, int]) -> list[str]:
    return [name for name, bit in assignments.items() if value & (1 << bit)]


def pack_indian_phone(phone: str) -> bytes:
    """Pack exactly ten Indian national-number digits into five BCD bytes."""
    digits = re.sub(r"[\s\-()]", "", phone)
    if digits.startswith("+91"):
        digits = digits[3:]
    elif digits.startswith("91") and len(digits) == 12:
        digits = digits[2:]
    if not re.fullmatch(r"\d{10}", digits):
        raise ValueError("Emergency phone must be a 10-digit Indian number (optionally prefixed +91).")
    return bytes((int(digits[index]) << 4) | int(digits[index + 1]) for index in range(0, 10, 2))


def unpack_indian_phone(value: bytes) -> str:
    if len(value) != 5:
        raise ValueError("Packed phone must be exactly five bytes.")
    digits = "".join(f"{byte >> 4}{byte & 0x0F}" for byte in value)
    if not re.fullmatch(r"\d{10}", digits):
        raise ValueError("Invalid BCD phone value.")
    return digits


@dataclass(frozen=True)
class Tier1Data:
    blood_type: BloodType
    allergy_mask: int
    condition_mask: int
    emergency_phone: str
    tag_id: int

    def encode_unsigned(self) -> bytes:
        if not 0 <= self.allergy_mask <= 0xFFFF or not 0 <= self.condition_mask <= 0xFFFF:
            raise ValueError("Flag masks must fit in 16 bits.")
        if not 0 <= self.tag_id <= 0xFFFFFFFF:
            raise ValueError("tag_id must fit in an unsigned 32-bit integer.")
        return struct.pack(
            ">BBHH5sI",
            FORMAT_VERSION,
            int(self.blood_type),
            self.allergy_mask,
            self.condition_mask,
            pack_indian_phone(self.emergency_phone),
            self.tag_id,
        )

    @classmethod
    def decode_unsigned(cls, value: bytes) -> "Tier1Data":
        if len(value) != UNSIGNED_PAYLOAD_LENGTH:
            raise ValueError(f"Tier 1 data must be {UNSIGNED_PAYLOAD_LENGTH} bytes.")
        version, blood, allergies, conditions, phone, tag_id = struct.unpack(">BBHH5sI", value)
        if version != FORMAT_VERSION:
            raise ValueError(f"Unsupported Tier 1 format version: {version}")
        try:
            blood_type = BloodType(blood)
        except ValueError as exc:
            raise ValueError(f"Unknown blood type enum: {blood}") from exc
        return cls(blood_type, allergies, conditions, unpack_indian_phone(phone), tag_id)

    def as_display_dict(self) -> dict[str, object]:
        return {
            "format_version": FORMAT_VERSION,
            "tag_id": self.tag_id,
            "blood_type": BLOOD_TYPE_NAMES[self.blood_type],
            "allergies": decode_flags(self.allergy_mask, ALLERGY_FLAGS),
            "critical_conditions": decode_flags(self.condition_mask, CONDITION_FLAGS),
            "emergency_phone": self.emergency_phone,
        }
