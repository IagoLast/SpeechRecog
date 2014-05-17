package es.udc.iagolast.speechrecog.speechrecog.mailClient.imap;

import android.util.Log;

import javax.mail.internet.MimeUtility;
import org.apache.commons.net.ProtocolCommandEvent;
import org.apache.commons.net.ProtocolCommandListener;
import org.apache.commons.net.imap.IMAPClient;
import org.htmlcleaner.HtmlCleaner;
import org.htmlcleaner.TagNode;

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
    private void receiveMailEnumeration(String message) {
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


    private String extractFromField(String message) {
        String text = message;
        try{
            text = text.split("\n")[1].split(":", 2)[1];
        } catch (IndexOutOfBoundsException e) {
            e.printStackTrace();
            return "Sin remitente"; /// @TODO: Extract string
        }
        text = text.trim();
        if (text.startsWith("\"") && text.endsWith("\""));{
            text = text.substring(1, text.length() - 1);
        }
        try {
            text = MimeUtility.decodeText(text);
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return text;
    }


    private String extractSubjectField(String message) {
        String text = message;
        try{
            text = text.split("\n")[1].split(":", 2)[1];
        } catch (IndexOutOfBoundsException e) {
            e.printStackTrace();
            return "Sin asunto"; /// @TODO: Extract string
        }
        text = text.trim();
        if (text.startsWith("\"") && text.endsWith("\""));{
            text = text.substring(1, text.length() - 1);
        }
        try {
            text = MimeUtility.decodeText(text);
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return text;
    }


    private boolean isFlagSeenSet(String message) {
        return message.split("\n")[0].toUpperCase().contains("SEEN");
    }


    private String extractMailBody(String message) {
        String[] lines = message.split("\n");
        int l = lines.length - 1;
        String body;

        StringBuilder builder = new StringBuilder(l - 1);
        for (int i = 1; i < l; i++) {
            if (i > 1) {
                builder.append("\n");
            }
            builder.append(lines[i]);
        }
        try {
            body = MimeUtility.decodeText(builder.toString());
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
            body = builder.toString();
        }

        return extractHTMLText(body);
    }

    private String extractHTMLText(String html) {
        HtmlCleaner cleaner = new HtmlCleaner();
        TagNode node = cleaner.clean(html);

        return String.valueOf(node.getText());
    }


    /**
     * Receives an email field and stores it in the Mail object.
     *
     * @param message
     */
    private void receiveMailField(String message) {
        int uid = -1;
        try {
            uid = Integer.parseInt(message.split(" ")[1]);
        } catch (IndexOutOfBoundsException e) {
            Log.e("IMAPClient/SpeechRecognizer", "Invalid FETCH line: " + message);
            return;
        } catch (NumberFormatException e) {
            Log.e("IMAPClient/SpeechRecognizer", "Invalid FETCH line, UID not found: " + message);
            return;
        }

        IMAPMail mail = mailsToComplete.get(uid);
        if (mail == null) {
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
                            + " Subject: " + mail.getSubject()
            );

            iface.addMail(mail);
            mailsToComplete.remove(uid);
        }
    }


    @Override
    public void protocolReplyReceived(ProtocolCommandEvent event) {
        String message = event.getMessage();
        Log.d("IMAPListener/SpeechRecog", event.getReplyCode() + " || " +
                message.substring(0, Math.min(100, message.length())) + "...");

        // Messages in folder
        if (message.startsWith("* SEARCH")) {
            receiveMailEnumeration(message);
        } else if (message.contains(" FETCH ")) {
            receiveMailField(message);
        }

    }

}
