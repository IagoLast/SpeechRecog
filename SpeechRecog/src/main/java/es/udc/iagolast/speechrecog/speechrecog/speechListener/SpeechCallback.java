package es.udc.iagolast.speechrecog.speechrecog.speechListener;

/**
 * Created by iagolast on 16/03/14.
 */
public interface SpeechCallback {
    /**
     * Generic callback to define what to do with the detected text.
     * @param speech the words that the user has spoken processed
     */
    public void processSpeech(String speech);

    public void endOfSpeech();

}
