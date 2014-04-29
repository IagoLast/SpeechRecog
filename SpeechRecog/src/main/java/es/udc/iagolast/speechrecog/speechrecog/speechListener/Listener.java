package es.udc.iagolast.speechrecog.speechrecog.speechListener;

import android.os.Bundle;
import android.speech.RecognitionListener;
import android.speech.SpeechRecognizer;
import android.util.Log;

import java.util.ArrayList;

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
    private SpeechRecognitionService speechRecognitionService;

    public Listener(SpeechRecognitionService callback) {
        this.speechRecognitionService = callback;
    }

    /**
     * Gets the first String from the results and passes it to the callback.
     *
     * @param results
     */
    public void onResults(Bundle results) {
        Log.d("Listener", "onResults");
        ArrayList<String> data = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
        String speech = data.get(0);
        speechRecognitionService.processSpeech(speech);
    }

    /**
     * If error happens just call Service.onError()
     *
     * @param error
     */
    public void onError(int error) {
        Log.d("Listener", "Error " + error);
        speechRecognitionService.onError();
    }


    public void onReadyForSpeech(Bundle params) {
        Log.d("Listener", "onReadyForSpeech (Audio ON)");
        speechRecognitionService.unMuteAudio();
    }

    public void onEndOfSpeech() {
        Log.d("Listener", "onEndOfSpeech");
    }

    public void onBeginningOfSpeech() {
        Log.d("Listener", "onBeggining");
    }

    public void onPartialResults(Bundle partialResults) {
        Log.d("Listener", "onPartialResults");
    }

    public void onEvent(int eventType, Bundle params) {
        Log.d("Listener", "onEvent " + eventType);
    }

    public void onRmsChanged(float rmsdB) {
    }

    public void onBufferReceived(byte[] buffer) {
    }
}

