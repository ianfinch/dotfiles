SHELL := bash
.DEFAULT_GOAL := cli

.PHONY: all
all: cli gui

.PHONY: cli
cli: dotfiles

.PHONY: gui
gui: regolith terminal backgrounds applications

.PHONY: dotfiles
dotfiles:
	mkdir -p $(HOME)/.config
	for file in $(shell find $(CURDIR) -path "$(CURDIR)/_*" -type f -not -name "*.swp") ; do \
		f=$$(echo $$file | sed 's|^$(CURDIR)/_|.|'); \
		ln -sfn $$file $(HOME)/$$f; \
	done

.PHONY: regolith
regolith:
	mkdir -p $(HOME)/.config/regolith/i3
	mkdir -p $(HOME)/.config/regolith/compton
	ln -sfn $(CURDIR)/resources/regolith/i3-config $(HOME)/.config/regolith/i3/config
	ln -sfn $(CURDIR)/resources/regolith/i3xrocks $(HOME)/.config/regolith/i3xrocks
	ln -sfn $(CURDIR)/resources/regolith/compton-config $(HOME)/.config/regolith/compton/config
	regolith-look set lascaille
	regolith-look refresh

.PHONY: terminal
terminal:
	dconf load /org/gnome/terminal/legacy/profiles:/ < $(CURDIR)/resources/gnome-terminal-profiles.dconf

.PHONY: applications
applications:
	for file in $(shell find $(CURDIR) -path "$(CURDIR)/resources/applications/*" -type f -not -name "*.swp") ; do \
		f=$$(echo $$file | sed 's|^$(CURDIR)/resources/applications/||'); \
		ln -sfn $$file $(HOME)/.local/share/applications/$$f; \
	done

.PHONY: backgrounds
backgrounds:
	gsettings set org.gnome.desktop.background picture-uri file:///$(CURDIR)/backgrounds/desktop.png
	gsettings set org.gnome.gnome-flashback screensaver false
	ln -sfn $(CURDIR)/backgrounds/lockscreen.png $(HOME)/.config/regolith/lockscreen.png
