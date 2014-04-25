package es.udc.iagolast.speechrecog.speechrecog.voicetivities.MailVoicetivity;


import android.content.Context;

import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;

public class MailVoicetivity implements Voicetivity {

    protected Context service;
    protected MailVoicetivityState state;

    public MailVoicetivity(Context service) {
        this.service = service;
        state = new MailVtInitialState(this);

    }


    @Override
    public void processSpeech(String speech) {


        
        state.processSpeech(speech);


    }

    @Override
    public String getIconName() {
        return null;
    }

    @Override
    public String getName() {
        return null;
    }

    @Override
    public String getDesc() {
        return null;
    }
}
