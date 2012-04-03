//===
// Activity Feed handlers and functions
//===

var PAGINATE = false;

$(document).ready(function() {
  // Setup 'active' class to remembers buttons from cookies:
  setupOrderByDateScopesFromCookies();
  setupFilterByDateScopesFromCookies();
  setupFilterByTypeScopesFromCookies();

  // Init cookie for contact filter
  saveFilterScopesToCookies( $('#contact_id.for_scope').val(), 'by_contact');
  // Init cookie for client filter
  saveFilterScopesToCookies( $('#client_id.for_scope').val(), 'by_client');

  // Remove fucken handlers from activity feed element href:
  $('#dc0 tbody a').unbind();
  // This hack remove on href page open:
  $('#dc0 tbody a').live('click', function() {
    //window.open( $(this).attr('href') );
    location.href = $(this).attr('href');
    return false;
  });
  // Add link emulator to table line:
  $('#dc0 tbody tr').live('click', function() {
    //window.open( $(this).find('a').attr('href') );
    location.href = $(this).find('a').attr('href');
  });

  // Write filter by contact or client options into cookies:
  function saveFilterScopesToCookies(object_id, scope) {
    var json = '';
    if (object_id == undefined) {
      $.cookie(('filter_' + scope), null);
    } else {
      json = '{ "' + scope + '":' + object_id + ' }';
      $.cookie(('filter_' + scope), json);
    }

    return json;
  }

  // Write filter by date options into cookies:
  function saveFilterByDateScopesToCookies() {
    var json = '{';

    $('.filter_by_date').each(function(index, element) {
      element = $(element);
      if (element.hasClass('active')) {
        if (json != '{') {json = json + ','};
        json = json + '"' + element.attr('id') + '"' + ':true';
      }
    });

    json = json + '}';
    $.cookie('filter_by_date', json);

    return json;
  }

  // Write filter by type options into cookies:
  function saveFilterByTypeScopesToCookies() {
    var json = '{';

    $('.filter_by_type').each(function(index, element) {
      element = $(element);
      if (element.hasClass('active')) {
        if (json != '{') {json = json + ','};
        json = json + '"' + element.children('a').attr('class') + '"' + ':true';
      }
    });

    json = json + '}';
    $.cookie('filter_by_type', json);

    console.info(json);

    return json;
  }

  // Write order by date options into cookies:
  function saveOrderByDateScopesToCookies() {
    var json = '{';

    $('.order_by_date').each(function(index, element) {
      element = $(element);
      if (element.hasClass('active')) {
        if (json != '{') {json = json + ','};
        json = json + '"' + element.children('a').attr('class') + '"' + ':true';
      }
    });

    json = json + '}';
    $.cookie('order_by_date', json);

    return json;
  }

  // Load order by date options from cookies and set 'active' class to button:
  function setupOrderByDateScopesFromCookies() {
    var scope = $.parseJSON( $.cookie('order_by_date') );
    if (scope == null) { scope = {"order_by_date":true} }

    $.each(scope, function(key, value) {
      $('li.order_by_date a.' + key.toString()).parent().addClass('active');
    });
  }

  // Load filter by date options from cookies and set 'active' class to button:
  function setupFilterByDateScopesFromCookies() {
    var scope = $.parseJSON( $.cookie('filter_by_date') );
    if (scope == null) { scope = {"today":true} }

    $.each(scope, function(key, value) {
      $('li a.filter_by_date#' + key.toString()).addClass('active');
    });
  }

  // Load filter by type options from cookies and set 'active' class to button:
  function setupFilterByTypeScopesFromCookies() {
    var scope = $.parseJSON( $.cookie('filter_by_type') );

    if (scope != null) {
      $.each(scope, function(key, value) {
        $('li.filter_by_type a.' + key.toString()).trigger('click');
      });
    }
  }

  // Store current will paginate page to upload by ajax on scroll:
  var ACTIVIY_FEEDS_PAGE = 1;
  // If true - scroll upload blocked:
  var ACTIVIY_FEEDS_STOP_LOADING = false;

  // Upload more activities on scroll:
  if ($('#dc0').hasClass('scrollable')) {
    $('#dc0').scroll(function() {
      var dc_height = $('#dc0').height();
      var table_height = $('#dc0 table').height();

      if (($('#dc0').scrollTop() + dc_height) == table_height && ACTIVIY_FEEDS_STOP_LOADING == false) {
        ACTIVIY_FEEDS_PAGE = ACTIVIY_FEEDS_PAGE + 1;
        $.get('/activity_feeds/more?page=' + ACTIVIY_FEEDS_PAGE.toString() + '&' + getAllScopes(), function(data) {
          if (data != '') {
            $('#dc0 table tbody').append(data);
          } else {
            ACTIVIY_FEEDS_STOP_LOADING = true;
          }
        });
      }
    });
  }

  // Remember filter by type options into cookies on click:
  $('li.filter_by_type a').click(function() {
    saveFilterByTypeScopesToCookies();
    return false;
  });

  // Upload activities filtered by date scope and set 'activity' class to clicked button:
  $('.filter_by_date').click(function() {
    $('.filter_by_date').each(function(index, element) {
      $(element).removeClass('active');
    });
    $(this).addClass('active');

    loadScopedActivities();
    saveFilterByDateScopesToCookies();
    return false;
  });

  // Upload activities ordered date scope and set 'activity' class to clicked button:
  $('li.order_by_date').click(function() {
    $('.order_by_date').each(function(index, element) {
      $(element).removeClass('active');
    });
    $(this).addClass('active');

    loadScopedActivities();
    saveOrderByDateScopesToCookies();
    return false;
  });

  // Ajax pagination.
  var LAST_ACTIVITY_FEEDS_PAGE = 1;

  $('div#activity_feed_pages div.pagination a').live('click', function () {
    ACTIVIY_FEEDS_PAGE = $(this).text();

    // Set page for next button:
    if (ACTIVIY_FEEDS_PAGE.match(/Next/i)) {
      ACTIVIY_FEEDS_PAGE = parseFloat(LAST_ACTIVITY_FEEDS_PAGE) + 1;
    }

    // Set page for previous button:
    if (ACTIVIY_FEEDS_PAGE.toString().match(/Prev/i)) {
      ACTIVIY_FEEDS_PAGE = parseFloat(LAST_ACTIVITY_FEEDS_PAGE) - 1;
    }

    LAST_ACTIVITY_FEEDS_PAGE = ACTIVIY_FEEDS_PAGE;

    $.get('/activity_feeds/more?paginate=true&page=' + ACTIVIY_FEEDS_PAGE.toString() + '&' + getAllScopes(), function(data) {
      var res = data.replace(/\n/g, '').match(/(.*)(<div id='activity_feed_pages'>)(.*)/);
      var feed = res[1];
      var pagination = res[2] + res[3];

      $('#dc0 table tbody').html(feed);
      $('#activity_feed_pages').replaceWith(pagination);
    });
    return false;
  });

  // Launch a get request to load activities ordered and filtered by current options:
  function loadScopedActivities() {
    $.get('/activity_feeds/more?paginate=' + PAGINATE + '&' + getAllScopes(), function(data) {
      if (PAGINATE == true) {
        var res = data.replace(/\n/g, '').match(/(.*)(<div id='activity_feed_pages'>)(.*)/);
        var feed = res[1];
        var pagination = res[2] + res[3];

        $('#dc0 table tbody').html(feed);
        $('#activity_feed_pages').replaceWith(pagination);
      } else {
        $('#dc0 table tbody').html(data);
      }
    });
  }

  // Collect all filter and order options:
  function getAllScopes() {
    var scopes = '';
    var contact_id = $('#contact_id.for_scope').val();

    $('.filter_by_date').each(function(index, element) {
      element = $(element);
      if (element.hasClass('active')) {
        if (scopes != '') {scopes = scopes + '&'};
        scopes = scopes + element.attr('href');
      }
    });

    $('.order_by_date').each(function(index, element) {
      element = $(element);
      if (element.hasClass('active')) {
        if (scopes != '') {scopes = scopes + '&'};
        scopes = scopes + element.children('a').attr('href');
      }
    });

    $('.for_scope').each(function(index, element) {
      element = $(element);
      if (scopes != '') {scopes = scopes + '&'};
      scope = 'by_' + element.attr('id').replace('_id', '');
      scopes = scopes + scope + '=' + element.val();
    });

    return scopes;
  }
});

