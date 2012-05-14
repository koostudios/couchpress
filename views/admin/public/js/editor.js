
/*
cushy.markdown.coffee

Cushy Markdown Editor for CouchPress. Heavily inspired by Gollum Editor by Github.
Written by Alexander Yuen
MIT License
*/

(function() {

  $(function() {
    var Draft, Editor, markdown;
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
          ok: function(e) {
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
    Draft = {
      slug: $('.editor-markdown').attr('id'),
      load: function() {
        var md, slug, title, tags;
        slug = Draft.slug;
        title = localStorage[slug + '.title'];
        tags = localStorage[slug + '.tags'];
        md = localStorage[slug + '.markdown'];
        if ((title !== '' && title !== $('#title').val()) || (md !== '' && md !== $('.editor-markdown').val())) {
          return $.Dialog.init({
            title: 'Load Draft',
            body: 'There seems to be a newer, autosaved version of this post last edited at ' + localStorage[slug + '.time'] + '. Would you like to load it?',
            ok: function() {
              if (title) $('#title').val(title);
              if (tags) {
                $('#tags').val(tags.join(', '));
              }
              if (md) $('.editor-markdown').val(md);
              if (localStorage[slug + '.slug']) {
                $('#slug').val(localStorage[slug + '.slug']);
              }
              return $.Dialog.hide();
            }
          });
        }
      },
      save: function() {
        var slug, tags = [], potentialTag;
        slug = Draft.slug;
        localStorage[slug + '.title'] = $('#title').val();
        localStorage[slug + '.slug'] = $('#slug').val();
        //Tag Parsing
        // See server sided code, this process must match the server-side tag parsing
        // in order to function properly. Details in comments on server-side
        var tagstr = $('#tags').val().split(',');
        for (p in tagstr) {
          potentialTag = tagstr[p].trim().replace(/[^a-z0-9]+/gi, '-').replace(/^-*|-*$/g, '')
          if (potentialTag != '')
            tags.push(potentialTag);
        }
        localStorage[slug + '.tags'] = tags;
        localStorage[slug + '.markdown'] = $('.editor-markdown').val();
        localStorage[slug + '.time'] = new Date();
        console.log('TAGS: ', tags);
        return console.log('Draft saved at ' + new Date());
      },
      clear: function() {
        var slug;
        slug = Draft.slug;
        localStorage[slug + '.title'] = '';
        localStorage[slug + '.slug'] = '';
        localStorage[slug + '.tags'] = [];
        localStorage[slug + '.markdown'] = '';
        return localStorage[slug + '.time'] = '';
      }
    };
    Draft.load();
    setInterval(Draft.save, 30000);
    $('#dialog-buttons button').on('click', function(e) {
      return e.preventDefault && e.preventDefault();
    });
    $('.edit').on('click', function(e) {
      var func, pos, text;
      e.preventDefault && e.preventDefault();
      pos = Editor.getPosition(Editor.elem);
      text = Editor.elem.val().substring(pos.start, pos.end);
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
    $('#fullscreen').on('click', function(e) {
      e.preventDefault && e.preventDefault();
      if ($(this).hasClass('selected')) {
        document.webkitCancelFullScreen();
        return $(this).removeClass('selected').children('img').attr('src', '/admin/img/tray/icon-fullscreen.png');
      } else {
        document.getElementById('fullscreen-area').webkitRequestFullScreen(Element.ALLOW_KEYBOARD_INPUT);
        return $(this).addClass('selected').children('img').attr('src', '/admin/img/tray/icon-fullscreen-selected.png');
      }
    });
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
    $('#status-check').on('change', function() {
      if ($(this).is(':checked')) {
        $('#go').val('Save');
        return $('input[name=status]').val('draft');
      } else {
        $('#go').val('Publish');
        return $('input[name=status]').val('published');
      }
    });
    return $('#go').on('click', function(e) {
      e.preventDefault && e.preventDefault();
      Draft.clear();
      return $('#editor').submit();
    });
  });

}).call(this);
