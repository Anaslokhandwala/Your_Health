//
//  ViewController.swift
//  Your Health
//
//  Created by Anas on 08/02/25.
//

import UIKit
import My_Health

class ViewController: UIViewController, DatePickerDelegate {

    @IBOutlet weak var tableView: UITableView!

    let getHealth = GetHealth()
    
    var data: [[String: Any]] = []
    var filteredData: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        getHealth.checkPermission(completion: {status in
            if status == "Granted" {
                self.getHealth.getHealthData(completion: {fetchedData in
                    DispatchQueue.main.async {
                        if fetchedData.count == 0 {
                            self.showAlert(title: "", message: "No Data Found.")
                        }else{
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd/MM/yy"  // Ensure this matches your date format in the data

                            self.data = fetchedData.sorted {
                                guard
                                    let date1String = $0["date"] as? String,
                                    let date2String = $1["date"] as? String,
                                    let date1 = dateFormatter.date(from: date1String),
                                    let date2 = dateFormatter.date(from: date2String)
                                else {
                                    return false
                                }
                                return date1 > date2  // Sort from today to the earliest date
                            }
                            self.filteredData = self.data
                            self.tableView.reloadData()
                        }
                    }
                })
            }else{
                DispatchQueue.main.async {
                    self.showAlert(title: "Health Access Denied", message: "HealthKit permission is required to fetch health data. Please enable it in Settings.")
                }
            }
        })
        
        self.tableView.register(UINib(nibName: "Health_Data_Cell", bundle: nil), forCellReuseIdentifier: "Health_Data_Cell")
        
    }


    // MARK: - Filter Button Action
    @IBAction func filterButton(_ sender: UIButton) {
        let datePickerVC = DatePickerViewController()
        datePickerVC.delegate = self
        datePickerVC.modalPresentationStyle = .popover
        present(datePickerVC, animated: true)
    }

    func didSelectDateRange(startDate: String, endDate: String) {
        if startDate.isEmpty && endDate.isEmpty {
            // If both startDate and endDate are empty, show all data
            filteredData = data
        } else {
            // Filter data where the date falls between startDate and endDate
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yy"
            
            if let start = dateFormatter.date(from: startDate),
               let end = dateFormatter.date(from: endDate) {
                filteredData = data.filter {
                    if let dateString = $0["date"] as? String, let date = dateFormatter.date(from: dateString) {
                        return date >= start && date <= end
                    }
                    return false
                }
            }
        }
        tableView.reloadData()
    }
    
    func showAlert(title:String,message:String){
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - UITableView Delegate & DataSource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Health_Data_Cell", for: indexPath) as! Health_Data_Cell
        
        let item = filteredData[indexPath.row]
        
        cell.dateLbl.text = "Date: \(item["date"] as? String ?? "N/A")"
        cell.heartLbl.text = "\(item["heart_rate"] ?? "N/A") BPM"
        cell.stepsLbl.text = "\(item["steps"] ?? "N/A")"
        cell.hoursLbl.text = "\(item["sleep_duration"] ?? "N/A")"
        
        // Add corner radius for better appearance
        cell.layer.cornerRadius = 10
        cell.layer.masksToBounds = true
        
        return cell
    }
    
    // Set row height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 127 // Adjust the row height as needed
    }

}

