package id.go.bps.digilib.controllers;

import java.sql.SQLException;
import java.util.List;

import id.go.bps.digilib.models.TPublication;

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
	Dao<TPublication, Object> tPublication;
	
	//@RequestMapping(method = RequestMethod.GET)
	public String index(Model model, HttpServletRequest req, HttpServletResponse resp) {
		return "Index";
	}
	
	@RequestMapping(method = RequestMethod.GET)
	public String shelf(Model model) throws SQLException {
		List<TPublication> pubs = tPublication.queryForAll();
		model.addAttribute("pubs", pubs);
		
		return "Index";
	}
	
}
