import { test } from 'node:test';
import assert from 'node:assert/strict';
import worker, { buildPrompt, MAX_TEXT } from '../src/index.js';

const env = { GEMINI_API_KEY: 'secret-key', GEMINI_MODEL: 'm1' };
const post = (body, headers = {}) =>
  new Request('https://w.example/translate', {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...headers },
    body: JSON.stringify(body),
  });

function mockFetch(status, body) {
  const calls = [];
  globalThis.fetch = async (url, init) => {
    calls.push({ url, init });
    return new Response(JSON.stringify(body), { status });
  };
  return calls;
}

test('forwards to Gemini with the secret key and our prompt', async () => {
  const calls = mockFetch(200, { candidates: [] });
  const res = await worker.fetch(
    post({ text: 'water', glossary: [{ tulu: 'ನೀರ್', roman: 'neer', en: 'water', kn: 'ನೀರು' }] }),
    env,
  );
  assert.equal(res.status, 200);
  assert.equal(calls.length, 1);
  assert.match(calls[0].url, /models\/m1:generateContent$/);
  assert.equal(calls[0].init.headers['x-goog-api-key'], 'secret-key');
  const sent = JSON.parse(calls[0].init.body);
  assert.match(sent.contents[0].parts[0].text, /ನೀರ್ \(neer\) = water/);
  assert.equal(sent.generationConfig.responseMimeType, 'application/json');
});

test('rejects bad requests without calling Gemini', async () => {
  const calls = mockFetch(200, {});
  assert.equal((await worker.fetch(post({ text: '' }), env)).status, 400);
  assert.equal((await worker.fetch(post({ text: 'x'.repeat(MAX_TEXT + 1) }), env)).status, 400);
  assert.equal((await worker.fetch(new Request('https://w.example/other'), env)).status, 404);
  assert.equal((await worker.fetch(post({ text: 'hi' }), {})).status, 500);
  assert.equal(calls.length, 0);
});

test('hides upstream key errors', async () => {
  mockFetch(403, { error: { message: 'API key invalid: secret-key' } });
  const res = await worker.fetch(post({ text: 'water' }), env);
  assert.equal(res.status, 502);
  assert.doesNotMatch(await res.text(), /secret-key/);
});

test('daily limit with KV', async () => {
  mockFetch(200, { candidates: [] });
  const store = new Map();
  const kv = { get: async (k) => store.get(k) ?? null, put: async (k, v) => store.set(k, v) };
  const e = { ...env, RATE_KV: kv, DAILY_LIMIT: '2' };
  const h = { 'cf-connecting-ip': '1.2.3.4' };
  assert.equal((await worker.fetch(post({ text: 'a' }, h), e)).status, 200);
  assert.equal((await worker.fetch(post({ text: 'b' }, h), e)).status, 200);
  assert.equal((await worker.fetch(post({ text: 'c' }, h), e)).status, 429);
});

test('buildPrompt caps glossary size', () => {
  const g = Array.from({ length: 50 }, (_, i) => ({ tulu: `t${i}`, roman: '', en: '', kn: '' }));
  assert.equal(buildPrompt('x', g).split('\n- ').length - 1, 20);
});

function memKv() {
  const store = new Map();
  return {
    store,
    get: async (k) => store.get(k) ?? null,
    put: async (k, v) => store.set(k, v),
    delete: async (k) => store.delete(k),
    list: async ({ prefix }) => ({
      keys: [...store.keys()].filter((k) => k.startsWith(prefix)).map((name) => ({ name })),
      list_complete: true,
    }),
  };
}

const suggest = (body) =>
  new Request('https://w.example/suggest', {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'cf-connecting-ip': '9.9.9.9' },
    body: JSON.stringify(body),
  });
const admin = (method, token, query = '') =>
  new Request(`https://w.example/admin/api${query}`, {
    method,
    headers: token ? { authorization: `Bearer ${token}` } : {},
  });

test('suggestions are stored and reviewed with the admin password', async () => {
  const kv = memKv();
  const e = { ...env, SUGGEST_KV: kv, ADMIN_TOKEN: 'pw' };
  const ok = await worker.fetch(suggest({ tulu: 'ರಾಜೆ', roman: 'raaje', en: 'king', note: 'x'.repeat(999) }), e);
  assert.equal(ok.status, 200);
  assert.equal((await worker.fetch(suggest({ tulu: 'raaje', en: 'king' }), e)).status, 400);
  assert.equal((await worker.fetch(suggest({ tulu: 'ರಾಜೆ' }), e)).status, 400);

  assert.equal((await worker.fetch(admin('GET'), e)).status, 401);
  assert.equal((await worker.fetch(admin('GET', 'wrong'), e)).status, 401);
  const list = await (await worker.fetch(admin('GET', 'pw'), e)).json();
  assert.equal(list.length, 1);
  assert.equal(list[0].tulu, 'ರಾಜೆ');
  assert.equal(list[0].cat, 'words');
  assert.equal(list[0].note.length, 300);

  const del = await worker.fetch(admin('DELETE', 'pw', `?key=${encodeURIComponent(list[0].key)}`), e);
  assert.equal(del.status, 200);
  assert.equal((await (await worker.fetch(admin('GET', 'pw'), e)).json()).length, 0);
});

test('suggestions need KV and an admin password to be enabled', async () => {
  assert.equal((await worker.fetch(suggest({ tulu: 'ರಾಜೆ', en: 'king' }), env)).status, 503);
  const e = { ...env, SUGGEST_KV: memKv() };
  assert.equal((await worker.fetch(admin('GET', 'undefined'), e)).status, 401);
  const page = await worker.fetch(new Request('https://w.example/admin'), e);
  assert.match(await page.text(), /Word suggestions/);
});

test('suggestions are rate limited per day', async () => {
  const e = { ...env, SUGGEST_KV: memKv() };
  let last;
  for (let i = 0; i < 31; i++) last = await worker.fetch(suggest({ tulu: 'ರಾಜೆ', en: 'king' }), e);
  assert.equal(last.status, 429);
});
