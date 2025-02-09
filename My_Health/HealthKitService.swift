//
//  HealthKitService.swift
//  My_Health
//
//  Created by Anas on 09/02/25.
//

import Foundation

public protocol HealthKitService {
    func requestHealthKitPermissions(completion: @escaping (String) -> Void)
    func fetchHealthData(completion: @escaping ([[String: Any]]) -> Void)
}
