/// [date] más [days] días de calendario, sin hora.
///
/// `date.add(Duration(days: n))` suma horas exactas: en los cambios de
/// horario de Chile cae a las 23:00 del día anterior (el sábado de abril
/// dura 25 horas y en septiembre se salta la medianoche), así que avanzar o
/// retroceder un día con eso se traba o se salta una fecha.
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);
