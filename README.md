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

This `codex-ide` branch uses [Codex IDE for Emacs](https://github.com/dgillis/emacs-codex-ide),
a native client for `codex app-server`; it does not configure Agent Shell.

On the first switch to this branch, install the package and restart Emacs:

```sh
home-manager switch
doom sync
```

After that initial setup, you can compare this branch with `main` using only
`git switch <branch>`, `home-manager switch`, and an Emacs restart. Agent Shell
packages are intentionally retained on this branch so returning to `main` does
not require another `doom sync`.

The main commands are available under `SPC a`:

| Key | Action |
| --- | --- |
| `SPC a n` | Start a new Codex session for the current project |
| `SPC a c` | Continue the latest Codex session for the current project |
| `SPC a s` | Browse, preview, and reopen saved Codex threads for the current project |
| `SPC a l` | List live Codex session buffers across projects |
| `SPC a b` | Switch to the live Codex session for this project |
| `SPC a d` | Open the current session's live/transcript/pinned diff |
| `SPC a k` | Interrupt the active Codex turn |
| `SPC a m` | Open Codex IDE's full command and configuration menu |

In the project history view, use Evil `j`/`k` to move, `n`/`p` between session
entries, `RET` to open or resume a session, `TAB` to expand details, `g` to
refresh, `D` to delete a stored thread, and `K` to close a live buffer. Inside
a Codex session, `SPC m m` opens its menu, `SPC m d` opens its diff, and
`SPC m k` interrupts its active turn. Prompts are submitted with `C-c RET`.
