import './style.css'

// Translations
const translations = {
  nl: {
    hero_title: "Navigeer met <br/> Vertrouwen.",
    hero_desc: "Het enige offline OsmAnd navigatiepakket specifiek ontworpen voor <strong>Brommobielen</strong> in Nederland. Vermijd snelwegen, respecteer C9 borden en rijd veilig.",
    btn_download_android: "Download BromBrom Manager (Android)",
    btn_visual_guide: "Visuele Handleiding",
    btn_download_ios: "iOS / Handmatige Installatie",
    btn_faq: "Veelgestelde Vragen",
    badge_label: "Nu Beschikbaar",
    hero_prereq: "Vereist de gratis <a href=\"https://play.google.com/store/apps/details?id=net.osmand\" target=\"_blank\" style=\"text-decoration: underline; color: inherit;\">OsmAnd</a> app op je telefoon.",
    feat_1_title: "Legale & Veilige Routes",
    feat_1_desc: "Vermijdt automatisch snelwegen, autowegen en wegen gesloten voor langzaam verkeer (C9-borden) op basis van actuele NDW-data.",
    feat_2_title: "Gesproken Aanwijzingen",
    feat_2_desc: "Navigeer ontspannen met duidelijke stemaanwijzingen en rijstrookbegeleiding die je precies vertellen waar je moet voorsorteren.",
    feat_3_title: "Offline & Op je Dashboard",
    feat_3_desc: "Volledig offline navigeren zonder internet of dataverbruik. Werkt naadloos op je telefoonscherm of direct op het dashboard via Android Auto*.",
    feat_3_footnote: "* Android Auto vereist OsmAnd Maps+ (<a href=\"#faq\" class=\"js-open-faq-auto\" style=\"text-decoration: underline; color: inherit;\">zie FAQ</a>).",
    feat_4_title: "Rustige & Kronkelige Routes",
    feat_4_desc: "Schakel optioneel 'Drukke wegen vermijden' in om verkeersaders te omzeilen en ontspannen binnendoor te rijden.",
    install_title: "Start binnen enkele minuten",
    install_desc: "De makkelijkste manier om te installeren en kaarten up-to-date te houden is via de <strong>BromBrom Manager</strong> voor Android.",
    step_1_title: "Installeer de App",
    step_1_desc: "Download de app via de Google Play Store.",
    step_2_title: "Geef Toestemming",
    step_2_desc: "Open de app en geef meldingen- en opslagmachtiging als hierom gevraagd wordt.",
    step_3_title: "Eén-klik Update",
    step_3_desc: "Open BromBrom Manager. De app controleert automatisch op updates en start de download. Tik na het downloaden op <strong>Open OsmAnd</strong>. OsmAnd opent: vink zowel <em>Instellingen</em> als <em>Bronnen</em> aan, tik op <em>Doorgaan</em> en kies <em>Alles vervangen</em>. Tik na de import op <em>Sluiten</em>.",
    tip_title: "iOS / Apple Gebruikers",
    tip_desc: "Geen app nodig! Voor iOS (iPhone) kun je het BromBrom.osf-bestand direct downloaden en openen in OsmAnd. Let op: handmatige installaties worden <strong>niet automatisch bijgewerkt</strong>; je zult de nieuwste versie zelf moeten downloaden voor updates. Bekijk de <a href='https://github.com/tbulligan/brombrom/blob/main/docs/manual_install.nl.md' target='_blank' class='link-subtle' style='text-decoration: underline;'>Handleiding Handmatige Installatie</a> op GitHub voor alle details.",
    tip_btn: "Download BromBrom.osf",
    footer_copy: "&copy; 2026 BromBrom Project.",
    footer_sub: "Open source en gratis. Data gebaseerd op OpenStreetMap & NDW.",
    footer_disclaimer: "BromBrom is een onafhankelijk initiatief en is niet gelieerd aan OsmAnd.",
    support_title: "Steun het Project",
    support_desc: "BromBrom is gratis voor persoonlijk, niet-commercieel gebruik (open-source). Vind je het project nuttig? Steun mij met een kopje koffie om de hosting en kaarten-updates mogelijk te maken!",
    coffee: "Trakteer mee op een koffie",
    faq_title: "Veelgestelde Vragen",
    faq_q8: "Er gebeurt niets of de <strong>import mislukt</strong> nadat ik op \"Open OsmAnd\" tik in de app. Wat kan ik doen?",
    faq_a8: "Geen zorgen, dit gebeurt meestal als OsmAnd op de achtergrond al actief was. Android kan de bestanden dan soms niet goed overdragen.<br/><br/><strong>De oplossing in 3 simpele stappen:</strong><br/>1. <strong>Sluit OsmAnd helemaal af:</strong> veeg OsmAnd omhoog of weg uit het overzicht van recent geopende apps op je telefoon.<br/>2. <strong>Open de BromBrom Manager opnieuw</strong> en tik op <strong>Open OsmAnd</strong>.<br/>3. OsmAnd start nu fris op en toont direct het importscherm. Vink zowel <strong>Instellingen</strong> als <strong>Bronnen</strong> aan, tik op <strong>Doorgaan</strong> en kies <strong>Alles vervangen</strong>.<br/><br/><em>Lukt het nog steeds niet? Start je telefoon even helemaal opnieuw op en probeer het nog een keer.</em>",
    faq_q3: "Ik zie het <strong>BromBrom-profiel</strong> helemaal niet in de lijst van OsmAnd staan. Waar vind ik het?",
    faq_a3: "Als het BromBrom-icoontje niet zichtbaar is, staat het profiel meestal nog verborgen in OsmAnd, of is de installatie nog niet helemaal afgerond.<br/><br/><strong>Zo controleer je dit stap voor stap:</strong><br/>1. <strong>Controleer of het profiel verborgen staat:</strong><br/>• Open OsmAnd en tik op het menu (de <strong>drie liggende streepjes</strong> in de hoek).<br/>• Tik op <strong>Instellingen</strong> (tandwieltje) en daarna op <strong>Profielen configureren</strong> (of <em>App-profielen</em>).<br/>• Zoek naar <strong>BromBrom</strong> (met het oranje autootje) en zet het <strong>schuifknopje op AAN</strong> (oranje). Zet voor de rust de andere profielen (zoals Auto) op UIT.<br/>2. <strong>Staat BromBrom er echt niet tussen?</strong><br/>• Open de BromBrom Manager-app en tik op de knop <strong>\"BromBrom opnieuw installeren in OsmAnd\"</strong>.<br/>• Volg rustig de stappen op het scherm.<br/><br/><em>Tip:</em> Vind je het priegelig op je telefoonscherm? Bekijk onze <a href=\"#visual-guide\" class=\"link-subtle\" style=\"text-decoration: underline;\">Visuele Handleiding</a> op een tablet of computer, zodat je rustig stap voor stap kunt meekijken.",
    faq_q2: "Ik zie alleen een <strong>grijs raster</strong> (leeg scherm) of de <strong>routeberekening mislukt</strong>. Wat is er mis?",
    faq_a2: "BromBrom levert de speciale verkeersregels en veilige routes voor je brommobiel, maar bevat zelf niet de grote landkaart van Nederland. OsmAnd heeft eerst die basiskaart nodig om straten te tonen en routes te kunnen berekenen.<br/><br/><strong>Zo download je de gratis kaart van Nederland in OsmAnd:</strong><br/>1. Open <strong>OsmAnd</strong>.<br/>2. Tik op de <strong>drie liggende streepjes</strong> (menu linksonder of rechtsonder).<br/>3. Tik op <strong>Kaarten en hulpmiddelen</strong> (of <em>Kaarten downloaden</em>).<br/>4. Tik op <strong>Europa</strong> → <strong>Nederland</strong> en download de <strong>Standaardkaart</strong> (Normale kaart).<br/><br/><em>Zodra de download klaar is (duurt via wifi meestal een paar minuten), kleurt je scherm groen/wit en verschijnen alle wegen en plaatsen vanzelf!</em>",
    faq_q4: "Help, de navigatie stuurt me alsnog de <strong>snelweg</strong> of <strong>autoweg</strong> op!",
    faq_a4: "Geen paniek: als dit gebeurt, staat in OsmAnd per ongeluk het gewone <strong>autoprofiel</strong> aan. OsmAnd denkt dan dat je in een gewone personenauto rijdt in plaats van een 45 km/u brommobiel.<br/><br/><strong>Zo los je dit meteen op:</strong><br/>1. Kijk bovenin het navigatiescherm van OsmAnd.<br/>2. Zie je daar een <strong>blauw autootje van voren gezien</strong>? Dan staat het gewone autoprofiel aan.<br/>3. Tik op dat icoontje en kies het <strong>BromBrom-profiel</strong>. Dit herken je aan het <strong>oranje autootje van de zijkant gezien</strong>.<br/><br/><em>Zodra het oranje BromBrom-profiel actief is, worden snelwegen, autowegen en C9-verbodswegen altijd automatisch vermeden.</em>",
    faq_q10: "Hoe kan ik <strong>drukke wegen vermijden</strong> en voor <strong>rustige binnenroutes</strong> kiezen?",
    faq_a10: "Rijd je liever ontspannen over rustige polder-, dijk- en binnenwegen in plaats van over drukke doorgaande wegen? BromBrom heeft hier een speciale instelling voor ingebouwd!<br/><br/><strong>Zo zet je rustige routes aan in OsmAnd:</strong><br/>1. Start een route met het <strong>BromBrom-profiel</strong> geselecteerd.<br/>2. Tik op <strong>Opties</strong> (het tandwieltje bij de routeplanner).<br/>3. Tik op <strong>Routeparameters</strong> (of <em>Vermijd wegen...</em>).<br/>4. Zet het vinkje aan bij <strong>\"Drukke wegen vermijden\"</strong>.<br/><br/><em>OsmAnd herberekent de route meteen en leidt je ontspannen over rustige secundaire wegen en dijken.</em>",
    faq_q11: "Hoe zet ik gesproken meldingen voor <strong>verkeersdrempels of zebrapaden</strong> aan of uit?",
    faq_a11: "Vind je dat de stem tijdens het rijden te vaak waarschuwt voor drempels of oversteekplaatsen? Je kunt dit heel eenvoudig naar eigen wens instellen in OsmAnd:<br/><br/>1. Open OsmAnd en tik op het menu (de <strong>drie liggende streepjes</strong>).<br/>2. Tik op <strong>Instellingen</strong> en kies <strong>BromBrom</strong> (onder Gebruikersprofielen).<br/>3. Tik op <strong>Navigatie-instellingen</strong> en daarna op <strong>Gesproken instructies</strong>.<br/>4. Onder het kopje 'Meld' kun je <strong>Verkeerswaarschuwingen</strong> (drempels) en <strong>Zebrapaden</strong> met één tik aan- of uitzetten.",
    faq_q5: "Werkt de app ook op een <strong>iPhone</strong> (Apple iOS)?",
    faq_a5: "De automatische BromBrom Manager-app is er op dit moment <strong>alleen voor Android-telefoons</strong>. In de Apple App Store staat momenteel nog geen app.<br/><br/><strong>Heb je een iPhone?</strong> Dan kun je BromBrom alsnog gewoon gebruiken via een eenmalige handmatige installatie:<br/>1. Download het bestand <strong>BromBrom.osf</strong> via de knop onderaan deze pagina.<br/>2. Open het bestand op je iPhone met de gratis OsmAnd-app.<br/>3. Bekijk onze duidelijke <a href=\"https://github.com/tbulligan/brombrom/blob/main/docs/manual_install.nl.md\" target=\"_blank\" class=\"link-subtle\" style=\"text-decoration: underline;\">Handleiding voor iPhone (iOS)</a> met stap-voor-stap uitleg en afbeeldingen.<br/><br/><em>Belangrijke opmerkingen:</em><br/>1. Bij deze handmatige methode worden kaarten <strong>niet automatisch bijgewerkt</strong>; je downloadt af en toe zelf de nieuwste versie.<br/>2. Navigatie op het telefoonscherm is <strong>100% gratis</strong>. Wil je navigeren via <strong>Apple CarPlay</strong> op je dashboard, dan vereist OsmAnd een betaalde licentie (<strong>Maps+</strong> is ruim voldoende; <strong>Pro</strong> is niet nodig).",
    faq_q12: "Heb ik een <strong>betaalde OsmAnd-licentie</strong> nodig voor <strong>Android Auto</strong>?",
    faq_a12: "Voor navigatie op het <strong>scherm van je telefoon</strong> (in een telefoonhouder) is OsmAnd <strong>volledig gratis</strong>.<br/><br/>Wil je het navigatiescherm projecteren op het dashboard van je brommobiel via <strong>Android Auto</strong>? Dan vereist OsmAnd zelf een betaalde licentie:<br/>• <strong>Maps+</strong> (jaarlijks abonnement of eenmalige aankoop): <em>Ruim voldoende</em> voor Android Auto en onbeperkte kaartdownloads.<br/>• <strong>Pro</strong>: Bevat extra functies zoals cloudback-up, live weer en 3D-reliëf, maar is <strong>niet nodig</strong> voor BromBrom.<br/><br/><em>Bespaartip:</em> OsmAnd biedt in de Google Play Store regelmatig aanzienlijke seizoenskortingen aan (zoals rond feestdagen en actieperiodes). Het kan lonen om daarop te wachten!<br/><br/><em>Disclaimer:</em> BromBrom is een onafhankelijk open-source project en is niet gelieerd aan, gesponsord door of verdienend aan OsmAnd. Alle abonnements- en aankoopkosten gaan rechtstreeks naar de makers van OsmAnd.",
    faq_q9: "Is BromBrom <strong>gratis</strong>? Mag ik de app <strong>commercieel</strong> gebruiken?",
    faq_a9: "Ja, BromBrom is <strong>volledig gratis voor persoonlijk gebruik</strong>! Iedereen met een brommobiel mag de app en kaarten kosteloos gebruiken om veilig en legaal de weg op te gaan.<br/><br/><strong>Commercieel gebruik:</strong><br/>Wil je BromBrom bedrijfsmatig inzetten (zoals in een verhuurbedrijf, garage, rijschool of bezorgdienst), of de software herdistribueren? Dan is vooraf schriftelijke toestemming vereist.<br/><br/>Voor vragen over commerciële licenties of samenwerkingen kun je <a href=\"#\" id=\"open-contact-btn\" class=\"link-subtle js-open-contact\" style=\"text-decoration: underline;\">direct contact met mij opnemen</a>.",
    faq_q6: "Is de app ook geschikt voor een <strong>scootmobiel</strong>, <strong>Canta</strong> of <strong>gehandicaptenvoertuig</strong>?",
    faq_a6: "<strong>Nee, BromBrom is uitsluitend bedoeld voor 45 km/u brommobielen (zoals Ligier, Aixam, Microcar en Chatenet).</strong><br/><br/>Een brommobiel moet volgens de verkeerswet op de autorijbaan rijden en mag nooit op het fietspad of het voetpad komen. Voor een scootmobiel of een Canta (gehandicaptenvoertuig) gelden heel andere regels: die mogen juist wel over het fietspad en door voetgangersgebieden rijden.<br/><br/><em>Gebruik BromBrom daarom niet voor een scootmobiel of Canta; de app stuurt je dan over de drukkere autorijbaan in plaats van over het fietspad.</em>",
    faq_q7: "Kan ik de app ook in <strong>België</strong> of <strong>Duitsland</strong> gebruiken?",
    faq_a7: "Op dit moment <strong>niet</strong>. De app is specifiek ontwikkeld voor de <strong>Nederlandse wetgeving en weginfrastructuur</strong>.<br/><br/>In Nederland koppelen we officiële data van het Nationaal Dataportaal Wegverkeer (NDW) om alle C9-verbodsborden exact te herkennen. In België en Duitsland gelden andere borden en afwijkende regels voor 45 km/u voertuigen. Zodra je de landsgrens oversteekt, is veilige navigatie daarom niet gegarandeerd.<br/><br/><em>Woon of rijd je in het grensgebied? Blijf dan aan de Nederlandse kant van de grens navigeren.</em>",
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
    carousel_step_3_desc: "OsmAnd opent en toont de bronnen die geïmporteerd gaan worden. Vink zowel <strong>Instellingen</strong> als <strong>Bronnen</strong> aan en tik daarna op <strong>Doorgaan</strong>.",
    carousel_step_4_title: "Vervangen Bevestigen",
    carousel_step_4_desc: "Kies, indien gevraagd, <strong>Alles vervangen</strong> om de bestaande BromBrom bestanden over te schrijven met de nieuwste update.",
    carousel_step_5_title: "Import Voltooid",
    carousel_step_5_desc: "De bestanden zijn succesvol geïmporteerd. Tik onderaan op <strong>Sluiten</strong>.",
    carousel_step_6_title: "Open Hoofdmenu",
    carousel_step_6_desc: "Open het hoofdmenu van OsmAnd door links- of rechtsonder op de drie streepjes te tikken.",
    carousel_step_7_title: "Ga naar Instellingen",
    carousel_step_7_desc: "Ga naar <strong>Instellingen</strong> om je actieve profielen te beheren.",
    carousel_step_8_title: "BromBrom Inschakelen",
    carousel_step_8_desc: "Zet <strong>BromBrom</strong> op <strong>AAN</strong> (oranje) en zet alle overige profielen op <strong>UIT</strong> (grijs). BromBrom is nu direct je enige actieve navigatieprofiel.",
    comparison_title: "Auto vs. Brommobiel Route",
    comparison_desc: "Zie het verschil: standaard autonavigatie stuurt je over verboden snelwegen zoals de A7 (links), terwijl BromBrom je over veilige en legale parallelwegen leidt (midden), of over rustige binnenroutes met de optie 'Drukke wegen vermijden' (rechts).",
    label_car: "Auto (Niet toegestaan)",
    label_brombrom: "BromBrom (Legaal)",
    label_scenic: "BromBrom (Rustige route)"
  },
  en: {
    hero_title: "Navigate <br/> with Confidence.",
    hero_desc: "The only offline OsmAnd navigation package designed specifically for <strong>L6e microcars (Brommobielen)</strong> in the Netherlands. Avoid highways, respect C9 signs, and drive safely.",
    btn_download_android: "Download BromBrom Manager (Android)",
    btn_visual_guide: "Visual Setup Guide",
    btn_download_ios: "iOS / Manual Installation",
    btn_faq: "Frequently Asked Questions",
    hero_prereq: "Requires the free <a href=\"https://play.google.com/store/apps/details?id=net.osmand\" target=\"_blank\" style=\"text-decoration: underline; color: inherit;\">OsmAnd</a> app on your device.",
    feat_1_title: "Safe & Legal Routing",
    feat_1_desc: "Automatically avoids motorways, expressways, and roads closed to slow motor vehicles (C9 signs) using live NDW traffic data.",
    feat_2_title: "Voice & Lane Guidance",
    feat_2_desc: "Drive stress-free with turn-by-turn spoken guidance and lane assistance telling you exactly where to merge or turn.",
    feat_3_title: "Offline & Dashboard-Ready",
    feat_3_desc: "Navigate fully offline without internet or data usage. Works seamlessly on your phone screen or directly on your dashboard via Android Auto*.",
    feat_3_footnote: "* Requires OsmAnd Maps+ (<a href=\"#faq\" class=\"js-open-faq-auto\" style=\"text-decoration: underline; color: inherit;\">see FAQ</a>).",
    feat_4_title: "Scenic & Quiet Routes",
    feat_4_desc: "Optionally enable 'Avoid busy roads' to bypass arterial traffic and enjoy relaxed cruising along calm countryside roads.",
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
    footer_disclaimer: "BromBrom is an independent open-source project and is not affiliated with OsmAnd.",
    badge_label: "Available Now",
    support_title: "Support the Project",
    support_desc: "BromBrom is free for personal, non-commercial use (open-source). If you find it useful, support me with a cup of coffee to help cover hosting and map update costs!",
    coffee: "Buy me a coffee",
    faq_title: "Frequently Asked Questions",
    faq_q8: "Nothing happens or the <strong>import fails</strong> after tapping \"Open OsmAnd\" in the app. What should I do?",
    faq_a8: "Don't worry, this usually happens if OsmAnd was already running in the background. Android can sometimes fail to hand over the files.<br/><br/><strong>The solution in 3 easy steps:</strong><br/>1. <strong>Completely close OsmAnd:</strong> swipe OsmAnd away from your phone's recent apps screen.<br/>2. <strong>Reopen BromBrom Manager</strong> and tap <strong>Open OsmAnd</strong>.<br/>3. OsmAnd will now start cleanly and show the import screen right away. Check both <strong>Settings</strong> and <strong>Resources</strong>, tap <strong>Continue</strong>, and choose <strong>Replace all</strong>.<br/><br/><em>Still having trouble? Restart your phone and try once more.</em>",
    faq_q3: "I can't find the <strong>BromBrom profile</strong> in OsmAnd. Where is it?",
    faq_a3: "If the BromBrom profile isn't visible, it is usually just hidden in OsmAnd's settings, or the initial import was not finished.<br/><br/><strong>How to check step-by-step:</strong><br/>1. <strong>Check if the profile is hidden:</strong><br/>• Open OsmAnd and tap the menu button (<strong>three horizontal lines</strong> in the corner).<br/>• Tap <strong>Settings</strong> (gear icon) and then <strong>Configure profiles</strong>.<br/>• Look for <strong>BromBrom</strong> (orange microcar icon) and switch the <strong>toggle to ON</strong> (orange). To prevent confusion, switch other profiles (like Car) to OFF.<br/>2. <strong>Is BromBrom not in the list at all?</strong><br/>• Open the BromBrom Manager app and tap <strong>\"Reinstall BromBrom in OsmAnd\"</strong>.<br/>• Carefully follow the on-screen steps.<br/><br/><em>Tip:</em> Hard to read on a small phone screen? Open our <a href=\"#visual-guide\" class=\"link-subtle\" style=\"text-decoration: underline;\">Visual Setup Guide</a> on a tablet or computer so you can follow along comfortably.",
    faq_q2: "I only see a <strong>grey grid</strong> (empty screen) or <strong>route calculation fails</strong>. What is wrong?",
    faq_a2: "BromBrom provides custom microcar routing rules, but does not include the base map of the Netherlands. OsmAnd requires this free offline map to display streets and calculate routes.<br/><br/><strong>How to download the free map of the Netherlands in OsmAnd:</strong><br/>1. Open <strong>OsmAnd</strong>.<br/>2. Tap the <strong>three lines menu</strong> in the corner.<br/>3. Tap <strong>Maps & Resources</strong> (or <em>Download maps</em>).<br/>4. Tap <strong>Europe</strong> → <strong>Netherlands</strong> and download the <strong>Standard map</strong>.<br/><br/><em>Once downloaded (takes a few minutes over Wi-Fi), your screen will display full streets and towns in green/white, and routes will calculate instantly!</em>",
    faq_q4: "Help, the navigation is sending me onto <strong>motorways</strong> or <strong>expressways</strong>!",
    faq_a4: "Don't panic: if this happens, OsmAnd is currently set to the standard <strong>car profile</strong>. The app thinks you are driving a normal passenger car instead of a 45 km/u microcar.<br/><br/><strong>How to fix this immediately:</strong><br/>1. Look at the top bar of the OsmAnd navigation screen.<br/>2. Do you see a <strong>blue car icon seen from the front</strong>? That means standard car navigation is active.<br/>3. Tap that icon and select the <strong>BromBrom profile</strong> instead. You can recognize it by the <strong>orange microcar icon seen from the side</strong>.<br/><br/><em>As soon as the orange BromBrom profile is active, motorways, expressways, and C9-restricted roads are always avoided automatically.</em>",
    faq_q10: "How can I <strong>avoid busy roads</strong> and choose <strong>quiet scenic routes</strong>?",
    faq_a10: "Prefer a relaxed drive along calm country roads and dykes rather than busy arterial routes? BromBrom has a built-in feature designed for this!<br/><br/><strong>How to enable quiet routes in OsmAnd:</strong><br/>1. Start a route with the <strong>BromBrom profile</strong> selected.<br/>2. Tap <strong>Options</strong> (the gear icon on the route screen).<br/>3. Tap <strong>Route parameters</strong> (or <em>Avoid roads...</em>).<br/>4. Check the box for <strong>\"Avoid busy roads\"</strong> (<em>Drukke wegen vermijden</em>).<br/><br/><em>OsmAnd will immediately recalculate to guide you along peaceful, scenic rural roads.</em>",
    faq_q11: "How do I turn voice alerts for <strong>speed bumps or pedestrian crossings</strong> on or off?",
    faq_a11: "Find the voice guidance warning you too frequently about speed bumps or crosswalks? You can easily customize this to your liking in OsmAnd:<br/><br/>1. Open OsmAnd and tap the menu button (<strong>three horizontal lines</strong>).<br/>2. Tap <strong>Settings</strong> and select <strong>BromBrom</strong> under App profiles.<br/>3. Tap <strong>Navigation settings</strong> and then <strong>Voice prompts</strong>.<br/>4. Under 'Report', simply tap <strong>Traffic warnings</strong> (speed bumps) or <strong>Pedestrian crosswalks</strong> to toggle them on or off.",
    faq_q5: "Does the app work on an <strong>iPhone</strong> (Apple iOS)?",
    faq_a5: "The automatic BromBrom Manager app is currently <strong>only available for Android</strong>. There is no dedicated app in the Apple App Store yet.<br/><br/><strong>Using an iPhone?</strong> You can still use BromBrom easily via a manual installation:<br/>1. Download the <strong>BromBrom.osf</strong> file using the button at the bottom of this page.<br/>2. Open the file on your iPhone with the free OsmAnd app.<br/>3. Check our step-by-step <a href=\"https://github.com/tbulligan/brombrom/blob/main/docs/manual_install.md\" target=\"_blank\" class=\"link-subtle\" style=\"text-decoration: underline;\">iPhone (iOS) Setup Guide</a> with clear instructions and screenshots.<br/><br/><em>Important notes:</em><br/>1. Manual installations <strong>do not update automatically</strong>; you will need to download the latest file manually for map updates.<br/>2. Navigating on your phone screen is <strong>100% free</strong>. If you want to navigate on your dashboard via <strong>Apple CarPlay</strong>, OsmAnd requires a paid license (<strong>Maps+</strong> is fully sufficient; <strong>Pro</strong> is not needed).",
    faq_q12: "Do I need a <strong>paid OsmAnd subscription</strong> for <strong>Android Auto</strong>?",
    faq_a12: "Navigating directly on your <strong>phone screen</strong> (in a phone mount) is completely free.<br/><br/>If you want to project navigation onto your car dashboard via <strong>Android Auto</strong>, OsmAnd requires a paid license:<br/>• <strong>Maps+</strong> (annual subscription or one-time purchase): <em>Fully sufficient</em> for Android Auto and unlimited map downloads.<br/>• <strong>Pro</strong>: Adds cloud sync, live weather, and 3D terrain, which are <strong>not needed</strong> for BromBrom.<br/><br/><em>Money-saving tip:</em> OsmAnd frequently runs substantial seasonal sales in the Google Play Store (e.g. holidays and sales events). Keep an eye out for discounts!<br/><br/><em>Disclaimer:</em> BromBrom is an independent open-source project and is not affiliated with, endorsed by, or receiving revenue/commission from OsmAnd. All purchase fees go directly to the OsmAnd developers.",
    faq_q9: "Is BromBrom <strong>free</strong>? Can I use it <strong>commercially</strong>?",
    faq_a9: "Yes, BromBrom is <strong>completely free for personal use</strong>! Anyone driving a microcar can use the app and maps free of charge to navigate safely.<br/><br/><strong>Commercial use:</strong><br/>If you wish to use BromBrom commercially (such as in a microcar rental service, dealership, driving school, or fleet), or redistribute the software, prior written permission is required.<br/><br/>For commercial inquiries or partnerships, please <a href=\"#\" id=\"open-contact-btn\" class=\"link-subtle js-open-contact\" style=\"text-decoration: underline;\">contact me directly</a>.",
    faq_q6: "Is the app suitable for <strong>mobility scooters</strong>, <strong>Cantas</strong>, or <strong>invalid carriages</strong>?",
    faq_a6: "<strong>No, BromBrom is strictly tailored for 45 km/h microcars (such as Ligier, Aixam, Microcar, and Chatenet).</strong><br/><br/>By Dutch law, microcars must drive on the main roadway and are never allowed on cycle paths or sidewalks. Mobility scooters and Cantas (invalid carriages) follow entirely different rules: they are permitted to use cycle tracks and pedestrian zones.<br/><br/><em>Do not use BromBrom for mobility scooters or Cantas; the app will route you onto normal roadways instead of cycle paths.</em>",
    faq_q7: "Can I use the app in <strong>Belgium</strong> or <strong>Germany</strong>?",
    faq_a7: "Currently, <strong>no</strong>. The app is specifically built and tested for <strong>Dutch traffic regulations and road infrastructure</strong>.<br/><br/>In the Netherlands, we integrate official data from the National Road Traffic Data portal (NDW) to accurately recognize all C9 vehicle-restriction signs. Belgium and Germany use different signs and regulations for 45 km/u microcars. Once you cross the border, safe routing cannot be guaranteed.<br/><br/><em>Driving near the border? Stay on roads within the Netherlands.</em>",
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
    carousel_step_3_desc: "OsmAnd opens and lists the resources to be imported. Check both <strong>Settings</strong> and <strong>Resources</strong> and then tap <strong>Continue</strong>.",
    carousel_step_4_title: "Confirm Replacement",
    carousel_step_4_desc: "If asked, select <strong>Replace all</strong> to overwrite the existing BromBrom files with the newest update.",
    carousel_step_5_title: "Import Complete",
    carousel_step_5_desc: "The files have been successfully imported. Tap <strong>Close</strong>.",
    carousel_step_6_title: "Open Main Menu",
    carousel_step_6_desc: "Open the main menu in OsmAnd by tapping the three lines icon in the bottom corner.",
    carousel_step_7_title: "Go to Settings",
    carousel_step_7_desc: "Go to <strong>Settings</strong> to manage your active navigation profiles.",
    carousel_step_8_title: "Enable BromBrom & Disable Others",
    carousel_step_8_desc: "Set <strong>BromBrom</strong> to <strong>ON</strong> (orange) and switch all other profiles to <strong>OFF</strong> (grey). BromBrom is now your sole active navigation profile.",
    comparison_title: "Car vs. Microcar Routing",
    comparison_desc: "See the difference: standard car navigation routes you onto forbidden motorways like the A7 (left), whereas BromBrom guides you over safe legal service roads (middle), or quiet scenic routes when avoiding busy arterial roads (right).",
    label_car: "Car (Forbidden)",
    label_brombrom: "BromBrom (Legal)",
    label_scenic: "BromBrom (Scenic & Quiet)"
  }
};

const screenshots = [
  'bbm-0-updates-available.png',
  'bbm-1-open-with-osmand.png',
  'bbm-2-import.png',
  'bbm-3-replace.png',
  'bbm-4-import-complete.png',
  'bbm-5-open-menu.png',
  'bbm-6-open-settings.png',
  'bbm-7-enable-brombrom.png'
].map(name => `/assets/bbm-screenshots/${name}`);

// Language Matcher & Carousel State
let currentLang = 'nl';
let carouselMode = 'first-time';
let activeIndex = 0; // active index inside visibleIndices[carouselMode]

const visibleIndices = {
  'first-time': [0, 1, 2, 3, 4, 5, 6, 7],
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

  // Smooth scroll and auto-expand for Android Auto FAQ from card footnote
  document.addEventListener('click', (e) => {
    const trigger = e.target.closest('.js-open-faq-auto');
    if (trigger) {
      e.preventDefault();
      const autoBtn = document.getElementById('faq-btn-auto');
      if (autoBtn) {
        const item = autoBtn.parentElement;
        item.classList.add('active');
        autoBtn.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
    }
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

