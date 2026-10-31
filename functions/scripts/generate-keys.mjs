// Generates the tag-signing key pair and the tag-password encryption key.
// Store the private values as Firebase secrets; ship the public key with the app and website.
//   npx firebase-tools functions:secrets:set TAG_SIGNING_KEY < signing-private.pem
//   npx firebase-tools functions:secrets:set TAG_SECRET_KEY
import { createPublicKey, generateKeyPairSync, randomBytes } from 'node:crypto';

const { privateKey, publicKey } = generateKeyPairSync('ec', { namedCurve: 'P-256' });
const jwk = createPublicKey(publicKey).export({ format: 'jwk' });
const raw = Buffer.concat([Buffer.from([4]), Buffer.from(jwk.x, 'base64url'), Buffer.from(jwk.y, 'base64url')]);

console.log('# TAG_SIGNING_KEY (secret, PKCS#8 PEM)');
console.log(privateKey.export({ type: 'pkcs8', format: 'pem' }));
console.log('# Public key for clients (uncompressed P-256, hex)');
console.log(raw.toString('hex'));
console.log('\n# TAG_SECRET_KEY (secret, base64, 32 bytes)');
console.log(randomBytes(32).toString('base64'));
