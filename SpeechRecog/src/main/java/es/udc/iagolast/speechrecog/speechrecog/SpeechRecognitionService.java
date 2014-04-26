package es.udc.iagolast.speechrecog.speechrecog;

import android.app.Notification;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.media.AudioManager;
import android.os.Binder;
import android.os.IBinder;
import android.speech.SpeechRecognizer;
import android.speech.tts.TextToSpeech;
import android.util.Log;
import android.widget.Toast;

import es.udc.iagolast.speechrecog.speechrecog.speechListener.Listener;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.voicetivityManager.VoicetivityManager;

public class SpeechRecognitionService extends Service implements TextToSpeech.OnInitListener {
    public int volume;  //Used to restore the volume to the original value.
    private Voicetivity currentVoicetivity;
    private static Intent serviceIntent = null;
    private SpeechRecognizer speechRecognizer = null;
    private TextToSpeech textToSpeech;
    private final IBinder sBinder = (IBinder) new SimpleBinder();
    private String TAG = "SERVICE";

    @Override
    public void onCreate() {
        Log.d(TAG, "onCreate");
        super.onCreate();
        initService();
    }

    /**
     * Creates a speech recognizer with a callback to processSpeech.
     */
    private void initService() {
        textToSpeech = new TextToSpeech(this, this);
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this);
        speechRecognizer.setRecognitionListener(new Listener(this));
        setCurrentVoicetivity(VoicetivityManager.getInstance(this).getVoicetivity("Main"));
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "onStartCommand");
        if (serviceIntent == null) {
            serviceIntent = intent;
        }
        return START_STICKY;
    }

    @Override
    public void onInit(int status) {
        Log.d(TAG, "onInit");
        if (status == TextToSpeech.SUCCESS) {
            startListening();
        }
    }

    /**
     * Listen for user input.
     * When listening notification is shown.
     */
    public void startListening() {
        speechRecognizer.startListening(serviceIntent);
        muteAudio();
        startForeground(1337, buildNofification());
    }

    @Override
    public void onDestroy() {
        Log.d(TAG, "onDestroy");
        destroyService();
        super.onDestroy();
    }

    private void destroyService() {
        textToSpeech.stop();
        textToSpeech.shutdown();
        speechRecognizer.destroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        Log.d(TAG, "onBind");
        return sBinder;
    }

    @Override
    public boolean onUnbind(Intent intent) {
        Log.d(TAG, "onUnbind");
        return super.onUnbind(intent);
    }

    /**
     * Mute volume to hide "BEEP" while listening.
     */
    private void muteAudio() {
        Log.d(TAG, "muteAudio");
        AudioManager audioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
        volume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC);
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, 0, 0);
    }

    /**
     * Builds a new notification which is always visible while service is running.
     *
     * @return notification.
     */
    private Notification buildNofification() {
        Notification notification = new Notification();
        Intent intent = new Intent(this, SpeechRecognitionService.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP |
                Intent.FLAG_ACTIVITY_SINGLE_TOP);
        notification.flags |= Notification.FLAG_NO_CLEAR;
        return notification;
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
     */
    public void processSpeech(String speech) {
        Log.d("SpeechRecognitionService", "Processing: " + speech);
        if (currentVoicetivity != null) {
            currentVoicetivity.processSpeech(speech);
        } else {
            Log.e("SpeechRecognitionService", "No voicetivity detected");
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
     * Waits until texToSpeech ends speaking to start listening again.
     */
    public void waitAndRun() {
        while (textToSpeech.isSpeaking()) {
            //Wait until stop speaking.
        }
        speechRecognizer.startListening(serviceIntent);
        muteAudio();
    }

    /**
     * @param speech
     */
    public void speak(String speech) {
        textToSpeech.speak(speech, TextToSpeech.QUEUE_FLUSH, null);
    }

    /**
     *
     * @param speech
     * @param flush
     */
    public void speak(String speech, Boolean flush) {
        if (flush) {
            speak(speech);
        } else {
            textToSpeech.speak(speech, TextToSpeech.QUEUE_ADD, null);
        }
    }

    class SimpleBinder extends Binder {
        SpeechRecognitionService getService() {
            return SpeechRecognitionService.this;
        }
    }
}
