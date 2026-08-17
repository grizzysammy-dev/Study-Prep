#!/bin/bash
# JQR Bash Project 1 - print common nmap commands from user-supplied IP(s) and port(s)
read -p "Target IP(s) (e.g. 192.168.1.20 or 192.168.1.0/24): " TGT
read -p "Port(s) (e.g. 22,80,443 or - for all): " PORTS
echo
echo "===== Common nmap commands for $TGT (ports: $PORTS) ====="
echo "Ping sweep / host discovery : nmap -sn $TGT"
echo "Quick top-1000 SYN scan     : sudo nmap -sS $TGT"
echo "Full TCP port scan          : sudo nmap -sS -p- $TGT"
echo "Service + default scripts   : sudo nmap -sV -sC -p $PORTS $TGT"
echo "Aggressive (OS,ver,scripts) : sudo nmap -A -p $PORTS $TGT"
echo "UDP top ports               : sudo nmap -sU --top-ports 20 $TGT"
echo "Vuln scripts                : sudo nmap --script vuln -p $PORTS $TGT"
echo "Save all formats            : sudo nmap -sV -p $PORTS -oA scan_$TGT $TGT"
