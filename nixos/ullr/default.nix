{ inputs, outputs, lib, config, pkgs, ... }:
let
  ifGroupsExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  ageKeyFile = "${config.users.users.daniel.home}/.config/age/keys.txt";
in
{
  imports = [
    ./hardware-configuration.nix
    inputs.sugar-candy.nixosModules.default
  ];

  ################################################
  #                 NIX SETTINGS                 #
  ################################################
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

    channel.enable = true;

    settings = {
      flake-registry = "";
      auto-optimise-store = true;
      experimental-features = "nix-command flakes";
      nix-path = config.nix.nixPath;

      # Avoid disk full issues
      max-free = lib.mkDefault (1000 * 1000 * 1000);
      min-free = lib.mkDefault (128 * 1000 * 1000);

      warn-dirty = false;
    };

    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "-d --repair --delete-older-than 2d";
      randomizedDelaySec = "45min";
    };
  };

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config.allowUnfree = true;
  };

  ###################################################
  #                 SYSTEM SETTINGS                 #
  ###################################################
  system.stateVersion = "24.11";

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Sofia";

  networking.hostName = "ullr";
  networking.networkmanager.enable = true;

  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

  ###############################################
  #                 BOOT LOADER                 #
  ###############################################
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 3;
    efi.canTouchEfiVariables = true;
  };

  boot.plymouth = {
    enable = true;
    theme = "colorful_loop";
    themePackages = [
      (pkgs.adi1090x-plymouth-themes.override {
        selected_themes = [ "colorful_loop" ];
      })
    ];
  };

  boot.kernel.sysctl = { "vm.swappiness" = 1; };
  boot.tmp.useTmpfs = true;
  boot.tmp.cleanOnBoot = true;

  ############################################
  #                 SERVICES                 #
  ############################################
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="apex", MODE="0660", GROUP="users"
    ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="b8:85:84:b8:ae:2c", NAME="eth0"
  '';

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    sugarCandyNix = {
      enable = true;
      settings = {
        # TODO: Check if this is good
        PartialBlur = true;
        # FullBlur = true;
        # BlurRadius = 35;
        ScreenWidth = 1920;
        ScreenHeight = 1200;
        # MainColor = "#7EBAE4";
        MainColor = "#B3BEC7";
        AccentColor = "#F2F2E9";
        BackgroundColor = "#000000";
        # ScaleImageCropped = false;
        HaveFormBackground = true;
        Background = lib.cleanSource ./norway-river-view.jpg;
        HeaderText = "nivem";
        Font = "CaskaydiaCove NF";
      };
    };
  };

  services.displayManager.defaultSession = "plasmax11";
  services.desktopManager.plasma6.enable = true;

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = ["daniel"]; # Allows all users by default. Can be [ "user1" "user2" ]
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "prohibit-password"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
    };
  };

  services.flatpak.enable = true;

  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;

  # NVIDIA
  # hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;

  ####################################################
  #                 USER APPLICATION                 #
  ####################################################
  users.users.daniel = {
    shell = pkgs.bash;
    home = "/home/daniel";
    isNormalUser = true;
    openssh.authorizedKeys.keys = lib.strings.splitString "\n" (builtins.fetchurl {
      url = https://github.com/dramirez-qb.keys;
      sha256 = "621341ff4df62480eac9092e449ac565ac3440b68ae373a78b37c0ca4577e5d2";
    });
    extraGroups = [
      "networkmanager"
      "plugdev"
      "input"
      "wheel"
      "media"
      "video"
      "dialout"
    ]
    ++ ifGroupsExist [
      "network"
      "samba-users"
    ];
  };

  # NOTE: `fc-cache -r`
  fonts = {
    packages = with pkgs; [
      ubuntu-sans
     (nerdfonts.override {
      fonts = [ "CascadiaCode" ];
     })
    ];
    fontconfig.defaultFonts = {
      serif = [ "Ubuntu Sans" ];
      sansSerif = [ "Ubuntu Sans" ];
      monospace = [ "CaskaydiaCove NF" ];
    };
  };

  sops = {
    age.keyFile = ageKeyFile;
    age.generateKey = true;
  };

  environment.systemPackages = with pkgs; [
    age
    brave
    btop
    curl
    direnv
    docker_27
    fd
    fzf
    gcc
    gettext
    git
    gnumake
    htop
    jq
    killall
    mc
    neovim
    nerdfonts
    obs-studio
    ripgrep
    steam
    sops
    starship
    waydroid
    wezterm
    wget
    yakuake
  ];

  environment.etc."nixos/active".text = config.system.nixos.label;
  # environment.etc."nixos/dotfiles-src".source = builtins.fetchGit {
  #   url = "https://github.com/dramirez-qb/home.git";
  #   ref = "main";
  # };
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };
  environment.variables = {
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
  environment.interactiveShellInit = ''
    alias vim='nvim'
  '';

  programs.neovim.enable = true;
  programs.git.enable = true;
  programs.gamemode.enable = true;

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  virtualisation = {
    containers ={
      enable = true;
    };
    docker = {
      enable = false;
      daemon.settings = {
        userland-proxy = false;
        experimental = true;
        metrics-addr = "0.0.0.0:9323";
        ipv6 = true;
        fixed-cidr-v6 = "fd00::/80";
      };
    };
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    waydroid = {
      enable = true;
    };
  };
}
