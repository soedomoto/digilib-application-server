package id.go.bps.digilib.controllers;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.io.IOUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
@RequestMapping("/pdf")
public class PdfController {
	@Autowired
	private String sharedPdf;
	
	@RequestMapping(method = RequestMethod.GET, value = "/{title}")
	public void pdf(@PathVariable("title") String title, Model model, HttpServletRequest req, HttpServletResponse resp) 
			throws FileNotFoundException, IOException {
		String filename = sharedPdf + File.separator + title.replace("-", " ");
		
		resp.setContentType("application/pdf");
		IOUtils.copyLarge(new FileInputStream(new File(filename)), resp.getOutputStream());
	}
	
	@RequestMapping(method = RequestMethod.GET, value = "/{title}/{page}")
	public void pdfPage(@PathVariable("title") String title, @PathVariable("page") Integer page, Model model, HttpServletRequest req, HttpServletResponse resp) 
			throws FileNotFoundException, IOException {
		String filename = sharedPdf + File.separator + title.replace("-", " ");
		
		resp.setContentType("application/pdf");
		IOUtils.copyLarge(new FileInputStream(new File(filename)), resp.getOutputStream());
	}
}
