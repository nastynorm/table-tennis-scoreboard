package com.steenbergttc.scoreboard;

import android.os.Bundle;

import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;

import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    hideSystemBars();
  }

  @Override
  public void onResume() {
    super.onResume();
    startKioskLock();
  }

  // Screen pinning (Lock Task) so the scoreboard can't be accidentally exited.
  // On a normal device this asks the user to confirm the first time; to leave,
  // touch & hold the Back and Overview (recent-apps) buttons together.
  private void startKioskLock() {
    try {
      startLockTask();
    } catch (Exception ignored) {
      // Not available / not permitted on this device — ignore.
    }
  }

  @Override
  public void onWindowFocusChanged(boolean hasFocus) {
    super.onWindowFocusChanged(hasFocus);
    // Re-hide whenever we regain focus (e.g. after a swipe reveals the bars).
    if (hasFocus) {
      hideSystemBars();
    }
  }

  // Immersive-sticky fullscreen: hide the status bar and navigation bar. They
  // reappear transiently on an edge swipe and then auto-hide again — ideal for
  // a scoreboard / kiosk.
  private void hideSystemBars() {
    WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
    WindowInsetsControllerCompat controller =
        WindowCompat.getInsetsController(getWindow(), getWindow().getDecorView());
    if (controller != null) {
      controller.hide(WindowInsetsCompat.Type.systemBars());
      controller.setSystemBarsBehavior(
          WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
    }
  }
}
