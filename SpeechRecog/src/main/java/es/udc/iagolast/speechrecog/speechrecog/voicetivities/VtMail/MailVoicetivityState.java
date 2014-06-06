package es.udc.iagolast.speechrecog.speechrecog.voicetivities.VtMail;


public interface MailVoicetivityState {

    public void processSpeech(String speech);

    public void onHelpRequest();

}
