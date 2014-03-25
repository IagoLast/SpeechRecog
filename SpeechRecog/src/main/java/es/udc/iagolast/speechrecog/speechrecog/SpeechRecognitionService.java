package es.udc.iagolast.speechrecog.speechrecog;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.speech.SpeechRecognizer;
import android.util.Log;

import es.udc.iagolast.speechrecog.speechrecog.speechListener.Listener;
import es.udc.iagolast.speechrecog.speechrecog.speechListener.SpeechCallback;
import es.udc.iagolast.speechrecog.speechrecog.speechListener.StupidCallback;

public class SpeechRecognitionService extends Service implements SpeechCallback {

    private static Object currentVoicetivity; /// TODO: Replace Object by the Voicetivity class
    private static SpeechRecognizer speechRecognizer;
    private static Intent serviceIntent;
    private static boolean listening;


    public SpeechRecognitionService() {
        currentVoicetivity = null;
        listening = false;
    }


    /**
     * Start/Stop listening.
     * This is used internally to synchronize the listening flag while providing a clean interface.
     *
     * @param listen Listen the user.
     */
    private static synchronized void changeListening(boolean listen){
        if (listening == listen){
            return; // Nothing changes
        }

        listening = listen;
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
    public static void startListening(){
        changeListening(true);
    }


    /**
     * Stop listening for user input.
     */
    public static void stopListening(){
        changeListening(false);
    }


    @Override
    public int onStartCommand(Intent intent, int flags, int startId){
        serviceIntent = intent;
        createSpeechRecognizer();

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
     */
    @Override
    public void processSpeech(String speech){
        Log.d("SpeechRecognitionService", "Processing: " + speech);
        if (currentVoicetivity != null){
            //currentVoicetivity.process(speech);
        }
    }


    @Override
    public IBinder onBind(Intent intent) {
        // TODO: Return the communication channel to the service.
        throw new UnsupportedOperationException("Not yet implemented");
    }
}
