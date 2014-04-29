package es.udc.iagolast.speechrecog.speechrecog.mailClient.imap;

import android.util.Log;

import org.apache.commons.fileupload.util.mime.MimeUtility;
import org.apache.commons.net.ProtocolCommandEvent;
import org.apache.commons.net.ProtocolCommandListener;
import org.apache.commons.net.imap.IMAPClient;
import org.apache.commons.net.imap.IMAPCommand;

import java.io.IOException;
import java.io.UnsupportedEncodingException;

import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;

class IMAPListener implements ProtocolCommandListener {

    IMAPMailClient iface;
    IMAPClient client;
    private String subject = null;
    private String from = null;
    private String text = null;
    private Boolean read = null;

    public IMAPListener(IMAPMailClient iface, IMAPClient client) {
        this.iface = iface;
        this.client = client;
    }

    @Override
    public void protocolCommandSent(ProtocolCommandEvent protocolCommandEvent) {
    }

    @Override
    public void protocolReplyReceived(ProtocolCommandEvent event) {
        String message = event.getMessage();
        Log.d("IMAPListener/SpeechRecog", event.getReplyCode() + " || " +
                message.substring(0, Math.min(100, message.length())));

        // Messages in folder
        if (message.startsWith("* SEARCH")){
            String uidSeq = message.substring(9);
            Log.d("IMAPListener/SpeechRecog", "--> " + uidSeq);
            for (String uid: uidSeq.split("\\s")){
                try {
                    Log.d("IMAPListener/SpeechRecog", "UID " + uid);
                    Integer.parseInt(uid);
                    client.fetch(uid, "FLAGS");
                    client.fetch(uid, "BODY.PEEK[HEADER.FIELDS (Subject)]");
                    client.fetch(uid, "BODY.PEEK[HEADER.FIELDS (From)]");
                    client.fetch(uid, "BODY.PEEK[TEXT]");
                } catch (IOException e) {
                    e.printStackTrace();
                }
                catch (NumberFormatException e){
                }
            }
        }
        else if (message.contains(" FETCH ")) {
            Log.d("IMAPClient/SpeechRecognizer", "?? " + message.split("\n")[0]);
            if (message.split("\n")[0].toUpperCase().contains("FROM")){
                try {
                    from = MimeUtility.decodeText(message.split("\n")[1]);
                } catch (UnsupportedEncodingException e) {
                    e.printStackTrace();
                }
            }
            else if (message.split("\n")[0].toUpperCase().contains("SUBJECT")){
                try {
                    subject = MimeUtility.decodeText(message.split("\n")[1]);
                } catch (UnsupportedEncodingException e) {
                    e.printStackTrace();
                }
            }
            else if (message.split("\n")[0].toUpperCase().contains("TEXT")){
                String[] lines = message.split("\n");
                int l = lines.length - 1;
                StringBuilder builder = new StringBuilder(l - 1);
                for(int i = 1; i < l; i++){
                    if (i > 1){
                        builder.append("\n");
                    }
                    builder.append(lines[i]);
                }
                try {
                    text = MimeUtility.decodeText(builder.toString());
                } catch (UnsupportedEncodingException e) {
                    e.printStackTrace();
                }
            }
            else if (message.split("\n")[0].toUpperCase().contains("FLAGS")){
                read = message.split("\n")[0].toUpperCase().contains("SEEN");
            }

            /// @TODO use the UID to make sure the mail is assembled correctly
            if ((read != null) && (from != null) && (subject != null) && (text != null)){
                Mail mail = new Mail(subject, from, text, read);
                Log.d("IMAPListener/SpeechRecog", "Added mail, read? " + read
                                                + " Subject: " + subject);

                subject = from = text = null;
                read = null;
                iface.addMail(mail);
            }



        }
    }
}
