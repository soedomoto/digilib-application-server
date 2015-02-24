package id.go.bps.digilib.models;

import com.j256.ormlite.field.DatabaseField;
import com.j256.ormlite.table.DatabaseTable;

/**
 * 
 * @author Erikaris
 * 

CREATE TABLE t_application_settings (
    id integer NOT NULL,
    server_name character varying(100),
    server_ip character varying(100),
    pdf_folder character varying(100),
    cover_folder character varying(100),
    map_foler character varying(100),
    ftp_server character varying,
    ftp_username character varying(50),
    ftp_password character varying(50)
);

 * 
 */

@DatabaseTable(tableName = "t_application_settings")
public class TApplicationSettings {
	@DatabaseField(id = true)
	private Integer id;
	@DatabaseField
	private String server_name;
	@DatabaseField
	private String server_ip;
	@DatabaseField
	private String pdf_folder;
	@DatabaseField
	private String cover_folder;
	@DatabaseField
	private String map_folder;
	@DatabaseField
	private String ftp_server;
	@DatabaseField
	private String ftp_username;
	@DatabaseField
	private String ftp_password;
	
	public Integer getId() {
		return id;
	}
	public void setId(Integer id) {
		this.id = id;
	}
	public String getServer_name() {
		return server_name;
	}
	public void setServer_name(String server_name) {
		this.server_name = server_name;
	}
	public String getServer_ip() {
		return server_ip;
	}
	public void setServer_ip(String server_ip) {
		this.server_ip = server_ip;
	}
	public String getPdf_folder() {
		return pdf_folder;
	}
	public void setPdf_folder(String pdf_folder) {
		this.pdf_folder = pdf_folder;
	}
	public String getCover_folder() {
		return cover_folder;
	}
	public void setCover_folder(String cover_folder) {
		this.cover_folder = cover_folder;
	}
	public String getMap_folder() {
		return map_folder;
	}
	public void setMap_folder(String map_folder) {
		this.map_folder = map_folder;
	}
	public String getFtp_server() {
		return ftp_server;
	}
	public void setFtp_server(String ftp_server) {
		this.ftp_server = ftp_server;
	}
	public String getFtp_username() {
		return ftp_username;
	}
	public void setFtp_username(String ftp_username) {
		this.ftp_username = ftp_username;
	}
	public String getFtp_password() {
		return ftp_password;
	}
	public void setFtp_password(String ftp_password) {
		this.ftp_password = ftp_password;
	}
}
