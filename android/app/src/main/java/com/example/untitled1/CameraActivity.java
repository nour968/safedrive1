package com.example.untitled1;

import android.graphics.Bitmap;
import android.graphics.ImageFormat;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.media.MediaPlayer;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.*;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.content.ContextCompat;

import com.google.common.util.concurrent.ListenableFuture;

import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.util.concurrent.ExecutionException;

import io.socket.client.Socket;
import okhttp3.*;

public class CameraActivity extends AppCompatActivity {

    private PreviewView previewView;

    private final OkHttpClient client =
            new OkHttpClient();

    private Socket socket;

    private MediaPlayer mediaPlayer;

    private static final String SERVER_URL =
            "http://192.168.1.64:8000/frame";

    @Override
    protected void onCreate(Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);

        previewView = new PreviewView(this);

        setContentView(previewView);

        mediaPlayer = MediaPlayer.create(
                this,
                R.raw.alert
        );

        socket = SocketManager.getSocket();

        listenForAlerts();

        startCamera();
    }

    // =====================================================
    // ALERTS
    // =====================================================

    private void listenForAlerts() {

        socket.on("new_alert", args -> {

            try {

                JSONObject data =
                        (JSONObject) args[0];

                String eventType =
                        data.getString("event_type");

                runOnUiThread(() -> {

                    Toast.makeText(
                            this,
                            "⚠ " + eventType,
                            Toast.LENGTH_LONG
                    ).show();

                    if (!mediaPlayer.isPlaying()) {

                        mediaPlayer.start();
                    }
                });

            } catch (Exception e) {

                e.printStackTrace();
            }
        });
    }

    // =====================================================
    // CAMERA
    // =====================================================

    private void startCamera() {

        ListenableFuture<ProcessCameraProvider>
                cameraProviderFuture =
                ProcessCameraProvider.getInstance(this);

        cameraProviderFuture.addListener(() -> {

            try {

                ProcessCameraProvider cameraProvider =
                        cameraProviderFuture.get();

                Preview preview =
                        new Preview.Builder().build();

                preview.setSurfaceProvider(
                        previewView.getSurfaceProvider()
                );

                ImageAnalysis imageAnalysis =
                        new ImageAnalysis.Builder()
                                .setBackpressureStrategy(
                                        ImageAnalysis
                                                .STRATEGY_KEEP_ONLY_LATEST
                                )
                                .build();

                imageAnalysis.setAnalyzer(
                        ContextCompat.getMainExecutor(this),

                        image -> {

                            try {

                                Bitmap bitmap =
                                        imageProxyToBitmap(image);

                                sendFrame(bitmap);

                            } catch (Exception e) {

                                e.printStackTrace();

                            } finally {

                                image.close();
                            }
                        }
                );

                CameraSelector selector =
                        new CameraSelector.Builder()
                                .requireLensFacing(
                                        CameraSelector
                                                .LENS_FACING_FRONT
                                )
                                .build();

                cameraProvider.unbindAll();

                cameraProvider.bindToLifecycle(
                        this,
                        selector,
                        preview,
                        imageAnalysis
                );

            } catch (
                    ExecutionException |
                    InterruptedException e
            ) {

                e.printStackTrace();
            }

        }, ContextCompat.getMainExecutor(this));
    }

    // =====================================================
    // SEND FRAME
    // =====================================================

    private void sendFrame(Bitmap bitmap) {

        try {

            ByteArrayOutputStream baos =
                    new ByteArrayOutputStream();

            bitmap.compress(
                    Bitmap.CompressFormat.JPEG,
                    30,
                    baos
            );

            byte[] bytes = baos.toByteArray();

            String base64 =
                    Base64.encodeToString(
                            bytes,
                            Base64.NO_WRAP
                    );

            String json =
                    "{"
                            + "\"image\":\"" + base64 + "\","
                            + "\"driver_id\":1"
                            + "}";

            RequestBody body =
                    RequestBody.create(
                            json,
                            MediaType.parse(
                                    "application/json"
                            )
                    );

            Request request =
                    new Request.Builder()
                            .url(SERVER_URL)
                            .post(body)
                            .build();

            client.newCall(request).enqueue(
                    new Callback() {

                        @Override
                        public void onFailure(
                                Call call,
                                java.io.IOException e
                        ) {

                            Log.e(
                                    "UPLOAD",
                                    "FAILED"
                            );
                        }

                        @Override
                        public void onResponse(
                                Call call,
                                Response response
                        ) {

                            Log.d(
                                    "UPLOAD",
                                    "FRAME SENT"
                            );

                            response.close();
                        }
                    }
            );

        } catch (Exception e) {

            e.printStackTrace();
        }
    }

    // =====================================================
    // IMAGE CONVERSION
    // =====================================================

    private Bitmap imageProxyToBitmap(
            ImageProxy image
    ) {

        byte[] nv21 =
                ImageUtils.toByteArray(image);

        YuvImage yuvImage =
                new YuvImage(
                        nv21,
                        ImageFormat.NV21,
                        image.getWidth(),
                        image.getHeight(),
                        null
                );

        ByteArrayOutputStream out =
                new ByteArrayOutputStream();

        yuvImage.compressToJpeg(
                new Rect(
                        0,
                        0,
                        image.getWidth(),
                        image.getHeight()
                ),
                50,
                out
        );

        byte[] imageBytes =
                out.toByteArray();

        return android.graphics.BitmapFactory
                .decodeByteArray(
                        imageBytes,
                        0,
                        imageBytes.length
                );
    }
}
