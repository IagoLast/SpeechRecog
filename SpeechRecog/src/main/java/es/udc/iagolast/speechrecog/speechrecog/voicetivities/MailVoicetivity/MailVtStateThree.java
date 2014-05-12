package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;

import android.content.res.Resources;
import android.util.Log;

import es.udc.iagolast.speechrecog.speechrecog.R;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;


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

        if (speech.equalsIgnoreCase(res.getString(R.string.Speech_Keyword_Yes))) {
            voicetivity.state = new MailVtStateFour(voicetivity, mail);

        } else if (speech.equalsIgnoreCase(res.getString(R.string.Speech_Keyword_No))) {
            voicetivity.state = new MailVtStateTwo(voicetivity);

        } else voicetivity.speak(res.getString(R.string.Speech_Response_Dont_Understand), true);

    }


    private void init() {

        voicetivity.speak(mail.getBody(), true);
        voicetivity.speak(res.getString(R.string.Speech_Response_Ask_To_Reply), false);

    }
}