#!/bin/bash
KATALOG="/tmp/cdlinux"
ARCH=~/SoSkrypty/cdlinux.tgz
NAZWA=""; ROZMIAR=""; TYP=""; DNI=""; EXT=""; VERBOSE=0; EXEC_CMD=""

usage(){
    cat <<HELP
Uzycie: $(basename $0) [OPCJE]
Wyszukiwarka plikow z filtrowaniem i statystykami (na bazie cdlinux).
  -d KATALOG   katalog przeszukiwania (domyslnie: /tmp/cdlinux)
  -n WZORZEC   wzorzec nazwy (np. "*.log")
  -e EXT       rozszerzenie pliku (np. log, iso, txt)
  -s [+/-]N    rozmiar w KB: +N wiekszy, -N mniejszy niz N KB
  -t TYP       typ: f (plik), d (katalog), l (dowiazanie)
  -m DNI       zmodyfikowane w ostatnich N dniach
  -x POLECENIE wykonaj polecenie na znalezionych plikach
  -v           tryb szczegolowy (ls -lah)
  -h           ta pomoc
HELP
    exit 0
}

init(){
    [ -d "$KATALOG" ] && return
    echo "Rozpakowywanie $ARCH do $KATALOG..."
    mkdir -p "$KATALOG"
    tar -xzf "$ARCH" -C "$KATALOG" 2>/dev/null || { echo "Blad: brak $ARCH"; exit 1; }
}

buduj_cmd(){
    local cmd="find \"$KATALOG\""
    [ -n "$TYP" ]     && cmd="$cmd -type $TYP"
    [ -n "$NAZWA" ]   && cmd="$cmd -name \"$NAZWA\""
    [ -n "$EXT" ]     && cmd="$cmd -name \"*.$EXT\""
    [ -n "$ROZMIAR" ] && cmd="$cmd -size ${ROZMIAR}k"
    [ -n "$DNI" ]     && cmd="$cmd -mtime -$DNI"
    echo "$cmd"
}

wyswietl(){
    local w="$1"
    local liczba; liczba=$(echo "$w" | grep -c .)
    echo "Znaleziono: $liczba obiektow w: $KATALOG"
    echo "----------------------------------------------------"
    if [ "$VERBOSE" -eq 1 ]; then
        echo "$w" | xargs -d'\n' ls -lah 2>/dev/null
    else
        echo "$w" | while IFS= read -r f; do
            printf "%-52s %s\n" "$f" "$(du -sh "$f" 2>/dev/null | cut -f1)"
        done
    fi
    echo "----------------------------------------------------"
    echo "Laczny rozmiar: $(echo "$w" | xargs -d'\n' du -shc 2>/dev/null | tail -1 | cut -f1)"
}

statystyki(){
    echo ""
    echo "=== Statystyki ==="
    echo "Pliki wg rozszerzenia:"
    echo "$1" | grep -oE '\.[^./]+$' | sort | uniq -c | sort -rn | head -10 \
        | awk '{printf "  %5d  %s\n",$1,$2}'
    echo "Rozklad wg katalogu:"
    echo "$1" | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -10 \
        | awk '{printf "  %5d  %s\n",$1,$2}'
}

while getopts "d:n:e:s:t:m:x:vh" o; do
    case $o in
        d) KATALOG="$OPTARG" ;; n) NAZWA="$OPTARG"    ;; e) EXT="$OPTARG"      ;;
        s) ROZMIAR="$OPTARG" ;; t) TYP="$OPTARG"      ;; m) DNI="$OPTARG"      ;;
        x) EXEC_CMD="$OPTARG";; v) VERBOSE=1           ;; h) usage              ;;
    esac
done

init
WYNIKI=$(eval "$(buduj_cmd)" 2>/dev/null)
[ -z "$WYNIKI" ] && echo "Brak wynikow dla podanych kryteriow." && exit 0
wyswietl "$WYNIKI"
statystyki "$WYNIKI"
[ -n "$EXEC_CMD" ] && echo "" && echo "=== Wykonywanie: $EXEC_CMD ===" \
    && echo "$WYNIKI" | xargs -d'\n' $EXEC_CMD 2>/dev/null
