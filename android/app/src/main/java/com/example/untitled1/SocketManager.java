package com.example.untitled1;

import io.socket.client.IO;
import io.socket.client.Socket;

public class SocketManager {

    private static Socket socket;

    public static Socket getSocket() {

        if (socket == null) {

            try {

                IO.Options options = new IO.Options();

                // IMPORTANT
                options.forceNew = true;
                options.reconnection = true;

                // USE BOTH
                options.transports = new String[] {
                        "websocket",
                        "polling"
                };

                socket = IO.socket(
                        "http://192.168.1.61:8000",
                        options
                );

            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        return socket;
    }
}
