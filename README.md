# SoSkrypty — Systemy Operacyjne

Repozytorium zawiera skrypty bashowe zrealizowane w ramach laboratorium z przedmiotu **Systemy Operacyjne**.

## Zawartość repozytorium

```
SoSkrypty/
├── cdlinux.tgz          # dane źródłowe: logi FTP i WWW serwera cdlinux.pl
├── male_skrypty/
│   ├── README.md        # opis skryptów, użycie, przykłady
│   ├── analizator_logow.sh   # skrypt 1: grep, sort, sed
│   ├── szukaj_pliki.sh       # skrypt 2: find
│   └── menu_cdlinux.sh       # skrypt 3: dialog
└── README.md            # ten plik
```

## Małe skrypty

Trzy skrypty (~60-80 linii) analizujące logi serwera projektu CDLinux zawarte w `cdlinux.tgz`.

| Skrypt | Narzędzia | Opis |
|--------|-----------|------|
| `analizator_logow.sh` | grep, sort, sed | Statystyki logów FTP i WWW: top IP, top pliki, filtrowanie |
| `szukaj_pliki.sh`     | find            | Wyszukiwarka plików z wielokryterialnym filtrowaniem |
| `menu_cdlinux.sh`     | dialog          | Interaktywne menu do przeglądania analiz logów |

Szczegółowy opis każdego skryptu (użycie, opcje, przykłady) → [`male_skrypty/README.md`](male_skrypty/README.md)

## Dane źródłowe

`cdlinux.tgz` — logi serwera polskiej dystrybucji Linux (cdlinux.pl, ~2004-2005):
- `cdlinux.ftp.log` — 62 337 linii logów vsftpd
- `cdlinux.www.log` — 79 052 linii logów thttpd (Combined Log Format)
