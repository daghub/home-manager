{ config, pkgs, ... }:

let
  doom-emacs = pkgs.callPackage (builtins.fetchTarball {
    url = https://github.com/nix-community/nix-doom-emacs/archive/develop.tar.gz;
  }) {
    doomPrivateDir = ./doom.d;
  };
in {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "dekengren";
  home.homeDirectory = "/home/dekengren";

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
    pkgs.openssh
    pkgs.ripgrep
    pkgs.fd
    pkgs.python3
    pkgs.python3Packages.python-lsp-server
    pkgs.python3Packages.jedi-language-server
    pkgs.python3Packages.flake8
    pkgs.zsh-powerlevel10k
    pkgs.xsel
    doom-emacs

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];


  programs.zsh = {
    enable = true;
    sessionVariables = {
       LC_ALL = "C.UTF-8";
       LANG = "C.UTF-8";
    };
    shellAliases = {
       emacs = "emacs -nw";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "fd"
        "ripgrep"
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
bind -T copy-mode-vi v send -X begin-selection
bind -n S-Up select-pane -L
bind -n S-Down select-pane -R
bind -n S-Left previous-window
bind -n S-Right next-window
    '';
    plugins = [ pkgs.tmuxPlugins.yank ];
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    ".p10k.zsh".source = ./p10k.zsh;
  };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/dekengren/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    EDITOR = "emacs";
    POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD = "true";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
