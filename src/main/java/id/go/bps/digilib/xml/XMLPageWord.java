package id.go.bps.digilib.xml;

public class XMLPageWord {
	private String text;
	private double left;
	private double bottom;
	private double width;
	private double height;

	public void setText(String text) {
		this.text = text;
	}

	public void setLeft(double x) {
		this.left = x;
	}

	public void setBottom(double y) {
		this.bottom = y;
	}

	public void setWidth(double width) {
		this.width = width;
	}

	public void setHeight(double height) {
		this.height = height;
	}

	public String getText() {
		return text;
	}

	public double getLeft() {
		return left;
	}

	public double getBottom() {
		return bottom;
	}

	public double getWidth() {
		return width;
	}

	public double getHeight() {
		return height;
	}
	
}