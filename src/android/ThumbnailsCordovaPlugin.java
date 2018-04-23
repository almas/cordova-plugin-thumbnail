package com.cordova.plugin.thumbnail;

import android.app.Activity;
import android.os.Environment;
import android.util.Log;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;

import java.io.File;
import java.io.IOException;
import java.util.UUID;

public class ThumbnailsCordovaPlugin extends CordovaPlugin {
    private Activity activity;
    private String persistentRoot;
    private String tempRoot;
    private String cacheRootPath;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        activity = cordova.getActivity();
        persistentRoot = getRootDirectoryPath(activity);
        tempRoot = getRootDirectoryPath(activity);
        cacheRootPath = persistentRoot;
        new File(cacheRootPath).mkdirs();
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("thumbnail")) {
            return onThumbnail(args, callbackContext);
        } else if (action.equals("config")) {
            return onConfig(args, callbackContext);
        }
        return false;
    }

    private boolean onConfig(JSONArray args, CallbackContext callbackContext) throws JSONException {
        int persistenceType = args.getInt(0);
        if (persistenceType == 0) {
            cacheRootPath = tempRoot;
        } else {
            cacheRootPath = persistentRoot;
        }
        return true;
    }

    private boolean onThumbnail(final JSONArray args, final CallbackContext callbackContext) throws JSONException {
        final Thumbnails.Options options = getThumbnailOptions(args);
        cordova.getThreadPool().submit(new Runnable() {
           @Override
           public void run() {
               try {
                   try {
                       new File(options.targetPath).createNewFile();
                   } catch (IOException e) {
                       throw new TargetPathNotFoundException();
                   }
                   Thumbnails.thumbnail(options);
                   callbackContext.success(options.targetPath);
               } catch (SourcePathNotFoundException e) {
                   e.printStackTrace();
                   callbackContext.error("The image file does not exist at path: " + options.sourcePath);
               } catch (TargetPathNotFoundException e) {
                   callbackContext.error("Can't create thumbnail file at path: " + options.targetPath);
               } catch (Exception e) {
                   callbackContext.error("Error: " + e.getMessage());
               }
           }
       });

       return true;
   }

    private Thumbnails.Options getThumbnailOptions(JSONArray args) throws JSONException {
        boolean hasTargetPath = args.length() >= 4;
        Thumbnails.Options options = new Thumbnails.Options();
        options.sourcePath = args.getString(0);
        if (hasTargetPath) {
            options.targetPath = args.getString(1);
            options.width = args.getInt(2);
            options.height = args.getInt(3);
        } else {
            options.targetPath = cacheRootPath + UUID.randomUUID().toString() + ".jpg";
            options.width = args.getInt(1);
            options.height = args.getInt(2);
        }

        return options;
    }

    private String getRootDirectoryPath(Activity activity) {
        String persistentRoot = null;
        String packageName = activity.getPackageName();
        String location = activity.getIntent().getStringExtra("androidpersistentfilelocation");
        if (location == null) {
            location = "compatibility";
        }

        if ("internal".equalsIgnoreCase(location)) {
            persistentRoot = activity.getFilesDir().getAbsolutePath() + "/files/";
        } else if ("compatibility".equalsIgnoreCase(location)) {
            if (Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED)) {
                persistentRoot = Environment.getExternalStorageDirectory().getAbsolutePath();
            } else {
                persistentRoot = "/data/data/" + packageName;
            }
        }

        return persistentRoot;
    }

    private String getRootTemplateDirectoryPath(Activity activity) {
        String tempRoot;
        String packageName = activity.getPackageName();
        tempRoot = activity.getCacheDir().getAbsolutePath();

        String location = activity.getIntent().getStringExtra("androidpersistentfilelocation");
        if (location == null) {
            location = "compatibility";
        }

        if ("compatibility".equalsIgnoreCase(location)) {
            tempRoot = Environment.getExternalStorageDirectory().getAbsolutePath() +
                    "/Android/data/" + packageName + "/cache/";
        }

        return tempRoot;
    }
}
