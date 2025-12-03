#!/usr/bin/env python3
"""
Parse PacketTunnel log files from logs/ folder to extract Roblox domains and IP addresses.
Compare with roblox.lst to find only missing IPs/domains that need to be added.
"""

import re
import sys
from pathlib import Path
from collections import defaultdict
import ipaddress

# Pattern to match .roblox.com domains
ROBLOX_DOMAIN_PATTERN = re.compile(r'([a-zA-Z0-9.-]+\.roblox\.com)')

def is_dummy_ip(ip):
    """Check if IP is a dummy/internal IP that should be filtered out."""
    if ip.startswith('198.18.'):
        return True
    if ip.startswith('::ffff:198.18.'):
        return True
    if ip == '0.0.0.0':
        return True
    return False

def load_covered_ranges(lst_file):
    """Load CIDR ranges from file (ASN prefixes or roblox.lst)."""
    covered_networks = []
    if not lst_file.exists():
        print(f"Warning: {lst_file} not found. All IPs will be considered missing.", file=sys.stderr)
        return covered_networks
    
    with open(lst_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                try:
                    network = ipaddress.ip_network(line, strict=False)
                    covered_networks.append(network)
                except ValueError:
                    print(f"Warning: Invalid CIDR in {lst_file.name}: {line}", file=sys.stderr)
    
    file_name = lst_file.name if hasattr(lst_file, 'name') else str(lst_file)
    print(f"Loaded {len(covered_networks)} CIDR ranges from {file_name}", file=sys.stderr)
    return covered_networks

def ip_is_covered(ip_str, covered_networks):
    """Check if an IP address is covered by any of the CIDR ranges."""
    try:
        ip = ipaddress.ip_address(ip_str)
        for network in covered_networks:
            if ip in network:
                return True
        return False
    except ValueError:
        return False

def parse_log_file(log_path):
    """Parse a log file and extract Roblox domains and IPs."""
    domains = set()
    domain_ips = defaultdict(set)
    all_ips = set()
    
    current_dns_record = {}
    in_dns_record = False
    
    with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            # Extract domains from various log entries
            for match in ROBLOX_DOMAIN_PATTERN.finditer(line):
                domain = match.group(1).lower()
                domains.add(domain)
            
            # Parse DNS response records
            if 'dns response record => {' in line:
                in_dns_record = True
                current_dns_record = {}
            elif in_dns_record:
                # Extract result (IP address)
                if 'result =' in line:
                    result_match = re.search(r'result\s*=\s*([^,]+)', line)
                    if result_match:
                        result = result_match.group(1).strip()
                        # Remove quotes if present
                        result = result.strip('"\'')
                        current_dns_record['result'] = result
                
                # Extract host (domain name)
                if 'host =' in line:
                    host_match = re.search(r'host\s*=\s*([^,]+)', line)
                    if host_match:
                        host = host_match.group(1).strip().strip('"\'')
                        current_dns_record['host'] = host.lower()
                
                # End of DNS record
                if line.strip().endswith('}'):
                    in_dns_record = False
                    if 'result' in current_dns_record and 'host' in current_dns_record:
                        ip = current_dns_record['result']
                        host = current_dns_record['host']
                        
                        # Only process if it's a Roblox domain
                        if '.roblox.com' in host:
                            # Filter out dummy IPs
                            if not is_dummy_ip(ip):
                                # Clean up IPv6-mapped IPv4 addresses
                                if ip.startswith('::ffff:'):
                                    ip = ip.replace('::ffff:', '')
                                
                                # Validate it's a real IP
                                if re.match(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$', ip):
                                    domain_ips[host].add(ip)
                                    all_ips.add(ip)
    
    return domains, domain_ips, all_ips

def main():
    script_dir = Path(__file__).parent
    logs_dir = script_dir / 'logs'
    
    # Load covered ranges from ASN prefixes file (passed as argument) or roblox.lst (fallback)
    if len(sys.argv) > 1:
        asn_file = Path(sys.argv[1])
        if asn_file.exists():
            covered_networks = load_covered_ranges(asn_file)
        else:
            print(f"Warning: ASN prefixes file {asn_file} not found, using roblox.lst as fallback", file=sys.stderr)
            lst_file = script_dir / 'roblox.lst'
            covered_networks = load_covered_ranges(lst_file)
    else:
        lst_file = script_dir / 'roblox.lst'
        covered_networks = load_covered_ranges(lst_file)
    
    # Find all log files in logs/ directory
    if not logs_dir.exists():
        print(f"Warning: {logs_dir} directory not found. Will use ASN prefixes only.", file=sys.stderr)
        # Create empty output files so downloader can continue
        (script_dir / 'domains.txt').touch()
        (script_dir / 'ips_missing.txt').touch()
        sys.exit(0)
    
    log_files = list(logs_dir.glob('*.log'))
    if not log_files:
        print(f"Warning: No .log files found in {logs_dir}. Will use ASN prefixes only.", file=sys.stderr)
        # Create empty output files so downloader can continue
        (script_dir / 'domains.txt').touch()
        (script_dir / 'ips_missing.txt').touch()
        sys.exit(0)
    
    all_domains = set()
    all_domain_ips = defaultdict(set)
    all_ips = set()
    
    # Parse all log files
    for log_file in sorted(log_files):
        print(f"Parsing {log_file.name}...", file=sys.stderr)
        domains, domain_ips, ips = parse_log_file(log_file)
        all_domains.update(domains)
        for domain, ip_set in domain_ips.items():
            all_domain_ips[domain].update(ip_set)
        all_ips.update(ips)
    
    # Filter out IPs that are already covered by roblox.lst
    missing_ips = []
    covered_ips = []
    
    for ip in sorted(all_ips, key=lambda x: tuple(map(int, x.split('.')))):
        if ip_is_covered(ip, covered_networks):
            covered_ips.append(ip)
        else:
            missing_ips.append(ip)
    
    # Filter domains - keep all domains for now (we'll resolve them and check coverage)
    # But we can track which domains have missing IPs
    domains_with_missing_ips = set()
    for domain, ip_set in all_domain_ips.items():
        for ip in ip_set:
            if not ip_is_covered(ip, covered_networks):
                domains_with_missing_ips.add(domain)
                break
    
    # Sort domains
    sorted_domains = sorted(all_domains)
    sorted_missing_domains = sorted(domains_with_missing_ips) if domains_with_missing_ips else sorted_domains
    
    # Write all domains (we'll resolve them and check coverage in downloader)
    domains_file = script_dir / 'domains.txt'
    with open(domains_file, 'w') as f:
        for domain in sorted_domains:
            f.write(f"{domain}\n")
    
    # Write missing IPs (not covered by roblox.lst)
    missing_ips_file = script_dir / 'ips_missing.txt'
    with open(missing_ips_file, 'w') as f:
        for ip in missing_ips:
            f.write(f"{ip}\n")
    
    # Write domains that have missing IPs
    missing_domains_file = script_dir / 'domains_missing.txt'
    with open(missing_domains_file, 'w') as f:
        for domain in sorted_missing_domains:
            f.write(f"{domain}\n")
    
    # Print summary
    print(f"\nExtraction Summary:", file=sys.stderr)
    print(f"  Total unique Roblox domains found: {len(sorted_domains)}", file=sys.stderr)
    print(f"  Domains with missing IPs: {len(domains_with_missing_ips)}", file=sys.stderr)
    print(f"  Total unique IP addresses found: {len(all_ips)}", file=sys.stderr)
    print(f"  IPs already covered by roblox.lst: {len(covered_ips)}", file=sys.stderr)
    print(f"  IPs NOT covered (need to add): {len(missing_ips)}", file=sys.stderr)
    
    if covered_ips:
        print(f"\n✓ Covered IPs (already in roblox.lst):", file=sys.stderr)
        for ip in covered_ips[:10]:  # Show first 10
            print(f"    {ip}", file=sys.stderr)
        if len(covered_ips) > 10:
            print(f"    ... and {len(covered_ips) - 10} more", file=sys.stderr)
    
    if missing_ips:
        print(f"\n✗ Missing IPs (NOT in roblox.lst, will be added):", file=sys.stderr)
        for ip in missing_ips:
            print(f"    {ip}", file=sys.stderr)
    
    print(f"\nFiles written:", file=sys.stderr)
    print(f"  - {domains_file} (all domains)", file=sys.stderr)
    print(f"  - {missing_ips_file} (missing IPs)", file=sys.stderr)
    print(f"  - {missing_domains_file} (domains with missing IPs)", file=sys.stderr)

if __name__ == '__main__':
    main()
