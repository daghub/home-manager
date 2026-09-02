{ config, inputs, lib, pkgs, ... }:
let
  doomCoreSync = pkgs.writeShellApplication {
    name = "doom-core-sync";
    runtimeInputs = [ pkgs.emacs pkgs.git ];
    text = ''
      set -eu

      doom_dir="${config.xdg.configHome}/emacs"
      expected_rev="${inputs.doom-core.rev}"

      if ! git -C "$doom_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Doom checkout not found at $doom_dir" >&2
        echo "Clone it first, then run doom-core-sync again." >&2
        exit 1
      fi

      if [ "$(git -C "$doom_dir" rev-parse HEAD)" != "$expected_rev" ]; then
        if ! git -C "$doom_dir" diff-index --quiet HEAD --; then
          echo "Doom checkout has tracked changes; refusing to replace them." >&2
          exit 1
        fi

        git -C "$doom_dir" fetch --depth=1 origin "$expected_rev"
        git -C "$doom_dir" checkout --detach "$expected_rev"
      fi

      "$doom_dir/bin/doom" sync --force
    '';
  };
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  #
  # Doom itself follows its upstream layout:
  #   ~/.config/emacs  — Doom core clone (mutable)
  #   ~/.config/doom   — private config, linked from ./doom.d by Home Manager
  home = {
    username = "dekengren";
    homeDirectory = "/home/dekengren";
    sessionPath = [
      "${config.xdg.configHome}/emacs/bin"
      "${config.home.homeDirectory}/.local/bin"
    ];
    sessionVariables = {
      EDITOR = "emacs";
      LANG = "C.UTF-8";
      POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD = "true";
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.local";
    };
  };

  # Keep the flake interface available after the initial bootstrap switch.
  nix = {
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "22.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.git
    pkgs.tig
    pkgs.htop
    pkgs.bmon
    pkgs.openssh
    pkgs.ripgrep
    pkgs.fd
    pkgs.python3
    pkgs.python3Packages.jedi-language-server
    pkgs.python3Packages.flake8
    pkgs.zsh-powerlevel10k
    pkgs.bazel-buildtools
    pkgs.xsel
    pkgs.go
    pkgs.gopls
    pkgs.pyright
    pkgs.emacs
    pkgs.cloc
    pkgs.eternal-terminal
    pkgs.nodejs
    doomCoreSync
  ];


  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    profileExtra = ''
      if [ -e "${config.home.homeDirectory}/.nix-profile/etc/profile.d/nix.sh" ]; then
        . "${config.home.homeDirectory}/.nix-profile/etc/profile.d/nix.sh"
      fi
    '';
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
      ];
    };
    initContent = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      source "${config.home.homeDirectory}/.p10k.zsh"
    '';
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    prefix = "`";
    terminal = "tmux-256color";
    mouse = true;
    extraConfig = ''
# See https://github.com/spudlyo/clipetty#dealing-with-a-stale-ssh_tty-environment-variable
set -ag update-environment "SSH_TTY"
set -s set-clipboard on
setw -g aggressive-resize on
bind -T copy-mode-vi v send -X begin-selection
bind -n S-Up select-pane -L
bind -n S-Down select-pane -R
bind -n S-Left previous-window
bind -n S-Right next-window
# No delay for escape key press
set -sg escape-time 0
    '';
    plugins = [ pkgs.tmuxPlugins.yank ];
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".p10k.zsh".source = ./p10k.zsh;
  };

  xdg = {
    enable = true;
    configFile = {
      # Doom natively searches ~/.config/doom; symlinked files are supported.
      "doom/config.el".source = doom.d/config.el;
      "doom/init.el".source = doom.d/init.el;
      "doom/packages.el".source = doom.d/packages.el;
    };
  };

  # Keep Doom's mutable core checkout and generated package state aligned with
  # the pinned Emacs and Doom revisions whenever Home Manager is activated.
  home.activation.doomCoreSync = lib.hm.dag.entryAfter [ "installPackages" "linkGeneration" ] ''
    if [ -z "$DRY_RUN_CMD" ] && [ -d "${config.xdg.configHome}/emacs/.git" ]; then
      ${doomCoreSync}/bin/doom-core-sync
    fi
  '';

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
