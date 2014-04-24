package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;


public class MailVtInitialState implements MailVoicetivityState {

    private MailVoicetivity voicetivity;

    public MailVtInitialState(MailVoicetivity voicetivity) {
        this.voicetivity = voicetivity;

    }


    @Override
    public void processSpeech(String speech) {

    }
}
