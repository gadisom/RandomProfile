import UIKit
import RxSwift
import ReactorKit
import RxCocoa

class ViewController: UIViewController, StoryboardView, UIScrollViewDelegate {
    var disposeBag = DisposeBag()
    typealias Reactor = ViewControllerReactor
    typealias DataSource = UICollectionViewDiffableDataSource<Section, RandomUser>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, RandomUser>
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var viewOptionButton: UIButton!
    @IBOutlet weak var genderSegmentedControl: UISegmentedControl!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var dataSource: DataSource!
    private var isTwoColumnLayout = false
    
    enum Section {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reactor = ViewControllerReactor()
        scrollView.delegate = self
        configureCollectionViewLayout()
        configureDataSource()
        if let reactor = self.reactor {
            bind(reactor: reactor)
            reactor.action.onNext(.selectGender(.male)) // 초기 API 호출
        }
        viewOptionButton.addTarget(self, action: #selector(toggleViewOption), for: .touchUpInside)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            let pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
            genderSegmentedControl.selectedSegmentIndex = pageIndex
            reactor?.action.onNext(.selectGender(pageIndex == 0 ? .male : .female))
        }
    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { [weak self] (collectionView, indexPath, user) -> UICollectionViewCell? in
            guard let self = self else { return nil }
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileCell", for: indexPath) as? ProfileCell else {
                fatalError("Unable to dequeue ProfileCell")
            }
            let columnLayout = self.reactor?.currentState.columnLayout ?? 1
            cell.configure(with: user, reactor: self.reactor!, columnLayout: columnLayout)
            return cell
        }
    }
    
    
    private func configureCollectionViewLayout() {
        collectionView.collectionViewLayout = createLayout(columns: 1)
    }
    
    private func createLayout(columns: Int) -> UICollectionViewLayout {
        let itemWidthFraction: CGFloat = columns == 1 ? 1 : 0.5
        let itemHightFraction: CGFloat = columns == 1 ? 0.2 : 0.4
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(itemWidthFraction), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(itemHightFraction))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    @objc private func toggleViewOption() {
        reactor?.action.onNext(.toggleLayout)
    }
    
    private func applySnapshot(users: [RandomUser]) {
        guard let dataSource = dataSource else {
            print("DataSource is nil")
            return
        }
        
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(users, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func bind(reactor: ViewControllerReactor) {
        genderSegmentedControl.rx.selectedSegmentIndex
            .map { index in
                index == 0 ? .male : .female
            }
            .distinctUntilChanged()
            .map(Reactor.Action.selectGender)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.selectedGender }
            .distinctUntilChanged()
            .map { $0 == .male ? 0 : 1 }
            .bind(to: genderSegmentedControl.rx.selectedSegmentIndex)
            .disposed(by: disposeBag)
        viewOptionButton.rx.tap
            .map { Reactor.Action.toggleLayout }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        reactor.state.map { $0.users }
            .subscribe(onNext: { [weak self] users in
                self?.applySnapshot(users: users)
            })
            .disposed(by: disposeBag)
        reactor.state
            .map { $0.columnLayout }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] columnLayout in
                let title = columnLayout == 2 ? "보기옵션: 2열" : "보기옵션: 1열"
                self?.viewOptionButton.setTitle(title, for: .normal)
                
                if let layout = self?.createLayout(columns: columnLayout) {
                    self?.collectionView.setCollectionViewLayout(layout, animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
}

