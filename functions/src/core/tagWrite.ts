// Assembles everything a client needs to program one tag. Pure: keys (PEM) and time are passed in.
import { encodeEnvelope } from './envelope';
import { ANDROID_PACKAGE, emergencyUri, fitsOnNtag216, MEDITAG_MIME_TYPE, tagBytesNeeded } from './ndef';
import { buildPayload, EmergencyProfile, encodePayloadJson, validatePayload } from './payload';
import { signBytes } from './signing';

export class TagWriteError extends Error {
  constructor(message: string, readonly details: string[] = []) {
    super(message);
  }
}

export interface TagWritePlan {
  tagId: string;
  uri: string;
  mimeType: string;
  /** Base64 of the binary envelope for the MIME record. */
  envelope: string;
  androidPackage: string;
  bytesNeeded: number;
}

export function planTagWrite(opts: {
  profile: EmergencyProfile;
  tagId: string;
  baseUrl: string;
  signingKey: string;
  keyId: number;
  now: number;
}): TagWritePlan {
  const payload = buildPayload(opts.profile, opts.tagId, Math.floor(opts.now / 1000));
  const problems = validatePayload(payload);
  if (problems.length > 0) throw new TagWriteError('Emergency profile cannot be written to a tag', problems);

  const json = encodePayloadJson(payload);
  const envelope = encodeEnvelope({ json, keyId: opts.keyId, signature: signBytes(json, opts.signingKey) });
  const uri = emergencyUri(opts.baseUrl, opts.tagId);
  const layout = { uri, envelopeLength: envelope.length };
  if (!fitsOnNtag216(layout)) {
    throw new TagWriteError('Too much information for one tag. Move some fields to cloud only.', [
      `needs ${tagBytesNeeded(layout)} of 888 bytes`,
    ]);
  }
  return {
    tagId: opts.tagId,
    uri,
    mimeType: MEDITAG_MIME_TYPE,
    envelope: Buffer.from(envelope).toString('base64'),
    androidPackage: ANDROID_PACKAGE,
    bytesNeeded: tagBytesNeeded(layout),
  };
}
