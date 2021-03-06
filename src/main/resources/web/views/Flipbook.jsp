<%@page import="org.icepdf.core.pobjects.PDimension"%>
<%@page import="java.util.HashMap"%>
<%@page import="java.util.Map"%>
<%@page import="id.go.bps.digilib.models.TPublication"%>
<%@page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<% TPublication pub = (TPublication) request.getAttribute("publication"); %>
<% Map<String, Object> properties = (HashMap<String, Object>) request.getAttribute("properties"); %>
<% PDimension docSize = (PDimension) properties.get("docSize"); %>
<% String format = (String) properties.get("format"); %>
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
		var flipbook = $('.magazine');
		var viewport = $('.magazine-viewport');
		var format = '<%= format %>';
		
		function loadFlipbook() {
			$('#canvas').fadeIn(1000);
		 	
		 	if (flipbook.width()==0 || flipbook.height()==0) {
				setTimeout(loadFlipbook, 10);
				return;
			}
		 	
		 	flipbook.turn({
		 		width: <%= new Float(docSize.getWidth()).intValue() * 2 %>,
		 		height: <%= new Float(docSize.getHeight()).intValue() %>,
		 		duration: 1000,
		 		acceleration: !(navigator.userAgent.indexOf('Chrome')!=-1),
		 		gradients: true,
		 		autoCenter: true,
		 		elevation: 50,
		 		pages: <%= properties.get("numPages") %>,
		 		when: {
		 			turning: function(event, page, view) {
		 				Hash.go('page/' + page).update();
		 				disableControls(page);
		 			},
		 			turned: function(event, page, view) {
		 				disableControls(page);
		 				$(this).turn('center');
		 				if (page==1) { 
		 					$(this).turn('peel', 'br');
		 				}
		 				rezoomCanvas();
		 			},
		 			missing: function (event, pages) {
		 				for (var i = 0; i < pages.length; i++) {
		 					var page = pages[i];
		 					var book = $(this);
		 					
		 					var element = $('<div />', {});
		 					if (book.turn('addPage', element, page)) {
		 						$('<div class="gradient">').appendTo(element);
		 						$('<div class="loader">').appendTo(element);
		 						
		 						if(format == "pdf") {
			 						var pdfjs = element.jPdfjs({
			 							onPdfOpened: function(jpdfjs, pdf, numPages) {
			 								jpdfjs.renderPage(1, $('<canvas>').get(0), 1, false);
			 							}, 
			 							onPdfRendered: function(jpdfjs, pageNumber, canvas, scale, pageObject) {
			 								$(canvas).appendTo(jpdfjs);
			 								rezoomCanvas();
			 								$(jpdfjs.get(0)).find('.loader').remove();
			 							}
			 						});
			 						pdfjs.open('<%= properties.get("baseUrl") %>/' + page);
			 					} else if(format == "jpg") {
			 						var img = $('<img />').data(element);
			 						img.mousedown(function(e) {
			 							e.preventDefault();
			 						});
			 						img.load(function() {
			 							$(this).css({width: '100%', height: '100%'});
			 							$(this).appendTo($(this).data());
			 							$(this).data().find('.loader').remove();
			 						});
			 						img.attr('src', '<%= properties.get("baseUrl") %>/' + page + '/jpg');
			 					}
		 					}
		 				}
		 			}
		 		}
			});
		 	
		 	viewport.zoom({
				flipbook: flipbook,
				max: function() { 
					return largeMagazineWidth()/flipbook.width();
				}, 
				when: {
					swipeLeft: function() {
						$(this).zoom('flipbook').turn('next');
					},
					swipeRight: function() {
						$(this).zoom('flipbook').turn('previous');
					},
					resize: function(event, scale, page, pageElement) {
						if (scale!=1) {
							var c = pageElement.find('canvas');
							c.css('zoom', scale * c.css('zoom'));
						}
					},
					zoomIn: function () {
						flipbook.removeClass('animated').addClass('zoom-in');
						$('.zoom-icon').removeClass('zoom-icon-in').addClass('zoom-icon-out');
						
						if (!window.escTip && !$.isTouch) {
							escTip = true;
							$('<div />', {'class': 'exit-message'}).
								html('<div>Press ESC to exit</div>').
								appendTo($('body')).
								delay(2000).
								animate({opacity:0}, 500, function() {
									$(this).remove();
								});
						}
					}, 
					zoomOut: function () {
						$('.exit-message').hide();
						$('.zoom-icon').removeClass('zoom-icon-out').addClass('zoom-icon-in');

						setTimeout(function(){
							flipbook.addClass('animated').removeClass('zoom-in');
							resizeViewport();
						}, 0);

					}
				}
			});
		 	
		 	if ($.isTouch)
				viewport.bind('zoom.doubleTap', zoomTo);
			else
				viewport.bind('zoom.tap', zoomTo);
		 	
		 	$(document).keydown(function(e){
		 		var previous = 37, next = 39, esc = 27;
		 		switch (e.keyCode) {
					case previous:
						// left arrow
						flipbook.turn('previous');
						e.preventDefault();
					break;
					case next:
						//right arrow
						flipbook.turn('next');
						e.preventDefault();
					break;
					case esc:
						viewport.zoom('zoomOut');	
						e.preventDefault();
					break;
				}
			});
		 	
			Hash.on('^page\/([0-9]*)$', {
				yep: function(path, parts) {
					var page = parts[1];
					if (page!==undefined) {
						if (flipbook.turn('is'))
							flipbook.turn('page', page);
					}
				},
				nop: function(path) {
					if (flipbook.turn('is'))
						flipbook.turn('page', 1);
				}
			});


			$(window).resize(function() {
				resizeViewport();
			}).bind('orientationchange', function() {
				resizeViewport();
			});
			
			$('.next-button').bind($.mouseEvents.over, function() {
				$(this).addClass('next-button-hover');
			}).bind($.mouseEvents.out, function() {
				$(this).removeClass('next-button-hover');
			}).bind($.mouseEvents.down, function() {
				$(this).addClass('next-button-down');
			}).bind($.mouseEvents.up, function() {
				$(this).removeClass('next-button-down');
			}).click(function() {
				flipbook.turn('next');
			});
			
			$('.previous-button').bind($.mouseEvents.over, function() {
				$(this).addClass('previous-button-hover');
			}).bind($.mouseEvents.out, function() {
				$(this).removeClass('previous-button-hover');
			}).bind($.mouseEvents.down, function() {
				$(this).addClass('previous-button-down');
			}).bind($.mouseEvents.up, function() {
				$(this).removeClass('previous-button-down');
			}).click(function() {
				flipbook.turn('previous');
			});
			
			$('.zoom-icon').bind('mouseover', function() {
				if ($(this).hasClass('zoom-icon-in'))
					$(this).addClass('zoom-icon-in-hover');
				if ($(this).hasClass('zoom-icon-out'))
			 		$(this).addClass('zoom-icon-out-hover');
			}).bind('mouseout', function() {
				if ($(this).hasClass('zoom-icon-in'))
					$(this).removeClass('zoom-icon-in-hover');
				if ($(this).hasClass('zoom-icon-out'))
					$(this).removeClass('zoom-icon-out-hover');
			}).bind('click', function() {
				if ($(this).hasClass('zoom-icon-in'))
					$('.magazine-viewport').zoom('zoomIn');
				else if ($(this).hasClass('zoom-icon-out'))	
					$('.magazine-viewport').zoom('zoomOut');
			});

			resizeViewport();
			flipbook.addClass('animated');
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