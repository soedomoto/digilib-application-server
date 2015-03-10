package id.go.bps.digilib.utils;

import static org.sejda.core.support.io.IOUtils.createTemporaryBuffer;
import static org.sejda.impl.icepdf.component.PdfToBufferedImageProvider.toBufferedImage;
import id.go.bps.digilib.task.ADirectoryTaskOutput;
import id.go.bps.digilib.task.BasePdfToImageTask;
import id.go.bps.digilib.xml.XMLPDFText;
import id.go.bps.digilib.xml.XMLPageText;

import java.awt.geom.Rectangle2D.Float;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.util.Set;

import org.icepdf.core.pobjects.Page;
import org.icepdf.core.pobjects.graphics.text.LineText;
import org.icepdf.core.pobjects.graphics.text.PageText;
import org.icepdf.core.pobjects.graphics.text.WordText;
import org.sejda.impl.icepdf.component.DefaultPdfSourceOpener;
import org.sejda.model.exception.TaskException;
import org.sejda.model.exception.TaskExecutionException;
import org.sejda.model.exception.TaskIOException;
import org.sejda.model.input.PdfSourceOpener;
import org.sejda.model.parameter.image.AbstractPdfToImageParameters;
import org.sejda.model.parameter.image.AbstractPdfToMultipleImageParameters;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PdfToImageConverter<T extends AbstractPdfToMultipleImageParameters> extends BasePdfToImageTask<AbstractPdfToImageParameters> {
	private static final Logger LOG = LoggerFactory.getLogger(PdfToImageConverter.class);
    private PdfSourceOpener<org.icepdf.core.pobjects.Document> sourceOpener = new DefaultPdfSourceOpener();
    private org.icepdf.core.pobjects.Document pdfDocument = null;
	private Set<Integer> requestedPages;

    public void before(AbstractPdfToImageParameters parameters) throws TaskExecutionException {
        super.before(parameters);
        try {
			pdfDocument = parameters.getSource().open(sourceOpener);
		} catch (TaskIOException e) {
			LOG.error(e.getMessage() + " : " + parameters.getSource().getName(), e);
		}
		requestedPages = ((AbstractPdfToMultipleImageParameters) parameters).getPages(pdfDocument.getNumberOfPages());
    }
    
	@Override
	public void execute(AbstractPdfToImageParameters parameters) throws TaskException {
		try {
			for (int currentPage : requestedPages) {
				if(((ADirectoryTaskOutput) parameters.getOutput()).exists(currentPage + "")) {
					continue;
				}
				
				File tmpFile = createTemporaryBuffer();
				getWriter().openWriteDestination(tmpFile, parameters);
				LOG.debug("Starting convert {} page {}.", parameters.getSource().getName(), currentPage);
				getWriter().write(toBufferedImage(pdfDocument, zeroBased(currentPage), parameters), parameters);
	            getWriter().closeDestination();
	            ((ADirectoryTaskOutput) parameters.getOutput()).accept(tmpFile, currentPage + "");
			}
		} catch (Exception e) {
			LOG.error(e.getMessage() + " : " + parameters.getSource().getName(), e);
		}
	}
	
	public void getPageText(AbstractPdfToImageParameters parameters) throws TaskException, IOException {
		ADirectoryTaskOutput output = ((ADirectoryTaskOutput) parameters.getOutput());
		if(FileUtils.exists(output.getDestination() + File.separator + "text" + ".xml")) return;
		
		XMLPDFText xpdt = new XMLPDFText();
		for (int currentPage=1; currentPage<= pdfDocument.getNumberOfPages(); currentPage++) {
			int pageNumber = zeroBased(currentPage);
			
			try {
				Page page = pdfDocument.getPageTree().getPage(pageNumber);
				PageText pageText = page.getViewText();
				XMLPageText xpt = new XMLPageText();
				xpt.setPage(currentPage);
				for(LineText line : pageText.getPageLines()) {
					for(WordText word : line.getWords()) {
						Float bound = word.getBounds();
						xpt.addWord(word.getText(), bound.getX(), bound.getY(), bound.getWidth(), bound.getHeight());
						//LOG.debug("{} --> {}", bound.getX()+","+bound.getY()+","+bound.getWidth()+","+bound.getHeight(), word.getText());
					}
				}
				
				xpdt.add(xpt);
			} catch(Exception e) {}
		}
		
		OutputStream os = FileUtils.getOutputStream(output.getDestination() + File.separator + "text" + ".xml");
		xpdt.write(os);
	}
	
	@Override
    public void after() {
        super.after();
        if (pdfDocument != null) {
            pdfDocument.dispose();
        }
    }
	
	private int zeroBased(int oneBased) {
        return oneBased - 1;
    }
}