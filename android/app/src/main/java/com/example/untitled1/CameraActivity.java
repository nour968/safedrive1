package com.example.untitled1;

import android.graphics.Bitmap;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;

import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.*;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.content.ContextCompat;

import com.google.common.util.concurrent.ListenableFuture;

import java.io.ByteArrayOutputStream;
import java.util.concurrent.ExecutionException;

import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Callback;
import okhttp3.Call;
import okhttp3.Response;

import io.socket.client.Socket;

public class CameraActivity extends AppCompatActivity {

    private PreviewView previewView;
    private final OkHttpClient client = new OkHttpClient();

    private Socket socket;

    private static final String SERVER_URL =
            "http://192.168.1.64:8000/frame";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        previewView = new PreviewView(this);
        setContentView(previewView);

        socket = SocketManager.getSocket();

        startCamera();
    }

    private void startCamera() {

        ListenableFuture<ProcessCameraProvider> cameraProviderFuture =
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
                                        ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST
                                )
                                .build();

                imageAnalysis.setAnalyzer(
                        ContextCompat.getMainExecutor(this),
                        image -> {

                            try {

                                Log.d("CAMERA", "Frame received");

                                // OPTIONAL: send frame (future AI step)
                                // sendFrame(bitmap);

                            } catch (Exception e) {
                                e.printStackTrace();
                            } finally {
                                image.close();
                            }
                        }
                );

                CameraSelector selector =
                        new CameraSelector.Builder()
                                .requireLensFacing(CameraSelector.LENS_FACING_FRONT)
                                .build();

                cameraProvider.unbindAll();

                cameraProvider.bindToLifecycle(
                        this,
                        selector,
                        preview,
                        imageAnalysis
                );

            } catch (ExecutionException | InterruptedException e) {
                e.printStackTrace();
            }

        }, ContextCompat.getMainExecutor(this));
    }

    private void sendFrame(Bitmap bitmap) {

        ByteArrayOutputStream baos = new ByteArrayOutputStream();

        bitmap.compress(Bitmap.CompressFormat.JPEG, 30, baos);

        byte[] bytes = baos.toByteArray();

        String base64 = Base64.encodeToString(bytes, Base64.NO_WRAP);

        String json = "{\"image\":\"" + base64 + "\"}";

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
                Log.e("UPLOAD", "FAILED: " + e.getMessage());
            }

            @Override
            public void onResponse(Call call, Response response) {
                Log.d("UPLOAD", "FRAME SENT");
                response.close();
            }
        });
    }
}
