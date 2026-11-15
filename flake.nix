{
  description = "Home Manager configuration of data";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      #system = "aarch64-darwin";
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      darwinConfigurations."data-juliad" = nix-darwin.lib.darwinSystem {
        # darwinSystem only accepts: modules, specialArgs, system, pkgs, inputs.
        # Home Manager options belong inside a module, not here.
        modules = [
          home-manager.darwinModules.home-manager
          (
            { pkgs, ... }:
            {
              nixpkgs.hostPlatform = "aarch64-darwin";
              nix.enable = false; # we are using Determinate Nix
              system.primaryUser = "data";
              system.stateVersion = 7;

              users.users.data.home = "/Users/data";

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit pkgsUnstable; };
                users.data =
                  { pkgs, ... }:
                  let
                    unstable = import pkgsUnstable {
                      inherit (pkgs.stdenv.hostPlatform) system;
                      config.allowUnfree = true;
                    };
                  in
                  {
                    imports = [ ./common.nix ];

                    home.packages = with pkgs; [
                      usbutils
                      #iotop -- no iotop for darwin
                      openfpgaloader
                      unstable.cue
                    ];

                    # Home Manager is pretty good at managing dotfiles. The primary way to manage
                    # plain files is through 'home.file'.
                    #home.file = {
                    #  ".screenrc".source = dotfiles/screenrc;
                    #};

                    #home.sessionVariables = {
                    #  EDITOR = "vim";
                    #};

                    # Let Home Manager install and manage itself.
                    programs.home-manager.enable = true;
                  };
              };
            }
          )
        ];
      };

      #homeConfigurations."data-bingen" = home-manager.lib.homeManagerConfiguration {
      #  inherit pkgs;
      #
      #  # Specify your home configuration modules here, for example,
      #  # the path to your home.nix.
      #  modules = [ ./data-bingen.nix ];
      #
      #  # Optionally use extraSpecialArgs
      #  # to pass through arguments to home.nix
      #};

      nixosConfigurations."data-bingen" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # or aarch64-linux
      specialArgs = { inherit pkgsUnstable; };
      modules = [
        ./hosts/bingen/configuration.nix   # your existing /etc/nixos/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit pkgsUnstable; };
            users.data = {
              imports = [ ./common.nix ./data-bingen.nix ];
            };
          };
        }
      ];
    };
}
