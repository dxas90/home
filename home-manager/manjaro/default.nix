{ inputs, outputs, lib, config, pkgs, ... }: let
  homePath = "/home/daniel";
in
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
  home.homeDirectory = homePath;

  catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  home.stateVersion = "24.11"; # Please read the comment before changing.
  programs = {
    lazygit.enable = true;
    zoxide.enable = true;
    starship.enable = false;
    bash = {
      enable = true;
      historyControl = [ "ignoredups" "ignorespace" ];
      bashrcExtra = "eval \"$(starship init bash)\"\nif [ -f ~/.bash_aliases ]; then\n. ~/.bash_aliases\nfi\nfor script in \"$HOME/.config/sops-nix/secrets/\"*.sh; do [ -f \"$script\" ] && source \"$script\"; done\n";
    };
    direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
      nix-direnv.enable = true;
    };
    # Tmate terminal sharing.
    tmate = {
      enable = true;
      #host = ""; #In case you wish to use a server other than tmate.io
    };
    tmux = {
      enable = true;
      terminal = "tmux-256color";
      clock24 = true;
      # aggressiveResize = true; -- Disabled to be iTerm-friendly
      baseIndex = 1;
      keyMode = "vi";
      newSession = true;

      plugins = with pkgs; [
        tmuxPlugins.better-mouse-mode
      ];
    };
    wezterm = {
      enable = false;
      # https://alexplescan.com/posts/2024/08/10/wezterm/
      extraConfig = builtins.readFile ./config/wezterm.lua;
    };
    git = {
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
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages =  with pkgs; [
     keepassxc
     nerdfonts
     discord
     teams-for-linux
     telegram-desktop
     aria2
     neovim
  ];

#   home.file = {
#     ".git-commit.txt".source = ./config/git-commit.tx;
#     ".gitignore".source = ./config/gitignore;
#     ".tmux.conf".source = ./config/tmux.conf;
#     #".config/starship.toml".source = ./config/starship.toml;
#     ".config/nvim" = {
#         source = ./nvim;
#         recursive = true;
#     };
#     ".config/mc/ini".source = ./config/mc.ini;
#     ".wezterm.lua".source = ./config/wezterm.lua;
#     ".bash_aliases".source = ./config/bash_aliases;
#     ".bash_logout".source = ./config/bash_logout;
#     ".face".source = ./.face;
#     ".face.icon".source = ./.face;
#     ".ssh/config".source = ./config/ssh_config;
#     ".config/lazygit/config.yml".text = ''
#     disableStartupPopups: true
#     reporting: "off"
#     '';
#     ".config/environment.d/gsk.conf".text = ''
#     GSK_RENDERER=gl
#     '';
#     ".ssh/config.d/git".text = ''
#     Host github.com
#       HostName github.com
#       User git
#     Host gitlab.com
#       HostName gitlab.com
#       User git
#     '';
#   };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "\$EDITOR";
    GS_OPTIONS = "-sPAPERSIZE=a4";
    GIT_SSH_COMMAND = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i \${HOME}/.ssh/id_ed25519";
    MY_SHELL = "\$(basename \$(readlink /proc/\$\$/exe))";
    DOCKER_CLI_EXPERIMENTAL = "enabled";
    NIXPKGS_ALLOW_UNFREE = "1";
    SSH_AUTH_SOCK="\${XDG_RUNTIME_DIR}/ssh-agent.socket";
  };

  home.shellAliases = {
    g = "git";
    vim = "nvim";
    cat = "bat -p";
    "..." = "cd ../..";
    hmu = "home-manager switch --flake github:dxas90/home#manjaro --impure --refresh --extra-experimental-features \"nix-command flakes\"";
    nsp = "nix-shell -p";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.linkerd2/bin"
    "$HOME/.local/go/bin"
    "$HOME/.cargo/bin"
  ];

  nix.gc = {
    automatic = true;
    # Change how often the garbage collector runs (default: weekly)
    frequency = "hourly";
  };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  sops = {
    age.keyFile = "${homePath}/.config/sops/age/keys.txt"; # must have no password!
    # It's also possible to use a ssh key, but only when it has no password:
    age.sshKeyPaths = [ "${homePath}/.ssh/id_rsa" ];
    defaultSopsFile = ./secrets.sops.yaml;
    secrets."hello" = {
      mode = "0400";
      path = "%r/secrets/hello";
    };
    secrets."codestats_api_key.sh" = {
      mode = "0500";
    };
    secrets."pve.sh" = {
      mode = "0500";
    };
    secrets."cf_api_token" = {
      mode = "0400";
    };
    secrets."cf_r2_tf_access_key" = {
      mode = "0400";
    };
    secrets."cf_r2_tf_secret_key" = {
      mode = "0400";
    };
    templates."config-with-secrets.toml" = {
      mode = "0400";
      content = ''
        password = "${config.sops.placeholder.hello}"
      '';
    };
  };
}
