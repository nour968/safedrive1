package com.example.untitled1;

import android.graphics.Bitmap;
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
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.socket.client.Socket;
import okhttp3.*;

public class CameraActivity extends AppCompatActivity {

    private static final String TAG = "CAMERA_DEBUG";

    private PreviewView previewView;
    private Socket socket;
    private MediaPlayer mediaPlayer;

    private final OkHttpClient client = new OkHttpClient();

    private static final String SERVER_URL =
            "http://192.168.1.64:8000/frame";

    // ✅ FIX: dedicated background thread for camera frames
    private final ExecutorService cameraExecutor =
            Executors.newSingleThreadExecutor();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Log.d(TAG, "onCreate START");

        previewView = new PreviewView(this);
        setContentView(previewView);

        mediaPlayer = MediaPlayer.create(this, R.raw.alert);

        socket = SocketManager.getSocket();

        listenForAlerts();
        startCamera();

        Log.d(TAG, "setup complete");
    }

    // ================= ALERT =================
    private void listenForAlerts() {

        socket.on("new_alert", args -> {

            if (args == null || args.length == 0) return;

            try {
                JSONObject data = (JSONObject) args[0];
                String eventType = data.optString("event_type");

                Log.d(TAG, "ALERT RECEIVED: " + data);

                runOnUiThread(() -> {

                    Toast.makeText(
                            this,
                            "⚠ " + eventType,
                            Toast.LENGTH_LONG
                    ).show();

                    if (mediaPlayer != null) {
                        try {
                            mediaPlayer.start();
                        } catch (Exception e) {
                            Log.e(TAG, "MediaPlayer error", e);
                        }
                    }
                });

            } catch (Exception e) {
                Log.e(TAG, "alert parse error", e);
            }
        });
    }

    // ================= CAMERA =================
    private void startCamera() {

        Log.d(TAG, "startCamera() called");

        ListenableFuture<ProcessCameraProvider> future =
                ProcessCameraProvider.getInstance(this);

        future.addListener(() -> {

            try {
                ProcessCameraProvider cameraProvider = future.get();

                cameraProvider.unbindAll();

                Preview preview = new Preview.Builder().build();

                preview.setSurfaceProvider(
                        previewView.getSurfaceProvider()
                );

                ImageAnalysis analysis =
                        new ImageAnalysis.Builder()
                                .setBackpressureStrategy(
                                        ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST
                                )
                                .setOutputImageFormat(
                                        ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888
                                )
                                .build();

                // ================= IMPORTANT FIX =================
                analysis.setAnalyzer(cameraExecutor, image -> {

                    Log.d(TAG, "ANALYZER FIRED");

                    try {
                        Log.d(TAG, "FRAME RECEIVED");

                        Bitmap bitmap =
                                BitmapUtils.imageProxyToBitmap(image);

                        if (bitmap == null) {
                            Log.e(TAG, "Bitmap is NULL");
                            return;
                        }

                        sendFrame(bitmap);

                    } catch (Exception e) {
                        Log.e(TAG, "frame processing error", e);
                    } finally {
                        image.close();
                    }
                });

                CameraSelector selector =
                        new CameraSelector.Builder()
                                .requireLensFacing(CameraSelector.LENS_FACING_FRONT)
                                .build();

                cameraProvider.bindToLifecycle(
                        this,
                        selector,
                        preview,
                        analysis
                );

                Log.d(TAG, "CAMERA BOUND SUCCESS");

            } catch (ExecutionException | InterruptedException e) {
                Log.e(TAG, "camera error", e);
            }

        }, ContextCompat.getMainExecutor(this));
    }

    // ================= SEND FRAME =================
    private void sendFrame(Bitmap bitmap) {

        try {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();

            bitmap.compress(Bitmap.CompressFormat.JPEG, 30, baos);

            String base64 = Base64.encodeToString(
                    baos.toByteArray(),
                    Base64.NO_WRAP
            );

            String json =
                    "{"
                            + "\"image\":\"" + base64 + "\","
                            + "\"driver_id\":1"
                            + "}";

            RequestBody body = RequestBody.create(
                    json,
                    MediaType.parse("application/json")
            );

            Request request = new Request.Builder()
                    .url(SERVER_URL)
                    .post(body)
                    .build();

            client.newCall(request).enqueue(new Callback() {

                @Override
                public void onFailure(Call call, java.io.IOException e) {
                    Log.e(TAG, "UPLOAD FAILED", e);
                }

                @Override
                public void onResponse(Call call, Response response) {
                    Log.d(TAG, "FRAME SENT SUCCESSFULLY");
                    response.close();
                }
            });

        } catch (Exception e) {
            Log.e(TAG, "sendFrame error", e);
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        if (cameraExecutor != null) {
            cameraExecutor.shutdown();
        }

        if (socket != null) {
            socket.off();
            socket.disconnect();
        }
    }
}
