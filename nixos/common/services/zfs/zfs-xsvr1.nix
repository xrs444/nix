_: {
  networking.hostId = "0814bb9a";
  services.sanoid = {
    enable = true;
    datasets = {
      "zroot/persist" = {
         hourly = 50;
         daily = 15;
         weekly = 3;
         monthly = 1;
        };
    };
  };
}
