#!/usr/bin/env python3
"""
Validates YAML syntax across repository files and validates
bank-of-z-definitions.yaml against resource-schema.json.
"""
import glob
import json
import os
import re
import sys
import jsonschema
import yaml

class Yaml12Loader(yaml.SafeLoader):
    """Safe loader that treats YES/NO/etc as strings rather than booleans (YAML 1.2 behavior)."""
    pass

for ch in ['y', 'Y', 'n', 'N', 'o', 'O']:
    rules = Yaml12Loader.yaml_implicit_resolvers.get(ch, [])
    Yaml12Loader.yaml_implicit_resolvers[ch] = [r for r in rules if r[0] != 'tag:yaml.org,2002:bool']

def validate_yaml_syntax(repo_root):
    yaml_files = sorted(
        glob.glob(os.path.join(repo_root, "**", "*.yaml"), recursive=True) +
        glob.glob(os.path.join(repo_root, "**", "*.yml"), recursive=True)
    )
    yaml_files = [f for f in yaml_files if "/.git/" not in f and not f.startswith(".git/")]

    print(f"Validating syntax of {len(yaml_files)} YAML files...")
    syntax_errors = 0
    for fpath in yaml_files:
        rel = os.path.relpath(fpath, repo_root)
        try:
            with open(fpath, "r", encoding="utf-8") as fp:
                yaml.safe_load(fp)
        except Exception as e:
            print(f"YAML SYNTAX ERROR: {rel}: {e}", file=sys.stderr)
            syntax_errors += 1

    if syntax_errors > 0:
        print(f"YAML syntax validation FAILED with {syntax_errors} errors.", file=sys.stderr)
        return False
    print(f"YAML syntax validation PASSED ({len(yaml_files)} files).")
    return True

def validate_definitions_schema(repo_root):
    def_file = os.path.join(repo_root, ".setup", "zconfig", "bank-of-z-definitions.yaml")
    schema_file = os.path.join(repo_root, ".setup", "zconfig", "resource-schema.json")

    if not os.path.exists(def_file):
        print(f"ERROR: Definitions file not found: {def_file}", file=sys.stderr)
        return False
    if not os.path.exists(schema_file):
        print(f"ERROR: Schema file not found: {schema_file}", file=sys.stderr)
        return False

    print("Validating bank-of-z-definitions.yaml against resource-schema.json...")
    with open(schema_file, "r", encoding="utf-8") as fp:
        schema = json.load(fp)

    with open(def_file, "r", encoding="utf-8") as fp:
        raw_yaml = fp.read()

    # Resolve Jinja variables to pattern-conforming mock values
    rendered = re.sub(r'\"?\{\{\s*vars\.cics_ipic_port\s*\}\}\"?', '5050', raw_yaml)
    rendered = re.sub(r'\"?\{\{\s*vars\.db2_ssid\s*\}\}\"?', 'DBD1', rendered)
    rendered = re.sub(r'\"?\{\{\s*vars\.mq_qmgr_name\s*\}\}\"?', 'MQ01', rendered)

    data = yaml.load(rendered, Loader=Yaml12Loader)

    try:
        jsonschema.validate(instance=data, schema=schema)
    except jsonschema.exceptions.ValidationError as e:
        print(f"SCHEMA VALIDATION ERROR: {e.message}", file=sys.stderr)
        return False

    print("Definitions schema validation PASSED.")
    return True

def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    ok_syntax = validate_yaml_syntax(repo_root)
    ok_schema = validate_definitions_schema(repo_root)

    if not (ok_syntax and ok_schema):
        sys.exit(1)
    sys.exit(0)

if __name__ == "__main__":
    main()
