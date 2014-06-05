package es.udc.iagolast.speechrecog.speechrecog.voicetivities;

import es.udc.iagolast.speechrecog.speechrecog.SpeechRecognitionService;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.MainVt.VtMain;

/**
 * Created by iagolast on 11/04/14.
 * <p/>
 * This is a Sample Voicetivity that only repeats what the user said.
 */
public class VtParrot implements Voicetivity {
    private SpeechRecognitionService service;

    public VtParrot(SpeechRecognitionService service) {
        this.service = service;
    }

    @Override
    public void processSpeech(String speech) {
        if (speech.equalsIgnoreCase("Salir")) {
            service.speak("saliendo.");
            service.setCurrentVoicetivity(new VtMain(service));
        } else {
            service.speak(speech);
        }
    }

    @Override
    public String getIconName() {
        return "ic_parrot";
    }

    @Override
    public String getName() {
        return "Parrot";
    }

    @Override
    public String getDesc() {
        return "Repeat every thing that you say";
    }

}