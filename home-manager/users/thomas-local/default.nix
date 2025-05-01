{ pkgs, ... }: {

  home.username = "thomas-local";
  home.homeDirectory = "/home/thomas-local";
  
  home.stateVersion = "24.11";
  
  home.packages = with pkgs; [
    # Add your user packages here
  ];
  
  programs.home-manager.enable = true;
}
