<%@page import="java.util.HashMap"%>
<%@page import="java.util.Map"%>
<%@page import="id.go.bps.digilib.models.TPublication"%>
<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>

<% TPublication pub = (TPublication) request.getAttribute("publication"); %>
<% Map<String, Object> properties = (HashMap<String, Object>) request.getAttribute("properties"); %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en">
<head>
	<title><%= pub.getJudul() %></title>
	<link rel='shortcut icon' type='image/x-icon' href='/assets/favicon.ico' />
	
	<meta name="viewport" content="width = 1050, user-scalable = no" />
	<script type="text/javascript" src="/assets/jquery-1.9.1.min.js"></script>
	<script type="text/javascript" src="/assets/turnjs/modernizr.2.5.3.min.js"></script>
	<script type="text/javascript" src="/assets/turnjs/hash.js"></script>
</head>
<body>
	<div id="canvas">
		<div class="zoom-icon zoom-icon-in"></div>
		<div class="magazine-viewport">
			<div class="container">
				<div class="magazine">
					<div ignore="1" class="next-button"></div>
					<div ignore="1" class="previous-button"></div>
				</div>
			</div>
		</div>
	</div>
	
	<script type="text/javascript">
		function loadFlipbook() {
			$('#canvas').fadeIn(1000);
			
			var flipbook = $('.magazine');
		 	
		 	if (flipbook.width()==0 || flipbook.height()==0) {
				setTimeout(loadFlipbook, 10);
				return;
			}
		 	
		 	flipbook.turn({
		 		width: 922,
		 		height: 600,
		 		duration: 1000,
		 		acceleration: !(navigator.userAgent.indexOf('Chrome')!=-1),
		 		gradients: true,
		 		autoCenter: true,
		 		elevation: 50,
		 		pages: <%= properties.get("numPages") %>,
		 		when: {
		 			turning: function(event, page, view) {
		 				
		 			},
		 			turned: function(event, page, view) {
		 				$(this).turn('center');
		 				if (page==1) { 
		 					$(this).turn('peel', 'br');
		 				}
		 			},
		 			missing: function (event, pages) {
		 				for (var i = 0; i < pages.length; i++) {
		 					var page = pages[i];
		 					var book = $(this);
		 					
		 					var element = $('<div />', {});
		 					if (book.turn('addPage', element, page)) {
		 						$('<div class="gradient">').appendTo(element);
		 						$('<div class="loader">').appendTo(element);
		 						
		 						
		 						$('<canvas>').appendTo(element);
		 					}
		 				}
		 			}
		 		}
			});
		}
	
		yepnope({
			test : Modernizr.csstransforms,
			yep: ['/assets/turnjs/turn.min.js'],
			nope: ['/assets/turnjs/turn.html4.min.js'],
			both: ['/assets/turnjs/zoom.min.js', '/assets/flipbook.js', '/assets/flipbook.css', 
			       '/assets/pdfjs/pdf.js', '/assets/pdfjs/pdf.worker.js', '/assets/pdfjs/jPdfjs.js'],
			complete: loadFlipbook
		});
	</script>
</body>
</html>