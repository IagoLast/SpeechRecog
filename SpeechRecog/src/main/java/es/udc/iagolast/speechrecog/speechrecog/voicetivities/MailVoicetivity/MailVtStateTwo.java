package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;


import android.content.res.Resources;
import android.util.Log;

import es.udc.iagolast.speechrecog.speechrecog.R;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;

public class MailVtStateTwo implements MailVoicetivityState {

    private VtMail voicetivity;
    private Mail mail;
    private Resources res;


    public MailVtStateTwo(VtMail voicetivity) {
        this.voicetivity = voicetivity;
        res = voicetivity.service.getResources();
        this.init();
    }

    @Override
    public void processSpeech(String speech) {

        Log.d("State 2", "IN");

        if (speech.equalsIgnoreCase(res.getString(R.string.Speech_Keyword_Exit)) || mail == null) {
            voicetivity.state = new MailVtInitialState(voicetivity);

        } else if (speech.matches(res.getString(R.string.Speech_Keyword_Yes))) {
            voicetivity.state = new MailVtStateThree(voicetivity, mail);

        } else if (speech.matches(res.getString(R.string.Speech_Keyword_No))) {
            getNextUnreadMail();

        } else
            voicetivity.speak(res.getString(R.string.Speech_Response_Dont_Understand), true);


    }

    @Override
    public void onHelpRequest() {
        if (mail != null) {
            voicetivity.speak(res.getString(R.string.Speech_Response_Mail_From) + mail.getFrom(), false);
            voicetivity.speak(res.getString(R.string.Speech_Help_Response_ReadUnreadMail_Afirmative), false);
            voicetivity.speak(res.getString(R.string.Speech_Help_Response_ReadUnreadMail_Negative), false);
        }
        voicetivity.speak(res.getString(R.string.Speech_Help_Response_ReadUnreadMail_Exit), false);

    }

    private void getNextUnreadMail() {

        mail = voicetivity.mailClient.getNextUnreadMail();

        if (mail != null) {
            voicetivity.speak(res.getString(R.string.Speech_Response_Mail_From) + mail.getFrom() + res.getString(R.string.Speech_Response_Subject) + mail.getSubject() + res.getString(R.string.Speech_Response_Mail_From_End), false);
        } else {
            voicetivity.speak(res.getString(R.string.Speech_Response_No_More_Unread_Mail), false);
            voicetivity.state = new MailVtInitialState(voicetivity);
        }

    }

    private void init() {
        getNextUnreadMail();

    }
}