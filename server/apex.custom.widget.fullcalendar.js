apex.custom = apex.custom ? apex.custom : {};
apex.custom.widget = apex.custom.widget ? apex.custom.widget : {};

(function($, parent, undefined){

  /**
  * @param pSelector
  * @param pOptions
  * @example
  * apex.custom.widget.fullCalendar('#fullCalendar', {
      custom: {
        includeTooltip: true
      , tooltipClasses: ''
      , ajaxIdentifier: ''
      },
      fullCalendar: {
        firstDay: 1
      , header: {}
      , theme: true
      }
    });
  */
  function fullCalendar(pSelector, pOptions) {

    var lDefaults = {
      height: "auto",
      defaultView: "agendaWeek",
      weekends: false,
      editable: false,
      weekNumbers: true,
      firstDay: 1,
      allDaySlot: true,
      minTime: "08:00:00",
      maxTime: "19:00:00",
      slotDuration: "00:05:00",
      timeFormat: 'HH:mm',
      slotLabelFormat: 'HH:mm',
      displayEventEnd: true,
      views: {
        month: { // options apply to month view
          columnFormat: "ddd", //Ma
          titleFormat: "MMMM YYYY" //december 2015
        },
        week: { // options apply to basicWeek and agendaWeek views
          columnFormat: "ddd D/M", //Ma 9/7
          titleFormat: "D MMMM YYYY" //28 december 2015 — 3 januari 2016
        },
        day: { // options apply to basicDay and agendaDay views
          columnFormat: "dddd", //Maandag
          titleFormat: "D MMMM YYYY" //31 December 2015
        }
      },
      theme: true,
      header: {
        left:   'month,agendaWeek,agendaDay',
        center: 'title',
        right:  'today prev,next'
      },
      eventClick: function(calEvent, jsEvent, view) {
        $s("P1_AFSPRAAK_ID",calEvent.id);
        $s("P1_STARTTIJD",calEvent.start);
        $s("P1_EINDTIJD",calEvent.end);

        $s("P6_ID",calEvent.id);
        return false;
      }
    };

    var lOptions = $.extend({}, lDefaults);

    //include tooltip
    if ( pOptions.custom.includeTooltip ) {

      lOptions.eventRender = function(event, element){
        element.qtip({
          content: event.description,
          style: { classes: pOptions.custom.tooltipClasses },
          widget: !pOptions.custom.tooltipClasses,
          position:{
            my: 'bottom middle',
            at: 'top middle',
            target: 'mouse',
            adjust: {mouse: true}
          }
        });
      };
    }

    lOptions.events = function(start, end, timezone, callback) {
      // format dates to ISO8601 format so they match the code in PLSQL
      apex.server.plugin(
        pOptions.custom.ajaxIdentifier
      , { widget_name: 'COM.IADVISE.FULLCALENDAR'
        , x01: start.format()
        , x02: end.format()
        }
      , { dataType: "json" }
      )
      .done( function ( data ) {
        callback(data.events);
      });
    };

    var lOptions = $.extend(lOptions, pOptions.fullCalendar);


    $(pSelector).fullCalendar(lOptions);
  }

  var interf = {
    fullCalendar: fullCalendar
  };

  $.extend(parent, interf);
})(apex.jQuery, apex.custom.widget);