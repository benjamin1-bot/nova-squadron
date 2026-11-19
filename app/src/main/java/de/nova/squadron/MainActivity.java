package de.nova.squadron;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.content.Context;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.view.InputDevice;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.webkit.JavascriptInterface;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

/**
 * Nova Squadron: startet das Spiel im Vollbild (Querformat) in einer WebView.
 * Alle Spieldateien liegen offline im App-Paket (assets/).
 */
public class MainActivity extends Activity {
    private WebView web;

    // ---------- Controller: Android liest das Gamepad direkt und reicht den Zustand an das Spiel weiter ----------
    private final float[] axes = new float[4];
    private final boolean[] btn = new boolean[17];
    private int padDevice = -1;

    private static boolean isPad(InputDevice d) {
        if (d == null) return false;
        int s = d.getSources();
        return (s & InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD || (s & InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK;
    }
    private static int mapKey(int k) {
        switch (k) {
            case KeyEvent.KEYCODE_BUTTON_A: return 0;   case KeyEvent.KEYCODE_BUTTON_B: return 1;
            case KeyEvent.KEYCODE_BUTTON_X: return 2;   case KeyEvent.KEYCODE_BUTTON_Y: return 3;
            case KeyEvent.KEYCODE_BUTTON_L1: return 4;  case KeyEvent.KEYCODE_BUTTON_R1: return 5;
            case KeyEvent.KEYCODE_BUTTON_L2: return 6;  case KeyEvent.KEYCODE_BUTTON_R2: return 7;
            case KeyEvent.KEYCODE_BUTTON_SELECT: return 8; case KeyEvent.KEYCODE_BUTTON_START: return 9;
            case KeyEvent.KEYCODE_BUTTON_THUMBL: return 10; case KeyEvent.KEYCODE_BUTTON_THUMBR: return 11;
            case KeyEvent.KEYCODE_DPAD_UP: return 12;   case KeyEvent.KEYCODE_DPAD_DOWN: return 13;
            case KeyEvent.KEYCODE_DPAD_LEFT: return 14; case KeyEvent.KEYCODE_DPAD_RIGHT: return 15;
            case KeyEvent.KEYCODE_BUTTON_MODE: return 16;
            default: return -1;
        }
    }
    private void pushPad() {
        if (web == null) return;
        StringBuilder sb = new StringBuilder("window.__nativePad&&__nativePad([");
        for (int i = 0; i < 4; i++) { if (i > 0) sb.append(','); sb.append(Math.round(axes[i] * 1000) / 1000f); }
        sb.append("],[");
        for (int i = 0; i < btn.length; i++) { if (i > 0) sb.append(','); sb.append(btn[i] ? 1 : 0); }
        sb.append("])");
        web.evaluateJavascript(sb.toString(), null);
    }
    @Override
    public boolean dispatchKeyEvent(KeyEvent e) {
        int idx = mapKey(e.getKeyCode());
        if (idx >= 0 && (isPad(e.getDevice()) || KeyEvent.isGamepadButton(e.getKeyCode()))) {
            padDevice = e.getDeviceId();
            if (e.getAction() == KeyEvent.ACTION_DOWN) btn[idx] = true;
            else if (e.getAction() == KeyEvent.ACTION_UP) btn[idx] = false;
            pushPad();
            return true;
        }
        return super.dispatchKeyEvent(e);
    }
    private static float ax(MotionEvent e, int a) { InputDevice d = e.getDevice(); if (d == null || d.getMotionRange(a, e.getSource()) == null) return 0f; return e.getAxisValue(a); }
    @Override
    public boolean dispatchGenericMotionEvent(MotionEvent e) {
        if ((e.getSource() & InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK && e.getAction() == MotionEvent.ACTION_MOVE) {
            padDevice = e.getDeviceId();
            axes[0] = ax(e, MotionEvent.AXIS_X); axes[1] = ax(e, MotionEvent.AXIS_Y);
            float rx = ax(e, MotionEvent.AXIS_Z), ry = ax(e, MotionEvent.AXIS_RZ);
            if (rx == 0f && ry == 0f) { rx = ax(e, MotionEvent.AXIS_RX); ry = ax(e, MotionEvent.AXIS_RY); }
            axes[2] = rx; axes[3] = ry;
            float lt = Math.max(ax(e, MotionEvent.AXIS_LTRIGGER), ax(e, MotionEvent.AXIS_BRAKE));
            float rt = Math.max(ax(e, MotionEvent.AXIS_RTRIGGER), ax(e, MotionEvent.AXIS_GAS));
            btn[6] = lt > 0.5f || btn[6] && lt > 0.3f; btn[7] = rt > 0.5f || btn[7] && rt > 0.3f;
            float hx = ax(e, MotionEvent.AXIS_HAT_X), hy = ax(e, MotionEvent.AXIS_HAT_Y);
            if (e.getDevice() != null && e.getDevice().getMotionRange(MotionEvent.AXIS_HAT_X, e.getSource()) != null) {
                btn[14] = hx < -0.5f; btn[15] = hx > 0.5f; btn[12] = hy < -0.5f; btn[13] = hy > 0.5f;
            }
            pushPad();
            return true;
        }
        return super.dispatchGenericMotionEvent(e);
    }
    /** Rumble: vibriert den Controller (falls er einen Motor hat). */
    private class PadBridge {
        @JavascriptInterface
        public void rumble(float strong, float weak, int ms) {
            try {
                InputDevice d = InputDevice.getDevice(padDevice);
                if (d == null) return;
                Vibrator v;
                if (Build.VERSION.SDK_INT >= 31) v = d.getVibratorManager().getDefaultVibrator();
                else v = d.getVibrator();
                if (v == null || !v.hasVibrator()) return;
                int amp = Math.max(1, Math.min(255, Math.round(Math.max(strong, weak) * 255)));
                int dur = Math.max(20, Math.min(1500, ms));
                if (Build.VERSION.SDK_INT >= 26) v.vibrate(VibrationEffect.createOneShot(dur, amp)); else v.vibrate(dur);
            } catch (Throwable ignored) { }
        }
        @JavascriptInterface
        public boolean hasPad() { return padDevice >= 0; }
    }

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Window w = getWindow();
        w.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        w.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
        if (Build.VERSION.SDK_INT >= 28) {
            WindowManager.LayoutParams lp = w.getAttributes();
            lp.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
            w.setAttributes(lp);
        }

        web = new WebView(this);
        web.setBackgroundColor(Color.rgb(3, 4, 10));
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);          // Highscores (localStorage)
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setAllowFileAccess(true);
        s.setLoadWithOverviewMode(true);
        s.setUseWideViewPort(true);
        s.setSupportZoom(false);
        web.setWebViewClient(new WebViewClient());
        web.setWebChromeClient(new WebChromeClient());
        web.setOverScrollMode(View.OVER_SCROLL_NEVER);
        web.addJavascriptInterface(new PadBridge(), "AndroidPad");
        setContentView(web);
        web.loadUrl("file:///android_asset/index.html");
        hideSystemBars();
    }

    private void hideSystemBars() {
        if (Build.VERSION.SDK_INT >= 30) {
            WindowInsetsController c = getWindow().getInsetsController();
            if (c != null) {
                c.hide(WindowInsets.Type.statusBars() | WindowInsets.Type.navigationBars());
                c.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
            }
        } else {
            getWindow().getDecorView().setSystemUiVisibility(
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                            | View.SYSTEM_UI_FLAG_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
        }
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) hideSystemBars();
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (web != null) { web.onPause(); web.pauseTimers(); }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (web != null) { web.onResume(); web.resumeTimers(); }
        hideSystemBars();
    }

    /** Zurück-Taste: im Spiel pausieren statt die App sofort zu schließen. */
    @Override
    public void onBackPressed() {
        web.evaluateJavascript(
                "(function(){var p=document.getElementById('pausem'),m=document.getElementById('menu');" +
                "if(m&&!m.classList.contains('hidden'))return 'exit';" +
                "if(p&&p.classList.contains('hidden')){window.dispatchEvent(new KeyboardEvent('keydown',{code:'KeyP'}));" +
                "window.dispatchEvent(new KeyboardEvent('keyup',{code:'KeyP'}));return 'paused';}return 'exit';})()",
                value -> { if (value != null && value.contains("exit")) finish(); });
    }

    @Override
    protected void onDestroy() {
        if (web != null) { web.destroy(); web = null; }
        super.onDestroy();
    }
}
