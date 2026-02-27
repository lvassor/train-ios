#!/usr/bin/env python3
"""Regenerate all flowchart PDFs from their Python generators.

Usage:
    python generate_all.py

Requires: graphviz (brew install graphviz)
"""

import importlib.util, os, sys


def run_generator(script_path: str) -> None:
    name = os.path.basename(script_path).removesuffix(".py")
    spec = importlib.util.spec_from_file_location(name, script_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    mod.main()


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    generators = sorted(
        f
        for f in os.listdir(here)
        if f.endswith(".py") and f != "generate_all.py"
    )

    print(f"Regenerating {len(generators)} flowcharts...\n")
    for gen in generators:
        try:
            run_generator(os.path.join(here, gen))
        except Exception as e:
            print(f"  ERROR in {gen}: {e}", file=sys.stderr)

    print(f"\nDone. {len(generators)} PDFs generated.")


if __name__ == "__main__":
    main()
