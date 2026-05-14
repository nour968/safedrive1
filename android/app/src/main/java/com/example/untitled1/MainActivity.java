package com.example.untitled1;

import io.flutter.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.socket.client.Socket;
import org.json.JSONObject;
import android.widget.Toast;

public class MainActivity extends FlutterActivity {

    private Socket socket;

    @Override
    protected void onCreate(android.os.Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // 🔌 CONNECT SOCKET ON APP START
        socket = SocketManager.getSocket();

        if (socket != null && !socket.connected()) {
            socket.connect();
        }
        socket = SocketManager.getSocket();
        socket.connect();

        socket.on("connect", args -> {
            Log.d("SOCKET", "CONNECTED SUCCESSFULLY");
        });

        socket.on("connect_error", args -> {
            Log.d("SOCKET", "CONNECT ERROR: " + args[0]);
        });

        socket.on("disconnect", args -> {
            Log.d("SOCKET", "DISCONNECTED");
        });

        // 📡 LISTEN FOR ALERTS
        socket.on("new_alert", args -> {

            if (args.length == 0) return;

            try {
                JSONObject data = (JSONObject) args[0];

                String eventType = data.optString("event_type", "Unknown");

                runOnUiThread(() -> {
                    Toast.makeText(
                            MainActivity.this,
                            "ALERT: " + eventType,
                            Toast.LENGTH_LONG
                    ).show();
                });

            } catch (Exception e) {
                e.printStackTrace();
            }
        });
    }

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        // keep empty or use for method channels only
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        if (socket != null) {
            socket.disconnect();
            socket.off("new_alert");
        }
    }
}