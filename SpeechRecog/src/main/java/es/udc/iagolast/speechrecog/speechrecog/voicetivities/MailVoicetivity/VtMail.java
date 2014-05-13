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
        /**   SharedPreferences sharedPreferences = service.getSharedPreferences("ziriPrefs", Context.MODE_PRIVATE);
         String username = sharedPreferences.getString("mail", "");
         String password = sharedPreferences.getString("password", "");
         mailClient = new IMAPMailClient(username, password, "imap.gmail.com", 993);**/
        mailClient = new MailClientMock();
        state = new MailVtInitialState(this);

    }

    protected void speak(String speech, Boolean flush) {
        service.speak(speech, flush);
    }

    @Override
    public void processSpeech(String speech) {
        if (speech.matches(service.getString(R.string.Speech_Keyword_Exit_Mail_Manager))) {
            service.speak(service.getString(R.string.Speech_Response_Leave_Mail_Voicetivity));
            service.setCurrentVoicetivity(VoicetivityManager.getInstance(service).getVoicetivity("Main"));
        } else if (speech.matches(service.getString(R.string.Speech_Keyword_Help_Request))) {
            state.onHelpRequest();

        } else if (speech.equalsIgnoreCase(service.getResources().getString(R.string.Speech_Keyword_Exit))) {
            state = new MailVtInitialState(this);
            service.speak(service.getResources().getString(R.string.Speech_Response_Exiting));
        } else state.processSpeech(speech);
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
