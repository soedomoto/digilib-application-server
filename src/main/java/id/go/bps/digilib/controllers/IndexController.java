package id.go.bps.digilib.controllers;

import id.go.bps.digilib.models.TApplicationSettings;
import id.go.bps.digilib.models.TPublication;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.sql.SQLException;
import java.util.Iterator;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import jcifs.smb.SmbException;
import jcifs.smb.SmbFile;

import org.apache.commons.lang.SystemUtils;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.DependsOn;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import com.itextpdf.text.DocumentException;
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
		return "Index";
	}

	@Override
	public void afterPropertiesSet() throws Exception {
		/*new Thread() {
			public void run() {
				try {
					Thread.sleep(5000);
					System.out.println("----------- STARTING CONVERT IMAGE --------------------");
					pdfController.convertToImage();
				} catch (SQLException | IOException | DocumentException | InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			};
		}.start();*/
	}
}
