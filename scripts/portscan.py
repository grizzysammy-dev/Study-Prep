#!/usr/bin/env python3
"""JQR Python Project 1 - simple TCP port scanner (concepts: sockets, loops, argparse)."""
import socket, argparse
p = argparse.ArgumentParser(description="Tiny TCP port scanner")
p.add_argument("host"); p.add_argument("-p","--ports",default="22,80,443,8080")
a = p.parse_args()
ports = [int(x) for x in a.ports.split(",")]
print(f"Scanning {a.host} ...")
for port in ports:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM); s.settimeout(0.5)
    state = "OPEN" if s.connect_ex((a.host, port)) == 0 else "closed"
    print(f"  {port:>5}/tcp  {state}")
    s.close()
