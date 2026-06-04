{ pkgs, ... }:
{
  systemd.user.targets.mode-llm = {
    Unit.Description = "LLM / AI work mode";
  };

  # Add your LLM-mode autostart services here.
  # Each service should have:
  #   PartOf = [ "mode-llm.target" ]
  #   Install.WantedBy = [ "mode-llm.target" ]
  #
  # Example — open a terminal on startup:
  # systemd.user.services.llm-terminal = {
  #   Unit = {
  #     Description = "LLM mode terminal";
  #     After = [ "graphical-session.target" ];
  #     PartOf = [ "mode-llm.target" ];
  #   };
  #   Service = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.foot}/bin/foot";
  #   };
  #   Install.WantedBy = [ "mode-llm.target" ];
  # };
}
