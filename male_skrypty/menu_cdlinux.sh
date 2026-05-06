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
    dialog --title "$TITLE" --infobox "Rozpakowywanie archiwum cdlinux.tgz..." 5 50
    mkdir -p "$LOGDIR"
    tar -xzf "$ARCH" -C "$LOGDIR" 2>/dev/null || {
        dialog --title "Blad" --msgbox "Nie mozna rozpakowac:\n$ARCH" 7 50; exit 1
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
    { printf "Lacznie zadan:   %d\n" "$(wc -l < "$WWW")"
      printf "Odpowiedzi 200:  %d\n" "$(grep -c '" 200 ' "$WWW")"
      printf "Odpowiedzi 206:  %d\n" "$(grep -c '" 206 ' "$WWW")"
      printf "Odpowiedzi 404:  %d\n" "$(grep -c '" 404 ' "$WWW")"
      echo "--- Top 15 adresow IP ---"
      grep -oE '^[0-9.]+' "$WWW" | sort | uniq -c | sort -rn | head -15 \
          | awk '{printf "%5d  %s\n",$1,$2}'
      echo "--- Top 10 zadanych zasobow ---"
      grep -oE '"(GET|HEAD) [^ ]+' "$WWW" | sed 's/"GET //;s/"HEAD //' \
          | sort | uniq -c | sort -rn | head -10 | awk '{printf "%5d  %s\n",$1,$2}'
    } > "$TMP"
    dialog --title "WWW - Statystyki" --textbox "$TMP" 28 72
}
szukaj_ip(){
    local ip
    ip=$(dialog --title "Szukaj IP" --inputbox "Podaj adres IP klienta:" 8 50 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] || [ -z "$ip" ] && return
    { echo "=== FTP: $ip ==="
      grep "$ip" "$FTP" | head -20
      echo "=== WWW: $ip ==="
      grep "^$ip " "$WWW" | head -20
    } > "$TMP"
    dialog --title "IP: $ip" --textbox "$TMP" 28 80
}

bledy_404(){
    grep '" 404 ' "$WWW" | grep -oE '"(GET|HEAD) [^ ]+' | sed 's/"GET //;s/"HEAD //' \
        | sort | uniq -c | sort -rn | head -30 | awk '{printf "%5d  %s\n",$1,$2}' > "$TMP"
    dialog --title "Bledy 404 - brakujace zasoby" --textbox "$TMP" 28 72
}

menu(){
    while true; do
        local wyb
        wyb=$(dialog --clear --title "$TITLE" --menu "Wybierz opcje:" 15 55 5 \
            1 "Statystyki FTP" 2 "Statystyki WWW" \
            3 "Szukaj po IP"  4 "Bledy 404"  5 "Wyjscie" \
            3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && break
        case $wyb in
            1) stat_ftp ;; 2) stat_www ;; 3) szukaj_ip ;; 4) bledy_404 ;; 5) break ;;
        esac
    done
    clear
}

init
menu
