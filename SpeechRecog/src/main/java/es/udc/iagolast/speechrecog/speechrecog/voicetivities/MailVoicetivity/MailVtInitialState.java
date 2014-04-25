package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;


import android.speech.tts.TextToSpeech;

import es.udc.iagolast.speechrecog.speechrecog.R;

public class MailVtInitialState implements MailVoicetivityState {

    private MailVoicetivity voicetivity;


    public MailVtInitialState(MailVoicetivity voicetivity) {
        this.voicetivity = voicetivity;

    }

    @Override
    public void processSpeech(String speech) {

        if (speech.equalsIgnoreCase(String.valueOf(R.string.Speech_Keyword_Check_Mail))) {

            if (voicetivity.mailClient.hasUnreadMail()) {
                voicetivity.tts.speak(String.valueOf(R.string.Speech_Keyword_Unread_Mail), TextToSpeech.QUEUE_FLUSH, null);
                voicetivity.state = new MailVtStateOne(voicetivity);

            } else
                voicetivity.tts.speak(String.valueOf(R.string.Speech_Response_Non_Unread_Mail), TextToSpeech.QUEUE_FLUSH, null);

        } else if (speech.equalsIgnoreCase(String.valueOf(R.string.Speech_Keyword_Write_Mail))) {
            //TODO
        } else
            voicetivity.tts.speak(String.valueOf(R.string.Speech_Response_Dont_Understand), TextToSpeech.QUEUE_FLUSH, null);


    }
}
