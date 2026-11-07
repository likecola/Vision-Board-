"""Extract Press Start 2P / VT323 / Space Mono / Jua from the prototype bundle into TTFs.

Usage: build_intro_fonts.py <prototype.html> <lib_dir> <out_dir>

* Press Start 2P / VT323: use the latin slice.
* Space Mono: latin slices for weight 400 and 700.
* Jua: pick only the unicode-range slices that cover the characters actually used in
  every lib/*.dart (Hangul + the punctuation Jua renders), then merge them into one TTF.
"""
import base64, io, json, re, sys, tempfile
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.merge import Merger

proto, lib_dir, out = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
out.mkdir(parents=True, exist_ok=True)
src = proto.read_text(encoding="utf-8")
manifest = json.loads(re.search(r'<script type="__bundler/manifest"[^>]*>(.*?)</script>', src, re.S).group(1))
template = json.loads(re.search(r'<script type="__bundler/template"[^>]*>(.*?)</script>', src, re.S).group(1))

faces = []
for m in re.finditer(r"@font-face\s*\{(.*?)\}", template, re.S):
    body = m.group(1)
    fam = re.search(r"font-family:\s*'([^']+)'", body)
    uid = re.search(r'url\("([0-9a-f-]{36})"\)', body)
    rng = re.search(r"unicode-range:\s*([^;]+);", body)
    if not (fam and uid):
        continue
    ranges = []
    if rng:
        for part in rng.group(1).split(","):
            part = part.strip().replace("U+", "")
            if "-" in part:
                a, b = part.split("-")
                ranges.append((int(a, 16), int(b, 16)))
            else:
                ranges.append((int(part, 16), int(part, 16)))
    faces.append({"family": fam.group(1), "uuid": uid.group(1), "ranges": ranges,
                  "weight": (re.search(r"font-weight:\s*(\d+)", body) or [0, "400"])[1] if re.search(r"font-weight:\s*(\d+)", body) else "400"})


def woff2_to_ttf(uuid, dest):
    entry = manifest[uuid]
    raw = base64.b64decode(entry["data"])
    if entry.get("compressed"):
        import gzip
        raw = gzip.decompress(raw)
    font = TTFont(io.BytesIO(raw))
    font.flavor = None
    font.save(dest)


def covers(face, cp):
    return any(a <= cp <= b for a, b in face["ranges"])


# ── Latin-only display fonts ──
for family, fname in (("Press Start 2P", "PressStart2P-Regular.ttf"), ("VT323", "VT323-Regular.ttf")):
    latin = [f for f in faces if f["family"] == family and covers(f, ord("A"))]
    assert latin, f"no latin slice for {family}"
    woff2_to_ttf(latin[0]["uuid"], out / fname)
    print("wrote", fname)

# ── Space Mono (400 / 700) ──
for wt, fname in (("400", "SpaceMono-Regular.ttf"), ("700", "SpaceMono-Bold.ttf")):
    latin = [f for f in faces if f["family"] == "Space Mono" and f["weight"] == wt and covers(f, ord("A"))]
    assert latin, f"no latin slice for Space Mono {wt}"
    woff2_to_ttf(latin[0]["uuid"], out / fname)
    print("wrote", fname)

# ── Jua: subset to used characters ──
dart = "\n".join(p.read_text(encoding="utf-8") for p in sorted(lib_dir.glob("*.dart")))
# 주석(// ...)은 화면에 그려지지 않으므로 글자 집합에서 제외한다.
dart = "\n".join(line.split("//")[0] for line in dart.splitlines())
used = {ord(c) for c in dart if ord(c) >= 0x20}
# Jua로 그려지는 문자만 필요하지만, 안전하게 소스에 쓰인 한글/기본 라틴/문장부호를 모두 포함.
need = {cp for cp in used if (0xAC00 <= cp <= 0xD7A3) or cp < 0x2000 or 0x2010 <= cp <= 0x2030}
jua = [f for f in faces if f["family"] == "Jua"]
chosen = {}
missing = []
for cp in sorted(need):
    hit = next((f for f in jua if covers(f, cp)), None)
    if hit is None:
        missing.append(chr(cp))
    else:
        chosen[hit["uuid"]] = hit
print("Jua chars needed:", len(need), "-> slices:", len(chosen), "| not in any Jua slice:", "".join(missing)[:40] or "none")

tmp = Path(tempfile.mkdtemp(prefix="jua_slices_", dir=out))
paths = []
for i, uuid in enumerate(chosen):
    p = tmp / f"slice{i:03d}.ttf"
    woff2_to_ttf(uuid, p)
    paths.append(str(p))
merged = Merger().merge(paths)
# 글리프 단위로 한 번 더 깎아 실제 쓰는 글자만 남긴다.
from fontTools import subset as ftsubset
opts = ftsubset.Options()
opts.layout_features = ["*"]
opts.notdef_outline = True
opts.name_IDs = ["*"]
sub = ftsubset.Subsetter(opts)
sub.populate(unicodes=sorted(need | {0x20}))
sub.subset(merged)
merged.save(out / "Jua-subset.ttf")
print("wrote Jua-subset.ttf")
for p in paths:
    Path(p).unlink()
tmp.rmdir()
