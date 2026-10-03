{
  programs.sshoot = {
    enable = true;

    settings = {
      executable = "sshuttle";
      "extra-options" = [ "--dns" ];
    };

    sessions = {
      work = {
        remote = "user@work.example.com";
        subnets = [ "10.0.0.0/24" ];
        autoHosts = true;
      };

      home = {
        remote = "user@home.example.com";
        subnets = [
          "192.168.1.0/24"
          "192.168.2.0/24"
        ];
        excludeSubnets = [ "192.168.1.100/32" ];
        seedHosts = [ "host1.example.com" ];
        extraArgs = [ "--verbose" ];
      };
    };
  };

  test.stubs.sshoot = { };

  nmt.script = ''
    assertFileExists home-files/.config/sshoot/config.yaml
    assertFileContent home-files/.config/sshoot/config.yaml \
      ${./config.yml}

    assertFileExists home-files/.config/sshoot/profiles.yaml
    assertFileContent home-files/.config/sshoot/profiles.yaml \
      ${./profiles.yml}
  '';
}
