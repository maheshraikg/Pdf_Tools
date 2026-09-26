/* Akshara Aata — Kannada Varnamala learning games for kids. No ads, no tracking, works offline. */
(function () {
  'use strict';

  var D = window.KV_DATA;
  var LETTERS = D.letters;
  var app = document.getElementById('app');

  // ---------------------------------------------------------------- storage
  var KEY = 'akshara-aata-v1';
  var defaults = {
    stars: 0,
    seen: {},
    traced: {},
    settings: { voice: true, roman: true, sfx: true, rate: 0.75, recordMode: false }
  };
  function load() {
    var s = null;
    try { s = JSON.parse(localStorage.getItem(KEY)); } catch (e) { /* storage blocked */ }
    s = s || {};
    return {
      stars: s.stars || 0,
      seen: s.seen || {},
      traced: s.traced || {},
      settings: Object.assign({}, defaults.settings, s.settings || {})
    };
  }
  var store = load();
  function save() {
    try { localStorage.setItem(KEY, JSON.stringify(store)); } catch (e) { /* ignore */ }
  }

  // ---------------------------------------------------------------- helpers
  function $(sel, root) { return (root || app).querySelector(sel); }
  function $$(sel, root) { return Array.prototype.slice.call((root || app).querySelectorAll(sel)); }
  function shuffle(a) {
    a = a.slice();
    for (var i = a.length - 1; i > 0; i--) {
      var j = Math.floor(Math.random() * (i + 1));
      var t = a[i]; a[i] = a[j]; a[j] = t;
    }
    return a;
  }
  function pick(a) { return a[Math.floor(Math.random() * a.length)]; }
  function sample(pool, n, not) {
    return shuffle(pool.filter(function (x) { return not.indexOf(x) < 0; })).slice(0, n);
  }
  function byGroup(g) { return LETTERS.filter(function (l) { return l.group === g; }); }
  function countKeys(o) { return Object.keys(o).length; }

  // ---------------------------------------------------------------- sound effects
  var actx = null;
  function tone(freq, start, dur, type, vol) {
    if (!store.settings.sfx) return;
    try {
      actx = actx || new (window.AudioContext || window.webkitAudioContext)();
      if (actx.state === 'suspended') actx.resume();
      var o = actx.createOscillator();
      var g = actx.createGain();
      o.type = type || 'sine';
      o.frequency.value = freq;
      var t = actx.currentTime + start;
      g.gain.setValueAtTime(0.0001, t);
      g.gain.exponentialRampToValueAtTime(vol || 0.25, t + 0.02);
      g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
      o.connect(g); g.connect(actx.destination);
      o.start(t); o.stop(t + dur + 0.05);
    } catch (e) { /* audio unavailable */ }
  }
  var sfx = {
    tap: function () { tone(660, 0, 0.08, 'triangle', 0.15); },
    right: function () { tone(523, 0, 0.14, 'triangle'); tone(659, 0.1, 0.14, 'triangle'); tone(784, 0.2, 0.25, 'triangle'); },
    wrong: function () { tone(220, 0, 0.2, 'sine', 0.2); tone(180, 0.12, 0.25, 'sine', 0.2); },
    pop: function () { tone(900, 0, 0.06, 'square', 0.12); tone(1300, 0.03, 0.06, 'square', 0.08); },
    win: function () { [523, 659, 784, 1047].forEach(function (f, i) { tone(f, i * 0.12, 0.3, 'triangle'); }); }
  };

  // ---------------------------------------------------------------- recorded voices (IndexedDB)
  var db = null;
  var recordings = {}; // text -> blob URL, loaded at start
  function openDb() {
    return new Promise(function (resolve) {
      try {
        var req = indexedDB.open('akshara-aata', 1);
        req.onupgradeneeded = function () { req.result.createObjectStore('voice'); };
        req.onsuccess = function () { db = req.result; resolve(db); };
        req.onerror = function () { resolve(null); };
      } catch (e) { resolve(null); }
    });
  }
  function loadRecordings() {
    return openDb().then(function (d) {
      if (!d) return;
      return new Promise(function (resolve) {
        try {
          var tx = d.transaction('voice', 'readonly');
          var st = tx.objectStore('voice');
          var req = st.openCursor();
          req.onsuccess = function () {
            var c = req.result;
            if (!c) { resolve(); return; }
            recordings[c.key] = URL.createObjectURL(c.value);
            c.continue();
          };
          req.onerror = function () { resolve(); };
        } catch (e) { resolve(); }
      });
    });
  }
  function putRecording(key, blob) {
    if (recordings[key]) URL.revokeObjectURL(recordings[key]);
    recordings[key] = URL.createObjectURL(blob);
    try { db.transaction('voice', 'readwrite').objectStore('voice').put(blob, key); } catch (e) { /* not persisted */ }
  }
  function deleteRecording(key) {
    if (recordings[key]) URL.revokeObjectURL(recordings[key]);
    delete recordings[key];
    try { db.transaction('voice', 'readwrite').objectStore('voice').delete(key); } catch (e) { /* ignore */ }
  }

  // ---------------------------------------------------------------- speech
  var voices = { kn: null, hi: null, en: null };
  function refreshVoices() {
    if (!('speechSynthesis' in window)) return;
    var list = speechSynthesis.getVoices() || [];
    function find(re) { for (var i = 0; i < list.length; i++) if (re.test(list[i].lang)) return list[i]; return null; }
    voices.kn = find(/^kn/i);
    voices.hi = find(/^hi/i) || find(/^mr/i);
    voices.en = find(/^en[-_]IN/i) || find(/^en/i);
  }
  if ('speechSynthesis' in window) {
    refreshVoices();
    speechSynthesis.addEventListener && speechSynthesis.addEventListener('voiceschanged', refreshVoices);
  }
  // Kannada and Devanagari share the Brahmi layout, so a Hindi voice can read a shifted string
  // when no Kannada voice is installed. Short e/o have no Hindi sound, so map them to long ones.
  var devaFix = { 0x0C8E: 0x090F, 0x0C92: 0x0913, 0x0CC6: 0x0947, 0x0CCA: 0x094B };
  function toDeva(s) {
    var out = '';
    for (var i = 0; i < s.length; i++) {
      var c = s.charCodeAt(i);
      if (devaFix[c]) out += String.fromCharCode(devaFix[c]);
      else if (c >= 0x0C80 && c <= 0x0CFF) out += String.fromCharCode(c - 0x380);
      else out += s[i];
    }
    return out;
  }
  var currentAudio = null;
  function speak(text, roman) {
    if (!store.settings.voice) return;
    if (currentAudio) { currentAudio.pause(); currentAudio = null; }
    if (recordings[text]) {
      currentAudio = new Audio(recordings[text]);
      currentAudio.play().catch(function () {});
      return;
    }
    if (!('speechSynthesis' in window)) return;
    speechSynthesis.cancel();
    var u;
    if (voices.kn) {
      u = new SpeechSynthesisUtterance(text); u.voice = voices.kn; u.lang = voices.kn.lang;
    } else if (voices.hi) {
      u = new SpeechSynthesisUtterance(toDeva(text)); u.voice = voices.hi; u.lang = voices.hi.lang;
    } else if (voices.en && roman) {
      u = new SpeechSynthesisUtterance(roman); u.voice = voices.en; u.lang = voices.en.lang;
    } else {
      u = new SpeechSynthesisUtterance(text); u.lang = 'kn-IN';
    }
    u.rate = store.settings.rate;
    u.pitch = 1.1;
    speechSynthesis.speak(u);
  }
  function voiceStatus() {
    refreshVoices();
    if (voices.kn) return '✅ Kannada voice found: ' + voices.kn.name;
    if (voices.hi) return '⚠️ No Kannada voice on this device, using the Hindi voice (' + voices.hi.name + '), which reads Kannada letters closely. For the best sound, install Kannada in your phone’s text-to-speech settings, or record your own voice below.';
    return '⚠️ No Kannada voice on this device. Install Kannada in your phone’s text-to-speech settings (Android: Settings → Accessibility → Text-to-speech → Speech Services by Google → Install voice data → Kannada), or record your own voice below.';
  }

  // ---------------------------------------------------------------- toast + confetti
  var toastEl = document.createElement('div');
  toastEl.className = 'toast';
  toastEl.setAttribute('role', 'status');
  document.body.appendChild(toastEl);
  var toastTimer;
  function toast(msg) {
    toastEl.textContent = msg;
    toastEl.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { toastEl.classList.remove('show'); }, 1800);
  }
  function confetti() {
    if (window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    var c = document.createElement('canvas');
    c.id = 'confetti';
    document.body.appendChild(c);
    var dpr = window.devicePixelRatio || 1;
    c.width = innerWidth * dpr; c.height = innerHeight * dpr;
    var ctx = c.getContext('2d');
    var colors = ['#c8323c', '#f2b21b', '#2f9a5a', '#1e6fb0', '#7a3e8e'];
    var parts = [];
    for (var i = 0; i < 120; i++) {
      parts.push({ x: c.width / 2, y: c.height * 0.35, vx: (Math.random() - 0.5) * 22 * dpr, vy: (-Math.random() * 18 - 6) * dpr, s: (6 + Math.random() * 8) * dpr, r: Math.random() * 6, col: pick(colors) });
    }
    var start = performance.now();
    (function frame(t) {
      ctx.clearRect(0, 0, c.width, c.height);
      parts.forEach(function (p) {
        p.vy += 0.6 * dpr; p.x += p.vx; p.y += p.vy; p.r += 0.2;
        ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.r);
        ctx.fillStyle = p.col; ctx.fillRect(-p.s / 2, -p.s / 4, p.s, p.s / 2);
        ctx.restore();
      });
      if (t - start < 1800) requestAnimationFrame(frame); else c.remove();
    })(start);
  }

  // ---------------------------------------------------------------- stars + stickers
  function addStars(n) {
    if (n <= 0) return;
    var before = Math.floor(store.stars / 10);
    store.stars += n;
    save();
    var after = Math.floor(store.stars / 10);
    var el = document.querySelector('.stars b');
    if (el) el.textContent = store.stars;
    if (after > before && after <= D.stickers.length) {
      setTimeout(function () { toast('ಹೊಸ ಸ್ಟಿಕ್ಕರ್! New sticker ' + D.stickers[after - 1]); }, 900);
    }
  }

  // ---------------------------------------------------------------- navigation
  var stack = [];
  var cleanup = null;
  // Browser history lets the Android back button move between screens.
  var useHistory = false;
  if (!window.KV_NO_HISTORY) {
    try { history.replaceState({ d: 1 }, ''); useHistory = true; } catch (e) { /* sandboxed */ }
  }
  function go(screen, args, replace) {
    if (cleanup) { cleanup(); cleanup = null; }
    if (currentAudio) { currentAudio.pause(); currentAudio = null; }
    if ('speechSynthesis' in window) speechSynthesis.cancel();
    if (replace && stack.length) stack[stack.length - 1] = { screen: screen, args: args };
    else {
      stack.push({ screen: screen, args: args });
      if (stack.length > 1 && useHistory) {
        try { history.pushState({ d: stack.length }, ''); } catch (e) { useHistory = false; }
      }
    }
    screen.apply(null, args || []);
    window.scrollTo(0, 0);
  }
  function back() {
    if (stack.length <= 1) return;
    if (cleanup) { cleanup(); cleanup = null; }
    if ('speechSynthesis' in window) speechSynthesis.cancel();
    stack.pop();
    var top = stack[stack.length - 1];
    top.screen.apply(null, top.args || []);
    window.scrollTo(0, 0);
  }
  window.addEventListener('popstate', function () { if (useHistory) back(); });
  function goBack() {
    // Keep browser history in step with the in-app stack.
    if (useHistory && stack.length > 1) history.back(); else back();
  }

  function bar(title, sub, noBack) {
    return '<header class="bar">' +
      (noBack ? '' : '<button class="icon-btn" data-back aria-label="Back">⬅️</button>') +
      '<h1>' + title + (sub ? '<small>' + sub + '</small>' : '') + '</h1>' +
      '<div class="stars" aria-label="Stars">⭐ <b>' + store.stars + '</b></div>' +
      '</header>';
  }
  function render(html) {
    app.innerHTML = html;
    var b = $('[data-back]');
    if (b) b.addEventListener('click', function () { sfx.tap(); goBack(); });
  }
  function on(sel, fn) {
    $$(sel).forEach(function (el) { el.addEventListener('click', function (ev) { fn(el, ev); }); });
  }

  // ---------------------------------------------------------------- home
  function home() {
    var seen = LETTERS.filter(function (l) { return store.seen[l.ch]; }).length;
    var traced = LETTERS.filter(function (l) { return store.traced[l.ch]; }).length;
    var unlocked = Math.min(Math.floor(store.stars / 10), D.stickers.length);
    var stick = D.stickers.map(function (s, i) {
      return '<span class="' + (i < unlocked ? '' : 'locked') + '" aria-hidden="true">' + s + '</span>';
    }).join('');
    render(
      bar('ಅಕ್ಷರ ಆಟ', 'Akshara Aata · Kannada Varnamala', true) +
      '<div class="hello"><div class="mascot" aria-hidden="true">🐘</div>' +
      '<div><strong>ನಮಸ್ಕಾರ!</strong><p>ಬಾ, ಕನ್ನಡ ಅಕ್ಷರ ಕಲಿಯೋಣ. Let’s learn Kannada letters.</p></div></div>' +
      '<nav class="blocks">' +
      '<button class="block c-red" data-go="swara"><span class="glyph" aria-hidden="true">ಅ</span><b>ಸ್ವರಗಳು</b><span>Vowels · 13</span></button>' +
      '<button class="block c-blue" data-go="vyanjana"><span class="glyph" aria-hidden="true">ಕ</span><b>ವ್ಯಂಜನಗಳು</b><span>Consonants · 34</span></button>' +
      '<button class="block c-plum" data-go="kagunita"><span class="glyph" aria-hidden="true">ಕಾ</span><b>ಕಾಗುಣಿತ</b><span>Letter + vowel sign</span></button>' +
      '<button class="block c-green" data-go="numbers"><span class="glyph" aria-hidden="true">೩</span><b>ಅಂಕಿಗಳು</b><span>Numbers ೦–೧೦</span></button>' +
      '<button class="block c-yellow" data-go="trace"><span class="glyph" aria-hidden="true">✏️</span><b>ಬರೆಯೋಣ</b><span>Trace &amp; write</span></button>' +
      '<button class="block c-red" data-go="games"><span class="glyph" aria-hidden="true">🎈</span><b>ಆಟಗಳು</b><span>7 fun games</span></button>' +
      '</nav>' +
      '<section class="progress-card" aria-label="Progress">' +
      '<h2>ನನ್ನ ಪ್ರಗತಿ · My progress</h2>' +
      '<div class="meter" role="progressbar" aria-valuemin="0" aria-valuemax="49" aria-valuenow="' + seen + '"><i style="width:' + (seen / 49 * 100) + '%"></i></div>' +
      '<p>' + seen + ' / 49 letters explored · ' + traced + ' / 49 letters written</p>' +
      '<div class="sticker-row" aria-label="' + unlocked + ' stickers collected">' + stick + '</div>' +
      '<p>Every 10 ⭐ unlocks a sticker.</p>' +
      '</section>' +
      '<button class="parents-link" data-parents>For parents · Settings</button>'
    );
    on('[data-go]', function (el) {
      sfx.tap();
      var g = el.getAttribute('data-go');
      if (g === 'swara') go(letterGrid, ['swara']);
      else if (g === 'vyanjana') go(letterGrid, ['vyanjana']);
      else if (g === 'kagunita') go(kagunita, [LETTERS[15]]);
      else if (g === 'numbers') go(numberGrid);
      else if (g === 'trace') go(traceMenu);
      else if (g === 'games') go(gamesMenu);
    });
    on('[data-parents]', function () { go(parentGate); });
  }

  // ---------------------------------------------------------------- letter grids
  function tileHtml(l, i, cls) {
    return '<button class="tile ' + cls + (store.traced[l.ch] ? ' done' : '') + '" data-i="' + i + '" aria-label="' + l.tr + '">' + l.ch + '</button>';
  }
  function letterGrid(group) {
    var html;
    if (group === 'swara') {
      var sw = byGroup('swara'), yg = byGroup('yogavaha');
      var list = sw.concat(yg);
      html = bar('ಸ್ವರಗಳು', 'Vowels — tap a letter') +
        '<div class="grid">' + sw.map(function (l, i) { return tileHtml(l, i, 'swara'); }).join('') + '</div>' +
        '<h2 class="section-title">ಯೋಗವಾಹಗಳು <small>Yogavahas</small></h2>' +
        '<div class="grid">' + yg.map(function (l, i) { return tileHtml(l, sw.length + i, 'yogavaha'); }).join('') + '</div>';
      render(html);
      on('.tile', function (el) { sfx.tap(); go(letterCard, [list, +el.dataset.i]); });
    } else {
      var vy = byGroup('vyanjana');
      html = bar('ವ್ಯಂಜನಗಳು', 'Consonants — tap a letter');
      D.vargas.forEach(function (v) {
        html += '<h2 class="section-title">' + v.name + ' <small>' + v.en + '</small></h2><div class="grid">';
        vy.forEach(function (l, i) { if (l.varga === v.id) html += tileHtml(l, i, 'vyanjana'); });
        html += '</div>';
      });
      render(html);
      on('.tile', function (el) { sfx.tap(); go(letterCard, [vy, +el.dataset.i]); });
    }
  }

  function markWord(word, ch) {
    var i = word.indexOf(ch);
    if (i < 0) return word;
    return word.slice(0, i) + '<mark>' + ch + '</mark>' + word.slice(i + ch.length);
  }

  function recorderHtml(keys) {
    if (!store.settings.recordMode) return '';
    return '<div class="rec-row" aria-label="Record your voice">' + keys.map(function (k, i) {
      return '<button class="btn small rec" data-rec="' + i + '">🎙️ ' + k + '</button>' +
        (recordings[k] ? '<button class="btn small ghost" data-del="' + i + '" aria-label="Delete recording">🗑️</button>' : '');
    }).join('') + '</div>';
  }
  function bindRecorder(keys, rerender) {
    var mediaRec = null;
    on('[data-rec]', function (el) {
      var key = keys[+el.dataset.rec];
      if (mediaRec) { mediaRec.stop(); return; }
      if (!navigator.mediaDevices || !window.MediaRecorder) { toast('Recording is not supported here'); return; }
      navigator.mediaDevices.getUserMedia({ audio: true }).then(function (stream) {
        var chunks = [];
        mediaRec = new MediaRecorder(stream);
        mediaRec.ondataavailable = function (e) { chunks.push(e.data); };
        mediaRec.onstop = function () {
          stream.getTracks().forEach(function (t) { t.stop(); });
          putRecording(key, new Blob(chunks, { type: mediaRec.mimeType || 'audio/webm' }));
          mediaRec = null;
          toast('Saved your voice for ' + key);
          rerender();
        };
        mediaRec.start();
        el.classList.add('on');
        el.textContent = '⏹️ Stop';
        setTimeout(function () { if (mediaRec && mediaRec.state === 'recording') mediaRec.stop(); }, 4000);
      }).catch(function () { toast('Microphone permission was not given'); });
    });
    on('[data-del]', function (el) { deleteRecording(keys[+el.dataset.del]); rerender(); });
  }

  function letterCard(list, idx) {
    var l = list[idx];
    var isNum = l.n !== undefined;
    store.seen[l.ch] = 1; save();
    var cls = isNum ? 'num' : l.group;
    var picture = isNum
      ? '<div class="count-row" aria-label="' + l.n + '">' + (l.n ? new Array(l.n + 1).join('⭐') : '🫙') + '</div>' +
        '<button class="picture" data-word><div class="word"><b>' + l.word + '</b><span>' + (store.settings.roman ? l.wordTr + ' · ' : '') + l.n + '</span></div></button>'
      : '<button class="picture" data-word><span class="emoji" aria-hidden="true">' + l.emoji + '</span><div class="word"><b>' + markWord(l.word, l.ch) + '</b><span>' + (store.settings.roman ? l.wordTr + ' · ' : '') + l.en + '</span></div></button>';
    var sub = isNum ? 'Number ' + l.n : (l.group === 'swara' ? 'ಸ್ವರ · vowel' : l.group === 'yogavaha' ? 'ಯೋಗವಾಹ' : 'ವ್ಯಂಜನ · consonant');
    render(
      bar((idx + 1) + ' / ' + list.length, sub) +
      '<article class="card">' +
      '<button class="big-letter ' + cls + '" data-say aria-label="Say ' + (l.tr || l.wordTr) + '">' + l.ch + '</button>' +
      (store.settings.roman && !isNum ? '<div class="roman">“' + l.tr + '”</div>' : '') +
      picture +
      recorderHtml(isNum ? [l.word] : [l.ch, l.word]) +
      '<div class="controls">' +
      '<button class="btn round ghost" data-prev aria-label="Previous"' + (idx === 0 ? ' disabled' : '') + '>◀</button>' +
      '<button class="btn round" data-say2 aria-label="Listen">🔊</button>' +
      '<button class="btn round c-yellow" style="--c:var(--turmeric);--c2:var(--turmeric-deep)" data-trace aria-label="Trace this letter">✏️</button>' +
      '<button class="btn round ghost" data-next aria-label="Next"' + (idx === list.length - 1 ? ' disabled' : '') + '>▶</button>' +
      '</div></article>'
    );
    function sayLetter() {
      var b = $('.big-letter');
      if (!b) return;
      b.classList.remove('pop'); void b.offsetWidth; b.classList.add('pop');
      speak(isNum ? l.word : l.ch, isNum ? l.wordTr : l.tr);
    }
    on('[data-say]', sayLetter);
    on('[data-say2]', function () {
      sayLetter();
      if (!isNum) setTimeout(function () { speak(l.word, l.wordTr); }, 1100);
    });
    on('[data-word]', function () { speak(l.word, l.wordTr); });
    on('[data-prev]', function () { sfx.tap(); go(letterCard, [list, idx - 1], true); });
    on('[data-next]', function () { sfx.tap(); go(letterCard, [list, idx + 1], true); });
    on('[data-trace]', function () { sfx.tap(); go(traceScreen, [list, idx]); });
    bindRecorder(isNum ? [l.word] : [l.ch, l.word], function () { go(letterCard, [list, idx], true); });
    // swipe left / right
    var card = $('.card'), x0 = null;
    card.addEventListener('pointerdown', function (e) { x0 = e.clientX; });
    card.addEventListener('pointerup', function (e) {
      if (x0 === null) return;
      var dx = e.clientX - x0; x0 = null;
      if (dx < -70 && idx < list.length - 1) go(letterCard, [list, idx + 1], true);
      else if (dx > 70 && idx > 0) go(letterCard, [list, idx - 1], true);
    });
    setTimeout(sayLetter, 250);
  }

  function numberGrid() {
    render(bar('ಅಂಕಿಗಳು', 'Kannada numbers') +
      '<div class="grid">' + D.numbers.map(function (n, i) {
        return '<button class="tile num' + (store.traced[n.ch] ? ' done' : '') + '" data-i="' + i + '" aria-label="' + n.n + '">' + n.ch + '<small>' + n.n + '</small></button>';
      }).join('') + '</div>');
    on('.tile', function (el) { sfx.tap(); go(letterCard, [D.numbers, +el.dataset.i]); });
  }

  // ---------------------------------------------------------------- kagunita
  var KAG_BASES = byGroup('vyanjana');
  function kagunita(base) {
    var root = base.tr.slice(0, -1);
    var forms = D.signs.map(function (s) { return { ch: base.ch + s.sign, tr: root + s.tr }; });
    render(bar('ಕಾಗುಣಿತ', 'Kagunita — pick a letter, then tap a form') +
      '<div class="chips" role="group" aria-label="Consonants">' + KAG_BASES.map(function (b, i) {
        return '<button class="chip" data-b="' + i + '" aria-pressed="' + (b === base) + '">' + b.ch + '</button>';
      }).join('') + '</div>' +
      '<h2 class="section-title">' + base.ch + ' ಕಾಗುಣಿತ <small>' + base.tr + ' + vowel signs</small></h2>' +
      '<div class="grid">' + forms.map(function (f, i) {
        return '<button class="tile vyanjana" data-f="' + i + '" aria-label="' + f.tr + '">' + f.ch + (store.settings.roman ? '<small>' + f.tr + '</small>' : '') + '</button>';
      }).join('') + '</div>' +
      '<div class="controls" style="margin-top:18px"><button class="btn" data-all>🔊 ಎಲ್ಲವನ್ನೂ ಕೇಳು · Hear all</button></div>');
    on('[data-b]', function (el) { sfx.tap(); go(kagunita, [KAG_BASES[+el.dataset.b]], true); });
    on('[data-f]', function (el) {
      var f = forms[+el.dataset.f];
      el.animate && el.animate([{ transform: 'scale(1.15)' }, { transform: 'scale(1)' }], 300);
      speak(f.ch, f.tr);
    });
    var timer = null;
    on('[data-all]', function () {
      var i = 0;
      clearInterval(timer);
      timer = setInterval(function () {
        var tiles = $$('[data-f]');
        if (i >= forms.length || !tiles.length) { clearInterval(timer); return; }
        tiles.forEach(function (t) { t.style.outline = ''; });
        tiles[i].style.outline = '4px solid var(--turmeric)';
        speak(forms[i].ch, forms[i].tr);
        i++;
      }, 1100);
    });
    cleanup = function () { clearInterval(timer); };
  }

  // ---------------------------------------------------------------- tracing
  function traceMenu() {
    var sw = byGroup('swara').concat(byGroup('yogavaha')), vy = byGroup('vyanjana');
    render(bar('ಬರೆಯೋಣ', 'Pick a letter to write') +
      '<h2 class="section-title">ಸ್ವರಗಳು <small>Vowels</small></h2>' +
      '<div class="grid">' + sw.map(function (l, i) { return tileHtml(l, i, 'swara').replace('data-i', 'data-s'); }).join('') + '</div>' +
      '<h2 class="section-title">ವ್ಯಂಜನಗಳು <small>Consonants</small></h2>' +
      '<div class="grid">' + vy.map(function (l, i) { return tileHtml(l, i, 'vyanjana').replace('data-i', 'data-v'); }).join('') + '</div>' +
      '<h2 class="section-title">ಅಂಕಿಗಳು <small>Numbers</small></h2>' +
      '<div class="grid">' + D.numbers.slice(0, 10).map(function (n, i) {
        return '<button class="tile num' + (store.traced[n.ch] ? ' done' : '') + '" data-n="' + i + '">' + n.ch + '</button>';
      }).join('') + '</div>');
    on('[data-s]', function (el) { go(traceScreen, [sw, +el.dataset.s]); });
    on('[data-v]', function (el) { go(traceScreen, [vy, +el.dataset.v]); });
    on('[data-n]', function (el) { go(traceScreen, [D.numbers.slice(0, 10), +el.dataset.n]); });
  }

  var CRAYONS = ['#c8323c', '#1e6fb0', '#2f9a5a', '#7a3e8e', '#f28c1b'];
  var crayon = CRAYONS[0];
  function traceScreen(list, idx) {
    var l = list[idx];
    render(bar('ಬರೆ: ' + l.ch, 'Trace over the grey letter') +
      '<div class="trace-wrap"><canvas id="guide"></canvas><canvas id="ink" aria-label="Drawing area for ' + l.ch + '"></canvas></div>' +
      '<div class="crayons" role="group" aria-label="Crayon colour">' + CRAYONS.map(function (c) {
        return '<button class="crayon" data-c="' + c + '" style="background:' + c + '" aria-pressed="' + (c === crayon) + '" aria-label="Colour"></button>';
      }).join('') + '</div>' +
      '<div class="trace-msg" aria-live="polite"></div>' +
      '<div class="controls">' +
      '<button class="btn round ghost" data-prev aria-label="Previous"' + (idx === 0 ? ' disabled' : '') + '>◀</button>' +
      '<button class="btn round ghost" data-clear aria-label="Clear">🧽</button>' +
      '<button class="btn" data-check style="--c:var(--green);--c2:var(--green-deep);padding-inline:16px">✔ ಆಯ್ತು</button>' +
      '<button class="btn round ghost" data-next aria-label="Next"' + (idx === list.length - 1 ? ' disabled' : '') + '>▶</button>' +
      '</div>');

    var wrap = $('.trace-wrap'), guide = $('#guide'), ink = $('#ink');
    var gctx = guide.getContext('2d'), ictx = ink.getContext('2d');
    var dpr = Math.min(window.devicePixelRatio || 1, 2);
    var size, brush, core, tol, font;
    var fontStack = "800 X 'Baloo Tamma 2', 'Noto Sans Kannada', sans-serif";

    function layout() {
      size = Math.round(wrap.clientWidth * dpr);
      [guide, ink].forEach(function (c) { c.width = size; c.height = size; });
      brush = size * 0.065;
      var fs = size * 0.62;
      gctx.font = fontStack.replace('X', fs + 'px');
      var m = gctx.measureText(l.ch);
      var w = (m.actualBoundingBoxLeft || 0) + (m.actualBoundingBoxRight || m.width);
      var h = (m.actualBoundingBoxAscent || fs * 0.7) + (m.actualBoundingBoxDescent || 0);
      var scale = Math.min(1, (size * 0.72) / w, (size * 0.72) / h);
      fs *= scale;
      font = fontStack.replace('X', fs + 'px');
      gctx.font = font;
      m = gctx.measureText(l.ch);
      var asc = m.actualBoundingBoxAscent || fs * 0.7, desc = m.actualBoundingBoxDescent || 0;
      var left = m.actualBoundingBoxLeft || 0, right = m.actualBoundingBoxRight || m.width;
      var x = size / 2 - (right - left) / 2 + left;
      var y = size / 2 + (asc - desc) / 2;
      function draw(ctx, fill, stroke, lw) {
        ctx.font = font; ctx.textBaseline = 'alphabetic'; ctx.lineJoin = 'round';
        if (stroke) { ctx.strokeStyle = stroke; ctx.lineWidth = lw; ctx.strokeText(l.ch, x, y); }
        if (fill) { ctx.fillStyle = fill; ctx.fillText(l.ch, x, y); }
      }
      // guide: soft letter with dashed outline + baseline ruling like a Kannada copybook
      gctx.clearRect(0, 0, size, size);
      gctx.strokeStyle = 'rgba(30,111,176,0.18)'; gctx.lineWidth = 2 * dpr;
      [0.2, 0.8].forEach(function (f) { gctx.beginPath(); gctx.moveTo(0, size * f); gctx.lineTo(size, size * f); gctx.stroke(); });
      draw(gctx, '#eee2cc');
      gctx.setLineDash([6 * dpr, 8 * dpr]);
      draw(gctx, null, '#c9b48f', 2 * dpr);
      gctx.setLineDash([]);
      // masks used for checking
      core = document.createElement('canvas'); core.width = core.height = size;
      draw(core.getContext('2d'), '#000');
      tol = document.createElement('canvas'); tol.width = tol.height = size;
      draw(tol.getContext('2d'), '#000', '#000', brush * 2.2);
    }

    var drawing = false, last = null, hasInk = false;
    function pos(e) {
      var r = ink.getBoundingClientRect();
      return { x: (e.clientX - r.left) * size / r.width, y: (e.clientY - r.top) * size / r.height };
    }
    ink.addEventListener('pointerdown', function (e) {
      drawing = true; last = pos(e); hasInk = true;
      try { ink.setPointerCapture(e.pointerId); } catch (err) { /* ignore */ }
      ictx.fillStyle = crayon;
      ictx.beginPath(); ictx.arc(last.x, last.y, brush / 2, 0, Math.PI * 2); ictx.fill();
    });
    ink.addEventListener('pointermove', function (e) {
      if (!drawing) return;
      var p = pos(e);
      ictx.strokeStyle = crayon; ictx.lineWidth = brush; ictx.lineCap = 'round'; ictx.lineJoin = 'round';
      ictx.beginPath(); ictx.moveTo(last.x, last.y); ictx.lineTo(p.x, p.y); ictx.stroke();
      last = p;
    });
    function end() { drawing = false; }
    ink.addEventListener('pointerup', end);
    ink.addEventListener('pointercancel', end);

    function check() {
      var msg = $('.trace-msg');
      if (!hasInk) { msg.textContent = 'ಬೆರಳಿನಿಂದ ಬರೆ ✍️ Draw with your finger'; speak(l.ch, l.tr); return; }
      var a = core.getContext('2d').getImageData(0, 0, size, size).data;
      var b = tol.getContext('2d').getImageData(0, 0, size, size).data;
      var c = ictx.getImageData(0, 0, size, size).data;
      var letterPx = 0, covered = 0, inkPx = 0, inside = 0, step = 4 * 3;
      for (var i = 3; i < a.length; i += step) {
        var isL = a[i] > 60, isInk = c[i] > 60;
        if (isL) { letterPx++; if (isInk) covered++; }
        if (isInk) { inkPx++; if (b[i] > 60) inside++; }
      }
      var coverage = covered / Math.max(1, letterPx), accuracy = inside / Math.max(1, inkPx);
      if (coverage >= 0.5 && accuracy >= 0.7) {
        var first = !store.traced[l.ch];
        store.traced[l.ch] = 1; save();
        sfx.win(); confetti();
        msg.textContent = pick(D.praise) + (first ? ' +2 ⭐' : '');
        if (first) addStars(2);
        speak(l.ch, l.tr || l.wordTr);
      } else if (accuracy < 0.7) {
        sfx.wrong();
        msg.textContent = 'ಗೆರೆಯ ಒಳಗೆ ಬರೆ · Stay inside the letter';
      } else {
        sfx.wrong();
        msg.textContent = 'ಇನ್ನೂ ಸ್ವಲ್ಪ! · Colour the whole letter';
      }
    }

    on('[data-c]', function (el) {
      crayon = el.dataset.c;
      $$('[data-c]').forEach(function (b) { b.setAttribute('aria-pressed', b === el); });
    });
    on('[data-clear]', function () { ictx.clearRect(0, 0, size, size); hasInk = false; $('.trace-msg').textContent = ''; });
    on('[data-check]', check);
    on('[data-prev]', function () { go(traceScreen, [list, idx - 1], true); });
    on('[data-next]', function () { go(traceScreen, [list, idx + 1], true); });

    function start() { layout(); }
    var fontReady = document.fonts && document.fonts.load ? document.fonts.load(fontStack.replace('X', '100px'), l.ch) : Promise.resolve();
    fontReady.then(start, start);
    var onResize = function () { if (!hasInk) layout(); };
    window.addEventListener('resize', onResize);
    cleanup = function () { window.removeEventListener('resize', onResize); };
    setTimeout(function () { speak(l.ch, l.tr || l.wordTr); }, 300);
  }

  // ---------------------------------------------------------------- games menu
  var GAMES = [
    { id: 'listen', name: 'ಕೇಳಿ ಹುಡುಕು', en: 'Listen & find', glyph: '👂', cls: 'c-red' },
    { id: 'picture', name: 'ಚಿತ್ರ ಆಟ', en: 'First letter', glyph: '🖼️', cls: 'c-blue' },
    { id: 'memory', name: 'ಜೋಡಿ ಆಟ', en: 'Memory pairs', glyph: '🃏', cls: 'c-green' },
    { id: 'balloon', name: 'ಬಲೂನ್ ಆಟ', en: 'Balloon pop', glyph: '🎈', cls: 'c-plum' },
    { id: 'next', name: 'ಮುಂದೆ ಏನು?', en: 'What comes next', glyph: '➡️', cls: 'c-yellow' },
    { id: 'kagunita', name: 'ಕಾಗುಣಿತ ಆಟ', en: 'Add the sign', glyph: 'ಕಿ', cls: 'c-red' },
    { id: 'count', name: 'ಎಣಿಸು', en: 'Count & pick', glyph: '🔢', cls: 'c-blue wide' }
  ];
  function gamesMenu() {
    render(bar('ಆಟಗಳು', 'Games — every right answer earns a ⭐') +
      '<div class="game-list">' + GAMES.map(function (g) {
        return '<button class="block ' + g.cls + '" data-g="' + g.id + '"><span class="glyph" aria-hidden="true">' + g.glyph + '</span><b>' + g.name + '</b><span>' + g.en + '</span></button>';
      }).join('') + '</div>');
    on('[data-g]', function (el) {
      sfx.tap();
      var id = el.dataset.g;
      if (id === 'memory') go(memoryGame);
      else if (id === 'balloon') go(balloonGame);
      else go(quiz, [id]);
    });
  }

  // ---------------------------------------------------------------- quiz engine (5 games share it)
  var ROUNDS = 8;
  var makers = {
    listen: function () {
      var pool = pick([byGroup('swara'), byGroup('vyanjana'), LETTERS]);
      var ans = pick(pool);
      var opts = shuffle([ans].concat(sample(pool, 3, [ans])));
      return {
        title: 'ಕೇಳಿ ಹುಡುಕು', sub: 'Listen, then tap the letter',
        prompt: '<button class="say" data-say aria-label="Play sound">🔊</button><div class="q">ಯಾವ ಅಕ್ಷರ? Which letter?</div>' +
          (store.settings.roman ? '<div class="hint">“' + ans.tr + '”</div>' : ''),
        say: function () { speak(ans.ch, ans.tr); },
        options: opts.map(function (o) { return { label: o.ch, ok: o === ans }; }),
        after: function () {}
      };
    },
    picture: function () {
      var pool = LETTERS.filter(function (l) { return l.start; });
      var ans = pick(pool);
      var opts = shuffle([ans].concat(sample(pool, 3, [ans])));
      return {
        title: 'ಚಿತ್ರ ಆಟ', sub: 'Which letter does it start with?',
        prompt: '<div class="show emoji" aria-hidden="true">' + ans.emoji + '</div>' +
          '<button class="btn small ghost" data-say>🔊 ' + (store.settings.roman ? ans.en : 'ಕೇಳು') + '</button>',
        say: function () { speak(ans.word, ans.wordTr); },
        options: opts.map(function (o) { return { label: o.ch, ok: o === ans }; }),
        after: function () { toast(ans.emoji + ' ' + ans.word); }
      };
    },
    next: function () {
      var seq = pick([byGroup('swara'), byGroup('vyanjana').slice(0, 25), byGroup('vyanjana').slice(25), D.numbers.slice(0, 10)]);
      var start = Math.floor(Math.random() * (seq.length - 3));
      var run = seq.slice(start, start + 4);
      var gap = 1 + Math.floor(Math.random() * 3);
      var ans = run[gap];
      var opts = shuffle([ans].concat(sample(seq, 3, run)));
      return {
        title: 'ಮುಂದೆ ಏನು?', sub: 'Which letter fills the gap?',
        prompt: '<div class="seq">' + run.map(function (x, i) {
          return i === gap ? '<span class="gap">' + x.ch + '</span>' : '<span>' + x.ch + '</span>';
        }).join('') + '</div><div class="q">ಬಿಟ್ಟ ಅಕ್ಷರ ಯಾವುದು?</div>',
        say: function () {},
        options: opts.map(function (o) { return { label: o.ch, ok: o === ans }; }),
        after: function () { if (ans.n !== undefined) speak(ans.word, ans.wordTr); else speak(ans.ch, ans.tr); }
      };
    },
    kagunita: function () {
      var bases = byGroup('vyanjana').filter(function (b) { return b.ch !== 'ಙ' && b.ch !== 'ಞ'; });
      var base = pick(bases);
      var signs = D.signs.slice(1, 13);
      var s = pick(signs);
      var root = base.tr.slice(0, -1);
      var ans = base.ch + s.sign;
      var others = sample(signs, 2, [s]).map(function (o) { return base.ch + o.sign; });
      var other = pick(bases.filter(function (b) { return b !== base; })).ch + s.sign;
      var opts = shuffle([ans, other].concat(others));
      return {
        title: 'ಕಾಗುಣಿತ ಆಟ', sub: 'Letter + vowel sign = ?',
        prompt: '<div class="seq"><span>' + base.ch + '</span><span style="color:var(--ink-soft)">+</span><span style="color:var(--red)">' + s.vowel + '</span><span style="color:var(--ink-soft)">=</span><span style="color:var(--ink-soft)">?</span></div>' +
          (store.settings.roman ? '<div class="hint">' + base.tr + ' + ' + s.tr + ' = “' + root + s.tr + '”</div>' : ''),
        say: function () { speak(ans, root + s.tr); },
        options: opts.map(function (o) { return { label: o, ok: o === ans }; }),
        after: function () { speak(ans, root + s.tr); }
      };
    },
    count: function () {
      var nums = D.numbers.slice(1, 10);
      var ans = pick(nums);
      var thing = pick(['🍎', '🐟', '🌸', '🦆', '⭐', '🥭', '🎈', '🐞']);
      var opts = shuffle([ans].concat(sample(nums, 3, [ans])));
      return {
        title: 'ಎಣಿಸು', sub: 'Count, then tap the Kannada number',
        prompt: '<div class="count-row" aria-label="' + ans.n + ' things">' + new Array(ans.n + 1).join(thing) + '</div><div class="q">ಎಷ್ಟು? How many?</div>',
        say: function () {},
        options: opts.map(function (o) { return { label: o.ch, ok: o === ans }; }),
        after: function () { speak(ans.word, ans.wordTr); }
      };
    }
  };

  function quiz(kind) {
    var round = 0, score = 0;
    function next() {
      if (round >= ROUNDS) { finish(kind, score, ROUNDS, function () { go(quiz, [kind], true); }); return; }
      var r = makers[kind]();
      var firstTry = true, done = false;
      render(bar(r.title, r.sub) +
        '<div class="hud"><div class="meter"><i style="width:' + (round / ROUNDS * 100) + '%"></i></div><span>' + (round + 1) + '/' + ROUNDS + '</span></div>' +
        '<section class="prompt">' + r.prompt + '</section>' +
        '<div class="choices">' + r.options.map(function (o, i) {
          return '<button class="choice" data-o="' + i + '">' + o.label + '</button>';
        }).join('') + '</div>');
      on('[data-say]', function () { r.say(); });
      on('[data-o]', function (el) {
        if (done) return;
        var o = r.options[+el.dataset.o];
        if (o.ok) {
          done = true;
          el.classList.add('right');
          sfx.right();
          if (firstTry) score++;
          r.after();
          round++;
          setTimeout(next, 1300);
        } else {
          firstTry = false;
          el.classList.add('wrong');
          el.disabled = true;
          sfx.wrong();
          setTimeout(r.say, 400);
        }
      });
      setTimeout(r.say, 350);
    }
    next();
  }

  function finish(kind, score, total, again) {
    addStars(score);
    var rating = score >= total * 0.85 ? 3 : score >= total * 0.5 ? 2 : 1;
    sfx.win();
    if (rating === 3) confetti();
    render(bar('ಆಟ ಮುಗಿಯಿತು', 'Game over') +
      '<section class="result">' +
      '<div class="trophy" aria-hidden="true">' + (rating === 3 ? '🏆' : rating === 2 ? '🥳' : '🌱') + '</div>' +
      '<h2>' + (rating === 3 ? 'ಶಭಾಷ್!' : rating === 2 ? 'ಚೆನ್ನಾಗಿದೆ!' : 'ಮತ್ತೆ ಆಡೋಣ!') + '</h2>' +
      '<div class="earned" aria-label="' + rating + ' of 3">' + '⭐'.repeat(rating) + '<span style="opacity:.2">' + '⭐'.repeat(3 - rating) + '</span></div>' +
      '<p>' + score + ' / ' + total + ' right the first time · +' + score + ' ⭐</p>' +
      '<div class="controls"><button class="btn" data-again>🔁 ಮತ್ತೆ ಆಡು</button><button class="btn ghost" data-menu>🎮 ಆಟಗಳು</button></div>' +
      '</section>');
    on('[data-again]', again);
    on('[data-menu]', function () { goBack(); });
    speak(rating === 3 ? 'ಶಭಾಷ್' : 'ಚೆನ್ನಾಗಿದೆ', rating === 3 ? 'shabash' : 'chennagide');
  }

  // ---------------------------------------------------------------- memory game
  function memoryGame() {
    var pairs = sample(LETTERS.filter(function (l) { return l.start; }), 6, []);
    var cards = shuffle(pairs.map(function (l) { return { l: l, face: l.ch, kind: 'ch' }; })
      .concat(pairs.map(function (l) { return { l: l, face: l.emoji, kind: 'pic' }; })));
    var open = [], matched = 0, moves = 0, lock = false;
    render(bar('ಜೋಡಿ ಆಟ', 'Match each letter with its picture') +
      '<div class="hud"><span>Moves: <b data-moves>0</b></span></div>' +
      '<div class="memory">' + cards.map(function (c, i) {
        return '<button class="mcard" data-m="' + i + '" aria-label="Card"><div class="inner"><div class="face back"></div><div class="face front">' + c.face + '</div></div></button>';
      }).join('') + '</div>');
    on('[data-m]', function (el) {
      var i = +el.dataset.m, c = cards[i];
      if (lock || el.classList.contains('open') || el.classList.contains('matched')) return;
      sfx.tap();
      el.classList.add('open');
      if (c.kind === 'ch') speak(c.l.ch, c.l.tr); else speak(c.l.word, c.l.wordTr);
      open.push({ el: el, c: c });
      if (open.length < 2) return;
      moves++; $('[data-moves]').textContent = moves;
      var a = open[0], b = open[1];
      open = [];
      if (a.c.l === b.c.l && a.c.kind !== b.c.kind) {
        setTimeout(function () {
          a.el.classList.add('matched'); b.el.classList.add('matched');
          sfx.right(); matched++;
          if (matched === pairs.length) {
            setTimeout(function () {
              var score = moves <= 9 ? 8 : moves <= 13 ? 6 : 4;
              finish('memory', score, 8, function () { go(memoryGame, [], true); });
            }, 700);
          }
        }, 300);
      } else {
        lock = true;
        setTimeout(function () { a.el.classList.remove('open'); b.el.classList.remove('open'); lock = false; }, 1000);
      }
    });
  }

  // ---------------------------------------------------------------- balloon game
  function balloonGame() {
    var GOAL = 8;
    var pool = pick([byGroup('swara'), byGroup('vyanjana').slice(0, 15), byGroup('vyanjana').slice(15)]);
    var target = pick(pool);
    var popped = 0, balloons = [], running = true, last = 0, spawnAt = 0, raf;
    var colors = ['#c8323c', '#1e6fb0', '#2f9a5a', '#7a3e8e', '#f28c1b'];
    render(bar('ಬಲೂನ್ ಆಟ', 'Pop only the balloons with this letter') +
      '<div class="hud"><button class="btn small" data-say style="font-size:1.8rem">' + target.ch + ' 🔊</button>' +
      '<div class="meter"><i data-prog style="width:0%"></i></div><span data-count>0/' + GOAL + '</span></div>' +
      '<div class="sky" aria-label="Balloons"></div>');
    var sky = $('.sky');
    on('[data-say]', function () { speak(target.ch, target.tr); });
    function spawn() {
      var isT = Math.random() < 0.4;
      var l = isT ? target : pick(pool.filter(function (x) { return x !== target; }));
      var b = document.createElement('button');
      b.className = 'balloon';
      b.textContent = l.ch;
      b.style.background = pick(colors);
      var w = sky.clientWidth;
      var obj = { el: b, l: l, x: 8 + Math.random() * Math.max(10, w - 94), y: sky.clientHeight + 10, v: 55 + Math.random() * 45 + popped * 4, wob: Math.random() * 6 };
      b.style.left = obj.x + 'px';
      b.addEventListener('pointerdown', function (e) {
        e.preventDefault();
        if (obj.gone) return;
        if (obj.l === target) {
          obj.gone = true;
          b.classList.add('popped'); sfx.pop();
          popped++;
          $('[data-count]').textContent = popped + '/' + GOAL;
          $('[data-prog]').style.width = (popped / GOAL * 100) + '%';
          setTimeout(function () { b.remove(); }, 260);
          if (popped >= GOAL) { running = false; setTimeout(function () { finish('balloon', GOAL, GOAL, function () { go(balloonGame, [], true); }); }, 600); }
        } else {
          sfx.wrong();
          b.animate && b.animate([{ transform: 'translateX(-8px)' }, { transform: 'translateX(8px)' }, { transform: 'none' }], 300);
          speak(obj.l.ch, obj.l.tr);
        }
      });
      sky.appendChild(b);
      balloons.push(obj);
    }
    function frame(t) {
      if (!running) return;
      var dt = last ? Math.min(0.05, (t - last) / 1000) : 0;
      last = t;
      if (t > spawnAt) { spawn(); spawnAt = t + 900 - Math.min(400, popped * 30); }
      balloons = balloons.filter(function (o) {
        if (o.gone) return false;
        o.y -= o.v * dt;
        o.el.style.transform = 'translate(' + Math.sin(t / 500 + o.wob) * 8 + 'px,' + o.y + 'px)';
        if (o.y < -140) { o.el.remove(); return false; }
        return true;
      });
      raf = requestAnimationFrame(frame);
    }
    raf = requestAnimationFrame(frame);
    cleanup = function () { running = false; cancelAnimationFrame(raf); };
    setTimeout(function () { speak(target.ch, target.tr); }, 300);
  }

  // ---------------------------------------------------------------- parents
  function parentGate() {
    var a = 3 + Math.floor(Math.random() * 6), b = 4 + Math.floor(Math.random() * 5);
    var ans = a + b;
    var opts = shuffle([ans, ans + 2, ans - 3, ans + 5]);
    render(bar('For parents', 'Ask a grown-up') +
      '<section class="panel"><p>Grown-ups only: tap the answer to open settings.</p>' +
      '<div class="gate-q">' + a + ' + ' + b + ' = ?</div>' +
      '<div class="choices">' + opts.map(function (o) { return '<button class="choice" style="font-size:2rem" data-a="' + o + '">' + o + '</button>'; }).join('') + '</div></section>');
    on('[data-a]', function (el) {
      if (+el.dataset.a === ans) go(parents, [], true);
      else goBack();
    });
  }

  function parents() {
    var s = store.settings;
    function row(id, label, checked) {
      return '<div class="row"><label for="' + id + '">' + label + '</label><input class="switch" type="checkbox" id="' + id + '"' + (checked ? ' checked' : '') + '></div>';
    }
    render(bar('Parents', 'Settings & progress') +
      '<section class="panel"><h2>Sound</h2>' +
      row('set-voice', 'Speak letters aloud', s.voice) +
      row('set-sfx', 'Game sound effects', s.sfx) +
      '<div class="row"><label for="set-rate">Speaking speed</label><input type="range" id="set-rate" min="0.5" max="1.1" step="0.05" value="' + s.rate + '"></div>' +
      '<div class="voice-status" data-status>' + voiceStatus() + '</div>' +
      '<div><button class="btn small" data-test>🔊 Test: ಅ ಆ ಇ</button></div></section>' +
      '<section class="panel"><h2>Record your own voice</h2>' +
      '<p>Turn this on to show 🎙️ buttons on every letter card. Your recording plays instead of the phone’s voice, so your child hears Kannada the way your family says it. Recordings stay on this device.</p>' +
      row('set-rec', 'Show record buttons', s.recordMode) +
      '<p data-reccount>' + countKeys(recordings) + ' recordings saved.</p></section>' +
      '<section class="panel"><h2>Display</h2>' +
      row('set-roman', 'Show English sounds (a, aa, ka…) and meanings', s.roman) + '</section>' +
      '<section class="panel"><h2>Progress</h2>' +
      '<p>' + countKeys(store.seen) + ' letters explored · ' + countKeys(store.traced) + ' letters written · ' + store.stars + ' stars</p>' +
      '<div><button class="btn small rec" data-reset>Reset progress</button></div></section>' +
      '<section class="panel"><h2>About</h2><p>Akshara Aata teaches the 49 letters of the Kannada varnamala (13 swaras, 2 yogavahas, 34 vyanjanas), kagunita and numbers through listening, tracing and games. No ads, no accounts and no data leaves this device. It works offline once opened.</p></section>');
    function bind(id, key) {
      document.getElementById(id).addEventListener('change', function (e) { s[key] = e.target.checked; save(); });
    }
    bind('set-voice', 'voice'); bind('set-sfx', 'sfx'); bind('set-rec', 'recordMode'); bind('set-roman', 'roman');
    document.getElementById('set-rate').addEventListener('change', function (e) { s.rate = +e.target.value; save(); });
    on('[data-test]', function () {
      $('[data-status]').textContent = voiceStatus();
      speak('ಅ ಆ ಇ', 'a aa i');
    });
    var armed = false;
    on('[data-reset]', function (el) {
      if (!armed) { armed = true; el.textContent = 'Tap again to erase all progress'; return; }
      store.stars = 0; store.seen = {}; store.traced = {}; save();
      toast('Progress reset');
      go(parents, [], true);
    });
  }

  // ---------------------------------------------------------------- boot
  go(home);
  loadRecordings();
  if (!window.KV_NO_SW && 'serviceWorker' in navigator && (location.protocol === 'https:' || location.hostname === 'localhost')) {
    try { navigator.serviceWorker.register('sw.js').catch(function () {}); } catch (e) { /* not available */ }
  }
})();
