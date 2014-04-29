package es.udc.iagolast.speechrecog.speechrecog.mailClient.imap;

import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;

public class IMAPMail extends Mail {
    private Boolean read;

    public IMAPMail(String subject, String from, String body, boolean read) {
        super(subject, from, body);
        this.read = read;
    }

    public Boolean getRead() {
        return read;
    }

}
