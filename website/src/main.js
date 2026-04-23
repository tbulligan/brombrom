import './style.css'

// Translations
const translations = {
  nl: {
    hero_title: "Navigeer met <br/> Vertrouwen.",
    hero_desc: "Het enige offline OsmAnd navigatiepakket specifiek ontworpen voor <strong>Brommobielen</strong> in Nederland. Vermijd snelwegen, respecteer C9 borden en rijd veilig.",
    btn_download_android: "Download BromBrom Manager (Android)",
    btn_download_ios: "Download BromBrom.osf (iOS)",
    badge_label: "Nu Beschikbaar",
    feat_1_title: "C9 Handhaving",
    feat_1_desc: "Vermijdt automatisch wegen gemarkeerd met het C9 verkeersbord (gesloten voor langzaam motorverkeer), zodat u legaal en veilig blijft.",
    feat_2_title: "Snelwegen Verbod",
    feat_2_desc: "Routeert nooit over snelwegen en autowegen waar brommobielen niet zijn toegestaan, en kiest slimme alternatieven via service-wegen.",
    feat_3_title: "100% Offline",
    feat_3_desc: "Gebouwd op OsmAnd. Navigeer overal in Nederland zonder internetverbinding. Geen dataverbruik nodig.",
    install_title: "Start binnen enkele minuten",
    install_desc: "De makkelijkste manier om te installeren en kaarten up-to-date te houden is via de <strong>BromBrom Manager</strong> voor Android.",
    step_1_title: "Download de App",
    step_1_desc: "Download de <strong>BromBrom.apk</strong> van de releases pagina.",
    step_2_title: "Installeer",
    step_2_desc: "Open de APK om te installeren op je Android toestel.",
    step_3_title: "Importeer & Activeer",
    step_3_desc: "Open BromBrom Manager en tik op <strong>INSTALLEREN / BIJWERKEN</strong>. OsmAnd opent: tik op <em>Alle instellingen en bronnen → Doorgaan → Alles vervangen</em>. Tik na de import op <em>Instellingen</em>, schakel <strong>BromBrom</strong> in en selecteer BromBrom vervolgens in het <strong>Navigatiemenu</strong> (oranje auto-icoon).",
    tip_title: "iOS / Apple Gebruikers",
    tip_desc: "Geen app nodig! Download BromBrom.osf en open het in OsmAnd. Tik op <em>Alle instellingen en bronnen → Doorgaan → Toepassen</em>. Na de import: Instellingen → schakel <strong>BromBrom</strong> in → selecteer BromBrom vervolgens in het <strong>Navigatiemenu</strong> (oranje auto-icoon).",
    tip_btn: "Download BromBrom.osf",
    footer_copy: "&copy; 2026 BromBrom Project.",
    footer_sub: "Open source en gratis. Data gebaseerd op OpenStreetMap & NDW.",
    support_title: "Steun het Project",
    coffee: "Trakteer mee op een koffie"
  },
  en: {
    hero_title: "Navigate <br/> with Confidence.",
    hero_desc: "The only offline OsmAnd navigation package designed specifically for <strong>L6e microcars (Brommobielen)</strong> in the Netherlands. Avoid highways, respect C9 signs, and drive safely.",
    btn_download_android: "Download BromBrom Manager (Android)",
    btn_download_ios: "Download BromBrom.osf (iOS)",
    feat_1_title: "C9 Enforcement",
    feat_1_desc: "Automatically avoids roads marked with the C9 traffic sign (closed to slow motor vehicles), keeping you legal and safe.",
    feat_2_title: "No Motorways",
    feat_2_desc: "Strictly prohibits routing on motorways and expressways where microcars are not allowed, prioritizing service roads.",
    feat_3_title: "100% Offline",
    feat_3_desc: "Built on OsmAnd. Navigate anywhere in the Netherlands without an internet connection. No data usage required.",
    install_title: "Get Started in Minutes",
    install_desc: "The easiest way to install and keep your maps updated is via the <strong>BromBrom Manager</strong> for Android.",
    step_1_title: "Download the App",
    step_1_desc: "Download the <strong>BromBrom.apk</strong> from the releases page.",
    step_2_title: "Install",
    step_2_desc: "Open the APK to install onto your Android device.",
    step_3_title: "Import & Activate",
    step_3_desc: "Open BromBrom Manager and tap <strong>INSTALL / UPDATE</strong>. OsmAnd will open: tap <em>All Settings and Resources → Continue → Replace all</em>. After import, tap <em>Settings</em>, enable <strong>BromBrom</strong>, then select BromBrom from the <strong>Navigation menu</strong> (orange car icon).",
    tip_title: "iOS / Apple Users",
    tip_desc: "No app needed! Download BromBrom.osf and open it in OsmAnd. Tap <em>All Settings and Resources → Continue → Apply</em>. After import: Settings → enable <strong>BromBrom</strong> → select BromBrom from the <strong>Navigation menu</strong> (orange car icon).",
    tip_btn: "Download BromBrom.osf",
    footer_copy: "&copy; 2026 BromBrom Project.",
    footer_sub: "Open source and free. Data based on OpenStreetMap & NDW.",
    badge_label: "Available Now",
    support_title: "Support the Project",
    coffee: "Buy me a coffee"
  }
};

// Language Matcher
let currentLang = 'nl';

// Cache DOM elements to prevent redundant queries
const i18nElements = document.querySelectorAll('[data-i18n]');
const langOptionBtns = document.querySelectorAll('.lang-option');

function updateLanguage(lang) {
  currentLang = lang;
  i18nElements.forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (translations[lang][key]) {
      el.innerHTML = translations[lang][key];
    }
  });

  langOptionBtns.forEach(btn => {
    btn.classList.toggle('active', btn.dataset.lang === lang);
  });
}

langOptionBtns.forEach(btn => {
  btn.addEventListener('click', () => updateLanguage(btn.dataset.lang));
});

// GitHub Version Fetcher
async function fetchLatestVersion() {
  try {
    const response = await fetch('https://api.github.com/repos/tbulligan/brombrom/releases/latest');
    const data = await response.json();

    if (data.assets) {
      // Find the map file specifically
      const mapAsset = data.assets.find(a => a.name.endsWith('.obf'));
      const timestamp = mapAsset ? mapAsset.updated_at : data.published_at;

      const versionEl = document.getElementById('version-tag');
      if (versionEl && timestamp) {
        const date = new Date(timestamp);
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const displayVersion = `${months[date.getMonth()]} ${date.getFullYear()}`;

        // Update all version placeholders
        document.querySelectorAll('.version-plh').forEach(el => el.textContent = displayVersion);

        // Update the main badge
        versionEl.textContent = displayVersion;
        document.getElementById('version-badge').style.opacity = '1';
      }
    }
  } catch (e) {
    console.log('Could not fetch version', e);
  }
}

// Animations
const observerOptions = {
  root: null,
  rootMargin: '0px',
  threshold: 0.1
};

const observer = new IntersectionObserver((entries, observer) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      observer.unobserve(entry.target);
    }
  });
}, observerOptions);

document.addEventListener('DOMContentLoaded', () => {
  const animatedElements = document.querySelectorAll('.fade-in');
  animatedElements.forEach((el) => observer.observe(el));

  updateLanguage('nl');
  fetchLatestVersion();
});
