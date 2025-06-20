class NginxUiRootHelper < Formula
  desc "Helper to install nginx-ui as a root service using launchd (with warning)"
  homepage "https://github.com/bredecl/homebrew-nginxui"
  url "https://example.com/fake-source.tar.gz" # No source needed
  version "1.0.0"
  sha256 "d41d8cd98f00b204e9800998ecf8427e" # dummy checksum for empty archive

  def install
    (bin/"nginx-ui-root-setup").write <<~SH
      #!/bin/bash
      set -e

      PLIST_PATH="/Library/LaunchDaemons/cl.brede.nginxui.plist"
      CONFIG_PATH="/opt/homebrew/etc/nginxui/nginxui.ini"
      LOG_DIR="/opt/homebrew/var/log/nginxui"
      BIN_PATH="/opt/homebrew/bin/nginx-ui"

      echo "Creating plist at $PLIST_PATH..."

      sudo tee "$PLIST_PATH" > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>cl.brede.nginxui</string>
  <key>ProgramArguments</key>
  <array>
    <string>#{BIN_PATH}</string>
    <string>--config</string>
    <string>#{CONFIG_PATH}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>WorkingDirectory</key>
  <string>/opt/homebrew/etc/nginxui</string>
  <key>StandardOutPath</key>
  <string>#{LOG_DIR}/nginxui.out.log</string>
  <key>StandardErrorPath</key>
  <string>#{LOG_DIR}/nginxui.err.log</string>
</dict>
</plist>
EOF

      echo "Fixing permissions..."
      sudo chown root:wheel "$PLIST_PATH"
      sudo chmod 644 "$PLIST_PATH"

      echo "Bootstrapping root service..."
      sudo launchctl bootstrap system "$PLIST_PATH"
      sudo launchctl enable system/cl.brede.nginxui
      echo "nginx-ui root service installed and started."
    SH

    chmod 0755, bin/"nginx-ui-root-setup"
  end

  def caveats
    <<~EOS
      ⚠️  This script configures nginx-ui to run as root using launchd.

      - Use only if you need root-level access for nginx configuration tasks.
      - Not recommended for general use — running services as root can be risky.
      - To install and start the root service:
          sudo #{bin}/nginx-ui-root-setup

      To stop the service:
          sudo launchctl bootout system /Library/LaunchDaemons/cl.brede.nginxui.plist
    EOS
  end

  test do
    assert_predicate bin/"nginx-ui-root-setup", :exist?
  end
end
