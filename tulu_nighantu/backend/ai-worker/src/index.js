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
//   SUGGEST_KV      (optional KV binding that stores word suggestions)
//   ADMIN_TOKEN     (secret; password for the /admin review page)

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


// ---------------------------------------------------------------------------
// Word suggestions from app users ("Send to the dictionary").

const MAX_FIELD = 120;
const SUGGEST_DAILY_LIMIT = 30;
const KANNADA = /[ಀ-೿]/;

/** Validates and cleans a suggestion; returns null when invalid. */
export function cleanSuggestion(b) {
  const f = (k, n = MAX_FIELD) => clip(typeof b?.[k] === 'string' ? b[k].trim() : '', n);
  const s = {
    tulu: f('tulu', 60),
    roman: f('roman', 60),
    kn: f('kn'),
    en: f('en'),
    cat: f('cat', 20) || 'words',
    note: f('note', 300),
  };
  if (!s.tulu || !KANNADA.test(s.tulu)) return null;
  if (!s.kn && !s.en) return null;
  return s;
}

async function handleSuggest(request, env) {
  if (!env.SUGGEST_KV) return error(503, 'Suggestions are not set up yet.');
  let body;
  try {
    body = await request.json();
  } catch {
    return error(400, 'Invalid JSON');
  }
  const s = cleanSuggestion(body);
  if (!s) return error(400, 'Tulu word (Kannada script) and a meaning are required.');
  const ip = request.headers.get('cf-connecting-ip') || 'unknown';
  const day = new Date().toISOString().slice(0, 10);
  const rlKey = `rl:s:${day}:${ip}`;
  const used = Number((await env.SUGGEST_KV.get(rlKey)) || 0);
  if (used >= SUGGEST_DAILY_LIMIT) {
    return error(429, 'Too many suggestions today. Try again tomorrow.');
  }
  await env.SUGGEST_KV.put(rlKey, String(used + 1), { expirationTtl: 60 * 60 * 26 });
  const at = new Date().toISOString();
  const key = `s:${at}:${crypto.randomUUID().slice(0, 8)}`;
  await env.SUGGEST_KV.put(key, JSON.stringify({ ...s, at }));
  return json({ ok: true });
}

function isAdmin(request, env) {
  const auth = request.headers.get('authorization') || '';
  return Boolean(env.ADMIN_TOKEN) && auth === `Bearer ${env.ADMIN_TOKEN}`;
}

async function listSuggestions(env) {
  const out = [];
  let cursor;
  do {
    const page = await env.SUGGEST_KV.list({ prefix: 's:', cursor });
    for (const k of page.keys) {
      const v = await env.SUGGEST_KV.get(k.name);
      if (v) out.push({ key: k.name, ...JSON.parse(v) });
    }
    cursor = page.list_complete ? undefined : page.cursor;
  } while (cursor);
  return out;
}

async function handleAdminApi(request, env, url) {
  if (!env.SUGGEST_KV) return error(503, 'Suggestions are not set up yet.');
  if (!isAdmin(request, env)) return error(401, 'Wrong password');
  if (request.method === 'GET') return json(await listSuggestions(env));
  if (request.method === 'DELETE') {
    const key = url.searchParams.get('key') || '';
    if (!key.startsWith('s:')) return error(400, 'Bad key');
    await env.SUGGEST_KV.delete(key);
    return json({ ok: true });
  }
  return error(405, 'Method not allowed');
}

export const ADMIN_PAGE = `<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Tulu Nighantu – suggestions</title>
<style>
body{font-family:system-ui,sans-serif;margin:0;background:#fff8f6;color:#231917}
header{background:#b3261e;color:#fff;padding:16px}h1{font-size:20px;margin:0}
main{padding:16px;max-width:720px;margin:auto}
input,button{font-size:16px;padding:10px;border-radius:10px;border:1px solid #ccc}
button{background:#b3261e;color:#fff;border:0}button.alt{background:#eee;color:#231917}
.card{background:#fff;border-radius:14px;padding:12px;margin:10px 0;box-shadow:0 1px 3px #0002}
.t{font-size:22px;font-weight:700}.m{color:#555}.row{display:flex;gap:8px;flex-wrap:wrap;margin-top:8px}
textarea{width:100%;height:160px;font-family:monospace}
</style></head><body><header><h1>ತುಳು ನಿಘಂಟು · Word suggestions</h1></header><main>
<div id="login" class="row"><input id="pw" type="password" placeholder="Admin password">
<button onclick="load()">Open</button></div><p id="msg" class="m"></p><div id="list"></div>
<div id="exp" hidden><h3>Approved words (words.json format)</h3>
<p class="m">Tap “Approve” on good words, then copy this and send it to be added to the app.</p>
<textarea id="out" readonly></textarea><div class="row">
<button onclick="navigator.clipboard.writeText(out.value)">Copy</button></div></div>
</main><script>
let items=[],ok=[];const pw=()=>document.getElementById('pw').value;
const h=()=>({authorization:'Bearer '+pw()});
const esc=s=>String(s||'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
async function load(){const r=await fetch('/admin/api',{headers:h()});
if(!r.ok){msg.textContent=(await r.json()).error.message;return}
items=await r.json();msg.textContent=items.length+' suggestion(s)';draw()}
function draw(){list.innerHTML=items.map((s,i)=>'<div class=card><div class=t>'+esc(s.tulu)+'</div>'+
'<div>'+esc(s.roman)+' · '+esc(s.en)+' · '+esc(s.kn)+'</div><div class=m>'+esc(s.cat)+' · '+esc(s.at)+
(s.note?'<br>Note: '+esc(s.note):'')+'</div><div class=row><button onclick="ap('+i+')">Approve</button>'+
'<button class=alt onclick="del('+i+')">Delete</button></div></div>').join('');
exp.hidden=!ok.length;out.value=JSON.stringify(ok,null,2)}
async function del(i){const s=items[i];await fetch('/admin/api?key='+encodeURIComponent(s.key),{method:'DELETE',headers:h()});
items.splice(i,1);draw()}
async function ap(i){const s=items[i];ok.push({tulu:s.tulu,roman:s.roman,kn:s.kn,en:s.en,cat:s.cat});await del(i)}
</script></body></html>`;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === 'GET' && url.pathname === '/') {
      return json({ ok: true, service: 'tulu-nighantu-ai' });
    }
    if (request.method === 'GET' && url.pathname === '/admin') {
      return new Response(ADMIN_PAGE, {
        headers: { 'content-type': 'text/html; charset=utf-8' },
      });
    }
    if (url.pathname === '/admin/api') return handleAdminApi(request, env, url);
    if (request.method === 'POST' && url.pathname === '/suggest') {
      return handleSuggest(request, env);
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
