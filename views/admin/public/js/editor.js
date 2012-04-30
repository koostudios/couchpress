
/*
cushy.markdown.coffee

Cushy Markdown Editor for CouchPress. Heavily inspired by Gollum Editor by Github.
Written by Alexander Yuen
MIT License
*/

(function() {

  $(function() {
    var Editor, markdown;
    markdown = {
      'bold': {
        search: /([^\n]+)([\n\s]*)/g,
        replace: "**$1**$2",
        add: "****"
      },
      'italic': {
        search: /([^\n]+)([\n\s]*)/g,
        replace: "_$1_$2",
        add: "__"
      },
      'code': {
        search: /(.+)([\n]?)/g,
        replace: "`$1`$2",
        add: "``"
      },
      'quote': {
        search: /(.+)([\n]?)/g,
        replace: "> $1$2",
        add: ">"
      },
      'unordered-list': {
        search: /(.+)([\n]?)/g,
        replace: "* $1$2",
        add: "*"
      },
      'ordered-list': {
        search: /(.+)([\n]?)/g,
        replace: "1. $1$2",
        add: "1. "
      },
      'link': {
        exec: {
          title: 'Insert Link',
          body: [
            {
              id: 'text',
              name: 'Link Text',
              type: 'text'
            }, {
              id: 'url',
              name: 'Location',
              type: 'text'
            }
          ],
          ok: function() {
            var text;
            text = '[' + $('#dialog-text').val() + '](' + $('#dialog-url').val() + ')';
            Editor.add(text);
            return $.Dialog.hide();
          }
        }
      },
      'img': {
        exec: {
          title: 'Insert Image',
          body: [
            {
              id: 'url',
              name: 'Specify a URL',
              type: 'text'
            }, {
              id: 'caption',
              name: 'Caption',
              type: 'text'
            }
          ],
          ok: function(e) {
            var text;
            text = '![' + $('#dialog-caption').val() + '](' + $('#dialog-url').val() + ')';
            Editor.add(text);
            return $.Dialog.hide();
          }
        }
      }
    };
    Editor = {
      elem: $('.editor-markdown'),
      add: function(text) {
        var elem, pos, val;
        elem = Editor.elem;
        val = elem.val();
        pos = Editor.getPosition(elem);
        elem.val(val.substring(0, pos.start) + text + val.substring(pos.end));
        return elem[0].setSelectionRange(pos.start + text.length, pos.start + text.length);
      },
      replace: function(text, search, replace) {
        var elem, pos, val;
        elem = Editor.elem;
        val = elem.val();
        pos = Editor.getPosition(elem);
        text = text.replace(search, replace);
        elem.val(val.substring(0, pos.start) + text + val.substring(pos.end));
        return elem[0].setSelectionRange(pos.start, pos.start + text.length);
      },
      addElement: function(add) {
        var elem, index, pos, val;
        elem = Editor.elem;
        val = elem.val();
        pos = Editor.getPosition(elem);
        if (add.length % 2 === 0) {
          index = pos.start + add.length / 2;
        } else {
          add += ' ';
          index = pos.start + add.length;
        }
        elem.val(val.substring(0, pos.start) + add + val.substring(pos.end));
        return elem[0].setSelectionRange(index, index);
      },
      getPosition: function(elem) {
        var end, start;
        this.elem = elem;
        start = 0;
        end = 0;
        if (typeof elem[0].selectionStart === 'number') {
          start = elem[0].selectionStart;
          end = elem[0].selectionEnd;
        }
        return {
          start: start,
          end: end
        };
      }
    };
    $('.edit').on('click', function(e) {
      var func, pos, text;
      pos = Editor.getPosition(Editor.elem);
      text = Editor.elem.val().substring(pos.start, pos.end);
      e.preventDefault && e.preventDefault();
      if ($(this).attr('id')) {
        func = markdown[$(this).attr('id')];
        if (typeof func.exec === 'object') {
          return $.Dialog.init(func.exec);
        } else if (typeof func.replace === 'string') {
          if (text.length > 0) {
            return Editor.replace(text, func.search, func.replace);
          } else {
            return Editor.addElement(func.add);
          }
        }
      }
    });
    /*
    	Fullscreen not supported yet
    	$('#fullscreen').on 'click', (e) ->
    		e.preventDefault && e.preventDefault()
    		if $(this).hasClass 'selected'
    			document.webkitCancelFullScreen()
    			$(this)
    				.removeClass('selected').children('img').attr('src', '/admin/img/tray/icon-fullscreen.png')	
    		else
    			document.getElementById('fullscreen-area').webkitRequestFullScreen Element.ALLOW_KEYBOARD_INPUT
    			$(this)
    				.addClass('selected')
    				.children('img').attr('src', '/admin/img/tray/icon-fullscreen-selected.png')
    */
    $('.toggle-mode button').on('click', function(e) {
      var converter;
      e.preventDefault && e.preventDefault();
      if (!$(e.target).hasClass('selected')) {
        if (this.id.toString() === 'preview') {
          converter = new Showdown.converter();
          $('.preview').html(converter.makeHtml($('.editor-markdown').val())).show();
          $('.editor-markdown').hide();
        } else if (this.id.toString() === 'markdown') {
          $('.editor-markdown').show().focus();
          $('.preview').hide();
        }
        $('.toggle-mode button').removeClass('selected');
        return $(this).addClass('selected');
      }
    });
    $('.editor-markdown').on('keydown', function(e) {
      if (e.keyCode === 9) {
        e.preventDefault && e.preventDefault();
        return Editor.add('    ');
      }
    });
    $('#overlay').on('click', function() {
      return $.Dialog.hide();
    });
    return $('#status').on('change', function() {
      if ($(this).is(':checked')) {
        $('#submit').val('Save');
        return $('input[name=status]').val('draft');
      } else {
        $('#submit').val('Publish');
        return $('input[name=status]').val('published');
      }
    });
  });

}).call(this);
