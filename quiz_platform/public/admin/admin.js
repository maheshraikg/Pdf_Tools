// Administrator dashboard (role-based; the server enforces every permission).
import { api } from '../js/api.js';
import { fmtDuration, fmtMs, h, mount } from '../js/dom.js';

const root = document.getElementById('app');
let admin = null;
let timers = [];
const can = (perm) => admin?.permissions?.includes(perm);
const fmt = (d) => (d ? new Date(d).toLocaleString() : '—');
const STATUS_LABEL = {
  draft: 'Draft', scheduled: 'Scheduled', registration_open: 'Registration open', live: 'Live', completed: 'Completed', cancelled: 'Cancelled',
};

function toLocalInput(d) {
  if (!d) return '';
  const x = new Date(d);
  const pad = (n) => String(n).padStart(2, '0');
  return `${x.getFullYear()}-${pad(x.getMonth() + 1)}-${pad(x.getDate())}T${pad(x.getHours())}:${pad(x.getMinutes())}`;
}
const fromLocalInput = (v) => (v ? new Date(v).toISOString() : undefined);

function shell(active, ...content) {
  const link = (href, label, key) => h('a', { href, class: active === key ? 'active' : '' }, label);
  mount(root,
    h('header', { class: 'topbar' }, h('span', { class: 'logo' }, 'Q'), h('h1', {}, 'Quiz Admin'),
      h('span', { class: 'small' }, `${admin.name} · ${admin.role.replace('_', ' ')}`),
      h('button', { class: 'icon-btn', type: 'button', title: 'Log out', 'aria-label': 'Log out', onclick: logout }, '⎋')),
    h('nav', { class: 'admin-nav', 'aria-label': 'Admin sections' },
      link('#/', 'Competitions', 'comps'),
      link('#/users', 'Participants', 'users'),
      can('audit.read') ? link('#/audit', 'Audit log', 'audit') : null,
      link('#/health', 'System health', 'health'),
      can('admins.manage') ? link('#/admins', 'Administrators', 'admins') : null),
    h('main', {}, ...content));
}

async function logout() {
  await api('POST', '/api/admin/auth/logout').catch(() => {});
  admin = null;
  location.hash = '#/login';
  route();
}

function errorCard(err) { return h('div', { class: 'card error', role: 'alert' }, err.message); }
function chip(status) { return h('span', { class: `chip chip-${status}` }, STATUS_LABEL[status] ?? status); }

async function route() {
  for (const t of timers) clearInterval(t);
  timers = [];
  if (!admin) {
    try { admin = (await api('GET', '/api/admin/me')).admin; } catch { admin = null; }
  }
  if (!admin) return loginView();
  const parts = location.hash.replace(/^#\/?/, '').split('/').filter(Boolean);
  if (parts[0] === 'new') return editView(null);
  if (parts[0] === 'c' && parts[1]) return competitionView(parts[1], parts[2] ?? 'overview');
  if (parts[0] === 'users') return usersView();
  if (parts[0] === 'audit') return auditView();
  if (parts[0] === 'health') return healthView();
  if (parts[0] === 'admins') return adminsView();
  return listView();
}
window.addEventListener('hashchange', route);

// ---------------------------------------------------------------------------
function loginView() {
  const email = h('input', { id: 'email', type: 'email', autocomplete: 'username', required: true });
  const password = h('input', { id: 'password', type: 'password', autocomplete: 'current-password', required: true });
  const msg = h('p', { class: 'msg', role: 'alert' });
  const form = h('form', { class: 'card stack' }, h('h2', {}, 'Administrator login'),
    h('label', { for: 'email' }, 'Email'), email, h('label', { for: 'password' }, 'Password'), password,
    h('button', { class: 'btn primary block', type: 'submit' }, 'Log in'), msg);
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
      admin = (await api('POST', '/api/admin/auth/login', { email: email.value, password: password.value })).admin;
      location.hash = '#/';
      route();
    } catch (err) { msg.textContent = err.message; }
  });
  mount(root, h('header', { class: 'topbar' }, h('span', { class: 'logo' }, 'Q'), h('h1', {}, 'Quiz Admin')), h('main', { class: 'narrow' }, form));
  email.focus();
}

// ---------------------------------------------------------------------------
async function listView() {
  shell('comps', h('p', {}, 'Loading…'));
  let data;
  try { data = await api('GET', '/api/admin/competitions'); } catch (err) { shell('comps', errorCard(err)); return; }
  shell('comps',
    h('div', { class: 'row between' }, h('h2', {}, 'Competitions'), can('competitions.write') ? h('a', { class: 'btn primary', href: '#/new' }, '+ New competition') : null),
    h('div', { class: 'card table-wrap' }, h('table', { class: 'data' },
      h('thead', {}, h('tr', {}, ['Title', 'Code', 'Status', 'Starts', 'Questions', 'Participants', 'Results'].map((x) => h('th', {}, x)))),
      h('tbody', {}, data.competitions.length ? data.competitions.map((c) => h('tr', {},
        h('td', {}, h('a', { href: `#/c/${c.id}` }, c.title)),
        h('td', { class: 'mono' }, c.code),
        h('td', {}, chip(c.status)),
        h('td', {}, fmt(c.startAt)),
        h('td', { class: 'num' }, `${c.questionsReady}/15`),
        h('td', { class: 'num' }, c.participantCount),
        h('td', {}, c.resultsPublished ? 'Published' : c.resultsComputedAt ? 'Computed' : '—'))) : h('tr', {}, h('td', { colspan: 7, class: 'muted' }, 'No competitions yet.'))))));
}

// ---------------------------------------------------------------------------
async function editView(id, existing) {
  const c = existing ?? {
    title: '', description: '', rules: 'Each competition has 15 multiple-choice questions.\nYou get exactly 10 seconds per question.\nCorrect answer: +1 mark. Wrong or no answer: 0.\nTies are broken by the total time taken for correct answers (faster ranks higher).',
    startAt: new Date(Date.now() + 86400e3), registrationOpensAt: new Date(), registrationClosesAt: new Date(Date.now() + 86400e3),
    transitionMs: 3000, defaultMarks: 1, visibility: 'public', lateEntryAllowed: true, revealAnswers: false, showProvisional: false, notifySms: false, branding: {},
  };
  const f = {
    title: h('input', { id: 'f-title', value: c.title, required: true, maxlength: 200 }),
    description: h('textarea', { id: 'f-desc', maxlength: 10000 }, c.description),
    rules: h('textarea', { id: 'f-rules', maxlength: 10000 }, c.rules),
    startAt: h('input', { id: 'f-start', type: 'datetime-local', value: toLocalInput(c.startAt), required: true }),
    regOpen: h('input', { id: 'f-ro', type: 'datetime-local', value: toLocalInput(c.registrationOpensAt), required: true }),
    regClose: h('input', { id: 'f-rc', type: 'datetime-local', value: toLocalInput(c.registrationClosesAt), required: true }),
    transition: h('input', { id: 'f-tr', type: 'number', min: 1, max: 30, value: c.transitionMs / 1000 }),
    marks: h('input', { id: 'f-marks', type: 'number', min: 1, max: 100, value: c.defaultMarks }),
    visibility: h('select', { id: 'f-vis' }, h('option', { value: 'public', selected: c.visibility === 'public' }, 'Public'), h('option', { value: 'restricted', selected: c.visibility === 'restricted' }, 'Restricted (access code)')),
    accessCode: h('input', { id: 'f-code', maxlength: 64, placeholder: c.hasAccessCode ? '(unchanged)' : 'e.g. SCHOOL2026' }),
    late: h('input', { type: 'checkbox', checked: c.lateEntryAllowed }),
    reveal: h('input', { type: 'checkbox', checked: c.revealAnswers }),
    prov: h('input', { type: 'checkbox', checked: c.showProvisional }),
    sms: h('input', { type: 'checkbox', checked: c.notifySms }),
    org: h('input', { id: 'f-org', value: c.branding?.organization ?? '', maxlength: 120 }),
    color: h('input', { id: 'f-color', type: 'color', value: c.branding?.primaryColor ?? '#1d4ed8' }),
    logo: h('input', { id: 'f-logo', type: 'url', value: c.branding?.logoUrl ?? '', placeholder: 'https://…' }),
  };
  const msg = h('p', { class: 'msg', role: 'alert' });
  const field = (label, el, full) => h('div', { class: `stack-sm${full ? ' full' : ''}` }, h('label', { for: el.id }, label), el);
  const form = h('form', { class: 'card stack' },
    h('h2', {}, id ? 'Edit competition' : 'New competition'),
    h('p', { class: 'small muted' }, 'Every competition has exactly 15 questions with exactly 10 seconds each. Settings lock automatically when the competition starts.'),
    h('div', { class: 'form-grid' },
      field('Title', f.title, true), field('Description', f.description, true), field('Rules & instructions', f.rules, true),
      field('Start (your local time)', f.startAt), field('Pause between questions (seconds)', f.transition),
      field('Registration opens', f.regOpen), field('Registration closes', f.regClose),
      field('Default marks per correct answer', f.marks), field('Visibility', f.visibility),
      field('Access code (restricted only)', f.accessCode), field('Organisation / school name', f.org),
      field('Brand colour', f.color), field('Logo URL (https)', f.logo),
      h('label', { class: 'check full' }, f.late, 'Allow late entry (late joiners only get the remaining questions)'),
      h('label', { class: 'check full' }, f.reveal, 'Reveal the correct answer after each question closes'),
      h('label', { class: 'check full' }, f.prov, 'Show provisional (live) standings to participants'),
      h('label', { class: 'check full' }, f.sms, 'Send SMS notifications (in addition to in-app)')),
    h('div', { class: 'actions' }, h('button', { class: 'btn primary', type: 'submit' }, 'Save'), h('a', { class: 'btn', href: id ? `#/c/${id}` : '#/' }, 'Cancel')),
    msg);
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    msg.textContent = '';
    const body = {
      title: f.title.value, description: f.description.value, rules: f.rules.value,
      startAt: fromLocalInput(f.startAt.value), registrationOpensAt: fromLocalInput(f.regOpen.value), registrationClosesAt: fromLocalInput(f.regClose.value),
      transitionMs: Math.round(Number(f.transition.value) * 1000), defaultMarks: Number(f.marks.value), visibility: f.visibility.value,
      lateEntryAllowed: f.late.checked, revealAnswers: f.reveal.checked, showProvisional: f.prov.checked, notifySms: f.sms.checked,
      branding: { organization: f.org.value || undefined, primaryColor: f.color.value, logoUrl: f.logo.value || undefined },
    };
    if (f.accessCode.value) body.accessCode = f.accessCode.value;
    try {
      const r = id ? await api('PATCH', `/api/admin/competitions/${id}`, body) : await api('POST', '/api/admin/competitions', body);
      location.hash = `#/c/${r.competition.id}/questions`;
    } catch (err) { msg.textContent = err.message; }
  });
  shell('comps', form);
}

// ---------------------------------------------------------------------------
async function competitionView(id, tab) {
  shell('comps', h('p', {}, 'Loading…'));
  let data;
  try { data = await api('GET', `/api/admin/competitions/${id}`); } catch (err) { shell('comps', errorCard(err)); return; }
  const c = data.competition;
  if (tab === 'edit') return editView(id, c);
  const tabs = [['overview', 'Overview'], ['questions', 'Questions'], ['participants', 'Participants'], ['live', 'Live monitor'],
    ['leaderboard', 'Leaderboard'], ['report', 'Report & export'], can('users.suspend') ? ['suspicious', 'Suspicious activity'] : null].filter(Boolean);
  const body = h('div', { class: 'stack' });
  const msg = h('p', { class: 'msg', role: 'alert' });
  const act = async (label, path, payload, confirmText) => {
    if (confirmText && !confirm(confirmText)) return;
    msg.textContent = '';
    try { await api('POST', `/api/admin/competitions/${id}/${path}`, payload); route(); } catch (err) { msg.textContent = `${label}: ${err.message}`; }
  };
  const editable = c.storedStatus === 'draft' || (c.storedStatus === 'scheduled' && new Date(c.startAt) > new Date());
  const actions = h('div', { class: 'actions' },
    can('competitions.write') && editable ? h('a', { class: 'btn sm', href: `#/c/${id}/edit` }, 'Edit details') : null,
    can('competitions.write') && c.storedStatus === 'draft' ? h('button', { class: 'btn sm primary', type: 'button', onclick: () => act('Schedule', 'schedule', undefined, 'Schedule this competition? Participants will be able to register during the registration window.') }, 'Schedule') : null,
    can('competitions.write') && c.storedStatus === 'scheduled' && editable ? h('button', { class: 'btn sm', type: 'button', onclick: () => act('Unschedule', 'unschedule') }, 'Back to draft') : null,
    can('competitions.write') && ['draft', 'scheduled', 'live'].includes(c.storedStatus) ? h('button', {
      class: 'btn sm danger', type: 'button',
      onclick: () => { const reason = prompt('Reason for cancellation (sent to registered participants):'); if (reason) act('Cancel', 'cancel', { reason }); },
    }, 'Cancel competition') : null,
    can('results.publish') && c.storedStatus === 'completed' && !c.resultsPublished ? h('button', { class: 'btn sm primary', type: 'button', onclick: () => act('Publish', 'publish', undefined, 'Publish the official results? Participants will be notified. This cannot be undone.') }, 'Publish results') : null,
    can('competitions.write') && c.storedStatus === 'draft' ? h('button', {
      class: 'btn sm danger', type: 'button',
      onclick: async () => { if (!confirm('Delete this draft permanently?')) return; try { await api('DELETE', `/api/admin/competitions/${id}`); location.hash = '#/'; } catch (err) { msg.textContent = err.message; } },
    }, 'Delete draft') : null);

  shell('comps',
    h('section', { class: 'card stack' },
      h('div', { class: 'row between wrap' }, h('h2', {}, c.title), chip(c.status)),
      h('p', { class: 'small muted' }, `${c.code} · starts ${fmt(c.startAt)} · ends ${fmt(c.endsAt)} · ${c.participantCount} registered`),
      actions, msg),
    h('nav', { class: 'tabs', role: 'tablist' }, tabs.map(([k, label]) => h('a', { class: 'tab', role: 'tab', href: `#/c/${id}/${k}`, 'aria-selected': k === tab ? 'true' : 'false' }, label))),
    body);

  const views = { overview, questions, participants, live, leaderboard, report, suspicious };
  await (views[tab] ?? overview)();

  function overview() {
    mount(body, h('section', { class: 'card' }, h('dl', { class: 'facts' },
      ...[
        ['Status', STATUS_LABEL[c.status]], ['Start', fmt(c.startAt)], ['End (last deadline)', fmt(c.endsAt)],
        ['Registration', `${fmt(c.registrationOpensAt)} → ${fmt(c.registrationClosesAt)}`],
        ['Format', `${c.questionCount} questions × ${c.questionTimeMs / 1000} s, ${c.transitionMs / 1000} s between questions`],
        ['Questions ready', `${c.questionsReady}/15`], ['Default marks', c.defaultMarks], ['Visibility', c.visibility],
        ['Late entry', c.lateEntryAllowed ? 'Allowed' : 'Not allowed'], ['Reveal answers', c.revealAnswers ? 'Yes' : 'No'],
        ['Provisional standings', c.showProvisional ? 'Shown' : 'Hidden'], ['SMS notifications', c.notifySms ? 'On' : 'Off'],
        ['Frozen at', fmt(c.frozenAt)], ['Question-set hash', c.questionSetHash ?? '—'],
        ['Results computed', fmt(c.resultsComputedAt)], ['Results published', fmt(c.resultsPublishedAt)],
      ].flatMap(([k, v]) => [h('dt', {}, k), h('dd', { class: k.includes('hash') ? 'mono' : '' }, String(v))]))),
    c.rules ? h('section', { class: 'card' }, h('h3', {}, 'Rules'), h('p', { class: 'pre' }, c.rules)) : null);
  }

  function questions() {
    const qs = new Map(data.questions.map((q) => [q.position, q]));
    const locked = !(c.storedStatus === 'draft' || (c.storedStatus === 'scheduled' && new Date(c.startAt) > new Date())) || !can('competitions.write');
    const importBox = h('textarea', { placeholder: 'Paste CSV with header: position,text,optionA,optionB,optionC,optionD,correctOption,marks,category,imageUrl — or a JSON array of 15 questions', rows: 5 });
    const importMsg = h('p', { class: 'msg', role: 'alert' });
    const fileInput = h('input', { type: 'file', accept: '.csv,.json,text/csv,application/json' });
    fileInput.addEventListener('change', async () => { importBox.value = await fileInput.files[0].text(); });
    const doImport = async () => {
      importMsg.textContent = '';
      const text = importBox.value.trim();
      let payload;
      try { payload = text.startsWith('[') ? { questions: JSON.parse(text) } : { csv: text }; } catch (err) { importMsg.textContent = `Invalid JSON: ${err.message}`; return; }
      try { await api('POST', `/api/admin/competitions/${id}/questions/import`, payload); route(); } catch (err) { importMsg.textContent = err.message; }
    };
    const editors = Array.from({ length: 15 }, (_, i) => questionEditor(i + 1, qs.get(i + 1), locked));
    mount(body,
      !locked && c.storedStatus === 'draft' ? h('section', { class: 'card stack' }, h('h3', {}, 'Import all 15 questions'), fileInput, importBox,
        h('div', { class: 'actions' }, h('button', { class: 'btn primary sm', type: 'button', onclick: doImport }, 'Import (replaces all questions)')), importMsg) : null,
      locked ? h('p', { class: 'card muted' }, can('competitions.write') ? 'Questions are frozen: this competition has started or finished.' : 'Read-only access.') : null,
      editors);
  }

  function questionEditor(pos, q, locked) {
    const v = q ?? {};
    const text = h('textarea', { rows: 2, maxlength: 2000, disabled: locked }, v.text ?? '');
    const opts = ['A', 'B', 'C', 'D'].map((o) => h('input', { maxlength: 500, value: v[`option${o}`] ?? '', disabled: locked, 'aria-label': `Option ${o}` }));
    const correct = h('select', { disabled: locked, 'aria-label': 'Correct option' }, ['A', 'B', 'C', 'D'].map((o) => h('option', { value: o, selected: v.correctOption === o }, `Correct: ${o}`)));
    const marks = h('input', { type: 'number', min: 0, max: 100, value: v.marks ?? c.defaultMarks, disabled: locked, 'aria-label': 'Marks' });
    const category = h('input', { maxlength: 100, value: v.category ?? '', placeholder: 'Category (optional)', disabled: locked });
    const image = h('input', { type: 'url', value: v.imageUrl ?? '', placeholder: 'Image URL https:// (optional)', disabled: locked });
    const m = h('span', { class: 'small', role: 'status' });
    const save = async () => {
      m.textContent = '';
      try {
        await api('PUT', `/api/admin/competitions/${id}/questions/${pos}`, {
          text: text.value, optionA: opts[0].value, optionB: opts[1].value, optionC: opts[2].value, optionD: opts[3].value,
          correctOption: correct.value, marks: Number(marks.value), category: category.value || null, imageUrl: image.value || null,
        });
        m.textContent = '✓ saved';
        m.className = 'small ok-text';
      } catch (err) { m.textContent = err.message; m.className = 'small bad-text'; }
    };
    return h('section', { class: `q-editor${q ? '' : ' missing'}` },
      h('div', { class: 'row between' }, h('strong', {}, `Question ${pos}`), q ? null : h('span', { class: 'chip chip-warn' }, 'missing')),
      text, h('div', { class: 'opts' }, opts.map((o, i) => h('div', { class: 'row' }, h('span', { class: 'opt-letter' }, 'ABCD'[i]), o))),
      h('div', { class: 'row wrap' }, can('questions.read') || !q ? correct : h('span', { class: 'muted small' }, 'Answer key hidden for your role'), marks, category),
      image,
      locked ? null : h('div', { class: 'actions' }, h('button', { class: 'btn sm primary', type: 'button', onclick: save }, 'Save question'), m));
  }

  async function participants(q = '', page = 1) {
    const search = h('input', { type: 'search', placeholder: 'Search name or registration ID', value: q });
    const result = h('div', {}, 'Loading…');
    mount(body, h('section', { class: 'card stack' }, search, result));
    let deb;
    search.addEventListener('input', () => { clearTimeout(deb); deb = setTimeout(() => load(search.value, 1), 300); });
    const load = async (qq, pg) => {
      let r;
      try { r = await api('GET', `/api/admin/competitions/${id}/participants?${new URLSearchParams({ q: qq, page: pg, pageSize: 50 })}`); } catch (err) { mount(result, errorCard(err)); return; }
      const pages = Math.max(1, Math.ceil(r.total / 50));
      mount(result, h('p', { class: 'small muted' }, `${r.total} participants`),
        h('div', { class: 'table-wrap' }, h('table', { class: 'data' },
          h('thead', {}, h('tr', {}, ['Reg. ID', 'Name', 'Mobile', 'Status', 'Registered', 'Entered', 'Marks', 'Rank', ''].map((x) => h('th', {}, x)))),
          h('tbody', {}, r.rows.map((p) => h('tr', {},
            h('td', { class: 'mono' }, p.registrationId), h('td', {}, p.displayName ?? '—'), h('td', {}, p.maskedPhone),
            h('td', {}, p.status, p.accountStatus === 'suspended' ? h('span', { class: 'chip chip-cancelled' }, 'suspended') : null),
            h('td', {}, fmt(p.registeredAt)), h('td', {}, fmt(p.startedAt)),
            h('td', { class: 'num' }, p.totalMarks ?? '—'), h('td', { class: 'num' }, p.rank ?? '—'),
            h('td', {}, suspendButton(p.userId, p.accountStatus))))))),
        h('div', { class: 'row between' },
          h('button', { class: 'btn sm', type: 'button', disabled: pg <= 1, onclick: () => load(qq, pg - 1) }, 'Previous'),
          h('span', { class: 'small' }, `Page ${pg} / ${pages}`),
          h('button', { class: 'btn sm', type: 'button', disabled: pg >= pages, onclick: () => load(qq, pg + 1) }, 'Next')));
    };
    load(q, page);
  }

  async function live() {
    const box = h('div', { class: 'stack' }, 'Loading…');
    mount(body, box);
    const load = async () => {
      let s;
      try { s = await api('GET', `/api/admin/competitions/${id}/live`); } catch (err) { mount(box, errorCard(err)); return; }
      const kpi = (l, v) => h('div', { class: 'kpi' }, h('div', { class: 'v' }, String(v)), h('div', { class: 'l' }, l));
      const ph = s.phase;
      const phaseText = ph.phase === 'question' ? `Question ${ph.position} open — ${fmtDuration(ph.closesAt - Date.now())} left`
        : ph.phase === 'transition' ? `Between questions (next: Q${ph.nextPosition})`
          : ph.phase === 'before' ? `Starts in ${fmtDuration(ph.nextOpensAt - Date.now())}` : 'Ended';
      mount(box,
        h('p', { class: 'card' }, h('strong', {}, 'Phase: '), phaseText),
        h('div', { class: 'kpis' },
          kpi('Registered', s.registered), kpi('Entered', s.started), kpi('Connected (WebSocket)', s.connected),
          kpi('Active in last 30 s', s.activeLast30s), kpi('Answers / s (10 s avg)', s.submissions.perSecondLast10s.toFixed(1)),
          kpi('Answers last minute', s.submissions.perMinute), kpi('Total answers', s.submissions.total)),
        h('section', { class: 'card' }, h('h3', {}, 'Rejected submissions'),
          Object.keys(s.rejections).length ? h('ul', {}, Object.entries(s.rejections).map(([k, v]) => h('li', {}, `${k}: ${v}`))) : h('p', { class: 'muted' }, 'None')),
        h('p', { class: 'small muted' }, 'Refreshes every 2 seconds.'));
    };
    await load();
    timers.push(setInterval(load, 2000));
  }

  async function leaderboard() {
    const box = h('div', {}, 'Loading…');
    mount(body, h('section', { class: 'card stack' }, box));
    let r;
    try { r = await api('GET', `/api/admin/competitions/${id}/leaderboard?limit=100`); } catch (err) { mount(box, errorCard(err)); return; }
    mount(box, h('p', { class: `chip ${r.provisional ? 'chip-warn' : 'chip-ok'}` }, r.provisional ? 'Provisional (live) — not final' : r.official ? 'Official (published)' : 'Final, not yet published'),
      h('p', { class: 'small muted' }, `${r.total} ranked · showing top ${Math.min(100, r.total)}`),
      h('div', { class: 'table-wrap' }, h('table', { class: 'data' },
        h('thead', {}, h('tr', {}, ['Rank', 'Participant', 'Reg. ID', 'Score', 'C/I/U', 'Correct time', 'Total time'].map((x) => h('th', {}, x)))),
        h('tbody', {}, r.rows.map((x) => h('tr', {},
          h('td', { class: 'num' }, x.rank), h('td', {}, x.displayName), h('td', { class: 'mono' }, x.registrationId),
          h('td', { class: 'num' }, `${x.totalMarks}/${x.maxMarks}`), h('td', {}, `${x.correct}/${x.incorrect}/${x.unanswered}`),
          h('td', { class: 'num' }, fmtMs(x.correctTimeMs)), h('td', { class: 'num' }, fmtMs(x.totalTimeMs))))))));
    if (r.provisional) timers.push(setInterval(leaderboard, 5000));
  }

  async function report() {
    const box = h('div', { class: 'stack' }, 'Loading…');
    mount(body, box);
    let r;
    try { r = await api('GET', `/api/admin/competitions/${id}/report`); } catch (err) { mount(box, errorCard(err)); return; }
    const kpi = (l, v) => h('div', { class: 'kpi' }, h('div', { class: 'v' }, v === null || v === undefined ? '—' : String(v)), h('div', { class: 'l' }, l));
    const maxCount = Math.max(1, ...r.distribution.map((d) => d.count));
    const bars = r.distribution.map((d) => {
      const bar = h('div', { class: 'bar' });
      bar.style.width = `${(d.count / maxCount) * 100}%`;
      return h('div', { class: 'bar-row' }, h('span', {}, `${d.marks}`), bar, h('span', { class: 'num' }, String(d.count)));
    });
    const p = r.participants;
    mount(box,
      can('export') ? h('section', { class: 'card actions' },
        h('a', { class: 'btn sm primary', href: `/api/admin/competitions/${id}/export?format=csv` }, 'Download CSV'),
        h('a', { class: 'btn sm primary', href: `/api/admin/competitions/${id}/export?format=xlsx` }, 'Download Excel'),
        admin.role === 'super_admin' ? h('a', { class: 'btn sm', href: `/api/admin/competitions/${id}/export?format=xlsx&includePhone=true` }, 'Excel with full mobile numbers') : null) : null,
      h('div', { class: 'kpis' },
        kpi('Registered', p.registered), kpi('Started', p.started), kpi('Completed', p.completed), kpi('Did not finish', p.didNotFinish),
        kpi('Absent', p.absent), kpi('Average score', r.scores.avg?.toFixed(2)), kpi('Median score', r.scores.median), kpi('Highest score', r.scores.max),
        kpi('Avg response', fmtMs(r.responseTimes.avgMs)), kpi('p50 / p90 response', `${fmtMs(r.responseTimes.p50Ms === null ? null : Math.round(r.responseTimes.p50Ms))} / ${fmtMs(r.responseTimes.p90Ms === null ? null : Math.round(r.responseTimes.p90Ms))}`)),
      h('section', { class: 'card stack' }, h('h3', {}, 'Score distribution'), bars.length ? h('div', { class: 'bars' }, bars) : h('p', { class: 'muted' }, 'Available after the competition completes.')),
      h('section', { class: 'card table-wrap' }, h('h3', {}, 'Question analysis'), h('table', { class: 'data' },
        h('thead', {}, h('tr', {}, ['#', 'Question', 'Key', 'Correct', 'Incorrect', 'Unanswered', 'A/B/C/D picks', 'Avg time'].map((x) => h('th', {}, x)))),
        h('tbody', {}, r.questions.map((q) => h('tr', {},
          h('td', {}, q.position), h('td', {}, q.text), h('td', {}, q.correctOption), h('td', { class: 'num' }, q.correct),
          h('td', { class: 'num' }, q.incorrect), h('td', { class: 'num' }, q.unanswered),
          h('td', {}, `${q.picks.A}/${q.picks.B}/${q.picks.C}/${q.picks.D}`), h('td', { class: 'num' }, fmtMs(q.avgResponseMs))))))));
  }

  async function suspicious() {
    const box = h('div', { class: 'stack' }, 'Loading…');
    mount(body, box);
    let r;
    try { r = await api('GET', `/api/admin/competitions/${id}/suspicious`); } catch (err) { mount(box, errorCard(err)); return; }
    const table = (title, rows, cols) => h('section', { class: 'card table-wrap' }, h('h3', {}, title),
      rows.length ? h('table', { class: 'data' }, h('thead', {}, h('tr', {}, cols.map(([l]) => h('th', {}, l)))),
        h('tbody', {}, rows.map((x) => h('tr', {}, cols.map(([, k]) => h('td', {}, typeof x[k] === 'object' ? JSON.stringify(x[k]) : String(x[k] ?? '—'))))))) : h('p', { class: 'muted' }, 'Nothing flagged.'));
    mount(box, h('p', { class: 'card small' }, r.notes),
      table('Repeated rejected submissions', r.repeatedRejections, [['Reg. ID', 'registration_id'], ['Name', 'display_name'], ['Rejections', 'rejections'], ['By reason', 'by_reason']]),
      table('Abnormally fast answers (< 400 ms)', r.abnormallyFastAnswers, [['Reg. ID', 'registration_id'], ['Name', 'display_name'], ['Fast answers', 'fast_answers'], ['Fast & correct', 'fast_correct']]),
      table('Perfect score with very fast average', r.perfectAndVeryFast, [['Reg. ID', 'registration_id'], ['Name', 'display_name'], ['Marks', 'total_marks'], ['Correct time (ms)', 'correct_time_ms']]),
      table('Shared network fingerprints (≥ 5 participants)', r.sharedNetworkFingerprints, [['Fingerprint', 'ip_fingerprint'], ['Participants', 'participants']]));
  }
}

function suspendButton(userId, status) {
  if (!can('users.suspend')) return null;
  if (status === 'suspended') {
    return h('button', { class: 'btn sm', type: 'button', onclick: async () => { await api('POST', `/api/admin/users/${userId}/reinstate`).catch((e) => alert(e.message)); route(); } }, 'Reinstate');
  }
  return h('button', {
    class: 'btn sm danger', type: 'button',
    onclick: async () => {
      const reason = prompt('Reason for suspension (recorded in the audit log):');
      if (!reason) return;
      await api('POST', `/api/admin/users/${userId}/suspend`, { reason }).catch((e) => alert(e.message));
      route();
    },
  }, 'Suspend');
}

// ---------------------------------------------------------------------------
async function usersView() {
  const search = h('input', { type: 'search', placeholder: 'Search name, registration ID or last 4 digits of mobile' });
  const result = h('div', {}, 'Loading…');
  shell('users', h('h2', {}, 'Participants'), h('section', { class: 'card stack' }, search, result));
  let deb;
  const load = async (q, page = 1) => {
    let r;
    try { r = await api('GET', `/api/admin/users?${new URLSearchParams({ q, page })}`); } catch (err) { mount(result, errorCard(err)); return; }
    mount(result, h('p', { class: 'small muted' }, `${r.total} accounts`), h('div', { class: 'table-wrap' }, h('table', { class: 'data' },
      h('thead', {}, h('tr', {}, ['Reg. ID', 'Name', 'Mobile', 'Status', 'Registered', 'Competitions', ''].map((x) => h('th', {}, x)))),
      h('tbody', {}, r.rows.map((u) => h('tr', {},
        h('td', { class: 'mono' }, u.registrationId), h('td', {}, u.displayName ?? '—'), h('td', {}, u.maskedPhone),
        h('td', {}, u.status, u.suspendedReason ? h('div', { class: 'small muted' }, u.suspendedReason) : null),
        h('td', {}, fmt(u.registeredAt)), h('td', { class: 'num' }, u.competitions), h('td', {}, suspendButton(u.id, u.status))))))));
  };
  search.addEventListener('input', () => { clearTimeout(deb); deb = setTimeout(() => load(search.value), 300); });
  load('');
}

async function auditView() {
  shell('audit', h('p', {}, 'Loading…'));
  let r;
  try { r = await api('GET', '/api/admin/audit'); } catch (err) { shell('audit', errorCard(err)); return; }
  shell('audit', h('h2', {}, 'Audit log'), h('section', { class: 'card table-wrap' }, h('table', { class: 'data' },
    h('thead', {}, h('tr', {}, ['When', 'Actor', 'Action', 'Entity', 'Details'].map((x) => h('th', {}, x)))),
    h('tbody', {}, r.logs.map((l) => h('tr', {},
      h('td', {}, fmt(l.created_at)), h('td', {}, l.actor_email ?? `${l.actor_type}${l.actor_id ? ` ${l.actor_id.slice(0, 8)}` : ''}`),
      h('td', { class: 'mono' }, l.action), h('td', { class: 'mono' }, l.entity_type ? `${l.entity_type}:${(l.entity_id ?? '').slice(0, 8)}` : ''),
      h('td', { class: 'mono small' }, JSON.stringify(l.metadata))))))));
}

async function healthView() {
  const box = h('div', { class: 'stack' }, 'Loading…');
  shell('health', h('h2', {}, 'System health (this node)'), box);
  const load = async () => {
    let s;
    try { s = await api('GET', '/api/admin/health'); } catch (err) { mount(box, errorCard(err)); return; }
    const kpi = (l, v, ok) => h('div', { class: 'kpi' }, h('div', { class: `v ${ok === false ? 'bad-text' : ''}` }, String(v)), h('div', { class: 'l' }, l));
    mount(box, h('div', { class: 'kpis' },
      kpi('Node', s.node), kpi('Uptime', fmtDuration(s.uptimeSec * 1000)), kpi('Database', s.db.ok ? 'OK' : 'DOWN', s.db.ok),
      kpi('DB latency', `${s.db.latencyMs} ms`), kpi('DB pool (total/idle/waiting)', `${s.db.pool.total}/${s.db.pool.idle}/${s.db.pool.waiting}`),
      kpi('Redis', typeof s.redis === 'string' ? 'single-node' : s.redis.ok ? 'OK' : 'DOWN', typeof s.redis === 'string' ? undefined : s.redis.ok),
      kpi('Memory RSS', `${s.memoryMb.rss} MB`), kpi('WebSockets (this node)', s.wsConnectionsThisNode), kpi('Event-loop lag', `${s.eventLoopLagMs} ms`)),
    h('p', { class: 'small muted' }, 'Prometheus metrics for all nodes are exposed at /metrics. Refreshes every 3 seconds.'));
  };
  await load();
  timers.push(setInterval(load, 3000));
}

async function adminsView() {
  shell('admins', h('p', {}, 'Loading…'));
  let r;
  try { r = await api('GET', '/api/admin/admins'); } catch (err) { shell('admins', errorCard(err)); return; }
  const f = { email: h('input', { type: 'email', required: true, id: 'a-email' }), name: h('input', { required: true, id: 'a-name' }),
    password: h('input', { type: 'password', minlength: 12, required: true, id: 'a-pw', autocomplete: 'new-password' }),
    role: h('select', { id: 'a-role' }, ['admin', 'moderator', 'viewer', 'super_admin'].map((x) => h('option', { value: x }, x))) };
  const msg = h('p', { class: 'msg', role: 'alert' });
  const form = h('form', { class: 'card stack' }, h('h3', {}, 'Add administrator'),
    h('div', { class: 'form-grid' }, ...Object.entries({ Email: f.email, Name: f.name, 'Password (min 12 chars)': f.password, Role: f.role }).map(([l, el]) => h('div', { class: 'stack-sm' }, h('label', { for: el.id }, l), el))),
    h('p', { class: 'small muted' }, 'super_admin: everything · admin: competitions, answer keys, publishing, exports · moderator: monitoring + suspensions · viewer: read-only, no answer keys.'),
    h('button', { class: 'btn primary', type: 'submit' }, 'Create'), msg);
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    try { await api('POST', '/api/admin/admins', { email: f.email.value, name: f.name.value, password: f.password.value, role: f.role.value }); route(); } catch (err) { msg.textContent = err.message; }
  });
  shell('admins', h('h2', {}, 'Administrators'),
    h('section', { class: 'card table-wrap' }, h('table', { class: 'data' },
      h('thead', {}, h('tr', {}, ['Name', 'Email', 'Role', 'Status', 'Last login', ''].map((x) => h('th', {}, x)))),
      h('tbody', {}, r.admins.map((a) => h('tr', {},
        h('td', {}, a.name), h('td', {}, a.email), h('td', {}, a.role), h('td', {}, a.status), h('td', {}, fmt(a.lastLoginAt)),
        h('td', {}, a.id === admin.id ? '(you)' : h('button', {
          class: 'btn sm', type: 'button',
          onclick: async () => { await api('POST', `/api/admin/admins/${a.id}/status`, { status: a.status === 'active' ? 'disabled' : 'active' }).catch((e) => alert(e.message)); route(); },
        }, a.status === 'active' ? 'Disable' : 'Enable'))))))),
    form);
}

route();
