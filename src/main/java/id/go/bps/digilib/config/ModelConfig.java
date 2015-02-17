package id.go.bps.digilib.config;

import java.sql.SQLException;

import id.go.bps.digilib.models.TPublication;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.j256.ormlite.dao.Dao;
import com.j256.ormlite.jdbc.JdbcConnectionSource;
import com.j256.ormlite.spring.DaoFactory;

@Configuration
public class ModelConfig {
	@Autowired
	JdbcConnectionSource conn;
	
	@Bean(name = "tPublication")
	public Dao<TPublication, Object> tPublication() throws SQLException {
		return DaoFactory.createDao(conn, TPublication.class);
	}
}
