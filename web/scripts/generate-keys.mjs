// Generates the tag-signing key pair and the tag-password encryption key, as ready-to-paste env lines.
// The two secrets go only into web/.env.local and Vercel's Environment Variables (see SETUP.md).
import { generateKeyPairSync, randomBytes } from 'node:crypto';

const { privateKey, publicKey } = generateKeyPairSync('ec', { namedCurve: 'P-256' });
const jwk = publicKey.export({ format: 'jwk' });
const raw = Buffer.concat([Buffer.from([4]), Buffer.from(jwk.x, 'base64url'), Buffer.from(jwk.y, 'base64url')]);
const pem = privateKey.export({ type: 'pkcs8', format: 'pem' });

console.log('# SECRET: web/.env.local and Vercel only');
console.log(`TAG_SIGNING_KEY=${Buffer.from(pem).toString('base64')}`);
console.log(`TAG_SECRET_KEY=${randomBytes(32).toString('base64')}`);
console.log('\n# Public: safe to share, also needed by the app (--dart-define=TAG_PUBLIC_KEYS=...)');
console.log(`NEXT_PUBLIC_TAG_PUBLIC_KEYS={"1":"${raw.toString('hex')}"}`);
