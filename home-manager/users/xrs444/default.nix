{ pkgs, ... }: {

  home.packages = with pkgs; [
    # Add your user packages here
  ];
  
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "Thomas Letherby";
    userEmail = "xrs444@xrs444.net";
  };

}
