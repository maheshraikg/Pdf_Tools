/*
 * Akshara Aata — Kannada Varnamala content.
 * 49 letters (13 swaras + 2 yogavahas + 34 vyanjanas), numerals and kagunita signs.
 * start:false marks words where the letter is not the first sound
 * (those words are skipped by the "which letter does it start with?" game).
 */
(function () {
  'use strict';

  function L(ch, tr, group, varga, word, wordTr, emoji, en, start) {
    return { ch: ch, tr: tr, group: group, varga: varga, word: word, wordTr: wordTr, emoji: emoji, en: en, start: start !== false };
  }

  var letters = [
    // ಸ್ವರಗಳು — vowels
    L('ಅ', 'a', 'swara', '', 'ಅನಾನಸ್', 'anaanas', '🍍', 'Pineapple'),
    L('ಆ', 'aa', 'swara', '', 'ಆನೆ', 'aane', '🐘', 'Elephant'),
    L('ಇ', 'i', 'swara', '', 'ಇಲಿ', 'ili', '🐭', 'Mouse'),
    L('ಈ', 'ii', 'swara', '', 'ಈರುಳ್ಳಿ', 'iiruLLi', '🧅', 'Onion'),
    L('ಉ', 'u', 'swara', '', 'ಉಂಗುರ', 'ungura', '💍', 'Ring'),
    L('ಊ', 'uu', 'swara', '', 'ಊಟ', 'uuTa', '🍛', 'Meal'),
    L('ಋ', 'ru', 'swara', '', 'ಋಷಿ', 'rushi', '🧘', 'Sage'),
    L('ಎ', 'e', 'swara', '', 'ಎಲೆ', 'ele', '🍃', 'Leaf'),
    L('ಏ', 'ee', 'swara', '', 'ಏಣಿ', 'eeNi', '🪜', 'Ladder'),
    L('ಐ', 'ai', 'swara', '', 'ಐದು', 'aidu', '🖐️', 'Five'),
    L('ಒ', 'o', 'swara', '', 'ಒಂಟೆ', 'onTe', '🐫', 'Camel'),
    L('ಓ', 'oo', 'swara', '', 'ಓದು', 'oodu', '📖', 'Read'),
    L('ಔ', 'au', 'swara', '', 'ಔಷಧಿ', 'aushadhi', '💊', 'Medicine'),
    // ಯೋಗವಾಹಗಳು
    L('ಅಂ', 'am', 'yogavaha', '', 'ಅಂಗಡಿ', 'angaDi', '🏪', 'Shop'),
    L('ಅಃ', 'ah', 'yogavaha', '', 'ದುಃಖ', 'duhkha', '😢', 'Sadness', false),
    // ವರ್ಗೀಯ ವ್ಯಂಜನಗಳು
    L('ಕ', 'ka', 'vyanjana', 'ka', 'ಕಮಲ', 'kamala', '🪷', 'Lotus'),
    L('ಖ', 'kha', 'vyanjana', 'ka', 'ಖಡ್ಗ', 'khaDga', '🗡️', 'Sword'),
    L('ಗ', 'ga', 'vyanjana', 'ka', 'ಗಡಿಯಾರ', 'gaDiyaara', '⏰', 'Clock'),
    L('ಘ', 'gha', 'vyanjana', 'ka', 'ಘಂಟೆ', 'ghanTe', '🔔', 'Bell'),
    L('ಙ', 'nga', 'vyanjana', 'ka', 'ವಾಙ್ಮಯ', 'vaangmaya', '📜', 'Literature', false),
    L('ಚ', 'cha', 'vyanjana', 'cha', 'ಚಮಚ', 'chamacha', '🥄', 'Spoon'),
    L('ಛ', 'chha', 'vyanjana', 'cha', 'ಛತ್ರಿ', 'chhatri', '☂️', 'Umbrella'),
    L('ಜ', 'ja', 'vyanjana', 'cha', 'ಜಿಂಕೆ', 'jinke', '🦌', 'Deer'),
    L('ಝ', 'jha', 'vyanjana', 'cha', 'ಝರಿ', 'jhari', '🏞️', 'Stream'),
    L('ಞ', 'nya', 'vyanjana', 'cha', 'ಜ್ಞಾನ', 'jnaana', '🧠', 'Knowledge', false),
    L('ಟ', 'Ta', 'vyanjana', 'Ta', 'ಟಗರು', 'Tagaru', '🐏', 'Ram'),
    L('ಠ', 'Tha', 'vyanjana', 'Ta', 'ಮಠ', 'maTha', '🛕', 'Monastery', false),
    L('ಡ', 'Da', 'vyanjana', 'Ta', 'ಡಮರು', 'Damaru', '🥁', 'Hand drum'),
    L('ಢ', 'Dha', 'vyanjana', 'Ta', 'ಢಕ್ಕೆ', 'Dhakke', '🪘', 'Big drum'),
    L('ಣ', 'Na', 'vyanjana', 'Ta', 'ಬಾಣ', 'baaNa', '🏹', 'Arrow', false),
    L('ತ', 'ta', 'vyanjana', 'ta', 'ತರಕಾರಿ', 'tarakaari', '🥕', 'Vegetables'),
    L('ಥ', 'tha', 'vyanjana', 'ta', 'ಕಥೆ', 'kathe', '📚', 'Story', false),
    L('ದ', 'da', 'vyanjana', 'ta', 'ದನ', 'dana', '🐄', 'Cow'),
    L('ಧ', 'dha', 'vyanjana', 'ta', 'ಧ್ವಜ', 'dhvaja', '🚩', 'Flag'),
    L('ನ', 'na', 'vyanjana', 'ta', 'ನವಿಲು', 'navilu', '🦚', 'Peacock'),
    L('ಪ', 'pa', 'vyanjana', 'pa', 'ಪುಸ್ತಕ', 'pustaka', '📕', 'Book'),
    L('ಫ', 'pha', 'vyanjana', 'pa', 'ಫಲ', 'phala', '🍎', 'Fruit'),
    L('ಬ', 'ba', 'vyanjana', 'pa', 'ಬಾತುಕೋಳಿ', 'baatukoLi', '🦆', 'Duck'),
    L('ಭ', 'bha', 'vyanjana', 'pa', 'ಭೂಮಿ', 'bhuumi', '🌍', 'Earth'),
    L('ಮ', 'ma', 'vyanjana', 'pa', 'ಮರ', 'mara', '🌳', 'Tree'),
    // ಅವರ್ಗೀಯ ವ್ಯಂಜನಗಳು
    L('ಯ', 'ya', 'vyanjana', 'avargiya', 'ಯಂತ್ರ', 'yantra', '⚙️', 'Machine'),
    L('ರ', 'ra', 'vyanjana', 'avargiya', 'ರೈಲು', 'railu', '🚂', 'Train'),
    L('ಲ', 'la', 'vyanjana', 'avargiya', 'ಲಾರಿ', 'laari', '🚚', 'Lorry'),
    L('ವ', 'va', 'vyanjana', 'avargiya', 'ವಜ್ರ', 'vajra', '💎', 'Diamond'),
    L('ಶ', 'sha', 'vyanjana', 'avargiya', 'ಶಂಖ', 'shankha', '🐚', 'Conch'),
    L('ಷ', 'Sha', 'vyanjana', 'avargiya', 'ಕೃಷಿ', 'krushi', '🌾', 'Farming', false),
    L('ಸ', 'sa', 'vyanjana', 'avargiya', 'ಸೂರ್ಯ', 'suurya', '☀️', 'Sun'),
    L('ಹ', 'ha', 'vyanjana', 'avargiya', 'ಹೂವು', 'huuvu', '🌸', 'Flower'),
    L('ಳ', 'La', 'vyanjana', 'avargiya', 'ಬಾಳೆಹಣ್ಣು', 'baaLehaNNu', '🍌', 'Banana', false)
  ];

  var vargas = [
    { id: 'ka', name: 'ಕ ವರ್ಗ', en: 'Ka group' },
    { id: 'cha', name: 'ಚ ವರ್ಗ', en: 'Cha group' },
    { id: 'Ta', name: 'ಟ ವರ್ಗ', en: 'Ta group' },
    { id: 'ta', name: 'ತ ವರ್ಗ', en: 'ta group' },
    { id: 'pa', name: 'ಪ ವರ್ಗ', en: 'Pa group' },
    { id: 'avargiya', name: 'ಅವರ್ಗೀಯ', en: 'Other consonants' }
  ];

  var numbers = [
    { ch: '೦', n: 0, word: 'ಸೊನ್ನೆ', wordTr: 'sonne' },
    { ch: '೧', n: 1, word: 'ಒಂದು', wordTr: 'ondu' },
    { ch: '೨', n: 2, word: 'ಎರಡು', wordTr: 'eraDu' },
    { ch: '೩', n: 3, word: 'ಮೂರು', wordTr: 'mooru' },
    { ch: '೪', n: 4, word: 'ನಾಲ್ಕು', wordTr: 'naalku' },
    { ch: '೫', n: 5, word: 'ಐದು', wordTr: 'aidu' },
    { ch: '೬', n: 6, word: 'ಆರು', wordTr: 'aaru' },
    { ch: '೭', n: 7, word: 'ಏಳು', wordTr: 'eeLu' },
    { ch: '೮', n: 8, word: 'ಎಂಟು', wordTr: 'enTu' },
    { ch: '೯', n: 9, word: 'ಒಂಬತ್ತು', wordTr: 'ombattu' },
    { ch: '೧೦', n: 10, word: 'ಹತ್ತು', wordTr: 'hattu' }
  ];

  // Vowel signs (ಗುಣಿತಾಕ್ಷರ ಚಿಹ್ನೆಗಳು), paired with their swara.
  var signs = [
    { sign: '', vowel: 'ಅ', tr: 'a' },
    { sign: 'ಾ', vowel: 'ಆ', tr: 'aa' },
    { sign: 'ಿ', vowel: 'ಇ', tr: 'i' },
    { sign: 'ೀ', vowel: 'ಈ', tr: 'ii' },
    { sign: 'ು', vowel: 'ಉ', tr: 'u' },
    { sign: 'ೂ', vowel: 'ಊ', tr: 'uu' },
    { sign: 'ೃ', vowel: 'ಋ', tr: 'ru' },
    { sign: 'ೆ', vowel: 'ಎ', tr: 'e' },
    { sign: 'ೇ', vowel: 'ಏ', tr: 'ee' },
    { sign: 'ೈ', vowel: 'ಐ', tr: 'ai' },
    { sign: 'ೊ', vowel: 'ಒ', tr: 'o' },
    { sign: 'ೋ', vowel: 'ಓ', tr: 'oo' },
    { sign: 'ೌ', vowel: 'ಔ', tr: 'au' },
    { sign: 'ಂ', vowel: 'ಅಂ', tr: 'am' },
    { sign: 'ಃ', vowel: 'ಅಃ', tr: 'ah' }
  ];

  var praise = ['ಶಭಾಷ್!', 'ಅದ್ಭುತ!', 'ತುಂಬಾ ಚೆನ್ನಾಗಿದೆ!', 'ಸೂಪರ್!', 'ಸರಿ ಉತ್ತರ!'];

  // Sticker rewards: one unlocks every 10 stars.
  var stickers = ['🐘', '🦚', '🪁', '🥭', '🐯', '🌺', '🚂', '🦜', '🏏', '🌈', '🐢', '🦋', '🍦', '🚀', '👑', '🎺', '🐬', '🌻', '🦁', '🏆'];

  window.KV_DATA = {
    letters: letters,
    vargas: vargas,
    numbers: numbers,
    signs: signs,
    praise: praise,
    stickers: stickers
  };
})();
