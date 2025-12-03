#!/usr/bin/env python3
"""
Filter IP addresses, removing those already covered by CIDR ranges in roblox.lst
"""

import sys
import ipaddress
from pathlib import Path

def main():
    if len(sys.argv) < 2:
        print("Usage: filter_ips.py <roblox.lst>", file=sys.stderr)
        sys.exit(1)
    
    lst_file = Path(sys.argv[1])
    covered_networks = []
    
    # Load covered networks from roblox.lst
    if lst_file.exists():
        with open(lst_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    try:
                        covered_networks.append(ipaddress.ip_network(line, strict=False))
                    except ValueError:
                        pass
    
    # Check each IP from stdin
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            # Parse CIDR (e.g., 1.2.3.4/32)
            ip_net = ipaddress.ip_network(line, strict=False)
            # Check if any covered network contains this IP
            is_covered = False
            for covered in covered_networks:
                # Check if the IP is in the covered network
                if ip_net.network_address in covered:
                    is_covered = True
                    break
            if not is_covered:
                print(line)
        except ValueError:
            # If not a valid CIDR, try as IP
            try:
                ip_str = line.split('/')[0]
                ip = ipaddress.ip_address(ip_str)
                is_covered = False
                for covered in covered_networks:
                    if ip in covered:
                        is_covered = True
                        break
                if not is_covered:
                    print(line)
            except ValueError:
                pass

if __name__ == '__main__':
    main()

