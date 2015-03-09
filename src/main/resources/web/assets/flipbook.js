function zoomTo(event) {
	setTimeout(function() {
		if ($('.magazine-viewport').data().regionClicked) {
			$('.magazine-viewport').data().regionClicked = false;
		} else {
			if ($('.magazine-viewport').zoom('value')==1) {
				$('.magazine-viewport').zoom('zoomIn', event);
			} else {
				$('.magazine-viewport').zoom('zoomOut');
			}
		}
	}, 1);
}

function disableControls(page) {
	if (page==1)
		$('.previous-button').hide();
	else
		$('.previous-button').show();
				
	if (page==$('.magazine').turn('pages'))
		$('.next-button').hide();
	else
		$('.next-button').show();
}

function resizeViewport() {
	var width = $(window).width(),
		height = $(window).height(),
		options = $('.magazine').turn('options');
	
	$('.magazine').removeClass('animated');	
	$('.magazine-viewport').css({
		width: width,
		height: height
	}).zoom('resize');


	if ($('.magazine').turn('zoom')==1) {
		var bound = calculateBound({
			width: options.width,
			height: options.height,
			boundWidth: Math.min(options.width, width),
			boundHeight: Math.min(options.height, height)
		});
	
		if (bound.width%2!==0)
			bound.width-=1;
		
		if (bound.width!=$('.magazine').width() || bound.height!=$('.magazine').height()) {
			$('.magazine').turn('size', bound.width, bound.height);
			if ($('.magazine').turn('page')==1)
				$('.magazine').turn('peel', 'br');
	
			$('.next-button').css({height: bound.height, backgroundPosition: '-38px '+(bound.height/2-32/2)+'px'});
			$('.previous-button').css({height: bound.height, backgroundPosition: '-4px '+(bound.height/2-32/2)+'px'});
		}
	
		$('.magazine').css({top: -bound.height/2, left: -bound.width/2});
		rezoomCanvas();
	}
	
	$('.magazine').addClass('animated');
}

function calculateBound(d) {
	var bound = {width: d.width, height: d.height};
	if (bound.width>d.boundWidth || bound.height>d.boundHeight) {
		var rel = bound.width/bound.height;
		if (d.boundWidth/rel>d.boundHeight && d.boundHeight*rel<=d.boundWidth) {
			bound.width = Math.round(d.boundHeight*rel);
			bound.height = d.boundHeight;
		} else {
			bound.width = d.boundWidth;
			bound.height = Math.round(d.boundWidth/rel);
		}
	}
	return bound;
}

function rezoomCanvas() {
	var width = $(window).width(),
	height = $(window).height(),
	options = $('.magazine').turn('options');
	
	var bound = calculateBound({
		width: options.width,
		height: options.height,
		boundWidth: Math.min(options.width, width),
		boundHeight: Math.min(options.height, height)
	});
	
	$('canvas').each(function() {
		var zoom = bound.width/ 2 / $(this).attr('width');
		$(this).css('zoom', zoom);
	});
}

function largeMagazineWidth() {
	return 2000;
}