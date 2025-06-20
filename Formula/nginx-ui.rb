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
      EnableFileLog = false
      Dir =
      MaxSize = 0
      MaxAge = 0
      MaxBackups = 0
      Compress = false
  
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
  
      [openai]
      BaseUrl =
      Token =
      Proxy =
      Model =
      APIType = OPEN_AI
      EnableCodeCompletion = false
      CodeCompletionModel =
  
      [terminal]
      StartCmd = login
  
      [webauthn]
      RPDisplayName =
      RPID =
      RPOrigins =
    EOS
  
    config_file.write config_content
  end


  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>nginx-ui</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/nginx-ui</string>
          <string>--config</string>
          <string>#{etc}/nginxui/nginxui.ini</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>#{etc}</string>
        <key>StandardErrorPath</key>
        <string>#{var}/log/nginxui/nginxui.err.log</string>
        <key>StandardOutPath</key>
        <string>#{var}/log/nginxui/nginxui.out.log</string>
      </dict>
      </plist>
    EOS
  end

  service do
    run [
      opt_bin/"nginx-ui",
      "--config",
      etc/"nginxui/nginxui.ini"
    ]
    keep_alive true
    working_dir HOMEBREW_PREFIX
    log_path var/"log/nginxui/nginxui.log"
    error_log_path var/"log/nginxui/nginxui.err.log"
  end

  test do
    system "#{bin}/nginx-ui", "--version"
  end
end
