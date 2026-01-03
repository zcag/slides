BASE := /slides/
OUT  := $(CURDIR)/dist
PORT ?= 3030

# Also used by github workflow
build:
	rm -rf "$(OUT)"
	mkdir -p "$(OUT)"

	# build decks
	find decks -mindepth 2 -maxdepth 2 -name slides.md | while read -r f; do \
	  deck=$$(basename $$(dirname "$$f")); \
	  echo "▶ building $$deck"; \
	  npx slidev build "$$f" \
	    --base "$(BASE)$$deck/" \
	    --out "$(OUT)/$$deck"; \
	done

	# generate index.html from template
	cp templates/index.html "$(OUT)/index.html"
	find decks -mindepth 2 -maxdepth 2 -name slides.md | while read -r f; do \
	  deck=$$(basename $$(dirname "$$f")); \
	  sed -i "s|<!--DECKS-->|<a class=\"card\" href=\"./$$deck/\"><div class=\"name\">$$deck</div><div class=\"path\">/$$deck/</div></a>\n<!--DECKS-->|" "$(OUT)/index.html"; \
	done

dev:
	@deck=$(filter-out $@,$(MAKECMDGOALS)); \
	( sleep 2 && xdg-open http://localhost:$(PORT) ) & \
	exec npx slidev decks/$$deck/slides.md --host 0.0.0.0 --port $(PORT)

# swallow positional arg
%:
	@:
