extends Node

const POST_FIXES: Array[String] = [
	"", "K", "M", "B"
]

func format(number: int) -> String:
	if number == 0:
		return "0"
	var is_negative: bool = number < 0
	number = absi(number)
	var log10: float = log(number + 1) / log(10.0)
	if log10 < 3.0:
		return "%s%d" % ["-" if is_negative else "", number]

	var post_fix: int = floori(log10 / 3)
	assert (post_fix < POST_FIXES.size())
	var after_comma_digits: int = 2 - (int(log10) % 3)
	var short: float = number / pow(10.0, post_fix * 3.0)
	var pre_comma: int = floori(short)
	var multi: float = pow(10.0, after_comma_digits)
	var post_comma: int = roundi((short - pre_comma) * multi)
	if after_comma_digits > 0 and post_comma != 0:
		return ("%s%d%s%0*d%s" % [
			"-" if is_negative else "", 
			pre_comma, 
			Options.decimal_separator, 
			after_comma_digits, post_comma, 
			POST_FIXES[post_fix]]).rstrip("0")
	else:
		return "%s%d%s" % [
			"-" if is_negative else "", 
			pre_comma, 
				POST_FIXES[post_fix]]


func format_float(number: float, zero_digits_after_separator: int = 0) -> String:
	var is_negative: bool = number < 0
	number = absf(number)
	var pre_comma: int = int(number)
	var post_comma: int = roundi((number - pre_comma) * pow(10.0, zero_digits_after_separator))
	if zero_digits_after_separator > 0 and post_comma != 0:
		return ("%s%d%s%0*d" % [
			"-" if is_negative else "", 
			pre_comma, 
			Options.decimal_separator, 
			zero_digits_after_separator, post_comma
		]).rstrip("0")
	else:
		return "%s%d" % [
			"-" if is_negative else "", 
			pre_comma
		]

func format_date(number: int) -> String:
	if number <= 0:
		return "-"
	var date_time: Dictionary = Time.get_datetime_dict_from_unix_time(number)
	return "{year}-{month}-{day} {hour}:{minute}".format(date_time)
