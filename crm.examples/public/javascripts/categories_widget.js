function categoriesAddBtnHandler(resource_name) {
  console.info('.categories.btn-add.' + resource_name);
  console.info('fuck1');
  $('.categories.btn-add.' + resource_name).die();
  $('.categories.btn-add.' + resource_name).live('click', function() {
    var field_value = $('input#act-' + resource_name + '-category').val();

    if (field_value.length > 0 && !( field_value.match(/^\s+$/) )) {
      $('input#act-' + resource_name + '-category').val('');
      appendCategoryItem(resource_name, field_value);
    }

    return false;
  });

  // If category item doesn't selected (checked) - do not send it's data to server (set 'disabled'):
  $('li.category-item div.emChkBxLbl, li.category-item div.emChkBxLbl').die();
  $('li.category-item div.emChkBxLbl, li.category-item div.emChkBxLbl').live('click', function () {
    var destroy_input = $(this).parent().children('input.category_destroy');
    if (destroy_input.attr('disabled') == 'disabled') {
      destroy_input.removeAttr('disabled');
    } else {
      destroy_input.attr('disabled', 'disabled');
    }
  });
}

function appendCategoryItem(resource_name, field_value, id) {
  var counter = $('li.category-item.' + resource_name).size();

  // Initialize all elements:
  var li_container = '<li class="inline category-item ' + resource_name + '" id="category_container_' + counter.toString() + '"></li>';
  var label = '<label for="act-' + resource_name.toString() + '-category-' + counter.toString() + '"></label>';
  var checkbox = '<input type="checkbox" class="checkbox" style="display: none" id="act-' + resource_name.toString() + '-category-' + counter.toString() + '" name="none" checked="checked"/>';
  var destroy_input = '<input type="hidden" class="category_destroy" name="' + resource_name.toString() + '[category_tokens][' + counter.toString() + '][_destroy]" disabled="disabled" value="1" />';
  var name_input  = '<input type="hidden" name="' + resource_name.toString() + '[category_tokens][' + counter.toString() + '][name]" value="' + field_value.toString()  + '" />';
  var smart_fake_chbx =  '<div class="emChkBx checked" id="emChkBx' + counter.toString() + '"></div>' +
    '<div class="emChkBxLbl" id="emChkBxLbl' + counter.toString() + '">' + field_value.toString() + '</div>';

  // Append them to base container:
  $('li#add-category-widget.' + resource_name).after(li_container);
  $('.' + resource_name + '#category_container_' + counter.toString()).append(label, checkbox, smart_fake_chbx, name_input, destroy_input);

  // If it is an exist category create a id field:
  if (id != null) {
    var id_input  = '<input type="hidden" class="category_id_input ' + resource_name.toString() + '" name="' + resource_name.toString() + '[category_tokens][' + counter.toString() + '][id]" value="' + id.toString() + '"/>';
    $('.' + resource_name + '#category_container_' + counter.toString()).append(id_input);
  }
}

// Removes category item by its category id field value:
function removeCategoryItemByCategoryId(resource_name, category_id) {
  var input = $('input.category_id_input.' + resource_name + '[value="' + category_id.toString() + '"]');
  input.parent().remove();
}

// Launch searching timeout id:
var T_ID = false;

function initAutocomplete(resource_name) {
  // Launch AJAX request to search category:
  $('#act-' + resource_name.toString() + '-category').die();
  $('#act-' + resource_name.toString() + '-category').live('keyup', function() {
    clearTimeout(T_ID);

    //var cat_name_field = $(this);
    var field_id = '#act-' + resource_name.toString() + '-category';

    T_ID = setTimeout(function() {
      var cat_name_field = $(field_id);
      var query_field = cat_name_field;
      var query = cat_name_field.val();

      $.get('/categories.json?q=' + query, function(data) {
        var ul_container = $('#categories-autocomplete');
        ul_container.attr('style', "display: block; top: " +
          (query_field.offset().top + 25).toString() + "px; left: " +
          query_field.offset().left.toString() + "px;"
        );
        ul_container.html('');

        // Construct the dropdown list from JSON result:
        $.each(data, function(i, el) {
          var li_container = '<li num="' + i.toString() + '"></li>';

          ul_container.append(li_container);
          $('li[num="' + i.toString() + '"]').append('<a category_id="' + el.id + '" class="category-autocomplete-item ' + resource_name + '">' + el.name + '</a>');

          // If current category already selected - add selected class to it:
          if ( $('input.category_id_input.' + resource_name + '[value="' + el.id.toString() + '"]').size() > 0 ) {
            $('li[num="' + i.toString() + '"]').addClass('categories-selected');
          }
        });
      });
    }, 1000);
  });

  $('#act-' + resource_name.toString() + '-category').live('focus', function() {
    if ( $(this).val().length == 0 || $(this).val().match(/^\s+$/) ) {
      $(this).trigger('keyup');
    }
  });

  // Hide autocomplete result list with click on the page:
  $('body').click(function (e) {
    if (!($(e.target).hasClass('category-autocomplete-item'))) {
      $('#categories-autocomplete').hide();
    }
  });

  $('a.category-autocomplete-item.' + resource_name).die();
  $('a.category-autocomplete-item.' + resource_name).live('click', function () {
    var li_container = $(this).parent();
    if (li_container.hasClass('categories-selected')) {
      li_container.removeClass('categories-selected');

      // Remove category item on repeated click:
      removeCategoryItemByCategoryId(resource_name, $(this).attr('category_id'));
    } else {
      li_container.addClass('categories-selected');

      // Add new category item on click:
      appendCategoryItem(resource_name, $(this).text(), $(this).attr('category_id'));
    }
  });
}
