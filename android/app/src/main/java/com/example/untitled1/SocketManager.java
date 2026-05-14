package com.example.untitled1;

import java.net.URISyntaxException;
import io.socket.client.IO;
import io.socket.client.Socket;

public class SocketManager {

    private static Socket socket;

    public static Socket getSocket() {

        if (socket == null) {

            try {
                IO.Options options = new IO.Options();
                options.transports = new String[]{"websocket"};
                options.reconnection = true;

                socket = IO.socket("http://192.168.1.23:8000", options);

            } catch (URISyntaxException e) {
                e.printStackTrace();
            }
        }

        return socket;
    }
}