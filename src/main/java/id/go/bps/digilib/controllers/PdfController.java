package id.go.bps.digilib.controllers;

import id.go.bps.digilib.models.TPublication;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.MalformedURLException;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;

import javax.imageio.ImageIO;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import jcifs.smb.SmbFile;

import org.apache.commons.io.IOUtils;
import org.apache.commons.lang.SystemUtils;
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
import com.itextpdf.text.pdf.PdfCopy;
import com.itextpdf.text.pdf.PdfImportedPage;
import com.itextpdf.text.pdf.PdfReader;
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
		
		boolean exists = false;
		String jpgName = filename.replace(".pdf", "") + File.separator + page + ".jpg";
		if(SystemUtils.IS_OS_WINDOWS) {
			if(new File(jpgName).exists()) {
				exists = true;
				IOUtils.copy(new FileInputStream(jpgName), resp.getOutputStream());
			}
		} else {
			SmbFile s = new SmbFile(jpgName);
			if(s.exists()) {
				exists = true;
				IOUtils.copy(s.getInputStream(), resp.getOutputStream());
			}
		}
		
		if(!exists) {
			ByteArrayOutputStream baos = new ByteArrayOutputStream();
			extractPageToJpeg(page, is, baos);
			IOUtils.copy(new ByteArrayInputStream(baos.toByteArray()), resp.getOutputStream());
			if(SystemUtils.IS_OS_WINDOWS) {
				File oDir = new File(jpgName).getParentFile();
				if(! oDir.exists()) oDir.mkdirs();
				IOUtils.copy(new ByteArrayInputStream(baos.toByteArray()), new FileOutputStream(jpgName));
			} else {
				SmbFile oDir = new SmbFile(new SmbFile(jpgName).getParent());
				if(! oDir.exists()) oDir.mkdirs();
				IOUtils.copy(new ByteArrayInputStream(baos.toByteArray()), new SmbFile(jpgName).getOutputStream());
			}
		}
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
        	
        	InputStream is = null;
    		if(SystemUtils.IS_OS_WINDOWS) {
    			is = new FileInputStream(new File(filename));
    		} else {
    			is = new SmbFile(filename).getInputStream();
    		}
        	
    		PDDocument doc = PDDocument.loadNonSeq(is, null);
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
		PdfCopy writer = new PdfCopy(document, output);
        //writer.setFullCompression();
        document.open();
        PdfImportedPage pdfPage = writer.getImportedPage(reader, page);
        writer.addPage(pdfPage);
        document.close();
        writer.close();
	}
	
	/**
	 * 
	 * @param page Start from 1
	 * @param is
	 * @param os
	 * @return 
	 * @throws IOException 
	 */
	private void extractPageToJpeg(int page, InputStream is, OutputStream os) throws IOException {
		PDDocument doc = PDDocument.loadNonSeq(is, null);
		PDPage pdfPage = (PDPage) doc.getDocumentCatalog().getAllPages().get(page-1);
		BufferedImage bi = pdfPage.convertToImage();
		ImageIO.write(bi, "jpg", os);
	}
	
	public void convertToImage() throws SQLException, IOException, DocumentException {
		List<TPublication> pubs = tPublicationDao.queryForAll();
		Iterator<TPublication> itr = pubs.iterator();
		while(itr.hasNext()) {
			TPublication pub = itr.next();
			String filename = getFilename(pub);
			
			if(SystemUtils.IS_OS_WINDOWS) {
				if(new File(filename).exists()) {
					convertPubToImage(pub, filename);
				}
			} else {
				if(new SmbFile(filename).exists()) {
					convertPubToImage(pub, filename);
				}
			}
		}
	}
	
	private void convertPubToImage(TPublication pub, final String filename) throws MalformedURLException, IOException, DocumentException {
		String oDir;
		if(SystemUtils.IS_OS_WINDOWS) {
			File outDir = new File(filename.replace(".pdf", ""));
			outDir.mkdirs();
			oDir = outDir.getPath();
		} else {
			SmbFile outDir = new SmbFile(filename.replace(".pdf", ""));
			outDir.mkdirs();
			oDir = outDir.getPath();
		}
		
		InputStream pdfIs = null;
		if(SystemUtils.IS_OS_WINDOWS) {
			pdfIs = new FileInputStream(new File(filename));
		} else {
			pdfIs = new SmbFile(filename).getInputStream();
		}
		
		final String oDirTmp = oDir;
		PdfReader reader = new PdfReader(pdfIs);
		for(int i=1; i<reader.getNumberOfPages()+1; i++) {
			final int iTmp = i;
			new Thread() {
				public void run() {
					try {
						InputStream jpgIs = null;
						if(SystemUtils.IS_OS_WINDOWS) {
							jpgIs = new FileInputStream(new File(filename));
						} else {
							jpgIs = new SmbFile(filename).getInputStream();
						}
						
						boolean exists = false;
						OutputStream os = null;
						if(SystemUtils.IS_OS_WINDOWS) {
							File f = new File(oDirTmp + File.separator + iTmp + ".jpg");
							os = new FileOutputStream(f);
							exists = f.exists();
						} else {
							SmbFile f = new SmbFile(oDirTmp + File.separator + iTmp + ".jpg");
							os = f.getOutputStream();
							exists = f.exists();
						}
						
						extractPageToJpeg(iTmp, jpgIs, os);
					} catch(Exception ex) {
						ex.printStackTrace();
					}
				};
			}.start();
		}
	}
}
