#!/bin/bash
# JQR Bash Project 2 - check dir exists; if so check file; create file if missing
DIR="${1:-/tmp/jcu_demo}"
FILE="${2:-notes.txt}"
if [ -d "$DIR" ]; then
    echo "[+] Directory '$DIR' exists."
    if [ -f "$DIR/$FILE" ]; then
        echo "[+] File '$FILE' already exists in '$DIR'."
    else
        touch "$DIR/$FILE"
        echo "[!] File '$FILE' did NOT exist -> it has now been created."
    fi
else
    echo "[-] Directory '$DIR' does not exist. Creating it and the file."
    mkdir -p "$DIR" && touch "$DIR/$FILE"
    echo "[!] Created directory '$DIR' and file '$FILE'."
fi
