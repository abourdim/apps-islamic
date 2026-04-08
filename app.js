/* ============================================================
   Workshop-Diy Kids Hub — app.js
   i18n (EN/FR/AR) · 7 Themes · Fun · Accessible
   ============================================================ */

const USER = "abourdim";
const VIEW = (repo) => `https://${USER}.github.io/${repo}/`;

/* ──────── i18n STRINGS ──────── */
const I18N = {
  en: {
    subtitle: "Islamic apps, Arabic tools & sacred books 🌙",
    search_placeholder: 'Search apps\u2026 (try "quran" or "ghazali")',
    filter_all: "All",
    filter_arabic: "Arabic & Islamic", filter_learning: "Books & Learning",
    filter_ai: "AI", filter_tools: "Tools",
    lib_ghazali: "Al-Ghazali", lib_messiri: "El-Messiri", lib_ulwan: "Ulwan",
    shuffle: "Shuffle",
    no_results: "Nothing found. Try another keyword 🔍",
    footer: 'Built by <strong>Workshop-Diy</strong> \u2022 Islamic Apps Collection',
    github: "GitHub ↗", view_btn: "Launch ▶",
    badge_new: "NEW", badge_popular: "Popular", badge_hub: "Hub", badge_stable: "Stable",
    status_beta: "Beta", status_dev: "Dev", status_offline: "Offline",
    status_filter_all: "All", status_filter_stable: "Stable", status_filter_beta: "Beta", status_filter_dev: "Dev", status_filter_offline: "Offline",
    stats_apps: "apps", stats_cats: "categories", stats_made: "Built with 🔥",
    greeting_morning: "Rise & grind, builder! ☀️",
    greeting_afternoon: "What's up, hacker! 🌤️",
    greeting_evening: "Night mode activated! 🌙",
    explorer_prefix: "You've explored",
    explorer_suffix: "apps!",
    explorer_title_0: "Start building! 🔰",
    explorer_title_5: "Rookie Hacker! 🎮",
    explorer_title_10: "Tech Explorer! 🚀",
    explorer_title_15: "Elite Coder! 💻",
    explorer_title_22: "Workshop Legend! 🏆",
    tooltips: [
      "This one's sick! 🔥", "Try me if you dare! 💀", "Top tier! 👑",
      "Insane build! ⚡", "Smash that button! 💥", "Beep boop! 🤖",
      "Power unlocked! 🔓", "You'll crush this! 💪"
    ],
    jokes: [
      "Why do programmers prefer dark mode? Because light attracts bugs! 🪲",
      "What's a robot's favorite snack? Micro-chips! 🍟",
      "Why was the computer cold? It left its Windows open! 🥶",
      "What's a hacker's favorite season? Phishing season! 🎣",
      "Why do Java devs wear glasses? They can't C#! 🤓",
      "How does a computer get drunk? It takes screenshots! 📸"
    ]
  },
  fr: {
    subtitle: "Apps islamiques, outils arabes & livres sacrés 🌙",
    search_placeholder: "Chercher… (essaie « coran » ou « ghazali »)",
    filter_all: "Tous",
    filter_arabic: "Arabe & Islamique", filter_learning: "Livres & Apprentissage",
    filter_ai: "IA", filter_tools: "Outils",
    lib_ghazali: "Al-Ghazali", lib_messiri: "El-Messiri", lib_ulwan: "Ulwan",
    shuffle: "Mélanger",
    no_results: "Rien trouvé. Essaie un autre mot 🔍",
    footer: "Construit par <strong>Workshop-Diy</strong> • Collection Apps Islamiques",
    github: "GitHub ↗", view_btn: "Lancer ▶",
    badge_new: "NOUVEAU", badge_popular: "Populaire", badge_hub: "Hub", badge_stable: "Stable",
    status_beta: "Bêta", status_dev: "Dev", status_offline: "Hors ligne",
    status_filter_all: "Tous", status_filter_stable: "Stable", status_filter_beta: "Bêta", status_filter_dev: "Dev", status_filter_offline: "Hors ligne",
    stats_apps: "apps", stats_cats: "catégories", stats_made: "Construit avec 🔥",
    greeting_morning: "Debout, builder ! ☀️",
    greeting_afternoon: "Salut, hacker ! 🌤️",
    greeting_evening: "Mode nuit activé ! 🌙",
    explorer_prefix: "Tu as exploré",
    explorer_suffix: "apps !",
    explorer_title_0: "Commence à builder ! 🔰",
    explorer_title_5: "Hacker débutant ! 🎮",
    explorer_title_10: "Explorateur tech ! 🚀",
    explorer_title_15: "Codeur d'élite ! 💻",
    explorer_title_22: "Légende Workshop ! 🏆",
    tooltips: [
      "Celui-ci est dingue ! 🔥", "Essaie si tu oses ! 💀", "Top niveau ! 👑",
      "Build insane ! ⚡", "Clique ! 💥", "Bip boup ! 🤖",
      "Pouvoir débloqué ! 🔓", "Tu vas gérer ! 💪"
    ],
    jokes: [
      "Pourquoi les devs préfèrent le mode sombre ? La lumière attire les bugs ! 🪲",
      "Quel est le goûter préféré d'un robot ? Des micro-chips ! 🍟",
      "Pourquoi l'ordinateur avait froid ? Il avait laissé ses fenêtres ouvertes ! 🥶",
      "Quelle est la saison préférée d'un hacker ? La saison du phishing ! 🎣",
      "Pourquoi les devs Java portent des lunettes ? Ils peuvent pas C# ! 🤓",
      "Comment un ordinateur s'enivre ? Il prend des captures d'écran ! 📸"
    ]
  },
  ar: {
    subtitle: "تطبيقات إسلامية، أدوات عربية وكتب مقدسة 🌙",
    search_placeholder: "بحث عن تطبيقات… (جرّب «قرآن» أو «غزالي»)",
    filter_all: "الكل",
    filter_arabic: "عربي وإسلامي", filter_learning: "كتب وتعلّم",
    filter_ai: "ذكاء", filter_tools: "أدوات",
    lib_ghazali: "الغزالي", lib_messiri: "المسيري", lib_ulwan: "العلوان",
    shuffle: "خلط",
    no_results: "لم يتم العثور على شيء. جرّب كلمة أخرى 🔍",
    footer: "بناه <strong>Workshop-Diy</strong> • مجموعة التطبيقات الإسلامية",
    github: "GitHub ↗", view_btn: "إطلاق ▶",
    badge_new: "جديد", badge_popular: "شائع", badge_hub: "مركز", badge_stable: "مستقر",
    status_beta: "تجريبي", status_dev: "تطوير", status_offline: "غير متصل",
    status_filter_all: "الكل", status_filter_stable: "مستقر", status_filter_beta: "تجريبي", status_filter_dev: "تطوير", status_filter_offline: "غير متصل",
    stats_apps: "تطبيق", stats_cats: "فئات", stats_made: "بُني بـ 🔥",
    greeting_morning: "صباح الخير يا بنّاء! ☀️",
    greeting_afternoon: "أهلاً يا هاكر! 🌤️",
    greeting_evening: "الوضع الليلي مفعّل! 🌙",
    explorer_prefix: "لقد استكشفت",
    explorer_suffix: "تطبيقات!",
    explorer_title_0: "ابدأ البناء! 🔰",
    explorer_title_5: "هاكر مبتدئ! 🎮",
    explorer_title_10: "مستكشف تقني! 🚀",
    explorer_title_15: "مبرمج نخبة! 💻",
    explorer_title_22: "أسطورة الورشة! 🏆",
    tooltips: [
      "هذا جنوني! 🔥", "جرّب إن كنت تجرؤ! 💀", "أعلى مستوى! 👑",
      "بناء خرافي! ⚡", "اضغط! 💥", "بيب بوب! 🤖",
      "قوة مفتوحة! 🔓", "ستسحقه! 💪"
    ],
    jokes: [
      "لماذا يفضل المبرمجون الوضع المظلم؟ لأن الضوء يجذب الحشرات! 🪲",
      "ما هي وجبة الروبوت المفضلة؟ رقائق صغيرة! 🍟",
      "لماذا كان الكمبيوتر باردًا؟ لأنه ترك نوافذه مفتوحة! 🥶",
      "ما هو الموسم المفضل للهاكر؟ موسم التصيّد! 🎣",
      "لماذا مطورو جافا يرتدون نظارات؟ لأنهم لا يستطيعون C#! 🤓",
      "كيف يسكر الكمبيوتر؟ يأخذ لقطات شاشة! 📸"
    ]
  }
};

/* ──────── LOAD APP DATA ──────── */
let APPS = [];
let LANG = localStorage.getItem("wdiy-lang") || "en";
let THEME = localStorage.getItem("wdiy-theme") || "islamic";
let SOUND = localStorage.getItem("wdiy-sound") !== "off";
let FAVS = JSON.parse(localStorage.getItem("wdiy-favs") || "[]");
let EXPLORED = JSON.parse(localStorage.getItem("wdiy-explored") || "[]");
let VIEW_MODE = localStorage.getItem("wdiy-view") || "grid";
let logoClicks = 0;

/* ──────── DOM REFS ──────── */
const grid = document.getElementById("grid");
const empty = document.getElementById("empty");
const q = document.getElementById("q");
const clearBtn = document.getElementById("clear-search");
const filterButtons = [...document.querySelectorAll(".mode-btn")];
const statusFilterButtons = [...document.querySelectorAll(".st-tog")];
const langButtons = [...document.querySelectorAll(".lang-btn")];
const themeButtons = [...document.querySelectorAll(".theme-btn")];
const viewButtons = [...document.querySelectorAll(".view-btn")];
const soundToggle = document.getElementById("sound-toggle");
const scrollTopBtn = document.getElementById("scroll-top");
const shuffleBtn = document.getElementById("shuffle-btn");
const greetingBar = document.getElementById("greeting-bar");
const statsBar = document.getElementById("stats-bar");
const jokeBar = document.getElementById("joke-bar");
const explorerBar = document.getElementById("explorer-bar");
const siteLogo = document.getElementById("site-logo");
const particleCanvas = document.getElementById("particles");
const confettiCanvas = document.getElementById("confetti-canvas");

let currentFilter = "";
let currentStatusFilter = "";
let currentLibrary = "";

/* ============================================================
   INLINE APP DATA
   status: "stable" (default) | "beta" | "dev" | "offline"
   ============================================================ */
const INLINE_APPS = [
  { name:"al-dawah-fi-al-qarn", emoji:"📢", categories:["learning"], badge:"dev", status:"beta", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"📢 Islamic Dawah This Century — الدعوة الإسلامية في القرن الحالي", fr:"Al Dawah Fi Al Qarn — application éducative islamique trilingue.", ar:"الدعوة الإسلامية في القرن الحالي" }},
  { name:"al-fasad-al-siyasi", emoji:"🏛", categories:["learning"], badge:"dev", status:"beta", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🏛️ Political Corruption — الفساد السياسي", fr:"Al Fasad Al Siyasi — application éducative islamique trilingue.", ar:"الفساد السياسي" }},
  { name:"al-ghazali-library", emoji:"📚", categories:["learning"], badge:"new", status:"dev", visibility:"public", tags:["HTML", "Islamic", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"📚 Al-Ghazali Interactive Library", fr:"Al Ghazali Library — application éducative islamique trilingue.", ar:"مكتبة الغزالي التفاعلية" }},
  { name:"al-ghazw-al-thaqafi", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"الغزو الثقافي يمتد في فراغنا — Cultural Invasion Spreads into Our Void", fr:"Al Ghazw Al Thaqafi — application éducative islamique trilingue.", ar:"الغزو الثقافي يمتد في فراغنا" }},
  { name:"al-ghirbal", emoji:"⛔", categories:["learning"], badge:"dev", status:"beta", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"⛔ The Sieve — الغربال", fr:"Al Ghirbal — application éducative islamique trilingue.", ar:"الغربال" }},
  { name:"al-hayat-al-ula", emoji:"🌅", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🌅 The First Life — الحياة الأولى", fr:"Al Hayat Al Ula — application éducative islamique trilingue.", ar:"الحياة الأولى" }},
  { name:"al-islam-al-muftara-alayh", emoji:"⚖", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"⚖️ Islam Falsely Accused — الإسلام المفترى عليه", fr:"Al Islam Al Muftara Alayh — application éducative islamique trilingue.", ar:"الإسلام المفترى عليه" }},
  { name:"al-islam-fi-wajh-al-zahf", emoji:"🔴", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🔴 Islam Facing the Red Tide — الإسلام في وجه الزحف الأحمر", fr:"Al Islam Fi Wajh Al Zahf — application éducative islamique trilingue.", ar:"الإسلام في وجه الزحف الأحمر" }},
  { name:"al-islam-wa-qanun", emoji:"⚖", categories:["learning"], badge:"dev", status:"beta", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"⚖️ Islam & Personal Status Law — الإسلام وقانون الأحوال الشخصية", fr:"Al Islam Wa Qanun — application éducative islamique trilingue.", ar:"الإسلام وقانون الأحوال الشخصية" }},
  { name:"al-islam-wal-awda-al-iqtisadiyah", emoji:"💰", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"💰 Islam and Economic Affairs — الإسلام والأوضاع الاقتصادية", fr:"Al Islam Wal Awda Al Iqtisadiyah — application éducative islamique trilingue.", ar:"الإسلام والأوضاع الاقتصادية" }},
  { name:"al-islam-wal-istibdad", emoji:"⚖", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"⚖️ Islam & Political Tyranny — الإسلام والاستبداد السياسي", fr:"Al Islam Wal Istibdad — application éducative islamique trilingue.", ar:"الإسلام والاستبداد السياسي" }},
  { name:"al-islam-wal-manahij", emoji:"🟠", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🟠 Islam and Socialist Systems — الإسلام والمناهج الاشتراكية", fr:"Al Islam Wal Manahij — application éducative islamique trilingue.", ar:"الإسلام والمناهج الاشتراكية" }},
  { name:"al-istimar", emoji:"🏴", categories:["learning"], badge:"dev", status:"beta", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🏴 Colonialism: Grudges & Greed — الاستعمار أحقاد وأطماع", fr:"Al Istimar — application éducative islamique trilingue.", ar:"الاستعمار أحقاد وأطماع" }},
  { name:"al-janib-al-atifi", emoji:"💗", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"💗 The Emotional Side of Islam — الجانب العاطفي من الإسلام", fr:"Al Janib Al Atifi — application éducative islamique trilingue.", ar:"الجانب العاطفي من الإسلام" }},
  { name:"al-mahawir-al-khamsah", emoji:"🔥", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🔥 The Five Axes of the Quran — المحاور الخمسة للقرآن الكريم", fr:"Al Mahawir Al Khamsah — application éducative islamique trilingue.", ar:"المحاور الخمسة للقرآن الكريم" }},
  { name:"al-miraat", emoji:"🪞", categories:["learning"], badge:"dev", status:"beta", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🪞 The Mirror — المرآة", fr:"Al Miraat — application éducative islamique trilingue.", ar:"المرآة" }},
  { name:"al-saaiqa", emoji:"⛈", categories:["learning"], badge:"dev", status:"beta", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"⛈️ The Thunderbolt — الصاعقة", fr:"Al Saaiqa — application éducative islamique trilingue.", ar:"الصاعقة" }},
  { name:"al-sunnah-al-nabawiyah", emoji:"📜", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"📜 Prophetic Sunnah — السنة النبوية بين أهل الفقه وأهل الحديث", fr:"Al Sunnah Al Nabawiyah — application éducative islamique trilingue.", ar:"السنة النبوية بين أهل الفقه وأهل الحديث" }},
  { name:"al-taassub-wal-tasamuh", emoji:"🕊", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🕊️ Fanaticism & Tolerance — التعصب والتسامح", fr:"Al Taassub Wal Tasamuh — application éducative islamique trilingue.", ar:"التعصب والتسامح" }},
  { name:"amthal", emoji:"🕌", categories:["arabic"], badge:"new", status:"dev", visibility:"public", tags:["Islamic", "arabic"],
    desc:{ en:"Arabic proverbs and wisdom collection — interactive trilingual app.", fr:"Collection de proverbes et sagesse arabes — application trilingue interactive.", ar:"مجموعة أمثال وحكم عربية — تطبيق تفاعلي ثلاثي اللغات." }},
  { name:"aqidat-al-muslim", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🕌 عقيدة المسلم — The Muslim's Creed", fr:"Aqidat Al Muslim — application éducative islamique trilingue.", ar:"عقيدة المسلم" }},
  { name:"ayqidh-taqatak", emoji:"⚡", categories:["learning"], badge:"dev", status:"beta", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"⚡ Awaken Your Energy — أيقظ طاقتك", fr:"Ayqidh Taqatak — application éducative islamique trilingue.", ar:"أيقظ طاقتك" }},
  { name:"builders-of-light", emoji:"💫", categories:["learning", "arabic", "classroom"], badge:"new", status:"stable", visibility:"public", tags:["BLE", "TTS", "STT", "WLED", "game", "HTML", "LED", "kids"],
    desc:{ en:"Version 1.0 · Single-file HTML app · 830 KB · 139 sections · 434+ functions · 3 languages · Zero dependencies", fr:"Builders Of Light — explorez et expérimentez !", ar:"Builders Of Light — استكشف وجرّب!" }},
  { name:"difaa-al-aqidah", emoji:"🛡", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🛡️ Defense of Creed — دفاع عن العقيدة", fr:"Difaa Al Aqidah — application éducative islamique trilingue.", ar:"دفاع عن العقيدة" }},
  { name:"dustur-al-wahdah", emoji:"🤝", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🤝 Charter of Cultural Unity — دستور الوحدة الثقافية بين المسلمين", fr:"Dustur Al Wahdah — application éducative islamique trilingue.", ar:"دستور الوحدة الثقافية بين المسلمين" }},
  { name:"eid", emoji:"🌙", categories:["arabic", "learning"], badge:"new", status:"stable", visibility:"public", tags:["Eid", "Islamic", "celebration", "kids"],
    desc:{ en:"Eid celebration app for kids.", fr:"Application de célébration de l'Aïd pour enfants.", ar:"تطبيق احتفالات العيد للأطفال." }},
  { name:"fan-al-dhikr", emoji:"🤲", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🤲 The Art of Dhikr & Dua — فن الذكر والدعاء", fr:"Fan Al Dhikr — application éducative islamique trilingue.", ar:"فن الذكر والدعاء" }},
  { name:"fi-mawkib-al-dawa", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"في موكب الدعوة — In the Procession of Dawah", fr:"Fi Mawkib Al Dawa — application éducative islamique trilingue.", ar:"في موكب الدعوة" }},
  { name:"fiqh-al-sirah", emoji:"📜", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"📜 فقه السيرة — Fiqh Al-Sirah", fr:"Fiqh Al Sirah — application éducative islamique trilingue.", ar:"فقه السيرة" }},
  { name:"golden-age", emoji:"🏛️", categories:["learning", "arabic", "classroom"], badge:"stable", status:"stable", visibility:"public", tags:["Islamic-history", "Golden-Age", "interactive", "game", "kids"],
    desc:{ en:"An interactive educational journey through the Islamic Golden Age — explore algebra, medicine, optics, engineering and more.", fr:"Voyage éducatif interactif à travers l'Âge d'Or islamique — explorez l'algèbre, la médecine, l'optique, l'ingénierie et plus encore.", ar:"رحلة تعليمية تفاعلية عبر العصر الذهبي الإسلامي — استكشف الجبر والطب والبصريات والهندسة والمزيد." }},
  { name:"hajj-guide", emoji:"🕋", categories:["arabic"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "node", "web-app"],
    desc:{ en:"🕋 Guide Complet du Hajj 2026", fr:"Guide interactif complet pour le pèlerinage du Hajj 2026 — trilingue Français / عربي / English.", ar:"وَأَذِّن فِي النَّاسِ بِالْحَجِّ يَأْتُوكَ رِجَالًا وَعَلَىٰ كُلِّ ضَامِرٍ يَأْتِينَ مِن كُلِّ فَجٍّ عَمِيقٍ" }},
  { name:"halqa", emoji:"🕌", categories:["arabic"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"],
    desc:{ en:"Halqa — Islamic study circle management app.", fr:"Halqa — application de gestion de cercles d'étude islamiques.", ar:"حلقة — تطبيق إدارة حلقات الدراسة الإسلامية." }},
  { name:"haqiqat-al-qawmiyah", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"حقيقة القومية العربية — Arab Nationalism: Truth & Myth", fr:"Haqiqat Al Qawmiyah — application éducative islamique trilingue.", ar:"حقيقة القومية العربية" }},
  { name:"hasad-al-ghurur", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"حصاد الغرور — The Harvest of Arrogance — La Moisson de l'Orgueil", fr:"Hasad Al Ghurur — application éducative islamique trilingue.", ar:"حصاد الغرور" }},
  { name:"humum-daiya", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"هموم داعية — Concerns of a Preacher", fr:"Humum Daiya — application éducative islamique trilingue.", ar:"هموم داعية" }},
  { name:"huquq-al-insan", emoji:"⚖", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"⚖️ Human Rights — حقوق الإنسان", fr:"Huquq Al Insan — application éducative islamique trilingue.", ar:"حقوق الإنسان" }},
  { name:"iyadat-al-ummah", emoji:"🩺", categories:["learning"], badge:"dev", status:"beta", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🩺 The Ummah Clinic — عيادة الأمة", fr:"Iyadat Al Ummah — application éducative islamique trilingue.", ar:"عيادة الأمة" }},
  { name:"jaddid-hayatak", emoji:"🌅", categories:["learning"], badge:"dev", status:"beta", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🌅 Renew Your Life — جدد حياتك", fr:"Jaddid Hayatak — application éducative islamique trilingue.", ar:"جدد حياتك" }},
  { name:"jihad-al-dawah", emoji:"🌿", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🌿 Jihad of Dawah — جهاد الدعوة بين عجز الداخل وكيد الخارج", fr:"Jihad Al Dawah — application éducative islamique trilingue.", ar:"جهاد الدعوة بين عجز الداخل وكيد الخارج" }},
  { name:"kayfa-nafham", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"كيف نفهم الإسلام — How We Understand Islam", fr:"Kayfa Nafham — application éducative islamique trilingue.", ar:"كيف نفهم الإسلام" }},
  { name:"kayfa-nataamal-maa-al-quran", emoji:"📖", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"📖 How to Deal with the Quran — كيف نتعامل مع القرآن", fr:"Kayfa Nataamal Maa Al Quran — application éducative islamique trilingue.", ar:"كيف نتعامل مع القرآن" }},
  { name:"khuluq-al-muslim", emoji:"🌟", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🌟 خلق المسلم — The Muslim's Character", fr:"Khuluq Al Muslim — application éducative islamique trilingue.", ar:"خلق المسلم" }},
  { name:"khutab-al-ghazali", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"خطب الغزالي — Ghazali's Sermons", fr:"Khutab Al Ghazali — application éducative islamique trilingue.", ar:"خطب الغزالي" }},
  { name:"kunuz-min-al-sunnah", emoji:"✨", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"✨ Treasures from the Sunnah — كنوز من السنة", fr:"Kunuz Min Al Sunnah — application éducative islamique trilingue.", ar:"كنوز من السنة" }},
  { name:"luminaries-of-islam", emoji:"🌟", categories:["learning", "arabic", "ai"], badge:"new", status:"stable", visibility:"public", tags:["BLE", "TTS", "STT", "WLED", "game", "git", "linux", "security", "HTML", "robot", "LED", "kids"],
    desc:{ en:"Interactive trilingual app about 12 Muslim scientists of the Islamic Golden Age.", fr:"Application trilingue interactive sur 12 scientifiques musulmans de l'Âge d'Or islamique.", ar:"تطبيق تفاعلي ثلاثي اللغات عن 12 عالماً مسلماً من العصر الذهبي الإسلامي." }},
  { name:"maa-allah", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🕌 With God — مع الله", fr:"Maa Allah — application éducative islamique trilingue.", ar:"مع الله" }},
  { name:"marakah-al-mushaf", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"معركة المصحف — Battle of the Quran", fr:"Marakah Al Mushaf — application éducative islamique trilingue.", ar:"معركة المصحف" }},
  { name:"miat-sual", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"مائة سؤال عن الإسلام — 100 Questions About Islam", fr:"Miat Sual — application éducative islamique trilingue.", ar:"مائة سؤال عن الإسلام" }},
  { name:"min-huna-nalam", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"من هنا نعلم — This Is Where We Learn", fr:"Min Huna Nalam — application éducative islamique trilingue.", ar:"من هنا نعلم" }},
  { name:"mushkilat", emoji:"📖", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "PWA", "developer-tool", "web-app"], library:"ghazali",
    desc:{ en:"📖 مشكلات في طريق الحياة الإسلامية — Problems on the Islamic Path", fr:"Mushkilat — application Workshop-DIY.", ar:"مشكلات في طريق الحياة الإسلامية" }},
  { name:"nahwa-tafsir-mawdui", emoji:"🌊", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🌊 Toward Thematic Quran Interpretation — نحو تفسير موضوعي لسور القرآن", fr:"Nahwa Tafsir Mawdui — application éducative islamique trilingue.", ar:"نحو تفسير موضوعي لسور القرآن" }},
  { name:"nazarat-fi-al-quran", emoji:"📖", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"📖 Insights into the Quran — نظرات في القرآن", fr:"Nazarat Fi Al Quran — application éducative islamique trilingue.", ar:"نظرات في القرآن" }},
  { name:"nusuk", emoji:"🕋", categories:["arabic", "learning"], badge:"new", status:"stable", visibility:"public", tags:["Hajj", "Islamic", "pilgrimage", "guide"],
    desc:{ en:"Interactive Hajj and Umrah guide.", fr:"Guide interactif du Hajj et de l'Omra.", ar:"دليل تفاعلي للحج والعمرة." }},
  { name:"ops-catalog-islamic-kids-apps", emoji:"☪️", categories:["arabic", "learning", "classroom"], badge:"popular", status:"stable", visibility:"public", tags:["Islamic", "kids", "educational", "apps"],
    desc:{ en:"Interactive Islamic educational apps for Muslim kids.", fr:"Applications islamiques éducatives pour enfants musulmans.", ar:"تطبيقات إسلامية تعليمية تفاعلية للأطفال المسلمين." }},
  { name:"ops-catalog-islamic-kids-quizzes", emoji:"❓", categories:["arabic", "learning", "classroom"], badge:"popular", status:"stable", visibility:"public", tags:["Islamic", "quizzes", "kids", "education"],
    desc:{ en:"1,091 Islamic educational quizzes for Muslim kids.", fr:"1 091 quiz islamiques éducatifs pour enfants.", ar:"1091 اختبار إسلامي تعليمي للأطفال المسلمين." }},
  { name:"qadaya-al-marah", emoji:"🌹", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"🌹 Women's Issues — قضايا المرأة", fr:"Qadaya Al Marah — application éducative islamique trilingue.", ar:"قضايا المرأة" }},
  { name:"qadhaaif-al-haqq", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"قذائف الحق — Missiles of Truth", fr:"Qadhaaif Al Haqq — application éducative islamique trilingue.", ar:"قذائف الحق" }},
  { name:"rakaiz-al-iman", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"Pillars of Faith — ركائز الإيمان بين العقل والقلب", fr:"Rakaiz Al Iman — application éducative islamique trilingue.", ar:"ركائز الإيمان بين العقل والقلب" }},
  { name:"ramadan-wal-siyam", emoji:"📖", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"📖 رمضان والصيام — Ramadan and Fasting", fr:"Ramadan Wal Siyam — application éducative islamique trilingue.", ar:"رمضان والصيام" }},
  { name:"rihlati-fikriyah", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "arabic", "web-app"], library:"messiri",
    desc:{ en:"رحلتي الفكرية — عبد الوهاب المسيري", fr:"Rihlati Fikriyah — application éducative islamique trilingue.", ar:"Rihlati Fikriyah — تطبيق تعليمي إسلامي تفاعلي ثلاثي اللغات." }},
  { name:"salat-times", emoji:"🕌", categories:["microbit", "arabic"], badge:"new", status:"dev", visibility:"public", tags:["prayer-times", "adhan", "micro:bit", "BLE", "PWA", "Islamic"],
    desc:{ en:"A single-file Islamic prayer times web app with micro:bit V2 Adhan Lantern support.", fr:"Application web de horaires de prière islamique en fichier unique avec support micro:bit V2 Adhan Lantern.", ar:"تطبيق ويب لمواقيت الصلاة الإسلامية في ملف واحد مع دعم فانوس الأذان micro:bit V2." }},
  { name:"sayhah-tahdhir", emoji:"📖", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"📖 صيحة تحذير من دعاة التنصير — Warning Against Missionaries", fr:"Sayhah Tahdhir — application éducative islamique trilingue.", ar:"صيحة تحذير من دعاة التنصير" }},
  { name:"shahid-ala-al-asr", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"شاهد على العصر — Ghazali: Witness of the Era", fr:"Shahid Ala Al Asr — application éducative islamique trilingue.", ar:"شاهد على العصر" }},
  { name:"taamulat", emoji:"🌿", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "PWA", "developer-tool", "web-app"], library:"ghazali",
    desc:{ en:"🌿 Reflections on Religion & Life — تأملات في الدين والحياة", fr:"Taamulat — application Workshop-DIY.", ar:"تأملات في الدين والحياة" }},
  { name:"tarbiyat-al-awlad", emoji:"📖", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ulwan",
    desc:{ en:"📖 تربية الأولاد في الإسلام — Tarbiyat al-Awlad", fr:"منصة تعليمية تفاعلية ثلاثية اللغات (عربي / English / Français) مستلهمة من كتاب «تربية الأولاد في الإسلام» للشيخ عبد الله", ar:"﴿ وَالَّذِينَ يَقُولُونَ رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّق" }},
  { name:"tesbih", emoji:"📿", categories:["arabic"], badge:"new", status:"dev", visibility:"public", tags:["tasbih", "dhikr", "prayer", "counter", "PWA", "Islamic"],
    desc:{ en:"A digital tasbih (prayer bead counter) with dhikr tracking — tap to count, fully offline PWA.", fr:"Tasbih numérique (compteur de perles de prière) avec suivi du dhikr — tapez pour compter, PWA entièrement hors ligne.", ar:"تسبيح رقمي (عداد مسبحة) مع تتبع الذكر — اضغط للعدّ، تطبيق PWA يعمل بدون إنترنت." }},
  { name:"tethkir", emoji:"📔", categories:["arabic", "tools"], badge:"new", status:"dev", visibility:"public", tags:["task-manager", "notes", "encryption", "PWA", "Islamic"],
    desc:{ en:"Islamic Task Manager & Secure Notes", fr:"Gestionnaire de tâches islamique et notes sécurisées.", ar:"مدير مهام إسلامي وملاحظات مشفّرة." }},
  { name:"zalam-min-al-gharb", emoji:"🕌", categories:["learning"], badge:"stable", status:"stable", visibility:"public", tags:["HTML", "Islamic", "PWA", "arabic", "web-app"], library:"ghazali",
    desc:{ en:"ظلام من الغرب — Darkness from the West", fr:"Zalam Min Al Gharb — application éducative islamique trilingue.", ar:"ظلام من الغرب" }},
];

/* ============================================================
   INIT
   ============================================================ */
function init() {
  APPS = INLINE_APPS.map((a, i) => ({
    ...a,
    _num: i + 1,
    github: `https://github.com/${USER}/${a.name}`,
    view: VIEW(a.name)
  }));

  applyTheme(THEME);
  applyLang(LANG);
  applyViewMode(VIEW_MODE);
  updateFilterCounts();
  render();
  updateGreeting();
  updateStats();
  updateJoke();
  updateExplorer();
  initParticles();
  initListeners();
}

/* ============================================================
   i18n
   ============================================================ */
function t(key) { return (I18N[LANG] || I18N.en)[key] || (I18N.en)[key] || key; }

function applyLang(lang) {
  LANG = lang;
  localStorage.setItem("wdiy-lang", lang);
  document.documentElement.lang = lang;
  document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";
  document.documentElement.dataset.lang = lang;

  langButtons.forEach(b => b.classList.toggle("active", b.dataset.lang === lang));

  document.querySelectorAll("[data-i18n]").forEach(el => {
    const key = el.dataset.i18n;
    el.innerHTML = t(key);
  });
  document.querySelectorAll("[data-i18n-placeholder]").forEach(el => {
    el.placeholder = t(el.dataset.i18nPlaceholder);
  });

  updateGreeting();
  updateStats();
  updateJoke();
  updateExplorer();
  updateFilterCounts();
  render();
}

/* ============================================================
   THEMES
   ============================================================ */
function applyTheme(theme) {
  THEME = theme;
  localStorage.setItem("wdiy-theme", theme);
  document.documentElement.dataset.theme = theme;
  themeButtons.forEach(b => b.classList.toggle("active", b.dataset.theme === theme));
  initParticles();
}

/* ============================================================
   SOUND EFFECTS
   ============================================================ */
const AudioCtx = window.AudioContext || window.webkitAudioContext;
let audioCtx;

function playSound(type) {
  if (!SOUND) return;
  if (!audioCtx) audioCtx = new AudioCtx();
  const osc = audioCtx.createOscillator();
  const gain = audioCtx.createGain();
  osc.connect(gain);
  gain.connect(audioCtx.destination);
  gain.gain.value = 0.08;

  if (type === "pop") {
    osc.frequency.setValueAtTime(600, audioCtx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(200, audioCtx.currentTime + 0.15);
    gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.15);
    osc.start(); osc.stop(audioCtx.currentTime + 0.15);
  } else if (type === "zap") {
    osc.type = "sawtooth";
    osc.frequency.setValueAtTime(1200, audioCtx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(200, audioCtx.currentTime + 0.1);
    gain.gain.value = 0.1;
    gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.15);
    osc.start(); osc.stop(audioCtx.currentTime + 0.15);
  } else if (type === "whoosh") {
    osc.type = "sawtooth";
    osc.frequency.setValueAtTime(300, audioCtx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(80, audioCtx.currentTime + 0.25);
    gain.gain.value = 0.04;
    gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.25);
    osc.start(); osc.stop(audioCtx.currentTime + 0.25);
  } else if (type === "tada") {
    [523, 659, 784].forEach((freq, i) => {
      const o = audioCtx.createOscillator();
      const g = audioCtx.createGain();
      o.connect(g); g.connect(audioCtx.destination);
      o.frequency.value = freq;
      g.gain.value = 0.06;
      g.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.3 + i * 0.1);
      o.start(audioCtx.currentTime + i * 0.1);
      o.stop(audioCtx.currentTime + 0.3 + i * 0.1);
    });
  }
}

/* ============================================================
   PARTICLES — stars in Medina theme, circles otherwise
   ============================================================ */
let particles = [];
let animFrameId = null;

function drawStar(ctx, cx, cy, r, points, innerR) {
  ctx.beginPath();
  for (let i = 0; i < points * 2; i++) {
    const radius = i % 2 === 0 ? r : innerR;
    const angle = (Math.PI * i) / points - Math.PI / 2;
    const x = cx + Math.cos(angle) * radius;
    const y = cy + Math.sin(angle) * radius;
    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
  }
  ctx.closePath();
}

function initParticles() {
  if (animFrameId) cancelAnimationFrame(animFrameId);
  const ctx = particleCanvas.getContext("2d");
  particleCanvas.width = window.innerWidth;
  particleCanvas.height = window.innerHeight;

  const isMedina = THEME === "islamic";
  const isAlhambra = THEME === "alhambra";
  const isIznik = THEME === "iznik";
  const isZellige = THEME === "zellige";
  const isArabesque = THEME === "arabesque";
  const isIslamic = isMedina || isAlhambra || isIznik || isZellige || isArabesque;
  const color = getComputedStyle(document.documentElement).getPropertyValue('--particle-color').trim() || 'rgba(127,90,240,0.3)';
  const count = window.innerWidth < 600 ? (isIslamic ? 18 : 25) : (isIslamic ? 35 : 50);
  particles = [];

  for (let i = 0; i < count; i++) {
    particles.push({
      x: Math.random() * particleCanvas.width,
      y: Math.random() * particleCanvas.height,
      r: isIslamic ? Math.random() * 5 + 2 : Math.random() * 3 + 1,
      dx: (Math.random() - 0.5) * (isIslamic ? 0.25 : 0.5),
      dy: (Math.random() - 0.5) * (isIslamic ? 0.25 : 0.5),
      alpha: Math.random() * 0.5 + 0.2,
      rot: Math.random() * Math.PI * 2,
      dr: (Math.random() - 0.5) * (isArabesque ? 0.003 : 0.008),
      points: (isMedina || isAlhambra) ? (Math.random() > 0.4 ? 8 : 6) :
              isIznik ? (Math.random() > 0.5 ? 6 : 4) :
              isZellige ? 4 : 0,
      shape: isArabesque ? "leaf" : isZellige ? "diamond" : isIznik ? "diamond" : "star"
    });
  }

  function animate() {
    ctx.clearRect(0, 0, particleCanvas.width, particleCanvas.height);
    particles.forEach(p => {
      p.x += p.dx;
      p.y += p.dy;
      p.rot += p.dr;
      if (p.x < 0 || p.x > particleCanvas.width) p.dx *= -1;
      if (p.y < 0 || p.y > particleCanvas.height) p.dy *= -1;

      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate(p.rot);
      ctx.fillStyle = color.replace(/[\d.]+\)$/, p.alpha + ')');

      if (isMedina && p.points) {
        drawStar(ctx, 0, 0, p.r, p.points, p.r * 0.45);
        ctx.fill();
        ctx.strokeStyle = color.replace(/[\d.]+\)$/, (p.alpha * 0.5) + ')');
        ctx.lineWidth = 0.5;
        ctx.stroke();
      } else if (isAlhambra && p.points) {
        drawStar(ctx, 0, 0, p.r, p.points, p.r * 0.4);
        ctx.fill();
        ctx.strokeStyle = color.replace(/[\d.]+\)$/, (p.alpha * 0.4) + ')');
        ctx.lineWidth = 0.5;
        ctx.stroke();
      } else if ((isIznik || isZellige) && p.points) {
        // Diamond / rotated square
        const s = p.r;
        ctx.beginPath();
        ctx.moveTo(0, -s); ctx.lineTo(s, 0); ctx.lineTo(0, s); ctx.lineTo(-s, 0);
        ctx.closePath();
        ctx.fill();
        ctx.strokeStyle = color.replace(/[\d.]+\)$/, (p.alpha * 0.4) + ')');
        ctx.lineWidth = 0.5;
        ctx.stroke();
      } else if (isArabesque) {
        // Organic leaf shape
        const s = p.r;
        ctx.beginPath();
        ctx.moveTo(0, -s);
        ctx.bezierCurveTo(s * 0.8, -s * 0.5, s * 0.8, s * 0.5, 0, s);
        ctx.bezierCurveTo(-s * 0.8, s * 0.5, -s * 0.8, -s * 0.5, 0, -s);
        ctx.closePath();
        ctx.fill();
      } else {
        ctx.beginPath();
        ctx.arc(0, 0, p.r, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.restore();
    });
    animFrameId = requestAnimationFrame(animate);
  }
  animate();
}

window.addEventListener("resize", () => {
  particleCanvas.width = window.innerWidth;
  particleCanvas.height = window.innerHeight;
});

/* ============================================================
   CONFETTI
   ============================================================ */
function fireConfetti() {
  const ctx = confettiCanvas.getContext("2d");
  confettiCanvas.width = window.innerWidth;
  confettiCanvas.height = window.innerHeight;

  const pieces = [];
  const islamicThemes = {
    islamic: ["#d4a843", "#f0c75e", "#1b8c6a", "#b8922e", "#3aaf85", "#f2e8d0", "#0f5e47", "#fff"],
    alhambra: ["#e8922e", "#f0c75e", "#c46a1a", "#a0522d", "#f5e6cc", "#d4a843", "#fff"],
    iznik: ["#00bcd4", "#e84040", "#1a73e8", "#fff", "#1a3a7a", "#00e5ff", "#ff6666"],
    zellige: ["#1a8c50", "#e8a832", "#2a78c8", "#c46028", "#3aaf70", "#fff", "#f0c75e"],
    arabesque: ["#5a8068", "#b0b8d0", "#d0d8e8", "#3a5a44", "#7880a0", "#fff"]
  };
  const colors = islamicThemes[THEME]
    || ["#ef4444", "#f97316", "#eab308", "#22c55e", "#3b82f6", "#8b5cf6", "#06b6d4", "#fff"];

  for (let i = 0; i < 100; i++) {
    const angle = Math.random() * Math.PI * 2;
    const speed = Math.random() * 16 + 6;
    pieces.push({
      x: window.innerWidth / 2, y: window.innerHeight / 2,
      dx: Math.cos(angle) * speed, dy: Math.sin(angle) * speed - 8,
      r: Math.random() * 5 + 2,
      color: colors[Math.floor(Math.random() * colors.length)],
      rot: Math.random() * 360, dr: (Math.random() - 0.5) * 15,
      life: 1, shape: Math.random() > 0.5 ? "rect" : "circle"
    });
  }

  let frame = 0;
  function draw() {
    ctx.clearRect(0, 0, confettiCanvas.width, confettiCanvas.height);
    let alive = false;
    pieces.forEach(p => {
      if (p.life <= 0) return;
      alive = true;
      p.x += p.dx; p.y += p.dy; p.dy += 0.35;
      p.rot += p.dr; p.life -= 0.016; p.dx *= 0.985;
      ctx.save();
      ctx.translate(p.x, p.y);
      ctx.rotate((p.rot * Math.PI) / 180);
      ctx.globalAlpha = p.life;
      ctx.fillStyle = p.color;
      if (p.shape === "rect") ctx.fillRect(-p.r / 2, -p.r / 2, p.r, p.r * 0.5);
      else { ctx.beginPath(); ctx.arc(0, 0, p.r / 2, 0, Math.PI * 2); ctx.fill(); }
      ctx.restore();
    });
    if (alive && frame < 180) { frame++; requestAnimationFrame(draw); }
    else { ctx.clearRect(0, 0, confettiCanvas.width, confettiCanvas.height); }
  }
  draw();
}

/* ============================================================
   FILTERING & SEARCHING
   ============================================================ */
function normalize(s) { return (s || "").toLowerCase(); }

function matches(app) {
  const desc = (app.desc && typeof app.desc === 'object') ? (app.desc[LANG] || app.desc.en || '') : (app.desc || '');
  const text = normalize(app.name + " " + desc + " " + (app.tags || []).join(" ") + " " + (app.status || ""));
  const query = normalize(q.value).trim();
  const words = query.split(/\s+/).filter(Boolean);
  const okQuery = words.length === 0 || words.every(w => text.includes(w));
  const okFilter = currentLibrary || !currentFilter || (app.categories && app.categories.includes(currentFilter));
  const okStatus = !currentStatusFilter || app.status === currentStatusFilter;
  const okLibrary = !currentLibrary || app.library === currentLibrary;
  return okQuery && okFilter && okStatus && okLibrary;
}

/* ============================================================
   CARD BUILDER
   ============================================================ */
const CARD_COLORS = [
  "#ef4444","#f97316","#eab308","#22c55e","#10b981",
  "#14b8a6","#06b6d4","#0ea5e9","#3b82f6","#6366f1",
  "#8b5cf6","#7c3aed","#2563eb","#0891b2","#059669",
  "#ca8a04","#dc2626","#ea580c","#4f46e5","#0d9488",
  "#16a34a","#d97706","#9333ea"
];

function escapeHtml(s) {
  const d = document.createElement("div");
  d.textContent = s;
  return d.innerHTML;
}

function card(app, index) {
  const el = document.createElement("article");
  const num = app._num || (index + 1);
  const color = CARD_COLORS[((app._num || index + 1) - 1) % CARD_COLORS.length];
  el.className = "kids-card";
  el.dataset.cat = (app.categories && app.categories[0]) || "";
  el.style.setProperty("--card-color", color);
  el.setAttribute("tabindex", "0");
  el.setAttribute("role", "article");
  el.setAttribute("aria-label", app.name);

  const desc = (app.desc && typeof app.desc === 'object') ? (app.desc[LANG] || app.desc.en || '') : (app.desc || '');
  const isFav = FAVS.includes(app.name);

  // Badge (NEW / Popular / Hub)
  let badgeHTML = "";
  if (app.badge === "new") badgeHTML = `<span class="card-badge new">${t("badge_new")}</span>`;
  else if (app.badge === "popular") badgeHTML = `<span class="card-badge popular">${t("badge_popular")}</span>`;
  else if (app.badge === "hub") badgeHTML = `<span class="card-badge hub">${t("badge_hub")}</span>`;
  else if (app.badge === "stable") badgeHTML = `<span class="card-badge stable">${t("badge_stable")}</span>`;

  // Visibility badge (public 🌐 / private 🔒)
  const isPublic = (app.visibility || "private") === "public";
  const visHTML = isPublic
    ? `<span class="vis-badge public" title="Public repo">🌐</span>`
    : `<span class="vis-badge private" title="Private repo">🔒</span>`;

  // Status badge (Beta / Dev / Offline / custom — stable shows nothing)
  let statusHTML = "";
  if (app.status === "beta") statusHTML = `<span class="status-badge beta">${t("status_beta")}</span>`;
  else if (app.status === "dev") statusHTML = `<span class="status-badge dev">${t("status_dev")}</span>`;
  else if (app.status === "offline") statusHTML = `<span class="status-badge offline">${t("status_offline")}</span>`;
  else if (app.status && app.status !== "stable") statusHTML = `<span class="status-badge custom">${app.status}</span>`;

  el.innerHTML = `
    ${badgeHTML}
    ${visHTML}
    <button class="fav-btn ${isFav ? 'favorited' : ''}" data-fav="${app.name}" title="Favorite" aria-label="Toggle favorite">🔥</button>
    <h3><span class="card-number">#${num}</span><span class="kids-emoji">${escapeHtml(app.emoji)}</span><span class="kids-name">${escapeHtml(app.name)}</span>${statusHTML}</h3>
    <p class="kids-desc">${escapeHtml(desc)}</p>
    <div class="kids-actions">
      ${isPublic
        ? `<a class="kids-link" href="${app.github}" target="_blank" rel="noreferrer">${t("github")}</a>`
        : `<span class="kids-link disabled" title="Private repo">🔒 Private</span>`
      }
      ${isPublic
        ? `<a class="kids-link primary view-link" href="${app.view}" target="_blank" rel="noreferrer" data-app="${app.name}">${t("view_btn")}</a>`
        : `<span class="kids-link primary disabled">🔒 ${t("view_btn")}</span>`
      }
    </div>
    <div class="kids-tags">
      ${(app.tags || []).slice(0, 5).map(tag => `<span class="kids-tag">${escapeHtml(tag)}</span>`).join("")}
    </div>
  `;

  el.querySelector(".fav-btn").addEventListener("click", (e) => {
    e.stopPropagation();
    toggleFav(app.name, e.currentTarget);
  });

  el.querySelector(".view-link")?.addEventListener("click", () => {
    fireConfetti();
    playSound("tada");
    trackExplored(app.name);
  });

  return el;
}

/* ============================================================
   FAVORITES
   ============================================================ */
function toggleFav(name, btn) {
  if (FAVS.includes(name)) {
    FAVS = FAVS.filter(f => f !== name);
    btn.classList.remove("favorited");
    playSound("pop");
  } else {
    FAVS.push(name);
    btn.classList.add("favorited");
    playSound("zap");
  }
  localStorage.setItem("wdiy-favs", JSON.stringify(FAVS));
}

/* ============================================================
   EXPLORER TRACKER
   ============================================================ */
function trackExplored(name) {
  if (!EXPLORED.includes(name)) {
    EXPLORED.push(name);
    localStorage.setItem("wdiy-explored", JSON.stringify(EXPLORED));
    updateExplorer();
  }
}

function updateExplorer() {
  const count = EXPLORED.length;
  let title = t("explorer_title_0");
  if (count >= 22) title = t("explorer_title_22");
  else if (count >= 15) title = t("explorer_title_15");
  else if (count >= 10) title = t("explorer_title_10");
  else if (count >= 5) title = t("explorer_title_5");

  if (count > 0) {
    explorerBar.innerHTML = `${t("explorer_prefix")} <strong>${count}</strong> ${t("explorer_suffix")} — ${title}`;
  } else {
    explorerBar.innerHTML = title;
  }
}

/* ============================================================
   GREETING
   ============================================================ */
function updateGreeting() {
  const hour = new Date().getHours();
  let key = "greeting_morning";
  if (hour >= 12 && hour < 18) key = "greeting_afternoon";
  else if (hour >= 18 || hour < 5) key = "greeting_evening";
  greetingBar.textContent = t(key);
}

/* ============================================================
   STATS
   ============================================================ */
function updateStats() {
  const cats = new Set(APPS.flatMap(a => a.categories || []));
  const pubCount  = APPS.filter(a => (a.visibility || "private") === "public").length;
  const privCount = APPS.filter(a => (a.visibility || "private") === "private").length;
  statsBar.innerHTML = `
    <span class="stat-item"><span class="stat-num">${APPS.length}</span> ${t("stats_apps")}</span>
    <span class="stat-item">•</span>
    <span class="stat-item"><span class="stat-num">${cats.size}</span> ${t("stats_cats")}</span>
    <span class="stat-item">•</span>
    <span class="stat-item" title="Public repos">🌐 <span class="stat-num">${pubCount}</span></span>
    <span class="stat-item" title="Private repos" style="opacity:0.6">🔒 <span class="stat-num">${privCount}</span></span>
    <span class="stat-item">•</span>
    <span class="stat-item">${t("stats_made")}</span>
  `;
}

/* ============================================================
   JOKE
   ============================================================ */
function updateJoke() {
  const jokes = t("jokes");
  const joke = jokes[Math.floor(Math.random() * jokes.length)];
  jokeBar.innerHTML = `<span class="joke-emoji">😂</span> ${joke}`;
}

/* ============================================================
   FILTER COUNTS
   ============================================================ */
function updateFilterCounts() {
  document.querySelectorAll("[data-count-filter]").forEach(el => {
    const cat = el.dataset.countFilter;
    const count = cat ? APPS.filter(a => a.categories && a.categories.includes(cat)).length : APPS.length;
    el.textContent = count;
  });
  document.querySelectorAll("[data-count-library]").forEach(el => {
    const lib = el.dataset.countLibrary;
    el.textContent = APPS.filter(a => a.library === lib).length;
  });
}

/* ============================================================
   RENDER
   ============================================================ */
function render() {
  grid.innerHTML = "";
  const items = APPS.filter(matches);
  items.forEach((a, i) => grid.appendChild(card(a, i)));
  empty.style.display = items.length ? "none" : "block";
}

/* ============================================================
   VIEW MODE
   ============================================================ */
function applyViewMode(mode) {
  VIEW_MODE = mode;
  localStorage.setItem("wdiy-view", mode);
  grid.classList.toggle("list-view", mode === "list");
  viewButtons.forEach(b => b.classList.toggle("active", b.dataset.view === mode));
}

/* ============================================================
   SHUFFLE
   ============================================================ */
function shuffleApps() {
  for (let i = APPS.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [APPS[i], APPS[j]] = [APPS[j], APPS[i]];
  }
  playSound("whoosh");
  render();
}

/* ============================================================
   EASTER EGG — Click logo 5 times
   ============================================================ */
function easterEgg() {
  logoClicks++;
  if (logoClicks >= 5) {
    logoClicks = 0;
    fireConfetti();
    playSound("tada");
    siteLogo.style.animation = "wiggle 0.5s ease-in-out 3";
    setTimeout(() => { siteLogo.style.animation = ""; }, 1500);
  }
}

/* ============================================================
   SCROLL TO TOP
   ============================================================ */
function checkScroll() {
  scrollTopBtn.classList.toggle("visible", window.scrollY > 300);
}

/* ============================================================
   LISTENERS
   ============================================================ */
function initListeners() {
  q.addEventListener("input", () => {
    clearBtn.style.display = q.value ? "block" : "none";
    render();
  });
  clearBtn.addEventListener("click", () => {
    q.value = "";
    clearBtn.style.display = "none";
    render();
    q.focus();
  });

  filterButtons.forEach(btn => {
    btn.addEventListener("click", () => {
      filterButtons.forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      currentFilter = btn.dataset.filter || "";
      playSound("pop");
      render();
    });
  });

  statusFilterButtons.forEach(btn => {
    btn.addEventListener("click", () => {
      statusFilterButtons.forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      currentStatusFilter = btn.dataset.status || "";
      playSound("pop");
      render();
    });
  });

  // Library filter buttons
  const libraryButtons = [...document.querySelectorAll(".lib-btn[data-library]")];
  libraryButtons.forEach(btn => {
    btn.addEventListener("click", () => {
      const wasActive = btn.classList.contains("active");
      libraryButtons.forEach(b => b.classList.remove("active"));
      if (wasActive) {
        currentLibrary = "";
      } else {
        btn.classList.add("active");
        currentLibrary = btn.dataset.library || "";
        // Deselect category filter when library is active
        filterButtons.forEach(b => b.classList.remove("active"));
        filterButtons[0].classList.add("active"); // reset to "All"
        currentFilter = "";
      }
      playSound("pop");
      render();
    });
  });

  langButtons.forEach(btn => {
    btn.addEventListener("click", () => {
      playSound("pop");
      applyLang(btn.dataset.lang);
    });
  });

  themeButtons.forEach(btn => {
    btn.addEventListener("click", () => {
      playSound("zap");
      applyTheme(btn.dataset.theme);
    });
  });

  viewButtons.forEach(btn => {
    btn.addEventListener("click", () => {
      playSound("pop");
      applyViewMode(btn.dataset.view);
    });
  });

  soundToggle.addEventListener("click", () => {
    SOUND = !SOUND;
    localStorage.setItem("wdiy-sound", SOUND ? "on" : "off");
    soundToggle.textContent = SOUND ? "🔊" : "🔇";
    if (SOUND) playSound("pop");
  });
  soundToggle.textContent = SOUND ? "🔊" : "🔇";

  shuffleBtn.addEventListener("click", shuffleApps);

  scrollTopBtn.addEventListener("click", () => {
    window.scrollTo({ top: 0, behavior: "smooth" });
    playSound("whoosh");
  });
  window.addEventListener("scroll", checkScroll, { passive: true });

  siteLogo.addEventListener("click", easterEgg);

  document.addEventListener("keydown", (e) => {
    if (e.key === "/" && document.activeElement !== q) {
      e.preventDefault();
      q.focus();
    }
    if (e.key === "Escape" && document.activeElement === q) {
      q.blur();
    }
  });
}

/* ============================================================
   START
   ============================================================ */
init();
