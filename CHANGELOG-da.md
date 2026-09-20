# Ikke udgivet — statistik

- Permanent Statistik-menu med årsvælger, nye rapporter og rapportarkiv.
- Gemte Org-rapporter og JSON-øjebliksbilleder pr. projekt og år.
- Sammenligning med sidste rapport og seneste måling før årsskiftet.
- Årsaktivitet og månedsfordeling med tydelige begrænsninger for historiske data.
- Datakontrol og beskyttelse mod ugemte kildefiler og beskadiget rapportarkiv.

# 1.0.2 — 20. september 2026

- Standardprojektmappe: `~/org/agenda/`.
- Åbn standardprojektet, når intet aktuelt eller tidligere projekt er valgt.
- Brug samme standard ved oprettelse og valg af projekt.
- Selvstændig installationspakke med ZIP, Emacs TAR og kontrolsummer.
- Bevar seneste lokale forbedringer af projektbundne ure på startsiden.

# PerInf 1.0.1 — ændringer og kontrol

Udført 11. september 2026.

PerInf er installeret under `~/.emacs.d/lisp/perinf/` og indlæst i den allerede
åbne Emacs. Både grænsefladens standardsprog og den lokale sprogtilsidesættelse
er sat til dansk. Projektdataenes eget sprog er ikke ændret.

## Ændringer

- Dansk programoverskrift, buffernavn og modebetegnelse. De tidligere
  engelske valideringsbeskeder har nu danske oversættelser. De fem eksisterende
  grænsefladesprog er bevaret; nye valideringsbeskeder falder tilbage på engelsk
  for fransk, tysk og spansk.
- Flad pakkestruktur med alle 22 runtime-moduler i pakkens rod, korrekt
  projektadresse, package headers, eksplicitte afhængigheder, feature-navne,
  autoloads og fuld GPL-licenstekst. En MELPA-opskrift følger med.
- Lokal installer opretter `lisp/perinf/` automatisk og genererer autoloads.
  Bibliotekerne ændrer ikke længere selv load-path. Almindelig package.el-
  installation er fortsat mulig og bruger Emacs' pakkemappe.
- Flere offentlige M-x-kommandoer manglede interaktiv indsamling af obligatoriske
  objekt-id'er. De viser nu et valg. Den fælles vælger skelner også mellem
  objekter med samme titel ved hjælp af deres id.
- Intern Org-læsning kører uden brugerens mode-hooks. Egne TODO-ord og
  TODO-hooks påvirker ikke længere PerInfs interne statusændringer.
- Filer med ugemte ændringer i en åben Emacs-buffer overskrives ikke.
  Eksisterende filrettigheder bevares ved atomisk filudskiftning.
- Opgaveaktivitet bindes til det rigtige projekt. Fejlbehæftede skriveforsøg
  gentages ikke ved hvert tastetryk. Timer og hooks kan ryddes op ved unload,
  og batch-indlæsning starter ikke baggrundstimeren.
- Projektoprettelse sletter ikke længere en mappe, den ikke selv har oprettet,
  ved en fejl. Oprettelse af nye filer bruger eksklusiv oprettelse.
- Projektets sprog og skemaversion valideres. Den tidligere uimplementerede
  offentlige læsefunktion kan nu læse lagrede objekter og mødeunderpunkter.
- Normaliserede datoer/tider valideres, og sekunder bevares. Det eksisterende
  localized-long-valg accepterer ISO-datoer ved indtastning.
- Projektmetadata genbruges under den enkelte tegning af grænsefladen.
  Pakkeopbygning bruger en ren midlertidig mappe og tager kun kildefiler med.

## Kontroller

- 42/42 tests bestået i ren Emacs, herunder de oprindelige 30 funktionstests.
- 42/42 tests bestået med org-roam og database-autosynkronisering aktiveret
  mod en midlertidig database.
- Syntakskontrol og bytekompilering med advarsler behandlet som fejl bestået.
  Modulerne er også kontrolleret ved separat kompilering.
- package-lint: ingen fund i hovedpakken med det lokale pakkearkivs metadata.
- package-install-file af tar-pakken i et tomt Emacs-miljø bestået; M-x perinf
  blev autoloadet og viste dansk UI.
- Lokal installation til en ny mappe med mellemrum i stien bestået, inklusive
  direkte autoload af perinf-home.
- Dansk gengivelse kontrolleret i den åbne Emacs. locate-library peger på den
  nye lokale installation.
- init.el på disk og i den åbne, ændrede buffer er sammenlignet med kopier fra
  før flytningen. Kun PerInf-indlæsningsblokken er ændret; de tidligere ugemte
  ændringer er stadig ugemte. PerInf-tilstandsfilens indhold er uændret.
- Kildepakke og installerede runtime-filer er sammenlignet. Tar-pakken indeholder
  ikke bytekode eller macOS' AppleDouble-filer.

## Afgrænsning

Den konkrete testversion er Emacs 32.0.50. Emacs 31 er ikke særskilt afprøvet.
Doct er ikke installeret i brugerens Emacs; PerInf har ingen doct-afhængighed
eller særskilt doct-integration. Eksisterende capture-skabeloner er ikke ændret.

Pakken er forberedt til MELPA. Optagelse kræver MELPA-vedligeholdernes
godkendelse. Vejledningen er kontrolleret mod MELPAs CONTRIBUTING.org.

Atomiske skrivninger gælder den enkelte fil. Handlinger over flere filer er
fortsat ikke database-transaktioner, og samtidige skrivninger fra forskellige
Emacs-processer er ikke låst samlet. Lavniveaufejl kan fortsat være på engelsk.
Testene er ikke en garanti for, at enhver mulig fejl eller kombination af
brugeropsætninger er dækket.

## Leverance

`perinf-1.0.1-source.zip` indeholder den komplette færdige kildekode, tests,
eksempelprojekt, byggefunktioner og dokumentation.

`perinf-1.0.1.tar` er pakken til M-x package-install-file. Den lokale installation
er allerede udført; tar-pakken behøver ikke også blive installeret dér.
