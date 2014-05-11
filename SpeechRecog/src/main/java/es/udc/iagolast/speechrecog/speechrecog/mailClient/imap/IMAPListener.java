package es.udc.iagolast.speechrecog.speechrecog.mailClient.imap;

import android.content.res.Resources;
import android.util.Log;

import org.apache.commons.fileupload.util.mime.MimeUtility;
import org.apache.commons.net.ProtocolCommandEvent;
import org.apache.commons.net.ProtocolCommandListener;
import org.apache.commons.net.imap.IMAPClient;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.Map;

class IMAPListener implements ProtocolCommandListener {

    IMAPMailClient iface;
    IMAPClient client;
    private Map<Integer, IMAPMail> mailsToComplete;

    public IMAPListener(IMAPMailClient iface, IMAPClient client) {
        this.iface = iface;
        this.client = client;
        this.mailsToComplete = new HashMap<Integer, IMAPMail>();
    }

    @Override
    public void protocolCommandSent(ProtocolCommandEvent protocolCommandEvent) {
    }

    /**
     * Receives the UID list of available Mails, asks for more data.
     *
     * @param message The raw message received
     */
    private void receiveMailEnumeration(String message){
        String uidSeq = message.substring(9);
        Log.d("IMAPListener/SpeechRecog", "--> " + uidSeq);
        for (String uid : uidSeq.split("\\s")) {
            try {
                Log.d("IMAPListener/SpeechRecog", "UID " + uid);
                Integer iuid = Integer.parseInt(uid);
                mailsToComplete.put(iuid, new IMAPMail());
                client.fetch(uid, "FLAGS");
                client.fetch(uid, "BODY.PEEK[HEADER.FIELDS (Subject)]");
                client.fetch(uid, "BODY.PEEK[HEADER.FIELDS (From)]");
                client.fetch(uid, "BODY.PEEK[TEXT]");
            } catch (IOException e) {
                e.printStackTrace();
            } catch (NumberFormatException e) {
            }
        }
    }


    private String extractFromField(String message){
        try {
            return MimeUtility.decodeText(message.split("\n")[1])
                    .split(":", 2)[1];
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
            try{
                return message.split("\n")[1].split(":", 2)[1];
            } catch (IndexOutOfBoundsException ioobe){
                return message.split("\n")[1];
            }
        } catch (IndexOutOfBoundsException e) {
            return "Sin remitente"; /// @TODO: Extract string
        }
    }


    private String extractSubjectField(String message){
        try {
            return MimeUtility.decodeText(message.split("\n")[1])
                    .split(":", 2)[1];
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
            try{
                return message.split("\n")[1].split(":", 2)[1];
            } catch (IndexOutOfBoundsException ioobe){
                return message.split("\n")[1];
            }
        } catch (IndexOutOfBoundsException e) {
            return "Sin asunto"; /// @TODO: Extract string
        }
    }


    private boolean isFlagSeenSet(String message){
        return message.split("\n")[0].toUpperCase().contains("SEEN");
    }


    private String extractMailBody(String message){
        String[] lines = message.split("\n");
        int l = lines.length - 1;
        StringBuilder builder = new StringBuilder(l - 1);
        for (int i = 1; i < l; i++) {
            if (i > 1) {
                builder.append("\n");
            }
            builder.append(lines[i]);
        }
        try {
            return MimeUtility.decodeText(builder.toString());
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
            return builder.toString();
        }
    }


    /**
     * Receives an email field and stores it in the Mail object.
     *
     * @param message
     */
    private void receiveMailField(String message){
        int uid = -1;
        try {
            uid = Integer.parseInt(message.split(" ")[1]);
        } catch (IndexOutOfBoundsException e){
            Log.e("IMAPClient/SpeechRecognizer", "Invalid FETCH line: " + message);
            return;
        } catch(NumberFormatException e){
            Log.e("IMAPClient/SpeechRecognizer", "Invalid FETCH line, UID not found: " + message);
            return;
        }

        IMAPMail mail= mailsToComplete.get(uid);
        if (mail == null){
            Log.w("IMAPClient/SpeechRecognizer", "UID \"" + uid + "\" not found");
            return;
        }

        if (message.split("\n")[0].toUpperCase().contains("FROM")) {
            mail.setFrom(extractFromField(message));
        } else if (message.split("\n")[0].toUpperCase().contains("SUBJECT")) {
            mail.setSubject(extractSubjectField(message));
        } else if (message.split("\n")[0].toUpperCase().contains("TEXT")) {
            mail.setBody(extractMailBody(message));
        } else if (message.split("\n")[0].toUpperCase().contains("FLAGS")) {
            mail.setRead(isFlagSeenSet(message));
        }

        // Mail completed, pass it around
        if ((mail.getRead() != null) && (mail.getFrom() != null)
         && (mail.getSubject() != null) && (mail.getBody() != null)) {

            Log.d("IMAPListener/SpeechRecog",
                    "Added mail, read? " + mail.getRead()
                    + " Subject: " + mail.getSubject());

            iface.addMail(mail);
            mailsToComplete.remove(uid);
        }
    }


    @Override
    public void protocolReplyReceived(ProtocolCommandEvent event) {
        String message = event.getMessage();
        Log.d("IMAPListener/SpeechRecog", event.getReplyCode() + " || " +
                message.substring(0, Math.min(100, message.length())));

        // Messages in folder
        if (message.startsWith("* SEARCH")) {
            receiveMailEnumeration(message);
        } else if (message.contains(" FETCH ")) {
            receiveMailField(message);
        }

    }

}