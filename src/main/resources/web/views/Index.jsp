<%@page import="id.go.bps.digilib.models.TPublication"%>
<%@page import="java.util.List"%>
<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en">
<head>
	<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
	<title>BPS Digital Library</title>
	<link rel='shortcut icon' type='image/x-icon' href='/assets/favicon.ico' />
	
	<link rel="stylesheet" href="/assets/bootstrap/bootstrap.min.css">
	<style type="text/css">
		.book-holder {
			padding-top: 15px;
		}
		.book {
		    /* padding: 15px 0 0 0; */
		    margin: auto;
			position: relative;
			z-index: 1;
			-webkit-box-shadow: 2px 2px 5px rgba(0,0,0,0.6);
			-moz-box-shadow: 2px 2px 5px rgba(0,0,0,0.6);
			-ms-box-shadow: 2px 2px 5px rgba(0,0,0,0.6);
			-o-box-shadow: 2px 2px 5px rgba(0,0,0,0.6);
			box-shadow: 2px 2px 5px rgba(0,0,0,0.6);
			-webkit-transition: -webkit-transform 0.1s;
			-webkit-transform: translate(0, 0);
			-moz-transition: -moz-transform 0.1s;
			-moz-transform: translate(0, 0);
			-ms-transition: -ms-transform 0.1s;
			-ms-transform: translate(0, 0);
			-o-transition: -o-transform 0.1s;
			-o-transform: translate(0, 0);
			transition: transform 0.1s;
			transform: translate(0, 0);
		}
		.book.hover {
			z-index: 2;
			background-color: white;
			-webkit-transform: scale3d(1.1, 1.1, 1) translate3d(0, -5px, 0);
			-moz-transform: scale3d(1.1, 1.1, 1) translate3d(0, -5px, 0);
			-ms-transform: scale3d(1.1, 1.1, 1) translate3d(0, -5px, 0);
			-o-transform: scale3d(1.1, 1.1, 1) translate3d(0, -5px, 0);
			transform: scale3d(1.1, 1.1, 1) translate3d(0, -5px, 0);
		}
		.shelf {
			top: -15px;
			z-index: -1;
			background: url(/assets/turnjs/wall-bookshelf.png);
			background-size: 100% 140%;
			background-repeat: no-repeat;
			height: 70px;

		    /* border-bottom: 30px solid #A1A194;
		    border-left: 20px solid transparent;
		    border-right: 20px solid transparent;
		    top: -15px;
		    z-index: -1; */
		}
		/* .shelf:after {
			background:url(../pics/wall-bookshelf.png);
			background-size:100%;
			background-repeat: no-repeat;
			background-position:bottom left;
			width:426px;
			height:210px;
			display:block;
			content:"";
			margin-left:-38px;
		} */
	</style>
	
	<script src="/assets/jquery-1.9.1.min.js"></script>
	<script type="text/javascript">
		jQuery(function($) {
			$(".book").each(function() {
				$(this).attr("src", $(this).attr("src-url"));
				$(this).removeAttr("src-url");
			}).mouseenter(function() {
				$(this).addClass('hover');
			}).mouseleave(function() {
				$(this).removeClass('hover');
			})
		});
	</script>
</head>
<body>
	<% List<TPublication> pubs = (List<TPublication>) request.getAttribute("pubs"); %>
	<div class="container">
	    <div class="row">
	    <% int p = 1; %>
	    <% for(TPublication pub : pubs) { %>
	    	<div class="col-xs-4 col-md-2 book-holder">
		    	<a target="_BLANK_" href="<%= "/pdf/" + pub.getId_publikasi() + "/" + pub.getJudul().replace(" ", "-") + "/jpg" %>">
		    		<img src-url="<%= "/pdf/" + pub.getId_publikasi() + "/" + pub.getJudul().replace(" ", "-") + "/1/jpg" %>" class="img-responsive book"/>
		    	</a>
	    	</div>
	    	
	    	<% if(p%6 == 0) { %>
	    		<div class="col-xs-12 shelf"></div>
	    	<% } else if(p%3 == 0) { %>
	    		<div class="col-xs-12 shelf hidden-md hidden-lg"></div>
	    	<% } %>
	    	
	    	<% p++; %>
	    <% } %>
	    <% if(p%3 != 0) { %>
	    	<div class="col-xs-12 shelf"></div>
	    <% } %>
	    </div>
	</div> 
	
	<script src="/assets/bootstrap/bootstrap.min.js"></script>
</body>
</html>