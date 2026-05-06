#!/bin/bash
LOGDIR="/tmp/cdlinux_$$"
FTP="$LOGDIR/cdlinux.ftp.log"
WWW="$LOGDIR/cdlinux.www.log"
ARCH=~/SoSkrypty/cdlinux.tgz
N=10; TYP="oba"; IP=""; ST=""; PAT=""

usage(){
    cat <<HELP
Uzycie: $(basename $0) [OPCJE]
Analizator logow serwera cdlinux (FTP i WWW) - grep, sort, sed.
  -f        analizuj tylko logi FTP
  -w        analizuj tylko logi WWW
  -i IP     filtruj po adresie IP klienta
  -s STATUS filtruj po statusie (OK, FAIL, 200, 404, 206)
  -n N      wyswietl top N wynikow (domyslnie: 10)
  -p PAT    wyszukaj wzorzec w logach
  -h        wyswietl te pomoc
HELP
    exit 0
}

init(){
    mkdir -p "$LOGDIR"
    tar -xzf "$ARCH" -C "$LOGDIR" 2>/dev/null || { echo "Blad: brak $ARCH"; exit 1; }
    trap "rm -rf $LOGDIR" EXIT
}

linia(){ echo "=================================================="; }

ftp_stat(){
    local d; d=$(cat "$FTP")
    [ -n "$IP" ] && d=$(echo "$d" | grep "$IP")
    [ -n "$ST" ] && d=$(echo "$d" | grep "$ST")
    linia; echo " ANALIZA FTP"; linia
    printf "%-28s %d\n" "Lacznie wpisow:"     "$(echo "$d" | wc -l)"
    printf "%-28s %d\n" "Udane (OK):"         "$(echo "$d" | grep -c ' OK DOWNLOAD')"
    printf "%-28s %d\n" "Nieudane (FAIL):"    "$(echo "$d" | grep -c ' FAIL DOWNLOAD')"
    echo ""
    echo "Top $N klientow IP:"
    echo "$d" | grep -oE 'Client "[0-9.]+"' | sed 's/Client "//;s/"//' \
        | sort | uniq -c | sort -rn | head -"$N" | awk '{printf "  %5d  %s\n",$1,$2}'
    echo ""
    echo "Top $N pobieranych plikow ISO:"
    echo "$d" | grep -oE '"/.+?\.iso"' | sed 's/"//g;s|.*/||' \
        | sort | uniq -c | sort -rn | head -"$N" | awk '{printf "  %5d  %s\n",$1,$2}'
}

www_stat(){
    local d; d=$(cat "$WWW")
    [ -n "$IP" ] && d=$(echo "$d" | grep "^$IP ")
    [ -n "$ST" ] && d=$(echo "$d" | grep "\" $ST ")
    linia; echo " ANALIZA WWW"; linia
    printf "%-28s %d\n" "Lacznie zadan:"   "$(echo "$d" | wc -l)"
    printf "%-28s %d\n" "Odpowiedzi 200:"  "$(echo "$d" | grep -c '" 200 ')"
    printf "%-28s %d\n" "Odpowiedzi 206:"  "$(echo "$d" | grep -c '" 206 ')"
    printf "%-28s %d\n" "Odpowiedzi 404:"  "$(echo "$d" | grep -c '" 404 ')"
    echo ""
    echo "Top $N adresow IP:"
    echo "$d" | grep -oE '^[0-9.]+' | sort | uniq -c | sort -rn | head -"$N" \
        | awk '{printf "  %5d  %s\n",$1,$2}'
    echo ""
    echo "Top $N zadanych zasobow:"
    echo "$d" | grep -oE '"(GET|HEAD|POST) [^ ]+' | sed 's/"GET //;s/"HEAD //;s/"POST //' \
        | sort | uniq -c | sort -rn | head -"$N" | awk '{printf "  %5d  %s\n",$1,$2}'
    echo ""
    echo "Top $N przegladarek:"
    echo "$d" | grep -oE '"[^"]*"$' | sed 's/"//g' | sort | uniq -c | sort -rn | head -"$N" \
        | awk '{printf "  %5d  %s\n",$1,$2}'
}

szukaj(){
    linia; echo " WYSZUKIWANIE: $PAT"; linia
    [ "$TYP" != "www" ] && grep -hE "$PAT" "$FTP" | sed 's/^/[FTP] /' | head -30
    [ "$TYP" != "ftp" ] && grep -hE "$PAT" "$WWW" | sed 's/^/[WWW] /' | head -30
}

while getopts "fwi:s:n:p:h" o; do
    case $o in
        f) TYP="ftp" ;; w) TYP="www" ;; i) IP="$OPTARG" ;;
        s) ST="$OPTARG" ;; n) N="$OPTARG" ;; p) PAT="$OPTARG" ;; h) usage ;;
    esac
done

init
[ -n "$PAT" ] && szukaj && exit 0
[ "$TYP" != "www" ] && ftp_stat && echo ""
[ "$TYP" != "ftp" ] && www_stat
