{ config, pkgs, ... }:
{
  time = "2026-10-03T19:46:15+00:00";
  condition = true;
  message = ''
    A new module is available: 'programs.sshoot'.

    It manages sshuttle VPN sessions via the sshoot command-line tool,
    including 'programs.sshoot.sessions' for defining sessions and
    'programs.sshoot.settings' for sshoot's own global configuration.
  '';
}
