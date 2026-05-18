#!/bin/bash
# ==============================================================================
# Licencja: MIT License - dozwolone uzywanie, kopiowanie i modyfikacja
# Autor:    Filip Zdrojewski
# Wersja:   1.0
# Opis:     Skrypt do tworzenia szyfrowanych kopii zapasowych katalogow
#           z wysylka na serwer zewnetrzny przez SSH. Obsługuje tworzenie
#           kopii (backup), listowanie oraz przywracanie danych (restore).
#           Dane tymczasowe zapisywane w /tmp i usuwane po zakonczeniu.
# Użycie:   backuper.sh [-b] [-r] [-l] [-d KATALOG] [-o KATALOG] [-n N] [-v] [-h]
# ==============================================================================

VERSION="1.0"
AUTHOR="Filip Zdrojewski"
RC_FILE="$HOME/.backuper.rc"
TMP_DIR="/tmp/backuper_$$"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# --- Wartości domyślne (nadpisywane przez .rc i opcje) ---
BACKUP_DIRS=""
REMOTE_HOST=""
REMOTE_DIR="/backups"
KEEP_LAST=7
GPG_PASS_FILE="$HOME/.backup_pass"
LOG_FILE="$HOME/.backuper.log"
RESTORE_DIR="$HOME/przywrocone"
DO_BACKUP=0; DO_RESTORE=0; DO_LIST=0

# --- Wczytaj plik konfiguracyjny .rc jesli istnieje ---
[ -f "$RC_FILE" ] && source "$RC_FILE"

usage() {
    cat <<HELP
Uzycie: $(basename "$0") [OPCJE]
Szyfrowane kopie zapasowe z wysylka na serwer SSH.
  -b            wykonaj kopie zapasowa (backup)
  -r            przywroc dane z wybranej kopii (interaktywnie przez dialog)
  -l            wyswietl liste dostepnych kopii na serwerze
  -d KATALOG    katalog zrodlowy do backupu (mozna podac wielokrotnie)
  -o KATALOG    katalog docelowy przywracania (domyslnie: ~/przywrocone)
  -n N          liczba przechowywanych kopii (domyslnie: $KEEP_LAST)
  -v            wersja i autor
  -h            ta pomoc
HELP
    exit 0
}

wersja() { echo "backuper.sh v$VERSION -- $AUTHOR"; exit 0; }

# --- Inicjalizacja: katalog tymczasowy + trap sprzatajacy ---
init() {
    mkdir -p "$TMP_DIR"
    trap "rm -rf '$TMP_DIR'; log 'INFO' 'Skrypt zakonczony, /tmp wyczyszczony'" EXIT
    [ -z "$REMOTE_HOST" ] && { echo "Blad: brak REMOTE_HOST w $RC_FILE"; exit 1; }
    [ -z "$BACKUP_DIRS" ] && [ "$DO_BACKUP" -eq 1 ] && { echo "Blad: brak BACKUP_DIRS"; exit 1; }
}

# --- Zapis do logu ---
log() {
    local level="$1" msg="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg" >> "$LOG_FILE"
    echo "[$level] $msg"
}

# --- Sprawdz wymagane narzedzia ---
sprawdz_zaleznosci() {
    local brakuje=0
    for cmd in tar gpg scp ssh dialog; do
        command -v "$cmd" &>/dev/null || { echo "Brak: $cmd"; brakuje=1; }
    done
    [ "$brakuje" -eq 1 ] && exit 1
}

# --- Tworzenie kopii zapasowej ---
wykonaj_backup() {
    log "INFO" "Rozpoczynam backup katalogow: $BACKUP_DIRS"
    local archiwum="$TMP_DIR/backup_${TIMESTAMP}.tar.gz"
    local zaszyfrowany="$archiwum.gpg"

    # Tworzenie archiwum tar.gz w /tmp
    # shellcheck disable=SC2086
    tar -czf "$archiwum" $BACKUP_DIRS 2>/dev/null \
        || { log "ERROR" "Blad tworzenia archiwum"; exit 1; }
    local rozmiar; rozmiar=$(du -sh "$archiwum" | cut -f1)
    log "INFO" "Archiwum utworzone: $rozmiar"

    # Szyfrowanie GPG (AES-256) haslem z pliku
    gpg --batch --yes --passphrase-file "$GPG_PASS_FILE" \
        --symmetric --cipher-algo AES256 \
        --output "$zaszyfrowany" "$archiwum" 2>/dev/null \
        || { log "ERROR" "Blad szyfrowania GPG"; exit 1; }
    log "INFO" "Archiwum zaszyfrowane GPG AES-256"

    # Wysylka na serwer przez scp
    scp "$zaszyfrowany" "${REMOTE_HOST}:${REMOTE_DIR}/" 2>/dev/null \
        || { log "ERROR" "Blad wysylki na ${REMOTE_HOST}"; exit 1; }
    log "INFO" "Backup wyslany na ${REMOTE_HOST}:${REMOTE_DIR}"

    # Rotacja: usun stare kopie (zostaw KEEP_LAST najnowszych)
    ssh "$REMOTE_HOST" \
        "ls -t ${REMOTE_DIR}/backup_*.tar.gz.gpg 2>/dev/null | tail -n +$((KEEP_LAST+1)) | xargs -r rm -f" 2>/dev/null
    log "INFO" "Rotacja: zachowano ostatnich $KEEP_LAST kopii"
}

# --- Lista kopii na serwerze ---
lista_kopii() {
    log "INFO" "Pobieranie listy kopii z ${REMOTE_HOST}"
    ssh "$REMOTE_HOST" "ls -lh ${REMOTE_DIR}/backup_*.tar.gz.gpg 2>/dev/null" \
        || { log "WARN" "Brak kopii lub problem z polaczeniem"; exit 1; }
}

# --- Przywracanie przez dialog ---
przywroc() {
    # Pobierz liste plikow z serwera
    local lista; lista=$(ssh "$REMOTE_HOST" \
        "ls ${REMOTE_DIR}/backup_*.tar.gz.gpg 2>/dev/null | xargs -I{} basename {}" 2>/dev/null)
    [ -z "$lista" ] && { log "WARN" "Brak kopii do przywrocenia"; exit 1; }

    # Zbuduj menu dla dialog
    local opcje=(); local i=1
    while IFS= read -r plik; do
        opcje+=("$i" "$plik"); ((i++))
    done <<< "$lista"

    # Wyswietl interaktywne menu dialog
    local wybor
    wybor=$(dialog --clear --title "Przywracanie kopii zapasowej" \
        --menu "Wybierz kopie do przywrocenia:" 20 65 12 \
        "${opcje[@]}" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && { clear; log "INFO" "Przywracanie anulowane"; exit 0; }
    clear

    # Pobierz wybrany plik
    local wybrany_plik; wybrany_plik=$(echo "$lista" | sed -n "${wybor}p")
    log "INFO" "Przywracanie: $wybrany_plik"
    local lokalny="$TMP_DIR/$wybrany_plik"

    scp "${REMOTE_HOST}:${REMOTE_DIR}/${wybrany_plik}" "$lokalny" 2>/dev/null \
        || { log "ERROR" "Blad pobierania kopii"; exit 1; }

    # Odszyfruj GPG
    local odszyfrowany="${lokalny%.gpg}"
    gpg --batch --yes --passphrase-file "$GPG_PASS_FILE" \
        --output "$odszyfrowany" --decrypt "$lokalny" 2>/dev/null \
        || { log "ERROR" "Blad deszyfrowania"; exit 1; }

    # Rozpakuj do katalogu docelowego
    mkdir -p "$RESTORE_DIR"
    tar -xzf "$odszyfrowany" -C "$RESTORE_DIR" 2>/dev/null \
        || { log "ERROR" "Blad rozpakowywania"; exit 1; }
    log "INFO" "Przywrocono do: $RESTORE_DIR"
}

# --- Parsowanie opcji przez getopts ---
while getopts "brlvhd:o:n:" o; do
    case $o in
        b) DO_BACKUP=1 ;;
        r) DO_RESTORE=1 ;;
        l) DO_LIST=1 ;;
        d) BACKUP_DIRS="$BACKUP_DIRS $OPTARG" ;;
        o) RESTORE_DIR="$OPTARG" ;;
        n) KEEP_LAST="$OPTARG" ;;
        v) wersja ;;
        h) usage ;;
        *) usage ;;
    esac
done

# --- Glowna logika ---
sprawdz_zaleznosci
init

[ "$DO_LIST"    -eq 1 ] && lista_kopii
[ "$DO_BACKUP"  -eq 1 ] && wykonaj_backup
[ "$DO_RESTORE" -eq 1 ] && przywroc
[ "$DO_LIST" -eq 0 ] && [ "$DO_BACKUP" -eq 0 ] && [ "$DO_RESTORE" -eq 0 ] && usage
