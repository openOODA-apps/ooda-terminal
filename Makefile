# ooda-console Makefile
#
# Apps-layer GUI terminal front end on the shared ooda-standard terminal engine.
#
# The VT500 engine (vt parser, grid, screen semantics, pixel raster, replay session) lives in
# ooda-standard/core/app/ui/term and is imported as "ooda-standard/core/app/ui/term/...".
# The compiler resolves that prefix against OODA_STANDARD_ROOT, so the root must be the standard
# SOURCE tree that carries core/app/ui/term. The sibling checkout is preferred; the installed copy
# under ~/.openooda is the fallback. Override with `make OODA_STANDARD_ROOT=<path>`.

OODA_COMPILER ?= $(HOME)/.openooda/bin/ooda-compiler
OODA_VERIFY ?= $(HOME)/.openooda/bin/ooda-verify
OODA_STANDARD_ROOT ?= $(firstword $(wildcard $(CURDIR)/../../openOODA-core/ooda-standard $(HOME)/.openooda/ooda-standard))
OODA_RUNTIME_ROOT ?= $(HOME)/.openooda/bin
OODACODEX ?= $(HOME)/.openooda/AGENTS.md
export OODA_COMPILER OODA_VERIFY OODA_STANDARD_ROOT OODA_RUNTIME_ROOT OODACODEX
OO_LIST_AMBIENT_QUOTA ?= 8589934592
OODA_FS_READDIR ?= $(HOME)/.openooda:$(CURDIR):/tmp
OODA_FS_WRITEDIR ?= $(CURDIR):/tmp
OODA_NO_JAIL ?= 1
export OO_LIST_AMBIENT_QUOTA
export OODA_FS_READDIR OODA_FS_WRITEDIR OODA_NO_JAIL

PREFIX ?= $(HOME)/.openooda/bin
BIN := bin/ooda-console
FUNC_BIN := bin/test_functional
REFUSE_BIN := bin/test_refusal
EMIT_BIN := bin/emit_vt
REPO_NAME := ooda-console
VER := 0.1.0
SRC := $(shell find cli core tests -name "*.oo" 2>/dev/null) anchor.oo
ENV := OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODA_COMPILER=$(OODA_COMPILER) OODA_STANDARD_ROOT=$(OODA_STANDARD_ROOT) OODA_RUNTIME_ROOT=$(OODA_RUNTIME_ROOT) OODACODEX=$(OODACODEX) OODA_FS_READDIR=$(OODA_FS_READDIR) OODA_FS_WRITEDIR=$(OODA_FS_WRITEDIR) OODA_NO_JAIL=1

.PHONY: all build verify test det check cycle gate line-cap file-law academy density vocab clean shape link-law

all: build verify test det

build: $(BIN)

$(BIN): $(SRC)
	@mkdir -p bin .ooda-cache
	$(ENV) $(OODA_COMPILER) build cli/main.oo -o $(BIN)
	@chmod +x $(BIN)
	@echo "built $(BIN)"

$(FUNC_BIN): tests/test_functional.oo
	@mkdir -p bin
	$(ENV) $(OODA_COMPILER) build tests/test_functional.oo -o $(FUNC_BIN)
	@chmod +x $(FUNC_BIN)

$(REFUSE_BIN): tests/test_refusal.oo
	@mkdir -p bin
	$(ENV) $(OODA_COMPILER) build tests/test_refusal.oo -o $(REFUSE_BIN)
	@chmod +x $(REFUSE_BIN)

$(EMIT_BIN): tests/emit_vt.oo
	@mkdir -p bin
	$(ENV) $(OODA_COMPILER) build tests/emit_vt.oo -o $(EMIT_BIN)
	@chmod +x $(EMIT_BIN)

line-cap:
	@violations=0; \
	for f in $$(find . -name "*.oo" -o -name "*.oot" | grep -v "/.git/" | grep -v "/bin/" | grep -v "/dist/" | grep -v "/.ooda-cache/"); do \
		n=$$(wc -l < "$$f"); \
		if [ "$$n" -gt 256 ]; then \
			echo "VIOLATION: $$f = $$n lines (exceeds 256)"; violations=$$((violations+1)); \
		fi; \
		code=$$(grep -vE '^[[:space:]]*(//.*)?$$' "$$f" | grep -cvE '^[[:space:]]*import[[:space:]]+"'); \
		if [ "$$code" = "0" ]; then continue; fi; \
		if [ "$$n" -lt 16 ]; then \
			echo "VIOLATION: $$f = $$n lines (under 16-line floor, not a shim)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ "$$violations" -gt 0 ]; then echo "FAIL: $$violations files violate the Page Rule"; exit 1; fi; \
	echo "PASS: Page Rule sizing (16-256 lines, shims exempt from floor) holds"

file-law:
	@forbidden="c h py rs js ts rb pl json yaml toml html sh"; violations=0; \
	for ext in $$forbidden; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./bin/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; violations=$$((violations+1)); fi; \
	done; \
	for nm in util utils helper helpers common misc shared base core; do \
		found=$$(find . -name "$$nm.oo" -not -path "./.git/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -not -path "./bin/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then echo "VIOLATION: banned page name $$nm.oo:"; echo "$$found"; violations=$$((violations+1)); fi; \
	done; \
	for f in $$(find . -name "*.md" -not -path "./.git/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -not -path "./bin/*" 2>/dev/null); do \
		b=$$(basename "$$f"); \
		if [ "$$b" != "README.md" ] && [ "$$b" != "AGENTS.md" ]; then echo "VIOLATION: .md forbidden outside README.md and AGENTS.md: $$f"; violations=$$((violations+1)); fi; \
	done; \
	if [ "$$violations" -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./.git/*" -not -path "./bin/*" -not -path "./dist/*" -not -path "./.ooda-cache/*"); do \
		header=$$(head -7 "$$f"); \
		missing=""; \
		echo "$$header" | grep -q "^// # "        || missing="$$missing title"; \
		echo "$$header" | grep -q "^// Logline:"  || missing="$$missing logline"; \
		echo "$$header" | grep -q "^// Setup:"    || missing="$$missing setup"; \
		echo "$$header" | grep -q "^// Beats:"    || missing="$$missing beats"; \
		if [ -n "$$missing" ]; then \
			echo "FAIL: $$f missing Academy element(s):$$missing"; failures=$$((failures+1)); \
		fi; \
	done; \
	if [ "$$failures" -gt 0 ]; then echo "FAIL: $$failures academy header violations"; exit 1; fi; \
	echo "PASS: academy headers hold"

density:
	@violations=0; \
	for d in $$(find . -type d -not -path "./.git*" -not -path "./bin*" -not -path "./dist*" -not -path "./.ooda-cache*"); do \
		n=$$(ls "$$d"/*.oo "$$d"/*.oot 2>/dev/null | grep -v '\*' | wc -l); \
		if [ "$$n" -gt 8 ]; then \
			echo "VIOLATION: $$d holds $$n pages (exceeds 8)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ "$$violations" -gt 0 ]; then echo "FAIL: $$violations directories exceed density bound"; exit 1; fi; \
	echo "PASS: directory density (<= 8 pages per directory) holds"

vocab:
	@if grep -rniE 't[o]do|f[i]xme|x[x]x|h[a]ck|sover[e]ign|boot[s]trap|moon[s]hot|dog[f]ight|b[l]ackbox|a[u]topsy|c[o]ckpit|w[i]ngman|fl[i]ght|[S]tage [0-9]|[P]illar [0-9]' $$(find . -type f \( -name "*.oo" -o -name "*.oot" -o -name "*.md" -o -name "*.pkg" \) -not -path "./.git/*" -not -path "./.ooda-cache/*" -not -path "./dist/*" -not -path "./bin/*") 2>/dev/null | grep -vi 'prefl[i]ght'; then \
		echo "FAIL: banned vocabulary present"; exit 1; \
	fi; \
	echo "PASS: vocabulary check holds"

shape:
	@violations=0; \
	for f in $$(find . -name "*.oo" -not -path "./.git/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -not -path "./bin/*"); do \
		count=$$(grep -cE "^[[:space:]]*(pub[[:space:]]+)?fn[[:space:]]" "$$f"); \
		if [ "$$count" -gt 8 ]; then echo "VIOLATION: $$f has $$count fns"; violations=$$((violations+1)); fi; \
		out=$$(awk -v file="$$f" 'BEGIN{in_fn=0; start=0; fn_name=""} /^[[:space:]]*(pub[[:space:]]+)?fn[[:space:]]/ { if (in_fn) { len=NR-start; if (len>64) print "VIOLATION: " file " " fn_name " is " len " lines (>64)" } in_fn=1; start=NR; fn_name=$$0 } END{ if (in_fn) { len=NR-start+1; if (len>64) print "VIOLATION: " file " " fn_name " is " len " lines (>64)" } }' "$$f"); \
		if [ -n "$$out" ]; then echo "$$out"; violations=$$((violations+1)); fi; \
	done; \
	if [ "$$violations" -gt 0 ]; then echo "FAIL: $$violations shape violations"; exit 1; fi; \
	echo "PASS: shape law holds (<=8 fns/page, <=64 lines/fn)"

link-law:
	@violations=0; \
	for f in $$(find . -type l -not -path "./.git/*" 2>/dev/null); do \
		echo "VIOLATION: symbolic link $$f"; violations=$$((violations+1)); \
	done; \
	for f in $$(find . -type f -links +1 -not -path "./.git/*" 2>/dev/null); do \
		echo "VIOLATION: hard link $$f"; violations=$$((violations+1)); \
	done; \
	if [ "$$violations" -gt 0 ]; then echo "FAIL: $$violations link law violations"; exit 1; fi; \
	echo "PASS: link law holds (no symbolic link, no hard link)"

check:
	@for f in $$(find . -name "*.oo" -not -path "./.git/*" -not -path "./bin/*" -not -path "./dist/*" -not -path "./.ooda-cache/*"); do \
		$(ENV) $(OODA_COMPILER) check "$$f" > /dev/null || { echo "VIOLATION: ooda-compiler check fails on $$f"; exit 1; }; \
	done; \
	echo "PASS: ooda-compiler check holds on all .oo files"

cycle:
	@$(OODA_VERIFY) cycle $(CURDIR) < /dev/null
	@echo "PASS: composite gate holds (ooda-verify quorum_mask=255)"

gate:
	@$(OODA_VERIFY) cycle $(CURDIR) < /dev/null
	@echo "PASS: composite gate holds (ooda-verify quorum_mask=255)"

verify: line-cap file-law academy density vocab check shape link-law cycle

test: $(BIN) $(FUNC_BIN) $(REFUSE_BIN) $(EMIT_BIN)
	@PATH=/nonexistent ./$(FUNC_BIN) < /dev/null | grep -q "PASS: 23/23 console assertions" && echo "PASS: functional suite (23 assertions)"
	@PATH=/nonexistent ./$(REFUSE_BIN) < /dev/null | grep -q "PASS: 14/14 console refusal assertions" && echo "PASS: refusal suite (14 assertions)"
	@./$(BIN) --help | grep -q "$(REPO_NAME) $(VER)" && echo "PASS: --help"
	@./$(BIN) --version | grep -q "$(VER)" && echo "PASS: --version"
	@./$(BIN) status | grep -q "PASS" && echo "PASS: status"
	@./$(BIN) verify | grep -q "verify OK" && echo "PASS: verify"
	@./$(BIN) inspect | grep -q '"status":"pass"' && echo "PASS: inspect"
	@./$(BIN) --self-test | grep -q "PASS" && echo "PASS: --self-test"
	@./$(BIN) --json | grep -q '"status":"pass"' && echo "PASS: --json"
	@./$(BIN) --json > .ooda-cache/r1.txt && ./$(BIN) --json > .ooda-cache/r2.txt && cmp -s .ooda-cache/r1.txt .ooda-cache/r2.txt && echo "PASS: double-run output determinism"
	@./$(BIN) about | grep -q "Binary       : $(REPO_NAME) (v$(VER))" && echo "PASS: about binary"
	@./$(BIN) about | grep -q "Organization : openOODA-apps" && echo "PASS: about org"
	@./$(BIN) about | grep -q "Subcommands  :" && echo "PASS: about subcommands"
	@./$(BIN) about | grep -q "Capabilities :" && echo "PASS: about capabilities"
	@./$(BIN) about | grep -q "Theme        :" && echo "PASS: about theme"
	@./$(BIN) about --json | grep -q '"component":"$(REPO_NAME)"' && echo "PASS: about --json component"
	@./$(BIN) about --json | grep -q '"organization":"openOODA-apps"' && echo "PASS: about --json org"
	@./$(BIN) about --json | wc -l | grep -q "^1$$" && echo "PASS: about --json is one line"
	@rc=0; ./$(BIN) --definitely-unknown-flag > /dev/null 2>&1 || rc=$$?; [ "$$rc" = "2" ] && echo "PASS: unknown argument exits 2"
	@rc=0; ./$(BIN) about nosuchtarget > /dev/null 2>&1 || rc=$$?; [ "$$rc" = "2" ] && echo "PASS: about unknown target exits 2"
	@rc=0; ./$(BIN) about --bad-flag > /dev/null 2>&1 || rc=$$?; [ "$$rc" = "2" ] && echo "PASS: about unknown flag exits 2"
	@rc=0; ./$(BIN) run > /dev/null 2>&1 || rc=$$?; [ "$$rc" = "2" ] && echo "PASS: run missing operand exits 2"
	@rc=0; ./$(BIN) pty-run > /dev/null 2>&1 || rc=$$?; [ "$$rc" = "2" ] && echo "PASS: pty-run missing operand exits 2"
	@rc=0; ./$(BIN) theme nosuchtheme > /dev/null 2>&1 || rc=$$?; [ "$$rc" = "2" ] && echo "PASS: unknown theme exits 2"
	@printf 'alpha\r\nbeta\r\n' > .ooda-cache/transcript.txt
	@./$(BIN) run .ooda-cache/transcript.txt | grep -q "alpha" && echo "PASS: run replays a transcript through the engine"
	@./$(BIN) run .ooda-cache/transcript.txt | grep -q "replay path=" && echo "PASS: run reports the replay summary"
	@rm -f .ooda-cache/transcript.txt
	@rc=0; ./$(BIN) run /tmp/../etc/$(REPO_NAME)_evil.txt > /dev/null 2>&1 || rc=$$?; [ "$$rc" = "2" ] && echo "PASS: run refuses a parent-directory path (CWE-22)"
	@./$(BIN) pty-run ./$(EMIT_BIN) | grep -q "GREEN" && echo "PASS: pty-run interprets a live child through the engine"
	@echo "ALL TESTS PASSED"

det: $(BIN)
	@$(ENV) $(OODA_COMPILER) build cli/main.oo -o .ooda-cache/det_a > /dev/null
	@$(ENV) $(OODA_COMPILER) build cli/main.oo -o .ooda-cache/det_b > /dev/null
	@cmp -s .ooda-cache/det_a .ooda-cache/det_b && sha256sum .ooda-cache/det_a && echo "PASS: deterministic build (byte-identical)" || (echo "FAIL: nondeterministic build"; exit 1)

clean:
	@rm -rf bin dist .ooda-cache

install: build
	@mkdir -p $(DESTDIR)$(PREFIX)
	install -m 0755 $(BIN) $(DESTDIR)$(PREFIX)/ooda-console
	@echo "installed ooda-console to $(DESTDIR)$(PREFIX)"
