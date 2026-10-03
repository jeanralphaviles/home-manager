{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.sshoot;

  yamlFormat = pkgs.formats.yaml { };

  removeEmptyValues = lib.filterAttrs (_key: value: value != null && value != [ ]);

  sessionModule = lib.types.submodule {
    options = {
      remote = lib.mkOption {
        type = lib.types.str;
        example = "testuser@example.com";
        description = ''
          The remote hostname, and optional username and ssh port, to
          connect to for this session. Corresponds to sshuttle's
          `--remote` option; see
          <https://sshuttle.readthedocs.io/en/stable/manpage.html>
          for the exact syntax.
        '';
      };

      subnets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        example = [ "10.0.0.0/24" ];
        description = ''
          Subnets to route over the VPN for this session, e.g.
          `1.2.3.0/24`. Corresponds to sshuttle's positional `<subnets>`
          arguments; see
          <https://sshuttle.readthedocs.io/en/stable/manpage.html>
          for the exact syntax, including port ranges and hostnames.
        '';
      };

      autoHosts = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to scan for remote hostnames and update the local
          `/etc/hosts` file for as long as the session is open. Corresponds
          to sshuttle's `--auto-hosts` option.
        '';
      };

      autoNets = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to automatically route the subnets suggested by the
          remote server's routing table, in addition to {option}`subnets`.
          Corresponds to sshuttle's `--auto-nets` option.
        '';
      };

      dns = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to capture local DNS requests and resolve them on the
          remote side of the tunnel. Corresponds to sshuttle's `--dns`
          option.
        '';
      };

      excludeSubnets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "10.0.0.100/32" ];
        description = ''
          Subnets to explicitly exclude from forwarding, in the same
          format as {option}`subnets`. Corresponds to sshuttle's
          `--exclude` option.
        '';
      };

      seedHosts = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "host1.example.com"
          "host2.example.com"
        ];
        description = ''
          Hostnames to seed the {option}`autoHosts` scan with, to speed up
          hostname discovery. Corresponds to sshuttle's `--seed-hosts`
          option.
        '';
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra arguments to pass to `sshuttle` for this session.";
      };
    };
  };

  toSessionConfig =
    session:
    removeEmptyValues {
      inherit (session) remote subnets;
      "auto-hosts" = if session.autoHosts then true else null;
      "auto-nets" = if session.autoNets then true else null;
      "dns" = if session.dns then true else null;
      "exclude-subnets" = session.excludeSubnets;
      "seed-hosts" = session.seedHosts;
      "extra-opts" = session.extraArgs;
    };
in
{
  meta.maintainers = [ lib.maintainers.jeanralphaviles ];

  options.programs.sshoot = {
    enable = lib.mkEnableOption "sshoot, a command-line interface to manage sshuttle VPN sessions";

    package = lib.mkPackageOption pkgs "sshoot" { nullable = true; };

    settings = lib.mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = {
        executable = "sshuttle";
        "extra-options" = [ "--dns" ];
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/sshoot/config.yaml`.

        See the [sshoot documentation](https://github.com/albertodonato/sshoot)
        for the full list of available settings (`executable`, `extra-options`).
      '';
    };

    sessions = lib.mkOption {
      type = lib.types.attrsOf sessionModule;
      default = { };
      example = lib.literalExpression ''
        {
          work = {
            remote = "user@work.example.com";
            subnets = [ "10.0.0.0/24" ];
            autoHosts = true;
          };
        }
      '';
      description = ''
        VPN sessions managed by sshoot, written to
        {file}`$XDG_CONFIG_HOME/sshoot/profiles.yaml`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."sshoot/config.yaml" = lib.mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "sshoot-config.yaml" cfg.settings;
    };

    xdg.configFile."sshoot/profiles.yaml" = lib.mkIf (cfg.sessions != { }) {
      source = yamlFormat.generate "sshoot-profiles.yaml" (
        lib.mapAttrs (_name: toSessionConfig) cfg.sessions
      );
    };
  };
}
