/// Duas and adhkar shown in the app (offline): Arabic, transliteration,
/// English meaning and how many times it is said.
library;

enum DuaGroup { morningEvening, afterPrayer, daily, ramadan }

class Dua {
  const Dua(
    this.group,
    this.title,
    this.arabic,
    this.transliteration,
    this.meaning, {
    this.times = 1,
    this.source = '',
  });

  final DuaGroup group;
  final String title, arabic, transliteration, meaning, source;
  final int times;
}

const duas = <Dua>[
  // Morning and evening.
  Dua(
    DuaGroup.morningEvening,
    'Ayat al-Kursi',
    'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
    "Allāhu lā ilāha illā huwal-ḥayyul-qayyūm, lā ta'khudhuhū sinatun wa lā nawm, lahū mā fis-samāwāti wa mā fil-arḍ, man dhal-ladhī yashfa'u 'indahū illā bi-idhnih, ya'lamu mā bayna aydīhim wa mā khalfahum, wa lā yuḥīṭūna bi-shay'in min 'ilmihī illā bimā shā', wasi'a kursiyyuhus-samāwāti wal-arḍ, wa lā ya'ūduhū ḥifẓuhumā, wa huwal-'aliyyul-'aẓīm.",
    'Allah – there is no god but Him, the Ever-Living, the Sustainer of all. Neither drowsiness nor sleep overtakes Him. To Him belongs all that is in the heavens and the earth. Who can intercede with Him except by His permission? He knows what is before them and what is behind them, and they encompass nothing of His knowledge except what He wills. His Kursi extends over the heavens and the earth, and guarding them does not tire Him. He is the Most High, the Most Great.',
    source: 'Al-Baqarah 2:255',
  ),
  Dua(
    DuaGroup.morningEvening,
    'Morning',
    'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
    "Aṣbaḥnā wa aṣbaḥal-mulku lillāh, wal-ḥamdu lillāh, lā ilāha illallāhu waḥdahū lā sharīka lah, lahul-mulku wa lahul-ḥamd, wa huwa 'alā kulli shay'in qadīr.",
    'We have entered the morning and the whole kingdom belongs to Allah. Praise is for Allah. There is no god but Allah alone, without partner; His is the kingdom and His is the praise, and He has power over all things.',
    source: 'Muslim',
  ),
  Dua(
    DuaGroup.morningEvening,
    'Evening',
    'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
    "Amsaynā wa amsal-mulku lillāh, wal-ḥamdu lillāh, lā ilāha illallāhu waḥdahū lā sharīka lah, lahul-mulku wa lahul-ḥamd, wa huwa 'alā kulli shay'in qadīr.",
    'We have entered the evening and the whole kingdom belongs to Allah. Praise is for Allah. There is no god but Allah alone, without partner; His is the kingdom and His is the praise, and He has power over all things.',
    source: 'Muslim',
  ),
  Dua(
    DuaGroup.morningEvening,
    'Protection',
    'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
    "Bismillāhil-ladhī lā yaḍurru ma'asmihī shay'un fil-arḍi wa lā fis-samā', wa huwas-samī'ul-'alīm.",
    'In the name of Allah, with whose name nothing on earth or in the heaven can cause harm, and He is the All-Hearing, the All-Knowing.',
    times: 3,
    source: 'Abu Dawud, Tirmidhi',
  ),
  Dua(
    DuaGroup.morningEvening,
    'Sayyid al-Istighfar',
    'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَٰهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَىٰ عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ',
    "Allāhumma anta rabbī lā ilāha illā ant, khalaqtanī wa ana 'abduk, wa ana 'alā 'ahdika wa wa'dika mastaṭa't, a'ūdhu bika min sharri mā ṣana't, abū'u laka bi-ni'matika 'alayya, wa abū'u bi-dhanbī faghfir lī, fa-innahū lā yaghfirudh-dhunūba illā ant.",
    'O Allah, You are my Lord; there is no god but You. You created me and I am Your servant, and I keep Your covenant and promise as best I can. I seek refuge in You from the evil I have done. I acknowledge Your favour upon me and I acknowledge my sin, so forgive me, for none forgives sins but You.',
    source: 'Bukhari',
  ),
  Dua(
    DuaGroup.morningEvening,
    'Trust in Allah',
    'حَسْبِيَ اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
    "Ḥasbiyallāhu lā ilāha illā huwa 'alayhi tawakkaltu wa huwa rabbul-'arshil-'aẓīm.",
    'Allah is sufficient for me; there is no god but Him. In Him I put my trust, and He is the Lord of the Mighty Throne.',
    times: 7,
    source: 'At-Tawbah 9:129',
  ),
  Dua(
    DuaGroup.morningEvening,
    'Pleased with Allah',
    'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ ﷺ نَبِيًّا',
    "Raḍītu billāhi rabbā, wa bil-islāmi dīnā, wa bi-Muḥammadin ṣallallāhu 'alayhi wa sallama nabiyyā.",
    'I am pleased with Allah as my Lord, with Islam as my religion and with Muhammad ﷺ as my Prophet.',
    times: 3,
    source: 'Abu Dawud',
  ),

  // After the prayer.
  Dua(
    DuaGroup.afterPrayer,
    'Seeking forgiveness',
    'أَسْتَغْفِرُ اللَّهَ',
    'Astaghfirullāh.',
    'I seek the forgiveness of Allah.',
    times: 3,
    source: 'Muslim',
  ),
  Dua(
    DuaGroup.afterPrayer,
    'Peace',
    'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
    'Allāhumma antas-salāmu wa minkas-salām, tabārakta yā dhal-jalāli wal-ikrām.',
    'O Allah, You are Peace and from You is peace. Blessed are You, O Owner of majesty and honour.',
    source: 'Muslim',
  ),
  Dua(
    DuaGroup.afterPrayer,
    'SubhanAllah',
    'سُبْحَانَ اللَّهِ',
    'Subḥānallāh.',
    'Glory be to Allah.',
    times: 33,
    source: 'Muslim',
  ),
  Dua(
    DuaGroup.afterPrayer,
    'Alhamdulillah',
    'الْحَمْدُ لِلَّهِ',
    'Al-ḥamdu lillāh.',
    'All praise is for Allah.',
    times: 33,
    source: 'Muslim',
  ),
  Dua(
    DuaGroup.afterPrayer,
    'Allahu Akbar',
    'اللَّهُ أَكْبَرُ',
    'Allāhu akbar.',
    'Allah is the Greatest.',
    times: 34,
    source: 'Muslim',
  ),
  Dua(
    DuaGroup.afterPrayer,
    'Tawhid',
    'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
    "Lā ilāha illallāhu waḥdahū lā sharīka lah, lahul-mulku wa lahul-ḥamd, wa huwa 'alā kulli shay'in qadīr.",
    'There is no god but Allah alone, without partner. His is the kingdom and His is the praise, and He has power over all things.',
    source: 'Muslim',
  ),
  Dua(
    DuaGroup.afterPrayer,
    'Good in both worlds',
    'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    "Rabbanā ātinā fid-dunyā ḥasanatan wa fil-ākhirati ḥasanatan wa qinā 'adhāban-nār.",
    'Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.',
    source: 'Al-Baqarah 2:201',
  ),

  // Daily.
  Dua(
    DuaGroup.daily,
    'After the Azan',
    'اللَّهُمَّ رَبَّ هَٰذِهِ الدَّعْوَةِ التَّامَّةِ، وَالصَّلَاةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذِي وَعَدْتَهُ',
    "Allāhumma rabba hādhihid-da'watit-tāmmah, waṣ-ṣalātil-qā'imah, āti Muḥammadanil-wasīlata wal-faḍīlah, wab'athhu maqāman maḥmūdanil-ladhī wa'adtah.",
    'O Allah, Lord of this perfect call and of the prayer to be established, grant Muhammad the intercession and the excellence, and raise him to the praised station You promised him.',
    source: 'Bukhari',
  ),
  Dua(
    DuaGroup.daily,
    'Entering the masjid',
    'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
    'Allāhummaftaḥ lī abwāba raḥmatik.',
    'O Allah, open for me the doors of Your mercy.',
    source: 'Muslim',
  ),
  Dua(
    DuaGroup.daily,
    'Leaving the masjid',
    'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
    "Allāhumma innī as'aluka min faḍlik.",
    'O Allah, I ask You of Your bounty.',
    source: 'Muslim',
  ),
  Dua(
    DuaGroup.daily,
    'Leaving home',
    'بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    "Bismillāh, tawakkaltu 'alallāh, wa lā ḥawla wa lā quwwata illā billāh.",
    'In the name of Allah. I put my trust in Allah, and there is no power nor might except with Allah.',
    source: 'Abu Dawud, Tirmidhi',
  ),
  Dua(
    DuaGroup.daily,
    'Before eating',
    'بِسْمِ اللَّهِ',
    'Bismillāh.',
    'In the name of Allah.',
    source: 'Abu Dawud, Tirmidhi',
  ),
  Dua(
    DuaGroup.daily,
    'After eating',
    'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَٰذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
    "Al-ḥamdu lillāhil-ladhī aṭ'amanī hādhā wa razaqanīhi min ghayri ḥawlin minnī wa lā quwwah.",
    'Praise is for Allah who fed me this and provided it for me without any might or power from me.',
    source: 'Abu Dawud, Tirmidhi',
  ),
  Dua(
    DuaGroup.daily,
    'Before sleeping',
    'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
    'Bismika Allāhumma amūtu wa aḥyā.',
    'In Your name, O Allah, I die and I live.',
    source: 'Bukhari',
  ),
  Dua(
    DuaGroup.daily,
    'On waking up',
    'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
    "Al-ḥamdu lillāhil-ladhī aḥyānā ba'da mā amātanā wa ilayhin-nushūr.",
    'Praise is for Allah who gave us life after He caused us to die, and to Him is the return.',
    source: 'Bukhari',
  ),

  // Ramadan.
  Dua(
    DuaGroup.ramadan,
    'Breaking the fast',
    'ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ، وَثَبَتَ الْأَجْرُ إِنْ شَاءَ اللَّهُ',
    "Dhahabaẓ-ẓama'u wabtallatil-'urūqu wa thabatal-ajru in shā' Allāh.",
    'The thirst has gone, the veins are moistened, and the reward is certain, if Allah wills.',
    source: 'Abu Dawud',
  ),
  Dua(
    DuaGroup.ramadan,
    'Laylat al-Qadr',
    'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
    "Allāhumma innaka 'afuwwun tuḥibbul-'afwa fa'fu 'annī.",
    'O Allah, You are the Pardoner and You love to pardon, so pardon me.',
    source: 'Tirmidhi',
  ),
];
