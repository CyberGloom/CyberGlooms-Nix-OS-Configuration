{ config, pkgs, inputs, ... }: {

  imports = [ ./hardware-configuration.nix ];
  system.nixos.label = "Chaotic-Nyx";
  # sudo responisbly  
  # security.sudo.extraConfig = ''
  # Defaults lecture="always"
  # '';

  # =========================================================================
  # 1. BINARY CACHE / SUBSTITUTERS
  # =========================================================================
  nix.settings = {
    substituters = [ "https://cache.nixos.org" ];
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    
    # Enable Flakes and command line tool support
    experimental-features = [ "nix-command" "flakes" ];
    
    # Automatically use all available logical CPU cores for parallel builds
    max-jobs = "auto";
  
    # Suggest how many cores each individual build job can consume (0 = use all available)
    cores = 0;

    # Automatically optimize/hardlink duplicate files in the Nix store to save space and I/O overhead
    auto-optimise-store = true;
  
    # Allow building as many things concurrently as possible without restriction
    builders-use-substitutes = true;
  };

  # =========================================================================
  # 2. CORE SYSTEM & HARDWARE
  # =========================================================================
  
  boot.loader = {
  # Enable GRUB
  grub = {
      enable = true;
      device = "nodev"; 
      efiSupport = true;
      useOSProber = true; 
      enableCryptodisk = false; 
    };
  };

  boot.loader.timeout = 300; 
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "Spectra";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";
  
  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # Hardware Tweaks for Intel CPU + AMD GPU
  hardware.cpu.intel.updateMicrocode = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Native System Services
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.fprintd.enable = true;
  services.thermald.enable = true;
  services.geoclue2.enable = true;

  # Peripheral Hardware Daemons
  services.hardware.openrgb.enable = true;
  services.ratbagd.enable = true;

  # udev services
  services.udev.extraRules = ''
  SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0b05", MODE="0666", TAG+="uaccess"
  '';

  # =========================================================================
  # 3. THE DESKTOP ENVIRONMENT
  # =========================================================================
  
  # Enable Niri
  # programs.niri.enable = true;
 
  # Enable Noctalia Greeter
  # programs.noctalia-greeter = {
  #  enable = true;
  #  settings = {
  #    cursor = {
  #      theme = "Bibata-Modern-Ice";
  #      size = 24;
  #     };
  #   };
  # };
 
  # Enable COSMIC
  services.desktopManager.cosmic.enable = true;

  # Enable COSMIC Login Manager
  services.displayManager.cosmic-greeter.enable = true;

  # Enable System76 Scheduler
  services.system76-scheduler.enable = true;

  # Global Wayland environmental protocol force targets
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    PROTON_USE_WAYLAND = "1";
  };

  # Pipewire Audio Configuration
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # =========================================================================
  # 4. SHELLS, ENVIRONMENT, & USER ACCOUNT
  # =========================================================================
  programs.fish.enable = true;
  nixpkgs.config.allowUnfree = true;

  users.users.kittie = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "networkmanager" "video" "input" "openrazer" ];
  };

  # =========================================================================
  # 5. GAMING, PERFORMANCE, & FHS CAPABILITIES
  # =========================================================================
  programs.steam.enable = true;
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  # FHS Escape layer for loose mod managers, libraries, and binaries
  programs.nix-ld = {
    enable = true;
    libraries =  with pkgs; [
      zlib
      fuse3
      icu
      nss
      nspr
    ];
  };

  # Enable OpenRazer drivers and daemon support
  hardware.openrazer.enable = true;

  # Activating LACT Daemon for AMD GPU Control/Undervolting
  systemd.packages = [ pkgs.lact ];
  systemd.services.lactd.wantedBy = [ "multi-user.target" ];
  
  # Enable overdrive support for AMD GPUs
  boot.kernelParams = [ "amdgpu.freesync_video=1" "amdgpu.sg_display=0" "amdgpu.ppfeaturemask=0xffffffff" ];

  # Set specific module parameters
  boot.extraModprobeConfig = "options amdgpu dc=1";

  services.flatpak.enable = true;
  
  programs.nh = {
  enable = true;
  clean.enable = true;
  clean.extraArgs = "--keep-since 4d --keep 3";
  flake = "/etc/nixos"; # Points straight to your flake directory
  };

  # =========================================================================
  # 6. HARDWARE SYSTEM FONTS
  # =========================================================================
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    roboto
  ];

  # =========================================================================
  # 7. DECLARATIVE PACKAGES ENVIRONMENT
  # =========================================================================
  environment.systemPackages = with pkgs; [
    # Wayland Utils & Core CLI Tools
    git nano vim wget rsync bc jq cargo uv ripgrep eza kitty fastfetch chafa btop htop starship gum
    wl-clipboard grim slurp swappy wtype ydotool wlsunset cliphist
    libqalculate tesseract networkmanagerapplet pasystray pavucontrol brightnessctl ddcutil
    openrazer-daemon
    polychromatic 
    # noctalia-shell
    # wf-recorder

    # Cosmic Extensions
    cosmic-ext-applet-caffeine
    # cosmic-ext-applet-vitals
    # cosmic-applet-minimon
    # cosmic-ext-applet-gamemode-status

    # Security & Hacking Tools
    nmap wireshark ffuf gobuster hydra hashcat netcat

    # Apps & Media
    firefox fractal mpv playerctl gimp easyeffects mission-center
    smartmontools yt-dlp songrec lmstudio sillytavern legcord upscayl spotify freetube

    # Gaming Helpers & Utilities
    steam-run mangohud protontricks protonup-qt piper xwayland-satellite prismlauncher heroic lutris
    lact

    # Game Repos
    zeroad
  ];

  # Temporary Overlay (GNU Grep Check Phase Failure in Upstream Nix Unstable)
  nixpkgs.overlays = [
    (self: super: {
      gnugrep = super.gnugrep.overrideAttrs (_: { doCheck = false; doInstallCheck = false; });     
      buildPackages = super.buildPackages // {
        gnugrep = super.buildPackages.gnugrep.overrideAttrs (_: { doCheck = false; doInstallCheck = false; });
      };
    })
  ];

  # =========================================================================
  # 8. AUTOMATED HARD DRIVE STORAGE MOUNTS
  # =========================================================================
  fileSystems."/mnt/game-1" = {
    device = "/dev/disk/by-uuid/40813fc6-ffae-4c19-8655-6afe847d1817";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/game-3" = {
    device = "/dev/disk/by-uuid/d72ac9c3-dffb-4265-b8f7-0ad1b25ebe0f";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/game-2" = {
    device = "/dev/disk/by-uuid/3a04e374-1647-4edd-aa58-f1780af26d82";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/game-nvme" = {
    device = "/dev/disk/by-uuid/148e3bde-35f4-4a11-b36a-16f9b89a0e7c";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/windows" = {
    device = "/dev/disk/by-uuid/083C76E33C76CB68";
    fsType = "ntfs3";
    options = [ "nofail" "ro" "user" ];
  };

  system.stateVersion = "26.05";
}
