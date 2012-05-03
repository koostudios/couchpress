
/*
cushy.dialog.coffee

Dialog box for Cushy Editor. Heavily inspired by Gollum Editor by Github.
Written by Alexander Yuen
MIT License
*/

(function() {

  $(function() {
    var Dialog;
    Dialog = {
      attachEvents: function(ok) {
        $('#dialog-ok').on('click', function(e) {
          e.preventDefault && e.preventDefault();
          return ok();
        });
        $('#dialog-body input').keydown(function(e) {
          if (e.keyCode === 13) {
            e.preventDefault && e.preventDefault();
            return ok();
          }
        });
        return $('#dialog-cancel').on('click', Dialog.hide);
      },
      createFields: function(obj) {
        var field, html, _i, _len;
        html = '';
        for (_i = 0, _len = obj.length; _i < _len; _i++) {
          field = obj[_i];
          if (field.name) {
            html += '<label for=' + field.id + '>' + field.name + '</label>';
          }
          if (field.id && field.type) {
            html += '<input type=' + field.type + ' name=' + field.id + ' id=dialog-' + field.id + '>';
          }
        }
        return html;
      },
      init: function(args) {
        if (typeof args.title === 'string') {
          $('#dialog-title').text(args.title);
        } else {
          $('#dialog-title').text('Information');
        }
        if (typeof args.body === 'string') {
          $('#dialog-body').html(args.body);
        } else if (typeof args.body === 'object') {
          $('#dialog-body').html(Dialog.createFields(args.body));
        } else {
          $('#dialog-body').html('<b>Woops.</b> There was some error in displaying this dialog box.');
        }
        if (typeof args.ok === 'function') {
          Dialog.attachEvents(args.ok);
        } else {
          Dialog.attachEvents(Dialog.hide);
        }
        return Dialog.show();
      },
      show: function() {
        $('#dialog').show();
        Dialog.position();
        $('#dialog').animate({
          opacity: 1
        }, 500);
        return $('#overlay').show().animate({
          opacity: 0.4
        }, 500);
      },
      hide: function() {
        $('#dialog').hide();
        $('#overlay').hide();
        $('#dialog-ok').off('click');
        return $('#dialog-cancel').off('click');
      },
      position: function() {
        var left, top;
        top = parseInt(($(window).height() - $('#dialog').height()) / 2);
        left = parseInt(($(window).width() - $('#dialog').width()) / 2);
        return $('#dialog').css('top', top).css('left', left);
      }
    };
    return $.Dialog = Dialog;
  });

}).call(this);
