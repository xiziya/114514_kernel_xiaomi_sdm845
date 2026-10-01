#!/usr/bin/env python3
"""Reject duplicate/overlapping options and device options lost to Kconfig."""
import re
import sys
from pathlib import Path

def parse(path):
    result={}
    for number,line in enumerate(Path(path).read_text().splitlines(),1):
        enabled=re.fullmatch(r'(CONFIG_\w+)=(.*)',line)
        disabled=re.fullmatch(r'# (CONFIG_\w+) is not set',line)
        if not enabled and not disabled:continue
        key,value=enabled.groups() if enabled else (disabled[1],'n')
        if key in result:raise SystemExit(f'Duplicate option {key} in {path}:{number}')
        result[key]=value
    return result

if len(sys.argv) not in (3,4):raise SystemExit('Usage: check-configs.py BASE POLARIS [RESOLVED]')
base,device=map(parse,sys.argv[1:3])
overlap=sorted(base.keys() & device.keys())
if overlap:raise SystemExit('Overlapping options: '+', '.join(overlap))
if len(sys.argv)==4:
    resolved=parse(sys.argv[3])
    lost={key:(value,resolved.get(key)) for key,value in device.items() if resolved.get(key)!=value}
    if lost:raise SystemExit('Device settings lost during Kconfig: '+repr(lost))
print(f'Config check passed: {len(base)} base + {len(device)} device options; no duplicates/overlap')
