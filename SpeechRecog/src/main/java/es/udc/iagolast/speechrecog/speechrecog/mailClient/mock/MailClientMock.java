package es.udc.iagolast.speechrecog.speechrecog.mailClient.mock;

import java.util.LinkedList;
import java.util.List;
import java.util.Stack;

import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.MailClient;


public class MailClientMock implements MailClient {

    Stack<Mail> unreadMailStack;
    List<Mail> readMails;

    private final String SUBJECT_BASE_STRING = "Tema de prueba";
    private final String FROM_BASE_STRING = "Remitente.prueba";
    private final String FROM_END_STRING = "@mail.com";
    private final String BODY_BASE_STRING = "Esto es un mail de prueba";
    private final String TO_MAIL_STRING = "mimail@mail.com";

    public MailClientMock() {

        Mail readMail1 = new Mail(SUBJECT_BASE_STRING + 1, FROM_BASE_STRING + 1 + FROM_END_STRING, TO_MAIL_STRING, BODY_BASE_STRING + 1);
        Mail readMail2 = new Mail(SUBJECT_BASE_STRING + 2, FROM_BASE_STRING + 2 + FROM_END_STRING, TO_MAIL_STRING, BODY_BASE_STRING + 2);

        Mail unreadMail1 = new Mail(SUBJECT_BASE_STRING + 1, FROM_BASE_STRING + 1 + FROM_END_STRING, TO_MAIL_STRING, BODY_BASE_STRING + 1);
        Mail unreadMail2 = new Mail(SUBJECT_BASE_STRING + 2, FROM_BASE_STRING + 2 + FROM_END_STRING, TO_MAIL_STRING, BODY_BASE_STRING + 2);

        unreadMailStack = new Stack<Mail>();
        readMails = new LinkedList<Mail>();

        unreadMailStack.push(unreadMail1);
        unreadMailStack.push(unreadMail2);

        readMails.add(readMail1);
        readMails.add(readMail2);

    }

    @Override
    public boolean hasUnreadMail() {
        return !unreadMailStack.isEmpty();
    }

    @Override
    public Stack<Mail> getUnreadMails() {
        return unreadMailStack;
    }

    @Override
    public List<Mail> getAllMails() {
        return readMails;
    }

    @Override
    public Mail getNextMail() {
        readMails.add(unreadMailStack.peek());
        return unreadMailStack.pop();
    }

    @Override
    public boolean sendMail(Mail mail) {
        return (Math.random() > 0.5);


    }
}
