#!/bin/bash
LOGDIR="/tmp/cdlinux"
FTP="$LOGDIR/cdlinux.ftp.log"
WWW="$LOGDIR/cdlinux.www.log"
ARCH=~/SoSkrypty/cdlinux.tgz
TMP="/tmp/menu_cdlinux_$$"
TITLE="Analizator logow CDLinux"
cleanup(){ rm -f "$TMP"; }
trap cleanup EXIT
init(){
    [ -f "$FTP" ] && return
    dialog --title "$TITLE" --infobox "Rozpakowywanie cdlinux.tgz..." 4 48
    mkdir -p "$LOGDIR"
    tar -xzf "$ARCH" -C "$LOGDIR" 2>/dev/null || {
        dialog --title "Blad" --msgbox "Nie mozna rozpakowac: $ARCH" 6 50; exit 1
    }
}
stat_ftp(){
    { printf "Lacznie wpisow:      %d\n" "$(wc -l < "$FTP")"
      printf "Udane pobierania:    %d\n" "$(grep -c ' OK DOWNLOAD' "$FTP")"
      printf "Nieudane pobierania: %d\n" "$(grep -c ' FAIL DOWNLOAD' "$FTP")"
      echo "--- Top 15 klientow IP ---"
      grep -oE 'Client "[0-9.]+"' "$FTP" | sed 's/Client "//;s/"//' \
          | sort | uniq -c | sort -rn | head -15 | awk '{printf "%5d  %s\n",$1,$2}'
      echo "--- Top 10 pobieranych plikow ---"
      grep -oE '"/.+?\.iso"' "$FTP" | sed 's/"//g;s|.*/||' \
          | sort | uniq -c | sort -rn | head -10 | awk '{printf "%5d  %s\n",$1,$2}'
    } > "$TMP"
    dialog --title "FTP - Statystyki" --textbox "$TMP" 28 72
}
stat_www(){
    local w; w=$(sed 's/^[^:]*://' "$WWW")
    { printf "Lacznie zadan:   %d\n" "$(echo "$w" | wc -l)"
      printf "Odpowiedzi 200:  %d\n" "$(echo "$w" | grep -c '" 200 ')"
      printf "Odpowiedzi 206:  %d\n" "$(echo "$w" | grep -c '" 206 ')"
      printf "Odpowiedzi 404:  %d\n" "$(echo "$w" | grep -c '" 404 ')"
      echo "--- Top 15 adresow IP ---"
      echo "$w" | grep -oE '^[0-9.]+' | sort | uniq -c | sort -rn | head -15 \
          | awk '{printf "%5d  %s\n",$1,$2}'
      echo "--- Top 10 zadanych zasobow ---"
      echo "$w" | grep -oE '"(GET|HEAD) [^ ]+' | sed 's/"GET //;s/"HEAD //' \
          | sort | uniq -c | sort -rn | head -10 | awk '{printf "%5d  %s\n",$1,$2}'
    } > "$TMP"
    dialog --title "WWW - Statystyki" --textbox "$TMP" 28 72
}
szukaj_ip(){
    local ip
    ip=$(zenity --entry --title "Szukaj po IP" --text "Podaj adres IP:" --width=340 2>/dev/null) \
        || return
    [ -z "$ip" ] && return
    { echo "=== FTP: $ip ==="; grep "$ip" "$FTP" | head -25
      echo ""; echo "=== WWW: $ip ==="
      sed 's/^[^:]*://' "$WWW" | grep "^$ip " | head -25
    } > "$TMP"
    zenity --text-info --title "Wyniki: $ip" --filename="$TMP" --width=750 --height=500 2>/dev/null
}
bledy_404(){
    local n; n=$(grep -c '" 404 ' "$WWW")
    grep '" 404 ' "$WWW" | grep -oE '"(GET|HEAD) [^ ]+' | sed 's/"GET //;s/"HEAD //' \
        | sort | uniq -c | sort -rn | head -30 | awk '{printf "%5d  %s\n",$1,$2}' > "$TMP"
    zenity --text-info --title "Bledy 404 (lacznie: $n)" \
        --filename="$TMP" --width=640 --height=460 2>/dev/null
}
menu(){
    while true; do
        local wyb
        wyb=$(dialog --clear --title "$TITLE" --menu "Wybierz opcje:" 15 55 5 \
            1 "Statystyki FTP  [dialog]" 2 "Statystyki WWW  [dialog]" \
            3 "Szukaj po IP   [zenity]" 4 "Bledy 404       [zenity]" 5 "Wyjscie" \
            3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && break
        case $wyb in
            1) stat_ftp ;; 2) stat_www ;; 3) szukaj_ip ;; 4) bledy_404 ;; 5) break ;;
        esac
    done; clear
}
init
menu
