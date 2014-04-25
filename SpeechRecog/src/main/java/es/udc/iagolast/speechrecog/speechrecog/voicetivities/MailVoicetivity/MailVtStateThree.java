package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;

import android.content.res.Resources;

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
        //TODO
    }


    private void init() {

        voicetivity.speak(mail.getBody(), true);

    }
}