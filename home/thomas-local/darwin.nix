{ pkgs, ... }: {
  home.stateVersion = "24.11";
  
  home.packages = with pkgs; [
    # Add your user packages here
  ];
  
  programs.home-manager.enable = true;
}