// Self-check for reset-password redirect logic (Node-compatible).
// Mirrors the decision logic in index.ts so the URL can be verified without an Auth client.

const assert = require('assert');

const subdomain = 'demo';

function getRedirect(last_sign_in_at) {
  const hasSignedIn = !!last_sign_in_at;
  const type = hasSignedIn ? 'recovery' : 'invite';
  const path = hasSignedIn ? 'reset-password' : 'set-password';
  const redirectTo = `https://${subdomain}.vietsalepro.com/${path}`;
  return { type, redirectTo };
}

const cases = [
  {
    label: 'user đã từng đăng nhập',
    last_sign_in_at: '2026-07-05T00:00:00Z',
    expected: { type: 'recovery', redirectTo: 'https://demo.vietsalepro.com/reset-password' },
  },
  {
    label: 'user mới chưa đăng nhập',
    last_sign_in_at: null,
    expected: { type: 'invite', redirectTo: 'https://demo.vietsalepro.com/set-password' },
  },
  {
    label: 'user mới chưa đăng nhập (undefined)',
    last_sign_in_at: undefined,
    expected: { type: 'invite', redirectTo: 'https://demo.vietsalepro.com/set-password' },
  },
];

for (const c of cases) {
  const actual = getRedirect(c.last_sign_in_at);
  assert.deepStrictEqual(
    actual,
    c.expected,
    `Failed for ${c.label}: expected ${JSON.stringify(c.expected)}, got ${JSON.stringify(actual)}`
  );
  console.log(`OK: ${c.label} -> ${actual.type} ${actual.redirectTo}`);
}

console.log('All redirect checks passed.');
