//
//  PlaygroundListView.swift
//  zSwing
//
//  Created by USER on 1/20/25.
//

import UIKit
import RxSwift

final class PlaygroundListView: UIView {
   // MARK: - Properties
   private let disposeBag = DisposeBag()
   
   // MARK: - UI Components
   private let tableView: UITableView = {
       let table = UITableView()
       table.backgroundColor = .clear
       table.separatorStyle = .none
       table.register(PlaygroundListCell.self, forCellReuseIdentifier: PlaygroundListCell.identifier)
       table.translatesAutoresizingMaskIntoConstraints = false
       return table
   }()
   
   private let emptyStateLabel: UILabel = {
       let label = UILabel()
       label.text = "이 카테고리의 놀이터가 없습니다"
       label.textAlignment = .center
       label.textColor = .secondaryLabel
       label.font = .systemFont(ofSize: 16)
       label.isHidden = true
       label.translatesAutoresizingMaskIntoConstraints = false
       return label
   }()
   
   // MARK: - Initialization
   override init(frame: CGRect) {
       super.init(frame: frame)
       setupUI()
   }
   
   required init?(coder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
   }
   
   // MARK: - Setup
   private func setupUI() {
       backgroundColor = .systemBackground
       
       addSubview(tableView)
       addSubview(emptyStateLabel)
       
       NSLayoutConstraint.activate([
           tableView.topAnchor.constraint(equalTo: topAnchor),
           tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
           tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
           tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
           
           emptyStateLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
           emptyStateLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
       ])
   }
   
   // MARK: - Configuration
   func configure(with viewModel: RideCategoryViewModel) {
       // Bind playgrounds data to tableView
       viewModel.filteredPlaygrounds
           .bind(to: tableView.rx.items(
               cellIdentifier: PlaygroundListCell.identifier,
               cellType: PlaygroundListCell.self
           )) { [weak self] _, playground, cell in
               guard let self = self else { return }
               let distance = viewModel.calculateDistance(to: playground.coordinate)
               cell.configure(with: playground, distance: distance)
           }
           .disposed(by: disposeBag)
       
       // Show/hide empty state
       viewModel.filteredPlaygrounds
           .map { $0.isEmpty }
           .bind(to: emptyStateLabel.rx.isHidden)
           .disposed(by: disposeBag)
       
       // Configure row height
       tableView.rx.setDelegate(self)
           .disposed(by: disposeBag)
   }
}

// MARK: - UITableViewDelegate
extension PlaygroundListView: UITableViewDelegate {
   func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       return 140
   }
}
