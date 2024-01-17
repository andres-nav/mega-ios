import Foundation

public typealias Timestamp = Date

public extension Date {

    /// Will return the starting time of current date on given calendar.
    /// - Parameter calendar: Calendar on which the starting time of current instance based.
    /// - Returns: A `Timestamp` (`Date`)  of a calendar day that contains current date.
    func startOfDay(on calendar: Calendar) -> Timestamp? {
        startingTimestamp(with: .day, on: calendar)
    }

    /// Will return starting timestamp with given `CalendarComponent` in the given `Calendar.`
    /// e.g. given current date is 31 May, 22:39, 2020, with the given calendar component `.day`, and calendar instance `Gregorian Calendar`,
    /// TimeZone `AEST`, Local `Australia`, it will return a timestamp - actually a `Date` instance with `31 May, 00:00, 2020`
    /// (1590847200 since Jan 1, 1970 ) in `AEST`
    /// time zone.
    /// - Parameters:
    ///   - calendarComponent: The calendar component that erase the `Date` instance's corresponding property to 0.
    ///   - calendar: The calendar on which the starting timestamp of date based.
    /// - Returns: A `Timestamp` (`Date`)  of a given calendar component that contains current date.
    func startingTimestamp(with calendarComponent: Calendar.Component,
                           on calendar: Calendar) -> Timestamp? {
        calendar.dateInterval(of: calendarComponent, for: self)?.start
    }
    
    /// Return a date object by removing the timestamp. Only year, month and day date components will be preserved
    /// - Parameter timeZone: the time zone to use to create the new date. If not provided, the system time zone will be used.
    /// - Returns: A new date object without timestamp
    func removeTimestamp(timeZone: TimeZone? = nil) -> Date? {
        var calendar = Calendar.current
        if let timeZone = timeZone {
            calendar.timeZone = timeZone
        }
        let components = calendar.dateComponents([.year, .month, .day], from: self)
        return calendar.date(from: components)
    }
    
    /// Return a date object by removing day information. Only year, month date components will be preserved
    /// - Parameter timeZone: the time zone to use to create the new date. If not provided, the system time zone will be used.
    /// - Returns: A new date object without day information
    func removeDay(timeZone: TimeZone? = nil) -> Date? {
        var calendar = Calendar.current
        if let timeZone = timeZone {
            calendar.timeZone = timeZone
        }
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)
    }
    
    /// Return a date object by removing day information. Only year date components will be preserved
    /// - Parameter timeZone: the time zone to use to create the new date. If not provided, the system time zone will be used.
    /// - Returns: A new date object without month infomation
    func removeMonth(timeZone: TimeZone? = nil) -> Date? {
        var calendar = Calendar.current
        if let timeZone = timeZone {
            calendar.timeZone = timeZone
        }
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components)
    }

    // Return a date object of the start of the day 'days' ago from current date
    /// - Parameter days: the time zone to use to create the new date. If not provided, the system time zone will be used.
    /// - Parameter timeZone: the time zone to use to create the new date. If not provided, the system time zone will be used.
    /// - Returns: A new date object 'days' ago from the current date
    func daysAgo(_ days: Int, timeZone: TimeZone? = nil) -> Date? {
        var calendar = Calendar.current
        if let timeZone = timeZone {
            calendar.timeZone = timeZone
        }
        let date = calendar.date(byAdding: .day, value: -days, to: self)
        return date?.startOfDay(on: calendar)
    }

    // Return a date object at the beginning of the current year
    /// - Parameter timeZone: the time zone to use to create the new date. If not provided, the system time zone will be used.
    /// - Returns: A new date object at the beginning of the current year
    func currentYearStartDate(timeZone: TimeZone? = nil) -> Date? {
        var calendar = Calendar.current
        if let timeZone = timeZone {
            calendar.timeZone = timeZone
        }

        let components = calendar.dateComponents([.year], from: self)
        let currentYearStartDate = calendar.date(from: components)
        return currentYearStartDate?.startOfDay(on: calendar)
    }

    // Return a date object at the beginning of the previous year
    /// - Parameter timeZone: the time zone to use to create the new date. If not provided, the system time zone will be used.
    /// - Returns: A new date object at the beginning of the previous year
    func previousYearStartDate(timeZone: TimeZone? = nil) -> Date? {
        var calendar = Calendar.current
        if let timeZone = timeZone {
            calendar.timeZone = timeZone
        }

        let components = calendar.dateComponents([.year], from: self)
        guard let currentYearStartDate = calendar.date(from: components) else { return nil }
        let date = calendar.date(byAdding: .year, value: -1, to: currentYearStartDate)
        return date?.startOfDay(on: calendar)
    }
    
    /// Return a date that has added single day, and subtracted one second
    /// - Returns: A new date object at the end of the current day
    func endOfDay(calendar: Calendar = .autoupdatingCurrent) -> Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return calendar.date(byAdding: components, to: calendar.startOfDay(for: self))
    }
}
