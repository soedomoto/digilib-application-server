package id.go.bps.digilib.config;

import java.io.File;
import java.sql.SQLException;

import id.go.bps.digilib.models.TApplicationSettings;
import id.go.bps.digilib.models.TPublication;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.DependsOn;

import com.j256.ormlite.dao.Dao;
import com.j256.ormlite.jdbc.JdbcConnectionSource;
import com.j256.ormlite.spring.DaoFactory;

@Configuration
public class ModelConfig {
	@Autowired
	JdbcConnectionSource conn;
	
	@Bean(name = "tPublicationDao")
	public Dao<TPublication, Object> tPublicationDao() throws SQLException {
		return DaoFactory.createDao(conn, TPublication.class);
	}
	
	@Bean(name = "tApplicationSettingsDao")
	public Dao<TApplicationSettings, Object> tApplicationSettingsDao() throws SQLException {
		return DaoFactory.createDao(conn, TApplicationSettings.class);
	}
	
	@Bean(name = "sharedPdf")
	@DependsOn(value = {"tApplicationSettingsDao"})
	public String sharedPdf() throws SQLException {
		TApplicationSepgttings setting = tApplicationSettingsDao().queryBuilder().queryForFirst();
		return File.separator + File.separator + setting.getServer_name() + File.separator + setting.getPdf_folder();
	}
}
