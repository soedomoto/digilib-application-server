package id.go.bps.digilib.controllers;

import id.go.bps.digilib.models.TApplicationSettings;
import id.go.bps.digilib.models.TPublication;

import java.awt.Toolkit;
import java.io.File;
import java.net.MalformedURLException;
import java.sql.SQLException;
import java.util.Iterator;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import jcifs.smb.SmbException;
import jcifs.smb.SmbFile;

import org.apache.commons.lang.SystemUtils;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.DependsOn;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import com.j256.ormlite.dao.Dao;

@Controller("indexController")
@DependsOn(value = {"pdfController"})
@RequestMapping("/")
public class IndexController implements InitializingBean {
	@Autowired
	private PdfController pdfController;
	@Autowired
	private Dao<TPublication, Object> tPublicationDao;
	@Autowired
	private Dao<TApplicationSettings, Object> tApplicationSettingsDao;
	@Value("${flipbook.autoConvert}")
	private boolean autoconvert;
	@Value("${flipbook.autoConvertAtStartup}")
	private boolean autoConvertAtStartup;
	@Value("${flipbook.autoConvertInterval}")
	private int autoConvertInterval;
	@Value("${flipbook.pageFormat}")
	private String pageFormat;
	
	//@RequestMapping(method = RequestMethod.GET)
	public String index(Model model, HttpServletRequest req, HttpServletResponse resp) {
		return "Index";
	}
	
	@RequestMapping(method = RequestMethod.GET)
	public String shelf(Model model) throws SQLException, SmbException, MalformedURLException {
		List<TPublication> pubs = tPublicationDao.queryForAll();
		Iterator<TPublication> itr = pubs.iterator();
		while(itr.hasNext()) {
			TPublication pub = itr.next();
			String filename = pdfController.getFilename(pub);
			
			if(SystemUtils.IS_OS_WINDOWS) {
				if(! new File(filename).exists()) itr.remove();
			} else {
				if(! new SmbFile(filename).exists())  itr.remove();
			}
		}
		
		model.addAttribute("pubs", pubs);
		model.addAttribute("format", pageFormat);
		return "Index";
	}

	@Override
	public void afterPropertiesSet() throws Exception {
		if(autoconvert) {
			if(autoConvertAtStartup) autoConvert();
			new Timer().schedule(new TimerTask() {
				@Override
				public void run() {
					autoConvert();
				}
			}, autoConvertInterval * 60 * 1000);
		}
	}
	
	private void autoConvert() {
		new Thread() {
			public void run() {
				try {
					Thread.sleep(1000);
					System.out.println("----------- STARTING CONVERT IMAGE --------------------");
					Toolkit.getDefaultToolkit().beep();
					pdfController.convertAllPublicationsToImage();
				} catch (Exception e) {
					e.printStackTrace();
				}
			};
		}.start();
	}
}
