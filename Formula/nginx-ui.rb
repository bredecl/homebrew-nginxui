class NginxUi < Formula
  desc "Web UI for managing nginx configuration"
  homepage "https://github.com/bredecl/homebrew-nginxui"
  url "https://github.com/0xJacky/nginx-ui/releases/download/v2.1.6/nginx-ui-macos-arm64-v8a.tar.gz"
  sha256 "326147df53ebe11973d82b8d540159141a75b9f40bcdcfaf8151fba63c9d68d5"
  license "MIT"

  depends_on :macos

  def install
    bin.install "nginx-ui"
  end

  def post_install
    require "securerandom"

    (etc/"nginxui").mkpath
    (var/"log/nginxui").mkpath

    config_file = etc/"nginxui/nginxui.ini"
    return if config_file.exist?

    secret_crypto = SecureRandom.hex(32)
    secret_node = SecureRandom.uuid

    config_content = <<~EOS
      [app]
      PageSize = 20
      JwtSecret =

      [server]
      Host =
      Port = 9000
      RunMode = debug
      BaseUrl =
      EnableHTTPS = false
      SSLCert =
      SSLKey =

      [database]
      Name = database

      [log]
      EnableFileLog = true
      Dir = #{var}/log/nginxui
      MaxSize = 10
      MaxAge = 7
      MaxBackups = 5
      Compress = true

      [auth]
      IPWhiteList =
      BanThresholdMinutes = 10
      MaxAttempts = 10

      [backup]
      GrantedAccessPath =

      [crypto]
      Secret = #{secret_crypto}

      [node]
      Name =
      Secret = #{secret_node}

      [nginx]
      ConfigDir = /opt/homebrew/etc/nginx
      ConfigPath = /opt/homebrew/etc/nginx/nginx.conf
      PIDPath = /opt/homebrew/var/run/nginx.pid
      AccessLogPath = /opt/homebrew/var/log/nginx/access.log
      ErrorLogPath = /opt/homebrew/var/log/nginx/error.log
      ReloadCmd = brew services restart nginx
      TestConfigCmd = nginx -t

      [terminal]
      StartCmd = login
    EOS

    config_file.write config_content

    # Wrapper para ejecutar con config
    wrapper = bin/"nginx-ui-wrapper"
    wrapper.write <<~SH
      #!/bin/bash
      CONFIG_PATH="#{etc}/nginxui/nginxui.ini"
      if [[ ! -f "$CONFIG_PATH" ]]; then
        echo "Config file not found at $CONFIG_PATH"
        exit 1
      fi
      exec "#{opt_bin}/nginx-ui" --config "$CONFIG_PATH"
    SH
    wrapper.chmod 0755
  end

  service do
    run [opt_bin/"nginx-ui-wrapper"]
    keep_alive true
    working_dir HOMEBREW_PREFIX
    log_path var/"log/nginxui/nginxui.log"
    error_log_path var/"log/nginxui/nginxui.err.log"
  end

  test do
    system "#{bin}/nginx-ui", "--version"
  end
end
