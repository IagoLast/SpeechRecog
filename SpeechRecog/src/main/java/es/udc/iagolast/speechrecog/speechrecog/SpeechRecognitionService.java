package es.udc.iagolast.speechrecog.speechrecog;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.media.AudioManager;
import android.os.Binder;
import android.os.IBinder;
import android.speech.SpeechRecognizer;
import android.speech.tts.TextToSpeech;
import android.support.v4.app.NotificationCompat;
import android.util.Log;
import android.widget.Toast;

import es.udc.iagolast.speechrecog.speechrecog.speechListener.Listener;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.MainVt.VtMain;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;

public class SpeechRecognitionService extends Service implements TextToSpeech.OnInitListener {
    public final int ERROR = 0;
    public final int OK = 1;
    public final int LISTENING = 2;

    private int volume;  //Used to restore the volume to the original value.
    private Voicetivity currentVoicetivity;
    private static Intent serviceIntent = null;
    private SpeechRecognizer speechRecognizer = null;
    private TextToSpeech textToSpeech;
    private final IBinder sBinder = (IBinder) new SimpleBinder();
    private String TAG = "SERVICE";
    private int NOTIFICATION_ID = 1337;

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
        startForeground(NOTIFICATION_ID, buildNofification(Color.GREEN));
    }

    @Override
    public void onDestroy() {
        Log.d(TAG, "onDestroy");
        destroyService();
        super.onDestroy();
    }

    private void destroyService() {
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


    private Notification buildNofification(int color) {
        NotificationCompat.Builder mNotifyBuilder = new NotificationCompat.Builder(this)
                .setContentTitle("Ziri")
                .setContentText("Ziri se esta ejecutando.")
                .setSmallIcon(R.drawable.ic_launcher)
                .setLights(color, 2000, 100)
                .setAutoCancel(false);
        return mNotifyBuilder.build();
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
            notify(OK);
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
            notify(ERROR);
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
        notify(LISTENING);
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

    public void notify(int code) {
        NotificationManager notificationManager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        switch (code) {
            case ERROR:
                notificationManager.notify(NOTIFICATION_ID, buildNofification(Color.RED));
                break;
            case OK:
                notificationManager.notify(NOTIFICATION_ID, buildNofification(Color.BLUE));
                break;
            case LISTENING:
                notificationManager.notify(NOTIFICATION_ID, buildNofification(Color.GREEN));

        }
    }

    class SimpleBinder extends Binder {
        SpeechRecognitionService getService() {
            return SpeechRecognitionService.this;
        }
    }

}
