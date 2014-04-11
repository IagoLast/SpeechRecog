package es.udc.iagolast.speechrecog.speechrecog.speechListener;

import android.app.NotificationManager;
import android.content.Context;
import android.os.Bundle;
import android.speech.RecognitionListener;
import android.speech.SpeechRecognizer;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

import java.util.ArrayList;

import es.udc.iagolast.speechrecog.speechrecog.R;
import es.udc.iagolast.speechrecog.speechrecog.SpeechRecognitionService;

/**
 * Created by iagolast on 21/02/14.
 * <p/>
 * Esta clase es la que realmente escucha lo que el usuario dice.
 * Cuando esta escuchando añade una notificacion en la notif bar.
 * Cuando para de escuchar la elimina.
 * Cuando obtiene resultados se los pasa al service para que lo delegue a
 * su Voicetivity correspondiente.
 * Si hay un error avisa al servicio
 */
public class Listener implements RecognitionListener {
    private final int NOTIFICATION_ID = 02356;
    private SpeechRecognitionService speechRecognitionService;
    private Context context;
    private NotificationManager notificationManager;

    public Listener(SpeechRecognitionService callback, Context context) {
        this.speechRecognitionService = callback;
        this.context = context;
        // Gets an instance of the NotificationManager service
        notificationManager =
                (NotificationManager) context.getSystemService(context.NOTIFICATION_SERVICE);
    }

    /**
     * When starting to listen, add a notification.
     */
    public void onReadyForSpeech(Bundle params) {
        NotificationCompat.Builder mBuilder =
                new NotificationCompat.Builder(context)
                        .setSmallIcon(R.drawable.abc_ic_voice_search)
                        .setContentTitle("Escuchando Ordenes ")
                        .setContentText("");
        // Builds the notification and issues it.
        notificationManager.notify(NOTIFICATION_ID, mBuilder.build());
    }

    /**
     * Dismiss notification when speech ends.
     */
    public void onEndOfSpeech() {
        Log.d("SpeechRecognitionService", "onEndOfSpeech");
        notificationManager.cancel(NOTIFICATION_ID);
    }

    /**
     * When error happens, dimiss Listening notification.
     * If error is that there is no matches notify srcgService.
     *
     * @param error
     */
    public void onError(int error) {
        Log.d("SpeechRecognitionService", "Error " + error);
        notificationManager.cancel(NOTIFICATION_ID);
        switch (error) {
            case SpeechRecognizer.ERROR_NO_MATCH:
                speechRecognitionService.onNomatchesFound();
        }
    }

    /**
     * Gets the first String from the results and passes it to the callback.
     *
     * @param results
     */
    public void onResults(Bundle results) {
        Log.d("SpeechRecognitionService", "onResults");
        ArrayList<String> data = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
        String speech = data.get(0);
        speechRecognitionService.processSpeech(speech);
    }

    public void onBeginningOfSpeech() {
        Log.d("SpeechRecognitionService", "onBeggining");
    }

    public void onPartialResults(Bundle partialResults) {
        Log.d("SpeechRecognitionService", "onPartialResults");
    }

    public void onEvent(int eventType, Bundle params) {
        Log.d("SpeechRecognitionService", "onEvent " + eventType);
    }

    public void onRmsChanged(float rmsdB) {
    }

    public void onBufferReceived(byte[] buffer) {
    }
}

