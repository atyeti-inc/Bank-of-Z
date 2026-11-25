#!/usr/bin/env python3
"""
Audit COBOL fixed-format 80-column layout and copybook resolution universe.
"""
import glob
import os
import re
import sys

def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

    # 1. Collect target files
    if len(sys.argv) > 1:
        target_files = [os.path.abspath(f) for f in sys.argv[1:]]
    else:
        pattern_cbl = os.path.join(repo_root, "src", "base", "**", "*.cbl")
        pattern_cpy = os.path.join(repo_root, "src", "base", "**", "*.cpy")
        target_files = sorted(glob.glob(pattern_cbl, recursive=True) + glob.glob(pattern_cpy, recursive=True))

    if not target_files:
        print("ERROR: No COBOL or copybook files found to audit.", file=sys.stderr)
        sys.exit(1)

    # 2. Build copybook resolution universe
    # - src/**/*.cpy
    # - src/**/*.bms (symbolic BMS map names)
    # - .archon/stubs/cpy/*.cpy
    # - Known system copybooks
    copybook_universe = {
        "DFHAID", "DFHBMSCA", "SQLCA", "SQLDA", "CEEIGZCT", "DFHEIBLK"
    }

    src_cpy = glob.glob(os.path.join(repo_root, "src", "**", "*.cpy"), recursive=True)
    for f in src_cpy:
        base = os.path.splitext(os.path.basename(f))[0].upper()
        copybook_universe.add(base)

    src_bms = glob.glob(os.path.join(repo_root, "src", "**", "*.bms"), recursive=True)
    for f in src_bms:
        base = os.path.splitext(os.path.basename(f))[0].upper()
        copybook_universe.add(base)

    stubs_cpy = glob.glob(os.path.join(repo_root, ".archon", "stubs", "cpy", "*.cpy"), recursive=True)
    for f in stubs_cpy:
        base = os.path.splitext(os.path.basename(f))[0].upper()
        copybook_universe.add(base)

    # 3. Perform 80-column layout and copybook audit
    layout_errors = 0
    unresolved_copybooks = 0

    copy_regex = re.compile(r'\bCOPY\s+([A-Za-z0-9_-]+)', re.IGNORECASE)
    sql_include_regex = re.compile(r'\bINCLUDE\s+([A-Za-z0-9_-]+)', re.IGNORECASE)

    for file_path in target_files:
        rel_path = os.path.relpath(file_path, repo_root)
        with open(file_path, "r", encoding="utf-8", errors="replace") as f:
            for line_no, line in enumerate(f, start=1):
                raw_line = line.rstrip("\r\n")
                # 80-column layout check
                if len(raw_line) > 80:
                    print(f"LAYOUT ERROR: {rel_path}:{line_no} exceeds 80 columns (len={len(raw_line)})", file=sys.stderr)
                    layout_errors += 1

                # Skip comment lines (col 7 indicator '*' or '/')
                col7 = raw_line[6:7] if len(raw_line) > 6 else ' '
                if col7 in ('*', '/'):
                    continue

                # Copybook resolution check
                matches = copy_regex.findall(raw_line)
                for copy_name in matches:
                    cname = copy_name.upper().rstrip('.')
                    if cname not in copybook_universe:
                        print(f"UNRESOLVED COPYBOOK: {rel_path}:{line_no} references '{copy_name}'", file=sys.stderr)
                        unresolved_copybooks += 1

                # Db2 EXEC SQL INCLUDE check
                if "EXEC" in raw_line.upper() and "SQL" in raw_line.upper():
                    sql_matches = sql_include_regex.findall(raw_line)
                    for copy_name in sql_matches:
                        cname = copy_name.upper().rstrip('.')
                        if cname not in copybook_universe:
                            print(f"UNRESOLVED SQL INCLUDE: {rel_path}:{line_no} references '{copy_name}'", file=sys.stderr)
                            unresolved_copybooks += 1

    total_files = len(target_files)
    if layout_errors > 0 or unresolved_copybooks > 0:
        print(f"Audit FAILED: {total_files} files audited, {layout_errors} layout errors, {unresolved_copybooks} unresolved copybooks.", file=sys.stderr)
        sys.exit(1)

    print(f"Audit PASSED: {total_files} files audited, 0 layout errors, 0 unresolved copybooks.")
    sys.exit(0)

if __name__ == "__main__":
    main()
