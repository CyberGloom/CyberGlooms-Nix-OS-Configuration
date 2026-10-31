{ config, pkgs, inputs, lib, ... }: {

  imports = [ ./hardware-configuration.nix ];
  system.nixos.label = "Chaotic-Nyx";

  # =========================================================================
  # 1. BINARY CACHE / SUBSTITUTERS
  # =========================================================================
  nix.settings = {
    substituters = [ "https://cache.nixos.org" ];
    trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    experimental-features = [ "nix-command" "flakes" ];
    max-jobs = "auto";
    cores = 0;
    auto-optimise-store = true;
    builders-use-substitutes = true;
  };

  # =========================================================================
  # 2. CORE SYSTEM & HARDWARE
  # =========================================================================
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
      backdrop = "0d0914";
    };
    extraConfig = ''
      BACKGROUND_COLOR: 0d0914
      MARGIN: 0
      VERBOSE: no
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

  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  hardware.cpu.intel.updateMicrocode = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.fprintd.enable = true;
  services.geoclue2.enable = true;

  services.hardware.openrgb.enable = true;
  services.ratbagd.enable = true;

  services.udev.extraRules = ''
  SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0b05", MODE="0666", TAG+="uaccess"
  '';

  networking.firewall.allowedTCPPorts = [ 8000 ];

  services.quassel.enable = true;
  services.quassel.interfaces = [ "127.0.0.1" ];

  # =========================================================================
  # 3. THE DESKTOP ENVIRONMENTS (KDE Added, COSMIC Active)
  # =========================================================================

  # Enable KDE Plasma 6 & SDDM Wayland Greeter alongside COSMIC for safe migration
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    PROTON_USE_WAYLAND = "1";
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Low-latency KWin configs, Klassy window rules, Krohnkite, and shortcuts
  environment.etc = {
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

      [Windows]
      BorderlessMaximizedWindows=true

      [org.kde.kdecoration2]
      theme=__aurorae__svg__klassy
    '';

    "xdg/baloofilerc".text = ''
      [Basic Settings]
      Indexing-Enabled=false
    '';

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

    "xdg/autostart/enable-krohnkite.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Enable Krohnkite
      Exec=qdbus org.kde.KWin /KWin org.kde.KWin.reconfigure
      OnlyShowIn=KDE;
    '';
  };

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

  programs.nix-ld = {
    enable = true;
    libraries =  with pkgs; [ zlib fuse3 icu nss nspr ];
  };

  systemd.packages = [ pkgs.lact ];
  systemd.services.lactd.wantedBy = [ "multi-user.target" ];

  boot.kernelParams = [ "amdgpu.freesync_video=1" "amdgpu.sg_display=0" "amdgpu.ppfeaturemask=0xffffffff" ];
  boot.extraModprobeConfig = "options amdgpu dc=1";

  services.flatpak.enable = true;

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/etc/nixos";
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
    git nano vim wget rsync bc jq cargo uv ripgrep eza kitty fastfetch chafa btop htop starship gum
    wl-clipboard grim slurp swappy wtype ydotool wlsunset cliphist quasselClient openssl
    libqalculate tesseract networkmanagerapplet pavucontrol brightnessctl ddcutil

    klassy
    kdePackages.krohnkite
    kdePackages.plasma-integration

    nmap wireshark ffuf gobuster hashcat netcat sbctl

    firefox fractal mpv playerctl gimp mission-center qbittorrent
    smartmontools yt-dlp songrec lmstudio sillytavern legcord upscayl spotify freetube

    steam-run mangohud protontricks protonup-qt piper xwayland-satellite prismlauncher heroic lutris
    xemu dolphin-emu lact

    zeroad
  ];

  # =========================================================================
  # 9. AUTOMATED HARD DRIVE STORAGE MOUNTS
  # =========================================================================
  fileSystems."/mnt/game-1" = { device = "/dev/disk/by-uuid/40813fc6-ffae-4c19-8655-6afe847d1817"; fsType = "ext4"; options = [ "nofail" ]; };
  fileSystems."/mnt/game-3" = { device = "/dev/disk/by-uuid/d72ac9c3-dffb-4265-b8f7-0ad1b25ebe0f"; fsType = "ext4"; options = [ "nofail" ]; };
  fileSystems."/mnt/game-2" = { device = "/dev/disk/by-uuid/3a04e374-1647-4edd-aa58-f1780af26d82"; fsType = "ext4"; options = [ "nofail" ]; };
  fileSystems."/mnt/game-nvme" = { device = "/dev/disk/by-uuid/148e3bde-35f4-4a11-b36a-16f9b89a0e7c"; fsType = "ext4"; options = [ "nofail" ]; };
  fileSystems."/mnt/windows" = { device = "/dev/disk/by-uuid/083C76E33C76CB68"; fsType = "ntfs3"; options = [ "nofail" "ro" "user" ]; };

  system.stateVersion = "26.05";
}
