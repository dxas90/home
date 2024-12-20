{ inputs, outputs, lib, config, pkgs, ... }:
let
  ifGroupsExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  imports = [
    ./hardware-configuration.nix
    inputs.sops-nix.nixosModules.sops
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

  networking.hostName = "generic";
  networking.networkmanager.enable = true;

  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

  ###############################################
  #                 BOOT LOADER                 #
  ###############################################
  boot.loader = {
    systemd-boot = {
      enable = false;
      configurationLimit = 3;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi"; # ← use the same mount point here.
    };
    grub = {
      efiSupport = true;
      #efiInstallAsRemovable = true; # in case canTouchEfiVariables doesn't work for your system
      device = "nodev";
    };
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

  boot.kernel.sysctl = { 
    "fs.aio-max-nr" = 524288;
    "fs.file-max" = 9000000;
    "fs.inotify.max_user_instances" = 10240;
    "fs.inotify.max_user_watches" = 524288;
    "fs.nr_open" = 12000000;
    "kernel.dmesg_restrict" = 0;
    "kernel.hung_task_timeout_secs" = 0;
    "net.core.rmem_max" = 16777216;
    "net.ipv4.tcp_fastopen" = 3;
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 50;
  };
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
    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTRS{idVendor}=="2357", ATTRS{idProduct}=="012d", ATTR{address}="34:60:f9:92:56:4c", NAME="usb_wlan0", SYMLINK+="usb_wlan0", TAG+="uaccess", TAG+="wifi""
    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTRS{idVendor}=="2001", ATTRS{idProduct}=="3319", ATTR{address}="34:0a:33:35:02:14", NAME="usb_wlan1", SYMLINK+="usb_wlan1", TAG+="uaccess", TAG+="wifi""
    SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTRS{idVendor}=="2001", ATTRS{idProduct}=="331d", ATTR{address}="34:0a:33:34:86:8c", NAME="usb_wlan2", SYMLINK+="usb_wlan2", TAG+="uaccess", TAG+="wifi""
  '';

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  services.displayManager.defaultSession = "plasma";
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

  hardware.graphics.enable = true;


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

  environment.systemPackages = with pkgs; [
    age
    aria2
    brave
    bc
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
    lshw
    lsof
    lz4
    lzip
    mc
    neovim
    nerdfonts
    obs-studio
    ripgrep
    steam
    sops
    starship
    vlc
    waydroid
    wezterm
    wireguard-tools
    wget
    yakuake
  ];

  environment.etc."nixos/active".text = config.system.nixos.label;
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

  virtualisation = {
    containers ={
      enable = true;
    };
    docker = {
      enable = false;
      daemon.settings = {
        experimental = true;
        fixed-cidr-v6 = "fd00::/80";
        ip6tables = false;
        ipv6 = false;
        live-restore = true;
        metrics-addr = "0.0.0.0:9323";
        userland-proxy = false;
      };
    };
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    waydroid = {
      enable = false;
    };
  };
}
