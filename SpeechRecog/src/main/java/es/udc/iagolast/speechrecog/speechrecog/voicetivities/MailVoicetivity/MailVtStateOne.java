package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;


public class MailVtStateOne implements MailVoicetivityState {

    private MailVoicetivity voicetivity;

    public MailVtStateOne(MailVoicetivity voicetivity) {
        this.voicetivity = voicetivity;

    }


    @Override
    public void processSpeech(String speech) {

    }
}
