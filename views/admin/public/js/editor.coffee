$ ->	
	
	$('.edit').on 'click', () ->
		document.execCommand(this.id, null, false)
		
	$('.toggle-mode button').on 'click', (e) ->
		if !$(e.target).hasClass 'selected'
			if this.id.toString() == 'visual'
				$('.editor-visual')
						.html($('.editor-html').val())
						.show()
						.focus()
				$('.editor-html').hide()
			else if this.id.toString() == 'html'
				$('.editor-html')
						.val($('.editor-visual').html())
						.show()
						.focus()
				$('.editor-visual').hide()
			$('.toggle-mode button').removeClass('selected')
			$(this).addClass('selected')

	$('.tray button').on 'click', (e) ->
		e.preventDefault && e.preventDefault()
	
	$('#submit').on 'click', (e) ->
		e.preventDefault && e.preventDefault()
		$('.editor-html').text($('.editor-visual').html())
		$('form#new').submit()