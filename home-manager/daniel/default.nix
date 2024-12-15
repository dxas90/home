{ inputs, outputs, config, pkgs, ... }:
let
  homeDirectory = "/home/daniel";
  ageKeyFile = "${homeDirectory}/.config/age/keys.txt";
in
{
  ##################################################
  #                 BASIC SETTINGS                 #
  ##################################################
  nix = {
    package = pkgs.nix;
    settings.experimental-features = "nix-command flakes";
  };

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config.allowUnfree = true;
  };

  #################################################
  #                 USER SETTINGS                 #
  #################################################
   # Home Manager needs a bit of information about you and the paths it should
  # manage.

  home.username = "daniel";
  home.homeDirectory = homeDirectory;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.
  programs.bash.enable = true;
  programs.bash.bashrcExtra = "eval \"$(starship init bash)\"\nif [ -f ~/.bash_aliases ]; then\n. ~/.bash_aliases\nfi\n";

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
      core.editor = "nvim";
      core.autocrlf = "input";
      core.quotepath = false;
      core.commitGraph = true;
      core.excludesfile = "~/.gitignore";
      core.ignorecase = false;
      credential.helper = "cache --timeout=57600";
      merge.conflictstyle = "diff3";
      merge.tool = "vimdiff";
      branch.autosetuprebase = "always";
      fetch.prune = true;
      color.ui = true;
      color.status = "auto";
      color.branch = "auto";
      push.default = "simple";
      push.followTags = true;
      push.autoSetupRemote = true;
      mergetool.prompt = false;
      gc.writeCommitGraph = true;
      init.defaultBranch = "main";
      receive.advertisePushOptions = true;
      receive.procReceiveRefs = "refs/for";
      commit.gpgsign = true;
      commit.template = "~/.git-commit.txt";
      gpg.format = "ssh";
      filter.lfs.smudge = "git-lfs smudge -- %f";
      filter.lfs.process = "git-lfs filter-process";
      filter.lfs.required = true;
      filter.lfs.clean = "git-lfs clean -- %f";
      diff.sopsdiffer.textconv = "sops -d";
    };
  };

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages =  with pkgs; [
     devspace
     k3d
     k9s
     kubectl
     lazygit
     nerdfonts
     syncthing
     vcluster
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
    ".git-commit.txt".text = ''
     # (If applied, this commit will...) <subject> (Max 50 char)
     # |<----  Using a Maximum Of 50 Characters  ---->|

     # Explain why this change is being made
     # |<----   Try To Limit Each Line to a Maximum Of 72 Characters   ---->|
     # Why is this change needed? Prior to this change,...

     # How does it address the issue? This change...

     # Provide links to any relevant tickets, articles or other resources
     # Example: Github issue #23

     # Remember to
     #    Capitalize the subject line
     #    Use the imperative mood in the subject line
     #    Do not end the subject line with a period
     #    Separate subject from body with a blank line
     #    Use the body to explain what and why vs. how
     #    Can use multiple lines with "-" for bullet points in body
     # --------------------
     # For more information about this template, check out
     # https://chris.beams.io/posts/git-commit/
    '';
    ".gitignore".source = ./.gitignore;
    ".config/environment.d/ssh-agent.conf".text = ''
    SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent
    '';
    ".config/starship.toml".source = ./starship.toml;
    ".config/nvim" = {
        source = ./nvim;
        recursive = true;
    };
    ".wezterm.lua".text = ''
    -- Pull in the wezterm API
    local wezterm = require 'wezterm'

    -- This will hold the configuration.
    local config = wezterm.config_builder()

    -- This is where you actually apply your config choices

    -- For example, changing the color scheme:
    config.color_scheme = 'Catppuccin Mocha'

    --config.font = wezterm.font 'Symbols Nerd Font Mono'

    --config.webgpu_preferred_adapter = {
    --  backend = 'Vulkan',
    --  device = 9479,
    --  device_type = 'DiscreteGpu',
    --  driver = 'NVIDIA',
    --  driver_info = '550.135',
    --  name = 'NVIDIA GeForce RTX 3050',
    --  vendor = 4318,
    --}

    config.front_end = 'WebGpu'

    -- and finally, return the configuration to wezterm
    return config
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
  };

  home.shellAliases = {
    g = "git";
    "..." = "cd ../..";
    hmu = "home-manager switch --flake github:dramirez-qb/home#daniel --impure --refresh";
  };

  # services
#  services.syncthing = {
#    enable = true;
#  };

  programs.direnv.enable = true;
  programs.lazygit.enable = true;
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
