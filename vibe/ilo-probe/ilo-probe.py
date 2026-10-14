#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Made by papi
# Created on: Wed 14 Oct 2026 01:56:11 PM CEST
# ilo-probe.py
# Description:
#  Full disclosure I did not code any of this I probably could've but I got GLM-5.3
#  to just give it out for me on a pentest.

"""ilo_probe.py - Unauthenticated iLO fleet recon: /redfish/v1/ + /xmldata?item=all
Probes HPE iLO management interfaces for firmware version, IPMI-over-LAN state,
and known CVE ranges. Never authenticates, so it is lockout-safe to run
against an entire fleet.
Usage:
  ./ilo_probe.py -ip 172.17.3.142
  ./ilo_probe.py -f targets.txt -o results.csv
  ./ilo_probe.py -f targets.txt --threads 20 --timeout 5 -o results.csv
Targets file: one IP/hostname per line, '#' comments allowed.
"""
import argparse
import csv
import json
import ssl
import sys
import urllib.request
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor, as_completed
# (CVE, manager_type_prefix, (min_inclusive, max_exclusive), summary)
# min/max are version tuples; None = unbounded on that side.
CVE_DB = [
    ("CVE-2023-50272", "iLO 6", ((1, 5), (1, 55)),
     "Remote authentication bypass (iLO 6 1.05 to <1.55)"),
    ("CVE-2023-50272", "iLO 5", ((2, 63), (3, 0)),
     "Remote authentication bypass (iLO 5 2.63 to <3.00)"),
    ("CVE-2026-63457", "iLO 6", (None, (1, 78)),
     "Unauthenticated DoS, unresponsive BMC (iLO 6 <1.78)"),
    ("CVE-2017-12542", "iLO 4", (None, (2, 53)),
     "Connection header overflow -> auth bypass / RCE (iLO 4 <2.53)"),
]
CSV_FIELDS = ["ip", "status", "manager", "firmware", "fqdn", "product",
             "serial", "ilo_serial", "ipmi_lan", "cves"]

def fw_tuple(version: str):
    """'1.75' -> (1, 75). Digit prefix per component, zero-padded to len 2."""
    parts = []
    for chunk in str(version).split("."):
        digits = ""
        for c in chunk:
            if c.isdigit():
                digits += c
            else:
                break
        parts.append(int(digits) if digits else 0)
    while len(parts) < 2:
        parts.append(0)
    return tuple(parts)
def fetch(url: str, timeout: int) -> bytes:
    """GET with self-signed cert tolerance (iLO ships a factory cert)."""
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    req = urllib.request.Request(
        url, headers={"User-Agent": "ilo-probe/1.0", "Accept": "*/*"}
    )
    with urllib.request.urlopen(req, timeout=timeout, context=ctx) as resp:
        return resp.read()
def cve_matches(manager_type: str, fw: tuple) -> list:
    out = []
    for cve, mgr, (lo, hi), _summary in CVE_DB:
        if not manager_type.startswith(mgr):
            continue
        if lo is not None and not (lo <= fw):
            continue
        if hi is not None and not (fw < hi):
            continue
        out.append(cve)
    return out
def probe_host(ip: str, timeout: int) -> dict:
    """Probe one iLO. Returns a CSV record. Never raises."""
    rec = {f: "" for f in CSV_FIELDS}
    rec["ip"] = ip
    rec["status"] = "error"
    root = rimp = None
    try:
        root = json.loads(fetch(f"https://{ip}/redfish/v1/", timeout))
    except Exception:
        pass
    try:
        rimp = ET.fromstring(fetch(f"https://{ip}/xmldata?item=all", timeout))
    except Exception:
        pass
    if root is None and rimp is None:
        rec["status"] = "unreachable"
        return rec
    manager_type, fw_str = "unknown", "unknown"
    if isinstance(root, dict):
        try:
            mgrs = root["Oem"]["Hpe"]["Manager"]
            if mgrs:
                manager_type = mgrs[0].get("ManagerType", "unknown")
                fw_str = mgrs[0].get("ManagerFirmwareVersion", "unknown")
                rec["fqdn"] = mgrs[0].get("FQDN", "")
        except (KeyError, TypeError, IndexError):
            pass
    if rimp is not None:
        rec["product"] = rimp.findtext("./HSI/SPN", "") or ""
        rec["serial"] = rimp.findtext("./HSI/SBSN", "") or ""
        rec["ilo_serial"] = rimp.findtext("./MP/SN", "") or ""
        ipm = rimp.findtext("./MP/IPM", "")
        rec["ipmi_lan"] = ("enabled" if ipm == "1"
                           else "disabled" if ipm == "0" else ipm)
        if fw_str == "unknown":
            fw_str = rimp.findtext("./MP/FWRI", "unknown") or "unknown"
    rec["manager"] = manager_type
    rec["firmware"] = fw_str
    if fw_str != "unknown":
        cves = cve_matches(manager_type, fw_tuple(fw_str))
        rec["cves"] = ";".join(cves)
        rec["status"] = "vulnerable" if cves else "ok"
    else:
        rec["cves"] = "n/a"
        rec["status"] = "no-version"
    return rec
def load_targets(path: str) -> list:
    targets = []
    with open(path, "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()
            if line:
                targets.append(line)
    return targets
def print_rec(rec: dict):
    tag = {"vulnerable": "[VULN]", "ok": "[ OK ]",
           "unreachable": "[DEAD]", "no-version": "[?FW?]",
           "error": "[ERR ]"}.get(rec["status"], "[?   ]")
    line = f"{tag} {rec['ip']:<18}"
    if rec["status"] != "unreachable":
        line += f" {rec['manager']} fw {rec['firmware']}"
        if rec["fqdn"]:
            line += f"  {rec['fqdn']}"
        if rec["ipmi_lan"]:
            line += f"  ipmi:{rec['ipmi_lan']}"
        if rec["cves"]:
            line += f"  -> {rec['cves']}"
    print(line)
def main() -> int:
    ap = argparse.ArgumentParser(
        description="Unauthenticated iLO fleet recon (Redfish root + xmldata). "
                    "Lockout-safe: never sends credentials.")
    tgt = ap.add_mutually_exclusive_group(required=True)
    tgt.add_argument("-ip", metavar="HOST",
                     help="single target IP/hostname")
    tgt.add_argument("-f", metavar="FILE",
                     help="target list file, one host per line")
    ap.add_argument("-o", "--output", metavar="CSV",
                    help="write results to CSV")
    ap.add_argument("--threads", type=int, default=10,
                    help="concurrent probes (default: 10)")
    ap.add_argument("--timeout", type=int, default=10,
                    help="per-request timeout in seconds (default: 10)")
    args = ap.parse_args()
    targets = [args.ip] if args.ip else load_targets(args.f)
    print(f"[*] probing {len(targets)} target(s), "
          f"{args.threads} threads, {args.timeout}s timeout")
    records = []
    with ThreadPoolExecutor(max_workers=args.threads) as pool:
        futures = {pool.submit(probe_host, t, args.timeout): t
                   for t in targets}
        for fut in as_completed(futures):
            rec = fut.result()
            records.append(rec)
            print_rec(rec)
    # keep CSV in input-file order so it diffs cleanly against the target list
    order = {t: i for i, t in enumerate(targets)}
    records.sort(key=lambda r: order.get(r["ip"], 1 << 30))
    if args.output:
        with open(args.output, "w", newline="", encoding="utf-8") as fh:
            w = csv.DictWriter(fh, fieldnames=CSV_FIELDS)
            w.writeheader()
            w.writerows(records)
        print(f"[*] wrote {len(records)} record(s) to {args.output}")
    vuln = sum(1 for r in records if r["status"] == "vulnerable")
    dead = sum(1 for r in records if r["status"] == "unreachable")
    print(f"[*] summary: {len(records)} probed, "
          f"{vuln} vulnerable, {dead} unreachable")
    return 0
if __name__ == "__main__":
    sys.exit(main())
