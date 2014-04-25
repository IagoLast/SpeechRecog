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

        if (mail != null) {
            if (speech.equalsIgnoreCase(res.getString(R.string.Speech_Keyword_Yes))) {
                voicetivity.state = new MailVtStateThree(voicetivity, mail);

            } else if (speech.equalsIgnoreCase(res.getString(R.string.Speech_Keyword_No))) {
                voicetivity.state = new MailVtStateTwo(voicetivity);

            } else
                voicetivity.speak(res.getString(R.string.Speech_Response_Dont_Understand));

        } else {

            voicetivity.speak(res.getString(R.string.Speech_Response_No_More_Unread_Mail));
            voicetivity.state = new MailVtInitialState(voicetivity);
        }

    }

    public void init() {
        if (voicetivity.mailClient.hasUnreadMail()) {
            mail = voicetivity.mailClient.getNextMail();

            voicetivity.speak(res.getString(R.string.Speech_Response_Mail_From) + mail.getFrom() + res.getString(R.string.Speech_Response_Mail_From_End));

        } else mail = null;


    }
}