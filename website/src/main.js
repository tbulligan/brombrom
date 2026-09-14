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
    faq_q8: "Er gebeurt niets na het tikken op <strong>\"OPEN OSMAND\"</strong>. Wat kan ik doen?",
    faq_a8: "<p>OsmAnd stond waarschijnlijk nog open op de achtergrond.</p><p><strong>Zo los je dit op:</strong></p><ol><li>Sluit OsmAnd helemaal af (veeg OsmAnd weg uit het scherm met recente apps).</li><li>Open BromBrom Manager &rarr; tik op <strong>Hulp & Probleemoplossing</strong> &rarr; <strong>\"BromBrom opnieuw installeren in OsmAnd\"</strong>.</li><li>Tik na het downloaden op <strong>OPEN OSMAND</strong>.</li><li>In OsmAnd: vink <strong>Instellingen</strong> en <strong>Bronnen</strong> aan &rarr; tik op <strong>Doorgaan</strong> &rarr; kies <strong>Alles vervangen</strong>.</li></ol>",
    faq_q3: "Ik zie het <strong>BromBrom-profiel</strong> niet in OsmAnd staan. Waar vind ik het?",
    faq_a3: "<p>Het profiel staat meestal nog verborgen:</p><ol><li>In OsmAnd: open het menu (<strong>drie streepjes ☰</strong>) &rarr; <strong>Instellingen</strong> &rarr; <strong>Profielen configureren</strong>.</li><li>Zoek <strong>BromBrom</strong> (oranje autootje) en zet de schakelaar op <strong>AAN</strong> (oranje). Zet overige profielen op <strong>UIT</strong>.</li><li>Staat BromBrom er niet tussen? Open BromBrom Manager &rarr; tik op <strong>Hulp & Probleemoplossing</strong> &rarr; <strong>\"BromBrom opnieuw installeren in OsmAnd\"</strong>.</li></ol>",
    faq_q2: "Ik zie een <strong>grijs raster</strong> (leeg scherm) of de <strong>routeberekening mislukt</strong>. Wat is er mis?",
    faq_a2: "<p>OsmAnd mist de basiskaart van Nederland om wegen te kunnen tonen en routes te berekenen.</p><p><strong>Kaart gratis downloaden in OsmAnd:</strong></p><ol><li>Open het menu (<strong>drie streepjes ☰</strong>) &rarr; <strong>Kaarten en hulpmiddelen</strong>.</li><li>Tik op <strong>Europa</strong> &rarr; <strong>Nederland</strong> &rarr; download de <strong>Standaardkaart</strong>.</li></ol><div class=\"faq-note\">Zodra de download klaar is, verschijnen alle wegen en werkt routeberekening direct.</div>",
    faq_q4: "Help, de navigatie stuurt me alsnog de <strong>snelweg</strong> of <strong>autoweg</strong> op!",
    faq_a4: "<p>Het gewone autoprofiel staat actief in plaats van het BromBrom-profiel.</p><p><strong>Oplossing:</strong></p><ol><li>Tik bovenin het OsmAnd-navigatiescherm op het auto-icoontje.</li><li>Kies het <strong>BromBrom-profiel</strong> (het <strong>oranje autootje van de zijkant gezien</strong>).</li></ol><div class=\"faq-note\">Met BromBrom actief worden snelwegen, autowegen en C9-verbodswegen altijd automatisch vermeden.</div>",
    faq_q10: "Hoe kan ik <strong>drukke wegen vermijden</strong> en voor <strong>rustige binnenroutes</strong> kiezen?",
    faq_a10: "<ol><li>Start een route met het <strong>BromBrom-profiel</strong> actief.</li><li>Tik op <strong>Opties</strong> (tandwieltje) &rarr; <strong>Routeparameters</strong>.</li><li>Vink <strong>\"Drukke wegen vermijden\"</strong> aan.</li></ol><div class=\"faq-note\">OsmAnd herberekent de route meteen langs rustige binnenwegen en dijken.</div>",
    faq_q11: "Hoe zet ik gesproken meldingen voor <strong>verkeersdrempels of zebrapaden</strong> aan of uit?",
    faq_a11: "<ol><li>In OsmAnd: open het menu (<strong>drie streepjes ☰</strong>) &rarr; <strong>Instellingen</strong> &rarr; kies <strong>BromBrom</strong>.</li><li>Tik op <strong>Navigatie-instellingen</strong> &rarr; <strong>Gesproken instructies</strong>.</li><li>Onder het kopje <strong>Meld</strong>: schakel <strong>Verkeerswaarschuwingen</strong> (drempels) of <strong>Zebrapaden</strong> uit of aan.</li></ol>",
    faq_q5: "Werkt de app ook op een <strong>iPhone</strong> (Apple iOS)?",
    faq_a5: "<p>De automatische BromBrom Manager-app is er <strong>alleen voor Android</strong>. Op iOS installeer je de kaarten handmatig:</p><ol><li>Download <strong>BromBrom.osf</strong> onderaan deze pagina.</li><li>Open het bestand op je iPhone met de gratis OsmAnd-app.</li><li>Zie de <a href=\"https://github.com/tbulligan/brombrom/blob/main/docs/manual_install.nl.md\" target=\"_blank\" class=\"link-subtle\" style=\"text-decoration: underline;\">handleiding voor iPhone (iOS)</a> met stap-voor-stap uitleg.</li></ol><div class=\"faq-note\"><strong>Let op:</strong> Navigatie op het telefoonscherm is gratis. Voor <strong>Apple CarPlay</strong> op het dashboard vraagt OsmAnd een betaalde licentie (<strong>Maps+</strong> is ruim voldoende; het duurdere <strong>Pro</strong> is niet nodig).</div>",
    faq_q12: "Heb ik een <strong>betaalde OsmAnd-licentie</strong> nodig voor <strong>Android Auto</strong>?",
    faq_a12: "<p>Op het <strong>telefoonscherm</strong> is navigatie met OsmAnd <strong>volledig gratis</strong>.</p><p>Alleen voor projectie op het dashboardscherm via <strong>Android Auto</strong> vraagt OsmAnd een licentie:</p><ul><li><strong>Maps+</strong> (jaarlijks of eenmalig): <em>Ruim voldoende</em> voor Android Auto en onbeperkte kaarten.</li><li><strong>Pro</strong>: Bevat extra functies (zoals satellietbeelden en reliëf), maar is <strong>niet nodig</strong> voor BromBrom.</li></ul><div class=\"faq-note\"><p><strong>Tip:</strong> OsmAnd biedt in de Play Store regelmatig flinke seizoenskortingen aan.</p><p><strong>Disclaimer:</strong> BromBrom is een onafhankelijk project en verdient niets aan OsmAnd.</p></div>",
    faq_q9: "Is BromBrom <strong>gratis</strong>? Mag ik de app <strong>commercieel</strong> gebruiken?",
    faq_a9: "<p>BromBrom is <strong>100% gratis voor persoonlijk gebruik</strong>.</p><p>Voor <strong>commercieel gebruik</strong> (zoals in een verhuurbedrijf, garage, rijschool of bezorgdienst) of herdistributie is vooraf schriftelijke toestemming nodig. Neem hiervoor <a href=\"#\" id=\"open-contact-btn\" class=\"link-subtle js-open-contact\" style=\"text-decoration: underline;\">contact met mij op</a>.</p>",
    faq_q6: "Is de app ook geschikt voor een <strong>scootmobiel</strong> of <strong>Canta</strong>?",
    faq_a6: "<p><strong>Nee.</strong> BromBrom is uitsluitend gemaakt voor 45 km/u brommobielen (zoals Ligier, Aixam, Microcar).</p><p>Brommobielen moeten volgens de wet op de autorijbaan rijden. Scootmobielen en Cantas (gehandicaptenvoertuigen) mogen juist over het fietspad en het trottoir rijden. Gebruik BromBrom daar niet voor; de routeplanner stuurt je dan over de autorijbaan.</p>",
    faq_q7: "Kan ik de app ook in <strong>België</strong> of <strong>Duitsland</strong> gebruiken?",
    faq_a7: "<p><strong>Nee.</strong> BromBrom is specifiek ontwikkeld voor de Nederlandse wetgeving en weginfrastructuur (met officiële NDW-data voor Nederlandse C9-borden). Buiten Nederland gelden andere regels en bebording voor 45 km/u voertuigen.</p>",
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
    coffee: "Buy me a coffee",
    faq_title: "Frequently Asked Questions",
    faq_q8: "Nothing happens after tapping <strong>\"OPEN OSMAND\"</strong>. What should I do?",
    faq_a8: "<p>OsmAnd was likely still running in the background.</p><p><strong>How to resolve:</strong></p><ol><li>Completely close OsmAnd (swipe it away from recent apps).</li><li>Open BromBrom Manager &rarr; tap <strong>Help</strong> &rarr; <strong>\"Re-install BromBrom in OsmAnd\"</strong>.</li><li>When the download finishes, tap <strong>OPEN OSMAND</strong>.</li><li>In OsmAnd: check both <strong>Settings</strong> and <strong>Resources</strong> &rarr; tap <strong>Continue</strong> &rarr; choose <strong>Replace all</strong>.</li></ol>",
    faq_q3: "I can't find the <strong>BromBrom profile</strong> in OsmAnd. Where is it?",
    faq_a3: "<p>The profile is usually just hidden:</p><ol><li>In OsmAnd: open the menu (<strong>three lines ☰</strong>) &rarr; <strong>Settings</strong> &rarr; <strong>Configure profiles</strong>.</li><li>Find <strong>BromBrom</strong> (orange microcar icon) and switch it to <strong>ON</strong> (orange). Set other profiles to <strong>OFF</strong>.</li><li>Not in the list at all? Open BromBrom Manager &rarr; tap <strong>Help</strong> &rarr; <strong>\"Re-install BromBrom in OsmAnd\"</strong>.</li></ol>",
    faq_q2: "I only see a <strong>grey grid</strong> (empty screen) or <strong>route calculation fails</strong>. What is wrong?",
    faq_a2: "<p>OsmAnd is missing the offline base map of the Netherlands.</p><p><strong>How to download the free map in OsmAnd:</strong></p><ol><li>Open the menu (<strong>three lines ☰</strong>) &rarr; <strong>Maps & Resources</strong>.</li><li>Tap <strong>Europe</strong> &rarr; <strong>Netherlands</strong> &rarr; download the <strong>Standard map</strong>.</li></ol><div class=\"faq-note\">Once downloaded, roads appear and route calculation works immediately.</div>",
    faq_q4: "Help, the navigation is sending me onto <strong>motorways</strong> or <strong>expressways</strong>!",
    faq_a4: "<p>The standard car profile is active instead of the BromBrom profile.</p><p><strong>Fix:</strong></p><ol><li>Tap the vehicle icon at the top of the OsmAnd navigation screen.</li><li>Select the <strong>BromBrom profile</strong> (the <strong>orange microcar seen from the side</strong>).</li></ol><div class=\"faq-note\">With BromBrom selected, motorways, expressways, and C9-restricted roads are always avoided automatically.</div>",
    faq_q10: "How can I <strong>avoid busy roads</strong> and choose <strong>quiet scenic routes</strong>?",
    faq_a10: "<ol><li>Start a route with the <strong>BromBrom profile</strong> active.</li><li>Tap <strong>Options</strong> (gear icon) &rarr; <strong>Route parameters</strong>.</li><li>Check <strong>\"Drukke wegen vermijden\"</strong> (Avoid busy roads).</li></ol><div class=\"faq-note\">OsmAnd will recalculate to favor calm secondary and rural roads.</div>",
    faq_q11: "How do I turn voice alerts for <strong>speed bumps or pedestrian crossings</strong> on or off?",
    faq_a11: "<ol><li>In OsmAnd: open menu (<strong>three lines ☰</strong>) &rarr; <strong>Settings</strong> &rarr; select <strong>BromBrom</strong>.</li><li>Tap <strong>Navigation settings</strong> &rarr; <strong>Voice prompts</strong>.</li><li>Under <strong>Report</strong>: toggle <strong>Traffic warnings</strong> (speed bumps) or <strong>Pedestrian crosswalks</strong> on or off.</li></ol>",
    faq_q5: "Does the app work on an <strong>iPhone</strong> (Apple iOS)?",
    faq_a5: "<p>The BromBrom Manager app is <strong>Android-only</strong>. On iOS, you install maps manually:</p><ol><li>Download <strong>BromBrom.osf</strong> at the bottom of this page.</li><li>Open the file on your iPhone with the free OsmAnd app.</li><li>See the <a href=\"https://github.com/tbulligan/brombrom/blob/main/docs/manual_install.md\" target=\"_blank\" class=\"link-subtle\" style=\"text-decoration: underline;\">iPhone (iOS) guide</a> for step-by-step instructions.</li></ol><div class=\"faq-note\"><strong>Note:</strong> Screen navigation is free. Displaying on your dashboard via <strong>Apple CarPlay</strong> requires an OsmAnd license (<strong>Maps+</strong> is fully sufficient; <strong>Pro</strong> is not needed).</div>",
    faq_q12: "Do I need a <strong>paid OsmAnd subscription</strong> for <strong>Android Auto</strong>?",
    faq_a12: "<p>On your <strong>phone screen</strong>, OsmAnd navigation is <strong>completely free</strong>.</p><p>A paid license is only required to display navigation on your car dashboard via <strong>Android Auto</strong>:</p><ul><li><strong>Maps+</strong> (annual or one-time): <em>Fully sufficient</em> for Android Auto and unlimited maps.</li><li><strong>Pro</strong>: Adds extras (satellite imagery, elevation), but is <strong>not needed</strong> for BromBrom.</li></ul><div class=\"faq-note\"><p><strong>Tip:</strong> OsmAnd frequently runs seasonal sales in the Google Play Store.</p><p><strong>Disclaimer:</strong> BromBrom is an independent open-source project and receives no money from OsmAnd.</p></div>",
    faq_q9: "Is BromBrom <strong>free</strong>? Can I use it <strong>commercially</strong>?",
    faq_a9: "<p>BromBrom is <strong>100% free for personal use</strong>.</p><p>For <strong>commercial use</strong> (microcar rental, dealerships, driving schools, fleet operations) or redistribution, prior written permission is required. Please <a href=\"#\" id=\"open-contact-btn\" class=\"link-subtle js-open-contact\" style=\"text-decoration: underline;\">contact me directly</a>.</p>",
    faq_q6: "Is the app suitable for <strong>mobility scooters</strong>, <strong>Cantas</strong>, or <strong>invalid carriages</strong>?",
    faq_a6: "<p><strong>No.</strong> BromBrom is built exclusively for 45 km/u microcars (such as Ligier, Aixam, Microcar).</p><p>Microcars must legally drive on the main roadway. Mobility scooters and Cantas (invalid carriages) are permitted on cycle paths and sidewalks. Do not use BromBrom for them; it will route you onto vehicle roadways.</p>",
    faq_q7: "Can I use the app in <strong>Belgium</strong> or <strong>Germany</strong>?",
    faq_a7: "<p><strong>No.</strong> BromBrom is specifically built for Dutch traffic laws and road networks (using official NDW sign data for Dutch C9 signs). Foreign signs and microcar regulations are not supported.</p>",
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

