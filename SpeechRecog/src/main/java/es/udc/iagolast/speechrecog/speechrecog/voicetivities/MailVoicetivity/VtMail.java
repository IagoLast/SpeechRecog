package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;


import es.udc.iagolast.speechrecog.speechrecog.R;
import es.udc.iagolast.speechrecog.speechrecog.SpeechRecognitionService;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.MailClient;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.mock.MailClientMock;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.voicetivityManager.VoicetivityManager;

public class VtMail implements Voicetivity {

    protected SpeechRecognitionService service;
    protected MailVoicetivityState state;
    protected MailClient mailClient;

    public VtMail(SpeechRecognitionService service) {
        this.service = service;
        state = new MailVtInitialState(this);
        mailClient = new MailClientMock();
    }

    protected void speak(String speech, Boolean flush) {
        service.speak(speech, flush);
    }

    @Override
    public void processSpeech(String speech) {
        if (!speech.equalsIgnoreCase(service.getString(R.string.Speech_Keyword_Exit_Mail_Manager))) {
            state.processSpeech(speech);
        } else {
            service.speak(service.getString(R.string.Speech_Response_Leave_Mail_Voicetivity));
            service.setCurrentVoicetivity(VoicetivityManager.getInstance(service).getVoicetivity("Main"));
        }
    }

    @Override
    public String getIconName() {
        return "ic_mail";
    }

    @Override
    public String getName() {
        return "Mail Client";
    }

    @Override
    public String getDesc() {
        return "Lee tu correo solo por voz.";
    }
}
