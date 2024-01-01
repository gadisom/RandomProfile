//
//  CollectionViewCell.swift
//  Selection
//
//  Created by 김정원 on 12/28/23.
//

import UIKit
import ReactorKit

class ProfileCell: UICollectionViewCell, StoryboardView {
    var disposeBag = DisposeBag()
    
    // 이미지 뷰, 라벨들의 선언
    let userProfileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let countryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let emailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var oneColumnConstraints: [NSLayoutConstraint] = []
    var twoColumnConstraints: [NSLayoutConstraint] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayoutConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupLayoutConstraints()
    }
    
    private func setupViews() {
        addSubview(userProfileImageView)
        addSubview(nameLabel)
        addSubview(countryLabel)
        addSubview(emailLabel)
    }
    
    private func setupLayoutConstraints() {
        // 일반적인 제약 조건 설정
        NSLayoutConstraint.activate([
            userProfileImageView.heightAnchor.constraint(equalTo: userProfileImageView.widthAnchor)
        ])
        
        // 1열 레이아웃 제약 조건
        oneColumnConstraints = [
            userProfileImageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            userProfileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            userProfileImageView.widthAnchor.constraint(equalToConstant: 80),
            userProfileImageView.heightAnchor.constraint(equalToConstant: 80),
            nameLabel.topAnchor.constraint(equalTo: userProfileImageView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: userProfileImageView.trailingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            countryLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            countryLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            countryLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            emailLabel.topAnchor.constraint(equalTo: countryLabel.bottomAnchor, constant: 4),
            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor)
        ]
        
        // 2열 레이아웃 제약 조건
        twoColumnConstraints = [
                userProfileImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.45),
                userProfileImageView.topAnchor.constraint(equalTo: topAnchor),
                userProfileImageView.centerXAnchor.constraint(equalTo: centerXAnchor),

                nameLabel.topAnchor.constraint(equalTo: userProfileImageView.bottomAnchor, constant: 10),
                nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
                nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
                
                countryLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
                countryLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
                countryLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
                
                emailLabel.topAnchor.constraint(equalTo: countryLabel.bottomAnchor, constant: 4),
                emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
                emailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
                emailLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10)
            ]
        NSLayoutConstraint.activate(oneColumnConstraints)
    }
    
    private func updateLayout(columnLayout: Int) {
        if columnLayout == 1 {
            NSLayoutConstraint.deactivate(twoColumnConstraints)
            NSLayoutConstraint.activate(oneColumnConstraints)
        } else {
            NSLayoutConstraint.deactivate(oneColumnConstraints)
            NSLayoutConstraint.activate(twoColumnConstraints)
        }
        layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        userProfileImageView.image = nil
        nameLabel.text = nil
        countryLabel.text = nil
        emailLabel.text = nil
    }
    
    func configure(with user: RandomUser, reactor: ViewControllerReactor, columnLayout: Int) {
        nameLabel.text = user.name.fullName
        countryLabel.text = user.location.country
        emailLabel.text = user.email
        userProfileImageView.image = UIImage(systemName: "person.fill")
        
        self.reactor = reactor
        updateLayout(columnLayout: columnLayout)
        bind(reactor: reactor)
    }
    
    func bind(reactor: ViewControllerReactor) {
        reactor.state
            .map { $0.columnLayout }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] columnLayout in
                self?.updateLayout(columnLayout: columnLayout)
            })
            .disposed(by: disposeBag)
    }
}
