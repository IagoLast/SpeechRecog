package es.udc.iagolast.speechrecog.speechrecog.voicetivities.VtMail;

import android.content.res.Resources;
import android.util.Log;

import es.udc.iagolast.speechrecog.speechrecog.R;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.VtMail.mailClient.Mail;


public class MailVtStateThree implements MailVoicetivityState {

    private VtMail voicetivity;
    private Mail mail;
    private Resources res;


    public MailVtStateThree(VtMail voicetivity, Mail mail) {
        this.voicetivity = voicetivity;
        this.mail = mail;
        res = voicetivity.service.getResources();
        this.init();
    }


    @Override
    public void processSpeech(String speech) {
        Log.d("State 3", "IN");

        if (speech.matches(res.getString(R.string.Speech_Keyword_Yes))) {
            voicetivity.state = new MailVtStateFour(voicetivity, mail, true);

        } else if (speech.matches(res.getString(R.string.Speech_Keyword_No))) {
            voicetivity.state = new MailVtStateTwo(voicetivity);

        } else if (speech.equalsIgnoreCase(res.getString(R.string.Speech_Keyword_ReRead))) {
            readMail();

        } else {
            voicetivity.speak(res.getString(R.string.Speech_Response_Dont_Understand), true);

        }

    }

    @Override
    public void onHelpRequest() {
        voicetivity.speak(res.getString(R.string.Speech_Help_Response_ResponseMail_Afirmative), false);
        voicetivity.speak(res.getString(R.string.Speech_Help_Response_ResponseMail_Negative), false);
        voicetivity.speak(res.getString(R.string.Speech_Help_Response_ReReadMail), false);

    }

    private void readMail() {
        voicetivity.speak(mail.getBody(), true);

    }

    private void init() {
        readMail();
        voicetivity.speak(res.getString(R.string.Speech_Response_Ask_To_Reply), false);

    }
}