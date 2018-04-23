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
        BitmapFactory.Options options = calculateImageSize(thumbnailOptions.sourcePath);

        options.inJustDecodeBounds = false;
        options.inSampleSize = calculateInSampleSize(options, thumbnailOptions.width, thumbnailOptions.height);
        boolean needScaleImage = options.outWidth / options.inSampleSize > thumbnailOptions.width &&
                options.outHeight / options.inSampleSize > thumbnailOptions.height;

        Bitmap bitmap = BitmapFactory.decodeFile(thumbnailOptions.sourcePath, options);

        if (needScaleImage) {
            bitmap = thumbnailSamllImage(bitmap, thumbnailOptions.width, thumbnailOptions.height);
        }

        saveBitmapToFile(bitmap, thumbnailOptions.targetPath);

        Log.i("thumbnail", "Generated at [" + thumbnailOptions.sourcePath + "] in " + (System.currentTimeMillis() - begin) + "ms");
    }

    private static Bitmap thumbnailSamllImage(Bitmap bitmap, int width, int height) {
        long begin = System.currentTimeMillis();
        int oWidth = bitmap.getWidth();
        int oHeight = bitmap.getHeight();

        float ratio = Math.min(oWidth * 1.0f / width, oHeight * 1.0f / height);

        width = (int)(oWidth / ratio);
        height = (int)(oHeight / ratio);

        bitmap = ThumbnailUtils.extractThumbnail(bitmap, width, height);

        Log.i("thumbnailSallImage", "Spent time: " + (System.currentTimeMillis() - begin) + "ms");
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
        }finally {
            if (is != null) {
                is.close();
            }
        }
    }

    public static int calculateInSampleSize(BitmapFactory.Options options,
                                            int reqWidth, int reqHeight) {
        final int height = options.outHeight;
        final int width = options.outWidth;
        int inSampleSize = 1;

        options.inSampleSize = 8;

        if (height > reqHeight || width > reqWidth) {
            final int halfHeight = height / 2;
            final int halfWidth = width / 2;

            while ((halfHeight / inSampleSize) > reqHeight &&
                    (halfWidth / inSampleSize) > reqWidth) {
                inSampleSize *= 2;
            }
        }

        return inSampleSize;
    }

    public static void saveBitmapToFile(Bitmap bitmap, String targetPath) {
        OutputStream os = null;

        try {
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
                } catch (IOException ex) {
                    Log.e("Thumbnails.saveBitmapToFile()", "Error closing file stream.");
                    ex.printStackTrace();
                }
            }
        }
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
        public int width;
        public int height;

        public Options() {
        }
    }
}
