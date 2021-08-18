let
  pkgs = import (import ./nixpkgs.nix) { };
  lib = pkgs.lib;

  inherit (pkgs.callPackage ./resources.nix { }) resources resourcesByRole;
  inherit (import ./utils.nix) nodeIP;

  etcdHosts = map (r: r.values.name) (resourcesByRole "etcd");
  controlPlaneHosts = map (r: r.values.name) (resourcesByRole "controlplane");

  etcdConf = { ... }: {
    imports = [ ./modules/etcd.nix ];
    deployment.tags = [ "etcd" ];
  };

  controlPlaneConf = { ... }: {
    imports = [ ./modules/controlplane ];
    deployment.tags = [ "controlplane" ];
  };
in
{
  meta = {
    nixpkgs = import (import ./nixpkgs.nix);
  };

  defaults = { name, self, ... }: {
    imports = [
      ./modules/autoresources.nix
      ./modules/base.nix
    ];

    deployment.targetHost = nodeIP self;
    networking.hostName = name;
  };
}
// builtins.listToAttrs (map (h: { name = h; value = etcdConf; }) etcdHosts)
  // builtins.listToAttrs (map (h: { name = h; value = controlPlaneConf; }) controlPlaneHosts)
