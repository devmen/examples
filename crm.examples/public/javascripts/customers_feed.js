//===
// Customers Feed handlers and functions
//===

$(document).ready(function() {
  // Setup 'active' class to remembers buttons from cookies:
  setupFilterScopesFromCookies();
  setupOrderByDescriptionScopesFromCookies();

  // Remove fucken handlers from customer feed element href:
  $('#dc1 tbody a').unbind();
  // This hack remove on href page open:
  $('#dc1 tbody a').live('click', function() {
    location.href = $(this).attr('href');
    return false;
  });
  // Add link emulator to table line:
  $('#dc1 tbody tr').live('click', function() {
    location.href = $(this).find('a').attr('href');
  });

  // Write order by date options into cookies:
  function saveOrderByDescriptionScopesToCookies() {
    var json = '{';

    $('.sorting.customers.alpha li').each(function(index, element) {
      element = $(element);
      if (element.hasClass('active')) {
        if (json != '{') {json = json + ','};
        json = json + '"' + element.children('a').attr('class') + '"' + ':true';
      }
    });

    json = json + '}';
    $.cookie('customers_order_by_description', json);

    return json;
  }

  // Write filter options into cookies:
  function saveFilterScopesToCookies() {
    var json = '{';

    $('.customers_filter li a').each(function(index, element) {
      element = $(element);
      if (element.hasClass('active')) {
        if (json != '{') {json = json + ','};
        json = json + '"' + element.attr('class').split(/\s+/)[0] + '"' + ':true';
      }
    });

    json = json + '}';
    $.cookie('customers_filter', json);

    return json;
  }

  // Load order by date options from cookies and set 'active' class to button:
  function setupOrderByDescriptionScopesFromCookies() {
    var scope = $.parseJSON( $.cookie('customers_order_by_description') );
    if (scope == null) { scope = {"order_by_description":true} }

    $.each(scope, function(key, value) {
      $('ul.sorting.customers li a.' + key.toString()).parent().addClass('active');
    });
  }

  // Load order by date options from cookies and set 'active' class to button:
  function setupFilterScopesFromCookies() {
    var scope = $.parseJSON( $.cookie('customers_filter') );
    if (scope == null) { scope = {"all":true} }

    $.each(scope, function(key, value) {
      $('ul.customers_filter li a.' + key.toString()).addClass('active');
    });
  }

  // Store current will paginate page to upload by ajax on scroll:
  var CUSTOMERS_FEEDS_PAGE = 1;
  // If true - scroll upload blocked:
  var CUSTOMERS_FEEDS_STOP_LOADING = false;

  // Upload more customers on scroll:
  if ($('#dc1').hasClass('scrollable')) {
    $('#dc1').scroll(function() {
      var dc_height = $('#dc1').height();
      var table_height = $('#dc1 table').height();

      if (($('#dc1').scrollTop() + dc_height) == table_height && CUSTOMERS_FEEDS_STOP_LOADING == false) {
        CUSTOMERS_FEEDS_PAGE = CUSTOMERS_FEEDS_PAGE + 1;
        $.get('/customers_feeds/more?page=' + CUSTOMERS_FEEDS_PAGE.toString() + '&' + getAllScopes(), function(data) {
          if (data != '') {
            $('#dc1 table tbody').append(data);
          } else {
            CUSTOMERS_FEEDS_STOP_LOADING = true;
          }
        });
      }
    });
  }

  // Upload customers ordered date scope and set 'customers' class to clicked button:
  $('ul.sorting.customers li').click(function() {
    $('ul.sorting.customers li').each(function(index, element) {
      $(element).removeClass('active');
    });
    $(this).addClass('active');

    loadScopedActivities();
    saveOrderByDescriptionScopesToCookies();
    return false;
  });

  // Upload activities filtered by date scope and set 'activity' class to clicked button:
  $('.customers_filter li a').click(function() {
    $('.customers_filter li a').each(function(index, element) {
      $(element).removeClass('active');
    });
    $(this).addClass('active');

    loadScopedActivities();
    saveFilterScopesToCookies();
    return false;
  });

  // Launch a get request to load customers ordered and filtered by current options:
  function loadScopedActivities() {
    $.get('/customers_feeds/more?' + getAllScopes(), function(data) {
      $('#dc1 table tbody').html(data);
    });

    CUSTOMERS_FEEDS_STOP_LOADING = false;
  }

  // Collect all filter and order options:
  function getAllScopes() {
    var scopes = '';

    $('ul.sorting.customers li').each(function(index, element) {
      element = $(element);
      if (element.hasClass('active')) {
        if (scopes != '') {scopes = scopes + '&'};
        scopes = scopes + element.children('a').attr('href');
      }
    });

    $('ul.customers_filter li a').each(function(index, element) {
      element = $(element);
      if (element.hasClass('active')) {
        if (scopes != '') {scopes = scopes + '&'};
        scopes = scopes + element.attr('href');
      }
    });

    return scopes;
  }
});
