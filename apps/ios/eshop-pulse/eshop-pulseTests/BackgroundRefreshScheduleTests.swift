import Foundation
import XCTest
@testable import eshop_pulse

final class BackgroundRefreshScheduleTests: XCTestCase {
    func testEarliestDateIsTodayAtNineBeforeNineAndTomorrowAtOrAfterNine() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))

        let beforeNine = try date(year: 2026, month: 9, day: 17, hour: 8, calendar: calendar)
        let atNine = try date(year: 2026, month: 9, day: 17, hour: 9, calendar: calendar)
        let todayAtNine = try date(year: 2026, month: 9, day: 17, hour: 9, calendar: calendar)
        let tomorrowAtNine = try date(year: 2026, month: 9, day: 18, hour: 9, calendar: calendar)

        XCTAssertEqual(
            BackgroundRefreshSchedule.nextEarliestDate(after: beforeNine, calendar: calendar),
            todayAtNine
        )
        XCTAssertEqual(
            BackgroundRefreshSchedule.nextEarliestDate(after: atNine, calendar: calendar),
            tomorrowAtNine
        )
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        calendar: Calendar
    ) throws -> Date {
        try XCTUnwrap(calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour
        )))
    }
}
