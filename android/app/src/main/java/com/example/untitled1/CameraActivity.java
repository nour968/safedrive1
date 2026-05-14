package com.example.untitled1;

import android.os.Bundle;
import android.util.Log;

import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageProxy;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.content.ContextCompat;

import com.google.common.util.concurrent.ListenableFuture;

import java.util.concurrent.ExecutionException;

public class CameraActivity extends AppCompatActivity {

    private PreviewView previewView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Camera preview UI
        previewView = new PreviewView(this);

        setContentView(previewView);

        startCamera();
    }

    private void startCamera() {

        ListenableFuture<ProcessCameraProvider> cameraProviderFuture =
                ProcessCameraProvider.getInstance(this);

        cameraProviderFuture.addListener(() -> {

            try {

                ProcessCameraProvider cameraProvider =
                        cameraProviderFuture.get();

                // Preview
                androidx.camera.core.Preview preview =
                        new androidx.camera.core.Preview.Builder().build();

                preview.setSurfaceProvider(previewView.getSurfaceProvider());

                // Image Analysis (for AI processing)
                ImageAnalysis imageAnalysis =
                        new ImageAnalysis.Builder()
                                .setBackpressureStrategy(
                                        ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST
                                )
                                .build();

                imageAnalysis.setAnalyzer(
                        ContextCompat.getMainExecutor(this),
                        new ImageAnalysis.Analyzer() {
                            @Override
                            public void analyze(ImageProxy image) {

                                try {

                                    // 🔥 HERE YOU SEND FRAME TO AI (future upgrade)
                                    // byte[] data = ImageUtils.imageToByteArray(image.getImage());

                                    Log.d("Camera", "Frame received");

                                } catch (Exception e) {
                                    e.printStackTrace();
                                } finally {
                                    image.close();
                                }
                            }
                        }
                );

                CameraSelector cameraSelector =
                        new CameraSelector.Builder()
                                .requireLensFacing(CameraSelector.LENS_FACING_FRONT)
                                .build();

                cameraProvider.unbindAll();

                cameraProvider.bindToLifecycle(
                        this,
                        cameraSelector,
                        preview,
                        imageAnalysis
                );

            } catch (ExecutionException | InterruptedException e) {
                e.printStackTrace();
            }

        }, ContextCompat.getMainExecutor(this));
    }
}