from cryptography.hazmat.primitives.asymmetric import ec

from app.crypto import TagSigner, verify_raw
from app.protocol import ALLERGY_FLAGS, BloodType, CONDITION_FLAGS, TAG_PAYLOAD_LENGTH, Tier1Data, encode_flags


def test_payload_round_trip_and_signature():
    data = Tier1Data(
        blood_type=BloodType.O_NEGATIVE,
        allergy_mask=encode_flags(["penicillin", "latex"], ALLERGY_FLAGS, "allergies"),
        condition_mask=encode_flags(["diabetes"], CONDITION_FLAGS, "conditions"),
        emergency_phone="+91 98765 43210",
        tag_id=1001,
    )
    unsigned = data.encode_unsigned()
    assert len(unsigned) == 15
    assert Tier1Data.decode_unsigned(unsigned).as_display_dict()["emergency_phone"] == "9876543210"

    signer = TagSigner(ec.generate_private_key(ec.SECP256R1()))
    signed = unsigned + signer.sign_raw(unsigned)
    assert len(signed) == TAG_PAYLOAD_LENGTH
    assert verify_raw(unsigned, signed[15:], signer._private_key.public_key())

    tampered = bytearray(unsigned)
    tampered[2] ^= 1
    assert not verify_raw(bytes(tampered), signed[15:], signer._private_key.public_key())
