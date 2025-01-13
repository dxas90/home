{ inputs, outputs, config, pkgs, ... }:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  #################################################
  #                 USER SETTINGS                 #
  #################################################
   # Home Manager needs a bit of information about you and the paths it should
  # manage.

  home.username = "daniel";
  home.homeDirectory = "/home/daniel";

  catppuccin.flavor = "mocha";
  catppuccin.enable = true;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.
  programs.bash = {
    enable = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    bashrcExtra = "eval \"$(starship init bash)\"\nif [ -f ~/.bash_aliases ]; then\n. ~/.bash_aliases\nfi\n";
  };

  programs.git = {
    enable = true;
    userName = "Daniel Ramirez";
    userEmail = "dxas90@gmail.com";
    signing.signByDefault = true;
    signing.key = "~/.ssh/id_rsa.pub";
    aliases = {
      ca = "commit -a";
      ci = "commit";
      co = "checkout";
      st = "status";
      fa = "fetch --all";
      dat = "show --no-patch --no-notes --pretty='%cd'";
      amend = "commit --amend -m";
      pa = "!git remote | xargs -L1 git push --all";
      a = "!git status --short | peco | awk '{print $2}' | xargs git add";
      d = "diff";
      ps = "!git push origin $(git rev-parse --abbrev-ref HEAD)";
      pl = "!git pull origin $(git rev-parse --abbrev-ref HEAD)";
      br = "branch";
      ba = "branch -a";
      bm = "branch --merged";
      bn = "branch --no-merged";
      lg = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''     %C(black)%s%C(reset) %C(dimwhite)- %an%C(reset)' --all";
      lola = "log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --all";
      lol = "log --graph --decorate --oneline";
      llog = "log --graph --name-status --pretty=format:\'%C(red)%h %C(reset)(%cd) %C(green)%an %Creset%s %C(yellow)%d%Creset\' --date=relative";
      pln-release = "!'f() { git log \'$1\' --format=format:\'%aE * [ ] %C(auto)%h %Creset%s\' | sed 's/[0-9]\\{6,\\}+//g' | sed 's/users.noreply.github.com/quickbase.com/g' | sort | python3 ~/bin/email_sort.py; }; f'";
    };
    extraConfig = {
      branch.autosetuprebase = "always";
      color.branch = "auto";
      color.status = "auto";
      color.ui = true;
      commit.gpgsign = true;
      commit.template = "~/.git-commit.txt";
      core.autocrlf = "input";
      core.commitGraph = true;
      core.editor = "nvim";
      core.excludesfile = "~/.gitignore";
      core.ignorecase = false;
      core.quotepath = false;
      credential.helper = "cache --timeout=57600";
      diff.sopsdiffer.textconv = "sops -d";
      fetch.prune = true;
      filter.lfs.clean = "git-lfs clean -- %f";
      filter.lfs.process = "git-lfs filter-process";
      filter.lfs.required = true;
      filter.lfs.smudge = "git-lfs smudge -- %f";
      gc.writeCommitGraph = true;
      gpg.format = "ssh";
      init.defaultBranch = "main";
      merge.conflictstyle = "diff3";
      merge.tool = "vimdiff";
      mergetool.prompt = false;
      push.autoSetupRemote = true;
      push.default = "simple";
      push.followTags = true;
      receive.advertisePushOptions = true;
      receive.procReceiveRefs = "refs/for";
    };
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages =  with pkgs; [
    #  audacity
    #  blender
     devpod-desktop
     devspace
     discord
    #  famistudio
     git-credential-keepassxc
     go-task
     godot_4
     k3d
     k9s
     keepassxc
     kopia
     krita
     kubectl
     lazygit
     lens
     nerdfonts
     obsidian
     qbittorrent
     syncthing
     teams-for-linux
     telegram-desktop
     tor-browser
     vcluster
     zoom-us
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;
    ".git-commit.txt".source = ./config/git-commit.tx;
    ".gitignore".source = ./config/gitignore;
    # ".config/environment.d/ssh-agent.conf".text = ''
    # SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent
    # '';
    ".config/starship.toml".source = ./config/starship.toml;
    ".config/nvim" = {
        source = ./nvim;
        recursive = true;
    };
    ".config/mc/ini".source = ./config/mc.ini;
    ".wezterm.lua".source = ./config/wezterm.lua;
    ".bash_aliases".source = ./config/bash_aliases;
    ".face".source = ./.face;
    ".face.icon".source = ./.face;
    ".ssh/config".source = ./config/ssh_config;
    ".config/lazygit/config.yml".text = ''
    disableStartupPopups: true
    reporting: "off"
    '';
    ".config/environment.d/gsk.conf".text = ''
    GSK_RENDERER=gl
    '';
    ".ssh/config.d/github".text = ''
    Host github.com
      HostName github.com
      User git
    '';
    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/daniel/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
    GS_OPTIONS = "-sPAPERSIZE=a4";
    GIT_SSH_COMMAND = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i \${HOME}/.ssh/id_ed25519";
    MY_SHELL = "\$(basename \$(readlink /proc/\$\$/exe))";
    DOCKER_CLI_EXPERIMENTAL = "enabled";
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  home.shellAliases = {
    g = "git";
    "..." = "cd ../..";
    hmu = "home-manager switch --flake github:dramirez-qb/home#daniel --impure --refresh";    
    nsp = "nix-shell -p";
  };
  
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # services
#  services.syncthing = {
#    enable = true;
#  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true; # see note on other shells below
    nix-direnv.enable = true;
  };
  programs.lazygit.enable = true;
  programs.obs-studio = {
    enable = false;
    plugins = with pkgs; [
      obs-studio-plugins.wlrobs
      obs-studio-plugins.obs-websocket
      obs-studio-plugins.obs-multi-rtmp
      obs-studio-plugins.obs-move-transition
      obs-studio-plugins.advanced-scene-switcher
    ];
  };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  sops = {
    age.keyFile = "\${HOME}/.config/sops/age/keys.txt"; # must have no password!
    # It's also possible to use a ssh key, but only when it has no password:
    age.sshKeyPaths = [ "\${HOME}/.ssh/automation.pub" ];
    defaultSopsFile = ./secrets.sops.yaml;
    secrets."myservice/my_subdir/my_secret" = {
      mode = "0440";
      # owner = config.users.users.daniel.name;
      # group = config.users.users.daniel.group;
      path = "%r/my_secret"; 
    };
  };
}
