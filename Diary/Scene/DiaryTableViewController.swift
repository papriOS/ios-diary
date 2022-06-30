//
//  Diary - DiaryTableViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit
import CoreLocation

extension DiaryTableViewController {
    static func instance(coordinator: DiaryTableCoordinator, databaseManager: DatabaseManageable) -> DiaryTableViewController {
        return DiaryTableViewController(coordinator: coordinator, databaseManager: databaseManager)
    }
}

final class DiaryTableViewController: UITableViewController {
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Int, Diary>
    private typealias DataSource = UITableViewDiffableDataSource<Int, Diary>
    
    private var dataSource: DataSource?
    private let coordinator: DiaryTableCoordinator
    private let databaseManager: DatabaseManageable
    private let locationManager = CLLocationManager()
    
    private var diarys = [Diary]() {
        didSet {
            applySnapshot()
        }
    }
    
    init(coordinator: DiaryTableCoordinator, databaseManager: DatabaseManageable) {
        self.coordinator = coordinator
        self.databaseManager = databaseManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    
    private func create(with weather: Weather?) {
        let newDiary = Diary(title: "", body: "", createdDate: Date.now, weather: weather)
        diarys.insert(newDiary, at: .zero)
        databaseManager.create(data: newDiary)
    }
    
    private func read() {
        guard let results = databaseManager.read() else { return }
        
        diarys = results.map { entity in
            var weather: Weather?
            
            if let main = entity.weather, let icon = entity.weatherIcon {
                weather = Weather(main: main, icon: icon)
            }
            
            return Diary(
                title: entity.title,
                body: entity.body,
                createdDate: entity.createdDate,
                id: entity.id,
                weather: weather
            )
        }
    }
    
    private func find(id: String) -> Int? {
        return diarys.firstIndex { $0.id == id }
    }

    @objc
    private func addButtonDidTap() {
        locationManager.requestLocation()
    }
    
    private func makeDiary(with location: CLLocationCoordinate2D?) async {
        do {
            let weather = try await requestWeather(location: location)
            create(with: weather)
            guard let diary = diarys.first else { return }
            
            coordinator.pushToDiaryDetail(diary)
        } catch {
            AlertBuilder(viewController: self)
                .addAction(title: "확인", style: .default)
                .show(title: "서버연결에 실패했습니다", message: "다시 시도해 보세요", style: .alert)
        }
    }
    
    private func requestWeather(location: CLLocationCoordinate2D?) async throws -> Weather? {
        guard let location = location else { return nil }

        let openWeahterAPI = OpenWeatherAPI(latitude: location.latitude, longitude: location.longitude)
        let task = NetworkManager().request(api: openWeahterAPI)
        
        switch await task.result {
        case .success(let data):
            return WeatherInfomation.parse(data)?.weather.first
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - TableViewDelegate

extension DiaryTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let diary = diarys[indexPath.row]
        coordinator.pushToDiaryDetail(diary)
    }
    
    override func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        return ContextualActionBuilder()
            .addAction(
                title: "삭제",
                image: UIImage(systemName: "trash.circle"),
                style: .destructive,
                action: { [weak self] in
                    guard let diary = self?.diarys[indexPath.row] else { return }
                    self?.delete(diary: diary)
                })
            .addAction(
                title: "공유",
                backgroundColor: .systemBlue,
                image: UIImage(systemName: "square.and.arrow.up.circle"),
                style: .normal,
                action: { [weak self] in
                    guard let diary = self?.diarys[indexPath.row] else { return }
                    
                    let text = diary.title + "\n\n" + diary.body
                    let activityViewController = UIActivityViewController(
                        activityItems: [text],
                        applicationActivities: nil
                    )
                    
                    self?.present(activityViewController, animated: true)
                })
            .build()
    }
}

// MARK: - CLLocationManagerDelegate

extension DiaryTableViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last?.coordinate else { return }
        
        Task {
            await makeDiary(with: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task {
            await makeDiary(with: nil)
        }
    }
}

// MARK: - DiaryDetailViewDelegate

extension DiaryTableViewController: DiaryDetailViewDelegate {
    func update(diary: Diary) {
        guard let index = find(id: diary.id) else { return }
    
        diarys[index] = diary
        databaseManager.update(data: diary)
    }
    
    func delete(diary: Diary) {
        guard let index = find(id: diary.id) else { return }
    
        diarys.remove(at: index)
        databaseManager.delete(data: diary)
    }
}

// MARK: - SetUp

extension DiaryTableViewController {
    private func setUp() {
        setUpNavigationBar()
        setUpTableView()
        setUpLocationManager()
    }
    
    private func setUpNavigationBar() {
        title = "일기장"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonDidTap)
        )
    }
    
    private func setUpTableView() {
        tableView.separatorInset.left = 20
        tableView.register(DiaryCell.self, forCellReuseIdentifier: DiaryCell.reuseIdentifier)
        makeDataSource()
        read()
    }
    
    private func setUpLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func makeDataSource() {
        dataSource = DataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: DiaryCell.reuseIdentifier,
                for: indexPath
            ) as? DiaryCell
            
            cell?.setUpItem(with: item)
            return cell
        }
    }
    
    private func applySnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(diarys)
        
        dataSource?.apply(snapshot)
    }
}
