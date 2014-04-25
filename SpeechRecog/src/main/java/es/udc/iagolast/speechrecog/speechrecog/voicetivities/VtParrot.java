package es.udc.iagolast.speechrecog.speechrecog.voicetivities;

import android.speech.tts.TextToSpeech;

/**
 * Created by iagolast on 11/04/14.
 * <p/>
 * This is a Sample Voicetivity that only repeats what the user said.
 */
public class VtParrot implements Voicetivity {
    private TextToSpeech textToSpeech;

    public VtParrot(TextToSpeech textToSpeech) {
        this.textToSpeech = textToSpeech;
    }

    @Override
    public void processSpeech(String speech) {
        textToSpeech.speak(speech, TextToSpeech.QUEUE_FLUSH, null);
    }

    @Override
    public String getIconName() {
        return "ic_parrot";
    }

    @Override
    public String getName() {
        return "Parrot";
    }

    @Override
    public String getDesc() {
        return "Repeat every thing that you say";
    }

}