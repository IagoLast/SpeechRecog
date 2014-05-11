package es.udc.iagolast.speechrecog.speechrecog;

import android.app.Activity;
import android.content.SharedPreferences;
import android.os.AsyncTask;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import es.udc.iagolast.speechrecog.speechrecog.mailClient.imap.IMAPMailClient;

public class SettingsActivity extends Activity {
    SharedPreferences sharedPreferences;
    EditText editTextMail;
    EditText editTextPassword;
    Button butSavePrefs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_settings);
        loadUI();
    }

    @Override
    protected void onStop() {
        super.onStop();
    }

    protected void loadUI() {
        sharedPreferences = getSharedPreferences("ziriPrefs", MODE_PRIVATE);
        editTextMail = (EditText) findViewById(R.id.editText);
        editTextPassword = (EditText) findViewById(R.id.editText2);
        butSavePrefs = (Button) findViewById(R.id.but_save_prefs);

        populateUI();
    }

    private void populateUI() {
        String mail = sharedPreferences.getString("mail", "email");
        String password = sharedPreferences.getString("password", "password");

        if (mail.equals("email")) {
            editTextMail.setHint("email");
        } else {
            editTextMail.setText(mail);
        }
        if (password.equals("password")) {
            editTextPassword.setHint("password");
        } else {
            editTextPassword.setText(password);
        }
    }


    public void checkPreferences(View v){
        final String username = editTextMail.getText().toString();
        final String password = editTextPassword.getText().toString();

        butSavePrefs.setText(R.string.checking_credentials);
        new AsyncTask<Void, Void, Boolean>(){
            @Override
            protected Boolean doInBackground(Void... voids) {
                return IMAPMailClient.checkCredentials(username, password,
                                                       "imap.gmail.com", 993);
            }

            @Override
            protected void onPostExecute(Boolean validCredentials){
                butSavePrefs.setText(getString(R.string.save_preferences));
                if (validCredentials == null) {
                    Log.e("SpeechRecog/SettingsActivity", "NULL can't be returned here!");
                } else if (validCredentials){
                    savePreferences(username, password);
                } else {
                    Toast.makeText(SettingsActivity.this, getString(R.string.invalid_user_pass),
                                   Toast.LENGTH_SHORT).show();
                }
            }
        }.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);

    }


    private void savePreferences(String mail, String password) {

        if (!TextUtils.isEmpty(mail) && !TextUtils.isEmpty(password)) {
            sharedPreferences.edit().putString("mail", mail).commit();
            sharedPreferences.edit().putString("password", password).commit();
            Toast.makeText(this, "Preferencias actualizadas", Toast.LENGTH_SHORT).show();
        }
    }
}
