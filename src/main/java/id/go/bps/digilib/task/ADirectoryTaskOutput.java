package id.go.bps.digilib.task;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.MalformedURLException;

import jcifs.smb.SmbException;
import jcifs.smb.SmbFile;

import org.apache.commons.io.IOUtils;
import org.apache.commons.lang.SystemUtils;
import org.sejda.model.exception.TaskOutputVisitException;
import org.sejda.model.output.MultipleTaskOutput;
import org.sejda.model.output.SingleTaskOutput;
import org.sejda.model.output.TaskOutputDispatcher;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ADirectoryTaskOutput implements MultipleTaskOutput<String>, SingleTaskOutput<String> {
	private static final Logger LOG = LoggerFactory.getLogger(ADirectoryTaskOutput.class);
	private String outDir;

	public ADirectoryTaskOutput(String outDir) {
		this.outDir = outDir;
	}
	
	public boolean exists(String name) throws MalformedURLException, SmbException {
		if(SystemUtils.IS_OS_WINDOWS) {
			File of = new File(getDestination() + File.separator + name + ".jpg");
			return of.exists();
		} else {
			SmbFile of = new SmbFile(getDestination() + File.separator + name + ".jpg");
			return of.exists();
		}
	}

	public void accept(File tmpFile, String name) throws IOException {
		OutputStream os;
		if(SystemUtils.IS_OS_WINDOWS) {
			File of = new File(getDestination() + File.separator + name + ".jpg");
			if(! of.getParentFile().exists()) of.getParentFile().mkdirs();
			os = new FileOutputStream(of);
		} else {
			SmbFile of = new SmbFile(getDestination() + File.separator + name + ".jpg");
			if(! new SmbFile(getDestination()).exists()) new SmbFile(getDestination()).mkdirs();
			os = of.getOutputStream();
		}
		
		FileInputStream input = null;
		try {
			input = new FileInputStream(tmpFile);
            IOUtils.copy(input, os);
        } finally {
        	LOG.debug("Succesfully convert to {}.", getDestination() + File.separator + name + ".jpg");
            IOUtils.closeQuietly(input);
            delete(tmpFile);
        }
	}
	
	private static void delete(File file) {
        if (!file.delete()) {
            LOG.warn("Unable to delete temporary file {}", file);
        }
    }

	@Override
	public String getDestination() {		
		return outDir;
	}

	@Override
	public void accept(TaskOutputDispatcher dispatcher) throws TaskOutputVisitException {
		
	}

}
