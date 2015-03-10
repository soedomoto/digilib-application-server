package id.go.bps.digilib.xml;

import java.util.ArrayList;

public class XMLPageText extends ArrayList<XMLPageWord> {
	private static final long serialVersionUID = 1L;
	private int page;

	public int getPage() {
		return page;
	}

	public void setPage(int page) {
		this.page = page;
	}
	
	public void addWord(String text, double x, double y, double width,
			double height) {
		XMLPageWord xpw = new XMLPageWord();
		xpw.setText(text);
		xpw.setLeft(x);
		xpw.setBottom(y);
		xpw.setWidth(width);
		xpw.setHeight(height);
		this.add(xpw);
	}
}