package es.udc.iagolast.speechrecog.speechrecog.voicetivities.NaiveVt;

import android.app.SearchManager;
import android.content.Context;
import android.content.Intent;
import android.provider.MediaStore;
import android.util.Log;

import es.udc.iagolast.speechrecog.speechrecog.voicetivities.Voicetivity;

/**
 * Created by iagolast on 18/04/14.
 */
public class VtNaive implements Voicetivity {
    protected Context service;

    public VtNaive(Context context) {
        this.service = context;
    }

    @Override
    public void processSpeech(String speech) {
        if (speech.equalsIgnoreCase("sacar foto")) {
            Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            service.startActivity(intent);
        } else if (speech.equalsIgnoreCase("grabar video")) {
            Intent intent = new Intent(MediaStore.ACTION_VIDEO_CAPTURE);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            service.startActivity(intent);
        } else if (speech.matches("buscar .*")) {
            String query = speech.substring(speech.indexOf(" "));
            Log.d("Buscando:", query);
            Intent intent = new Intent(Intent.ACTION_WEB_SEARCH);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            intent.putExtra(SearchManager.QUERY, query);
            service.startActivity(intent);
        }
    }
}
