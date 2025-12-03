{ self, super }:
super
// {
  nixosModules = super.nixosModules // {
    grub = super.nixosModules.grub // {
      config = super.nixosModules.grub.config // {
        boot = super.nixosModules.grub.config.boot // {
          loader = super.nixosModules.grub.config.boot.loader // {
            grub = super.nixosModules.grub.config.boot.loader.grub // {
              bootDevice = null;
            };
          };
        };
      };
    };
  };
}
