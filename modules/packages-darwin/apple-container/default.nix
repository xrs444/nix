{ pkgs, ... }:

{
  system.activationScripts.postActivation.text = ''
    # Apple Container .pkg auto-installer
    # Fetches and installs the latest release from github.com/apple/container
    CONTAINER_BIN="/usr/local/bin/container"
    GITHUB_API="https://api.github.com/repos/apple/container/releases/latest"
    PKG_NAME="container-installer-signed.pkg"
    TMP_DIR=$(mktemp -d)

    echo "Checking Apple Container installation..."

    # Get the latest release version from GitHub
    LATEST_VERSION=$(${pkgs.curl}/bin/curl -sL "$GITHUB_API" | ${pkgs.jq}/bin/jq -r '.tag_name')

    if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" = "null" ]; then
      echo "  Warning: Could not fetch latest Apple Container version from GitHub. Skipping."
      rm -rf "$TMP_DIR"
    else
      INSTALLED_VERSION=""
      if [ -x "$CONTAINER_BIN" ]; then
        INSTALLED_VERSION=$("$CONTAINER_BIN" --version 2>/dev/null | awk '{print $NF}' || true)
      fi

      if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
        echo "  Apple Container $INSTALLED_VERSION is already up to date."
      else
        if [ -n "$INSTALLED_VERSION" ]; then
          echo "  Updating Apple Container from $INSTALLED_VERSION to $LATEST_VERSION..."
          "$CONTAINER_BIN" system stop 2>/dev/null || true
          /usr/local/bin/uninstall-container.sh -k 2>/dev/null || true
        else
          echo "  Installing Apple Container $LATEST_VERSION..."
        fi

        DOWNLOAD_URL="https://github.com/apple/container/releases/download/$LATEST_VERSION/$PKG_NAME"
        echo "  Downloading $PKG_NAME..."
        ${pkgs.curl}/bin/curl -sL -o "$TMP_DIR/$PKG_NAME" "$DOWNLOAD_URL"

        echo "  Installing..."
        /usr/sbin/installer -pkg "$TMP_DIR/$PKG_NAME" -target / 2>&1 || {
          echo "  Error: Failed to install Apple Container .pkg"
          rm -rf "$TMP_DIR"
        }

        rm -rf "$TMP_DIR"
        echo "  Apple Container $LATEST_VERSION installed successfully."
      fi
    fi
  '';
}
