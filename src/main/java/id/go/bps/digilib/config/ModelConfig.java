package id.go.bps.digilib.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;

import com.j256.ormlite.jdbc.JdbcConnectionSource;

@Configuration
public class ModelConfig {
	@Autowired
	JdbcConnectionSource conn;
	
}
