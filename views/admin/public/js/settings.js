(function() {

  $(function() {
    return $('#submit').on('click', function(e) {
      var admin, data;
      e.preventDefault && e.preventDefault();
      data = {};
      admin = {};
      $('table').each(function() {
        var fields, id;
        id = $(this).attr('id');
        fields = {};
        $('#' + id + ' input').each(function() {
          return fields[$(this).attr('name')] = $(this).val();
        });
        if (id !== 'admin') {
          return data[id] = fields;
        } else {
          return admin = fields;
        }
      });
      return $.post('/admin/settings', {
        data: JSON.stringify(data),
        admin: JSON.stringify(admin)
      }, function(data) {
        $('.message').html(data).show();
        return window.location = '#';
      });
    });
  });

}).call(this);
