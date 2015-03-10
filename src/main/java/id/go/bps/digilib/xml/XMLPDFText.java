package id.go.bps.digilib.xml;

import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;

import com.thoughtworks.xstream.XStream;

public class XMLPDFText extends ArrayList<XMLPageText> {
	private static final long serialVersionUID = 1L;
	
	public void addPage(XMLPageText page) {
		this.add(page);
	}
	
	public static XMLPDFText read(InputStream is) {
		return (XMLPDFText) new XStream().fromXML(is);
	}

	public void write(OutputStream os) {
		new XStream().toXML(this, os);
	}
}