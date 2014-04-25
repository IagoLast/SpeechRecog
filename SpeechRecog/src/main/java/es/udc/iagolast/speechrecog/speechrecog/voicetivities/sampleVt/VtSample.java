package es.udc.iagolast.speechrecog.speechrecog.voicetivities.sampleVt;

import android.content.Context;
import android.content.Intent;
import android.provider.MediaStore;
import android.speech.tts.TextToSpeech;

import es.udc.iagolast.speechrecog.speechrecog.voicetivities.State;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;

/**
 * Created by iagolast on 12/04/14.
 */
public class VtSample implements Voicetivity {
    State state;
    protected TextToSpeech textToSpeech;
    protected Context service;

    public VtSample(TextToSpeech textToSpeech, Context service) {
        this.textToSpeech = textToSpeech;
        this.service = service;
        state = new StateOne(this);
    }

    @Override
    public void processSpeech(String speech) {
        state.processSpeech(speech);
    }

    @Override
    public String getIconName() {
        return "ic_launcher";
    }

    @Override
    public String getName() {
        return "Ziri";
    }

    @Override
    public String getDesc() {
        return "Main voicetivity";
    }

    public void speak(String text) {
        textToSpeech.speak(text, TextToSpeech.QUEUE_FLUSH, null);
    }

};

class StateOne implements State {
    private VtSample voicetivity;

    public StateOne(VtSample voicetivity) {
        this.voicetivity = voicetivity;
    }

    @Override
    public void processSpeech(String speech) {
        if (speech.equalsIgnoreCase("sacar foto")) {
            Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            voicetivity.service.startActivity(intent);
        } else if (speech.equalsIgnoreCase("tiempo")) {
            voicetivity.speak("¿Que ciudad quieres saber?");
            voicetivity.state = new StateTwo(voicetivity);
        } else if (speech.equalsIgnoreCase("futbol")) {
            voicetivity.speak("¿De qué equipo eres?");
            voicetivity.state = new StateThree(voicetivity);
        } else {
            voicetivity.speak("No quiero hablar de " + speech + ".");
        }
    }

};

class StateTwo implements State {
    private VtSample voicetivity;

    public StateTwo(VtSample voicetivity) {
        this.voicetivity = voicetivity;
    }

    @Override
    public void processSpeech(String speech) {
        if (speech.equalsIgnoreCase("vigo")) {
            voicetivity.speak("Hace frio en vigo.");

        } else if (speech.equalsIgnoreCase("coruña") || speech.equalsIgnoreCase("a coruña")) {
            voicetivity.speak("Llueve bastante en coruña.");

        } else {
            voicetivity.speak("No tengo ni idea de que tiempo hace en" + speech + ".");

        }
        voicetivity.state = new StateOne(voicetivity);
    }

};

class StateThree implements State {
    private VtSample voicetivity;

    public StateThree(VtSample voicetivity) {
        this.voicetivity = voicetivity;
    }

    @Override
    public void processSpeech(String speech) {
        if (speech.equalsIgnoreCase("barça") || speech.equalsIgnoreCase("barsa")) {
            voicetivity.speak("Me caes bien, yo tambien soy del barça.");
        } else if (speech.equalsIgnoreCase("madrid") || speech.equalsIgnoreCase("real madrid")) {
            voicetivity.speak("Me parece que deberíamos hablar de otra cosa.");
        } else {
            voicetivity.speak("No tengo ni idea de que equipo es ese.");
        }
        voicetivity.state = new StateOne(voicetivity);
    }

};


