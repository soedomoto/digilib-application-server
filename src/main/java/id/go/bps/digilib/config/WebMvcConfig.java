package id.go.bps.digilib.config;

import java.sql.SQLException;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.support.ReloadableResourceBundleMessageSource;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter;
import org.springframework.web.servlet.view.InternalResourceViewResolver;
import org.springframework.web.servlet.view.JstlView;

import com.j256.ormlite.jdbc.JdbcConnectionSource;

@Configuration
@EnableWebMvc
public class WebMvcConfig extends WebMvcConfigurerAdapter {
	@Value("${database.url}")
	private String dbUrl;
	@Value("${database.username}")
	private String dbUsername;
	@Value("${database.password}")
	private String dbPassword;
	
	@Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/assets/**").addResourceLocations("assets/");
        registry.addResourceHandler("/favicon.ico").addResourceLocations("assets/favicon.ico");
    }
	
	@Bean(name = "viewResolver")
    public InternalResourceViewResolver viewResolver() {
        InternalResourceViewResolver bean = new InternalResourceViewResolver();
        bean.setViewClass(JstlView.class);
        bean.setPrefix("/views/");
        bean.setSuffix(".jsp");
        return bean;
    }
	
	@Bean(name = "messageSource")
    public ReloadableResourceBundleMessageSource messageSource() {
        ReloadableResourceBundleMessageSource resource = new ReloadableResourceBundleMessageSource();
        resource.setBasename("/i18n/messages");
        resource.setDefaultEncoding("UTF-8");
        resource.setCacheSeconds(30);
        return resource;
    }
	
	@Bean(name = "connectionSource")
	public JdbcConnectionSource connectionSource() throws SQLException {
		JdbcConnectionSource conn = new JdbcConnectionSource();
		conn.setUrl(dbUrl);
		conn.setUsername(dbUsername);
		conn.setPassword(dbPassword);
		conn.initialize();
		return conn;
	}
}
