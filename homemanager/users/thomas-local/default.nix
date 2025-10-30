{ pkgs, ... }: {
  
  home.packages = with pkgs; [
    # Add your user packages here
  ];
  
  programs.home-manager.enable = true;
}
