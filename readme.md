Oracle Apex FullCalendar v2.0 plugin

- Made in Apex 5.0 - requires apex 5.0 (at this moment)
- FullCalendar v2.5 (http://fullcalendar.io/)
- Since FullCalendar 2 requires moment.js, moment.js is also included

We started from the Enkitec FullCalendar plugin. When migrating to apex 5, the plugin became unusable because of the use of $.ready before the jQuery library was loaded since the libraries are now loaded at the end of the document. So we decided to use use `apex_javascript.add_onload_code` to ensure proper initialization at the correct time.
Additionally, loading of events was not dynamic and required pretty hefty HTML payloads with big script tags in it in order to pass the initial large set of events to the calendar. 

Moving the code to apex_javascript.add_onload_code also has the limitation of 4000 characters length restriction. It doesn't take long with a long list of events to bump against this limit. Paired with a lot of static settings for the calendar we found this ineffective. A lot of the initialization code has been moved to the `apex.custom.widget.fullCalendar` function, which frees up a lot of room in PLSQL and makes the code more readable and maintainable. 
To deal with inflexibility we made the event retrieval dynamic through ajax by using a function as events source. This means fullcalendar will only request events within a certain timerange! Eg when moving from week to week, only the events for those weeks will be requested when necessary and is no longer in the page render HTML.

We're now at a point where the plugin is stable and offers identical functionality, with the addition of more streamlined code and ajax retrieval.

Notes:

- in order to deal with limiting the events in time, the source query should now include DATES for start_dt and end_dt, no longer a TO_CHAR with a format. We moved this into the plugin as we're always moving over ISO-8601 date notation strings.
- Furthermore, you have to create TWO APPLICATION ITEMS! `AI_CAL_START_DT` and `AI_CAL_END_DT` - they are used in the AJAX process. (can be set to restricted access)
- the plugin does NOT replace the old plugin. You'll have to manually port over - but this should be really easy...

Outline of todo's:

- expand the documentation, both in `apex.custom.widget.fullCalendar`, source, and plugin
- expand functionality to allow better parameterization of fullCalendar, opening up more options for the developer out of the box
- listen to the apexrefresh event on the region (allowing easy refresh)
- language selection. At the moment we have Dutch hard-coded in there - but from this version on we can quickly fix up a lot of these things. By far, this may be the most important one.
- more than one calender by eliminating hard-coded ID


www.iadvise.eu - by the Apex team