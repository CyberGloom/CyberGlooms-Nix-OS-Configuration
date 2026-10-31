{ config, pkgs, inputs, lib, ... }: {

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
  
  #Limine
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.limine = {
    enable = true;
    secureBoot.enable = true;
    maxGenerations = 10;

    style = {
      interface = {
        branding = "CYBERGLOOM // SPECTRA";
        resolution = "2560x1440";
        helpHidden = true;
      };

      backdrop = "0d0914"; # Pure dark purple hex
    };

    # Direct Limine overrides to clear margins, hide default banner, and style UI
    extraConfig = ''
      # Remove gray margins and force solid dark purple background everywhere
      BACKGROUND_COLOR: 0d0914
      MARGIN: 0
      
      # Hide top status/logo header entirely
      VERBOSE: no

      # Theme colors
      TEXT_COLOR: c5b4e3
      HIGHLIGHT_COLOR: ff2a8d
    '';

    extraEntries = ''
      /Windows Boot Manager
      protocol: efi
      path: guid(8ed770bd-a97e-49cc-8fc6-dbf6fc8aede9):/EFI/Microsoft/Boot/bootmgfw.efi
    '';
  };
  
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
  services.geoclue2.enable = true;

  # Peripheral Hardware Daemons
  services.hardware.openrgb.enable = true;
  services.ratbagd.enable = true;

  # udev services
  services.udev.extraRules = ''
  SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0b05", MODE="0666", TAG+="uaccess"
  '';

  # Open port 8000 in the NixOS firewall so your phone can reach it
  networking.firewall.allowedTCPPorts = [ 8000 ];

  #Quassel Core
  services.quassel.enable = true;
  services.quassel.interfaces = [ "127.0.0.1" ];

  # =========================================================================
  # 3. THE DESKTOP ENVIRONMENT (KDE PLASMA 6)
  # =========================================================================
  
  # Enable KDE Plasma 6 & SDDM Wayland Greeter
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

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

  # Declarative Low-Latency & Tiling Defaults via /etc/xdg
  environment.etc = {
    # KWin Latency, Performance, Animation Speed (0 = Instant), & Krohnkite Tiling
    "xdg/kwinrc".text = ''
      [Compositing]
      AllowTearing=true
      AnimationSpeed=0
      LatencyPolicy=ExtremelyLow

      [Plugins]
      blurEnabled=false
      contrastEnabled=false
      krohnkiteEnabled=true
      slidingpopupsEnabled=false
      startupfeedbackEnabled=false
    '';

    # Disable Baloo File Indexing to free up background CPU cycles
    "xdg/baloofilerc".text = ''
      [Basic Settings]
      Indexing-Enabled=false
    '';

    # Custom Tiling Shortcuts (Super + H/J/K/L & Super + Return)
    "xdg/kglobalshortcutsrc".text = ''
      [kwin]
      Window Focus Down=Meta+J,none,Switch to Window Below
      Window Focus Left=Meta+H,none,Switch to Window Left
      Window Focus Right=Meta+L,none,Switch to Window Right
      Window Focus Up=Meta+K,none,Switch to Window Above
      Window Move Down=Meta+Shift+J,none,Move Window Down
      Window Move Left=Meta+Shift+H,none,Move Window Left
      Window Move Right=Meta+Shift+L,none,Move Window Right
      Window Move Up=Meta+Shift+K,none,Move Window Up
      Window Close=Meta+Q,none,Close Window
      Toggle Floating=Meta+Shift+Space,none,Toggle Window Floating

      Switch to Desktop 1=Meta+1,none,Switch to Desktop 1
      Switch to Desktop 2=Meta+2,none,Switch to Desktop 2
      Switch to Desktop 3=Meta+3,none,Switch to Desktop 3
      Switch to Desktop 4=Meta+4,none,Switch to Desktop 4

      Window to Desktop 1=Meta+Shift+1,none,Window to Desktop 1
      Window to Desktop 2=Meta+Shift+2,none,Window to Desktop 2
      Window to Desktop 3=Meta+Shift+3,none,Window to Desktop 3
      Window to Desktop 4=Meta+Shift+4,none,Window to Desktop 4

      [org.kde.kitty.desktop]
      _launch=Meta+Return,none,Launch Kitty
    '';
  };

  # Autostart trigger to make sure KWin initializes Krohnkite immediately on login
  environment.etc."xdg/autostart/enable-krohnkite.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Enable Krohnkite
    Exec=qdbus org.kde.KWin /KWin org.kde.KWin.reconfigure
    OnlyShowIn=KDE;
  '';

  # =========================================================================
  # 4. SHELLS, ENVIRONMENT, & USER ACCOUNT
  # =========================================================================
  programs.fish.enable = true;
  nixpkgs.config.allowUnfree = true;

  users.users.kittie = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
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
    wl-clipboard grim slurp swappy wtype ydotool wlsunset cliphist quasselClient openssl
    libqalculate tesseract networkmanagerapplet pavucontrol brightnessctl ddcutil

    # KDE Tiling Extension
    kdePackages.krohnkite
    kdePackages.plasma-integration

    # Security & Hacking Tools
    nmap wireshark ffuf gobuster hashcat netcat sbctl

    # Apps & Media
    firefox fractal mpv playerctl gimp mission-center qbittorrent
    smartmontools yt-dlp songrec lmstudio sillytavern legcord upscayl spotify freetube

    # Gaming Helpers & Utilities
    steam-run mangohud protontricks protonup-qt piper xwayland-satellite prismlauncher heroic lutris
    xemu dolphin-emu lact

    # Game Repos
    zeroad
  ];

  # =========================================================================
  # 9. AUTOMATED HARD DRIVE STORAGE MOUNTS
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