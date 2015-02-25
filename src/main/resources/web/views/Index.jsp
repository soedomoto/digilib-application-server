<%@page import="id.go.bps.digilib.models.TPublication"%>
<%@page import="java.util.List"%>
<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en">
<head>
	<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
	<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
	<title>BPS Digital Library</title>
	
	<link rel="stylesheet" href="/assets/bootstrap/bootstrap.min.css">
	<style type="text/css">
		.book {
		    padding: 15px 0 0 0;
		    margin: auto;
		}
		.shelf {
		    border-bottom: 30px solid #A1A194;
		    border-left: 20px solid transparent;
		    border-right: 20px solid transparent;
		    top: -15px;
		    z-index: -1;
		}
	</style>
	
	<script src="/assets/jquery-1.9.1.min.js"></script>
	<script type="text/javascript">
		jQuery(function($) {
			$(".book").each(function() {
				$(this).attr("src", $(this).attr("src-url"));
				$(this).removeAttr("src-url")
			})
		});
	</script>
</head>
<body>
	<%
		List<TPublication> pubs = (List<TPublication>) request.getAttribute("pubs");
	%>
	<div class="container">
	    <div class="row">
	    <% int p = 1; %>
	    <% for(TPublication pub : pubs) { %>
	    	<div class="col-xs-4 col-md-2">
	    		<img src-url="<%= "/pdf/" + pub.getId_publikasi() + "/" + pub.getJudul().replace(" ", "-") + "/cover" %>" class="img-responsive book"/>
	    	</div>
	    	
	    	<% if(p%6 == 0) { %>
	    		<div class="col-xs-12 shelf"></div>
	    	<% } else if(p%3 == 0) { %>
	    		<div class="col-xs-12 shelf hidden-md hidden-lg"></div>
	    	<% } %>
	    	
	    	<% p++; %>
	    <% } %>
	    	
	        <!-- <div class="col-xs-4 col-md-2"><img src="http://placehold.it/150x190" class="img-responsive book"/></div>
	        <div class="col-xs-4 col-md-2"><img src="http://placehold.it/150x190" class="img-responsive book"/></div>
	        <div class="col-xs-4 col-md-2"><img src="http://placehold.it/150x190" class="img-responsive book"/></div>
	        <div class="col-xs-12 shelf hidden-md hidden-lg"></div>
	        <div class="col-xs-4 col-md-2"><img src="http://placehold.it/150x190" class="img-responsive book"/></div>
	        <div class="col-xs-4 col-md-2"><img src="http://placehold.it/150x190" class="img-responsive book"/></div>
	        <div class="col-xs-4 col-md-2"><img src="http://placehold.it/150x190" class="img-responsive book"/></div>
	        <div class="col-xs-12 shelf"></div>
	        <div class="col-xs-4 col-md-2"><img src="http://placehold.it/150x190" class="img-responsive book"/></div>
	        <div class="col-xs-4 col-md-2"><img src="http://placehold.it/150x190" class="img-responsive book"/></div>
	        <div class="col-xs-4 col-md-2"><img src="http://placehold.it/150x190" class="img-responsive book"/></div>
	        <div class="col-xs-12 shelf hidden-md hidden-lg"></div>
	        <div class="col-xs-4 col-md-2"><img src="http://placehold.it/150x190" class="img-responsive book"/></div>
	        <div class="col-xs-4 col-md-2"><img src="http://placehold.it/150x190" class="img-responsive book"/></div>
	        <div class="col-xs-4 col-md-2"><img src="http://placehold.it/150x190" class="img-responsive book"/></div>
	        <div class="col-xs-12 shelf"></div> -->
	    </div>
	</div> 
	
	<script src="/assets/bootstrap/bootstrap.min.js"></script>
</body>
</html>