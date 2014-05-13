package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;


public interface MailVoicetivityState {

    public void processSpeech(String speech);

    public void onHelpRequest();

}
