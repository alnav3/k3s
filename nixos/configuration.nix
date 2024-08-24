{ config, lib, pkgs, meta, ... }:

{

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # allow unfree for nvidia drivers
  nixpkgs.config.allowUnfree = true;

  # enable docker
  virtualisation.docker.enable = true;

  # NVIDIA configuration
  hardware.opengl.enable = lib.mkIf (meta.hostname == "homelab-0") true;
  services.xserver.videoDrivers = lib.mkIf (meta.hostname == "homelab-0") [ "nvidia" ];
  hardware.nvidia = lib.mkIf (meta.hostname == "homelab-0") {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  fileSystems = lib.mkIf (config.networking.hostName == "homelab-0") {
    "/media/HDD1" = {
      device = "/dev/disk/by-uuid/81297f75-d3cb-4f83-b856-52557dff1131";
      fsType = "ext4";  # Replace with the actual filesystem type
      options = [ "defaults" ];
    };

    "/media/Jellyfin" = {
      device = "/dev/disk/by-uuid/0affb6bd-11dc-4d98-827c-0ac175d73bc5";
      fsType = "ext4";  # Replace with the actual filesystem type
      options = [ "defaults" ];
    };
  };

  # Networking configuration
  networking = {
    hostName = meta.hostname;
    networkmanager.enable = true;

    useDHCP = false;

    interfaces.eth0.ipv4.addresses = [{
      address = if meta.hostname == "homelab-0" then "10.71.71.60"
                else if meta.hostname == "homelab-1" then "10.71.71.61"
                else "10.71.71.62";
      prefixLength = 24;
    }];

    defaultGateway = "10.71.71.1";
    nameservers = [ "9.9.9.9" "1.1.1.1" ];

    firewall.enable = false;
  };

  # Set your time zone.
  time.timeZone = "Europe/Madrid";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
    #useXkbConfig = true; # use xkb.options in tty.
  };

  # Fixes for longhorn
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
  #virtualisation.docker.logDriver = "json-file";


  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = /var/lib/rancher/k3s/server/token;
    extraFlags = toString ([
	    "--write-kubeconfig-mode \"0644\""
	    "--cluster-init"
	    "--disable servicelb"
	    "--disable traefik"
	    "--disable local-storage"
	    "--docker"
    ] ++ (if meta.hostname == "homelab-0" then [] else [
	      "--server https://10.71.71.60:6443"
    ]));
    clusterInit = (meta.hostname == "homelab-0");
  };

  services.openiscsi = {
    enable = true;
    name = "iqn.2016-04.com.open-iscsi:${meta.hostname}";
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.alnav = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ]; # Enable ‘sudo’ for the user.
    # Created using mkpasswd
    hashedPassword = "$6$Ld6VVI/GPx3tS3HO$pAjCdjWroN88QoCPCER7UdXq1XTbC1C8linCar7/ykEsgtya4JesK1ILX5ffoRqgMkTR/NPN10NfYsvI2yHzE.";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC2PZ42g+dR8d/Qroi9ShxEvrvv5hEuTQaiqmcBrpT0O2TsMulIf6KAAID4gDEE7uzjPp/yu5SvNpoMYZEbM/SDnnGDE3c1OmfvvuWtkl/sDiT5laXsYlm58S5tXf48gxmIeXiXx0SD/ZuNjQCBzwjjLVqOdyl0vniw05u1J2kv4dy3Dk1bcs0VlxG09FyNQjogE7rE2MsbzQVf1+jMUjyFe24nRK2xn4JPGlfP7q6wXcTrYAolYzmAWh1bnnLlA8xGY8bk3QVMgmUAtajyYbwYaAxI1lBPUkFmz7T5re9BeBsPlKa/rGp7UJokIfs1NYKfsI2ekWRhpIrO7Clv/+s4xGEqO2pnVo658ut8243sAWa8WsVVHNB0Eem49+XWaxvOndjTBkz7wNMEf+L76h7rePRHnti1J3liROkJJP4k7T4ls44lK8acLRwbSGnaxk4189Ivh7LakbjZrZuFqP7tcXqVVTBimYvymcZSq9K9Ivi3cFe91ZamjZdNTjtUjo9TJlMc/+WMcrjVOMymCsQBzzoHLuRg/A4ePKud+BpcHZF1w8XRoy583JrWiy+t3XTGUX56mScpvoXn/VAnx+nVb0ifbZQ7mY8P7apuxhDcu/aNQdDmmkWvno6xh6ufc5P8U/BlY+QpUkZ2K5v69pyAV8/lJbTKFNt/WKTNERsdyQ== alexnavia3@MacBook-Air.local"
    ];
  };

  security.sudo.extraRules = [
    { users = [ "alnav" ];
       commands = [
         { command = "ALL" ;
             options= [ "NOPASSWD" ];
         }
       ];
    }
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     neovim
     k3s
     cifs-utils
     nfs-utils
     git
  ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;


  system.stateVersion = "23.11";

}
