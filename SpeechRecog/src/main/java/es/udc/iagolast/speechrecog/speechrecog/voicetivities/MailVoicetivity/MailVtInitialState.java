package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;


import android.content.res.Resources;
import android.speech.tts.TextToSpeech;
import android.util.Log;

import es.udc.iagolast.speechrecog.speechrecog.R;

public class MailVtInitialState implements MailVoicetivityState {

    private MailVoicetivity voicetivity;
    private Resources res;


    public MailVtInitialState(MailVoicetivity voicetivity) {
        this.voicetivity = voicetivity;
        res = voicetivity.service.getResources();

    }

    @Override
    public void processSpeech(String speech) {

        Log.d("INIT STATE", "IN");

        if (speech.equalsIgnoreCase(res.getString(R.string.Speech_Keyword_Check_Mail))) {

            if (voicetivity.mailClient.hasUnreadMail()) {
                voicetivity.tts.speak(res.getString(R.string.Speech_Keyword_Unread_Mail), TextToSpeech.QUEUE_FLUSH, null);
                voicetivity.state = new MailVtStateOne(voicetivity);

            } else
                voicetivity.tts.speak(res.getString(R.string.Speech_Response_Non_Unread_Mail), TextToSpeech.QUEUE_FLUSH, null);

        } else if (speech.equalsIgnoreCase(res.getString(R.string.Speech_Keyword_Write_Mail))) {
            //TODO
            voicetivity.tts.speak("Función no implementada aún.", TextToSpeech.QUEUE_FLUSH, null);

        } else
            voicetivity.tts.speak(res.getString(R.string.Speech_Response_Dont_Understand), TextToSpeech.QUEUE_FLUSH, null);


    }
}
