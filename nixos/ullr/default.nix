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

  fileSystems."/".options = [ "noatime" "nodiratime" "discard" "relatime" ];

  ###############################################
  #                 BOOT LOADER                 #
  ###############################################
  boot = {
    kernelParams = [
      "boot.shell_on_fail"
      "cgroup_enable=cpuset"
      "cgroup_enable=memory" 
      "cgroup_memory=1"
      "fbcon=nodefer"
      "loglevel=3"
      "nvidia_drm.modeset=1"
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
    "vm.swappiness" = 0;
    "vm.vfs_cache_pressure" = 90;
    "net.ipv4.tcp_congestion_control" = "bbr";     # Tweak local networking
    "net.core.netdev_max_backlog" = 30000;
    "net.core.rmem_default" = 262144;
    "net.core.wmem_default" = 262144;
    "net.core.wmem_max" = 67108864;
    "net.ipv4.ipfrag_high_threshold" = 5242880;
    "net.ipv4.tcp_keepalive_intvl" = 30;
    "net.ipv4.tcp_keepalive_probes" = 5;
    "net.ipv4.tcp_keepalive_time" = 300;
    "vm.dirty_background_bytes" = 583200768;      # 556 MB (128 MB + 450 MB)
    "vm.dirty_bytes" = 851968768;                 # 812 MB (384 MB + 450 MB)
    "vm.min_free_kbytes" = 65536;                 # Minimum free memory for safety (in KB)

    # Adjust dirty data management for NVMe drives
    "vm.dirty_background_ratio" = "5";            # Set the ratio of dirty memory at which background writeback starts (5%).
    "vm.dirty_expire_centisecs" = "3000";         # Set the time at which dirty data is old enough to be eligible for writeout (3000 centiseconds).
    "vm.dirty_ratio" = "10";                      # Set the ratio of dirty memory at which a process is forced to write out dirty data (10%).
    "vm.dirty_time" = "0";                        # Disable dirty time accounting.
    "vm.dirty_writeback_centisecs" = "300";       # Set the interval between two consecutive background writeback passes (300 centiseconds).    
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
    # theme = "Sweet-Mars";
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
      url = https://github.com/dxas90.keys;
      sha256 = "ff44683297b72895898610057d81e4961014f86d4068ffeec813bda2c5303a51";
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

  services.syncthing = {
    enable = true;
    overrideFolders = false;
    overrideDevices = false;
    user = "daniel";
    group = "users";
    dataDir = "/home/daniel/.syncthing";
    settings = {
      folders = {
        "/home/daniel/Sync" = {
          id = "default";
          label = "Default Folder";
          versioning = {
            type = "simple";
            params.keep = "3";
          };
        };
      };
    };
  };

  services.ollama = {
    enable = true;
    acceleration = "cuda";
    loadModels = [
      "codellama:13b"
      "deepseek-coder-v2"
      "gemma2:9b"
      # "llama3.2-vision"
      "llama3.2"
    ];
  };

  environment.systemPackages = with pkgs; [
    age
    age-plugin-yubikey
    appimage-run
    aria2
    bat
    bc
    brave
    btop
    btrfs-progs
    bzip2
    catppuccin-cursors.mochaDark
    canon-cups-ufr2
    comma
    crc # https://crc.dev/
    cups-bjnp
    curl
    direnv
    docker
    docker-buildx
    docker-credential-helpers
    fd
    fzf
    gcc
    gettext
    git
    gnumake
    home-manager
    htop
    ijs
    jq
    # kdePackages.colord-kde
    kdePackages.kleopatra
    kdePackages.plasma-vault
    kdePackages.print-manager
    # kdePackages.skanlite
    kdePackages.qtwayland
    killall
    libfido2
    lrzip
    lshw
    lsof
    lz4
    lzip
    lzop
    mc
    neovim
    nerdfonts
    onlyoffice-desktopeditors
    p7zip
    pinentry-curses
    pinentry-qt
    podman-desktop
    python3
    ripgrep
    sops
    starship
    steam
    unzip
    vagrant
    vlc
    # waydroid
    wezterm
    wget
    wireguard-tools
    x11_ssh_askpass
    xz
    yakuake
    yubikey-manager
    zip
    zstd
  ];

  environment.etc."nixos/active".text = config.system.nixos.label;
  # environment.etc."nixos/dotfiles-src".source = builtins.fetchGit {
  #   url = "https://github.com/dxas90/home.git";
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
        rm -f $XDG_RUNTIME_DIR/ssh-agent.socket
        ssh-agent -a $XDG_RUNTIME_DIR/ssh-agent.socket > "$XDG_RUNTIME_DIR/ssh-agent.env"
    fi
    if [[ ! "$SSH_AUTH_SOCK" ]]; then
        source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
    fi
  '';

  catppuccin = {
    enable = true;
    flavor = "mocha";
    plymouth.enable = false;
  };

  programs.neovim.enable = true;
  programs.git.enable = true;
  programs.gamemode.enable = true;

  programs.steam = {
    enable = false;
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
