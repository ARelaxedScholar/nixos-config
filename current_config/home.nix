{ config, pkgs, ... }:

{

  # blue light filter
  gammastep = {
    enable = true;
    provider = "manual";
    latitude = 45.32;
    longitude = 77.88;
  };
}
