package id.go.bps.digilib.controllers;

import id.go.bps.digilib.models.TPublication;
import id.go.bps.digilib.task.ADirectoryTaskOutput;
import id.go.bps.digilib.utils.FileUtils;
import id.go.bps.digilib.utils.PdfToImageConverter;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.MalformedURLException;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import jcifs.smb.SmbFile;

import org.apache.commons.io.IOUtils;
import org.apache.commons.lang.SystemUtils;
import org.sejda.model.exception.TaskException;
import org.sejda.model.input.PdfStreamSource;
import org.sejda.model.parameter.image.AbstractPdfToMultipleImageParameters;
import org.sejda.model.parameter.image.PdfToJpegParameters;
import org.sejda.model.pdf.page.PageRange;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import com.itextpdf.text.Document;
import com.itextpdf.text.DocumentException;
import com.itextpdf.text.pdf.PdfCopy;
import com.itextpdf.text.pdf.PdfImportedPage;
import com.itextpdf.text.pdf.PdfReader;
import com.j256.ormlite.dao.Dao;
import com.j256.ormlite.stmt.QueryBuilder;

@Controller("pdfController")
@RequestMapping("/pdf")
public class PdfController {
	//private static final Logger LOG = LoggerFactory.getLogger(PdfController.class);
	
	@Autowired
	private String sharedPdf;
	@Autowired
	private Dao<TPublication, Object> tPublicationDao;
	
	@RequestMapping(method = RequestMethod.GET, value = "/{id}/{title}")
	public String viewer(@PathVariable("id") final String id, @PathVariable("title") final String title, Model model, final HttpServletRequest req) 
			throws FileNotFoundException, IOException, SQLException {
		QueryBuilder<TPublication, Object> qb = tPublicationDao.queryBuilder();
		qb.where().eq("id_publikasi", id);
		TPublication pub = qb.queryForFirst();
		
		String filename = getFilename(pub);
		InputStream is = null;
		if(SystemUtils.IS_OS_WINDOWS) {
			is = new FileInputStream(new File(filename));
		} else {
			is = new SmbFile(filename).getInputStream();
		}
		
		final PdfReader reader = new PdfReader(is);
		
		model.addAttribute("publication", pub);
		model.addAttribute("properties", new HashMap<String, Object>() {
			private static final long serialVersionUID = 1L;
			{
				put("numPages", reader.getNumberOfPages());
				put("baseUrl", req.getScheme() + "://" + req.getServerName() + ":" + req.getServerPort() + 
						req.getContextPath() + "/pdf/" + id + "/" + title);
				put("docSize", reader.getPageSize(3));
				put("format", "pdf");
			}
		});
		
		return "Flipbook";
	}
	
	@RequestMapping(method = RequestMethod.GET, value = "/{id}/{title}/jpg")
	public String viewerJpg(@PathVariable("id") final String id, @PathVariable("title") final String title, Model model, final HttpServletRequest req) 
			throws FileNotFoundException, IOException, SQLException {
		QueryBuilder<TPublication, Object> qb = tPublicationDao.queryBuilder();
		qb.where().eq("id_publikasi", id);
		TPublication pub = qb.queryForFirst();
		
		String filename = getFilename(pub);
		InputStream is = null;
		if(SystemUtils.IS_OS_WINDOWS) {
			is = new FileInputStream(new File(filename));
		} else {
			is = new SmbFile(filename).getInputStream();
		}
		
		final PdfReader reader = new PdfReader(is);
		
		model.addAttribute("publication", pub);
		model.addAttribute("properties", new HashMap<String, Object>() {
			private static final long serialVersionUID = 1L;
			{
				put("numPages", reader.getNumberOfPages());
				put("baseUrl", req.getScheme() + "://" + req.getServerName() + ":" + req.getServerPort() + 
						req.getContextPath() + "/pdf/" + id + "/" + title);
				put("docSize", reader.getPageSize(3));
				put("format", "jpg");
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
		
		InputStream is = null;
		if(SystemUtils.IS_OS_WINDOWS) {
			is = new FileInputStream(new File(filename));
		} else {
			is = new SmbFile(filename).getInputStream();
		}
		
		resp.setContentType("application/pdf");
		IOUtils.copyLarge(is, resp.getOutputStream());
	}
	
	@RequestMapping(method = RequestMethod.GET, value = "/{id}/{title}/{page}")
	public void pdfPage(@PathVariable("id") String id, @PathVariable("title") String title, @PathVariable("page") Integer page,  HttpServletResponse resp) 
			throws FileNotFoundException, IOException, SQLException, DocumentException {
		QueryBuilder<TPublication, Object> qb = tPublicationDao.queryBuilder();
		qb.where().eq("id_publikasi", id);
		TPublication pub = qb.queryForFirst();
		String filename = getFilename(pub);
		
		InputStream is = null;
		if(SystemUtils.IS_OS_WINDOWS) {
			is = new FileInputStream(new File(filename));
		} else {
			is = new SmbFile(filename).getInputStream();
		}
		
		resp.setContentType("application/pdf");
		extractPage(page, is, resp.getOutputStream());
	}
	
	@RequestMapping(method = RequestMethod.GET, value = "/{id}/{title}/{page}/jpg")
	public void pdfPageJpg(@PathVariable("id") String id, @PathVariable("title") String title, @PathVariable("page") Integer page,  HttpServletResponse resp) 
			throws FileNotFoundException, IOException, SQLException, DocumentException, TaskException {
		QueryBuilder<TPublication, Object> qb = tPublicationDao.queryBuilder();
		qb.where().eq("id_publikasi", id);
		TPublication pub = qb.queryForFirst();
		String filename = getFilename(pub);
		
		String jpgName = filename.replace(".pdf", "") + File.separator + page + ".jpg";
		while(true) {
			if(FileUtils.exists(jpgName)) {
				IOUtils.copy(FileUtils.getInputStream(jpgName), resp.getOutputStream());
				break;
			}
			
			convertPublicationToImage(pub, filename, new PageRange(page, page));
		}
	}
	
	@RequestMapping(method = RequestMethod.GET, value = "/{id}/{title}/{page}/text")
	public void pdfPageText(@PathVariable("id") String id, @PathVariable("title") String title, @PathVariable("page") Integer page,  HttpServletResponse resp) 
			throws FileNotFoundException, IOException, SQLException, DocumentException, TaskException {
		QueryBuilder<TPublication, Object> qb = tPublicationDao.queryBuilder();
		qb.where().eq("id_publikasi", id);
		TPublication pub = qb.queryForFirst();
		String filename = getFilename(pub);
		
		extractPageText(pub, filename, new PageRange(page, page));
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
		PdfCopy writer = new PdfCopy(document, output);
        //writer.setFullCompression();
        document.open();
        PdfImportedPage pdfPage = writer.getImportedPage(reader, page);
        writer.addPage(pdfPage);
        document.close();
        writer.close();
	}
	
	public void convertAllPublicationsToImage() throws SQLException, IOException, DocumentException, TaskException {
		List<TPublication> pubs = tPublicationDao.queryForAll();
		Iterator<TPublication> itr = pubs.iterator();
		while(itr.hasNext()) {
			final TPublication pub = itr.next();
			final String filename = getFilename(pub);
			
			new Thread() {
				public void run() {
					try {
						if(SystemUtils.IS_OS_WINDOWS) {
							if(new File(filename).exists()) {
								convertPublicationToImage(pub, filename, new PageRange(1, 1));
								convertPublicationToImage(pub, filename, new PageRange(2));
							}
						} else {
							if(new SmbFile(filename).exists()) {
								convertPublicationToImage(pub, filename, new PageRange(1, 1));
								convertPublicationToImage(pub, filename, new PageRange(2));
							}
						}
					} catch(IOException | DocumentException | TaskException e) {
						e.printStackTrace();
					}
				};
			}.start();
		}
	}
	
	private void convertPublicationToImage(TPublication pub, final String filename, PageRange range) throws MalformedURLException, IOException, DocumentException, TaskException {
		InputStream is = FileUtils.getInputStream(filename);
		
		PdfToJpegParameters params = new PdfToJpegParameters();
		params.setSource(PdfStreamSource.newInstanceNoPassword(is, pub.getJudul()));
		params.setOutput(new ADirectoryTaskOutput(filename.replace(".pdf", "")));
		params.addPageRange(range);
		params.setOverwrite(true);
		
		PdfToImageConverter<AbstractPdfToMultipleImageParameters> task = new PdfToImageConverter<>();
		task.before(params);
		task.execute(params);
		task.after();
	}
	
	private void extractPageText(TPublication pub, final String filename, PageRange range) throws IOException, TaskException {
		InputStream is = FileUtils.getInputStream(filename);
		
		PdfToJpegParameters params = new PdfToJpegParameters();
		params.setSource(PdfStreamSource.newInstanceNoPassword(is, pub.getJudul()));
		params.setOutput(new ADirectoryTaskOutput(filename.replace(".pdf", "")));
		params.addPageRange(range);
		params.setOverwrite(true);
		
		PdfToImageConverter<AbstractPdfToMultipleImageParameters> task = new PdfToImageConverter<>();
		task.before(params);
		task.getPageText(params);
		/*Map<Integer, List<LineText>> pageText = task.getPageText();
		for(int p=0; p<pageText.size(); p++) {
			for(LineText line : pageText.get(p)) {
				Float bounds = line.getBounds();
				
				String texts = "";
				List<WordText> words = line.getWords();
				for(WordText text : words) {
					texts += text.getText();
				}
				LOG.debug("Page {} : x={}, y={}, w={}, h={}, text={}", pageText.keySet().toArray()[p], bounds.getX(), bounds.getY(), bounds.getWidth(), bounds.getHeight(), texts);
			}
		}*/
	}
}
