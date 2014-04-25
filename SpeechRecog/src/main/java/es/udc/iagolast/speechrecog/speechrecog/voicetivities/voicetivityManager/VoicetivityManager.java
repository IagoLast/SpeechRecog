package es.udc.iagolast.speechrecog.speechrecog.voicetivities.voicetivityManager;

import android.util.Log;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import es.udc.iagolast.speechrecog.speechrecog.SpeechRecognitionService;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.NaiveVt.VtNaive;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;
import es.udc.iagolast.speechrecog.speechrecog.voicetivities.VtParrot;

/**
 * Created by iagolast on 25/04/14.
 */
public class VoicetivityManager {
    private static VoicetivityManager INSTANCE = null;
    private SpeechRecognitionService service;
    private Map<String, Voicetivity> voicetivityMap;

    // Private constructor suppresses
    private VoicetivityManager(SpeechRecognitionService service) {
        this.service = service;
        voicetivityMap = new HashMap<String, Voicetivity>();
        voicetivityMap.put("Main", new VtNaive(this.service));
        voicetivityMap.put("Parrot", new VtParrot(this.service));
    }

    public static VoicetivityManager getInstance(SpeechRecognitionService service) {
        if (service == null) {
            Log.e("ERROR", "null service");
        }
        if (INSTANCE == null) {
            INSTANCE = new VoicetivityManager(service);
        }
        return INSTANCE;
    }

    public void registerVoicetivity(Voicetivity voicetivity) {
        voicetivityMap.put(voicetivity.getName(), voicetivity);
    }

    public Voicetivity getVoicetivity(String name) {
        return voicetivityMap.get(name);
    }

    public List<Voicetivity> getVoicetivityList() {
        List<Voicetivity> voicetivityList = new ArrayList<Voicetivity>();
        for (Map.Entry<String, Voicetivity> entry : voicetivityMap.entrySet()) {
            voicetivityList.add(entry.getValue());
        }
        return voicetivityList;
    }
}
