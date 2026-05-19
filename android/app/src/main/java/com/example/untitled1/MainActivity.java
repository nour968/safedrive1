package com.example.untitled1;

import android.os.Bundle;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.socket.client.Socket;
import org.json.JSONObject;

public class MainActivity extends FlutterActivity {

    private static final String TAG = "SOCKET_DEBUG";
    private Socket socket;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Log.d(TAG, "MainActivity onCreate");

        socket = SocketManager.getSocket();

        if (socket == null) {
            Log.e(TAG, "Socket is NULL");
            return;
        }

        // CONNECT
        socket.on(Socket.EVENT_CONNECT, args -> {
            Log.d(TAG, "CONNECTED SUCCESSFULLY");
        });

        // ERROR
        socket.on(Socket.EVENT_CONNECT_ERROR, args -> {
            Log.e(TAG, "CONNECT ERROR: " + (args.length > 0 ? args[0] : "unknown"));
        });

        // DISCONNECT
        socket.on(Socket.EVENT_DISCONNECT, args -> {
            Log.e(TAG, "DISCONNECTED");
        });

        // ALERT
        socket.on("new_alert", args -> {

            if (args == null || args.length == 0) return;

            try {
                JSONObject data = (JSONObject) args[0];

                String eventType = data.optString("event_type", "Unknown");
                double confidence = data.optDouble("confidence", 0.0);

                Log.d(TAG, "ALERT RECEIVED: " + data.toString());

                runOnUiThread(() -> Toast.makeText(
                        this,
                        "ALERT: " + eventType + " (" + confidence + ")",
                        Toast.LENGTH_LONG
                ).show());

            } catch (Exception e) {
                Log.e(TAG, "JSON ERROR", e);
            }
        });

        socket.connect();
        Log.d(TAG, "Socket connect() called");
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        if (socket != null) {
            socket.off();
            socket.disconnect();
        }
    }
}
