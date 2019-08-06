package com.redhat.myfispipeline;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.HashMap;
import java.util.Map;

import org.apache.camel.CamelContext;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@ActiveProfiles("dev")
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
public class ApplicationTest {

	@Autowired
	private TestRestTemplate restTemplate;

	@Autowired
	private CamelContext camelContext;

	@Test
	public void testProfile() {

		// Then call the REST API
		ResponseEntity<UserProfiles> profileResponse = restTemplate.getForEntity("/cicd/users/profile/11111",
				UserProfiles.class);
		assertThat(profileResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
		UserProfiles userProfile = profileResponse.getBody();
        assertThat(userProfile.getFirstName()).isEqualTo("Abdul");
        assertThat(userProfile.getLastName()).isEqualTo("Hameed");
        assertThat(userProfile.getEmail()).isEqualTo("abdulhameedmemon@gmail.com");
        assertThat(userProfile.getUsername()).isEqualTo("ahameed");
		assertThat(userProfile.getPhone()).isEqualTo("6364858533");
        assertThat(userProfile.getState()).isEqualTo("MA");
        assertThat(userProfile.getAddr()).isEqualTo("172 waltham");

	}

}