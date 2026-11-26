
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
  # Duplikat pochodził z aktywacji D-Bus (org.freedesktop.secrets.service
  # spawnował własnego demona równolegle z socketem) — przykryte przez
  # ~/.local/share/dbus-1/services/org.freedesktop.secrets.service
  # (SystemdService=gnome-keyring-daemon.service).
  export GNOME_KEYRING_CONTROL="$XDG_RUNTIME_DIR/keyring"
  ALOGIN_LOG="$HOME/.local/state/autologin-keyring.log"
  mkdir -p "$HOME/.local/state" 2>/dev/null || true

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

    # Socket istnieje wcześniej niż własność nazwy na busie. gjs łączący się
    # za wcześnie powodował spawn drugiego demona przez D-Bus — czekamy na nazwę.
    if [ -S "$CONTROL" ]; then
      for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
        busctl --user --no-pager list 2>/dev/null | grep -q 'org\.freedesktop\.secrets' && break
        sleep 0.1
      done
    fi

    if [ -S "$CONTROL" ]; then
      if timeout 15 gjs "$HOME/.local/bin/keyring-unlock-dbus" /run/keyring.pass >>"$ALOGIN_LOG" 2>&1; then
        printf '%s unlock OK, czyszcze /run/keyring.pass\n' "$(date '+%F %T')" >>"$ALOGIN_LOG" 2>&1 || true
        # /run jest root-owned: unlink jako user się nie uda, ale truncate
        # (prawo do pliku 0600 lukasz) kasuje hasło. Unlink dla porządku.
        : > /run/keyring.pass 2>/dev/null || true
        rm -f /run/keyring.pass 2>/dev/null || true
      else
        printf '%s unlock FAILED (rc=%s), plik pozostawiony\n' "$(date '+%F %T')" "$?" >>"$ALOGIN_LOG" 2>&1 || true
        logger -t autologin-keyring "Nie udalo sie odblokowac keyringa; plik /run/keyring.pass pozostawiony (szczegoly: $ALOGIN_LOG)"
      fi
    else
      printf '%s brak control socket, nie odblokowano\n' "$(date '+%F %T')" >>"$ALOGIN_LOG" 2>&1 || true
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
