self: super: {
  lazyssh = super.buildGoModule {
    pname = "lazyssh";
    version = "main"; # Or use a release/tag

    src = super.fetchFromGitHub {
      owner = "Adembc";
      repo = "lazyssh";
      rev = "main"; # Or a specific commit or tag
      # Run `nix flake update` or build once to get the correct sha256!
      sha256 = "0000000000000000000000000000000000000000000000000000"; 
    };

    # If lazyssh has submodules: fetchSubmodules = true;

    vendorSha256 = "0000000000000000000000000000000000000000000000000000"; # fill after first build

    meta = with super.lib; {
      description = "Simple SSH automation tool";
      homepage = "https://github.com/Adembc/lazyssh";
      license = licenses.mit;
      platforms = platforms.unix;
      maintainers = [ ];
    };
  };
}
