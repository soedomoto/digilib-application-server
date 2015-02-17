package id.go.bps.digilib.models;

import java.util.Date;

import com.j256.ormlite.field.DatabaseField;
import com.j256.ormlite.table.DatabaseTable;

/**
 * 
 * @author Erikaris
 * 

CREATE TABLE t_publikasi (
    id_publikasi character varying(13) NOT NULL,
    kd_bahan_pustaka character(3) NOT NULL,
    bln_terima character(2) NOT NULL,
    thn_terima character(4) NOT NULL,
    no_urut_bi character(4) NOT NULL,
    kd_subyek character(7) NOT NULL,
    judul text,
    judul_paralel text,
    kd_produsen character varying(11) NOT NULL,
    kd_table character(1) NOT NULL,
    kd_bahasa integer,
    jml_eks integer,
    jml_hal integer,
    p_buku numeric(4,1),
    l_buku numeric(4,1),
    is_table character(1) DEFAULT 0 NOT NULL,
    is_grafik character(1) DEFAULT 0 NOT NULL,
    is_peta character(1) DEFAULT 0 NOT NULL,
    flag_h character varying(2),
    flag_s character varying(2),
    pdf_dir character varying(255),
    cover_dir character varying(255),
    harga_perolehan numeric(9,2),
    nip_lama character varying(20),
    tgl_entri date,
    nip character varying(18),
    is_ilus character(1) DEFAULT 0 NOT NULL,
    jml_rom character varying(50),
    is_full_entry character(1) DEFAULT 0 NOT NULL,
    bulan_terbit character(2),
    tahun_terbit character(4),
    nip_editor character varying(18),
    tgl_edit date,
    kd_periode character varying(3) NOT NULL
);

 *
 */

@DatabaseTable(tableName = "t_publikasi")
public class TPublication {
	@DatabaseField(id = true)
	private String id_publikasi;
	@DatabaseField
	private String kd_bahan_pustaka;
	@DatabaseField
	private String bln_terima;
	@DatabaseField
	private String thn_terima;
	@DatabaseField
	private String no_urut_bi;
	@DatabaseField
	private String kd_subyek;
	@DatabaseField
	private String judul;
	@DatabaseField
	private String judul_paralel;
	@DatabaseField
	private String kd_produsen;
	@DatabaseField
	private String kd_table;
	@DatabaseField
	private Integer kd_bahasa;
	@DatabaseField
	private Integer jml_eks;
	@DatabaseField
	private Integer jml_hal;
	@DatabaseField
	private Float p_buku;
	@DatabaseField
	private Float l_buku;
	@DatabaseField
	private String is_table;
	@DatabaseField
	private String is_grafik;
	@DatabaseField
	private String is_peta;
	@DatabaseField
	private String flag_h;
	@DatabaseField
	private String flag_s;
	@DatabaseField
	private String pdf_dir;
	@DatabaseField
	private String cover_dir;
	@DatabaseField
	private Float harga_perolehan;
	@DatabaseField
	private String nip_lama;
	@DatabaseField
	private Date tgl_entri;
	@DatabaseField
	private String nip;
	@DatabaseField
	private String is_ilus;
	@DatabaseField
	private String jml_rom;
	@DatabaseField
	private String is_full_entry;
	@DatabaseField
	private String bulan_terbit;
	@DatabaseField
	private String tahun_terbit;
	@DatabaseField
	private String nip_editor;
	@DatabaseField
	private Date tgl_edit;
	@DatabaseField
	private String kd_periode;
	
	public String getId_publikasi() {
		return id_publikasi;
	}
	public void setId_publikasi(String id_publikasi) {
		this.id_publikasi = id_publikasi;
	}
	public String getKd_bahan_pustaka() {
		return kd_bahan_pustaka;
	}
	public void setKd_bahan_pustaka(String kd_bahan_pustaka) {
		this.kd_bahan_pustaka = kd_bahan_pustaka;
	}
	public String getBln_terima() {
		return bln_terima;
	}
	public void setBln_terima(String bln_terima) {
		this.bln_terima = bln_terima;
	}
	public String getThn_terima() {
		return thn_terima;
	}
	public void setThn_terima(String thn_terima) {
		this.thn_terima = thn_terima;
	}
	public String getNo_urut_bi() {
		return no_urut_bi;
	}
	public void setNo_urut_bi(String no_urut_bi) {
		this.no_urut_bi = no_urut_bi;
	}
	public String getKd_subyek() {
		return kd_subyek;
	}
	public void setKd_subyek(String kd_subyek) {
		this.kd_subyek = kd_subyek;
	}
	public String getJudul() {
		return judul;
	}
	public void setJudul(String judul) {
		this.judul = judul;
	}
	public String getJudul_paralel() {
		return judul_paralel;
	}
	public void setJudul_paralel(String judul_paralel) {
		this.judul_paralel = judul_paralel;
	}
	public String getKd_produsen() {
		return kd_produsen;
	}
	public void setKd_produsen(String kd_produsen) {
		this.kd_produsen = kd_produsen;
	}
	public String getKd_table() {
		return kd_table;
	}
	public void setKd_table(String kd_table) {
		this.kd_table = kd_table;
	}
	public Integer getKd_bahasa() {
		return kd_bahasa;
	}
	public void setKd_bahasa(Integer kd_bahasa) {
		this.kd_bahasa = kd_bahasa;
	}
	public Integer getJml_eks() {
		return jml_eks;
	}
	public void setJml_eks(Integer jml_eks) {
		this.jml_eks = jml_eks;
	}
	public Integer getJml_hal() {
		return jml_hal;
	}
	public void setJml_hal(Integer jml_hal) {
		this.jml_hal = jml_hal;
	}
	public Float getP_buku() {
		return p_buku;
	}
	public void setP_buku(Float p_buku) {
		this.p_buku = p_buku;
	}
	public Float getL_buku() {
		return l_buku;
	}
	public void setL_buku(Float l_buku) {
		this.l_buku = l_buku;
	}
	public String getIs_table() {
		return is_table;
	}
	public void setIs_table(String is_table) {
		this.is_table = is_table;
	}
	public String getIs_grafik() {
		return is_grafik;
	}
	public void setIs_grafik(String is_grafik) {
		this.is_grafik = is_grafik;
	}
	public String getIs_peta() {
		return is_peta;
	}
	public void setIs_peta(String is_peta) {
		this.is_peta = is_peta;
	}
	public String getFlag_h() {
		return flag_h;
	}
	public void setFlag_h(String flag_h) {
		this.flag_h = flag_h;
	}
	public String getFlag_s() {
		return flag_s;
	}
	public void setFlag_s(String flag_s) {
		this.flag_s = flag_s;
	}
	public String getPdf_dir() {
		return pdf_dir;
	}
	public void setPdf_dir(String pdf_dir) {
		this.pdf_dir = pdf_dir;
	}
	public String getCover_dir() {
		return cover_dir;
	}
	public void setCover_dir(String cover_dir) {
		this.cover_dir = cover_dir;
	}
	public Float getHarga_perolehan() {
		return harga_perolehan;
	}
	public void setHarga_perolehan(Float harga_perolehan) {
		this.harga_perolehan = harga_perolehan;
	}
	public String getNip_lama() {
		return nip_lama;
	}
	public void setNip_lama(String nip_lama) {
		this.nip_lama = nip_lama;
	}
	public Date getTgl_entri() {
		return tgl_entri;
	}
	public void setTgl_entri(Date tgl_entri) {
		this.tgl_entri = tgl_entri;
	}
	public String getNip() {
		return nip;
	}
	public void setNip(String nip) {
		this.nip = nip;
	}
	public String getIs_ilus() {
		return is_ilus;
	}
	public void setIs_ilus(String is_ilus) {
		this.is_ilus = is_ilus;
	}
	public String getJml_rom() {
		return jml_rom;
	}
	public void setJml_rom(String jml_rom) {
		this.jml_rom = jml_rom;
	}
	public String getIs_full_entry() {
		return is_full_entry;
	}
	public void setIs_full_entry(String is_full_entry) {
		this.is_full_entry = is_full_entry;
	}
	public String getBulan_terbit() {
		return bulan_terbit;
	}
	public void setBulan_terbit(String bulan_terbit) {
		this.bulan_terbit = bulan_terbit;
	}
	public String getTahun_terbit() {
		return tahun_terbit;
	}
	public void setTahun_terbit(String tahun_terbit) {
		this.tahun_terbit = tahun_terbit;
	}
	public String getNip_editor() {
		return nip_editor;
	}
	public void setNip_editor(String nip_editor) {
		this.nip_editor = nip_editor;
	}
	public Date getTgl_edit() {
		return tgl_edit;
	}
	public void setTgl_edit(Date tgl_edit) {
		this.tgl_edit = tgl_edit;
	}
	public String getKd_periode() {
		return kd_periode;
	}
	public void setKd_periode(String kd_periode) {
		this.kd_periode = kd_periode;
	}
}
