import './style.css'

// Translations
const translations = {
  nl: {
    hero_title: "Navigeer met <br/> Vertrouwen.",
    hero_desc: "Het enige offline OsmAnd navigatiepakket specifiek ontworpen voor <strong>Brommobielen</strong> in Nederland. Vermijd snelwegen, respecteer C9 borden en rijd veilig.",
    btn_download_android: "Download BromBrom Manager (Android)",
    btn_visual_guide: "Visuele Handleiding",
    btn_download_ios: "Download BromBrom.osf (iOS)",
    badge_label: "Nu Beschikbaar",
    feat_1_title: "C9 Handhaving",
    feat_1_desc: "Vermijdt automatisch wegen gemarkeerd met het C9 verkeersbord (gesloten voor langzaam motorverkeer), zodat je legaal en veilig blijft.",
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
    step_3_desc: "Open BromBrom Manager en tik op <strong>INSTALLEREN / BIJWERKEN</strong>. OsmAnd opent: tik op <em>Alle instellingen en bronnen → Doorgaan → Alles vervangen</em>. Tik na de import op <em>Sluiten</em>, ga naar de OsmAnd-instellingen en activeer het BromBrom-profiel in het Navigatiemenu.",
    tip_title: "iOS / Apple Gebruikers",
    tip_desc: "Geen app nodig! Download BromBrom.osf en open het in OsmAnd. Tik op <em>Alle instellingen en bronnen → Doorgaan → Toepassen</em>. Na de import: Instellingen → schakel <strong>BromBrom</strong> in → selecteer BromBrom vervolgens in het <strong>Navigatiemenu</strong> (oranje auto-icoon).",
    tip_btn: "Download BromBrom.osf",
    footer_copy: "&copy; 2026 BromBrom Project.",
    footer_sub: "Open source en gratis. Data gebaseerd op OpenStreetMap & NDW.",
    support_title: "Steun het Project",
    coffee: "Trakteer mee op een koffie",
    carousel_section_title: "Visuele Handleiding",
    carousel_mode_first_time: "Eerste Installatie",
    carousel_mode_update: "Updates",
    label_car: "Auto (Niet toegestaan)",
    label_brombrom: "BromBrom (Legaal)",
    carousel_step_1_title: "Updates Beschikbaar",
    carousel_step_1_desc: "De BromBrom Manager laat direct zien of er een nieuwe kaart of route-update beschikbaar is.",
    carousel_step_2_title: "Open met OsmAnd",
    carousel_step_2_desc: "Zodra je op de update-knop tikt en het bestand is gedownload, vraagt Android je dit bestand te openen via OsmAnd.",
    carousel_step_3_title: "Selecteer Bronnen",
    carousel_step_3_desc: "OsmAnd opent en toont de bronnen die geïmporteerd gaan worden. Tik op <strong>Alle instellingen en bronnen</strong> en daarna op <strong>Doorgaan</strong>.",
    carousel_step_4_title: "Vervangen Bevestigen",
    carousel_step_4_desc: "Kies, indien gevraagd, <strong>Alles vervangen</strong> om de bestaande BromBrom bestanden over te schrijven met de nieuwste update.",
    carousel_step_5_title: "Import Voltooid",
    carousel_step_5_desc: "De bestanden zijn succesvol geïmporteerd. Tik onderaan op <strong>Sluiten</strong>.",
    carousel_step_6_title: "Open Hoofdmenu",
    carousel_step_6_desc: "Open het hoofdmenu van OsmAnd door links- of rechtsonder op de drie streepjes te tikken.",
    carousel_step_7_title: "Navigeer naar Instellingen",
    carousel_step_7_desc: "Ga naar <strong>Instellingen</strong> om je actieve profielen te beheren.",
    carousel_step_8_title: "Activeer BromBrom",
    carousel_step_8_desc: "Scroll omlaag naar de lijst met profielen, zoek het <strong>BromBrom</strong> profiel en schakel de schuifregelaar in (ON). Tik daarna op <strong>Profielenlijst bewerken</strong>.",
    carousel_step_9_title: "Sorteer Profielen",
    carousel_step_9_desc: "Sleep het BromBrom profiel naar boven om het sneller selecteerbaar te maken in het menu.",
    carousel_step_10_title: "Selecteer BromBrom-profiel",
    carousel_step_10_desc: "Tik in het navigatiemenu op het profiel-icoon en selecteer het <strong>BromBrom</strong>-profiel (oranje brommobiel-icoon) om het te activeren.",
    comparison_title: "Auto vs. Brommobiel Route",
    comparison_desc: "Zie het verschil: standaard autonavigatie stuurt je over verboden snelwegen en C9-wegen (links), terwijl BromBrom je over veilige en legale service-wegen routeert (rechts)."
  },
  en: {
    hero_title: "Navigate <br/> with Confidence.",
    hero_desc: "The only offline OsmAnd navigation package designed specifically for <strong>L6e microcars (Brommobielen)</strong> in the Netherlands. Avoid highways, respect C9 signs, and drive safely.",
    btn_download_android: "Download BromBrom Manager (Android)",
    btn_visual_guide: "Visual Setup Guide",
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
    step_3_desc: "Open BromBrom Manager and tap <strong>INSTALL / UPDATE</strong>. OsmAnd will open: tap <em>All Settings and Resources → Continue → Replace all</em>. After import, tap <em>Close</em>, open OsmAnd Settings, and configure the BromBrom navigation profile.",
    tip_title: "iOS / Apple Users",
    tip_desc: "No app needed! Download BromBrom.osf and open it in OsmAnd. Tap <em>All Settings and Resources → Continue → Apply</em>. After import: Settings → enable <strong>BromBrom</strong> → select BromBrom from the <strong>Navigation menu</strong> (orange car icon).",
    tip_btn: "Download BromBrom.osf",
    footer_copy: "&copy; 2026 BromBrom Project.",
    footer_sub: "Open source and free. Data based on OpenStreetMap & NDW.",
    badge_label: "Available Now",
    support_title: "Support the Project",
    coffee: "Buy me a coffee",
    carousel_section_title: "Visual Setup Guide",
    carousel_mode_first_time: "First-Time Setup",
    carousel_mode_update: "Updates",
    label_car: "Car (Forbidden)",
    label_brombrom: "BromBrom (Legal)",
    carousel_step_1_title: "Updates Available",
    carousel_step_1_desc: "The BromBrom Manager displays immediately if a new map or routing update is available.",
    carousel_step_2_title: "Open with OsmAnd",
    carousel_step_2_desc: "As soon as you tap the update button and the download completes, Android prompts you to open the file with OsmAnd.",
    carousel_step_3_title: "Select Resources",
    carousel_step_3_desc: "OsmAnd opens and lists the resources to be imported. Tap <strong>All Settings and Resources</strong> and then tap <strong>Continue</strong>.",
    carousel_step_4_title: "Confirm Replacement",
    carousel_step_4_desc: "If asked, select <strong>Replace all</strong> to overwrite the existing BromBrom files with the newest update.",
    carousel_step_5_title: "Import Complete",
    carousel_step_5_desc: "The files have been successfully imported. Tap <strong>Close</strong>.",
    carousel_step_6_title: "Open Main Menu",
    carousel_step_6_desc: "Open the main menu in OsmAnd by tapping the three lines icon in the bottom corner.",
    carousel_step_7_title: "Go to Settings",
    carousel_step_7_desc: "Go to <strong>Settings</strong> to manage your active navigation profiles.",
    carousel_step_8_title: "Enable BromBrom",
    carousel_step_8_desc: "Scroll down to the profiles list, find the <strong>BromBrom</strong> profile, and toggle the switch to ON. Then tap <strong>Edit profile list</strong>.",
    carousel_step_9_title: "Profile Ordering",
    carousel_step_9_desc: "Drag the BromBrom profile to the top to make it quickly selectable from the main navigation menu.",
    carousel_step_10_title: "Select BromBrom Profile",
    carousel_step_10_desc: "Tap the navigation profile icon in the routing menu and select the <strong>BromBrom</strong> profile (orange microcar icon) to activate it.",
    comparison_title: "Car vs. Microcar Routing",
    comparison_desc: "See the difference: standard car navigation routes you onto forbidden motorways and C9 roads (left), whereas BromBrom routes you over safe and legal service roads (right)."
  }
};

const screenshots = [
  'bbm-0-updates-available.png',
  'bbm-1-open-with-osmand.png',
  'bbm-2-import.png',
  'bbm-2.5-replace.png',
  'bbm-3-import-complete.png',
  'bbm-4-open-menu.png',
  'bbm-5-open-settings.png',
  'bbm-6-enable-brombrom.png',
  'bbm-7-drag-first.png',
  'bbm-8-set-brombrom.png'
].map(name => `/assets/bbm-screenshots/${name}`);

// Language Matcher & Carousel State
let currentLang = 'nl';
let carouselMode = 'first-time';
let activeIndex = 0; // active index inside visibleIndices[carouselMode]

const visibleIndices = {
  'first-time': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
  'update': [0, 1, 2, 3, 4]
};

// Cache DOM elements to prevent redundant queries
const i18nElements = document.querySelectorAll('[data-i18n]');
const langOptionBtns = document.querySelectorAll('.lang-option');

const carouselImg = document.getElementById('carousel-img');
const carouselCounter = document.getElementById('carousel-step-counter');
const carouselStepTitle = document.getElementById('carousel-step-title');
const carouselStepDesc = document.getElementById('carousel-step-description');
const prevBtn = document.getElementById('prev-slide-btn');
const nextBtn = document.getElementById('next-slide-btn');
const dotsContainer = document.getElementById('carousel-dots');

function getActiveScreenshotIndex() {
  return visibleIndices[carouselMode][activeIndex];
}

function updateCarousel() {
  if (!carouselImg) return;
  
  const activeSubset = visibleIndices[carouselMode];
  const screenshotIndex = getActiveScreenshotIndex();
  const item = screenshots[screenshotIndex];
  
  carouselImg.classList.add('fade-out');
  
  setTimeout(() => {
    carouselImg.src = item;
    
    // Update counter text
    if (carouselCounter) {
      carouselCounter.textContent = `${activeIndex + 1} / ${activeSubset.length}`;
    }
    
    // Retrieve translations based on the raw screenshotIndex
    const stepIndex = screenshotIndex + 1;
    const titleKey = `carousel_step_${stepIndex}_title`;
    const descKey = `carousel_step_${stepIndex}_desc`;
    
    if (carouselStepTitle) {
      carouselStepTitle.textContent = translations[currentLang][titleKey] || `Step ${activeIndex + 1}`;
    }
    if (carouselStepDesc) {
      carouselStepDesc.innerHTML = translations[currentLang][descKey] || '';
    }
    
    // Update dots styling
    if (dotsContainer) {
      const dots = dotsContainer.querySelectorAll('.carousel-dot');
      dots.forEach((dot, idx) => {
        dot.classList.toggle('active', idx === activeIndex);
      });
    }
    
    carouselImg.classList.remove('fade-out');
  }, 150);
}

function initCarousel() {
  if (!dotsContainer) return;
  
  const activeSubset = visibleIndices[carouselMode];
  
  dotsContainer.innerHTML = '';
  activeSubset.forEach((_, idx) => {
    const dot = document.createElement('div');
    dot.className = 'carousel-dot';
    if (idx === activeIndex) dot.classList.add('active');
    dot.addEventListener('click', () => {
      activeIndex = idx;
      updateCarousel();
    });
    dotsContainer.appendChild(dot);
  });
  
  updateCarousel();
}

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

  // Dynamically switch the hero banner image based on selected language
  const heroBanner = document.getElementById('hero-banner-img');
  if (heroBanner) {
    heroBanner.src = lang === 'nl' ? '/assets/brombrom-banner-NL.jpg' : '/assets/brombrom-banner-EN.png';
  }

  updateCarousel();
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
      const mapAsset = data.assets.find(a => a.name.endsWith('.obf'));
      const timestamp = mapAsset ? mapAsset.updated_at : data.published_at;

      const versionEl = document.getElementById('version-tag');
      if (versionEl && timestamp) {
        const date = new Date(timestamp);
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const displayVersion = `${months[date.getMonth()]} ${date.getFullYear()}`;

        document.querySelectorAll('.version-plh').forEach(el => el.textContent = displayVersion);

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

  const modeFirstTimeBtn = document.getElementById('mode-first-time');
  const modeUpdateBtn = document.getElementById('mode-update');
  
  function setMode(mode) {
    carouselMode = mode;
    activeIndex = 0;
    
    if (modeFirstTimeBtn) modeFirstTimeBtn.classList.toggle('active', mode === 'first-time');
    if (modeUpdateBtn) modeUpdateBtn.classList.toggle('active', mode === 'update');
    
    initCarousel();
  }
  
  if (modeFirstTimeBtn) {
    modeFirstTimeBtn.addEventListener('click', () => setMode('first-time'));
  }
  if (modeUpdateBtn) {
    modeUpdateBtn.addEventListener('click', () => setMode('update'));
  }

  if (prevBtn) {
    prevBtn.addEventListener('click', () => {
      const activeSubset = visibleIndices[carouselMode];
      activeIndex = (activeIndex - 1 + activeSubset.length) % activeSubset.length;
      updateCarousel();
    });
  }
  
  if (nextBtn) {
    nextBtn.addEventListener('click', () => {
      const activeSubset = visibleIndices[carouselMode];
      activeIndex = (activeIndex + 1) % activeSubset.length;
      updateCarousel();
    });
  }

  // Touch swipe support for the visual setup guide carousel
  const carouselLayout = document.querySelector('.carousel-layout');
  if (carouselLayout) {
    let touchStartX = 0;
    let touchEndX = 0;

    carouselLayout.addEventListener('touchstart', e => {
      touchStartX = e.changedTouches[0].screenX;
    }, { passive: true });

    carouselLayout.addEventListener('touchend', e => {
      touchEndX = e.changedTouches[0].screenX;
      const threshold = 50; // minimum distance in pixels
      if (touchStartX - touchEndX > threshold) {
        // Swipe left -> Next slide
        const activeSubset = visibleIndices[carouselMode];
        activeIndex = (activeIndex + 1) % activeSubset.length;
        updateCarousel();
      } else if (touchEndX - touchStartX > threshold) {
        // Swipe right -> Previous slide
        const activeSubset = visibleIndices[carouselMode];
        activeIndex = (activeIndex - 1 + activeSubset.length) % activeSubset.length;
        updateCarousel();
      }
    }, { passive: true });
  }

  updateLanguage('nl');
  initCarousel();
  fetchLatestVersion();
});

