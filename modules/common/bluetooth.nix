{ pkgs, config, lib, ... }:
{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  hardware.bluetooth.settings = {
    General = {
      MultiProfile = "multiple";
      FastConnectable = true;
      Experimental = true;
      KernelExperimental = "15c0a148-c273-11ea-b3de-0242ac130004";
    };
    LE = {
      ScanIntervalSuspend = 2240;
      ScanWindowSuspend = 224;
    };
  };
  services.blueman.enable = true;
}
