#!/usr/bin/env python3
"""Build the silent six-scene calculus animation and its storyboard PDF.

Requires macOS, Python 3, Swift, and the built-in `cupsfilter` tool.
The video renderer is included in render.swift; no Python packages are needed.
"""
from pathlib import Path
import subprocess
import sys
import tempfile
import importlib.util

ROOT = Path(__file__).resolve().parent

def main():
    cache = Path(tempfile.gettempdir()) / "math-animation-swift-cache"
    cache.mkdir(exist_ok=True)
    subprocess.run(["swift", "-module-cache-path", str(cache), str(ROOT / "render.swift"),
                    str(ROOT / "Derivative_Animation.mp4")], check=True, cwd=ROOT)
    if importlib.util.find_spec("reportlab"):
        subprocess.run([sys.executable, str(ROOT / "make_storyboard.py")], check=True, cwd=ROOT)
    else:
        story = ROOT / "storyboard.txt"
        with (ROOT / "Storyboard.pdf").open("wb") as output:
            subprocess.run(["cupsfilter", "-i", "text/plain", "-m", "application/pdf", str(story)],
                           check=True, cwd=ROOT, stdout=output)
    print("Created Derivative_Animation.mp4 and Storyboard.pdf")

if __name__ == "__main__":
    try:
        main()
    except FileNotFoundError as exc:
        sys.exit(f"Required macOS tool not found: {exc.filename}")
