# Summary: Orange Pi WiFi firmware package for uwe5622 wireless module
{
  lib,
  stdenvNoCC,
  fetchgit,
}:

stdenvNoCC.mkDerivation {
  pname = "orangepi-firmware";
  version = "unstable-2023-07-11";

  src = fetchgit {
    url = "https://github.com/orangepi-xunlong/firmware.git";
    rev = "b2809d6c7a79ab874a91b84b9b0d9169cb41a749";
    hash = "sha256-cLSkfm25st6lyV/PJtUMM+Wu2r0IfLmVDGAYzafcC2Q=";
  };

  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/firmware
    cp -r . $out/lib/firmware/
    runHook postInstall
  '';

  meta = with lib; {
    description = "Firmware for Orange Pi boards (uwe5622 WiFi module)";
    homepage = "https://github.com/orangepi-xunlong/firmware";
    license = licenses.unfreeRedistributable;
    platforms = [ "aarch64-linux" ];
  };
}
