# 0.2.0

* added support for since param in the page method
  * include since_cursor and refresh_url to pagination results
* added default_page_by configuration option to change the cursored model column. default remains :id
* added default_processors configuration to process output cursor values 

# 0.1.2

* added support for ActiveRecord version 4.2
* removed support for ActiveRecord versions 3.0 and 3.1

# 0.1.0

* cloned kaminari
* ripped out all non-rails, non-active_record methods
* updated page method to support cursors with before and after params
