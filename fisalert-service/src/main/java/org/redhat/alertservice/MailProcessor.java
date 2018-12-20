package org.redhat.alertservice;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

@Component
public class MailProcessor implements Processor {

	
	@Autowired
	Environment environment;

	@Autowired
	private UserInfo userInfo;

	@Override
	public void process(Exchange exchange) throws Exception {

		UserInfo userInfo = (UserInfo) exchange.getIn().getBody();

		String messageBody = AlertMessage.enumSwitch(Types.valueOf(userInfo.getAlertType()));

		System.out.println(userInfo.getEmail());
		System.out.println(userInfo.getAlertType());

	    exchange.getOut().setBody(messageBody);
	}
}