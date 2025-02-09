//
//  GetHealth.swift
//  My_Health
//
//  Created by Anas on 08/02/25.
//

import Foundation

public class GetHealth {
    
    private let healthKitService: HealthKitService

    private static func createDefaultHealthKitService() -> HealthKitService {
        return InternalHealthKit()
    }

    public init(healthKitService: HealthKitService? = nil) {
        self.healthKitService = healthKitService ?? GetHealth.createDefaultHealthKitService()
    }

    
    public func checkPermission(completion: @escaping (String) -> Void) {
        healthKitService.requestHealthKitPermissions { status in
            completion(status)
        }
    }
    
    public func getHealthData(completion: @escaping ([[String:Any]]) -> Void) {
        healthKitService.fetchHealthData { data in
            completion(data)
        }
    }
}



