package es.udc.iagolast.speechrecog.speechrecog;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;
import android.speech.SpeechRecognizer;
import android.util.Log;
import android.widget.Toast;

import es.udc.iagolast.speechrecog.speechrecog.speechListener.Listener;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;

public class SpeechRecognitionService extends Service {
    private final int TIMEOUT = 500;
    private Voicetivity currentVoicetivity;
    private SpeechRecognizer speechRecognizer = null;
    private boolean listening = false;
    private static Intent serviceIntent = null;
    private final IBinder sBinder = (IBinder) new SimpleBinder();


    public static synchronized Intent getServiceIntent(Context context) {
        if (serviceIntent == null) {
            serviceIntent = new Intent(context, SpeechRecognitionService.class);
            context.startService(serviceIntent);
        }
        return serviceIntent;
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


    /**
     * Listen for user input.
     */
    public void startListening() {
        changeListening(true);
    }


    /**
     * Stop listening for user input.
     */
    public void stopListening() {
        changeListening(false);
    }


    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        serviceIntent = intent;
        createSpeechRecognizer();
        startListening();
        return START_STICKY;
    }


    /**
     * Creates a speech recognizer with a callback to processSpeech.
     */
    private void createSpeechRecognizer() {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(getApplicationContext());
        speechRecognizer.setRecognitionListener(new Listener(this, getApplicationContext()));
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

    @Override
    public IBinder onBind(Intent intent) {
        return sBinder;
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
     * Called by Listener when There is no matches.
     * Do a little sleep and start listening again.
     */
    public void onNomatchesFound() {
        Log.d("SpeechRecognitionService", "No Matches Found");
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

    class SimpleBinder extends Binder {
        SpeechRecognitionService getService() {
            return SpeechRecognitionService.this;
        }
    }

}
