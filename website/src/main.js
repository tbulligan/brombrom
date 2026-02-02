import './style.css'

// Translations
const translations = {
  nl: {
    hero_title: "Navigeer met <br/> Vertrouwen.",
    hero_desc: "Het enige offline OsmAnd navigatiepakket specifiek ontworpen voor <strong>Brommobielen</strong> in Nederland. Vermijd snelwegen, respecteer C9 borden en rijd veilig.",
    btn_download: "Download BromBrom Manager",
    badge_label: "Nu Beschikbaar",
    btn_how: "Hoe het werkt",
    feat_1_title: "C9 Handhaving",
    feat_1_desc: "Vermijdt automatisch wegen gemarkeerd met het C9 verkeersbord (gesloten voor langzaam motorverkeer), zodat u legaal en veilig blijft.",
    feat_2_title: "Snelwegen Verbod",
    feat_2_desc: "Routeert nooit over snelwegen en autowegen waar brommobielen niet zijn toegestaan, en kiest slimme alternatieven via service-wegen.",
    feat_3_title: "100% Offline",
    feat_3_desc: "Gebouwd op OsmAnd. Navigeer overal in Nederland zonder internetverbinding. Geen dataverbruik nodig.",
    install_title: "Start binnen enkele minuten",
    install_desc: "De makkelijkste manier om te installeren en kaarten up-to-date te houden is via de <strong>BromBrom Manager</strong> voor Android (Sideload Only).",
    step_1_title: "Download de App",
    step_1_desc: "Download de <strong>BromBrom.apk</strong> van de releases pagina.",
    step_2_title: "Installeer & Geef Toestemming",
    step_2_desc: "Open de APK om te installeren. U moet \"Alle Bestanden Toegang\" geven zodat de manager uw OsmAnd kaartenmap kan bijwerken.",
    step_3_title: "Eén-klik Update",
    step_3_desc: "Open BromBrom Manager en tik op <strong>Update Kaart</strong> en <strong>Update Routing</strong>. U bent klaar om te rijden!",
    tip_title: "iOS of Handmatige Installatie?",
    tip_desc: "Voor iPhone-gebruikers of geavanceerde gebruikers die liever handmatig bestanden kopiëren.",
    tip_btn: "Bekijk de Gids",
    footer_copy: "&copy; 2026 BromBrom Project.",
    footer_sub: "Open source en gratis. Data gebaseerd op OpenStreetMap & NDW.",
    support_title: "Steun het Project",
    coffee: "Trakteer mee op een koffie"
  },
  en: {
    hero_title: "Navigate <br/> with Confidence.",
    hero_desc: "The only offline OsmAnd navigation package designed specifically for <strong>L6e microcars (Brommobielen)</strong> in the Netherlands. Avoid highways, respect C9 signs, and drive safely.",
    btn_download: "Download BromBrom Manager",
    btn_how: "How it Works",
    feat_1_title: "C9 Enforcement",
    feat_1_desc: "Automatically avoids roads marked with the C9 traffic sign (closed to slow motor vehicles), keeping you legal and safe.",
    feat_2_title: "No Motorways",
    feat_2_desc: "Strictly prohibits routing on motorways and expressways where microcars are not allowed, prioritizing service roads.",
    feat_3_title: "100% Offline",
    feat_3_desc: "Built on OsmAnd. Navigate anywhere in the Netherlands without an internet connection. No data usage required.",
    install_title: "Get Started in Minutes",
    install_desc: "The easiest way to install and keep your maps updated is via the <strong>BromBrom Manager</strong> for Android (Sideload Only).",
    step_1_title: "Download the App",
    step_1_desc: "Download the <strong>BromBrom.apk</strong> from the releases page.",
    step_2_title: "Install & Grant Permissions",
    step_2_desc: "Open the APK to install. You must grant \"All Files Access\" so the manager can update your OsmAnd maps folder.",
    step_3_title: "One-Tap Update",
    step_3_desc: "Open BromBrom Manager and tap <strong>Update Map</strong> and <strong>Update Routing</strong>. You're ready to drive!",
    tip_title: "iOS or Manual Setup?",
    tip_desc: "For iPhone users or advanced users who prefer copying files manually.",
    tip_btn: "View the Guide",
    footer_copy: "&copy; 2026 BromBrom Project.",
    footer_sub: "Open source and free. Data based on OpenStreetMap & NDW.",
    badge_label: "Available Now",
    support_title: "Support the Project",
    coffee: "Buy me a coffee"
  }
};

// Language Matcher
let currentLang = 'nl';

function updateLanguage(lang) {
  currentLang = lang;
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (translations[lang][key]) {
      el.innerHTML = translations[lang][key];
    }
  });

  document.querySelectorAll('.lang-option').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.lang === lang);
  });
}

document.querySelectorAll('.lang-option').forEach(btn => {
  btn.addEventListener('click', () => updateLanguage(btn.dataset.lang));
});

// GitHub Version Fetcher
async function fetchLatestVersion() {
  try {
    const response = await fetch('https://api.github.com/repos/tbulligan/brombrom/releases/latest');
    const data = await response.json();
    if (data.tag_name) {
      const versionEl = document.getElementById('version-tag');
      if (versionEl) {
        // If tag is literally 'latest', use the publish date for a cleaner look
        let displayVersion = data.tag_name;
        if (displayVersion === 'latest' && data.published_at) {
          const date = new Date(data.published_at);
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          displayVersion = `${months[date.getMonth()]} ${date.getFullYear()}`;
        }

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
