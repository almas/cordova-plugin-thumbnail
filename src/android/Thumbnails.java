package com.cordova.plugin.thumbnail;


import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
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

        Bitmap bitmap = thumbnailSamllImage(thumbnailOptions);

        if(saveBitmapToFile(bitmap, thumbnailOptions.targetPath)) {
            File targetFile = new File(thumbnailOptions.targetPath);
            if(targetFile.exists()) {
                Log.i("Thumbnails.thumbnail", "Generated at [" + thumbnailOptions.targetPath + "] in " + (System.currentTimeMillis() - begin) + "ms");
            } else {
                Log.e("Thumbnails.thumbnail", "Generated file does not exists at [" + thumbnailOptions.targetPath + "]");
            }
        } else {
            Log.e("Thumbnails.thumbnail", "Error generate file [" + thumbnailOptions.targetPath + "]");
        }
    }

    private static Bitmap thumbnailSamllImage(Options thumbnailOptions) {

        BitmapFactory.Options options = calculateImageSize(thumbnailOptions.sourcePath);
        options.inJustDecodeBounds = false;
        Bitmap bitmap = BitmapFactory.decodeFile(thumbnailOptions.sourcePath, options);

        long begin = System.currentTimeMillis();
        int oWidth = bitmap.getWidth();
        int oHeight = bitmap.getHeight();

        float ratio = Math.min(oWidth * 1.0f / thumbnailOptions.maxPixelSize, oHeight * 1.0f / thumbnailOptions.maxPixelSize);

        if(ratio > 1) {
            int width = (int)(oWidth / ratio);
            int height = (int)(oHeight / ratio);

            bitmap = ThumbnailUtils.extractThumbnail(bitmap, width, height);
        }

        Log.i("Thumbnails.thumbnailSallImage", "Spent time: " + (System.currentTimeMillis() - begin) + "ms");
        return bitmap;
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

    public static Boolean saveBitmapToFile(Bitmap bitmap, String targetPath) {
        OutputStream os = null;

        try {
            // File targetFile = new File(targetPath);
            // targetFile.createNewFile();
            os = new BufferedOutputStream(new FileOutputStream(targetPath));
            bitmap.compress(guessImageType(targetPath), 90, os);
        } catch (FileNotFoundException ex) {
            throw new TargetPathNotFoundException(ex);
        } catch (IOException ex) {
            Log.e("Thumbnails.saveBitmapToFile()", "Error opening file stream:" + targetPath);
            ex.printStackTrace();
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

        public Options() {
        }
    }
}
