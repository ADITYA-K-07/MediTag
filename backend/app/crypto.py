"""P-256 signing helpers.  The NFC wire format deliberately uses raw r||s."""

from __future__ import annotations

from pathlib import Path

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, utils

from .protocol import SIGNATURE_LENGTH


class TagSigner:
    def __init__(self, private_key: ec.EllipticCurvePrivateKey):
        self._private_key = private_key

    @classmethod
    def load_or_create(cls, private_key_path: Path) -> "TagSigner":
        private_key_path.parent.mkdir(parents=True, exist_ok=True)
        if private_key_path.exists():
            private_key = serialization.load_pem_private_key(private_key_path.read_bytes(), password=None)
            if not isinstance(private_key, ec.EllipticCurvePrivateKey) or not isinstance(private_key.curve, ec.SECP256R1):
                raise ValueError("The issuer key must be an ECDSA P-256 private key.")
            return cls(private_key)
        private_key = ec.generate_private_key(ec.SECP256R1())
        private_key_path.write_bytes(
            private_key.private_bytes(
                serialization.Encoding.PEM,
                serialization.PrivateFormat.PKCS8,
                serialization.NoEncryption(),
            )
        )
        return cls(private_key)

    def sign_raw(self, payload: bytes) -> bytes:
        der_signature = self._private_key.sign(payload, ec.ECDSA(hashes.SHA256()))
        r, s = utils.decode_dss_signature(der_signature)
        return r.to_bytes(32, "big") + s.to_bytes(32, "big")

    def public_key_uncompressed(self) -> bytes:
        return self.public_key().public_bytes(
            serialization.Encoding.X962, serialization.PublicFormat.UncompressedPoint
        )

    def public_key_pem(self) -> str:
        return self.public_key().public_bytes(
            serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo
        ).decode("ascii")

    def public_key(self) -> ec.EllipticCurvePublicKey:
        return self._private_key.public_key()


def verify_raw(payload: bytes, signature: bytes, public_key: ec.EllipticCurvePublicKey) -> bool:
    if len(signature) != SIGNATURE_LENGTH:
        return False
    r = int.from_bytes(signature[:32], "big")
    s = int.from_bytes(signature[32:], "big")
    der_signature = utils.encode_dss_signature(r, s)
    try:
        public_key.verify(der_signature, payload, ec.ECDSA(hashes.SHA256()))
        return True
    except InvalidSignature:
        return False
