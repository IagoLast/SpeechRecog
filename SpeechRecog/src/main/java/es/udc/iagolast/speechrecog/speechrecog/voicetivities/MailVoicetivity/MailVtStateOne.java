package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;


import android.content.res.Resources;
import android.speech.tts.TextToSpeech;
import android.util.Log;

import es.udc.iagolast.speechrecog.speechrecog.R;

public class MailVtStateOne implements MailVoicetivityState {

    private MailVoicetivity voicetivity;
    private Resources res;


    public MailVtStateOne(MailVoicetivity voicetivity) {
        this.voicetivity = voicetivity;
        res = voicetivity.service.getResources();
    }


    @Override
    public void processSpeech(String speech) {

        Log.d("STATE 1", "IN");

        if (speech.equalsIgnoreCase(res.getString(R.string.Speech_Keyword_Yes))) {
            voicetivity.state = new MailVtStateTwo(voicetivity);


        } else if (speech.equalsIgnoreCase(res.getString(R.string.Speech_Keyword_No))) {
            voicetivity.state = new MailVtInitialState(voicetivity);

        } else
            voicetivity.tts.speak(res.getString(R.string.Speech_Response_Dont_Understand), TextToSpeech.QUEUE_FLUSH, null);


    }
}
