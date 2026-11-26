#!/bin/sh
# Installs the home screen on an Android TV (real or emulator) exactly like a user would,
# then checks it works. Usage: sh ci/smoke-test.sh <adb serial or TV_IP> [screenshot.png]
set -e
cd "$(dirname "$0")/.."
TV="$1"; SHOT="${2:-smoke.png}"
fail() {
  echo "FAIL: $*" >&2
  echo "-- on screen: $(focus)" >&2
  adb -s "$TV" logcat -d -b crash 2>/dev/null | grep -A12 "FATAL EXCEPTION" | head -40 >&2
  adb -s "$TV" exec-out screencap -p > "${SHOT%.png}-fail.png" 2>/dev/null || true
  exit 1
}
# Waits up to 15s for the home screen to be in front.
wait_home() { for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do focus | grep -q com.ansub.tvhome && return 0; sleep 1; done; return 1; }
ui() {
  # UIAutomator can take a moment to become idle on Android TV emulators.
  # Retry the dump and verify the file exists before trying to read it.
  for attempt in 1 2 3 4 5; do
    adb -s "$TV" shell "uiautomator dump --compressed /sdcard/ui.xml" >/dev/null 2>&1 || true
    if adb -s "$TV" shell "test -s /sdcard/ui.xml" >/dev/null 2>&1; then
      adb -s "$TV" shell "cat /sdcard/ui.xml" 2>/dev/null && return 0
    fi
    sleep 1
  done
  echo "UI hierarchy dump unavailable after 5 attempts" >&2
  return 1
}
focus() { adb -s "$TV" shell dumpsys window | grep -m1 mCurrentFocus; }

echo "== Android $(adb -s "$TV" shell getprop ro.build.version.release | tr -d '\r'), $(adb -s "$TV" shell wm size | tail -1 | tr -d '\r')"

echo "== install"
YES=1 sh install.sh "$TV"
sleep 3
home=$(adb -s "$TV" shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tail -1 | tr -d '\r')
case "$home" in
  com.ansub.tvhome/.MainActivity|org.droidtv.homeintentresolver/*) ;;
  *) fail "default home is $home" ;;
esac
adb -s "$TV" shell input keyevent KEYCODE_HOME
wait_home || fail "home screen not in front"

echo "== home screen shows a clock and Settings"
x=$(ui)
echo "$x" | grep -qiE '(text|content-desc)="(Settings|Ajustes|AJUSTES)"' || fail "no Settings/Ajustes tile"
echo "$x" | grep -qE 'text="[0-9]{1,2}:[0-9]{2}"' || fail "no clock"
tiles=$(echo "$x" | grep -o 'focusable="true"' | wc -l | tr -d ' ')
echo "   $tiles tiles"
if [ "$FAKE_INPUT" = 1 ]; then
  echo "== emulator input registered"
  # Its tile may already have a saved name from a previous manual test.
  adb -s "$TV" shell dumpsys tv_input | grep -q 'com.ansub.fakeinput/.FakeInputService' \
    || fail "fake input not registered"
fi

echo "== remote: move right, open Settings, come back with Home"
adb -s "$TV" shell input keyevent KEYCODE_DPAD_RIGHT
adb -s "$TV" shell am start -a android.settings.SETTINGS >/dev/null; sleep 3
adb -s "$TV" shell input keyevent KEYCODE_HOME
wait_home || fail "Home didn't come back"

echo "== custom app list"
# Use whatever TV app this device has (test images may have none).
app=$(adb -s "$TV" shell cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.LEANBACK_LAUNCHER \
  | tr -d '\r' | grep / | sed 's|/.*||; s/^ *//' | grep -vx com.ansub.tvhome | head -1)
if [ -n "$app" ]; then
  YES=1 sh install.sh "$TV" "$app"
  adb -s "$TV" shell input keyevent KEYCODE_HOME
  wait_home || fail "home screen not in front after custom list"
  n=$(ui | grep -o 'focusable="true"' | wc -l | tr -d ' ')
  [ "$n" -ge 2 ] || fail "custom app $app didn't show up"
  echo "   $app shows up"
else
  echo "   skipped: this device has no TV apps"
fi

adb -s "$TV" exec-out screencap -p > "$SHOT"

echo "== check.sh refuses a list it can't read"
list=$(mktemp)
echo "# nothing to check" > "$list"
sh check.sh "$TV" "$list" 2>&1 | grep -q "Can't read" && fail "check.sh refused a list it can read"
rm -f "$list"
rc=0; sh check.sh "$TV" "$list" >/dev/null 2>&1 || rc=$?
[ "$rc" = 2 ] || fail "check.sh exit $rc for a list it can't read, expected 2"

echo "== undo puts the TV back"
sh undo.sh "$TV" >/dev/null
if [ "$FAKE_INPUT" = 1 ]; then
  if adb -s "$TV" shell pm list packages com.ansub.fakeinput | grep -q 'package:com.ansub.fakeinput'; then
    fail "undo left the fake input installed"
  fi
fi
sleep 3
home=$(adb -s "$TV" shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tail -1 | tr -d '\r')
case "$home" in *com.ansub.tvhome*|"") fail "after undo, home is '$home'" ;; esac
echo "   home is back to $home"
echo "PASS ($SHOT)"
