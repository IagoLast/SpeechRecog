package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;


import android.speech.tts.TextToSpeech;

import es.udc.iagolast.speechrecog.speechrecog.R;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;

public class MailVtStateTwo implements MailVoicetivityState {

    private MailVoicetivity voicetivity;
    private Boolean firstIteration = true;
    private Mail mail;


    public MailVtStateTwo(MailVoicetivity voicetivity) {
        this.voicetivity = voicetivity;
    }

    @Override
    public void processSpeech(String speech) {

        if (voicetivity.mailClient.hasUnreadMail() || mail != null) {
            if (firstIteration) {
                firstIteration = false;
                mail = voicetivity.mailClient.getNextMail();

                voicetivity.tts.speak(String.valueOf(R.string.Speech_Response_Mail_From) + mail.getFrom() + String.valueOf(R.string.Speech_Response_Mail_From_End)
                        , TextToSpeech.QUEUE_FLUSH, null);
            }

            if (speech.equalsIgnoreCase(String.valueOf(R.string.Speech_Keyword_Yes))) {
                //StateThree
            } else if (speech.equalsIgnoreCase(String.valueOf(R.string.Speech_Keyword_No))) {
                voicetivity.state = new MailVtStateTwo(voicetivity);
            } else
                voicetivity.tts.speak(String.valueOf(R.string.Speech_Response_Dont_Understand), TextToSpeech.QUEUE_FLUSH, null);


        } else {
            voicetivity.tts.speak(String.valueOf(R.string.Speech_Response_No_More_Unread_Mail), TextToSpeech.QUEUE_FLUSH, null);
            voicetivity.state = new MailVtInitialState(voicetivity);
        }
    }
}