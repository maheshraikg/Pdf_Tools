// Tulu Nighantu AI proxy (Cloudflare Worker).
//
// Holds the Gemini API key as a secret so the app never contains it, and only
// performs one job: translate short Kannada/English text into Tulu. The
// prompt is built here, so the endpoint cannot be used as a general AI proxy.
//
// Request:  POST /translate  {"text": "...", "glossary": [{tulu, roman, en, kn}]}
// Response: Gemini's generateContent response (status and body passed through).
//
// Secrets / vars (see README):
//   GEMINI_API_KEY  (secret, required)
//   GEMINI_MODEL    (var, default "gemini-flash-latest")
//   DAILY_LIMIT     (var, requests per client per day, default 60)
//   RATE_KV         (optional KV binding used for the daily limit)

export const MAX_TEXT = 300;
export const MAX_GLOSSARY = 20;

// Keep in sync with GeminiClient._system in lib/ai/gemini_client.dart.
export const SYSTEM_PROMPT =
  'You are a careful Tulu language assistant for a Tulu–Kannada–English ' +
  'dictionary app. Tulu must be written in Kannada script (never in ' +
  "Malayalam or Latin script). Translate the user's Kannada or English " +
  'text into natural Tulu (Tulunadu common dialect). Prefer the words in ' +
  'the provided verified glossary when they fit. Do not invent words: if ' +
  'you are unsure, give your best guess, say so in "notes" and set ' +
  'confidence to "low". Reply ONLY with JSON: {"tulu": string, "roman": ' +
  'string (simple romanisation), "english": string (English meaning of ' +
  'your Tulu), "kannada": string (Kannada meaning), "notes": string (one ' +
  'or two short sentences on usage or grammar), "confidence": "high" | ' +
  '"medium" | "low"}.';

const clip = (s, n) => String(s ?? '').slice(0, n);

/** Builds the user prompt (same format as GeminiClient.buildPrompt). */
export function buildPrompt(text, glossary) {
  let p = `Text to translate into Tulu: ${text.trim()}\n`;
  const g = (Array.isArray(glossary) ? glossary : []).slice(0, MAX_GLOSSARY);
  if (g.length) {
    p += 'Verified glossary (Tulu = English / Kannada):\n';
    for (const w of g) {
      p += `- ${clip(w.tulu, 60)} (${clip(w.roman, 60)}) = ` +
        `${clip(w.en, 80)} / ${clip(w.kn, 80)}\n`;
    }
  }
  return p;
}

const json = (obj, status = 200) =>
  new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });

const error = (status, message) => json({ error: { code: status, message } }, status);

/** Returns true when the client is still under today's limit. */
async function allow(env, request) {
  if (!env.RATE_KV) return true;
  const limit = Number(env.DAILY_LIMIT || 60);
  const ip = request.headers.get('cf-connecting-ip') || 'unknown';
  const day = new Date().toISOString().slice(0, 10);
  const key = `rl:${day}:${ip}`;
  const used = Number((await env.RATE_KV.get(key)) || 0);
  if (used >= limit) return false;
  await env.RATE_KV.put(key, String(used + 1), { expirationTtl: 60 * 60 * 26 });
  return true;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === 'GET' && url.pathname === '/') {
      return json({ ok: true, service: 'tulu-nighantu-ai' });
    }
    if (request.method !== 'POST' || url.pathname !== '/translate') {
      return error(404, 'Not found');
    }
    if (!env.GEMINI_API_KEY) return error(500, 'Server has no Gemini key');
    if (Number(request.headers.get('content-length') || 0) > 16384) {
      return error(413, 'Request too large');
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return error(400, 'Invalid JSON');
    }
    const text = typeof body?.text === 'string' ? body.text.trim() : '';
    if (!text) return error(400, 'Missing text');
    if (text.length > MAX_TEXT) return error(400, `Text longer than ${MAX_TEXT}`);

    if (!(await allow(env, request))) {
      return error(429, 'Daily AI limit reached. Try again tomorrow.');
    }

    const model = env.GEMINI_MODEL || 'gemini-flash-latest';
    const upstream = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
      {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-goog-api-key': env.GEMINI_API_KEY,
        },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
          contents: [{ role: 'user', parts: [{ text: buildPrompt(text, body.glossary) }] }],
          generationConfig: { temperature: 0.2, responseMimeType: 'application/json' },
        }),
      },
    );
    // Never leak upstream key errors verbatim; map auth failures to 502.
    if (upstream.status === 400 || upstream.status === 401 || upstream.status === 403) {
      return error(502, 'AI server is misconfigured. Please try again later.');
    }
    return new Response(await upstream.text(), {
      status: upstream.status,
      headers: { 'content-type': 'application/json; charset=utf-8' },
    });
  },
};
