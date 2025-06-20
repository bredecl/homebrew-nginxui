require "securerandom"

class NginxUi < Formula
  desc "Web UI for managing nginx configuration"
  homepage "https://github.com/bredecl/homebrew-nginxui"
  url "https://github.com/0xJacky/nginx-ui/releases/download/v2.1.6/nginx-ui-macos-arm64-v8a.tar.gz"
  sha256 "326147df53ebe11973d82b8d540159141a75b9f40bcdcfaf8151fba63c9d68d5"
  license "MIT"

  depends_on :macos

  def install
    bin.install "nginx-ui"
    (etc/"nginxui").install "app.ini" unless (etc/"nginxui/app.ini").exist?
  end

  def post_install
    (etc/"nginxui").mkpath
    (var/"log/nginxui").mkpath
  
    config_file = etc/"nginxui/app.ini"
  
    unless config_file.exist?
      cp "app.ini", config_file
    end
  
    crypto_secret = SecureRandom.hex(32)
    node_secret = `uuidgen`.chomp
  
    text = File.read(config_file)
  
    # Reemplaza el Secret en la sección [crypto]
    text.gsub!(/(\[crypto\](?:.*\n)*?Secret\s*=\s*).*/, "\\1#{crypto_secret}")
  
    # Reemplaza el Secret en la sección [node]
    text.gsub!(/(\[node\](?:.*\n)*?Secret\s*=\s*).*/, "\\1#{node_secret}")
  
    File.write(config_file, text)
  end

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>cl.brede.nginxui</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/nginx-ui</string>
          <string>--config</string>
          <string>#{etc}/nginxui/app.ini</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>WorkingDirectory</key>
        <string>#{etc}</string>
        <key>StandardErrorPath</key>
        <string>/var/log/nginxui.err.log</string>
        <key>StandardOutPath</key>
        <string>/var/log/nginxui.out.log</string>
      </dict>
      </plist>
    EOS
  end

  service do
    run [
      opt_bin/"nginx-ui",
      "--config",
      etc/"nginxui/app.ini"
    ]
    keep_alive true
    working_dir HOMEBREW_PREFIX
    log_path var/"log/nginxui.log"
    error_log_path var/"log/nginxui.err.log"
  end

  test do
    system "#{bin}/nginx-ui", "--version"
  end
end
