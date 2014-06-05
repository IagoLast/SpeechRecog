package es.udc.iagolast.speechrecog.speechrecog;

import android.app.Notification;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.media.AudioManager;
import android.media.ToneGenerator;
import android.os.Binder;
import android.os.IBinder;
import android.speech.SpeechRecognizer;
import android.speech.tts.TextToSpeech;
import android.util.Log;
import android.widget.Toast;

import es.udc.iagolast.speechrecog.speechrecog.speechListener.Listener;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.MainVt.VtMain;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;

public class SpeechRecognitionService extends Service implements TextToSpeech.OnInitListener {
    public final int TONE_ERROR = 0;
    public final int TONE_OK = 1;

    private int volume;  //Used to restore the volume to the original value.
    private Voicetivity currentVoicetivity;
    private static Intent serviceIntent = null;
    private SpeechRecognizer speechRecognizer = null;
    private TextToSpeech textToSpeech;
    private final IBinder sBinder = (IBinder) new SimpleBinder();
    private String TAG = "SERVICE";
    ToneGenerator toneGenerator = new ToneGenerator(AudioManager.STREAM_ALARM, 100);



    /**
     * Creates a speech recognizer with a callback to processSpeech.
     */
    private void initService() {
        textToSpeech = new TextToSpeech(this, this);
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this);
        speechRecognizer.setRecognitionListener(new Listener(this));
        setCurrentVoicetivity(new VtMain(this));
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "onStartCommand");
        serviceIntent = intent;
        initService();
        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        Log.d(TAG, "onBind");
        return sBinder;
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
        //textToSpeech.stop();
        textToSpeech.shutdown();
        speechRecognizer.destroy();
    }



    @Override
    public boolean onUnbind(Intent intent) {
        Log.d(TAG, "onUnbind");
        return super.onUnbind(intent);
    }

    /**
     * Mute volume to hide "BEEP" while listening.
     */
    public void muteAudio() {
        Log.d(TAG, "muteAudio");
        AudioManager audioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
        volume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC);
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, 0, 0);
    }

    /**
     * Un-mute volume to the original level saved in volume.
     */
    public void unMuteAudio() {
        AudioManager audioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, volume, 0);
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
    public void onError(int error) {
        if (error == 7) {
            playTone(TONE_ERROR);
        }
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

    public void playTone(int tone) {
        switch (tone) {
            case TONE_ERROR:
                toneGenerator.startTone(ToneGenerator.TONE_SUP_ERROR, 250);
                break;
            case TONE_OK:
                toneGenerator.startTone(ToneGenerator.TONE_PROP_BEEP, 250);
                break;
            default:
                toneGenerator.startTone(tone, 500);

        }
    }

    class SimpleBinder extends Binder {
        SpeechRecognitionService getService() {
            return SpeechRecognitionService.this;
        }
    }

}
