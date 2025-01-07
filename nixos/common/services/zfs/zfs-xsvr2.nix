_: {
  networking.hostId = "8f9996ca";
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
