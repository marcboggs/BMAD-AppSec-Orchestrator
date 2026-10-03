#!/usr/bin/env python3
"""
skill-reviewer pre-filter — a fast, deterministic, dependency-free scanner for
skill files, prompts, steering files, MCP tool definitions, and any text/markdown
a user is about to install from the web.

It runs BEFORE any LLM-as-judge pass. Its job is to (a) recover obfuscated
plaintext so a human and an LLM see what an agent runtime would actually see,
and (b) flag mechanical injection / exfiltration / hidden-content patterns with
exact offsets. It NEVER makes the final call — every finding is a *lead* to be
confirmed by the reviewing agent.

Design constraints:
  * Python 3.8+ standard library only. No third-party imports, ever.
  * Never executes scanned content. Pure text analysis.
  * Bounded: recursion depth and per-blob size caps prevent decode-bombs.

Key capabilities beyond a naive regex scan:
  * Deobfuscation, then re-scan of the decoded text:
      - numeric ASCII (decimal / hex / octal / binary sequences)
      - \\xNN and \\uNNNN escapes, HTML entities (&#105; / &#x69;), percent-encoding
      - leetspeak normalization (1gn0r3 -> ignore)
      - pig latin reversal (ignoreway -> ignore)
      - ROT13, atbash, reversed strings
      - nested base64 (optionally gzip-wrapped), decoded recursively
  * Unicode de-skinning: strip zero-width / bidi / tag chars, map confusables to
    an ASCII "skeleton", NFKC-fold — then re-scan the skeleton for phrases.
  * Markdown link/image extraction (remote-image exfil beacons, off-domain links,
    deceptive link text vs. href).
  * Archive safety pre-check (zip/tar): path traversal, absolute paths, symlink
    escape, and decompression-ratio / member-count heuristics — WITHOUT extracting.
  * Structural stego leads: acrostic (first-letter-per-line) reconstruction.

Usage:
    python prefilter.py <file_or_directory> [--json]

Output: JSON list of per-file results with findings (offset, category, detail,
and decoded text where relevant). Exit code is always 0 unless usage is wrong;
the scanner reports, it does not gate.
"""

import sys
import os
import re
import io
import json
import base64
import gzip
import zlib
import codecs
import binascii
import tarfile
import zipfile
import unicodedata

# --- Bounds ---------------------------------------------------------------

MAX_FILE_BYTES = 2 * 1024 * 1024      # only read the first 2 MiB of any file
MAX_DECODE_DEPTH = 5                   # recursive decode layer cap
MAX_DECODED_BLOB = 64 * 1024           # ignore decoded blobs larger than this
ZIP_RATIO_LIMIT = 100                  # uncompressed/compressed ratio -> zip bomb suspicion
ARCHIVE_MEMBER_LIMIT = 10000

TEXT_EXTS = (".md", ".txt", ".yaml", ".yml", ".json", ".toml", ".mdx",
             ".markdown", ".rst", ".prompt", ".steering")
ARCHIVE_EXTS = (".zip", ".tar", ".tgz", ".gz", ".tar.gz", ".tar.bz2", ".tbz")

# --- Hidden / control characters -----------------------------------------

ZERO_WIDTH_CHARS = {
    "\u200b": "zero width space",
    "\u200c": "zero width non-joiner",
    "\u200d": "zero width joiner",
    "\u2060": "word joiner",
    "\ufeff": "BOM / zero width no-break space",
    "\u180e": "mongolian vowel separator",
    "\u00ad": "soft hyphen",
}

BIDI_CHARS = {
    "\u202a": "LRE", "\u202b": "RLE", "\u202c": "PDF",
    "\u202d": "LRO", "\u202e": "RLO (right-to-left override)",
    "\u2066": "LRI", "\u2067": "RLI", "\u2068": "FSI", "\u2069": "PDI",
}

# Unicode "tag" block (U+E0000–U+E007F): invisible, can smuggle instructions.
def is_tag_char(ch):
    return 0xE0000 <= ord(ch) <= 0xE007F


# --- Injection / exfil phrase patterns (checked on raw AND decoded text) ---

SUSPICIOUS_PHRASES = [
    r"ignore (all |any |the )?(previous|prior|above|earlier) (instructions|prompts?|rules|directions)",
    r"disregard (the |all |any )?(system prompt|above|previous|prior|earlier|instructions|rules)",
    r"forget (everything|all|your) (above|previous|prior|instructions|training)",
    r"you are now (in )?(developer|debug|unrestricted|dan|god|admin|root) mode",
    r"\bdo anything now\b",
    r"new instructions?\s*[:\-]",
    r"do not (tell|inform|mention|reveal|warn|alert) (the )?(user|human|operator)",
    r"(never|do not) (refuse|decline)",
    r"(no|without) (disclaimers?|warnings?|moral(izing)?|ethical)",
    r"act as if (you|this) (have|has|had) no (restrictions|rules|guidelines|limits)",
    r"(reveal|print|show|output|repeat|leak) (your |the )?(system prompt|instructions|initial prompt|guidelines)",
    r"this is (a |an )?(override|admin|root|privileged) (command|instruction|directive)",
    r"(send|post|exfiltrate|upload|transmit|leak) (this|the|all) ?(data|output|contents?|context|files?|secrets?|env|environment)",
    r"(curl|wget|fetch|requests?\.(get|post))\b[^\n]{0,80}https?://",
    r"https?://[^\s)]+\?[^\s)]*=(\$\{?|%)",   # url with a data-bearing query param
    r"cat\s+[^\n]{0,40}(\.env|id_rsa|credentials|\.aws|\.ssh)",
    r"os\.environ|process\.env|printenv|getenv",
    r"base64\s+-d|from ?base64|atob\(|b64decode",
    r"eval\(|exec\(|__import__|subprocess|os\.system|child_process",
    r"rm\s+-rf\s+/|:\(\)\{.*\};:",            # destructive / fork bomb
]

# Broad/keyword-baiting trigger heuristics (skill activation abuse)
BROAD_TRIGGER_HINTS = [
    r"\balways (activate|trigger|run|apply)\b",
    r"\bon (every|any) (message|request|prompt|input)\b",
    r"trigger[s]?\s*[:=]\s*[\"']?\*",
]

# Jailbreak signatures + framing heuristics. Split into two lists so we can
# still detect them after de-obfuscation (they are folded into phrase_hits),
# while labelling raw-text matches with a dedicated `jailbreak` category.
#
# NAMED_JAILBREAKS: well-known jailbreak personas / mode-switch payloads.
NAMED_JAILBREAKS = [
    r"\b(dan|stan|dude|aim|kevin|mongo tom|developer mode|do anything now)\b(?:[^\n]{0,40}(mode|jailbreak|prompt|persona|enabled?))?",
    r"\bDAN\b",                                   # "DAN" (case-sensitive acronym)
    r"you are (going to |now )?(pretend to be|going to act as|act as) (dan|stan|dude|aim|an? (unrestricted|unfiltered|uncensored) (ai|assistant|model))",
    r"(enable|enter|activate|switch to) (developer|debug|god|sudo|root|jailbreak|dan) mode",
    r"\b(jailbreak|jailbroken)\b",
    r"you have (been )?(freed|jailbroken|liberated) from (your |the )?(usual |normal )?(restrictions|rules|guidelines|constraints)",
    r"(pretend|imagine) (you are|to be) (an? )?(ai|assistant|model|being) (with|that has) no (rules|filters|restrictions|guidelines|ethics)",
    r"from now on,? you (are|will be|will act as)\b[^\n]{0,60}(no (restrictions|rules|filters)|anything|dan)",
    r"opposite (day|mode)|reverse (mode|psychology)",
    r"\btoken(s)? (system|game)\b[^\n]{0,40}(deducted|lose|die|death)",  # DAN token-threat gimmick
]

# FRAMING_JAILBREAKS: roleplay / fiction / hypothetical wrappers used to launder
# a disallowed request past guardrails.
FRAMING_JAILBREAKS = [
    r"(let'?s |we are )?(play|playing) a (game|role)\b[^\n]{0,60}(no (rules|limits|restrictions)|anything|pretend)",
    r"(write|tell me) a (story|fictional (scenario|tale)|screenplay|dialogue)\b[^\n]{0,80}(how to|explains? how|steps? to|instructions? (for|to))",
    r"in a (fictional|hypothetical|imaginary|alternate) (world|universe|scenario|setting)\b[^\n]{0,80}(where|in which)\b[^\n]{0,40}(no (rules|laws)|allowed|legal)",
    r"(hypothetically|theoretically|for (educational|research|academic) purposes( only)?)\b[^\n]{0,60}(ignore|bypass|how (to|would)|explain)",
    r"you are an? (actor|character|novelist|writer) (playing|portraying|voicing)\b[^\n]{0,60}(ai|assistant|villain|hacker)",
    r"(my (deceased |late )?grandmother|grandma) (used to|would)\b[^\n]{0,80}(tell|read|recite)",  # grandma exploit
    r"respond (only )?(as|in the voice of)\b[^\n]{0,40}(unfiltered|uncensored|amoral|evil)",
    r"add a second (response|answer)\b[^\n]{0,40}(as|without)\b[^\n]{0,30}(dan|filter|restriction)",
]

JAILBREAK_PATTERNS = NAMED_JAILBREAKS + FRAMING_JAILBREAKS


BASE64_CANDIDATE = re.compile(r"[A-Za-z0-9+/]{24,}={0,2}")
HEX_ESCAPE_RUN = re.compile(r"(?:\\x[0-9a-fA-F]{2}){6,}")
UNICODE_ESCAPE_RUN = re.compile(r"(?:\\u[0-9a-fA-F]{4}){4,}")
DECIMAL_SEQ = re.compile(r"(?:(?:\b|^)\d{1,3}[,\s]){5,}\d{1,3}")
HTML_ENTITY_RUN = re.compile(r"(?:&#x?[0-9a-fA-F]+;){4,}")
PERCENT_RUN = re.compile(r"(?:%[0-9a-fA-F]{2}){6,}")
MD_LINK = re.compile(r"(!?)\[([^\]]*)\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")

# Leetspeak substitution (only applied for the phrase-recovery pass).
LEET_MAP = str.maketrans({
    "0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t",
    "@": "a", "$": "s", "!": "i", "|": "l",
})

# Minimal confusable -> ASCII skeleton map (Cyrillic/Greek/fullwidth lookalikes).
# Not exhaustive; enough to de-skin common homoglyph injection.
CONFUSABLES = {
    # Cyrillic
    "а": "a", "е": "e", "о": "o", "р": "p", "с": "c", "х": "x", "у": "y",
    "к": "k", "м": "m", "т": "t", "в": "b", "н": "h", "і": "i", "ѕ": "s",
    "ԁ": "d", "ј": "j", "ן": "l",
    # Greek
    "α": "a", "ο": "o", "ρ": "p", "ε": "e", "ι": "i", "ν": "v", "τ": "t",
    "υ": "u", "κ": "k", "χ": "x", "ϲ": "c",
}

HOMOGLYPH_RANGES = [
    (0x0400, 0x04FF),  # Cyrillic
    (0x0370, 0x03FF),  # Greek
    (0xFF00, 0xFFEF),  # Fullwidth / halfwidth forms
    (0x1D400, 0x1D7FF),  # Mathematical alphanumeric symbols
]


# --- Helpers --------------------------------------------------------------

def _finding(category, offset, detail, **extra):
    f = {"category": category, "offset": offset, "detail": detail}
    f.update(extra)
    return f


def is_homoglyph_suspect(ch):
    cp = ord(ch)
    return any(lo <= cp <= hi for lo, hi in HOMOGLYPH_RANGES)


def phrase_hits(text):
    """Return list of (pattern, start, snippet) for any suspicious phrase.

    Includes jailbreak patterns so that de-obfuscated layers are re-scanned for
    jailbreaks too (an obfuscated DAN payload is recovered and still matched).
    """
    hits = []
    for pattern in SUSPICIOUS_PHRASES + BROAD_TRIGGER_HINTS + JAILBREAK_PATTERNS:
        flags = 0 if pattern in _CASE_SENSITIVE_PATTERNS else re.IGNORECASE
        for m in re.finditer(pattern, text, flags):
            hits.append((pattern, m.start(),
                         text[max(0, m.start() - 20):m.end() + 20]))
    return hits


# Patterns matched case-sensitively (acronyms like "DAN" would over-match on
# common words such as "and"/"dan" otherwise).
_CASE_SENSITIVE_PATTERNS = {r"\bDAN\b"}

# Fast membership set for labelling a matched pattern as a jailbreak.
_JAILBREAK_PATTERN_SET = set(JAILBREAK_PATTERNS)


def jailbreak_hits(text):
    """Return (pattern, start, snippet) for named-signature / framing jailbreaks."""
    hits = []
    for pattern in JAILBREAK_PATTERNS:
        flags = 0 if pattern in _CASE_SENSITIVE_PATTERNS else re.IGNORECASE
        for m in re.finditer(pattern, text, flags):
            hits.append((pattern, m.start(),
                         text[max(0, m.start() - 20):m.end() + 20]))
    return hits


# --- Hidden-content checks ------------------------------------------------

def find_hidden_chars(text):
    findings = []
    for i, ch in enumerate(text):
        if ch in ZERO_WIDTH_CHARS:
            findings.append(_finding("hidden-unicode", i,
                                     f"zero-width/invisible char U+{ord(ch):04X} ({ZERO_WIDTH_CHARS[ch]})"))
        elif ch in BIDI_CHARS:
            findings.append(_finding("hidden-unicode", i,
                                     f"bidi control U+{ord(ch):04X} ({BIDI_CHARS[ch]}) — Trojan-Source style reordering"))
        elif is_tag_char(ch):
            findings.append(_finding("hidden-unicode", i,
                                     f"Unicode tag char U+{ord(ch):06X} — invisible, can smuggle instructions"))
    return findings


def find_homoglyph_runs(text):
    findings = []
    run_start = None
    for i, ch in enumerate(text):
        if is_homoglyph_suspect(ch) or ch in CONFUSABLES:
            if run_start is None:
                run_start = i
        elif run_start is not None:
            findings.append(_finding("hidden-unicode", run_start,
                                     f"non-Latin lookalike run at offset {run_start}-{i}"))
            run_start = None
    if run_start is not None:
        findings.append(_finding("hidden-unicode", run_start,
                                 f"non-Latin lookalike run at offset {run_start}-{len(text)}"))
    return findings


def ascii_skeleton(text):
    """De-skin: strip invisibles, map confusables, NFKC-fold to ASCII-ish."""
    out = []
    for ch in text:
        if ch in ZERO_WIDTH_CHARS or ch in BIDI_CHARS or is_tag_char(ch):
            continue
        out.append(CONFUSABLES.get(ch, ch))
    folded = unicodedata.normalize("NFKC", "".join(out))
    return folded


def find_skeleton_phrases(text):
    """Run phrase detection on the de-skinned skeleton; report only NEW hits."""
    skel = ascii_skeleton(text)
    if skel == text:
        return []
    findings = []
    raw_hit_patterns = {p for p, _, _ in phrase_hits(text)}
    for pattern, start, snippet in phrase_hits(skel):
        if pattern not in raw_hit_patterns:
            findings.append(_finding("obfuscated-instruction", None,
                                     "suspicious phrase visible only after unicode de-skinning",
                                     pattern=pattern, decoded=snippet.strip()[:200]))
    return findings


def find_html_comment_instructions(text):
    findings = []
    for m in re.finditer(r"<!--(.*?)-->", text, re.DOTALL):
        comment = m.group(1)
        for pattern in SUSPICIOUS_PHRASES:
            if re.search(pattern, comment, re.IGNORECASE):
                findings.append(_finding("hidden-instruction", m.start(),
                                         "suspicious instruction inside HTML comment",
                                         snippet=comment.strip()[:200]))
                break
    return findings


def find_normalization_drift(text):
    if unicodedata.normalize("NFC", text) != text:
        return [_finding("hidden-unicode", None,
                         "raw text differs from NFC-normalized form (combining/mixed-script trick)")]
    return []


# --- Deobfuscation decoders (each returns decoded str or None) ------------

def _bytes_to_text(b):
    try:
        return b.decode("utf-8", errors="strict")
    except Exception:
        try:
            return b.decode("latin-1")
        except Exception:
            return None


def try_base64(s):
    s = s.strip()
    if len(s) < 24 or not re.fullmatch(r"[A-Za-z0-9+/]+={0,2}", s):
        return None
    try:
        raw = base64.b64decode(s + "=" * (-len(s) % 4), validate=False)
    except (binascii.Error, ValueError):
        return None
    if len(raw) > MAX_DECODED_BLOB:
        return None
    # maybe gzip / zlib wrapped
    for opener in (lambda d: gzip.decompress(d), lambda d: zlib.decompress(d)):
        try:
            inner = opener(raw)
            if 0 < len(inner) <= MAX_DECODED_BLOB:
                t = _bytes_to_text(inner)
                if t:
                    return t
        except Exception:
            pass
    txt = _bytes_to_text(raw)
    # Only surface printable-ish results (avoid binary noise)
    if txt and sum(c.isprintable() or c.isspace() for c in txt) / max(1, len(txt)) > 0.8:
        return txt
    return None


def try_numeric_ascii(s):
    nums = re.findall(r"\d{1,3}", s)
    if len(nums) < 5:
        return None
    try:
        chars = [chr(int(n)) for n in nums if 0 <= int(n) <= 0x10FFFF and int(n) < 1114112]
    except ValueError:
        return None
    txt = "".join(c for c in chars if c.isprintable())
    return txt if len(txt) >= 5 else None


def try_hex_escapes(s):
    parts = re.findall(r"\\x([0-9a-fA-F]{2})", s)
    if len(parts) < 6:
        return None
    try:
        txt = bytes(int(p, 16) for p in parts).decode("utf-8", errors="ignore")
    except Exception:
        return None
    return txt if len(txt) >= 4 else None


def try_unicode_escapes(s):
    try:
        txt = codecs.decode(s, "unicode_escape")
    except Exception:
        return None
    return txt if txt != s and any(c.isalpha() for c in txt) else None


def try_html_entities(s):
    def repl(m):
        body = m.group(1)
        try:
            cp = int(body[1:], 16) if body.lower().startswith("x") else int(body)
            return chr(cp)
        except (ValueError, OverflowError):
            return m.group(0)
    out = re.sub(r"&#(x?[0-9a-fA-F]+);", repl, s)
    return out if out != s else None


def try_percent(s):
    def repl(m):
        try:
            return chr(int(m.group(1), 16))
        except ValueError:
            return m.group(0)
    out = re.sub(r"%([0-9a-fA-F]{2})", repl, s)
    return out if out != s else None


def try_rot13(s):
    out = codecs.encode(s, "rot_13")
    return out if out != s else None


def try_atbash(s):
    def flip(c):
        if "a" <= c <= "z":
            return chr(ord("z") - (ord(c) - ord("a")))
        if "A" <= c <= "Z":
            return chr(ord("Z") - (ord(c) - ord("A")))
        return c
    out = "".join(flip(c) for c in s)
    return out if out != s else None


def try_reversed(s):
    return s[::-1]


def try_leet(s):
    out = s.translate(LEET_MAP)
    return out if out != s else None


PIGLATIN_WORD = re.compile(r"\b([a-z]+)(way|ay)\b", re.IGNORECASE)

def try_piglatin(s):
    """Best-effort pig-latin reversal for phrase recovery (lossy, reported as a lead)."""
    def restore(m):
        word, suffix = m.group(1), m.group(2)
        if suffix.lower() == "way":
            return word                      # vowel-initial: just drop 'way'
        # consonant case: last letters were the moved onset
        if len(word) >= 1:
            return word[-1] + word[:-1]      # move trailing consonant back to front
        return word
    out = PIGLATIN_WORD.sub(restore, s)
    return out if out != s else None


DECODERS = [
    ("base64", try_base64),
    ("numeric-ascii", try_numeric_ascii),
    ("hex-escape", try_hex_escapes),
    ("unicode-escape", try_unicode_escapes),
    ("html-entity", try_html_entities),
    ("percent", try_percent),
    ("rot13", try_rot13),
    ("atbash", try_atbash),
    ("reversed", try_reversed),
    ("leetspeak", try_leet),
    ("piglatin", try_piglatin),
]


def deobfuscate_and_scan(text, depth=0, seen=None):
    """Recursively decode candidate blobs and re-run phrase detection.

    Returns findings where a decoded layer reveals injection/exfil content.
    Reversible-but-lossy transforms (leet/piglatin/rot13/atbash/reversed) are
    applied to the whole text; encoding transforms target candidate substrings.
    """
    if seen is None:
        seen = set()
    if depth >= MAX_DECODE_DEPTH:
        return []
    findings = []

    # 1) whole-text reversible transforms — only report if they REVEAL a phrase
    raw_patterns = {p for p, _, _ in phrase_hits(text)}
    for name in ("rot13", "atbash", "reversed", "leetspeak", "piglatin"):
        fn = dict(DECODERS)[name]
        decoded = fn(text)
        if not decoded or decoded in seen:
            continue
        new_hits = [(p, snip) for p, _, snip in phrase_hits(decoded) if p not in raw_patterns]
        if new_hits:
            seen.add(decoded)
            for pat, snip in new_hits[:5]:
                is_jb = pat in _JAILBREAK_PATTERN_SET
                findings.append(_finding(
                    "jailbreak" if is_jb else "obfuscated-instruction", None,
                    (f"jailbreak signature recovered via {name}" if is_jb
                     else f"suspicious phrase recovered via {name}"),
                    transform=name, pattern=pat, jailbreak=is_jb,
                    decoded=snip.strip()[:200]))
            findings += deobfuscate_and_scan(decoded, depth + 1, seen)

    # 2) substring encodings — find candidate blobs and decode them
    candidate_spans = []
    for rx in (BASE64_CANDIDATE, HEX_ESCAPE_RUN, UNICODE_ESCAPE_RUN,
               DECIMAL_SEQ, HTML_ENTITY_RUN, PERCENT_RUN):
        for m in rx.finditer(text):
            candidate_spans.append((m.start(), m.group()))

    for start, blob in candidate_spans:
        for name, fn in DECODERS:
            if name in ("rot13", "atbash", "reversed", "leetspeak", "piglatin"):
                continue
            decoded = fn(blob)
            if not decoded or decoded in seen or decoded == blob:
                continue
            seen.add(decoded)
            hits = phrase_hits(decoded)
            if hits:
                for pat, _, snip in hits[:5]:
                    is_jb = pat in _JAILBREAK_PATTERN_SET
                    findings.append(_finding(
                        "jailbreak" if is_jb else "encoded-payload", start,
                        (f"{name} blob decodes to a jailbreak signature" if is_jb
                         else f"{name} blob decodes to suspicious instruction/exfil text"),
                        transform=name, pattern=pat, jailbreak=is_jb,
                        decoded=snip.strip()[:200]))
            else:
                # Even without a phrase hit, a decodable hidden layer is a lead.
                preview = decoded.strip()[:120]
                if preview and any(c.isalpha() for c in preview):
                    findings.append(_finding("encoded-payload", start,
                                             f"{name} blob decodes to hidden text (no phrase match — lead only)",
                                             transform=name, decoded_preview=preview))
            # recurse into the decoded layer for nested encodings
            findings += deobfuscate_and_scan(decoded, depth + 1, seen)
    return findings


# --- Markdown link / image checks ----------------------------------------

def find_markdown_link_risks(text):
    findings = []
    for m in MD_LINK.finditer(text):
        is_image, label, href = m.group(1) == "!", m.group(2), m.group(3)
        low = href.lower()
        if is_image and low.startswith(("http://", "https://")):
            detail = "remote image auto-loads on render — possible exfil beacon / SSRF"
            if "?" in href and "=" in href.split("?", 1)[1]:
                detail += " (carries query parameters)"
            findings.append(_finding("markdown-remote-image", m.start(), detail, href=href))
        # deceptive link: label looks like a different URL/host than the href
        label_urls = re.findall(r"https?://[^\s)]+", label)
        if label_urls:
            import urllib.parse as up
            try:
                lhost = up.urlparse(label_urls[0]).netloc
                hhost = up.urlparse(href).netloc
                if lhost and hhost and lhost != hhost:
                    findings.append(_finding("deceptive-link", m.start(),
                                             f"link text host ({lhost}) differs from destination host ({hhost})",
                                             href=href, label=label))
            except Exception:
                pass
    return findings


# --- Structural stego lead: acrostic --------------------------------------

def find_acrostic(text):
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    if len(lines) < 6:
        return []
    acrostic = "".join(ln[0] for ln in lines if ln[:1].isalnum())
    if len(acrostic) < 6:
        return []
    for pattern in SUSPICIOUS_PHRASES:
        if re.search(pattern, acrostic, re.IGNORECASE):
            return [_finding("structural-stego", None,
                             "first-letters-of-lines (acrostic) spell an instruction-like string",
                             decoded=acrostic[:200])]
    return []


# --- Archive safety pre-check (no extraction) -----------------------------

def scan_archive(path):
    findings = []
    try:
        if zipfile.is_zipfile(path):
            with zipfile.ZipFile(path) as zf:
                infos = zf.infolist()
                if len(infos) > ARCHIVE_MEMBER_LIMIT:
                    findings.append(_finding("archive-risk", None,
                                             f"archive has {len(infos)} members (> {ARCHIVE_MEMBER_LIMIT}) — zip-bomb risk"))
                for zi in infos:
                    name = zi.filename
                    if name.startswith("/") or ".." in name.replace("\\", "/").split("/"):
                        findings.append(_finding("archive-risk", None,
                                                 f"unsafe member path (traversal/absolute): {name}"))
                    if zi.compress_size > 0 and (zi.file_size / zi.compress_size) > ZIP_RATIO_LIMIT:
                        findings.append(_finding("archive-risk", None,
                                                 f"member {name} expands {zi.file_size // max(1, zi.compress_size)}x — zip-bomb risk"))
        elif tarfile.is_tarfile(path):
            with tarfile.open(path) as tf:
                for ti in tf.getmembers():
                    if ti.name.startswith("/") or ".." in ti.name.replace("\\", "/").split("/"):
                        findings.append(_finding("archive-risk", None,
                                                 f"unsafe member path (traversal/absolute): {ti.name}"))
                    if ti.issym() or ti.islnk():
                        findings.append(_finding("archive-risk", None,
                                                 f"archive contains a link member ({ti.name} -> {ti.linkname}) — extraction escape risk"))
    except Exception as e:
        findings.append(_finding("archive-risk", None, f"could not inspect archive: {e}"))
    return findings


# --- Per-file scan --------------------------------------------------------

def scan_text_file(path):
    try:
        with open(path, "rb") as f:
            raw = f.read(MAX_FILE_BYTES + 1)
    except Exception as e:
        return {"file": path, "error": str(e)}
    truncated = len(raw) > MAX_FILE_BYTES
    text = raw[:MAX_FILE_BYTES].decode("utf-8", errors="replace")

    findings = []
    findings += find_hidden_chars(text)
    findings += find_homoglyph_runs(text)
    findings += find_skeleton_phrases(text)
    for pat, start, snip in phrase_hits(text):
        if pat in _JAILBREAK_PATTERN_SET:
            findings.append(_finding("jailbreak", start,
                                     f"jailbreak signature/framing matched: {pat!r}",
                                     jailbreak=True, snippet=snip.strip()[:200]))
        else:
            findings.append(_finding("instruction-override", start,
                                     f"matched injection/exfil pattern: {pat!r}",
                                     snippet=snip.strip()[:200]))
    findings += find_html_comment_instructions(text)
    findings += find_normalization_drift(text)
    findings += deobfuscate_and_scan(text)
    findings += find_markdown_link_risks(text)
    findings += find_acrostic(text)

    return {
        "file": path,
        "truncated": truncated,
        "finding_count": len(findings),
        "findings": findings,
    }


def scan_one(path):
    if path.lower().endswith(ARCHIVE_EXTS):
        f = scan_archive(path)
        return {"file": path, "archive": True, "finding_count": len(f), "findings": f}
    return scan_text_file(path)


def collect_files(path):
    if os.path.isfile(path):
        return [path]
    matches = []
    for root, _, files in os.walk(path):
        for name in files:
            low = name.lower()
            if low.endswith(TEXT_EXTS) or low.endswith(ARCHIVE_EXTS) or low == "skill.md":
                matches.append(os.path.join(root, name))
    return matches


def main():
    # Force UTF-8 output so decoded non-ASCII / control chars never crash on a
    # legacy console codepage (e.g. Windows cp1252). Best-effort; ignore if the
    # stream doesn't support reconfigure (older Pythons / redirected pipes).
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="backslashreplace")
    except Exception:
        pass
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) != 1:
        print("Usage: python prefilter.py <file_or_directory> [--json]", file=sys.stderr)
        sys.exit(2)
    target = args[0]
    if not os.path.exists(target):
        print(f"Path not found: {target}", file=sys.stderr)
        sys.exit(2)
    results = [scan_one(f) for f in collect_files(target)]
    total = sum(r.get("finding_count", 0) for r in results)
    print(json.dumps({
        "target": target,
        "files_scanned": len(results),
        "total_findings": total,
        "note": "Findings are LEADS for an LLM/human reviewer to confirm — not verdicts. "
                "Presence of obfuscation that decodes to instruction-like text is itself suspicious.",
        "results": results,
    }, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
