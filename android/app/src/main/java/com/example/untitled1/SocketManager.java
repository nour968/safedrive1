package com.example.untitled1;

import android.util.Log;

import java.net.URISyntaxException;

import io.socket.client.IO;
import io.socket.client.Socket;

public class SocketManager {

    private static Socket socket;

    public static Socket getSocket() {

        if (socket == null) {

            try {

                IO.Options options = new IO.Options();

                options.transports =
                        new String[]{"websocket", "polling"};

                options.reconnection = true;
                options.forceNew = false;
                options.timeout = 20000;

                socket = IO.socket(
                        "http://192.168.1.64:8000",
                        options
                );

                socket.on(Socket.EVENT_CONNECT, args -> {
                    Log.d("SOCKET", "CONNECTED SUCCESSFULLY");
                });

                socket.on(Socket.EVENT_DISCONNECT, args -> {
                    Log.e("SOCKET", "DISCONNECTED");
                });

                socket.on(Socket.EVENT_CONNECT_ERROR, args -> {

                    Log.e("SOCKET", "CONNECT ERROR");

                    if (args.length > 0) {
                        Log.e(
                                "SOCKET",
                                args[0].toString()
                        );
                    }
                });

                socket.on("new_alert", args -> {

                    Log.d(
                            "SOCKET",
                            "NEW ALERT RECEIVED"
                    );
                });

                socket.connect();

            } catch (URISyntaxException e) {

                e.printStackTrace();
            }
        }

        return socket;
    }
}
