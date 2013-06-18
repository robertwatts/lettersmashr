$(document).ready(function() {

  $('#smash_form').submit(function() {
    var req_url = '/api/v1/smash/' + $('#text').val();
    $.ajax({
      url: req_url,
      type: 'post',
      error: function(text) {
        alert('Error ' + text);
      },
      success: function(text) {
        display_image(text);
      }
    });
    return false;
  });

  // Displays an image
  function display_image(smashed_image_id) {
    $.ajax({
      url: '/api/v1/image/' + smashed_image_id,
      type: 'get',
      dataType: 'json',
      error: function(xhr_data) {
        // terminate the script
      },
      success: function(xhr_data) {
        if (!xhr_data.ready) {
          $('#image').html('<img id="waiting" src="images/ajax-loader.gif">');
          setTimeout(function() {display_image(smashed_image_id)}, 300);
        } else {
          $('#image').html('<img id="smashed_image" src="'
            + xhr_data.image.url + '" width="' + xhr_data.width + '" height="' + xhr_data.height + '"/>');
        }
      }
    });
  }
});
