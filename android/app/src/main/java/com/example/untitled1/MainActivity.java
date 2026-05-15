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

    private Socket socket;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        socket = SocketManager.getSocket();
        socket.on(Socket.EVENT_CONNECT, args -> {
            Log.d("SOCKET", "CONNECTED SUCCESSFULLY");
        });
        socket.connect();

        // 📡 EVENTS
        socket.on(Socket.EVENT_CONNECT, args -> {
            Log.d("SOCKET", "CONNECTED SUCCESSFULLY");
        });

        socket.on(Socket.EVENT_CONNECT_ERROR, args -> {
            Log.d("SOCKET", "CONNECT ERROR: " + args[0]);
        });

        socket.on(Socket.EVENT_DISCONNECT, args -> {
            Log.d("SOCKET", "DISCONNECTED");
        });

        socket.on("new_alert", args -> {

            if (args.length == 0) return;

            try {
                JSONObject data = (JSONObject) args[0];

                String eventType = data.optString("event_type", "Unknown");

                runOnUiThread(() ->
                        Toast.makeText(
                                MainActivity.this,
                                "ALERT: " + eventType,
                                Toast.LENGTH_LONG
                        ).show()
                );

            } catch (Exception e) {
                e.printStackTrace();
            }
        });
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        if (socket != null) {
            socket.disconnect();
            socket.off();
        }
    }
}
