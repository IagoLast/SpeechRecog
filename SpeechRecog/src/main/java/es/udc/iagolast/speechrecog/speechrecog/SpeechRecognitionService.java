package es.udc.iagolast.speechrecog.speechrecog;

import android.app.Service;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Binder;
import android.os.IBinder;
import android.speech.SpeechRecognizer;
import android.util.Log;

import es.udc.iagolast.speechrecog.speechrecog.speechListener.Listener;
import es.udc.iagolast.speechrecog.speechrecog.speechListener.SpeechCallback;

public class SpeechRecognitionService extends Service implements SpeechCallback {

    private final IBinder sBinder = (IBinder) new SimpleBinder();
    class SimpleBinder extends Binder {
        SpeechRecognitionService getService(){
            return SpeechRecognitionService.this;
        }
    }


    private final int TIMEOUT = 500;
    private Object currentVoicetivity; /// TODO: Replace Object by the Voicetivity class
    private SpeechRecognizer speechRecognizer = null;
    private boolean listening = false;

    private static Intent serviceIntent = null;
    public static synchronized Intent getServiceIntent(Context c){
        if (serviceIntent == null){
            serviceIntent = new Intent(c, SpeechRecognitionService.class);
            c.startService(serviceIntent);
        }
        return serviceIntent;
    }


    /**
     * Start/Stop listening.
     * This is used internally to synchronize the listening flag while providing a clean interface.
     *
     * @param listen Listen the user.
     */
    private synchronized void changeListening(boolean listen){
        if (listening == listen){
            return; // Nothing changes
        }

        listening = listen;
        Log.d("SpeechRecognitionService", speechRecognizer + "");
        if (listen){
            speechRecognizer.startListening(serviceIntent);
        }
        else{
            speechRecognizer.stopListening();
        }
    }


    /**
     * Listen for user input.
     */
    public void startListening(){
        changeListening(true);
    }


    /**
     * Stop listening for user input.
     */
    public void stopListening(){
        changeListening(false);
    }


    @Override
    public int onStartCommand(Intent intent, int flags, int startId){
        serviceIntent = intent;
        createSpeechRecognizer();
        startListening();

        return START_STICKY;
    }


    /**
     *  Creates a speech recognizer with a callback to processSpeech.
     */
    private void createSpeechRecognizer() {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(getApplicationContext());
        speechRecognizer.setRecognitionListener(new Listener(this, getApplicationContext()));
    }


    /**
     * Send the words the user has spoken to the current Voicetivity.
     *
     * @param speech the words that the user has spoken processed.
     * @TODO Uncomment process() call to current voicetivity when the interface is defined
     */
    @Override
    public void processSpeech(String speech){
        Log.d("SpeechRecognitionService", "Processing: " + speech);
        if (currentVoicetivity != null){
            //currentVoicetivity.process(speech);
        }
    }


    /**
     * Change current voicetivity.
     *
     * @param voicetivity Voicetivity to receive the incoming input.
     * @return Voicetivity listening before this action.
     * @TODO Replace Object with Voicetivity
     */
    public Object setCurrentVoicetivity(Object voicetivity){
        Object lastVoicetivity = currentVoicetivity;
        currentVoicetivity = voicetivity;

        return lastVoicetivity;
    }


    public void endOfSpeech(){
        Log.d("SpeechRecognitionService", "End of speech");


        try {
            Thread.sleep(TIMEOUT);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        speechRecognizer.startListening(serviceIntent);
        Log.d("SpeechRecognitionService", "--------------");
    }


    @Override
    public IBinder onBind(Intent intent) {
        return sBinder;
    }
}
