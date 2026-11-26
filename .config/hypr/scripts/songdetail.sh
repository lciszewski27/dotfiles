#!/bin/bash
# Empty output (no player running) must not spam the lock screen.
playerctl metadata --format '{{title}}   ▶   {{artist}}' 2>/dev/null || exit 0
