package es.udc.iagolast.speechrecog.speechrecog.mailClient.imap;

import android.app.Service;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Binder;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;

import org.htmlcleaner.HtmlCleaner;
import org.htmlcleaner.TagNode;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

import javax.mail.Address;
import javax.mail.BodyPart;
import javax.mail.Folder;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Multipart;
import javax.mail.Part;
import javax.mail.Session;
import javax.mail.Store;

public class IMAPClientService extends Service {
    public static final String USERNAME = "USERNAME";
    public static final String PASSWORD = "PASSWORD";
    private static final String TAG = "SpeechRecog/IMAPClientService";

    private final IBinder sBinder = (IBinder) new SimpleBinder();
    private List<IMAPMail> mailList = new ArrayList<IMAPMail>();
    private String username, password;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "onStartCommand");
        if (intent != null){
            Bundle extras = intent.getExtras();
            if (extras != null){
                String newUsername = extras.getString(USERNAME),
                        newPassword = extras.getString(PASSWORD);
                if (newUsername != null){
                    username = newUsername;
                }
                if (newPassword != null){
                    password = newPassword;
                }
            }
        }

        refresh();
        return START_STICKY;
    }


    // Even on services Network operations have to be done inside a AsyncTask
    public void refresh(){
        new IMAPAsyncQuery(username, password, getResources()){
            @Override
            public void onPostExecute(List<IMAPMail> result){
                mailList = result;
            }
        }.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
    }



    @Override
    public IBinder onBind(Intent intent) {
        Log.d(TAG, "onBind");
        return sBinder;
    }


    public List<IMAPMail> getMailList() {
        return mailList;
    }


    class SimpleBinder extends Binder {
        IMAPClientService getService() {
            return IMAPClientService.this;
        }
    }
}
