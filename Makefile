SHELL := bash
.DEFAULT_GOAL := cli

.PHONY: all
all: cli gui

.PHONY: cli
cli: dotfiles

.PHONY: gui
gui: regolith terminal backgrounds applications themes fonts

.PHONY: dotfiles
dotfiles:
	mkdir -p $(HOME)/.config
	mkdir -p $(HOME)/.config/cmus
	for file in $(shell find $(CURDIR) -path "$(CURDIR)/_*" -type f -not -name "*.swp") ; do \
		f=$$(echo $$file | sed 's|^$(CURDIR)/_|.|'); \
		ln -sfn $$file $(HOME)/$$f; \
	done

.PHONY: regolith
regolith:
	mkdir -p $(HOME)/.config/regolith/i3
	mkdir -p $(HOME)/.config/regolith/compton
	mkdir -p $(HOME)/.config/regolith/scripts
	ln -sfn $(CURDIR)/resources/regolith/i3-config $(HOME)/.config/regolith/i3/config
	ln -sfn $(CURDIR)/resources/regolith/i3xrocks $(HOME)/.config/regolith/i3xrocks
	ln -sfn $(CURDIR)/resources/regolith/compton-config $(HOME)/.config/regolith/compton/config
	ln -sfn $(CURDIR)/scripts/regolith/launcher $(HOME)/.config/regolith/scripts/launcher
	ln -sfn $(CURDIR)/scripts/regolith/show-bindings $(HOME)/.config/regolith/scripts/show-bindings
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

.PHONY: themes
themes:
	mkdir -p $(HOME)/.themes
	cat $(CURDIR)/resources/themes/02-Flat-Remix-GTK-Green-20220627.tar.xz | xz --decompress --stdout | tar xf - --directory=$(HOME)/.themes
	gsettings set org.gnome.desktop.interface gtk-theme Flat-Remix-GTK-Green-Light

.PHONY: fonts
fonts:
	mkdir -p $(HOME)/.fonts
	curl -fL -o /tmp/Inconsolata.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Inconsolata.zip
	mkdir /tmp/fonts
	unzip -d /tmp/fonts /tmp/Inconsolata.zip
	cp /tmp/fonts/*.ttf $(HOME)/.fonts
