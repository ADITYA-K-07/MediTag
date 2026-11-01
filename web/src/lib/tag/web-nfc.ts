// Web NFC (Chrome on Android only). https://w3c.github.io/web-nfc/
// Types are declared here because TypeScript's DOM lib does not ship them.

interface NDEFRecord {
  recordType: string;
  mediaType?: string;
  data?: DataView;
  encoding?: string;
}

interface NDEFReadingEvent extends Event {
  serialNumber: string;
  message: { records: NDEFRecord[] };
}

interface NDEFReader extends EventTarget {
  scan(options?: { signal?: AbortSignal }): Promise<void>;
  onreading: ((event: NDEFReadingEvent) => void) | null;
  onreadingerror: ((event: Event) => void) | null;
}

declare global {
  interface Window {
    NDEFReader?: { new (): NDEFReader };
  }
}

export const MEDITAG_MIME_TYPE = "application/vnd.meditag.v1";

export interface TagRead {
  serialNumber: string;
  /** The signed envelope, if the tag has a MediTag record. */
  envelope?: Uint8Array;
  /** The tag's URL record, e.g. https://meditag.app/e/<tagId>. */
  url?: string;
}

export function webNfcSupported(): boolean {
  return typeof window !== "undefined" && "NDEFReader" in window;
}

/** Resolves with the first tag read. Rejects if permission is denied or NFC is off. */
export async function readOneTag(signal: AbortSignal): Promise<TagRead> {
  const reader = new window.NDEFReader!();
  await reader.scan({ signal });
  return new Promise((resolve, reject) => {
    signal.addEventListener("abort", () => reject(new DOMException("Scan cancelled", "AbortError")));
    reader.onreadingerror = () => reject(new Error("Could not read the tag. Hold it still and try again."));
    reader.onreading = (event) => {
      const read: TagRead = { serialNumber: event.serialNumber };
      for (const record of event.message.records) {
        if (record.recordType === "mime" && record.mediaType === MEDITAG_MIME_TYPE && record.data) {
          read.envelope = new Uint8Array(record.data.buffer, record.data.byteOffset, record.data.byteLength);
        } else if (record.recordType === "url" && record.data) {
          read.url = new TextDecoder().decode(record.data);
        }
      }
      resolve(read);
    };
  });
}
