{ pkgs, ... }: {

  home.username = "xrs444";
  home.homeDirectory = "/home/xrs444";
  
  home.packages = with pkgs; [
    # Add your user packages here
  ];
  
  programs.home-manager.enable = true;
}
