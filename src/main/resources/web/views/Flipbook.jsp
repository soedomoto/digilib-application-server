<%@page import="com.itextpdf.text.Rectangle"%>
<%@page import="java.util.HashMap"%>
<%@page import="java.util.Map"%>
<%@page import="id.go.bps.digilib.models.TPublication"%>
<%@page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

<% TPublication pub = (TPublication) request.getAttribute("publication"); %>
<% Map<String, Object> properties = (HashMap<String, Object>) request.getAttribute("properties"); %>
<% Rectangle docSize = (Rectangle) properties.get("docSize"); %>
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
		 					}
		 				}
		 			}
		 		}
			});
		 	
		 	$('.magazine-viewport').zoom({
				flipbook: $('.magazine'),

				max: function() { 
					
					return largeMagazineWidth()/$('.magazine').width();

				}, 

				when: {

					swipeLeft: function() {

						$(this).zoom('flipbook').turn('next');

					},

					swipeRight: function() {
						
						$(this).zoom('flipbook').turn('previous');

					},

					resize: function(event, scale, page, pageElement) {

						if (scale==1)
							loadSmallPage(page, pageElement);
						else
							loadLargePage(page, pageElement);

					},

					zoomIn: function () {

						$('.thumbnails').hide();
						$('.made').hide();
						$('.magazine').removeClass('animated').addClass('zoom-in');
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
						$('.thumbnails').fadeIn();
						$('.made').fadeIn();
						$('.zoom-icon').removeClass('zoom-icon-out').addClass('zoom-icon-in');

						setTimeout(function(){
							$('.magazine').addClass('animated').removeClass('zoom-in');
							resizeViewport();
						}, 0);

					}
				}
			});

			// Zoom event

			if ($.isTouch)
				$('.magazine-viewport').bind('zoom.doubleTap', zoomTo);
			else
				$('.magazine-viewport').bind('zoom.tap', zoomTo);


			// Using arrow keys to turn the page

			$(document).keydown(function(e){

				var previous = 37, next = 39, esc = 27;

				switch (e.keyCode) {
					case previous:

						// left arrow
						$('.magazine').turn('previous');
						e.preventDefault();

					break;
					case next:

						//right arrow
						$('.magazine').turn('next');
						e.preventDefault();

					break;
					case esc:
						
						$('.magazine-viewport').zoom('zoomOut');	
						e.preventDefault();

					break;
				}
			});

			// URIs - Format #/page/1 

			Hash.on('^page\/([0-9]*)$', {
				yep: function(path, parts) {
					var page = parts[1];

					if (page!==undefined) {
						if ($('.magazine').turn('is'))
							$('.magazine').turn('page', page);
					}

				},
				nop: function(path) {

					if ($('.magazine').turn('is'))
						$('.magazine').turn('page', 1);
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
				
				$('.magazine').turn('next');

			});

			// Events for the next button
			
			$('.previous-button').bind($.mouseEvents.over, function() {
				
				$(this).addClass('previous-button-hover');

			}).bind($.mouseEvents.out, function() {
				
				$(this).removeClass('previous-button-hover');

			}).bind($.mouseEvents.down, function() {
				
				$(this).addClass('previous-button-down');

			}).bind($.mouseEvents.up, function() {
				
				$(this).removeClass('previous-button-down');

			}).click(function() {
				
				$('.magazine').turn('previous');

			});


			resizeViewport();

			$('.magazine').addClass('animated');
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