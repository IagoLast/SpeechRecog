package es.udc.iagolast.speechrecog.speechrecog;

import android.app.Notification;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;
import android.speech.SpeechRecognizer;
import android.speech.tts.TextToSpeech;
import android.util.Log;
import android.widget.Toast;

import es.udc.iagolast.speechrecog.speechrecog.speechListener.Listener;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;

public class SpeechRecognitionService extends Service implements TextToSpeech.OnInitListener {
    private final int TIMEOUT = 500;
    private Voicetivity currentVoicetivity;
    private SpeechRecognizer speechRecognizer = null;
    private boolean listening = false;
    private static Intent serviceIntent = null;
    private final IBinder sBinder = (IBinder) new SimpleBinder();
    private TextToSpeech textToSpeech;


    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        serviceIntent = intent;
        initService();
        startListening();
        return START_STICKY;
    }

    /**
     * Inits TextToSpeech and
     * creates a speech recognizer with a callback to processSpeech.
     */
    private void initService() {
        textToSpeech = new TextToSpeech(getApplicationContext(), this);
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(getApplicationContext());
        speechRecognizer.setRecognitionListener(new Listener(this));
    }

    /**
     * Listen for user input.
     * When listening notification is shown.
     */
    public void startListening() {
        changeListening(true);
        Notification notification = new Notification();
        Intent intent = new Intent(this, SpeechRecognitionService.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP |
                Intent.FLAG_ACTIVITY_SINGLE_TOP);
        notification.flags |= Notification.FLAG_NO_CLEAR;
        startForeground(1337, notification);
    }

    /**
     * Start/Stop listening.
     * This is used internally to synchronize the listening flag while providing a clean interface.
     *
     * @param listen Listen the user.
     */
    private synchronized void changeListening(boolean listen) {
        if (listening == listen) {
            return; // Nothing changes
        }
        listening = listen;
        Log.d("SpeechRecognitionService", speechRecognizer + "");
        if (listen) {
            speechRecognizer.startListening(serviceIntent);
        } else {
            speechRecognizer.stopListening();
        }
    }

    public static synchronized Intent getServiceIntent(Context context) {
        if (serviceIntent == null) {
            serviceIntent = new Intent(context, SpeechRecognitionService.class);
            context.startService(serviceIntent);
        }
        return serviceIntent;
    }


    /**
     * Stop listening for user input.
     */
    public void stopListening() {
        changeListening(false);
        stopForeground(true);
    }

    /**
     * Change current voicetivity.
     *
     * @param voicetivity Voicetivity to receive the incoming input.
     * @return Voicetivity listening before this action.
     */
    public Voicetivity setCurrentVoicetivity(Voicetivity voicetivity) {
        Voicetivity lastVoicetivity = currentVoicetivity;
        currentVoicetivity = voicetivity;
        return lastVoicetivity;
    }


    /**
     * Send the words the user has spoken to the current Voicetivity.
     *
     * @param speech the words that the user has spoken processed.
     * @TODO Uncomment process() call to current voicetivity when the interface is defined
     */
    public void processSpeech(String speech) {
        Log.d("SpeechRecognitionService", "Processing: " + speech);
        if (currentVoicetivity != null) {
            currentVoicetivity.processSpeech(speech);
        } else {
            Log.d("SpeechRecognitionService", "Pass");
            Toast.makeText(getApplicationContext(), "No VT set yet.", Toast.LENGTH_SHORT).show();
        }
        waitAndRun();
    }

    /**
     * If an error happens, just restart and listen again.
     */
    public void onError() {
        waitAndRun();
    }

    /**
     * Performs a little thread sleep, this is the way how we can listen
     * several consecutive times.
     */
    public void waitAndRun() {
        try {
            Thread.sleep(TIMEOUT);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        speechRecognizer.startListening(serviceIntent);
    }


    @Override
    public IBinder onBind(Intent intent) {
        return sBinder;
    }

    class SimpleBinder extends Binder {
        SpeechRecognitionService getService() {
            return SpeechRecognitionService.this;
        }
    }

    @Override
    public void onInit(int status) {

    }
}
