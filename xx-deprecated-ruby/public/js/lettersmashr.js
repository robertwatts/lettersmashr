$(document).ready(function() {

  $('#filter-button').hide();
  $('#tag-list-box').hide();

  // Capture form submit and call display_image
  $('#smash_form').submit(function() {
    var req_url = '/api/v1/smash/' + $('#text').val();
    $.ajax({
      url: req_url,
      type: 'post',
      data: {
        'tags': $('#tags').textext()[0].tags()._formData
      },
      error: function(text) {
        console.log('Error posting new smashed image: ' + text);
        // TODO Send response to UI...
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
  };

  // Set up the TextExt JQuery plugn
  $('#tags').textext({
    plugins: 'tags prompt focus autocomplete ajax arrow',
    tagsItems: [],
    prompt: 'Apply tags',
    ajax: {
      url: '/api/v1/tags',
      dataType: 'json',
      cacheResults: false,
      dataCallback: function(query) {
        return {
          'start_with': query,  // Restrict tag output to start with the current query
          'text': $('#text').val(), // Ensure tags match the current text input
          'also_tagged_with': $('#tags').textext()[0].tags()._formData // Ensure currently selected tags match
        };
      }
    }
  });

  $('#tmpbutton').click(function() {
    $('#tags').textext()[0].ajax().load();
    console.log($('#tags').textext()[0].tags()._formData); // Ensure currently selected tags match
  });
});
