package com.example.untitled1;

import android.media.Image;
import androidx.camera.core.ImageProxy;

import java.nio.ByteBuffer;

public class ImageUtils {

    // REQUIRED METHOD (matches your CameraActivity call)
    public static byte[] toByteArray(ImageProxy image) {

        ImageProxy.PlaneProxy[] planes = image.getPlanes();

        ByteBuffer yBuffer = planes[0].getBuffer();
        ByteBuffer uBuffer = planes[1].getBuffer();
        ByteBuffer vBuffer = planes[2].getBuffer();

        int ySize = yBuffer.remaining();
        int uSize = uBuffer.remaining();
        int vSize = vBuffer.remaining();

        byte[] nv21 = new byte[ySize + uSize + vSize];

        yBuffer.get(nv21, 0, ySize);

        byte[] uBytes = new byte[uSize];
        byte[] vBytes = new byte[vSize];

        uBuffer.get(uBytes);
        vBuffer.get(vBytes);

        int pos = ySize;

        for (int i = 0; i < uSize; i++) {
            nv21[pos++] = vBytes[i];
            nv21[pos++] = uBytes[i];
        }

        return nv21;
    }
}
