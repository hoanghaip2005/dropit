"""Tách mọi khối ```mermaid trong design/*.md thành render/src/<tệp>-<n>.mmd."""
import re, pathlib, sys
root = pathlib.Path(__file__).resolve().parent.parent
out = root / "render" / "src"; out.mkdir(parents=True, exist_ok=True)
for f in ["01-kien-truc.md", "02-du-lieu.md", "04-luong-trang-thai.md"]:
    text = (root / f).read_text(encoding="utf-8")
    lines = text.split("\n"); n = 0; heading = ""
    i = 0
    while i < len(lines):
        if lines[i].startswith("#"): heading = lines[i].lstrip("# ").strip()
        if lines[i].strip() == "```mermaid":
            j = i + 1
            while lines[j].strip() != "```": j += 1
            n += 1
            name = f"{f[:-3]}-{n:02d}"
            (out / f"{name}.mmd").write_text("\n".join(lines[i+1:j]) + "\n", encoding="utf-8")
            print(f"{name}\t{f}:{i+1}\t{heading}")
            i = j
        i += 1
