package id.go.bps.digilib.utils;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.MalformedURLException;

import jcifs.smb.SmbException;
import jcifs.smb.SmbFile;

import org.apache.commons.lang.SystemUtils;

public class FileUtils {
	public static boolean exists(String filename) throws MalformedURLException, SmbException {
		if(SystemUtils.IS_OS_WINDOWS) {
			if(new File(filename).exists()) {
				return true;
			}
		} else {
			SmbFile s = new SmbFile(filename);
			if(s.exists()) {
				return true;
			}
		}
		
		return false;
	}
	
	public static InputStream getInputStream(String filename) throws IOException {
		if(SystemUtils.IS_OS_WINDOWS) {
			return new FileInputStream(filename);
		} else {
			SmbFile s = new SmbFile(filename);
			return s.getInputStream();
		}
	}
	
	public static OutputStream getOutputStream(String filename) throws IOException {
		if(SystemUtils.IS_OS_WINDOWS) {
			return new FileOutputStream(filename);
		} else {
			SmbFile s = new SmbFile(filename);
			return s.getOutputStream();
		}
	}
}
