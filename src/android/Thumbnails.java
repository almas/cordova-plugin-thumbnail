package com.cordova.plugin.thumbnail;


import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.media.ThumbnailUtils;
import android.util.Log;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class Thumbnails {

    public static void thumbnail(Options thumbnailOptions) throws IOException {
        long begin = System.currentTimeMillis();

        Bitmap bitmap = thumbnailSmallImage(thumbnailOptions);

        if (saveBitmapToFile(bitmap, thumbnailOptions.targetPath, thumbnailOptions)) {
            File targetFile = new File(thumbnailOptions.targetPath);
            if (targetFile.exists()) {
                Log.i("Thumbnails.thumbnail", "Generated at [" + thumbnailOptions.targetPath + "] in " + (System.currentTimeMillis() - begin) + "ms");
            } else {
                Log.e("Thumbnails.thumbnail", "Generated file does not exists at [" + thumbnailOptions.targetPath + "]");
            }
        } else {
            Log.e("Thumbnails.thumbnail", "Error generate file [" + thumbnailOptions.targetPath + "]");
        }
        bitmap = null;
    }

    private static Bitmap thumbnailSmallImage(Options thumbnailOptions) throws IOException {

        BitmapFactory.Options options = calculateImageSize(thumbnailOptions.sourcePath);
        options.inJustDecodeBounds = false;
        Bitmap bitmap = BitmapFactory.decodeFile(thumbnailOptions.sourcePath, options);

        long begin = System.currentTimeMillis();
        int oWidth = bitmap.getWidth();
        int oHeight = bitmap.getHeight();

        float ratio = Math.min(oWidth * 1.0f / thumbnailOptions.maxPixelSize, oHeight * 1.0f / thumbnailOptions.maxPixelSize);

        if (ratio > 1) {
            int width = (int) (oWidth / ratio);
            int height = (int) (oHeight / ratio);

            bitmap = ThumbnailUtils.extractThumbnail(bitmap, width, height);
        }
        ExifInterface exif = new ExifInterface(thumbnailOptions.sourcePath);
        int orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, 1);
        if (orientation != 1) {
            bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), getRotationMatrix(orientation), true);
        }
        Log.i("Thumbnails.thumbnailSallImage", "Spent time: " + (System.currentTimeMillis() - begin) + "ms");
        return bitmap;
    }

    private static Matrix getRotationMatrix(int orientation) {
        Matrix matrix = new Matrix();
        switch (orientation) {
            case 2:
                matrix.setScale(-1, 1);
                break;
            case 3:
                matrix.setRotate(180);
                break;
            case 4:
                matrix.setRotate(180);
                matrix.postScale(-1, 1);
                break;
            case 5:
                matrix.setRotate(90);
                matrix.postScale(-1, 1);
                break;
            case 6:
                matrix.setRotate(90);
                break;
            case 7:
                matrix.setRotate(-90);
                matrix.postScale(-1, 1);
                break;
            case 8:
                matrix.setRotate(-90);
                break;
        }
        return matrix;

    }

    public static BitmapFactory.Options calculateImageSize(String sourcePath) throws IOException {
        InputStream is = null;
        try {
            is = new BufferedInputStream(new FileInputStream(sourcePath));
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeStream(is, null, options);
            return options;
        } catch (FileNotFoundException e) {
            throw new SourcePathNotFoundException(e);
        } finally {
            if (is != null) {
                is.close();
            }
        }
    }

    public static Boolean saveBitmapToFile(Bitmap bitmap, String targetPath, Options thumbnailOptions) {
        OutputStream os = null;

        try {
            // File targetFile = new File(targetPath);
            // targetFile.createNewFile();
            os = new BufferedOutputStream(new FileOutputStream(targetPath));
            bitmap.compress(guessImageType(targetPath), 90, os);
        } catch (FileNotFoundException ex) {
            throw new TargetPathNotFoundException(ex);
        } finally {
            if (os != null) {
                try {
                    os.close();
                    return true;
                } catch (IOException ex) {
                    Log.e("Thumbnails.saveBitmapToFile()", "Error closing file stream.");
                    ex.printStackTrace();
                }
            }
        }
        return false;
    }

    public static Bitmap.CompressFormat guessImageType(String filePath) {
        String fileExt = filePath.substring(filePath.lastIndexOf(".") + 1).toLowerCase();
        if (fileExt.equals("png")) {
            return Bitmap.CompressFormat.PNG;
        } else if (fileExt.equals("webp")) {
            return Bitmap.CompressFormat.WEBP;
        } else {
            return Bitmap.CompressFormat.JPEG;
        }
    }

    public static class Options {
        public String targetPath;
        public String sourcePath;
        public int maxPixelSize;
        public int compression;

        public Options() {
        }
    }
}
