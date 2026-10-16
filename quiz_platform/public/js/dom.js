// Minimal DOM helpers. All text goes through textContent, never innerHTML,
// so user- or admin-supplied strings cannot inject markup (XSS-safe).
export function h(tag, attrs = {}, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs ?? {})) {
    if (v === undefined || v === null || v === false) continue;
    if (k === 'class') el.className = v;
    else if (k.startsWith('on') && typeof v === 'function') el.addEventListener(k.slice(2), v);
    else if (k === 'dataset') Object.assign(el.dataset, v);
    else if (v === true) el.setAttribute(k, '');
    else el.setAttribute(k, String(v));
  }
  append(el, children);
  return el;
}

function append(el, children) {
  for (const c of children.flat(Infinity)) {
    if (c === null || c === undefined || c === false) continue;
    el.append(c instanceof Node ? c : document.createTextNode(String(c)));
  }
}

export function mount(root, ...children) {
  root.replaceChildren();
  append(root, children);
}

export function fmtMs(ms) {
  if (ms === null || ms === undefined) return '—';
  return `${Number(ms).toLocaleString('en-IN')} ms`;
}

export function fmtDuration(ms) {
  if (ms <= 0) return '00:00';
  const s = Math.floor(ms / 1000);
  const d = Math.floor(s / 86400);
  const hh = Math.floor((s % 86400) / 3600);
  const mm = Math.floor((s % 3600) / 60);
  const ss = s % 60;
  const pad = (n) => String(n).padStart(2, '0');
  if (d > 0) return `${d}d ${pad(hh)}:${pad(mm)}:${pad(ss)}`;
  if (hh > 0) return `${pad(hh)}:${pad(mm)}:${pad(ss)}`;
  return `${pad(mm)}:${pad(ss)}`;
}
