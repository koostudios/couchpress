(function() {

  $(function() {
    $('.edit').on('click', function() {
      return document.execCommand(this.id, null, false);
    });
    $('.toggle-mode button').on('click', function(e) {
      if (!$(e.target).hasClass('selected')) {
        if (this.id.toString() === 'visual') {
          $('.editor-visual').html($('.editor-html').val()).show();
          $('.editor-html').hide();
        } else if (this.id.toString() === 'html') {
          $('.editor-html').val($('.editor-visual').html()).show();
          $('.editor-visual').hide();
        }
        $('.toggle-mode button').removeClass('selected');
        return $(this).addClass('selected');
      }
    });
    $('.tray button').on('click', function(e) {
      return e.preventDefault && e.preventDefault();
    });
    return $('#submit').on('click', function() {
      $('.editor-html').text($('.editor-visual').html());
    });
  });

}).call(this);
