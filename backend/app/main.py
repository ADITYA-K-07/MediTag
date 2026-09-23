from __future__ import annotations

import base64
import os
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import Depends, FastAPI, Header, HTTPException, status
from pydantic import BaseModel, Field, field_validator

from .crypto import TagSigner, verify_raw
from .protocol import ALLERGY_FLAGS, BLOOD_TYPE_NAMES, BloodType, CONDITION_FLAGS, Tier1Data, encode_flags
from .store import TagStore


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = Path(os.getenv("MEDITAG_DATA_DIR", ROOT / "data"))
ADMIN_TOKEN = os.getenv("MEDITAG_ADMIN_TOKEN", "change-me-before-demo")
CLINICIAN_TOKEN = os.getenv("MEDITAG_CLINICIAN_TOKEN", "demo-clinician-token")
PRIVATE_KEY_BASE64 = os.getenv("MEDITAG_PRIVATE_KEY_BASE64", "")


class IssueTagRequest(BaseModel):
    tag_id: int = Field(ge=0, le=0xFFFFFFFF, examples=[1001])
    blood_type: BloodType
    allergies: list[str] = Field(default_factory=list)
    critical_conditions: list[str] = Field(default_factory=list)
    emergency_phone: str
    tier2_record: dict[str, object] = Field(default_factory=dict)

    @field_validator("allergies")
    @classmethod
    def validate_allergies(cls, values: list[str]) -> list[str]:
        encode_flags(values, ALLERGY_FLAGS, "allergies")
        return values

    @field_validator("critical_conditions")
    @classmethod
    def validate_conditions(cls, values: list[str]) -> list[str]:
        encode_flags(values, CONDITION_FLAGS, "critical conditions")
        return values


class VerifyRequest(BaseModel):
    payload_base64: str


def require_admin(x_admin_token: str | None = Header(default=None)) -> None:
    if x_admin_token != ADMIN_TOKEN:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Admin token required.")


def require_clinician(authorization: str | None = Header(default=None)) -> None:
    if authorization != f"Bearer {CLINICIAN_TOKEN}":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Verified clinician role required.")


@asynccontextmanager
async def lifespan(app: FastAPI):
    if PRIVATE_KEY_BASE64:
        try:
            private_key = base64.b64decode(PRIVATE_KEY_BASE64, validate=True)
            app.state.signer = TagSigner.from_pem(private_key)
        except (ValueError, TypeError) as exc:
            raise RuntimeError("MEDITAG_PRIVATE_KEY_BASE64 is not a valid P-256 PEM key.") from exc
    else:
        app.state.signer = TagSigner.load_or_create(DATA_DIR / "issuer-p256-private.pem")
    app.state.store = TagStore(DATA_DIR / "meditag.sqlite3")
    yield


app = FastAPI(title="MediTag API", version="0.1.0", lifespan=lifespan)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/protocol")
def protocol() -> dict[str, object]:
    return {
        "format_version": 1,
        "unsigned_payload_bytes": 15,
        "signature_bytes": 64,
        "tag_payload_bytes": 79,
        "signature_encoding": "ECDSA P-256 SHA-256, raw r||s (32 bytes each)",
        "blood_types": {str(int(key)): value for key, value in BLOOD_TYPE_NAMES.items()},
        "allergy_flags": ALLERGY_FLAGS,
        "condition_flags": CONDITION_FLAGS,
    }


@app.get("/public-key")
def public_key() -> dict[str, str]:
    """Provision this public key into the reader app at build/release time."""
    signer: TagSigner = app.state.signer
    return {
        "algorithm": "ECDSA P-256 with SHA-256",
        "encoding": "X9.62 uncompressed point, base64 (65 bytes)",
        "public_key_base64": base64.b64encode(signer.public_key_uncompressed()).decode("ascii"),
        "public_key_pem": signer.public_key_pem(),
    }


@app.post("/tags/issue", dependencies=[Depends(require_admin)])
def issue_tag(request: IssueTagRequest) -> dict[str, object]:
    data = Tier1Data(
        blood_type=request.blood_type,
        allergy_mask=encode_flags(request.allergies, ALLERGY_FLAGS, "allergies"),
        condition_mask=encode_flags(request.critical_conditions, CONDITION_FLAGS, "critical conditions"),
        emergency_phone=request.emergency_phone,
        tag_id=request.tag_id,
    )
    unsigned_payload = data.encode_unsigned()
    signer: TagSigner = app.state.signer
    signed_payload = unsigned_payload + signer.sign_raw(unsigned_payload)
    app.state.store.issue(request.tag_id, request.tier2_record)
    return {
        "tag_id": request.tag_id,
        "tier1": data.as_display_dict(),
        "ndef_payload_base64": base64.b64encode(signed_payload).decode("ascii"),
        "ndef_payload_hex": signed_payload.hex(),
        "payload_bytes": len(signed_payload),
        "write_instruction": "Write these bytes as a single NDEF record with TNF=unknown, empty type and identifier.",
    }


@app.post("/tags/verify")
def verify_tag(request: VerifyRequest) -> dict[str, object]:
    try:
        payload = base64.b64decode(request.payload_base64, validate=True)
        data = Tier1Data.decode_unsigned(payload[:15])
    except (ValueError, TypeError) as exc:
        raise HTTPException(status_code=400, detail=f"Malformed Tier 1 payload: {exc}") from exc
    valid = verify_raw(payload[:15], payload[15:], app.state.signer.public_key())
    return {"valid": valid, "tier1": data.as_display_dict() if valid else None}


@app.get("/tags/{tag_id}/tier2", dependencies=[Depends(require_clinician)])
def get_tier2(tag_id: int) -> dict[str, object]:
    tier2_record = app.state.store.get_tier2(tag_id)
    if tier2_record is None:
        raise HTTPException(status_code=404, detail="Tag not registered.")
    return {"tag_id": tag_id, "tier2": tier2_record}
