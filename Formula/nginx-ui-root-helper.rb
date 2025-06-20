class NginxUiRootHelper < Formula
  desc "Helper to install nginx-ui as a root launchd service"
  homepage "https://github.com/bredecl/homebrew-nginxui"
  version "1.0.0"

  # No URL needed — this is a meta formula
  disable! date: "2025-01-01", because: "used as a local-only installer script"

  def install
    (bin/"nginx-ui-root-setup").write <<~SH
      #!/bin/bash
      set -euo pipefail

      PLIST_PATH="/Library/LaunchDaemons/cl.brede.nginxui.plist"
      CONFIG_PATH="/opt/homebrew/etc/nginxui/nginxui.ini"
      LOG_DIR="/opt/homebrew/var/log/nginxui"
      BIN_PATH="/opt/homebrew/bin/nginx-ui"

      if [ ! -f "$CONFIG_PATH" ]; then
        echo "Error: Config file not found at $CONFIG_PATH"
        echo "Please run: brew reinstall bredecl/nginxui/nginx-ui"
        exit 1
      fi

      sudo mkdir -p "$LOG_DIR"

      echo "Creating launchd plist at $PLIST_PATH..."

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
  <string>/opt/homebrew</string>
  <key>StandardOutPath</key>
  <string>#{LOG_DIR}/nginxui.out.log</string>
  <key>StandardErrorPath</key>
  <string>#{LOG_DIR}/nginxui.err.log</string>
</dict>
</plist>
EOF

      echo "Setting permissions..."
      sudo chown root:wheel "$PLIST_PATH"
      sudo chmod 644 "$PLIST_PATH"

      echo "Starting root-level nginx-ui service..."
      sudo launchctl bootstrap system "$PLIST_PATH"
      sudo launchctl enable system/cl.brede.nginxui
      echo "✅ nginx-ui is now running as root."
    SH

    chmod 0755, bin/"nginx-ui-root-setup"
  end

  def caveats
    <<~EOS
      ⚠️ This script configures nginx-ui as a *root* service using launchd.

      Only use it if nginx-ui needs root access for configuration validation or management.

      To start the service as root:
        sudo nginx-ui-root-setup

      To stop the service:
        sudo launchctl bootout system /Library/LaunchDaemons/cl.brede.nginxui.plist

      Be cautious with any services running as root.
    EOS
  end

  test do
    assert_predicate bin/"nginx-ui-root-setup", :exist?
  end
end
