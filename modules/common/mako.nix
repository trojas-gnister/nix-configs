{ config, pkgs, lib, ... }:

{
  home-manager.users.${config.variables.user.name} = { ... }: {
    services.mako = {
      enable = true;
      backgroundColor = "#282a36";
      textColor = "#f8f8f2";
      borderColor = "#6272a4";
      progressColor = "#bd93f9";
      borderRadius = 5;
      borderSize = 2;
      font = "JetBrainsMono Nerd Font 10";
      defaultTimeout = 5000;
      padding = "10";
      margin = "10";
      icons = true;
      maxVisible = 5;
    };
  };
}
