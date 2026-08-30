# Home Manager configuration

This repository is a standalone Home Manager configuration. It manages the
user environment, shell configuration, and the private Doom Emacs
configuration in `doom.d/`.

## First-time setup

Install [Home Manager](https://nix-community.github.io/home-manager/) first,
then clone this repository and activate it:

```sh
git clone git@github.com:daghub/home-manager.git ~/.config/home-manager
cd ~/.config/home-manager
home-manager switch
```

## Install Doom Emacs

Home Manager installs Emacs and Doom's command-line dependencies. Doom itself
is intentionally a normal, writable Git checkout, because Doom needs to manage
its own Git and package state.

After the first `home-manager switch`, run:

```sh
git clone --depth 1 https://github.com/doomemacs/core ~/.config/emacs
~/.config/emacs/bin/doom install
~/.config/emacs/bin/doom doctor
```

`doom install` performs the initial package synchronization and uses the
Home-Manager-managed private configuration at `~/.config/doom`. Doom keeps
its installation and generated package state under `~/.config/emacs`; leave
that checkout unmanaged. Afterward, launch Doom with `emacs` as usual.

## Updating this configuration

After changing or pulling changes to `home.nix` or other Home Manager files,
activate the new generation:

```sh
cd ~/.config/home-manager
home-manager switch
```

### Doom configuration changes

`doom.d/config.el`, `doom.d/init.el`, and `doom.d/packages.el` are linked into
`~/.config/doom` by Home Manager. After changing `init.el` or `packages.el`,
run `doom sync`; changes to `config.el` take effect after restarting Emacs.

```sh
home-manager switch
doom sync
```

To update Doom itself, do so deliberately and then synchronize it:

```sh
git -C ~/.config/emacs pull --ff-only
doom sync
doom doctor
```

If `doom` is not available by name in the current shell, use
`~/.config/emacs/bin/doom` or open a new terminal after Home Manager has been
activated.

### Codex sessions in Doom

Agent Shell provides the Codex client. Use `SPC a n` to start a Codex session
or select a session to resume; `SPC a t` toggles the current Agent Shell
buffer. Codex itself remains the source of truth for its saved sessions.
