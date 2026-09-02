# Home Manager configuration

This repository is a standalone Home Manager configuration. It manages the
user environment, shell configuration, and the private Doom Emacs
configuration in `doom.d/`.

## First-time setup

Install Nix first, then clone this repository and bootstrap its pinned Home
Manager configuration:

```sh
git clone git@github.com:daghub/home-manager.git ~/.config/home-manager
cd ~/.config/home-manager
nix --extra-experimental-features "nix-command flakes" \
  run github:nix-community/home-manager -- switch --flake .#dekengren
```

The first activation enables `nix-command` and `flakes` in the user Nix
configuration, so subsequent switches do not need the bootstrap flags.

## Install Doom Emacs

Home Manager installs Emacs and Doom's command-line dependencies. Doom itself
is intentionally a normal, writable Git checkout, because Doom needs to manage
its own package state. Its core revision is pinned in `flake.lock`.

The first Home Manager activation creates a checkout at the revision pinned in
`flake.lock`, then synchronizes Doom:

```sh
home-manager switch --flake .#dekengren
~/.config/emacs/bin/doom doctor
```

`doom install` performs the initial package synchronization and uses the
Home-Manager-managed private configuration at `~/.config/doom`. Doom keeps
its installation and generated package state under `~/.config/emacs`; leave
that checkout unmanaged. Afterward, launch Doom with `emacs` as usual.

## Updating this configuration

After changing or pulling Home Manager files, activate the new generation:

```sh
cd ~/.config/home-manager
home-manager switch
```

This repository lives at Home Manager's default flake path and its profile is
named after the user, so no `--flake` argument is needed for normal use.
Use `--flake <path>#<profile>` only when activating a different checkout or
profile.

## Pin inventory and upgrades

`flake.lock` is the source of truth for the three external pins below. Inspect
the lockfile diff before activating an update, then commit it with the
corresponding configuration change.

| Pin | Scope | Upgrade |
| --- | --- | --- |
| `nixpkgs` | Emacs, terminal tools, and all Home Manager packages | `nix flake update nixpkgs` |
| `home-manager` | Home Manager modules and activation behavior | `nix flake update home-manager` |
| `doom-core` | Doom core checkout at `~/.config/emacs` | `nix flake update doom-core`, then `home-manager switch` |

After updating `nixpkgs` or `home-manager`, activate the new generation:

```sh
nix flake update nixpkgs
home-manager switch
```

Update all three together only when that is intentional:

```sh
nix flake update
home-manager switch
```

Your Doom configuration (`doom.d/`) is pinned by this repository's Git commit.
Doom pins its package set by default; use explicit `:pin` values in
`doom.d/packages.el` for any package that must not follow Doom's chosen
revision. Codex is deliberately outside these pins and updates independently.

### Doom configuration changes

`doom.d/config.el`, `doom.d/init.el`, and `doom.d/packages.el` are linked into
`~/.config/doom` by Home Manager. After changing `init.el` or `packages.el`,
run `doom sync`; changes to `config.el` take effect after restarting Emacs.

```sh
home-manager switch
doom sync
```

Home Manager automatically moves Doom core to the locked revision and runs a
forced Doom sync on every activation. `doom-core-sync` remains available to
repair a checkout manually, but normal updates need only `home-manager switch`.

```sh
home-manager switch
```

Do not use `git pull` in `~/.config/emacs`: it bypasses the `doom-core` pin.

If `doom` is not available by name in the current shell, use
`~/.config/emacs/bin/doom` or open a new terminal after Home Manager has been
activated.

### Codex sessions in Doom

This configuration uses [Codex IDE for Emacs](https://github.com/dgillis/emacs-codex-ide),
a native client for `codex app-server`.

After the first Home Manager activation, install the package and restart
Emacs:

```sh
home-manager switch
doom sync
```

The main commands are available under `SPC a`:

| Key | Action |
| --- | --- |
| `SPC a n` | Start a new Codex session for the current project |
| `SPC a c` | Continue the latest Codex session for the current project |
| `SPC a s` | Browse, preview, and reopen saved Codex threads for the current project |
| `SPC a S` | Pick and resume a saved Codex session from any project |
| `SPC a /` | Search Codex sessions as literal text |
| `SPC a ?` | Search Codex sessions with a regular expression |
| `SPC a a` | Archive the current session, or pick one from the current project |
| `SPC a A` | Pick and archive a session from any project |
| `SPC a l` | List live Codex session buffers across projects |
| `SPC a b` | Switch to the live Codex session for this project |
| `SPC a d` | Open the current session's live/transcript/pinned diff |
| `SPC a k` | Interrupt the active Codex turn |
| `SPC a r` | Rename the current session |
| `SPC a M` | Set the model and reasoning effort |
| `SPC a e` | Set the reasoning effort |
| `SPC a m` | Open Codex IDE's full command and configuration menu |

In the project history view, use Evil `j`/`k` to move, `n`/`p` between session
entries, `RET` to open or resume a session, `TAB` to expand details, `g` to
refresh, `r` to rename a stored thread, `D` to delete a stored thread, and `K`
to close a live buffer. `SPC a r` renames the current session from any Codex
view. Inside a Codex session, `SPC m m` opens its menu, `SPC m d` opens its diff, and
`SPC m k` interrupts its active turn. `RET` submits prompts; `Shift+RET`
inserts a newline. The upstream `C-c RET` submit binding also remains
available.
