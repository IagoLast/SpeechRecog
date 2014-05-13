package es.udc.iagolast.speechrecog.speechrecog.mailClient.mock;

import java.util.LinkedList;
import java.util.List;
import java.util.Stack;

import es.udc.iagolast.speechrecog.speechrecog.mailClient.Mail;
import es.udc.iagolast.speechrecog.speechrecog.mailClient.MailClient;


public class MailClientMock implements MailClient {

    Stack<Mail> unreadMailStack;
    List<Mail> readMails;
    int index = 0;

    private final String SUBJECT_BASE_STRING = "Hola soy un mail de Prueba ";
    private final String FROM_BASE_STRING = "iago.lastra@gmail.com";
    private final String BODY_BASE_STRING = "Hola, es posible que llegue tarde a la reunión de las 10. Saludos";
    private final String TO_MAIL_STRING = "mimail@mail.com";

    public MailClientMock() {

        Mail readMail1 = new Mail(SUBJECT_BASE_STRING + 1, FROM_BASE_STRING, TO_MAIL_STRING, BODY_BASE_STRING + 1);
        Mail readMail2 = new Mail(SUBJECT_BASE_STRING + 2, FROM_BASE_STRING, TO_MAIL_STRING, BODY_BASE_STRING + 2);
        Mail readMail3 = new Mail(SUBJECT_BASE_STRING + 3, FROM_BASE_STRING, TO_MAIL_STRING, BODY_BASE_STRING + 3);

        Mail unreadMail1 = new Mail(SUBJECT_BASE_STRING + 1, FROM_BASE_STRING, TO_MAIL_STRING, BODY_BASE_STRING + 1);
        Mail unreadMail2 = new Mail(SUBJECT_BASE_STRING + 2, FROM_BASE_STRING, TO_MAIL_STRING, BODY_BASE_STRING + 2);
        Mail unreadMail3 = new Mail(SUBJECT_BASE_STRING + 3, FROM_BASE_STRING, TO_MAIL_STRING, BODY_BASE_STRING + 3);

        unreadMailStack = new Stack<Mail>();
        readMails = new LinkedList<Mail>();

        unreadMailStack.push(unreadMail1);
        unreadMailStack.push(unreadMail2);
        unreadMailStack.push(unreadMail3);

        readMails.add(readMail1);
        readMails.add(readMail2);
        readMails.add(readMail3);

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
        try {
            return readMails.get(index++);
        } catch (IndexOutOfBoundsException e) {
            index = 0;
            return null;
        }

    }

    @Override
    public Mail getNextUnreadMail() {
        if (!unreadMailStack.isEmpty()) {
            readMails.add(unreadMailStack.peek());
            return unreadMailStack.pop();
        } else return null;

    }

    @Override
    public boolean sendMail(Mail mail) {
        return (Math.random() > 0.5);


    }
}
