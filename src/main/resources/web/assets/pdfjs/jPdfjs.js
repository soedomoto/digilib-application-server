/**
 * jQuery PdfJS Plugin
 * 
 * @copyright	Copyright (c) 2015 Soedomoto
 * @version		0.1-beta
 * 
 */

PDFJS.disableWorker = true;
(function($) {
	$.fn.jPdfjs = function(options) {
		var jpdfjs = this;
		var options = $.extend({
			onBeforePdfOpened : function() {}, 
			onPdfOpened : function() {}, 
			onPdfOpenedError : function() {}, 
			onPdfOpenedProgress : function() {}, 
			onBeforePdfRendered : function() {}, 
			onPdfRendered : function() {}, 
			onBeforeTextExtracted : function() {}, 
			onTextExtracted : function() {}
		}, options);
		
		jpdfjs = $.extend(jpdfjs, {
			numPages : 0, 
			pdfObject : null, 
			textRaw : "", 
			textDivs : [], 
			options : options,
			open : function(src) {
				options.onBeforePdfOpened(jpdfjs, src);
				PDFJS.getDocument(src).then(
					function getDocumentCallback(pdf) {
						jpdfjs.numPages = pdf.numPages;
						jpdfjs.pdfObject = pdf;
						options.onPdfOpened(jpdfjs, pdf, jpdfjs.numPages);
					}, 
					function getDocumentError(message, exception) {
						options.onPdfOpenedError(jpdfjs, message, exception);
					}, 
					function getDocumentProgress(progressData) {
						var percentage = 100 * (progressData.loaded / progressData.total);
						options.onPdfOpenedProgress(jpdfjs, percentage);
					}
				);
				
				return jpdfjs;
			}, 
			renderPage : function(pageNumber, canvas, scale, isExtractText) {
				options.onBeforePdfRendered(jpdfjs, pageNumber, canvas, scale, isExtractText);
				jpdfjs.pdfObject.getPage(pageNumber).then(function(pageObject) {
					var viewport = pageObject.getViewport(scale);
	                var context = canvas.getContext('2d');
	                canvas.height = viewport.height;
	                canvas.width = viewport.width;
	                pageObject.render({
	                	canvasContext: context, 
	                	viewport: viewport
	                });
	                options.onPdfRendered(jpdfjs, pageNumber, canvas, scale, pageObject);
	                
	                if(isExtractText) {
	                	jpdfjs.extractText(pageNumber, pageObject, scale);
	                }
				});
				
				return jpdfjs;
			}, 
			extractText : function(pageNumber, pageObject, scale) {
				options.onBeforeTextExtracted(jpdfjs, pageNumber);
				pageObject.getTextContent().then(function(textContent) {
					var textItems = textContent.items;
					var styles = textContent.styles;
					var textRaw = "";
					var textDivs = [];
					for (var i = 0, len = textItems.length; i < len; i++) {
						var geom = textItems[i];
						var style = styles[geom.fontName];
						textRaw += geom.str;
						
						var textDiv = document.createElement('div');
						if (isAllWhitespace(geom.str)) {
							textDiv.dataset.isWhitespace = true;
						}
						textDiv.textContent = geom.str;
						
						var tx = PDFJS.Util.transform(this.viewport.transform, geom.transform);
						var angle = Math.atan2(tx[1], tx[0]);
						if (style.vertical) {
							angle += Math.PI / 2;
						}
						var fontHeight = Math.sqrt((tx[2] * tx[2]) + (tx[3] * tx[3]));
						var fontAscent = fontHeight;
						if (style.ascent) {
							fontAscent = style.ascent * fontAscent;
						} else if (style.descent) {
							fontAscent = (1 + style.descent) * fontAscent;
						}
						
						var left;
						var top;
						if (angle === 0) {
							left = tx[4];
							top = tx[5] - fontAscent;
						} else {
							left = tx[4] + (fontAscent * Math.sin(angle));
							top = tx[5] - (fontAscent * Math.cos(angle));
						}
						
						textDiv.style.left = left + 'px';
						textDiv.style.top = top + 'px';
						textDiv.style.fontSize = fontHeight + 'px';
						textDiv.style.fontFamily = style.fontFamily;
						
						if (PDFJS.pdfBug) {
							textDiv.dataset.fontName = geom.fontName;
						}
						if (angle !== 0) {
							textDiv.dataset.angle = angle * (180 / Math.PI);
						}
						
						if (textDiv.textContent.length > 1) {
							if (style.vertical) {
								textDiv.dataset.canvasWidth = geom.height * scale;
							} else {
								textDiv.dataset.canvasWidth = geom.width * scale;
							}
						}
						
						textDivs.push(textDiv);
						jpdfjs.textDivs.push(textDiv);
					}
					
					options.onTextExtracted(jpdfjs, pageNumber, textRaw, textDivs);
					jpdfjs.textRaw += textRaw;
				});
			}, 
			find : function(text) {
				
			}
		});
		
		return jpdfjs;
	}
})(jQuery);