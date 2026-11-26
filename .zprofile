
# >>> autologin-hyprland-keyring >>>
# Autologin na tty1: odblokuj keyring i uruchom Hyprland.
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ "$(tty 2>/dev/null)" = "/dev/tty1" ]; then
  export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$HOME/.bun/bin:$PATH"

  # getty czyści LANG/LC_*; przywróć locale z systemu.
  if [ -r /etc/locale.conf ]; then
    set -a
    . /etc/locale.conf
    set +a
  fi

  : "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
  export XDG_RUNTIME_DIR
  if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
  fi

  export XDG_SESSION_TYPE=wayland
  export XDG_CURRENT_DESKTOP=Hyprland
  export XDG_SESSION_DESKTOP=Hyprland
  export DESKTOP_SESSION=Hyprland
  : "${XDG_VTNR:=1}"
  export XDG_VTNR

  # Keyring: istniejący systemd user service jest Secret Service. Nie wolno
  # uruchamiać drugiego gnome-keyring-daemon (--start/--unlock tworzy duplikat).
  export GNOME_KEYRING_CONTROL="$XDG_RUNTIME_DIR/keyring"

  # keyring-secret.service powinien zdążyć przed getty; chwila zapasu.
  if [ ! -r /run/keyring.pass ]; then
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      [ -r /run/keyring.pass ] && break
      sleep 0.2
    done
  fi

  if [ -r /run/keyring.pass ]; then
    CONTROL="$GNOME_KEYRING_CONTROL/control"
    if [ ! -S "$CONTROL" ]; then
      systemctl --user start gnome-keyring-daemon.socket gnome-keyring-daemon.service >/dev/null 2>&1 || true
      for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
        [ -S "$CONTROL" ] && break
        sleep 0.1
      done
    fi

    if [ -S "$CONTROL" ]; then
      if timeout 15 gjs "$HOME/.local/bin/keyring-unlock-dbus" /run/keyring.pass >/dev/null 2>&1; then
        rm -f /run/keyring.pass
      else
        logger -t autologin-keyring "Nie udalo sie odblokowac keyringa; plik /run/keyring.pass pozostawiony"
      fi
    else
      logger -t autologin-keyring "Brak control socket keyringa; nie odblokowano"
    fi
  fi

  # Jeden autologin na boot. Po wylogowaniu/crashu getty da powłokę,
  # zamiast zapętlać Hyprland.
  MARKER=/run/hyprland-autologin/tried
  if [ ! -e "$MARKER" ]; then
    touch "$MARKER" 2>/dev/null || true
    exec /usr/bin/start-hyprland
  fi
fi
# <<< autologin-hyprland-keyring <<<
