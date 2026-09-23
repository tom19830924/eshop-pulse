import BackgroundTasks
import EshopService
import FavoritesListFeature
import Foundation
import UIKit

enum BackgroundRefreshSchedule {
    static let taskIdentifier = "com.tom19830924.eshoppulse.favorite-sales-refresh"

    static func nextEarliestDate(after date: Date, calendar inputCalendar: Calendar = .current) -> Date {
        let calendar = inputCalendar
        let todayAtNine = calendar.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: date
        ) ?? date

        if todayAtNine > date {
            return todayAtNine
        }

        return calendar.date(byAdding: .day, value: 1, to: todayAtNine)
            ?? todayAtNine.addingTimeInterval(24 * 60 * 60)
    }
}

@MainActor
enum BackgroundCatalogRefreshScheduler {
    private static var isCheckingPendingRequests = false

    static func register(using repository: any CatalogRepository) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundRefreshSchedule.taskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                handle(refreshTask, using: repository)
            }
        }
    }

    static func scheduleNextIfEnabled() async {
        guard !isCheckingPendingRequests else { return }
        isCheckingPendingRequests = true
        defer { isCheckingPendingRequests = false }

        guard FavoriteSaleAlertPreference.isEnabled() else {
            cancel()
            return
        }

        guard UIApplication.shared.backgroundRefreshStatus == .available else { return }

        let pendingRequests = await BGTaskScheduler.shared.pendingTaskRequests()
        guard !Task.isCancelled else { return }
        guard FavoriteSaleAlertPreference.isEnabled() else {
            cancel()
            return
        }
        guard !pendingRequests.contains(where: {
            $0.identifier == BackgroundRefreshSchedule.taskIdentifier
        }) else {
            return
        }

        let request = BGAppRefreshTaskRequest(
            identifier: BackgroundRefreshSchedule.taskIdentifier
        )
        request.earliestBeginDate = BackgroundRefreshSchedule.nextEarliestDate(after: .now)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // The next app launch or foreground transition will try scheduling again.
        }
    }

    static func cancel() {
        BGTaskScheduler.shared.cancel(
            taskRequestWithIdentifier: BackgroundRefreshSchedule.taskIdentifier
        )
    }

    private static func handle(_ task: BGAppRefreshTask, using repository: any CatalogRepository) {
        guard FavoriteSaleAlertPreference.isEnabled() else {
            task.setTaskCompleted(success: true)
            return
        }

        let operation = Task {
            await scheduleNextIfEnabled()
            let succeeded = await refreshCatalogAndNotify(using: repository)
            task.setTaskCompleted(success: succeeded)
        }

        task.expirationHandler = {
            operation.cancel()
        }
    }

    private static func refreshCatalogAndNotify(
        using repository: any CatalogRepository
    ) async -> Bool {
        do {
            let previousCatalog = await repository.loadCachedCatalog()
            try Task.checkCancellation()

            guard let updatedCatalog = try await repository.refreshCatalogIfNeeded() else {
                return true
            }
            try Task.checkCancellation()

            guard FavoriteSaleAlertPreference.isEnabled() else { return true }
            let favoriteGameIDs = FavoriteGameIDsStore().load()
            let previousFavoriteGames = previousCatalog?.games.map(FeatureGameMapper.favoriteGame(from:))
            let updatedFavoriteGames = updatedCatalog.games.map(FeatureGameMapper.favoriteGame(from:))
            let newlyOnSaleFavorites = FavoriteSaleTransitionDetector.newlyOnSaleFavorites(
                from: previousFavoriteGames,
                to: updatedFavoriteGames,
                favoriteGameIDs: favoriteGameIDs
            )
            await FavoriteSaleNotificationService.scheduleNewSaleNotification(
                for: newlyOnSaleFavorites.map(\.title)
            )
            return !Task.isCancelled
        } catch {
            return false
        }
    }
}
