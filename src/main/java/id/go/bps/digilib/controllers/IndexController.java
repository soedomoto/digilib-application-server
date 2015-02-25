package id.go.bps.digilib.controllers;

import id.go.bps.digilib.models.TApplicationSettings;
import id.go.bps.digilib.models.TPublication;

import java.io.File;
import java.sql.SQLException;
import java.util.Iterator;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import com.j256.ormlite.dao.Dao;

@Controller
@RequestMapping("/")
public class IndexController {
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
	public String shelf(Model model) throws SQLException {
		List<TPublication> pubs = tPublicationDao.queryForAll();
		Iterator<TPublication> itr = pubs.iterator();
		while(itr.hasNext()) {
			TPublication pub = itr.next();
			String filename = pdfController.getFilename(pub);
			if(! new File(filename).exists()) {
				itr.remove();
			}
		}
		
		model.addAttribute("pubs", pubs);
		return "Index";
	}
}
