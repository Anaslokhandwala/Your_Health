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
                            self.data = fetchedData.sorted { $0["date"] as! String > $1["date"] as! String }
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
        datePickerVC.modalPresentationStyle = .pageSheet
        present(datePickerVC, animated: true)
    }

    func didSelectDate(_ date: String) {
        if date.isEmpty {
            filteredData = data
        } else {
            filteredData = data.filter { $0["date"] as? String == date }
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

