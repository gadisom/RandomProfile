import UIKit
import RxSwift
import ReactorKit
import RxCocoa

class ViewController: UIViewController, StoryboardView {
    var disposeBag = DisposeBag()
    typealias Reactor = ViewControllerReactor
    typealias DataSource = UICollectionViewDiffableDataSource<Section, User>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, User>
    
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
        
        configureCollectionViewLayout()
        configureDataSource()
        applyInitialSnapshot()
        if let reactor = self.reactor {
            bind(reactor: reactor)
        }
        viewOptionButton.addTarget(self, action: #selector(toggleViewOption), for: .touchUpInside)
    }
    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { [weak self] (collectionView, indexPath, user) -> UICollectionViewCell? in
            guard let self = self else { return nil }
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileCell", for: indexPath) as? ProfileCell else {
                fatalError("Unable to dequeue ProfileCell")
            }
            cell.configure(with: user, reactor: self.reactor!, columnLayout: self.reactor?.currentState.columnLayout ?? 1)
            return cell
        }
    }
    
    
    private func configureCollectionViewLayout() {
        collectionView.collectionViewLayout = createLayout(columns: 1)
    }
    
    private func createLayout(columns: Int) -> UICollectionViewLayout {
        let itemWidthFraction: CGFloat = columns == 1 ? 1.0 : 0.5
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(itemWidthFraction), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    @objc private func toggleViewOption() {
        reactor?.action.onNext(.toggleLayout)
    }
    
    private func applyInitialSnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems([
            User(name: "John Doe", country: "USA", email: "jodhn@example.com"),
            User(name: "Jane Smith", country: "UK", email: "jane@example.co.uk")
        ], toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    func bind(reactor: ViewControllerReactor) {
        genderSegmentedControl.rx.selectedSegmentIndex
            .map { index in
                index == 0 ? .male : .female
            }
            .map(Reactor.Action.selectGender)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.selectedGender }
            .map { $0 == .male ? 0 : 1 }
            .bind(to: genderSegmentedControl.rx.selectedSegmentIndex)
            .disposed(by: disposeBag)
        viewOptionButton.rx.tap
            .map { Reactor.Action.toggleLayout }
            .bind(to: reactor.action)
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

struct User: Hashable {
    let name: String
    let country: String
    let email: String
    let identifier = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.identifier == rhs.identifier
    }
}
