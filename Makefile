SHELL := bash
.DEFAULT_GOAL := cli

.PHONY: all
all: cli gui

.PHONY: cli
cli: dotfiles

.PHONY: gui
gui: regolith terminal backgrounds

.PHONY: dotfiles
dotfiles:
	mkdir -p $(HOME)/.config
	for file in $(shell find $(CURDIR) -name "_*" -not -name "*.swp") ; do \
		f=$$(basename $$file | sed 's/^_/./'); \
		ln -sfn $$file $(HOME)/$$f; \
	done

.PHONY: regolith
regolith:
	mkdir -p $(HOME)/.config/regolith/i3
	ln -sfn $(CURDIR)/resources/regolith/i3-config $(HOME)/.config/regolith/i3/config
	ln -sfn $(CURDIR)/resources/regolith/i3xrocks $(HOME)/.config/regolith/i3xrocks
	regolith-look set lascaille
	echo "#include \"$(CURDIR)/resources/regolith/Xresources-regolith\"" >> $(HOME)/.Xresources-regolith
	regolith-look refresh

.PHONY: terminal
terminal:
	dconf load /org/gnome/terminal/legacy/profiles:/ < $(CURDIR)/resources/gnome-terminal-profiles.dconf

.PHONY: backgrounds
backgrounds:
	gsettings set org.gnome.desktop.background picture-uri file:///$(CURDIR)/backgrounds/desktop.png
