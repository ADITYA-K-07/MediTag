import { hexToBytes } from "../tag/envelope";
import type { TagPayload } from "../tag/payload";
import vectors from "./test-vectors.json";

export const DEMO_TAG_ID = "k8Fq2xLm9Pz4Rt7W";

const envelopeHex = (name: string) => vectors.cases.find((c) => c.name === name)!.envelopeHex;

export const demoTags = {
  genuine: () => hexToBytes(envelopeHex("valid")),
  tampered: () => hexToBytes(envelopeHex("tampered-blood-group")),
};

export const demoPayload = vectors.cases.find((c) => c.name === "valid")!.expectPayload as TagPayload;
