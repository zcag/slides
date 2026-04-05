BASE := /
OUT  := $(CURDIR)/dist
PORT ?= 3030

# Also used by github workflow
build:
	rm -rf "$(OUT)"
	mkdir -p "$(OUT)"

	# symlink shared styles into each deck
	find decks -mindepth 1 -maxdepth 3 -name slides.md | while read -r f; do \
	  dir=$$(dirname "$$f"); \
	  [ -e "$$dir/style.css" ] || ln -sf "$(CURDIR)/shared/style.css" "$$dir/style.css"; \
	done; true

	# build decks (supports decks/name/ and decks/group/name/)
	find decks -mindepth 1 -maxdepth 3 -name slides.md | while read -r f; do \
	  deck=$${f#decks/}; deck=$${deck%/slides.md}; \
	  echo "▶ building $$deck"; \
	  npx slidev build "$$f" \
	    --base "$(BASE)$$deck/" \
	    --out "$(OUT)/$$deck"; \
	done

	# generate index.html from template
	cp templates/index.html "$(OUT)/index.html"
	find decks -mindepth 1 -maxdepth 3 -name slides.md | sort | while read -r f; do \
	  deck=$${f#decks/}; deck=$${deck%/slides.md}; \
	  title=$$(awk '/^---$$/{n++} n==1 && /^title:/{sub(/^title:[[:space:]]*/,"");print;exit}' "$$f"); \
	  [ -z "$$title" ] && title="$$deck"; \
	  desc=$$(awk '/^---$$/{n++} n==1 && /^description:/{sub(/^description:[[:space:]]*/,"");print;exit}' "$$f"); \
	  desctag=""; \
	  [ -n "$$desc" ] && desctag="<div class=\"desc\">$$desc</div>"; \
	  group=$$(dirname "$$deck"); \
	  [ "$$group" = "." ] && group="" ; \
	  grouptag=""; \
	  [ -n "$$group" ] && grouptag="<div class=\"group\">$$group</div>"; \
	  sed -i "s|<!--DECKS-->|<a class=\"card\" href=\"./$$deck/\">$$grouptag<div class=\"title\">$$title</div>$$desctag<div class=\"path\">/$$deck/</div></a>\n<!--DECKS-->|" "$(OUT)/index.html"; \
	done

dev:
	@deck=$(filter-out $@,$(MAKECMDGOALS)); \
	dir=decks/$$deck; \
	[ ! -e "$$dir/style.css" ] && ln -sf "$(CURDIR)/shared/style.css" "$$dir/style.css"; \
	( sleep 2 && xdg-open http://localhost:$(PORT) ) & \
	exec npx slidev decks/$$deck/slides.md --host 0.0.0.0 --port $(PORT)

# swallow positional arg
%:
	@:
