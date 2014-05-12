package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;

import android.content.res.Resources;

import es.udc.iagolast.speechrecog.speechrecog.R;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;

public class MailVtStateFour implements MailVoicetivityState {

    private VtMail voicetivity;
    private Mail mail;
    private Resources res;
    private StringBuilder mailBody;

    private final String REPLY_STRING = "RE:";


    public MailVtStateFour(VtMail voicetivity, Mail mail) {
        this.voicetivity = voicetivity;
        this.mail = new Mail(REPLY_STRING + mail.getSubject(), mail.getTo(), mail.getFrom(), "");
        res = voicetivity.service.getResources();
        mailBody = new StringBuilder();

    }

    @Override
    public void processSpeech(String speech) {

        if (speech.equalsIgnoreCase(res.getString(R.string.Speech_Keyword_Stop_Writing_Mail))) {
            mail.setBody(mailBody.toString());
            if (voicetivity.mailClient.sendMail(mail)) {
                voicetivity.speak(res.getString(R.string.Speech_Response_Mail_Sent_OK), true);

            } else {
                voicetivity.speak(res.getString(R.string.Speech_Response_Mail_Sent_Fail), true);

            }

            voicetivity.state = new MailVtStateTwo(voicetivity);


        } else {
            mailBody.append(speech);
        }

    }
}
