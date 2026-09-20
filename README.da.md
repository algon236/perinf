# PerInf 1.0.2

Personligt arbejds- og informationssystem til Emacs. Opgaver, møder, personer,
beslutninger og huskesedler gemmes som almindelige Org-filer.

## Installation på en ny computer

Krav: Emacs 29.1 eller nyere og Org 9.6 eller nyere. Pakken er testet på macOS
med Emacs 32.0.50. Emacs selv følger ikke med.

Den nemmeste installation er at åbne Emacs, køre `M-x package-install-file` og
vælge `perinf-1.0.2.tar`. Pakken installeres i denne Emacs' pakkemappe, og
kommandoen `M-x perinf` bliver tilgængelig ved efterfølgende starter.

Alternativt: pak ZIP-filen ud og kør i den udpakkede mappe:

```sh
python3 install.py
```

Dette kræver Python 3 og installerer under `~/.emacs.d/lisp/perinf`. En eksisterende
installation eller et eksisterende symbolsk link bliver ikke overskrevet.
Tilføj følgende i din Emacs-konfiguration:

```elisp
(add-to-list 'load-path (expand-file-name "lisp/perinf/" user-emacs-directory))
(require 'perinf)
(global-set-key (kbd "C-æ") #'perinf)
```

Bruger du en anden konfigurationsmappe, skal installationsmålet passe til den.
Eksempel til den selvstændige NXS-konfigurationspakke:

```sh
python3 install.py --target "$HOME/.config/nxs-emacs/lisp/perinf"
```

Læg derefter ovenstående Lisp i den konfigurations `var/private.el`.

## Standardprojekt og filstruktur

Standardmappen er `~/org/agenda/`. Et aktuelt projekt eller et tidligere valgt
projekt har forrang. Du kan vælge et andet projekt med `M-x perinf-open-project`
eller ændre `perinf-default-project-directory`.

På en ny computer: opret først `~/org`, kør `M-x perinf-create-project`, og
accepter standarden `~/org/agenda/`. Vælg navn, sprog og datoformat i dialogen.
Oprettelse af et projekt afviser en allerede eksisterende mappe. Har du allerede
en agenda-mappe med egne filer, skal den bevares og dataoverførslen håndteres
separat; installationsprogrammet flytter eller sammenfletter ikke personlige data.

```text
~/org/agenda/
  perinf-project.org
  data/
    tasks.org
    people.org
    contexts.org
    decisions.org
    memos.org
    meetings/
    transcripts/
    minutes/
  media/
    audio/
    documents/
  archive/
  config/
```

Visse filer og undermapper oprettes først ved brug. Eksisterende almindelige
agenda-filer kan ligge ved siden af denne struktur; de bliver ikke automatisk
konverteret til PerInf-objekter.

## Valgfri integration

```elisp
(perinf-task-activity-mode 1)
(add-to-list 'org-capture-templates (perinf-memo-capture-template "H") t)
```

Åbn projektet med `M-x perinf` før capture. Aktivitetstilstanden registrerer
aktivitet på tilknyttede opgaver og håndterer inaktivitet for deres ure.
Den aktiveres kun, hvis du vælger det. Se README.md for detaljer.

## Kontrol og licens

`make test` kører regressionstests; `make compile` kontrollerer og kompilerer i
en midlertidig mappe; `make package` bygger Emacs TAR-pakken. `python3 build.py`
bygger ZIP og kontrolsummer. `make install` er et udviklerværktøj til opdatering
af en eksisterende kildeinstallation; brug Python-installeren på en ny computer.

Pakken indeholder ingen personlige projekter, private data eller lokal state.
GPL-3.0-or-later, Niels Søndergaard og øvrige angivne bidragydere; se LICENSE.
Se VALIDATION.md for testresultater og begrænsninger.
