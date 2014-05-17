package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;

import android.content.res.Resources;

import es.udc.iagolast.speechrecog.speechrecog.R;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;

public class MailVtStateSix implements MailVoicetivityState {

    private Mail mail;
    private VtMail voicetivity;
    private Resources res;


    public MailVtStateSix(VtMail voicetivity, Mail mail) {
        this.voicetivity = voicetivity;
        this.mail = mail;
        res = voicetivity.service.getResources();
        this.init();

    }

    @Override
    public void processSpeech(String speech) {

        if (speech.matches(res.getString(R.string.Speech_Keyword_Yes))) {
            if (voicetivity.mailClient.sendMail(mail)) {
                voicetivity.speak(res.getString(R.string.Speech_Response_Mail_Sent_OK), false);
            } else voicetivity.speak(res.getString(R.string.Speech_Response_Mail_Sent_Fail), false);
            voicetivity.state = new MailVtStateTwo(voicetivity);

        } else if (speech.matches(res.getString(R.string.Speech_Keyword_No))) {
            voicetivity.state = new MailVtStateFour(voicetivity, mail, false);

        } else voicetivity.speak(res.getString(R.string.Speech_Response_Dont_Understand), false);

    }

    @Override
    public void onHelpRequest() {
        voicetivity.speak(res.getString(R.string.Speech_Help_Response_Send_Mail), false);
        voicetivity.speak(res.getString(R.string.Speech_Help_Response_Rewrite), false);


    }

    public void init() {

        voicetivity.speak(res.getString(R.string.Speech_Response_Reading_Mail), false);
        voicetivity.speak(mail.getBody(), false);
    }
}
