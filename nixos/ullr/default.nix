{ inputs, outputs, lib, config, pkgs, ... }:
let
  ifGroupsExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    # ./secrets.nix
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
  time.hardwareClockInLocalTime = true;

  # networking.firewall.enable = false;
  networking.firewall.trustedInterfaces = [ "cni+" ]; # https://github.com/NixOS/nixpkgs/issues/98766#issuecomment-1232804319
  networking.hostName = "ullr";
  networking.networkmanager.enable = true;

  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

  ###############################################
  #                 BOOT LOADER                 #
  ###############################################
  boot = {
    kernelParams = [
      "boot.shell_on_fail"
      "cgroup_enable=cpuset"
      "cgroup_enable=memory" 
      "cgroup_memory=1"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "systemd.unified_cgroup_hierarchy=1"
      "udev.log_priority=3"
      "quiet"
      "splash"
    ];
    consoleLogLevel = 0;
    initrd.verbose = false;
    loader = {
      timeout = 0;
      systemd-boot = {
        configurationLimit = 3;
        enable = true;
        windows = {
          "10-pro" = {
            title = "Windows 10 Pro";
            efiDeviceHandle = "HD2b65535a1";
          };
          "11-pro" = {
            title = "Windows 11 Pro";
            efiDeviceHandle = "HD0b";
          };
        };
        edk2-uefi-shell.enable = false;
      };
      efi = {
        canTouchEfiVariables = true;
        # efiSysMountPoint = "/boot/efi"; # ← use the same mount point here.
      };
      grub = {
        enable = false;
        efiSupport = true;
        # efiInstallAsRemovable = true; # in case canTouchEfiVariables doesn't work for your system
        device = "/dev/sda";
        useOSProber = true;
        configurationLimit = 3;
      };
    };
    plymouth = 
    let
      theme = "infinite_seal";
    in
    {
      enable = true;
      inherit theme;
      themePackages = with pkgs; [
        # By default we would install all themes
        (adi1090x-plymouth-themes.override {
          selected_themes = [ theme ];
        })
      ];
    };
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
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.tcp_fastopen" = 3;
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 50;
  };
  boot.tmp.useTmpfs = false;
  boot.devShmSize = "50%";
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
    autoNumlock = true;
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
  services.pcscd.enable = true;

  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.Policy.AutoEnable = "true";
    settings.General = {
        Enable = "Source,Sink,Media,Socket";
        Name = "Ullr";
        ControllerMode = "dual";
        FastConnectable = "true";
        Experimental = "true";
        KernelExperimental = "true";
    };
  };
  # NVIDIA
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
  hardware.nvidia-container-toolkit.enable = true;
  # services.blueman.enable = false;
  # services.colord.enable = false;
  services.printing.enable = true;

  ####################################################
  #                 USER APPLICATION                 #
  ####################################################
  users.users.daniel = {
    shell = pkgs.bash;
    home = "/home/daniel";
    isNormalUser = true;
    openssh.authorizedKeys.keys = lib.strings.splitString "\n" (builtins.fetchurl {
      url = https://github.com/dramirez-qb.keys;
      sha256 = "84b34e33be4cce737a6260f980062618f711d7a23e925dbf2c258ee175837fc2";
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
      "docker"
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

  systemd.services."user@".serviceConfig.Delegate = "memory pids cpu cpuset";

  environment.systemPackages = with pkgs; [
    age
    age-plugin-yubikey
    appimage-run
    aria2
    bat
    bc
    brave
    btop
    canon-cups-ufr2
    crc # https://crc.dev/
    cups-bjnp
    curl
    direnv
    # docker
    # docker-buildx
    fd
    fzf
    gcc
    gettext
    git
    gnumake
    home-manager
    htop
    jq
    # kdePackages.colord-kde
    kdePackages.kleopatra
    kdePackages.plasma-vault
    kdePackages.print-manager
    kdePackages.qtwayland
    killall
    libfido2
    lshw
    lsof
    lz4
    lzip
    mc
    neovim
    nerdfonts
    onlyoffice-desktopeditors
    pinentry-curses
    pinentry-qt
    podman-desktop
    python3
    ripgrep
    sops
    starship
    steam
    vlc
    # waydroid
    wezterm
    wget
    wireguard-tools
    x11_ssh_askpass
    yakuake
    yubikey-manager
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
    if ! pgrep -u "$USER" ssh-agent > /dev/null; then
        ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
    fi
    if [[ ! "$SSH_AUTH_SOCK" ]]; then
        source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
    fi
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

  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  programs.gnupg.agent ={
    enable = true;
  };
  virtualisation = {
    containers ={
      enable = true;
    };
    docker = {
      enable = true;
      rootless = {
        enable = false;
        setSocketVariable = true;
      };
      # https://docs.docker.com/reference/cli/dockerd/#daemon-configuration-file
      daemon.settings = {
        experimental = true;
        fixed-cidr-v6 = "fd00::/80";
        ip6tables = false;
        ipv6 = false;
        live-restore = true;
        metrics-addr = "0.0.0.0:9323";
        userland-proxy = false;
        dns = [
          "10.23.23.1"
          "1.1.1.1"
          "8.8.8.8"
        ];
        "default-address-pools" = [
          { base = "10.254.0.0/16"; size = 24; }
          { base = "10.253.0.0/16"; size = 24; }
          { base = "10.252.0.0/16"; size = 24; }
        ];
        builder = {
          gc = {
            enabled = true;
            defaultKeepStorage = "10GB";
          };
        };
      };
    };
    multipass = {
      enable = true;
      logLevel = "info";
    };
    podman = {
      autoPrune.enable = true;
      enable = false;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    # waydroid = {
    #   enable = false;
    # };
  };
}
