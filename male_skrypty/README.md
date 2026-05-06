# Małe skrypty - Systemy Operacyjne

Trzy skrypty bashowe analizujące logi serwera projektu **CDLinux** (dystrybucja Linux z 2004-2005 r.).
Dane źródłowe: `cdlinux.tgz` zawierający `cdlinux.ftp.log` (62 337 linii) oraz `cdlinux.www.log` (79 052 linii).

---

## 1. `analizator_logow.sh` — grep, sort, sed

**Zastosowanie:** Analiza i filtrowanie logów serwerów FTP (vsftpd) i WWW (thttpd) projektu CDLinux.

**Co robi:**
- Wyświetla statystyki ogólne logów FTP i WWW (liczba wpisów, sukcesy/błędy, kody HTTP)
- Wyznacza ranking najaktywniejszych adresów IP klientów
- Wyznacza ranking najczęściej pobieranych plików ISO (FTP) i zasobów WWW
- Filtruje dane po IP, statusie (OK/FAIL/200/404/206), szuka wzorców (grep)
- Obsługuje opcje przez `getopts`

**Użycie:**
```
./analizator_logow.sh [OPCJE]
  -f        analizuj tylko logi FTP
  -w        analizuj tylko logi WWW
  -i IP     filtruj po adresie IP klienta
  -s STATUS filtruj po statusie (OK, FAIL, 200, 404, 206)
  -n N      wyświetl top N wyników (domyślnie: 10)
  -p PAT    wyszukaj wzorzec w logach (grep)
  -h        pomoc
```

**Przykłady:**
```bash
./analizator_logow.sh                     # pełna analiza FTP + WWW
./analizator_logow.sh -f -n 20            # top 20 FTP
./analizator_logow.sh -w -s 404           # tylko błędy 404 z WWW
./analizator_logow.sh -i 80.51.83.100     # aktywność konkretnego IP
./analizator_logow.sh -p "cdlinux-duzy"   # wyszukaj wzorzec w obu logach
```

**Narzędzia:** `grep`, `sort`, `sed`, `awk`, `uniq`, `tar`

---

## 2. `szukaj_pliki.sh` — find

**Zastosowanie:** Zaawansowana wyszukiwarka plików z filtrowaniem po wielu kryteriach jednocześnie,
z generowaniem statystyk. Domyślnie przeszukuje katalog z rozpakowanym cdlinux.

**Co robi:**
- Buduje dynamicznie polecenie `find` na podstawie podanych opcji
- Filtruje po: nazwie/wzorcu, rozszerzeniu, typie (plik/katalog/link), rozmiarze, dacie modyfikacji
- Wyświetla wyniki z rozmiarami i łącznym rozmiarem znalezionych plików
- Generuje statystyki: rozkład wg rozszerzenia i katalogu
- Opcjonalnie wykonuje podane polecenie na każdym znalezionym pliku (`-x`)
- Tryb szczegółowy `ls -lah` (`-v`)

**Użycie:**
```
./szukaj_pliki.sh [OPCJE]
  -d KATALOG   katalog przeszukiwania (domyślnie: /tmp/cdlinux)
  -n WZORZEC   wzorzec nazwy (np. "*.log")
  -e EXT       rozszerzenie pliku (np. log, txt)
  -s [+/-]N    rozmiar w KB: +N większy, -N mniejszy niż N KB
  -t TYP       typ: f (plik), d (katalog), l (dowiązanie)
  -m DNI       zmodyfikowane w ostatnich N dniach
  -x POLECENIE wykonaj polecenie na znalezionych plikach
  -v           tryb szczegółowy (ls -lah)
  -h           pomoc
```

**Przykłady:**
```bash
./szukaj_pliki.sh                         # wszystkie pliki w /tmp/cdlinux
./szukaj_pliki.sh -e log -v               # pliki .log, szczegółowy widok
./szukaj_pliki.sh -s +1000                # pliki większe niż 1 MB
./szukaj_pliki.sh -d /var/log -n "*.log" -m 7   # logi z ostatniego tygodnia
./szukaj_pliki.sh -e log -x "wc -l"      # policz linie w każdym pliku .log
```

**Narzędzia:** `find`, `du`, `ls`, `awk`, `sed`, `tar`

---

## 3. `menu_cdlinux.sh` — dialog

**Zastosowanie:** Interaktywne menu tekstowe do przeglądania analiz logów CDLinux.
Nie wymaga znajomości opcji — wszystko obsługuje się przez menu.

**Co robi:**
- Wyświetla interaktywne menu z opcjami analizy (biblioteka `dialog`)
- Automatycznie rozpakowuje `cdlinux.tgz` przy pierwszym uruchomieniu
- Prezentuje statystyki FTP i WWW w oknie przewijalnym
- Pozwala wyszukać aktywność dowolnego adresu IP (formularz dialog)
- Wyświetla ranking błędów 404 (brakujące zasoby na serwerze WWW)
- Sprząta po sobie pliki tymczasowe (`trap ... EXIT`)

**Użycie:**
```bash
./menu_cdlinux.sh    # uruchom interaktywne menu
```

**Opcje menu:**
1. Statystyki FTP — podsumowanie logów vsftpd + top IP + top pliki ISO
2. Statystyki WWW — podsumowanie logów thttpd + top IP + top zasoby
3. Szukaj po IP — wpisz adres IP i pobierz jego aktywność (FTP + WWW)
4. Błędy 404 — ranking brakujących zasobów
5. Wyjście

**Wymagania:** zainstalowany pakiet `dialog` (`apt install dialog`)

**Narzędzia:** `dialog`, `grep`, `sort`, `sed`, `awk`, `tar`

---

## Dane źródłowe

Archiwum `cdlinux.tgz` zawiera logi serwera projektu CDLinux (polska dystrybucja Linux, ~2004-2005):

| Plik                | Opis                          | Liczba linii |
|---------------------|-------------------------------|--------------|
| `cdlinux.ftp.log`   | Logi serwera FTP (vsftpd)     | 62 337       |
| `cdlinux.www.log`   | Logi serwera WWW (thttpd)     | 79 052       |

Format logów FTP: `vsftpd.log.X.gz: <data> [pid N] [ftp] OK/FAIL DOWNLOAD: Client "IP", "ścieżka", N bytes, N Kbyte/sec`  
Format logów WWW: Combined Log Format (Apache-compatible): `IP - - [data] "metoda zasób HTTP" kod bajty "referer" "UA"`
