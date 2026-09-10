#!/usr/bin/env python3
"""Thin shim — run the kbh CLI from a clone without installing.

Kept for running `scripts/kbh.py <cmd>` directly. The implementation lives in
`kbh/cli.py`, which is also the pip console-script entry point (`kbh`).
See docs/kbh-cli.md.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from kbh.cli import main  # noqa: E402

if __name__ == "__main__":
    raise SystemExit(main())
