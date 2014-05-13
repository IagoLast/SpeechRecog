package es.udc.iagolast.speechrecog.speechrecog.mailClient.imap.wrapper;


import java.util.List;
import java.util.Stack;

import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.MailClient;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.imap.IMAPMailClient;

public class IMAPMailClientWrapper implements MailClient {

    IMAPMailClient client;
    Stack<Mail> unreadMails;
    List<Mail> readMails;
    int index = 0;


    public IMAPMailClientWrapper(IMAPMailClient client) {
        this.client = client;
        unreadMails = new Stack<Mail>();

        for (Mail mail : client.getUnreadMails()) {
            unreadMails.push(mail);
        }

        readMails = client.getAllMails();
        readMails.removeAll(unreadMails);

    }

    @Override
    public boolean hasUnreadMail() {
        return !unreadMails.isEmpty();
    }

    @Override
    public List<Mail> getUnreadMails() {
        return unreadMails;
    }

    @Override
    public List<Mail> getAllMails() {
        return client.getAllMails();

    }


    @Override
    public Mail getNextMail() {
        try {
            return readMails.get(index++);
        } catch (IndexOutOfBoundsException e) {
            index = 0;
            return null;
        }
    }

    @Override
    public Mail getNextUnreadMail() {
        Mail retMail = (unreadMails.isEmpty()) ? null : unreadMails.pop();

        return retMail;
    }

    @Override
    public boolean sendMail(Mail mail) {
        return true;

    }
}
