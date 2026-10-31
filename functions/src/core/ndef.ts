// Byte budget for the MediTag NDEF message on an NTAG216 (888 bytes of user memory).

export const NTAG216_USER_BYTES = 888;
export const MEDITAG_MIME_TYPE = 'application/vnd.meditag.v1';
export const ANDROID_PACKAGE = 'com.meditag.app';
const AAR_TYPE = 'android.com:pkg';

// NFC Forum URI record prefix codes; the longest matching prefix is stored as one byte.
const URI_PREFIXES = ['https://www.', 'http://www.', 'https://', 'http://'];

const utf8Length = (s: string) => Buffer.byteLength(s, 'utf8');

/** Size of one NDEF record without an id field: header, type length, payload length (1 byte if < 256, else 4), type, payload. */
export function recordSize(typeLength: number, payloadLength: number): number {
  return 1 + 1 + (payloadLength < 256 ? 1 : 4) + typeLength + payloadLength;
}

export function uriPayloadLength(uri: string): number {
  const prefix = URI_PREFIXES.find((p) => uri.startsWith(p));
  return 1 + utf8Length(prefix ? uri.slice(prefix.length) : uri);
}

export interface MessageLayout {
  uri: string;
  envelopeLength: number;
  androidPackage?: string;
}

export function messageSize({ uri, envelopeLength, androidPackage = ANDROID_PACKAGE }: MessageLayout): number {
  return (
    recordSize(1, uriPayloadLength(uri)) +
    recordSize(utf8Length(MEDITAG_MIME_TYPE), envelopeLength) +
    recordSize(utf8Length(AAR_TYPE), utf8Length(androidPackage))
  );
}

/** NDEF message TLV on Type 2 tags: tag byte, length (1 byte if < 255, else 3), message, terminator TLV. */
export function tlvSize(messageLength: number): number {
  return 1 + (messageLength < 255 ? 1 : 3) + messageLength + 1;
}

export function tagBytesNeeded(layout: MessageLayout): number {
  return tlvSize(messageSize(layout));
}

export function fitsOnNtag216(layout: MessageLayout): boolean {
  return tagBytesNeeded(layout) <= NTAG216_USER_BYTES;
}

export function emergencyUri(baseUrl: string, tagId: string): string {
  return `${baseUrl.replace(/\/$/, '')}/e/${tagId}`;
}
