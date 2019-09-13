package org.redhat.alertservice;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Properties;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

@Component
public class MailProcessor implements Processor {

	private static final String DATE_FORMAT = "MM-dd-yyyy hh:mm";

	private static final String MAIL_SMTP_AUTH = "mail.smtp.auth";

	private static final String MAIL_SMTP_PORT = "mail.smtp.port";

	private static final String MAIL_SMTP_STARTTLS_ENABLE = "mail.smtp.starttls.enable";

	private static final String MAIL_SMTP_HOST = "mail.smtp.host";

	private String MAIL_MSG = "Mail has been sent successfully";

	@Autowired
	Environment environment;

	@Override
	public void process(Exchange exchange) throws Exception {
	
		try {

			UserInfo userInfo = (UserInfo) exchange.getIn().getBody();

			String messageBody = AlertMessage.enumSwitch(Types.valueOf(userInfo.getAlertType()));

			System.out.println(userInfo.getEmail());
			System.out.println(userInfo.getAlertType());
			
			Session session = setMailProperties();

			MimeMessage msg = new MimeMessage(session);

			InternetAddress[] address = InternetAddress.parse(userInfo.getEmail(), true);
			msg.setRecipients(Message.RecipientType.TO, address);
			String timeStamp = new SimpleDateFormat(DATE_FORMAT).format(new Date());
			msg.setSubject(userInfo.getAlertType() + " Alert Notification : " + timeStamp);
			msg.setSentDate(new Date());
			msg.setText(messageBody);
			msg.setHeader("XPriority", "1");
			Transport.send(msg);

			System.out.println(MAIL_MSG);

		} catch (MessagingException mex) {
			MAIL_MSG = "Unable to send an email" + mex;
		}

		exchange.getOut().setBody(MAIL_MSG);
	}

	private Session setMailProperties() {
		Properties props = new Properties();
		props.put(MAIL_SMTP_HOST, "true");
		props.put(MAIL_SMTP_STARTTLS_ENABLE, environment.getProperty("mail.tls"));
		props.put(MAIL_SMTP_HOST, environment.getProperty("mail.smtp.host"));
		props.put(MAIL_SMTP_PORT, environment.getProperty("mail.port"));
		props.put(MAIL_SMTP_AUTH, environment.getProperty("mail.smtp.auth"));
		Session session = Session.getInstance(props, new javax.mail.Authenticator() {
			protected PasswordAuthentication getPasswordAuthentication() {
				return new PasswordAuthentication(environment.getProperty("mail.user"),
						environment.getProperty("mail.passsword"));
			}
		});
		return session;
	}

}