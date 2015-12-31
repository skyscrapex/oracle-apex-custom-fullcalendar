create or replace package plugin_fullcal2_pkg
is
  FUNCTION render_calendar (
     p_region              IN APEX_PLUGIN.T_REGION,
     p_plugin              IN APEX_PLUGIN.T_PLUGIN,
     p_is_printer_friendly IN BOOLEAN
  )
  RETURN APEX_PLUGIN.T_REGION_RENDER_RESULT;
  
  FUNCTION calendar_ajax (
    p_region in apex_plugin.t_region
  , p_plugin in apex_plugin.t_plugin
  )
  RETURN apex_plugin.t_region_ajax_result;
end;
/
create or replace package plugin_fullcal2_pkg
is
  FUNCTION render_calendar (
     p_region              IN APEX_PLUGIN.T_REGION,
     p_plugin              IN APEX_PLUGIN.T_PLUGIN,
     p_is_printer_friendly IN BOOLEAN
  )
   RETURN APEX_PLUGIN.T_REGION_RENDER_RESULT
  IS
     l_retval            APEX_PLUGIN.T_REGION_RENDER_RESULT;
     l_calendar_code     VARCHAR2(32767);
     l_crlf              CHAR(2) := CHR(13)||CHR(10);
     l_id                PLS_INTEGER;
     l_title             VARCHAR2(32767);
     l_view_string       varchar2(100);
     -- Its easer to reference things using a local name rather than the APEX Attribute Number
     l_jqueryui_theme    VARCHAR2(30) := p_plugin.attribute_01;
     l_tooltip_theme     VARCHAR2(30) := p_plugin.attribute_02;
     l_tooltip_styles    VARCHAR2(30) := p_plugin.attribute_03;
     l_calendar_width    number       := p_region.attribute_01;
     l_header_left       varchar2(50) := p_region.attribute_02;
     l_header_center     varchar2(50) := p_region.attribute_03;
     l_header_right      varchar2(50) := p_region.attribute_04;
     l_include_tip       varchar2(1)  := p_region.attribute_05;
     l_dy_wk_type        varchar2(10) := p_region.attribute_06;
     l_include_alt       varchar2(10) := p_region.attribute_07;
     l_calendar_height   number       := p_region.attribute_08;
     l_first_day         number       := p_region.attribute_09;
     l_onload_js         varchar2(4000);
     l_tooltip_classes   VARCHAR2(60);
  BEGIN
  --
  -- If we're in debug mode, then turn on debugging for the region.
  --
  IF apex_application.g_debug THEN
    apex_plugin_util.debug_region (
      p_plugin => p_plugin,
      p_region => p_region
    );
  END IF;
  --
  -- Add the Moments JS library
  --
  apex_javascript.add_library (
    p_name      => 'moment.min',
    p_directory => p_plugin.file_prefix,
    p_version   => NULL
  );
  --
  -- Add the FullCalendar JavaScript
  --
  apex_javascript.add_library (
    p_name      => 'fullcalendar.min',
    p_directory => p_plugin.file_prefix,
    p_version   => NULL
  );
  --
  -- Add the FullCalendar Language File
  --
  apex_javascript.add_library (
    p_name      => 'nl',
    p_directory => p_plugin.file_prefix,
    p_version   => NULL
  );
  --
  -- Add the FullCalendar Custom Widget file
  --
  apex_javascript.add_library (
    p_name      => 'apex.custom.widget.fullcalendar',
    p_directory => p_plugin.file_prefix,
    p_version   => NULL
  );
  --
  -- Add the FullCalendar CSS
  --
  apex_css.add_file(
    p_name      => 'fullcalendar.min',
    p_directory => p_plugin.file_prefix,
    p_version   => NULL
  );
  --
  -- Add the jQuery qTIP JavaScript & CSS but only if instructed to
  --
  IF l_include_tip = 'Y' THEN
    apex_javascript.add_library (
      p_name      => 'jquery.qtip.min',
      p_directory => p_plugin.file_prefix,
      p_version   => NULL
    );
    apex_css.add_file(
      p_name      => 'jquery.qtip.min',
      p_directory => p_plugin.file_prefix,
      p_version   => NULL
    );
  END IF;
  --
  -- If a jQuery UI theme has been selected, load it up.
  --
  IF l_jqueryui_theme IS NOT NULL THEN
    apex_css.add_file(
      p_name      => 'jquery-ui',
      p_directory => apex_application.g_image_prefix || 'libraries/jquery-ui/1.8/themes/' || l_jqueryui_theme || '/',
      p_version   => NULL
    );
  END IF;
  --
  --Now emit the style sheet that will set the calendar width in px
  --
  htp.p(q'!
  <style type='text/css'>
    #calendar {!');
    IF l_calendar_width is not null then
       htp.p(q'!	width: !'||l_calendar_width ||q'!px;!');
    end if;
    IF l_calendar_height is not null then
       htp.p(q'!	height: !'||l_calendar_height ||q'!px;!');
    end if;
    htp.p(q'!	margin: 0 auto;
    }
  </style>
  !');

  --
  -- Prior to emitting the code, translate the header variables.
  --
  --
  -- First step is to create the right string for the view.
  --
     l_view_string := 'month,';
     IF instr(l_include_alt,'week')>0 THEN
        l_view_string := l_view_string||l_dy_wk_type||'Week,';
     end if;
     IF instr(l_include_alt,'day')>0 THEN
        l_view_string := l_view_string||l_dy_wk_type||'Day';
     end if;
  --
  -- Then set each header section to the proper string
  --
     l_header_left   := case l_header_left
                         when 'NAV'   then 'today prev,next'
                         when 'VIEW'  then l_view_string
                         when 'TITLE' then 'title'
                         else null
                      end;
     l_header_center := case l_header_center
                         when 'NAV'   then 'today prev,next'
                         when 'VIEW'  then l_view_string
                         when 'TITLE' then 'title'
                         else null
                      end;
     l_header_right  := case l_header_right
                         when 'NAV'   then 'today prev,next'
                         when 'VIEW'  then l_view_string
                         when 'TITLE' then 'title'
                         else null
                      end;
  --
  -- Now formulate the page code that will contain the data for each event.
  --
  l_onload_js := q'[
  apex.custom.widget.fullCalendar('#fullCalendar', {
    custom: {
      includeTooltip: ']'|| CASE WHEN l_include_tip = 'Y' THEN 'true' ELSE 'false' END ||q'['
    , tooltipClasses: '#TOOLTIPCLASSES#'
    , ajaxIdentifier: ']'|| APEX_PLUGIN.get_ajax_identifier ||q'['
    },
    fullCalendar: {
      firstDay: ']'|| l_first_day ||q'['
    , header: {
        left:   ']'||l_header_left||q'[',
        center: ']'||l_header_center||q'[',
        right:  ']'||l_header_right||q'['
      }
    , theme: ']'|| CASE WHEN l_jqueryui_theme IS NOT NULL THEN 'true' ELSE 'false' END ||q'['
    }
  });]';


  --
  -- Now look at the theme that was chosen for the tip and include the right section of the style
  --
  IF l_tooltip_theme is not null then
    l_tooltip_classes := l_tooltip_theme;

    IF l_tooltip_styles is not null then
      l_tooltip_classes := l_tooltip_classes || ' '||replace(l_tooltip_styles,':',' ');
    end if;
  END IF;

  l_onload_js := REPLACE(l_onload_js, '#TOOLTIPCLASSES#', l_tooltip_classes);

  sys.htp.p('<div id="fullCalendar"></div>');

  apex_javascript.add_onload_code(p_code => l_onload_js, p_key => null);

  --
  -- and exit with a return value
  --
     RETURN l_retval;
  END;
                                                                                            
  FUNCTION calendar_ajax (
    p_region in apex_plugin.t_region
  , p_plugin in apex_plugin.t_plugin
  )
  RETURN apex_plugin.t_region_ajax_result
  IS
    l_column_value_list APEX_PLUGIN_UTIL.T_COLUMN_VALUE_LIST;
    
    l_id                PLS_INTEGER;
    l_title             VARCHAR2(32767);
    l_start             VARCHAR2(50);
    l_end               VARCHAR2(50);
    l_url               VARCHAR2(32767);
    l_color             VARCHAR2(50);
    l_text_color        VARCHAR2(50);
    l_event_class       VARCHAR2(100);
    l_tip_text          VARCHAR2(32767);
    l_all_day           BOOLEAN;
    l_sql               VARCHAR2(32767);
    l_return            apex_plugin.t_region_ajax_result;
    
    l_object            VARCHAR2(4000);
  BEGIN
    -- save the given start and end into session state, so query can be filtered
    apex_util.set_session_state('AI_CAL_START_DT', apex_application.g_x01);
    apex_util.set_session_state('AI_CAL_END_DT', apex_application.g_x02);

    --
    -- Loop through the records creating the individual events.
    -- First get the return from the source query
    -- Then transform the query to only get data for the given date range, as requested by fullcalendar  
    l_sql := 'SELECT id, title, all_day, TO_CHAR(start_date, ''YYYY-MM-DD"T"HH24:MI:SS'') AS start_date, TO_CHAR(end_date, ''YYYY-MM-DD"T"HH24:MI:SS'') AS end_date, url, event_color, text_color, event_class, tip_text ' ||
    'FROM ('|| p_region.source ||') WHERE start_date >= TO_DATE(:AI_CAL_START_DT, ''YYYY-MM-DD"T"HH24:MI:SS'') AND end_date <= TO_DATE(:AI_CAL_END_DT, ''YYYY-MM-DD"T"HH24:MI:SS'')';
    
    l_column_value_list := apex_plugin_util.get_data(
      p_sql_statement  => l_sql,
      p_min_columns    => 10,
      p_max_columns    => 10,
      p_component_name => p_region.name
    );
    
    --
    -- Then loop through and get each record's values
    --
    htp.p('{"events": [');
    FOR x IN 1 .. l_column_value_list(1).count LOOP
      l_id := sys.htf.escape_sc(l_column_value_list(1)(x));
      l_title := sys.htf.escape_sc(l_column_value_list(2)(x));
      IF UPPER(sys.htf.escape_sc(l_column_value_list(3)(x))) = 'TRUE' THEN
        l_all_day := TRUE;
      ELSE
        l_all_day := FALSE;
      END IF;
      l_start := sys.htf.escape_sc(l_column_value_list(4)(x));
      l_end := sys.htf.escape_sc(l_column_value_list(5)(x));
      l_url := sys.htf.escape_sc(l_column_value_list(6)(x));
      l_color := sys.htf.escape_sc (l_column_value_list(7)(x));
      l_text_color := sys.htf.escape_sc (l_column_value_list(8)(x));
      l_event_class := l_column_value_list(9)(x);
      l_tip_text := l_column_value_list(10)(x);

      --
      -- Now emit the individual calendar event
      --
      IF x > 1 THEN
        l_object := l_object || ',';
      END IF;

      l_object := l_object || '{'
        || apex_javascript.add_attribute('id', l_id, TRUE, TRUE)
        || apex_javascript.add_attribute('allDay', l_all_day, TRUE, TRUE)
        || apex_javascript.add_attribute('start', l_start, FALSE, TRUE)
        || apex_javascript.add_attribute('end', l_end, TRUE, TRUE)
        || apex_javascript.add_attribute('url', l_url, TRUE, TRUE)
        || apex_javascript.add_attribute('color', l_color, TRUE, TRUE)
        || apex_javascript.add_attribute('textColor', l_text_color, TRUE, TRUE)
        || apex_javascript.add_attribute('description', l_tip_text, TRUE, TRUE)
        || apex_javascript.add_attribute('className',l_event_class, TRUE, TRUE)
        || apex_javascript.add_attribute('title', l_title, FALSE, FALSE)
        || '}';

      htp.p(l_object);
      
      l_object := NULL;
    END LOOP;
    htp.p(']}');
    
    RETURN l_return;
  END calendar_ajax;
end;
/