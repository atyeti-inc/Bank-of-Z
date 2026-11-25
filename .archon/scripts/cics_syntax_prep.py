#!/usr/bin/env python3
"""
CICS / SQL Syntax Preprocessor for GnuCOBOL offline syntax checking.
Normalizes EXEC CICS and EXEC SQL blocks into valid Area B statements,
replaces DFHRESP and DFHVALUE macros, and injects DFHEIBLK if needed.
"""
import os
import re
import sys

def preprocess_cics(src_path, dst_path):
    with open(src_path, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()

    out = []
    in_exec = False
    exec_lines = []
    in_proc_div = False
    ws_injected = False

    for line in lines:
        raw = line.rstrip('\r\n')
        upper_raw = raw.upper()

        if 'PROCEDURE DIVISION' in upper_raw:
            in_proc_div = True

        # Inject COPY DFHEIBLK under WORKING-STORAGE SECTION if not present
        if not in_proc_div and 'WORKING-STORAGE SECTION.' in upper_raw and not ws_injected:
            ws_injected = True
            out.append(line)
            out.append('           COPY DFHEIBLK.\n')
            continue

        col7 = raw[6:7] if len(raw) > 6 else ' '
        is_comment = col7 in ('*', '/')

        if not in_exec:
            stripped = raw[7:] if len(raw) > 7 else ''
            # Check for EXEC statement not inside quotes or comments
            idx_exec = -1
            for kw in ('EXEC CICS', 'EXEC SQL', 'EXEC\n', 'EXEC\t'):
                pos = stripped.find(kw)
                if pos != -1 and (idx_exec == -1 or pos < idx_exec):
                    idx_exec = pos

            starts_exec = False
            if not is_comment and idx_exec != -1:
                prefix = stripped[:idx_exec]
                if prefix.count("'") % 2 == 0 and prefix.count('"') % 2 == 0:
                    starts_exec = True

            if starts_exec:
                in_exec = True
                exec_lines = [raw]
                if 'END-EXEC' in upper_raw:
                    in_exec = False
                    _handle_exec_block(exec_lines, in_proc_div, out)
                    exec_lines = []
            else:
                l = re.sub(r'DFHRESP\([^)]+\)', '0', line)
                l = re.sub(r'DFHVALUE\([^)]+\)', '0', l)
                out.append(l)
        else:
            exec_lines.append(raw)
            if 'END-EXEC' in upper_raw:
                in_exec = False
                _handle_exec_block(exec_lines, in_proc_div, out)
                exec_lines = []

    os.makedirs(os.path.dirname(os.path.abspath(dst_path)), exist_ok=True)
    with open(dst_path, 'w', encoding='utf-8') as f:
        f.writelines(out)

def _handle_exec_block(exec_lines, in_proc_div, out):
    full_block = ' '.join(exec_lines)
    has_dot = '.' in full_block.split('END-EXEC')[-1]

    if 'INCLUDE' in full_block.upper():
        m = re.search(r'INCLUDE\s+([A-Za-z0-9_-]+)', full_block, re.IGNORECASE)
        if m:
            out.append(f'           COPY {m.group(1)}.\n')
            return

    if not in_proc_div:
        for el in exec_lines:
            col7 = el[6:7] if len(el) > 6 else ' '
            if col7 in ('*', '/'):
                out.append(el + '\n')
            else:
                out.append('      * ' + (el[7:] if len(el) > 7 else el) + '\n')
    else:
        if has_dot:
            out.append('           CONTINUE.\n')
        else:
            out.append('           CONTINUE\n')

def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <src_file> <dst_file>", file=sys.stderr)
        sys.exit(1)

    src_path = sys.argv[1]
    dst_path = sys.argv[2]
    preprocess_cics(src_path, dst_path)

if __name__ == '__main__':
    main()
