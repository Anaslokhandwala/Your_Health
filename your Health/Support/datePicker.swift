import UIKit

protocol DatePickerDelegate: AnyObject {
    func didSelectDate(_ date: String)
}

class DatePickerViewController: UIViewController {

    weak var delegate: DatePickerDelegate?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Pick a Date"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.maximumDate = Date()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    private let filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Apply", for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: #selector(filterDate), for: .touchUpInside)
        return button
    }()

    private let clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear", for: .normal)
        button.backgroundColor = UIColor.systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: #selector(clearFilter), for: .touchUpInside)
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.backgroundColor = UIColor.systemGray
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSheetPresentation()
    }

    private func setupUI() {
        view.backgroundColor = .white
        view.layer.cornerRadius = 15
        view.clipsToBounds = true

        let buttonStackView = UIStackView(arrangedSubviews: [cancelButton, clearButton, filterButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 10
        buttonStackView.distribution = .fillEqually
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false

        let containerStackView = UIStackView(arrangedSubviews: [titleLabel, datePicker, buttonStackView])
        containerStackView.axis = .vertical
        containerStackView.spacing = 20
        containerStackView.alignment = .fill
        containerStackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(containerStackView)

        NSLayoutConstraint.activate([
            containerStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            buttonStackView.leadingAnchor.constraint(equalTo: containerStackView.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            buttonStackView.heightAnchor.constraint(equalToConstant: 50),

            titleLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func setupSheetPresentation() {
        if let sheet = self.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
    }

    @objc private func filterDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        let selectedDate = dateFormatter.string(from: datePicker.date)
        delegate?.didSelectDate(selectedDate)
        dismiss(animated: true)
    }

    @objc private func clearFilter() {
        delegate?.didSelectDate("")
        dismiss(animated: true)
    }

    @objc private func dismissView() {
        dismiss(animated: true)
    }
}
