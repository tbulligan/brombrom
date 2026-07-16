import './style.css'

// Translations
const translations = {
  nl: {
    hero_title: "Navigeer met <br/> Vertrouwen.",
    hero_desc: "Het enige offline OsmAnd navigatiepakket specifiek ontworpen voor <strong>Brommobielen</strong> in Nederland. Vermijd snelwegen, respecteer C9 borden en rijd veilig.",
    btn_download_android: "Download BromBrom Manager (Android)",
    btn_visual_guide: "Visuele Handleiding",
    btn_download_ios: "iOS / Handmatige Installatie",
    btn_faq: "Vragen & Antwoorden",
    badge_label: "Nu Beschikbaar",
    hero_prereq: "Vereist de gratis <a href=\"https://play.google.com/store/apps/details?id=net.osmand\" target=\"_blank\" style=\"text-decoration: underline; color: inherit;\">OsmAnd</a> app op je telefoon.",
    feat_1_title: "Legale & Veilige Routes",
    feat_1_desc: "Vermijdt automatisch snelwegen, autowegen en wegen gesloten voor langzaam verkeer (C9-borden) op basis van actuele NDW-data.",
    feat_2_title: "Gesproken Aanwijzingen",
    feat_2_desc: "Navigeer ontspannen met duidelijke stemaanwijzingen en rijstrookbegeleiding die je precies vertellen waar je moet voorsorteren.",
    feat_3_title: "Offline & Op je Dashboard",
    feat_3_desc: "Volledig offline navigeren zonder internet of dataverbruik. Werkt naadloos op je telefoonscherm of direct op het dashboard via Android Auto.",
    feat_4_title: "Android Auto",
    feat_4_desc: "Ondersteunt Android Auto en Apple CarPlay (via OsmAnd Pro), zodat je routes direct op het dashboard van je brommobiel ziet.",
    install_title: "Start binnen enkele minuten",
    install_desc: "De makkelijkste manier om te installeren en kaarten up-to-date te houden is via de <strong>BromBrom Manager</strong> voor Android.",
    step_1_title: "Installeer de App",
    step_1_desc: "Download de app via de Google Play Store.",
    step_2_title: "Geef Toestemming",
    step_2_desc: "Open de app en geef meldingen- en opslagmachtiging als hierom gevraagd wordt.",
    step_3_title: "Eén-klik Update",
    step_3_desc: "Open BromBrom Manager. De app controleert automatisch op updates en start de download. Tik na het downloaden op <strong>Open OsmAnd</strong>. OsmAnd opent: vink zowel <em>Instellingen</em> als <em>Bronnen</em> aan, tik op <em>Doorgaan</em> en kies <em>Alles vervangen</em>. Tik na de import op <em>Sluiten</em>.",
    tip_title: "iOS / Apple Gebruikers",
    tip_desc: "Geen app nodig! Voor iOS (iPhone) kun je het BromBrom.osf-bestand direct downloaden en openen in OsmAnd. Let op: handmatige installaties worden <strong>niet automatisch bijgewerkt</strong>; je zult de nieuwste versie zelf moeten downloaden voor updates. Bekijk de <a href='https://github.com/tbulligan/brombrom/blob/main/docs/manual_install.md' target='_blank' class='link-subtle' style='text-decoration: underline;'>Manual Installation Guide</a> (Engels) op GitHub voor alle details.",
    tip_btn: "Download BromBrom.osf",
    footer_copy: "&copy; 2026 BromBrom Project.",
    footer_sub: "Open source en gratis. Data gebaseerd op OpenStreetMap & NDW.",
    support_title: "Steun het Project",
    support_desc: "BromBrom is gratis voor persoonlijk, niet-commercieel gebruik (open-source). Vind je het project nuttig? Steun mij met een kopje koffie om de hosting en kaarten-updates mogelijk te maken!",
    coffee: "Trakteer mee op een koffie",
    faq_title: "Veelgestelde Vragen",
    faq_q1: "Ik krijg de melding <strong>\"Kan app niet installeren\"</strong> (of \"Kan niet updaten\") in de <strong>Play Store</strong>. Wat moet ik doen?",
    faq_a1: "Dit gebeurt meestal als er al een eerdere testversie (bijvoorbeeld direct geïnstalleerd via een los APK-bestand van GitHub) op je telefoon staat. Omdat de beveiligingssleutels van losse APK-bestanden en de Google Play Store verschillen, blokkeert Android de installatie.<br/><br/><strong>De oplossing:</strong><br/>1. Verwijder de app van je telefoon. Zorg er hierbij voor dat je eventuele vinkjes zoals <strong>\"App-gegevens behouden\"</strong> uitschakelt.<br/>2. Mocht de melding blijven: ga op je telefoon naar <strong>Instellingen → Apps → BromBrom Manager</strong>. Tik rechtsboven op de drie puntjes en kies <strong>\"Verwijderen voor alle gebruikers\"</strong>.<br/>3. Wis daarna het geheugen van de Play Store app (Instellingen → Apps → Google Play Store → Opslag → Cache en gegevens wissen).<br/>4. Start je telefoon opnieuw op en installeer de app opnieuw via de Play Store.",
    faq_q2: "Ik zie alleen een <strong>grijs raster</strong> (leeg scherm) of de <strong>routeberekening mislukt</strong>. Wat is er mis?",
    faq_a2: "BromBrom levert de specifieke brommobiel-routes en -regels, maar bevat zelf geen landkaart. OsmAnd heeft eerst de basiskaart van Nederland nodig om wegen te kunnen tonen en routes te berekenen.<br/><br/><strong>De oplossing:</strong> Download de offline kaart van Nederland in OsmAnd:<br/>1. Open <strong>OsmAnd</strong>.<br/>2. Open het menu (drie streepjes links- of rechtsonder).<br/>3. Tik op <strong>Kaarten en hulpmiddelen</strong>.<br/>4. Tik op <strong>Europa/Nederland/Normale kaarten</strong> en download de kaarten.<br/><em>Zodra de download klaar is, kleurt het scherm groen/wit met alle wegen en kan er een route gepland worden.</em>",
    faq_q3: "Ik zie het <strong>BromBrom-profiel</strong> helemaal niet in de lijst van OsmAnd staan.",
    faq_a3: "Als het profiel niet zichtbaar is, is de koppeling tussen de BromBrom Manager en OsmAnd nog niet voltooid, of staat het profiel verborgen.<br/><br/><strong>De oplossing:</strong><br/>1. Controleer eerst of het profiel verborgen staat: Ga in OsmAnd naar <strong>Instellingen</strong> → <strong>Profielen configureren</strong> en controleer of de schuifregelaar naast <strong>BromBrom</strong> aan staat.<br/>2. Staat het er helemaal niet tussen? Open de BromBrom Manager en tik op de knop <strong>\"BromBrom opnieuw installeren in OsmAnd\"</strong>. Volg de instructies op het scherm nauwkeurig.<br/><br/><em>Tip:</em> Vind je het lastig vanaf je telefoonscherm? Open de visuele handleiding op <a href=\"https://brombrom.bulligan.com/#visual-guide\" class=\"link-subtle\" style=\"text-decoration: underline;\">brombrom.bulligan.com/#visual-guide</a> op een laptop of tablet, zodat je rustig kunt meelezen tijdens het uitvoeren van de stappen op je telefoon.",
    faq_q4: "Help, de navigatie stuurt me alsnog de <strong>snelweg</strong> of <strong>autoweg</strong> op!",
    faq_a4: "Als dit gebeurt, staat in OsmAnd het verkeerde rijprofiel actief. De app denkt op dat moment dat je een gewone auto bent.<br/><br/><strong>De oplossing:</strong> Kijk in het navigatiescherm van OsmAnd. Zie je daar bovenaan of in de route-instellingen een <strong>standaard auto-icoontje</strong> (vooraanzicht)? Tik daarop en wissel het profiel naar het specifieke BromBrom-profiel. Dit herken je aan het <strong>oranje autootje van de zijkant gezien</strong>. Zodra het juiste profiel actief is, worden snelwegen, autowegen en C9-wegen automatisch vermeden.",
    faq_q5: "Werkt de app ook op een <strong>iPhone</strong> (Apple iOS)?",
    faq_a5: "Nee, op dit moment is de BromBrom Manager <strong>alleen beschikbaar voor Android-telefoons</strong>. Er is momenteel nog geen versie voor iPhones beschikbaar in de Apple App Store.<br/><br/>Voor de echte avonturiers is het wel mogelijk om de kaarten handmatig op iOS te installeren. Download hiervoor het <strong>BromBrom.osf</strong> bestand onderaan de homepage en open dit direct in de OsmAnd app op je iPhone.<br/><br/><em>Belangrijke opmerking:</em> Bij deze handmatige methode worden kaarten en routes <strong>niet automatisch bijgewerkt</strong>. Je zult zelf de nieuwste `BromBrom.osf` van de website moeten downloaden en importeren voor updates.",
    faq_q6: "Is de app ook geschikt voor een <strong>scootmobiel</strong>, <strong>Canta</strong> of andere voertuigen?",
    faq_a6: "<strong>Nee, de app is specifiek en uitsluitend ingeregeld voor brommobielen (45 km/u voertuigen).</strong> De routeplanner houdt rekening met de wegen waar je met een brommobiel mag en moet rijden. Voor een scootmobiel of een Canta gelden heel andere verkeersregels (zoals het mogen rijden op het fietspad of de stoep). Je moet de app daarvoor dus <strong>niet gebruiken</strong>.",
    faq_q7: "Kan ik de app ook in <strong>België</strong> of <strong>Duitsland</strong> gebruiken?",
    faq_a7: "De app is momenteel specifiek ontwikkeld en getest voor de <strong>Nederlandse wetgeving en weginfrastructuur</strong> (inclusief het correct vermijden van de Nederlandse C9-wegen). Het navigeren over de grens in België of Duitsland is <strong>niet ondersteund</strong>.",
    faq_q8: "Er gebeurt niets of de <strong>import mislukt</strong> nadat ik op \"OPEN OSMAND\" tik in de Manager app. Wat kan ik doen?",
    faq_a8: "Dit kan gebeuren als OsmAnd al op de achtergrond actief is of in een ander menu staat, waardoor Android de bestanden niet correct kan doorsturen.<br/><br/><strong>De oplossing:</strong> Sluit OsmAnd volledig af voordat je de update start. Swipe OsmAnd weg uit het scherm met 'recente apps' op je telefoon. Open daarna de BromBrom Manager opnieuw en tik op de knop om de installatie te starten. OsmAnd start dan schoon op en zal het bestand direct succesvol importeren.",
    faq_q9: "Is BromBrom <strong>gratis</strong>? Mag ik de app <strong>commercieel</strong> gebruiken?",
    faq_a9: "BromBrom is volledig gratis voor <strong>persoonlijk en niet-commercieel gebruik</strong> onder de bijbehorende licentie. Commercieel gebruik, herdistributie of modificatie is niet toegestaan zonder voorafgaande schriftelijke toestemming.<br/><br/>Voor vragen over commerciële licenties of samenwerkingen kun je <a href=\"#\" id=\"open-contact-btn\" class=\"link-subtle\" style=\"text-decoration: underline;\">direct contact met mij opnemen</a>.",
    contact_title: "Contact Opnemen",
    contact_desc: "Heb je vragen, feedback of een bug? Stuur direct een bericht.",
    contact_notice: "De meeste problemen worden al in de Visuele Handleiding en Veelgestelde Vragen beantwoord.",
    contact_label_name: "Naam",
    contact_label_email: "E-mailadres",
    contact_label_subject: "Onderwerp",
    contact_opt_feedback: "Algemene feedback",
    contact_opt_bug: "Navigatie- of kaartfout rapporteren",
    contact_opt_commercial: "Commercieel / Samenwerking",
    contact_opt_other: "Overig",
    contact_label_company: "Bedrijf / Organisatie (Optioneel)",
    contact_label_msg: "Bericht",
    contact_btn_send: "Verstuur Bericht",
    faq_fallback_text: "Staat je vraag er niet tussen?",
    faq_fallback_link: "Neem contact op",
    carousel_section_title: "Visuele Handleiding",
    carousel_mode_first_time: "Eerste Installatie",
    carousel_mode_update: "Updates",
    label_car: "Auto (Niet toegestaan)",
    label_brombrom: "BromBrom (Legaal)",
    carousel_step_1_title: "Automatische Updates",
    carousel_step_1_desc: "De BromBrom Manager controleert bij het openen direct op updates en start automatisch de download.",
    carousel_step_2_title: "Open OsmAnd",
    carousel_step_2_desc: "Zodra de download in de BromBrom Manager is voltooid, tik je op <strong>Open OsmAnd</strong> om de bestanden door te sturen.",
    carousel_step_3_title: "Selecteer Bronnen",
    carousel_step_3_desc: "OsmAnd opent en toont de bronnen die geïmporteerd gaan worden. Vink zowel <strong>'Instellingen'</strong> als <strong>'Bronnen'</strong> aan en tik daarna op <strong>'Doorgaan'</strong>.",
    carousel_step_4_title: "Vervangen Bevestigen",
    carousel_step_4_desc: "Kies, indien gevraagd, <strong>Alles vervangen</strong> om de bestaande BromBrom bestanden over te schrijven met de nieuwste update.",
    carousel_step_5_title: "Import Voltooid",
    carousel_step_5_desc: "De bestanden zijn succesvol geïmporteerd. Tik onderaan op <strong>Sluiten</strong>.",
    carousel_step_6_title: "Open Hoofdmenu",
    carousel_step_6_desc: "Open het hoofdmenu van OsmAnd door links- of rechtsonder op de drie streepjes te tikken.",
    carousel_step_7_title: "Navigeer naar Instellingen",
    carousel_step_7_desc: "Ga naar <strong>Instellingen</strong> om je actieve profielen te beheren.",
    carousel_step_8_title: "Activeer BromBrom",
    carousel_step_8_desc: "Scroll omlaag naar de lijst met profielen, zoek het <strong>BromBrom</strong> profiel en schakel de schuifregelaar in (ON).",
    carousel_step_9_title: "Selecteer BromBrom-profiel",
    carousel_step_9_desc: "Tik in het navigatiemenu op het profiel-icoon en selecteer het <strong>BromBrom</strong>-profiel (oranje brommobiel-icoon) om het te activeren.",
    comparison_title: "Auto vs. Brommobiel Route",
    comparison_desc: "Zie het verschil: standaard autonavigatie stuurt je over verboden snelwegen en C9-wegen (links), terwijl BromBrom je over veilige en legale service-wegen routeert (rechts)."
  },
  en: {
    hero_title: "Navigate <br/> with Confidence.",
    hero_desc: "The only offline OsmAnd navigation package designed specifically for <strong>L6e microcars (Brommobielen)</strong> in the Netherlands. Avoid highways, respect C9 signs, and drive safely.",
    btn_download_android: "Download BromBrom Manager (Android)",
    btn_visual_guide: "Visual Setup Guide",
    btn_download_ios: "iOS / Manual Installation",
    btn_faq: "Questions & Answers",
    hero_prereq: "Requires the free <a href=\"https://play.google.com/store/apps/details?id=net.osmand\" target=\"_blank\" style=\"text-decoration: underline; color: inherit;\">OsmAnd</a> app on your device.",
    feat_1_title: "Safe & Legal Routing",
    feat_1_desc: "Automatically avoids motorways, expressways, and roads closed to slow motor vehicles (C9 signs) using live NDW traffic data.",
    feat_2_title: "Voice & Lane Guidance",
    feat_2_desc: "Drive stress-free with turn-by-turn spoken guidance and lane assistance telling you exactly where to merge or turn.",
    feat_3_title: "Offline & Dashboard-Ready",
    feat_3_desc: "Navigate fully offline without internet or data usage. Works seamlessly on your phone screen or directly on your dashboard via Android Auto.",
    install_title: "Get Started in Minutes",
    install_desc: "The easiest way to install and keep your maps updated is via the <strong>BromBrom Manager</strong> for Android.",
    step_1_title: "Install the App",
    step_1_desc: "Download the app from the Google Play Store.",
    step_2_title: "Grant Permissions",
    step_2_desc: "Open the app and grant notification and storage permissions when prompted.",
    step_3_title: "One-Click Update",
    step_3_desc: "Open BromBrom Manager. The app will automatically check for updates and start the download. Once finished, tap <strong>Open OsmAnd</strong>. OsmAnd will open: check both <em>Settings</em> and <em>Resources</em>, tap <em>Continue</em>, and choose <em>Replace all</em>. After import, tap <em>Close</em>.",
    tip_title: "iOS / Apple Users",
    tip_desc: "No app needed! For iOS (iPhone), you can download the BromBrom.osf file directly and open it in OsmAnd. Note: manual installations <strong>do not update automatically</strong>; you will need to manually download the latest version to get updates. Check the <a href='https://github.com/tbulligan/brombrom/blob/main/docs/manual_install.md' target='_blank' class='link-subtle' style='text-decoration: underline;'>Manual Installation Guide</a> on GitHub for detailed steps.",
    tip_btn: "Download BromBrom.osf",
    footer_copy: "&copy; 2026 BromBrom Project.",
    footer_sub: "Open source and free. Data based on OpenStreetMap & NDW.",
    badge_label: "Available Now",
    support_title: "Support the Project",
    support_desc: "BromBrom is free for personal, non-commercial use (open-source). If you find it useful, support me with a cup of coffee to help cover hosting and map update costs!",
    coffee: "Buy me a coffee",
    faq_title: "Frequently Asked Questions",
    faq_q1: "I get a <strong>\"Can't install app\"</strong> (or \"Can't update\") error in the <strong>Play Store</strong>. What should I do?",
    faq_a1: "This usually happens if an earlier test version (for example, installed directly via a separate APK file from GitHub) is already on your phone. Because the security keys of standalone APKs and the Google Play Store differ, Android blocks the installation.<br/><br/><strong>The solution:</strong><br/>1. Uninstall the app from your device. Make sure to uncheck any options like <strong>\"Keep app data\"</strong> during uninstallation.<br/>2. If the issue persists: go to <strong>Settings → Apps → BromBrom Manager</strong>. Tap the three dots in the top-right corner and choose <strong>\"Uninstall for all users\"</strong>.<br/>3. Next, clear the Play Store app storage (Settings → Apps → Google Play Store → Storage → Clear Cache & Clear Data).<br/>4. Restart your phone and install the app again from the Play Store.",
    faq_q2: "I only see a <strong>grey grid</strong> (empty screen) or <strong>route calculation fails</strong>. What is wrong?",
    faq_a2: "BromBrom provides custom microcar routing rules, but does not bundle the map database. OsmAnd requires the offline map of the Netherlands to show roads and calculate routes.<br/><br/><strong>The solution:</strong> Download the offline map of the Netherlands in OsmAnd:<br/>1. Open <strong>OsmAnd</strong>.<br/>2. Open the menu (three lines in the bottom corner).<br/>3. Tap <strong>Maps & Resources</strong>.<br/>4. Tap <strong>Europe/Netherlands/Standard map</strong> and download the maps.<br/><em>Once downloaded, the screen will display roads and routes can be calculated.</em>",
    faq_q3: "I can't find the <strong>BromBrom profile</strong> in OsmAnd.",
    faq_a3: "If the profile is missing, the import process from the BromBrom Manager was not completed, or the profile is hidden.<br/><br/><strong>The solution:</strong><br/>1. First check if it is hidden: Go to OsmAnd <strong>Settings</strong> → <strong>Configure profiles</strong> and ensure the toggle next to <strong>BromBrom</strong> is enabled.<br/>2. If it is completely missing: Open BromBrom Manager and tap <strong>\"Reinstall BromBrom in OsmAnd\"</strong>. Follow the step-by-step instructions carefully.<br/><br/><em>Tip:</em> Finding it hard on your mobile screen? Open the visual guide at <a href=\"https://brombrom.bulligan.com/#visual-guide\" class=\"link-subtle\" style=\"text-decoration: underline;\">brombrom.bulligan.com/#visual-guide</a> on a laptop or tablet to read along easily.",
    faq_q4: "Help, the navigation is sending me onto <strong>motorways</strong> or <strong>expressways</strong>!",
    faq_a4: "This happens when the wrong navigation profile is active. OsmAnd thinks you are driving a standard car.<br/><br/><strong>The solution:</strong> Look at your navigation screen. Do you see a <strong>standard car icon</strong> (front view)? Tap it and switch to the <strong>BromBrom</strong> profile, which is represented by an <strong>orange microcar icon (side view)</strong>. Once selected, motorways and C9 roads will be avoided automatically.",
    faq_q5: "Does the app work on <strong>iPhone</strong> (Apple iOS)?",
    faq_a5: "No, the BromBrom Manager is currently **Android-only**. There is no iOS app available in the Apple App Store.<br/><br/>For advanced users, you can manually import the maps to iOS. Download the **BromBrom.osf** file at the bottom of the homepage and open it directly with OsmAnd on your iPhone.<br/><br/><em>Important note:</em> Manual installations <strong>do not update automatically</strong>. You will need to manually download and import the latest `BromBrom.osf` file to get updates. Check the <a href='https://github.com/tbulligan/brombrom/blob/main/docs/manual_install.md' target='_blank' class='link-subtle' style='text-decoration: underline;'>Manual Installation Guide</a> on GitHub for detailed steps.",
    faq_q6: "Is the app suitable for <strong>mobility scooters</strong>, <strong>Cantas</strong>, or other vehicles?",
    faq_a6: "<strong>No, the app is strictly and exclusively tailored for microcars (45 km/u vehicles).</strong> The route planner calculates paths where microcars are legally allowed and supposed to drive. Mobility scooters and Cantas have different traffic rules (e.g., driving on cycle lanes or pavements) and should <strong>not use</strong> this app.",
    faq_q7: "Can I use the app in <strong>Belgium</strong> or <strong>Germany</strong>?",
    faq_a7: "The app is specifically built and tested for **Dutch traffic regulations and road infrastructure** (including the correct snapping of Dutch C9 signs). International navigation is <strong>not supported</strong>.",
    faq_q8: "Nothing happens or the <strong>import fails</strong> after I tap \"OPEN OSMAND\" in the Manager app. What should I do?",
    faq_a8: "This can happen if OsmAnd is already running in the background or open in another menu, which can cause Android to fail to deliver the files correctly.<br/><br/><strong>The solution:</strong> Completely close OsmAnd before starting the update. Swipe OsmAnd away from your phone's 'recent apps' screen. Then, open BromBrom Manager again and tap the update button. OsmAnd will start clean and import the file successfully.",
    faq_q9: "Is BromBrom <strong>free</strong>? Can I use it <strong>commercially</strong>?",
    faq_a9: "BromBrom is completely free for <strong>personal, non-commercial use</strong> under its license. Commercial use, redistribution, or modification is prohibited without prior written consent.<br/><br/>For commercial inquiries or partnerships, please <a href=\"#\" id=\"open-contact-btn\" class=\"link-subtle\" style=\"text-decoration: underline;\">contact me directly</a>.",
    contact_title: "Get in Touch",
    contact_desc: "Have questions, feedback, or a bug? Send a message directly.",
    contact_notice: "Most issues are already answered in the Visual Setup Guide and Frequently Asked Questions.",
    contact_label_name: "Name",
    contact_label_email: "Email Address",
    contact_label_subject: "Subject",
    contact_opt_feedback: "General feedback",
    contact_opt_bug: "Report a navigation or map error",
    contact_opt_commercial: "Commercial / Partnership",
    contact_opt_other: "Other",
    contact_label_company: "Company / Organization (Optional)",
    contact_label_msg: "Message",
    contact_btn_send: "Send Message",
    faq_fallback_text: "Question not answered?",
    faq_fallback_link: "Get in touch",
    carousel_section_title: "Visual Setup Guide",
    carousel_mode_first_time: "First-Time Setup",
    carousel_mode_update: "Updates",
    label_car: "Car (Forbidden)",
    label_brombrom: "BromBrom (Legal)",
    carousel_step_1_title: "Automatic Updates",
    carousel_step_1_desc: "Upon launch, the BromBrom Manager checks for updates and automatically starts downloading the latest files.",
    carousel_step_2_title: "Open OsmAnd",
    carousel_step_2_desc: "As soon as the download in the BromBrom Manager is complete, tap <strong>Open OsmAnd</strong> to forward the files.",
    carousel_step_3_title: "Select Resources",
    carousel_step_3_desc: "OsmAnd opens and lists the resources to be imported. Check both <strong>'Settings'</strong> and <strong>'Resources'</strong> and then tap <strong>'Continue'</strong>.",
    carousel_step_4_title: "Confirm Replacement",
    carousel_step_4_desc: "If asked, select <strong>Replace all</strong> to overwrite the existing BromBrom files with the newest update.",
    carousel_step_5_title: "Import Complete",
    carousel_step_5_desc: "The files have been successfully imported. Tap <strong>Close</strong>.",
    carousel_step_6_title: "Open Main Menu",
    carousel_step_6_desc: "Open the main menu in OsmAnd by tapping the three lines icon in the bottom corner.",
    carousel_step_7_title: "Go to Settings",
    carousel_step_7_desc: "Go to <strong>Settings</strong> to manage your active navigation profiles.",
    carousel_step_8_title: "Enable BromBrom",
    carousel_step_8_desc: "Scroll down to the profiles list, find the <strong>BromBrom</strong> profile, and toggle the switch to ON.",
    carousel_step_9_title: "Select BromBrom Profile",
    carousel_step_9_desc: "Tap the navigation profile icon in the routing menu and select the <strong>BromBrom</strong> profile (orange microcar icon) to activate it.",
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
  'bbm-7-set-brombrom.png'
].map(name => `/assets/bbm-screenshots/${name}`);

// Language Matcher & Carousel State
let currentLang = 'nl';
let carouselMode = 'first-time';
let activeIndex = 0; // active index inside visibleIndices[carouselMode]

const visibleIndices = {
  'first-time': [0, 1, 2, 3, 4, 5, 6, 7, 8],
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
      const mapAsset = data.assets.find(a => a.name.endsWith('.osf') || a.name.endsWith('.obf'));
      const timestamp = mapAsset ? mapAsset.updated_at : data.published_at;

      const versionEl = document.getElementById('version-tag');
      if (versionEl && timestamp) {
        const date = new Date(timestamp);
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const displayVersion = `${date.getDate()} ${months[date.getMonth()]} ${date.getFullYear()}`;

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

  // FAQ Accordion
  const faqQuestions = document.querySelectorAll('.faq-question');
  faqQuestions.forEach(btn => {
    btn.addEventListener('click', () => {
      const item = btn.parentElement;
      item.classList.toggle('active');
    });
  });

  // Contact Modal Logic
  const contactModal = document.getElementById('contact-modal');
  const closeContactBtn = document.getElementById('close-contact-btn');
  const contactForm = document.getElementById('contact-form');
  const contactStatus = document.getElementById('contact-status');

  document.addEventListener('click', (e) => {
    if (e.target && (e.target.id === 'open-contact-btn' || e.target.classList.contains('js-open-contact') || e.target.closest('.js-open-contact'))) {
      e.preventDefault();
      if (contactModal) {
        contactModal.classList.add('active');
        if (window.turnstile) {
          window.turnstile.reset();
        }
      }
    }
  });

  if (closeContactBtn && contactModal) {
    closeContactBtn.addEventListener('click', () => {
      contactModal.classList.remove('active');
      if (contactForm) contactForm.reset();
      if (contactStatus) {
        contactStatus.textContent = '';
        contactStatus.className = 'contact-status';
      }
    });
  }

  if (contactForm) {
    contactForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const submitBtn = contactForm.querySelector('button[type="submit"]');
      if (submitBtn) submitBtn.disabled = true;

      const formData = new FormData(contactForm);
      if (formData.get('confirm_email')) {
        if (submitBtn) submitBtn.disabled = false;
        return; // Honeypot triggered
      }

      if (contactStatus) {
        contactStatus.textContent = currentLang === 'nl' ? 'Verzenden...' : 'Sending...';
        contactStatus.className = 'contact-status';
      }

      const payload = Object.fromEntries(formData);
      if (payload.company && payload.message) {
        payload.message = `Company: ${payload.company}\n\n${payload.message}`;
      }
      delete payload.company;

      if (payload.subject && payload.message) {
        payload.message = `[Category: ${payload.subject}]\n${payload.message}`;
      }

      try {
        const response = await fetch('https://bulligan-form-mailer.tomaso-bulligan.workers.dev', {
          method: 'POST',
          body: JSON.stringify(payload),
          headers: {
            'Content-Type': 'application/json'
          }
        });

        const result = await response.json();

        if (response.ok && result.success) {
          if (contactStatus) {
            contactStatus.textContent = currentLang === 'nl' ? 'Bericht succesvol verzonden!' : 'Message sent successfully!';
            contactStatus.className = 'contact-status success';
          }
          contactForm.reset();
          if (window.turnstile) {
            window.turnstile.reset();
          }
        } else {
          throw new Error(result.error || 'Submission failed');
        }
      } catch (err) {
        console.error('Contact Form Error:', err);
        if (contactStatus) {
          contactStatus.textContent = currentLang === 'nl' 
            ? 'Verzenden mislukt. Probeer het later opnieuw.' 
            : 'Sending failed. Please try again later.';
          contactStatus.className = 'contact-status error';
        }
        if (window.turnstile) {
          window.turnstile.reset();
        }
      } finally {
        if (submitBtn) submitBtn.disabled = false;
      }
    });
  }

  // Handle URL hash to open contact modal directly
  const handleHashContact = () => {
    if (window.location.hash === '#contact') {
      if (contactModal) {
        contactModal.classList.add('active');
        if (window.turnstile) {
          window.turnstile.reset();
        }
      }
    }
  };

  // Run on page load and hash change
  handleHashContact();
  window.addEventListener('hashchange', handleHashContact);

  updateLanguage('nl');
  initCarousel();
  fetchLatestVersion();
});

