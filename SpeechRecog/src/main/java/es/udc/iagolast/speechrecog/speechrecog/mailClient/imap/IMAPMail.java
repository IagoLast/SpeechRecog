package es.udc.iagolast.speechrecog.speechrecog.mailClient.imap;

import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;

public class IMAPMail extends Mail {
    private Boolean read;

    public IMAPMail(String subject, String from, String body, boolean read) {
        super(subject, from, body);
        this.read = read;
    }

    public IMAPMail() {
        super(null, null, null);
    }

    public Boolean getRead() {
        return read;
    }

    public void setRead(Boolean read) {
        this.read = read;
    }
}
