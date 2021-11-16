# See: https://apidock.com/ruby/DateTime/strftime
Date::DATE_FORMATS[:long_no_padded] = '%B %-d, %Y'
Date::DATE_FORMATS[:long_month_and_day] = '%B %d'

Time::DATE_FORMATS[:long_no_padded] = Date::DATE_FORMATS[:long_no_padded]
Time::DATE_FORMATS[:long_month_and_day] = Date::DATE_FORMATS[:long_month_and_day]
