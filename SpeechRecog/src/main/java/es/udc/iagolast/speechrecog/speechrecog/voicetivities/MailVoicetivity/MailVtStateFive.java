package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;

import android.content.res.Resources;

import es.udc.iagolast.speechrecog.speechrecog.R;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;

public class MailVtStateFive implements MailVoicetivityState {

    private VtMail voicetivity;
    private Mail mail;
    private Resources res;

    MailVtStateFive(VtMail voicetivity) {
        this.voicetivity = voicetivity;
        res = voicetivity.service.getResources();
        this.init();

    }

    @Override
    public void processSpeech(String speech) {

        if (speech.matches(res.getString(R.string.Speech_Keyword_Yes))) {
            voicetivity.speak(mail.getBody(), false);
            nextMail();
        } else if (speech.matches(res.getString(R.string.Speech_Keyword_No))) {
            nextMail();

        } else if (speech.matches(res.getString(R.string.Speech_Keyword_Exit))) {
            voicetivity.state = new MailVtInitialState(voicetivity);

        } else voicetivity.speak(res.getString(R.string.Speech_Response_Dont_Understand), false);


    }

    @Override
    public void onHelpRequest() {
        readMailInfo(mail);
        voicetivity.speak(res.getString(R.string.Speech_Help_Response_ReadMail_Afirmative), false);
        voicetivity.speak(res.getString(R.string.Speech_Help_Response_ReadMail_Negative), false);
        voicetivity.speak(res.getString(R.string.Speech_Help_Response_Exit_State), false);
    }

    private void init() {
        nextMail();

    }

    private void nextMail() {
        mail = voicetivity.mailClient.getNextMail();
        if (mail != null) {
            readMailInfo(mail);
            voicetivity.speak(res.getString(R.string.Speech_Response_Mail_From_End), false);
        } else {
            voicetivity.speak(res.getString(R.string.Speech_Response_No_More_Mail), false);
            voicetivity.state = new MailVtInitialState(voicetivity);
        }

    }

    private void readMailInfo(Mail mail) {
        voicetivity.speak(res.getString(R.string.Speech_Response_Mail_From) + mail.getFrom() + res.getString(R.string.Speech_Response_Subject) + mail.getSubject(), false);

    }


}
