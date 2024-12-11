{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    username = "dekengren";
    homeDirectory = "/home/dekengren";
    sessionPath = [ "${config.xdg.configHome}/emacs/bin" ];
    sessionVariables = {
      DOOMDIR = "${config.xdg.configHome}/doom-config";
      DOOMLOCALDIR = "${config.xdg.configHome}/doom-local";
      EDITOR = "emacs";
      POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD = "true";
    };
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
    pkgs.direnv
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
  ];


  programs.zsh = {
    enable = true;
    sessionVariables = {
       LC_ALL = "C.UTF-8";
       LANG = "C.UTF-8";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "direnv"
        "pyenv"
      ];
    };
    initExtra = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme && source .p10k.zsh";
  };

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    prefix = "`";
    terminal = "screen-256color";
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
      "doom-config/config.el".source = doom.d/config.el;
      "doom-config/init.el".source = doom.d/init.el;
      "doom-config/packages.el".source = doom.d/packages.el;
      "emacs" = {
        source = builtins.fetchGit {
          url = "https://github.com/hlissner/doom-emacs";
          rev = "ba1dca322f9a07bc2b7bec6a98f2c3c55c0bbd77";
        };
        onChange = "${pkgs.writeShellScript "doom-change" ''
          export DOOMDIR="${config.home.sessionVariables.DOOMDIR}"
          export DOOMLOCALDIR="${config.home.sessionVariables.DOOMLOCALDIR}"
          if [ ! -d "$DOOMLOCALDIR" ]; then
            ${config.xdg.configHome}/emacs/bin/doom -y install
          else
            ${config.xdg.configHome}/emacs/bin/doom -y sync -u
          fi
        ''}";
      };
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
