package id.go.bps.digilib.controllers;

import id.go.bps.digilib.models.TPublication;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.sql.SQLException;
import java.util.HashMap;

import javax.imageio.ImageIO;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.io.IOUtils;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import com.itextpdf.text.Document;
import com.itextpdf.text.DocumentException;
import com.itextpdf.text.pdf.PdfImportedPage;
import com.itextpdf.text.pdf.PdfReader;
import com.itextpdf.text.pdf.PdfSmartCopy;
import com.j256.ormlite.dao.Dao;
import com.j256.ormlite.stmt.QueryBuilder;

@Controller("pdfController")
@RequestMapping("/pdf")
public class PdfController {
	@Autowired
	private String sharedPdf;
	@Autowired
	private Dao<TPublication, Object> tPublicationDao;
	
	@RequestMapping(method = RequestMethod.GET, value = "/{id}/{title}")
	public String viewer(@PathVariable("id") String id, @PathVariable("title") String title, Model model) 
			throws FileNotFoundException, IOException, SQLException {
		QueryBuilder<TPublication, Object> qb = tPublicationDao.queryBuilder();
		qb.where().eq("id_publikasi", id);
		TPublication pub = qb.queryForFirst();
		
		final PdfReader reader = new PdfReader(getFilename(pub));
		
		model.addAttribute("publication", pub);
		model.addAttribute("properties", new HashMap<String, Object>() {
			private static final long serialVersionUID = 1L;
			{
				put("numPages", reader.getNumberOfPages());
			}
		});
		
		return "Flipbook";
	}
	
	@RequestMapping(method = RequestMethod.GET, value = "/{id}/{title}/download")
	public void download(@PathVariable("id") String id, @PathVariable("title") String title, HttpServletResponse resp) 
			throws FileNotFoundException, IOException, SQLException {
		QueryBuilder<TPublication, Object> qb = tPublicationDao.queryBuilder();
		qb.where().eq("id_publikasi", id);
		TPublication pub = qb.queryForFirst();
		String filename = getFilename(pub);
		
		resp.setContentType("application/pdf");
		IOUtils.copyLarge(new FileInputStream(new File(filename)), resp.getOutputStream());
	}
	
	@RequestMapping(method = RequestMethod.GET, value = "/{id}/{title}/{page}")
	public void pdfPage(@PathVariable("id") String id, @PathVariable("title") String title, @PathVariable("page") Integer page,  HttpServletResponse resp) 
			throws FileNotFoundException, IOException, SQLException, DocumentException {
		QueryBuilder<TPublication, Object> qb = tPublicationDao.queryBuilder();
		qb.where().eq("id_publikasi", id);
		TPublication pub = qb.queryForFirst();
		String filename = getFilename(pub);
		
		resp.setContentType("application/pdf");
		extractPage(page, new FileInputStream(filename), resp.getOutputStream());
	}
	
	@RequestMapping(method = RequestMethod.GET, value = "/{id}/{title}/cover")
	public void pdfCover(@PathVariable("id") String id, @PathVariable("title") String title, HttpServletResponse resp) 
			throws FileNotFoundException, IOException, SQLException, DocumentException {
		QueryBuilder<TPublication, Object> qb = tPublicationDao.queryBuilder();
		qb.where().eq("id_publikasi", id);
		//System.out.println(qb.prepareStatementString());
		TPublication pub = qb.queryForFirst();
		
        String tmpImgDir = System.getProperty("java.io.tmpdir") + File.separator + "DigilibApplicationServer";//Files.createTempDirectory("DigilibApplicationServer").toFile().getAbsolutePath();
        new File(tmpImgDir).mkdirs();
        String tmpCoverFile = tmpImgDir + File.separator + getCoverName(pub);
        if(new File(tmpCoverFile).exists()) {
        	IOUtils.copy(new FileInputStream(tmpCoverFile), resp.getOutputStream());
        } else {
        	String filename = getFilename(pub);		
    		PDDocument doc = PDDocument.loadNonSeq(new File(filename), null);
    		PDPage pdfPage = (PDPage) doc.getDocumentCatalog().getAllPages().get(0);
    		BufferedImage bi = pdfPage.convertToImage();
    		ImageIO.write(bi, "jpg", resp.getOutputStream());
    		ImageIO.write(bi, "jpg", new FileOutputStream(tmpCoverFile));
        }
	}
	
	public String getFilename(TPublication pub) {
		return sharedPdf + File.separator + pub.getKd_bahan_pustaka() + File.separator + 
				pub.getKd_bahan_pustaka() + "_" + pub.getKd_subyek() + "_" + pub.getKd_produsen() + "_" + 
				pub.getTahun_terbit() + "_" + pub.getKd_periode() + "_" + pub.getIs_full_entry() + "_" + 
				pub.getJudul().replace(" ", "-") + ".pdf";
	}
	
	public String getCoverName(TPublication pub) {
		return pub.getKd_bahan_pustaka() + "_" + pub.getKd_subyek() + "_" + pub.getKd_produsen() + "_" + 
				pub.getTahun_terbit() + "_" + pub.getKd_periode() + "_" + pub.getIs_full_entry() + "_" + 
				pub.getJudul().replace(" ", "-") + ".jpg";
	}
	 
	private void extractPage(int page, InputStream input, OutputStream output) throws IOException, DocumentException {
		PdfReader reader = new PdfReader(input);
		Document document = new Document(reader.getPageSizeWithRotation(1));
		PdfSmartCopy writer = new PdfSmartCopy(document, output);
        writer.setFullCompression();
        document.open();
        PdfImportedPage pdfPage = writer.getImportedPage(reader, page);
        writer.addPage(pdfPage);
        document.close();
        writer.close();
	}
}
