package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;


import android.content.Context;
import android.speech.tts.TextToSpeech;

import es.udc.iagolast.speechrecog.speechrecog.R;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.MailClient;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.mock.MailClientMock;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;

public class MailVoicetivity implements Voicetivity {

    protected Context service;
    protected MailVoicetivityState state;
    protected MailClient mailClient;
    protected TextToSpeech tts;

    public MailVoicetivity(Context service, TextToSpeech tts) {

        this.service = service;
        this.tts = tts;
        state = new MailVtInitialState(this);
        mailClient = new MailClientMock();
    }

    @Override
    public void processSpeech(String speech) {

        if (!speech.equalsIgnoreCase(String.valueOf(R.string.Speech_Keyword_Salir))) {
            state.processSpeech(speech);
        }
    }
}
