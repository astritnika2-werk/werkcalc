# Rruga drejt Google Play (lista kontrolli)

Të dhënat e verifikuara nga faqet zyrtare të Play Console Help (gjendja: tetor 2026).
Rregullat ndryshojnë, ndaj para dërgimit kontrollo edhe një herë në Play Console.

## 1. Testimi në telefon (APK)

**Mënyra A, pa kompjuter të fuqishëm (e rekomanduar):** GitHub Actions.
1. Krijo një repository (private) në GitHub dhe ngarko të gjithë dosjen e projektit.
2. Hap Actions, zgjidh "Build APK", shtyp "Run workflow".
3. Kur mbaron, shkarko artefaktin `werkcalc-apk`, kopjoje `app-release.apk` në telefon dhe instaloje
   (në Android duhet lejuar "Instalo nga burime të panjohura" për aplikacionin e skedarëve).

**Mënyra B, lokalisht:** instalo Flutter dhe Android Studio, pastaj:
```bash
bash tools/setup_android.sh   # krijon android/, vendos emrin WerkCalc dhe ikonën
flutter test
flutter build apk --release
```
APK-ja del te `build/app/outputs/flutter-apk/app-release.apk`.
Kjo APK nënshkruhet me çelës testimi, është e mirë për testim por jo për Google Play.

## 2. Çfarë duhet përpara publikimit

- **applicationId:** `de.werkcalc.werkcalc` (e fiksuar te `tools/setup_android.sh`, përdoret edhe për iOS). Nuk ndryshohet më pas.
- **Çelësi i nënshkrimit (upload keystore):** krijoje një herë dhe ruaje në disa vende të sigurta (humbja e tij ndërlikon përditësimet).
  Pastaj konfiguro `android/key.properties` dhe `android/app/build.gradle` sipas
  [dokumentimit të Flutter për publikim në Android](https://docs.flutter.dev/deployment/android).
  Në Play Console aktivizo Play App Signing.
- **Format publikimi:** Google Play pranon AAB: `flutter build appbundle --release`.
- **Target API:** sipas faqes zyrtare, aplikacionet e reja dhe përditësimet duhet të synojnë Android 16 (API 36) ose më lart
  (afati 31 gusht 2026, me shtyrje të mundshme deri më 1 nëntor 2026). Pas `flutter create`, kontrollo `targetSdk` në
  `android/app/build.gradle` (ose `.kts`) dhe përdor një Flutter stable të përditësuar.
  Burimi: [Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en).
- **Ikona e app-it** dhe emri i shfaqur "WerkCalc": vendosen nga `tools/setup_android.sh`. Tekstet e listimit janë te `docs/BRANDING.md`.

## 3. Llogaria e zhvilluesit dhe testimi i mbyllur

- Llogari Google Play Console: 25 USD një herë, me verifikim identiteti.
- **Rëndësishme për llogari personale të krijuara pas 13 nëntorit 2023:** para se të kërkosh akses në prodhim duhet
  një test i mbyllur me **të paktën 12 testues** që kanë qenë të regjistruar pa ndërprerje **të paktën 14 ditë**.
  Testuesit që dalin para 14 ditëve nuk numërohen. Pas kësaj kërkon "production access"; shqyrtimi zakonisht zgjat deri
  në 7 ditë. Burimi: [App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).
  Praktikisht: duhet të gjesh 12 persona (p.sh. Handwerker të njohur) para se të planifikosh datën e publikimit.
  Llogaria si organizatë (firmë) mund t'i shmanget kësaj kërkese; kontrollo në Play Console.

## 4. Çfarë kërkon Play Console për listimin

- Emri, përshkrimi i shkurtër dhe i plotë (në gjermanisht, gjuha kryesore e tregut).
- Ikonë 512×512 dhe grafikë kryesore 1024×500: gati te `docs/store/` (gjenerohen me `tools/make_icons.py`).
  Pamjet e ekranit (të paktën 2 nga telefoni) i bën pasi të testosh APK-në; kontrollo përmasat aktuale në Console.
- **Politika e privatësisë (URL publike):** përdor tekstin te `docs/DATENSCHUTZ_ENTWURF.md`, plotëso të dhënat dhe
  publiko në një faqe web (p.sh. GitHub Pages ose faqja jote). Teksti në app (Mehr > Datenschutz) është vetëm një draft.
- **Data safety:** në versionin aktual (pa reklama, pa llogari, pa dërgim të dhënash) mund të deklarohet se nuk mblidhen të dhëna.
  Kur të shtohet AdMob, ky formular dhe politika e privatësisë duhet përditësuar (AdMob mbledh ID reklamash dhe të dhëna pajisjeje).
- Pyetësori i vlerësimit të përmbajtjes dhe grupmosha e synuar (jo për fëmijë).
- Impressum: plotëso te Mehr > Impressum (§ 5 DDG), me adresën e vërtetë.

## 5. Para publikimit: kontroll teknik

- [ ] `flutter test` kalon (formulat).
- [ ] Testo në të paktën 2 telefona (një i vjetër, një i ri) dhe me madhësi të ndryshme shkronjash.
- [ ] Testo PDF-in: ndarja (WhatsApp, e-mail, Dokumente), hapja në një lexues PDF, € dhe ä/ö/ü/ß shfaqen saktë.
- [ ] Kontrollo që APK-ja e publikimit nuk kërkon leje të panevojshme (version pa AdMob nuk duhet të ketë leje INTERNET).
- [ ] Plotëso Impressum dhe Datenschutz, hiq çdo "[PLACEHOLDER]".
- [ ] Kontrollo manualisht 3-5 llogaritje me një Handwerker ose me tabela të prodhuesit (veçanërisht Druckverlust).
