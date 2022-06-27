//
//  DiaryCell.swift
//  Diary
//
//  Created by dudu, papri on 2022/06/14.
//

import UIKit

final class DiaryCell: UITableViewCell {
    private let baseStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 10
        return stackView
    }()
    
    private let bottomStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 10
        return stackView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    private let weatherImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        
        return imageView
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        return label
    }()
    
    private var imageDownloadTask: Task<UIImage, Error>?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        attribute()
        addSubviews()
        layout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Cell Life Cycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageDownloadTask?.cancel()
        weatherImageView.image = nil
    }
    
    // MARK: - Funcitons
    
    private func attribute() {
        accessoryType = .disclosureIndicator
    }
    
    private func addSubviews() {
        bottomStackView.addArrangedSubviews(dateLabel, weatherImageView, contentLabel)
        baseStackView.addArrangedSubviews(titleLabel, bottomStackView)
        
        contentView.addSubview(baseStackView)
    }
    
    private func layout() {
        NSLayoutConstraint.activate([
            baseStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            baseStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            baseStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            baseStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    func setUpItem(with diary: Diary) {
        titleLabel.text = diary.title
        dateLabel.text = diary.createdDate.formattedString
        setUpImage(with: diary.weather?.icon)
        contentLabel.text = diary.body
    }
    
    private func setUpImage(with url: String?) {
        guard let url = url else { return }
        
        let openWeatherIconImageAPI = OpenWeatherIconImageAPI(path: "\(url)@2x.png")
        imageDownloadTask = NetworkManager().requestImage(api: openWeatherIconImageAPI)
        
        Task {
            let image = try await imageDownloadTask?.value
            
            DispatchQueue.main.async {
                self.weatherImageView.image = image
            }
        }
    }
}
