package id.go.bps.digilib.controllers;

import id.go.bps.digilib.models.TPublication;
import id.go.bps.digilib.task.ADirectoryTaskOutput;
import id.go.bps.digilib.utils.FileUtils;
import id.go.bps.digilib.utils.PdfToImageConverter;

import java.io.File;
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
import org.icepdf.core.pobjects.Document;
import org.icepdf.core.pobjects.PDimension;
import org.icepdf.core.pobjects.Page;
import org.sejda.impl.icepdf.component.DefaultPdfSourceOpener;
import org.sejda.impl.itext.component.input.PdfSourceOpeners;
import org.sejda.model.exception.TaskException;
import org.sejda.model.exception.TaskIOException;
import org.sejda.model.input.PdfStreamSource;
import org.sejda.model.parameter.image.AbstractPdfToMultipleImageParameters;
import org.sejda.model.parameter.image.PdfToJpegParameters;
import org.sejda.model.pdf.page.PageRange;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import com.j256.ormlite.dao.Dao;
import com.j256.ormlite.stmt.QueryBuilder;
import com.lowagie.text.DocumentException;
import com.lowagie.text.pdf.PdfImportedPage;
import com.lowagie.text.pdf.PdfReader;
import com.lowagie.text.pdf.PdfSmartCopy;

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
			throws FileNotFoundException, IOException, SQLException, TaskIOException {
		QueryBuilder<TPublication, Object> qb = tPublicationDao.queryBuilder();
		qb.where().eq("id_publikasi", id);
		final TPublication pub = qb.queryForFirst();
		final String filename = getFilename(pub);
		
		model.addAttribute("publication", pub);
		model.addAttribute("properties", new HashMap<String, Object>() {
			private static final long serialVersionUID = 1L;
			{
				put("numPages", pageCount(pub, filename));
				put("baseUrl", req.getScheme() + "://" + req.getServerName() + ":" + req.getServerPort() + 
						req.getContextPath() + "/pdf/" + id + "/" + title);
				put("docSize", pageSize(pub, filename, 3));
				put("format", "pdf");
			}
		});
		
		return "Flipbook";
	}
	
	@RequestMapping(method = RequestMethod.GET, value = "/{id}/{title}/jpg")
	public String viewerJpg(@PathVariable("id") final String id, @PathVariable("title") final String title, Model model, final HttpServletRequest req) 
			throws FileNotFoundException, IOException, SQLException, TaskIOException {
		QueryBuilder<TPublication, Object> qb = tPublicationDao.queryBuilder();
		qb.where().eq("id_publikasi", id);
		final TPublication pub = qb.queryForFirst();
		final String filename = getFilename(pub);
		
		model.addAttribute("publication", pub);
		model.addAttribute("properties", new HashMap<String, Object>() {
			private static final long serialVersionUID = 1L;
			{
				put("numPages", pageCount(pub, filename));
				put("baseUrl", req.getScheme() + "://" + req.getServerName() + ":" + req.getServerPort() + 
						req.getContextPath() + "/pdf/" + id + "/" + title);
				put("docSize", pageSize(pub, filename, 3));
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
		InputStream is = FileUtils.getInputStream(filename);
		
		resp.setContentType("application/pdf");
		IOUtils.copyLarge(is, resp.getOutputStream());
	}
	
	@RequestMapping(method = RequestMethod.GET, value = "/{id}/{title}/{page}")
	public void pdfPage(@PathVariable("id") String id, @PathVariable("title") String title, @PathVariable("page") Integer page,  HttpServletResponse resp) 
			throws FileNotFoundException, IOException, SQLException, TaskIOException, DocumentException {
		QueryBuilder<TPublication, Object> qb = tPublicationDao.queryBuilder();
		qb.where().eq("id_publikasi", id);
		TPublication pub = qb.queryForFirst();
		String filename = getFilename(pub);
		InputStream is = FileUtils.getInputStream(filename);
		
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
	 
	private void extractPage(int page, InputStream is, OutputStream os) throws IOException, TaskIOException, DocumentException {
		PdfReader reader = PdfStreamSource.newInstanceNoPassword(is, "Whole PDF").open(PdfSourceOpeners.newPartialReadOpener());
		com.lowagie.text.Document document = new com.lowagie.text.Document(reader.getPageSizeWithRotation(1));
		PdfSmartCopy writer = new PdfSmartCopy(document, os);
        document.open();
        PdfImportedPage pdfPage = writer.getImportedPage(reader, page);
        writer.addPage(pdfPage);
        document.close();
        writer.close();
	}
	
	public void convertAllPublicationsToImage() throws SQLException, IOException, TaskException {
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
					} catch(IOException | TaskException e) {
						e.printStackTrace();
					}
				};
			}.start();
		}
	}
	
	private int pageCount(TPublication pub, String filename) throws TaskIOException, IOException {
		InputStream is = FileUtils.getInputStream(filename);
		Document document = PdfStreamSource.newInstanceNoPassword(is, pub.getJudul()).open(new DefaultPdfSourceOpener());
		return document.getNumberOfPages();
	}
	
	private PDimension pageSize(TPublication pub, String filename, int pageNumber) throws TaskIOException, IOException {
		InputStream is = FileUtils.getInputStream(filename);
		Document document = PdfStreamSource.newInstanceNoPassword(is, pub.getJudul()).open(new DefaultPdfSourceOpener());
		Page page = document.getPageTree().getPage(pageNumber);
		return page.getSize(0);
	}
	
	private void convertPublicationToImage(TPublication pub, final String filename, PageRange range) throws MalformedURLException, IOException, TaskException {
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
