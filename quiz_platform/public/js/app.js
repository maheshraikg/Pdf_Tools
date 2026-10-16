// Participant Progressive Web App.
import { api, ApiError, addTimeSample, isSynced, monoNow, serverNow, syncClock } from './api.js';
import { fmtDuration, fmtMs, h, mount } from './dom.js';
import { fmtDateTime, fmtNumber, getLang, setLang, t } from './i18n.js';

const root = document.getElementById('app');
const banner = document.getElementById('net-banner');
let me = null;
let cleanup = []; // functions to run when leaving the current view

// ---------------------------------------------------------------------------
// Realtime connection (WebSocket with automatic reconnect + backoff)
// ---------------------------------------------------------------------------
class Realtime {
  constructor() {
    this.ws = null;
    this.handlers = new Set();
    this.subs = new Set();
    this.attempt = 0;
    this.connected = false;
    this.statusListeners = new Set();
  }

  ensure() {
    if (this.ws && this.ws.readyState <= 1) return;
    const proto = location.protocol === 'https:' ? 'wss' : 'ws';
    const ws = new WebSocket(`${proto}://${location.host}/api/ws`);
    this.ws = ws;
    ws.onopen = () => {
      this.attempt = 0;
      this.setConnected(true);
      for (const id of this.subs) ws.send(JSON.stringify({ type: 'subscribe', competitionId: id }));
      this.ping();
    };
    ws.onmessage = (ev) => {
      let msg;
      try { msg = JSON.parse(ev.data); } catch { return; }
      if (msg.type === 'time' && this.pingT0) {
        addTimeSample(this.pingT0, msg.serverNow, monoNow());
        this.pingT0 = null;
        return;
      }
      for (const fn of this.handlers) fn(msg);
    };
    ws.onclose = (ev) => {
      this.setConnected(false);
      if (ev.code === 4001 || ev.code === 4003) return; // unauthorised / suspended
      const delay = Math.min(15_000, 500 * 2 ** this.attempt) * (0.5 + Math.random());
      this.attempt += 1;
      setTimeout(() => { if (this.subs.size) this.ensure(); }, delay);
    };
  }

  ping() {
    if (this.ws?.readyState !== 1) return;
    this.pingT0 = monoNow();
    this.ws.send(JSON.stringify({ type: 'time', t0: this.pingT0 }));
  }

  setConnected(v) {
    this.connected = v;
    for (const fn of this.statusListeners) fn(v);
  }

  subscribe(id, handler) {
    this.subs.add(id);
    this.handlers.add(handler);
    this.ensure();
    if (this.ws?.readyState === 1) this.ws.send(JSON.stringify({ type: 'subscribe', competitionId: id }));
    return () => {
      this.handlers.delete(handler);
      this.subs.delete(id);
      if (this.ws?.readyState === 1) this.ws.send(JSON.stringify({ type: 'unsubscribe', competitionId: id }));
    };
  }
}
const rt = new Realtime();
setInterval(() => rt.ping(), 30_000);

// ---------------------------------------------------------------------------
// Shell
// ---------------------------------------------------------------------------
function header(title, { backTo } = {}) {
  return h('header', { class: 'topbar' },
    backTo ? h('a', { href: backTo, class: 'icon-btn', 'aria-label': t('back') }, '←') : h('span', { class: 'logo', 'aria-hidden': 'true' }, 'Q'),
    h('h1', {}, title),
    me ? h('a', { href: '#/profile', class: 'icon-btn avatar', 'aria-label': t('profile') }, (me.displayName ?? '?').trim().charAt(0).toUpperCase()) : langToggle(),
  );
}

function langToggle() {
  return h('button', {
    class: 'icon-btn lang', type: 'button', 'aria-label': t('language'),
    onclick: () => { setLang(getLang() === 'en' ? 'kn' : 'en'); route(); },
  }, getLang() === 'en' ? 'ಕ' : 'EN');
}

function spinner() {
  return h('div', { class: 'center', role: 'status' }, h('div', { class: 'spinner', 'aria-hidden': 'true' }), h('p', {}, t('loading')));
}

function errorBox(err, onRetry) {
  return h('div', { class: 'card error', role: 'alert' },
    h('p', {}, err.message ?? String(err)),
    onRetry ? h('button', { class: 'btn', type: 'button', onclick: onRetry }, t('retry')) : null);
}

function statusChip(status) {
  return h('span', { class: `chip chip-${status}` }, t(`status_${status}`));
}

function applyBranding(branding) {
  const color = branding?.primaryColor;
  if (color) document.documentElement.style.setProperty('--brand', color);
  else document.documentElement.style.removeProperty('--brand');
}

window.addEventListener('online', () => banner.hidden = true);
window.addEventListener('offline', () => { banner.textContent = t('offline'); banner.hidden = false; });

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------
async function route() {
  for (const fn of cleanup) { try { fn(); } catch { /* ignore */ } }
  cleanup = [];
  applyBranding(null);
  const hash = location.hash.replace(/^#/, '') || '/';
  const parts = hash.split('/').filter(Boolean);
  document.title = t('appName');

  if (!me) {
    mount(root, spinner());
    try {
      const r = await api('GET', '/api/me');
      me = r.user;
      if (me.preferredLang && me.preferredLang !== getLang()) setLang(me.preferredLang);
    } catch (err) {
      if (err.status !== 401) { mount(root, header(t('appName')), errorBox(err, route)); return; }
    }
  }
  if (!me) return loginView();
  if (!me.displayName) return profileSetupView();

  if (parts[0] === 'c' && parts[1]) {
    if (parts[2] === 'play') return playView(parts[1]);
    if (parts[2] === 'result') return resultView(parts[1]);
    if (parts[2] === 'leaderboard') return leaderboardView(parts[1]);
    return competitionView(parts[1]);
  }
  if (parts[0] === 'profile') return profileView();
  return dashboardView();
}
window.addEventListener('hashchange', route);

// ---------------------------------------------------------------------------
// Login (mobile + OTP)
// ---------------------------------------------------------------------------
function loginView() {
  let challenge = null;
  let resendAt = 0;
  const msg = h('p', { class: 'msg', role: 'alert', 'aria-live': 'assertive' });
  const phone = h('input', { id: 'phone', type: 'tel', inputmode: 'tel', autocomplete: 'tel', required: true, maxlength: 16, placeholder: '98765 43210' });
  const otp = h('input', { id: 'otp', type: 'text', inputmode: 'numeric', autocomplete: 'one-time-code', pattern: '[0-9]{6}', maxlength: 6, required: true });
  const resendBtn = h('button', { class: 'btn link', type: 'button', disabled: true }, t('resend'));
  const container = h('div');

  const phoneForm = h('form', { class: 'card stack' },
    h('h2', {}, t('loginTitle')),
    h('p', { class: 'muted' }, t('loginHint')),
    h('label', { for: 'phone' }, t('mobileNumber')),
    h('div', { class: 'phone-row' }, h('span', { class: 'cc' }, '+91'), phone),
    h('button', { class: 'btn primary block', type: 'submit' }, t('sendOtp')),
    h('p', { class: 'small muted' }, t('privacyNote')),
  );
  const sendOtp = async () => {
    msg.textContent = '';
    try {
      challenge = await api('POST', '/api/auth/otp/request', { phone: phone.value });
      resendAt = Date.now() + challenge.resendAfterMs;
      showOtp();
    } catch (err) { msg.textContent = err.message; }
  };
  phoneForm.addEventListener('submit', (e) => { e.preventDefault(); sendOtp(); });

  function showOtp() {
    const otpForm = h('form', { class: 'card stack' },
      h('h2', {}, t('otp')),
      h('p', {}, t('otpSentTo', { phone: challenge.maskedPhone })),
      h('label', { for: 'otp' }, t('otp')),
      otp,
      h('button', { class: 'btn primary block', type: 'submit' }, t('verify')),
      h('div', { class: 'row between' }, resendBtn,
        h('button', { class: 'btn link', type: 'button', onclick: () => { mount(container, phoneForm, msg); phone.focus(); } }, t('changeNumber'))),
    );
    otpForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      msg.textContent = '';
      try {
        const r = await api('POST', '/api/auth/otp/verify', { challengeId: challenge.challengeId, code: otp.value.trim() });
        me = r.user;
        if (me.preferredLang !== getLang()) await api('PATCH', '/api/me', { preferredLang: getLang() }).catch(() => {});
        route();
      } catch (err) {
        msg.textContent = err.details?.attemptsRemaining !== undefined ? `${err.message} (${err.details.attemptsRemaining})` : err.message;
        otp.select();
      }
    });
    resendBtn.onclick = sendOtp;
    mount(container, otpForm, msg);
    otp.value = '';
    otp.focus();
  }

  const iv = setInterval(() => {
    const left = Math.ceil((resendAt - Date.now()) / 1000);
    resendBtn.disabled = left > 0;
    resendBtn.textContent = left > 0 ? t('resendIn', { s: left }) : t('resend');
  }, 500);
  cleanup.push(() => clearInterval(iv));

  mount(container, phoneForm, msg);
  mount(root, header(t('appName')), h('main', { class: 'narrow' }, container));
  phone.focus();
}

function profileSetupView() {
  const name = h('input', { id: 'name', required: true, minlength: 2, maxlength: 60, autocomplete: 'name' });
  const msg = h('p', { class: 'msg', role: 'alert' });
  const form = h('form', { class: 'card stack' },
    h('h2', {}, t('completeProfile')),
    h('p', { class: 'muted' }, t('profileHint')),
    h('label', { for: 'name' }, t('yourName')), name,
    langSelect(),
    h('button', { class: 'btn primary block', type: 'submit' }, t('continue')));
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
      const r = await api('PATCH', '/api/me', { displayName: name.value, preferredLang: getLang() });
      me = r.user;
      route();
    } catch (err) { msg.textContent = err.message; }
  });
  mount(root, header(t('appName')), h('main', { class: 'narrow' }, form, msg));
  name.focus();
}

function langSelect() {
  const sel = h('select', { id: 'lang' },
    h('option', { value: 'en', selected: getLang() === 'en' }, 'English'),
    h('option', { value: 'kn', selected: getLang() === 'kn' }, 'ಕನ್ನಡ'));
  sel.addEventListener('change', async () => {
    setLang(sel.value);
    if (me?.displayName) await api('PATCH', '/api/me', { preferredLang: sel.value }).catch(() => {});
    route();
  });
  return h('div', { class: 'stack-sm' }, h('label', { for: 'lang' }, t('language')), sel);
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------
async function dashboardView() {
  const main = h('main', {}, spinner());
  mount(root, header(t('appName')), main);
  let data;
  let notes;
  try {
    syncClock(3);
    [data, notes] = await Promise.all([api('GET', '/api/competitions'), api('GET', '/api/me/notifications').catch(() => ({ notifications: [] }))]);
  } catch (err) { mount(main, errorBox(err, route)); return; }

  const countdowns = [];
  const cards = data.competitions.map((c) => {
    const cd = h('span', { class: 'countdown' });
    if (['scheduled', 'registration_open'].includes(c.status)) countdowns.push([cd, new Date(c.startAt).getTime()]);
    return h('a', { class: 'card comp-card', href: `#/c/${c.id}` },
      h('div', { class: 'row between' }, statusChip(c.status), c.registered ? h('span', { class: 'chip chip-ok' }, '✓ ' + t('registered')) : null),
      h('h3', {}, c.title),
      c.branding?.organization ? h('p', { class: 'muted small' }, c.branding.organization) : null,
      h('p', { class: 'small' }, `${t('startsAt')}: ${fmtDateTime(c.startAt)}`),
      cd,
      h('p', { class: 'small muted' }, `${t('participants')}: ${fmtNumber(c.participantCount ?? 0)} · ${t('format')}`));
  });
  const tick = () => { for (const [el, at] of countdowns) el.textContent = `${t('startsIn')} ${fmtDuration(at - serverNow())}`; };
  tick();
  const iv = setInterval(tick, 1000);
  cleanup.push(() => clearInterval(iv));

  const unread = notes.notifications.filter((n) => !n.read);
  mount(main,
    unread.length ? h('section', { class: 'card notes', 'aria-label': t('notifications') },
      h('div', { class: 'row between' }, h('h2', {}, `🔔 ${t('notifications')}`),
        h('button', { class: 'btn link', type: 'button', onclick: async (e) => { await api('POST', '/api/me/notifications/read'); e.target.closest('section').remove(); } }, '✓')),
      unread.slice(0, 5).map((n) => h('p', { class: 'small' }, n.body))) : null,
    h('h2', { class: 'section-title' }, t('competitions')),
    cards.length ? h('div', { class: 'grid' }, cards) : h('p', { class: 'card muted' }, t('noCompetitions')),
    h('p', {}, h('a', { href: '#/profile', class: 'btn block' }, t('myHistory'))));
}

// ---------------------------------------------------------------------------
// Competition lobby
// ---------------------------------------------------------------------------
async function competitionView(id) {
  const main = h('main', {}, spinner());
  mount(root, header(t('appName'), { backTo: '#/' }), main);
  let c;
  try {
    syncClock(3);
    c = (await api('GET', `/api/competitions/${id}`)).competition;
  } catch (err) { mount(main, errorBox(err, route)); return; }
  applyBranding(c.branding);
  document.title = c.title;

  const msg = h('p', { class: 'msg', role: 'alert' });
  const countdown = h('p', { class: 'big-countdown', 'aria-live': 'off' });
  const startMs = new Date(c.startAt).getTime();
  const tick = () => {
    const left = startMs - serverNow();
    countdown.textContent = left > 0 && ['scheduled', 'registration_open'].includes(c.status) ? `${t('startsIn')} ${fmtDuration(left)}` : '';
  };
  tick();
  const iv = setInterval(tick, 1000);
  cleanup.push(() => clearInterval(iv));

  const actions = h('div', { class: 'stack' });
  const renderActions = () => {
    const nodes = [];
    if (c.status === 'cancelled') nodes.push(h('p', { class: 'card error' }, t('cancelledReason', { reason: c.cancelledReason ?? '' })));
    else if (c.status === 'completed') {
      if (c.registered) nodes.push(h('a', { class: 'btn primary block', href: `#/c/${id}/result` }, t('viewResult')));
      nodes.push(h('a', { class: 'btn block', href: `#/c/${id}/leaderboard` }, t('viewLeaderboard')));
    } else if (c.registered) {
      nodes.push(h('p', { class: 'chip chip-ok' }, '✓ ' + t('registered')));
      nodes.push(h('a', { class: 'btn primary block big', href: `#/c/${id}/play` }, t('enterCompetition')));
      if (c.status === 'live' && c.showProvisional) nodes.push(h('a', { class: 'btn block', href: `#/c/${id}/leaderboard` }, t('viewLeaderboard')));
    } else if (c.registrationOpen) {
      const code = h('input', { id: 'code', maxlength: 64, autocomplete: 'off' });
      const form = h('form', { class: 'stack' },
        c.visibility === 'restricted' ? [h('p', { class: 'small' }, t('restrictedHint')), h('label', { for: 'code' }, t('accessCode')), code] : null,
        c.status === 'live' ? h('p', { class: 'small muted' }, t('lateEntryNote')) : null,
        h('button', { class: 'btn primary block big', type: 'submit' }, t('register')));
      form.addEventListener('submit', async (e) => {
        e.preventDefault();
        msg.textContent = '';
        try {
          await api('POST', `/api/competitions/${id}/register`, c.visibility === 'restricted' ? { accessCode: code.value } : {});
          c.registered = true;
          c.participantCount = (c.participantCount ?? 0) + 1;
          renderActions();
        } catch (err) { msg.textContent = err.message; }
      });
      nodes.push(form);
    } else {
      const opens = new Date(c.registrationOpensAt).getTime();
      nodes.push(h('p', { class: 'card muted' }, serverNow() < opens ? `${t('registrationOpens')}: ${fmtDateTime(opens)}` : t('registrationClosed')));
    }
    mount(actions, nodes);
  };
  renderActions();

  mount(main,
    h('section', { class: 'card stack' },
      h('div', { class: 'row between' }, statusChip(c.status), c.branding?.organization ? h('span', { class: 'muted small' }, c.branding.organization) : null),
      h('h2', {}, c.title),
      c.description ? h('p', { class: 'pre' }, c.description) : null,
      h('dl', { class: 'facts' },
        h('dt', {}, t('startsAt')), h('dd', {}, fmtDateTime(c.startAt)),
        h('dt', {}, t('registrationCloses')), h('dd', {}, fmtDateTime(c.registrationClosesAt)),
        h('dt', {}, t('participants')), h('dd', {}, fmtNumber(c.participantCount ?? 0)),
        h('dt', {}, t('formatLabel')), h('dd', {}, t('format'))),
      countdown, actions, msg),
    c.rules ? h('section', { class: 'card' }, h('h3', {}, t('rules')), h('p', { class: 'pre' }, c.rules)) : null);
}

// ---------------------------------------------------------------------------
// Live play
// ---------------------------------------------------------------------------
async function playView(id) {
  const conn = h('span', { class: 'conn', role: 'status' });
  const main = h('main', { class: 'play' }, spinner());
  mount(root, h('header', { class: 'topbar' }, h('a', { href: `#/c/${id}`, class: 'icon-btn', 'aria-label': t('back') }, '←'), h('h1', { id: 'play-title' }, t('appName')), conn), main);
  const setConn = (ok) => { conn.textContent = ok ? '●' : '○'; conn.title = ok ? t('connected') : t('reconnecting'); conn.className = `conn ${ok ? 'ok' : 'bad'}`; };
  rt.statusListeners.add(setConn);
  cleanup.push(() => rt.statusListeners.delete(setConn));
  setConn(rt.connected);

  await syncClock(isSynced() ? 2 : 5);

  // Local view model
  let st = null;
  let current = null; // public question currently open
  let answer = null; // { option, status: 'sending'|'locked'|'error', responseMs, message }
  const answered = new Set();
  const revealed = new Map();
  let raf = 0;
  let boundaryTimer = 0;
  let lastQuestionEventAt = 0;

  const els = {
    title: document.getElementById('play-title'),
    qnum: h('p', { class: 'qnum' }),
    dots: h('ol', { class: 'dots', 'aria-hidden': 'true' }),
    counts: h('p', { class: 'small muted counts' }),
    timer: h('div', { class: 'timer', role: 'timer', 'aria-hidden': 'true' }),
    timerSr: h('p', { class: 'sr-only', 'aria-live': 'polite' }),
    bar: h('div', { class: 'timebar' }, h('div', { class: 'timebar-fill' })),
    qtext: h('h2', { class: 'qtext' }),
    img: h('img', { class: 'qimg', alt: '', hidden: true, referrerpolicy: 'no-referrer' }),
    options: h('div', { class: 'options', role: 'group' }),
    status: h('p', { class: 'answer-status', role: 'status', 'aria-live': 'assertive' }),
    panel: h('section', { class: 'card stack center' }),
  };

  async function refresh() {
    try {
      st = await api('GET', `/api/competitions/${id}/state`);
    } catch (err) {
      if (err.status === 0) { scheduleRefresh(1000); return; }
      mount(main, errorBox(err, () => refresh()));
      return;
    }
    els.title.textContent = st.competition.title;
    applyBranding(st.competition.branding);
    for (const p of st.progress?.answeredPositions ?? []) answered.add(p);
    for (const r of st.revealed ?? []) revealed.set(r.position, r.correctOption);
    if (st.question) {
      if (current?.id !== st.question.id) {
        current = st.question;
        answer = st.myAnswer ? { option: st.myAnswer.selectedOption, status: 'locked', responseMs: st.myAnswer.responseMs } : null;
      } else if (st.myAnswer && (!answer || answer.status !== 'locked')) {
        answer = { option: st.myAnswer.selectedOption, status: 'locked', responseMs: st.myAnswer.responseMs };
      }
    } else {
      current = null;
    }
    render();
  }

  function scheduleRefresh(ms) {
    clearTimeout(boundaryTimer);
    boundaryTimer = setTimeout(refresh, ms);
  }

  // Safety net: if the push for a boundary does not arrive (WebSocket down),
  // fetch state shortly after the boundary. Jitter spreads the load.
  function armBoundary() {
    if (!st?.schedule || st.phase !== 'live' && st.phase !== 'scheduled' && st.phase !== 'registration_open') return;
    const now = serverNow();
    const { startAt, questionTimeMs, transitionMs, endsAt } = st.schedule;
    const slot = questionTimeMs + transitionMs;
    let next;
    if (now < startAt) next = startAt;
    else if (now > endsAt) next = now + 500;
    else {
      const idx = Math.floor((now - startAt) / slot);
      const opens = startAt + idx * slot;
      next = now <= opens + questionTimeMs ? opens + questionTimeMs + 1 : opens + slot;
    }
    const jitter = rt.connected ? 1500 + Math.random() * 1000 : 150 + Math.random() * 600;
    const delay = Math.min(next - now + jitter, 2 ** 31 - 1);
    clearTimeout(boundaryTimer);
    boundaryTimer = setTimeout(() => {
      // Only fetch if no push arrived for this boundary.
      if (performance.now() - lastQuestionEventAt > jitter) refresh(); else armBoundary();
    }, Math.max(50, delay));
  }

  const unsub = rt.subscribe(id, (msg) => {
    if (msg.competitionId && msg.competitionId !== id && msg.type !== 'question') return;
    if (msg.type === 'subscribed') { if (st) refresh(); return; }
    lastQuestionEventAt = performance.now();
    if (msg.type === 'question') {
      if (current?.id !== msg.question.id) { current = msg.question; answer = null; }
      if (st) { st.phase = 'live'; st.timeline = { phase: 'question', position: msg.question.position }; }
      render();
    } else if (msg.type === 'question_closed') {
      if (msg.correctOption) revealed.set(msg.position, msg.correctOption);
      if (st) st.timeline = { phase: 'transition', lastPosition: msg.position, nextOpensAt: msg.nextOpensAt };
      current = null;
      render();
    } else if (msg.type === 'competition_ended' || msg.type === 'results_computed') {
      if (st) st.phase = 'completed';
      current = null;
      render();
    } else if (msg.type === 'competition_cancelled') {
      refresh();
    }
  });
  cleanup.push(unsub);
  const onVis = () => { if (!document.hidden) { syncClock(2); refresh(); } };
  document.addEventListener('visibilitychange', onVis);
  cleanup.push(() => document.removeEventListener('visibilitychange', onVis));
  cleanup.push(() => { cancelAnimationFrame(raf); clearTimeout(boundaryTimer); });

  function renderDots(activePos) {
    const total = st?.competition?.questionCount ?? 15;
    const closed = activePos ? activePos - 1 : (st?.timeline?.lastPosition ?? (st?.phase === 'completed' ? total : 0));
    mount(els.dots, Array.from({ length: total }, (_, i) => {
      const p = i + 1;
      let cls = 'dot';
      if (answered.has(p)) cls += ' done';
      else if (p <= closed) cls += ' missed';
      if (p === activePos) cls += ' current';
      return h('li', { class: cls });
    }));
    const done = answered.size;
    els.counts.textContent = `${t('answered')}: ${done} · ${t('remaining')}: ${total - (activePos ? activePos - 1 : closed)}`;
  }

  function render() {
    cancelAnimationFrame(raf);
    if (!st) return;
    if (st.entryError) { mount(main, h('div', { class: 'card error' }, st.entryError.message)); return; }
    if (!st.registered) {
      mount(main, h('div', { class: 'card stack' }, h('p', {}, t('notRegistered')), h('a', { class: 'btn primary', href: `#/c/${id}` }, t('register'))));
      return;
    }
    if (st.phase === 'cancelled') {
      mount(main, h('div', { class: 'card error stack' }, h('p', {}, t('cancelledReason', { reason: st.competition.cancelledReason ?? '' })), h('a', { class: 'btn', href: '#/' }, t('backToDashboard'))));
      return;
    }
    if (st.phase === 'completed') {
      mount(main, h('div', { class: 'card stack center' }, h('p', { class: 'big' }, '🏁'), h('h2', {}, t('competitionOver')),
        h('a', { class: 'btn primary block', href: `#/c/${id}/result` }, t('viewResult'))));
      setTimeout(() => { if (location.hash === `#/c/${id}/play`) location.hash = `#/c/${id}/result`; }, 2500);
      return;
    }
    if (current) return renderQuestion();
    // Lobby or between questions
    const now = serverNow();
    const startAt = st.schedule.startAt;
    if (now < startAt) {
      const cd = h('p', { class: 'big-countdown' });
      mount(main, h('section', { class: 'card stack center' }, h('h2', {}, st.competition.title), h('p', {}, t('waitingStart')), cd, h('p', { class: 'small muted' }, t('format'))));
      const loop = () => { cd.textContent = fmtDuration(startAt - serverNow() + 999); raf = requestAnimationFrame(loop); };
      loop();
    } else {
      const lastPos = st.timeline?.lastPosition;
      const nextAt = st.timeline?.nextOpensAt;
      const cd = h('p', { class: 'muted' });
      const reveal = lastPos && revealed.get(lastPos) ? h('p', { class: 'chip chip-ok' }, t('correctWas', { opt: revealed.get(lastPos) })) : null;
      const mine = lastPos && answered.has(lastPos) ? t('submitted') : lastPos ? t('notAnswered') : '';
      renderDots(null);
      mount(main, els.dots, els.counts, h('section', { class: 'card stack center' }, h('p', { class: 'big' }, answered.has(lastPos) ? '✓' : '⏳'), h('p', {}, mine), reveal, cd));
      const loop = () => {
        if (nextAt) cd.textContent = t('nextQuestionIn', { s: Math.max(0, Math.ceil((nextAt - serverNow()) / 1000)) });
        raf = requestAnimationFrame(loop);
      };
      loop();
    }
    armBoundary();
  }

  function renderQuestion() {
    const q = current;
    els.qnum.textContent = t('questionXofY', { x: q.position, y: q.total });
    els.qtext.textContent = q.text;
    if (q.imageUrl) { els.img.src = q.imageUrl; els.img.hidden = false; } else { els.img.hidden = true; els.img.removeAttribute('src'); }
    renderDots(q.position);
    const buttons = ['A', 'B', 'C', 'D'].map((opt) => h('button', {
      class: 'option', type: 'button', dataset: { opt },
      'aria-pressed': answer?.option === opt ? 'true' : 'false',
      onclick: () => choose(opt),
    }, h('span', { class: 'opt-letter' }, opt), h('span', { class: 'opt-text' }, q.options[opt])));
    mount(els.options, buttons);
    mount(main, els.qnum, els.dots, els.counts, els.timer, els.bar, els.timerSr, h('section', { class: 'card qcard' }, els.qtext, els.img), els.options, els.status);
    updateAnswerUi();
    let lastSec = -1;
    const fill = els.bar.firstChild;
    const loop = () => {
      const left = q.closesAt - serverNow();
      if (left <= 0) {
        els.timer.textContent = '00.000';
        fill.style.transform = 'scaleX(0)';
        els.timer.classList.add('expired');
        if (!answer || answer.status === 'error') {
          answer = { ...(answer ?? {}), status: 'timeout' };
          updateAnswerUi();
        }
        armBoundary();
        return;
      }
      const secs = Math.floor(left / 1000);
      els.timer.textContent = `${String(secs).padStart(2, '0')}.${String(Math.floor(left % 1000)).padStart(3, '0')}`;
      els.timer.classList.toggle('warn', left <= 3000);
      fill.style.transform = `scaleX(${Math.min(1, left / q.durationMs)})`;
      if (secs !== lastSec) { lastSec = secs; if (secs <= 5 || secs % 5 === 0) els.timerSr.textContent = `${secs + 1} ${t('secondsLeft')}`; }
      raf = requestAnimationFrame(loop);
    };
    loop();
  }

  function updateAnswerUi() {
    const locked = answer && ['sending', 'locked', 'timeout'].includes(answer.status);
    for (const b of els.options.children) {
      const sel = answer?.option === b.dataset.opt;
      b.classList.toggle('selected', sel);
      b.setAttribute('aria-pressed', sel ? 'true' : 'false');
      b.disabled = Boolean(locked) || (current && serverNow() > current.closesAt);
    }
    els.status.className = 'answer-status';
    if (!answer) els.status.textContent = '';
    else if (answer.status === 'sending') els.status.textContent = t('submitting');
    else if (answer.status === 'locked') {
      els.status.textContent = answer.responseMs !== undefined ? t('submittedIn', { t: (answer.responseMs / 1000).toFixed(3) }) : t('submitted');
      els.status.classList.add('ok');
    } else if (answer.status === 'timeout') { els.status.textContent = answer.option && answer.message ? answer.message : t('timeUp'); els.status.classList.add('bad'); }
    else if (answer.status === 'error') { els.status.textContent = t('answerFailed', { msg: answer.message }); els.status.classList.add('bad'); }
  }

  async function choose(opt) {
    const q = current;
    if (!q || (answer && answer.status !== 'error') || serverNow() > q.closesAt) return;
    const key = answer?.key ?? (crypto.randomUUID?.() ?? `${Date.now()}-${Math.random()}`);
    answer = { option: opt, status: 'sending', key };
    updateAnswerUi();
    if (navigator.vibrate) navigator.vibrate(15);
    // Retry transient network failures with the same idempotency key until the deadline.
    for (;;) {
      try {
        const r = await api('POST', `/api/competitions/${id}/answers`, { questionId: q.id, option: opt, idempotencyKey: key }, { timeoutMs: 6000 });
        if (current?.id === q.id) { answer = { option: r.selectedOption, status: 'locked', responseMs: r.responseMs, key }; updateAnswerUi(); }
        answered.add(q.position);
        renderDots(current?.id === q.id ? q.position : null);
        return;
      } catch (err) {
        if (err instanceof ApiError && err.status === 0 && serverNow() < q.closesAt + 2000) {
          await new Promise((r) => setTimeout(r, 400));
          continue;
        }
        if (current?.id !== q.id) return;
        if (err.code === 'already_answered') {
          answer = { option: err.details?.selectedOption, status: 'locked', key };
          answered.add(q.position);
        } else if (err.code === 'deadline_passed') {
          answer = { option: opt, status: 'timeout', key, message: t('timeUp') };
        } else {
          answer = { option: opt, status: serverNow() < q.closesAt ? 'error' : 'timeout', message: err.message, key };
        }
        updateAnswerUi();
        return;
      }
    }
  }

  await refresh();
}

// ---------------------------------------------------------------------------
// Result
// ---------------------------------------------------------------------------
async function resultView(id) {
  const main = h('main', {}, spinner());
  mount(root, header(t('yourResult'), { backTo: `#/c/${id}` }), main);
  let r;
  try { r = await api('GET', `/api/competitions/${id}/my-result`); } catch (err) { mount(main, errorBox(err, route)); return; }
  if (!r.final) {
    mount(main, h('div', { class: 'card stack center' }, h('div', { class: 'spinner' }), h('p', {}, t('resultsProcessing'))));
    const iv = setTimeout(route, 4000);
    cleanup.push(() => clearTimeout(iv));
    return;
  }
  const stat = (label, value, cls = '') => h('div', { class: `stat ${cls}` }, h('div', { class: 'stat-value' }, value), h('div', { class: 'stat-label' }, label));
  mount(main,
    h('section', { class: 'card stack' },
      h('h2', {}, r.title),
      h('div', { class: 'score-big' }, h('span', {}, String(r.totalMarks)), h('span', { class: 'muted' }, ` / ${r.maxMarks}`)),
      r.resultsPublished && r.rank ? h('p', { class: 'rank-big' }, `🏆 ${t('rank')}: ${t('rankOf', { rank: r.rank, n: r.rankedCount })}`) : h('p', { class: 'muted' }, t('rankPending')),
      h('div', { class: 'stats' },
        stat(t('correct'), r.correct, 'ok'), stat(t('incorrect'), r.incorrect, 'bad'), stat(t('unanswered'), r.unanswered),
        stat(t('correctTime'), fmtMs(r.correctTimeMs)), stat(t('totalTime'), fmtMs(r.totalTimeMs))),
      h('div', { class: 'row wrap' },
        r.resultsPublished ? h('a', { class: 'btn primary', href: `#/c/${id}/leaderboard` }, t('viewLeaderboard')) : null,
        h('a', { class: 'btn', href: '#/' }, t('backToDashboard')))),
    h('section', { class: 'card' },
      h('h3', {}, t('questionBreakdown')),
      h('ol', { class: 'breakdown' }, r.questions.map((q) => h('li', { class: q.isCorrect ? 'ok' : q.status === 'timeout' ? 'none' : 'bad' },
        h('p', {}, q.text),
        h('p', { class: 'small' },
          `${t('yourAnswer')}: ${q.selectedOption ? `${q.selectedOption}. ${q.options[q.selectedOption]}` : t('notAnswered')}`,
          q.responseMs !== null ? ` · ${fmtMs(q.responseMs)}` : ''),
        !q.isCorrect ? h('p', { class: 'small muted' }, t('correctWas', { opt: `${q.correctOption}. ${q.options[q.correctOption]}` })) : null)))));
}

// ---------------------------------------------------------------------------
// Leaderboard
// ---------------------------------------------------------------------------
async function leaderboardView(id) {
  const main = h('main', {});
  mount(root, header(t('leaderboard'), { backTo: `#/c/${id}` }), main);
  let view = { limit: 10, page: 1, q: '', paged: false };
  const search = h('input', { type: 'search', placeholder: t('search'), 'aria-label': t('search'), maxlength: 60 });
  const tabs = h('div', { class: 'tabs', role: 'tablist' });
  const body = h('div', {}, spinner());
  let debounce;
  search.addEventListener('input', () => {
    clearTimeout(debounce);
    debounce = setTimeout(() => { view = { ...view, q: search.value.trim(), page: 1 }; load(); }, 300);
  });
  const setTab = (limit, paged) => { view = { ...view, limit, paged, page: 1 }; load(); };
  const renderTabs = () => mount(tabs, [[10, t('top10')], [50, t('top50')], [100, t('top100')], [50, t('all'), true]].map(([limit, label, paged]) =>
    h('button', { type: 'button', role: 'tab', class: 'tab', 'aria-selected': view.limit === limit && view.paged === Boolean(paged) ? 'true' : 'false', onclick: () => setTab(limit, Boolean(paged)) }, label)));

  async function load() {
    renderTabs();
    mount(body, spinner());
    let r;
    try {
      const qs = new URLSearchParams({ limit: view.limit, page: view.page });
      if (view.q) qs.set('q', view.q);
      r = await api('GET', `/api/competitions/${id}/leaderboard?${qs}`);
    } catch (err) { mount(body, errorBox(err, load)); return; }
    const pages = Math.max(1, Math.ceil(r.total / r.pageSize));
    mount(body,
      h('p', { class: `chip ${r.provisional ? 'chip-warn' : 'chip-ok'}` }, r.provisional ? t('provisional') : t('official')),
      r.rows.length ? h('div', { class: 'table-wrap' }, h('table', { class: 'lb' },
        h('thead', {}, h('tr', {}, h('th', { scope: 'col' }, t('rank')), h('th', { scope: 'col' }, t('participant')), h('th', { scope: 'col' }, t('score')),
          h('th', { scope: 'col', class: 'hide-sm' }, `${t('correct')}/${t('incorrect')}/${t('unanswered')}`), h('th', { scope: 'col' }, t('correctTime')))),
        h('tbody', {}, r.rows.map((x) => h('tr', { class: x.registrationId === me.registrationId ? 'me' : '' },
          h('td', { class: 'rank' }, x.rank <= 3 ? ['🥇', '🥈', '🥉'][x.rank - 1] : String(x.rank)),
          h('td', {}, h('div', {}, x.displayName), h('div', { class: 'small muted' }, x.registrationId)),
          h('td', {}, `${x.totalMarks}/${x.maxMarks}`),
          h('td', { class: 'hide-sm' }, `${x.correct}/${x.incorrect}/${x.unanswered}`),
          h('td', { class: 'num' }, fmtMs(x.correctTimeMs))))))) : h('p', { class: 'muted' }, t('noResults')),
      view.paged && pages > 1 ? h('div', { class: 'row between' },
        h('button', { class: 'btn', type: 'button', disabled: view.page <= 1, onclick: () => { view.page -= 1; load(); } }, t('prev')),
        h('span', { class: 'small' }, t('page', { p: view.page, n: pages })),
        h('button', { class: 'btn', type: 'button', disabled: view.page >= pages, onclick: () => { view.page += 1; load(); } }, t('next'))) : null);
    if (r.provisional) {
      const tm = setTimeout(load, 5000);
      cleanup.push(() => clearTimeout(tm));
    }
  }
  mount(main, h('section', { class: 'card stack' }, search, tabs, body));
  load();
}

// ---------------------------------------------------------------------------
// Profile + history
// ---------------------------------------------------------------------------
async function profileView() {
  const main = h('main', {}, spinner());
  mount(root, header(t('profile'), { backTo: '#/' }), main);
  let hist;
  try { hist = await api('GET', '/api/me/history'); } catch (err) { mount(main, errorBox(err, route)); return; }
  const name = h('input', { id: 'name', value: me.displayName, minlength: 2, maxlength: 60 });
  const msg = h('p', { class: 'msg', role: 'status' });
  const form = h('form', { class: 'stack' }, h('label', { for: 'name' }, t('yourName')), name, h('button', { class: 'btn primary', type: 'submit' }, t('save')), msg);
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    try { me = (await api('PATCH', '/api/me', { displayName: name.value })).user; msg.textContent = '✓'; } catch (err) { msg.textContent = err.message; }
  });
  mount(main,
    h('section', { class: 'card stack' },
      h('dl', { class: 'facts' },
        h('dt', {}, t('registrationId')), h('dd', {}, me.registrationId),
        h('dt', {}, t('mobileNumber')), h('dd', {}, me.maskedPhone),
        h('dt', {}, t('memberSince')), h('dd', {}, fmtDateTime(me.registeredAt))),
      form, langSelect(),
      h('button', { class: 'btn danger', type: 'button', onclick: async () => { await api('POST', '/api/auth/logout').catch(() => {}); me = null; location.hash = '#/'; route(); } }, t('logout'))),
    h('section', { class: 'card' },
      h('h3', {}, t('myHistory')),
      hist.competitions.length ? h('ul', { class: 'history' }, hist.competitions.map((c) => h('li', {},
        h('a', { href: `#/c/${c.competitionId}${c.status === 'completed' ? '/result' : ''}` }, c.title),
        h('div', { class: 'small muted' }, `${fmtDateTime(c.startAt)} · `, statusChip(c.status),
          c.rank ? ` · ${t('rank')} ${c.rank}/${c.rankedCount} · ${t('score')} ${c.totalMarks}` : '')))) : h('p', { class: 'muted' }, t('noHistory'))));
}

// ---------------------------------------------------------------------------
if ('serviceWorker' in navigator && location.protocol === 'https:') {
  navigator.serviceWorker.register('/sw.js').catch(() => {});
}
route();
