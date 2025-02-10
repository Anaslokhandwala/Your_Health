//
//  internalHealthKit.swift
//  My_Health
//
//  Created by Anas on 09/02/25.
//

import Foundation
import HealthKit

public class InternalHealthKit: HealthKitService { // Conforming to protocol

    let healthStore = HKHealthStore()
    var data: [[String: Any]] = []
    
    // MARK: - Request HealthKit Permissions
    public func requestHealthKitPermissions(completion:(@escaping (String) -> Void)) {
        let healthDataToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: healthDataToRead) { success, error in
            if success {
                completion("Granted")
            } else {
                completion("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func getEarliestHealthDataDate(completion: @escaping (Date?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var earliestDate: Date?

        // Define all health types we want to check
        let healthTypes: [HKSampleType] = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        for healthType in healthTypes {
            dispatchGroup.enter()
            
            let query = HKSampleQuery(sampleType: healthType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, results, _ in
                if let sample = results?.first {
                    let sampleDate = sample.startDate
                    if earliestDate == nil || sampleDate < earliestDate! {
                        earliestDate = sampleDate
                    }
                }
                dispatchGroup.leave()
            }
            
            healthStore.execute(query)
        }

        dispatchGroup.notify(queue: .main) {
            completion(earliestDate)
        }
    }

    
    // MARK: - Fetch Health Data
    public func fetchHealthData( completion: @escaping ([[String:Any]]) -> Void) {
        getEarliestHealthDataDate { earliestDate in
            guard let startDate = earliestDate else {
                completion([])
                return
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            self.fetchDataRecursively(currentDate: startDate, endDate: Date(), tempData: []) { fetchedData in
                DispatchQueue.main.async {
                    self.data = fetchedData.sorted { $0["date"] as! String > $1["date"] as! String }

                    completion(self.data)
                    
                }
            }
        }
    }

    func fetchDataRecursively(currentDate: Date, endDate: Date, tempData: [[String: Any]], completion: @escaping ([[String: Any]]) -> Void) {
        if currentDate > endDate {
            completion(tempData) // Stop recursion when all dates are processed
            return
        }

        let dateString = DateFormatter.localizedString(from: currentDate, dateStyle: .short, timeStyle: .none)
        let dispatchGroup = DispatchGroup()
        
        var steps: Int = 0
        var heartRate: Double = 0
        var sleepDuration: Double = 0

        dispatchGroup.enter()
        fetchStepCount(for: currentDate) { stepCount in
            steps = stepCount
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        fetchHeartRate(for: currentDate) { rate in
            heartRate = rate
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        fetchSleepDuration(for: currentDate) { duration in
            sleepDuration = duration
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            var updatedData = tempData

            let safeHeartRate = heartRate.isFinite ? Int(heartRate) : nil

            updatedData.append([
                "date": dateString,
                "steps": steps,
                "heart_rate": safeHeartRate ?? 0, // Use 0 or any default value if it's NaN or Inf
                "sleep_duration": "\(Int(sleepDuration / 3600))h \(Int(sleepDuration.truncatingRemainder(dividingBy: 3600) / 60))m"
            ])
            
            let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            self.fetchDataRecursively(currentDate: nextDate, endDate: endDate, tempData: updatedData, completion: completion)
        }
    }
    
    // MARK: - Fetch Step Count
    func fetchStepCount(for date: Date, completion: @escaping (Int) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let stepCount = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            completion(Int(stepCount))
        }

        healthStore.execute(query)
    }


    // MARK: - Fetch Heart Rate
    func fetchHeartRate(for date: Date, completion: @escaping (Double) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, results, _ in
            let total = results?.compactMap { ($0 as? HKQuantitySample)?.quantity.doubleValue(for: HKUnit(from: "count/min")) }.reduce(0, +) ?? 0
            let avgHeartRate = total / Double(results?.count ?? 1) // Calculate average heart rate
            completion(avgHeartRate)
        }

        healthStore.execute(query)
    }

    // MARK: - Fetch Sleep Duration
    func fetchSleepDuration(for date: Date, completion: @escaping (Double) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, results, _ in
            let totalSleep = results?.compactMap { ($0 as? HKCategorySample)?.endDate.timeIntervalSince(($0 as? HKCategorySample)!.startDate) }.reduce(0, +) ?? 0
            completion(totalSleep) // Return sleep in seconds
        }

        healthStore.execute(query)
    }
    
}
