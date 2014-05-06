package es.udc.iagolast.speechrecog.speechrecog;

import android.app.Activity;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.text.TextUtils;
import android.widget.EditText;
import android.widget.Toast;

public class SettingsActivity extends Activity {
    SharedPreferences sharedPreferences;
    EditText editTextMail;
    EditText editTextPassword;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_settings);
        loadUI();
    }

    @Override
    protected void onStop() {
        savePreferences();
        super.onStop();
    }

    protected void loadUI() {
        sharedPreferences = getSharedPreferences("ziriPrefs", MODE_PRIVATE);
        editTextMail = (EditText) findViewById(R.id.editText);
        editTextPassword = (EditText) findViewById(R.id.editText2);

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


    private void savePreferences() {
        String mail = editTextMail.getText().toString();
        String password = editTextPassword.getText().toString();

        if (!TextUtils.isEmpty(mail) && !TextUtils.isEmpty(password)) {
            sharedPreferences.edit().putString("mail", mail).commit();
            sharedPreferences.edit().putString("password", password).commit();
            Toast.makeText(this, "Preferencias actualizadas", Toast.LENGTH_SHORT).show();
        }
    }
}
