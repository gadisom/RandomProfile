import UIKit
import RxSwift
import ReactorKit
import RxCocoa

class ViewController: UIViewController, StoryboardView, UIScrollViewDelegate {
    var disposeBag = DisposeBag()
    typealias Reactor = ViewControllerReactor
    typealias DataSource = UICollectionViewDiffableDataSource<Section, RandomMen>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, RandomMen>
    
    typealias DataSource2 = UICollectionViewDiffableDataSource<Section, RandomWomen>
    typealias Snapshot2 = NSDiffableDataSourceSnapshot<Section, RandomWomen>
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var viewOptionButton: UIButton!
    @IBOutlet weak var genderSegmentedControl: UISegmentedControl!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionView2: UICollectionView!
    
    private var dataSource: DataSource!
    private var dataSource2: DataSource2!
    private var isTwoColumnLayout = false
    
    enum Section {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reactor = ViewControllerReactor()
        scrollView.delegate = self
        configureCollectionViewLayout(collectionView: collectionView)
        configureCollectionViewLayout(collectionView: collectionView2)
        configureDataSource(collectionView: collectionView)
        configureDataSource(collectionView: collectionView2)
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
    private func configureDataSource(collectionView: UICollectionView) {
        if collectionView == self.collectionView {
            dataSource = DataSource(collectionView: collectionView) { [weak self] (collectionView, indexPath, user) -> UICollectionViewCell? in
                return self?.configureMenCell(collectionView: collectionView, indexPath: indexPath, user: user)
            }
        } else if collectionView == self.collectionView2 {
            dataSource2 = DataSource2(collectionView: collectionView) { [weak self] (collectionView, indexPath, user) -> UICollectionViewCell? in
                return self?.configureWomenCell(collectionView: collectionView, indexPath: indexPath, user: user)
            }
        }
    }
    private func configureMenCell(collectionView: UICollectionView, indexPath: IndexPath, user: RandomMen) -> UICollectionViewCell? {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileCell", for: indexPath) as? ProfileCell else {
            fatalError("Unable to dequeue ProfileCell")
        }
        let columnLayout = self.reactor?.currentState.columnLayout ?? 1
        cell.configure(with: user, reactor: self.reactor!, columnLayout: columnLayout)
        return cell
    }
    private func configureWomenCell(collectionView: UICollectionView, indexPath: IndexPath, user: RandomWomen) -> UICollectionViewCell? {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileCell", for: indexPath) as? ProfileCell else {
            fatalError("Unable to dequeue ProfileCell")
        }
        let columnLayout = self.reactor?.currentState.columnLayout ?? 1
        cell.configure(with: user, reactor: self.reactor!, columnLayout: columnLayout)
        return cell
    }
    
    
    private func configureCollectionViewLayout(collectionView:UICollectionView) {
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
    
    
    private func applySnapshotToMen(users: [RandomMen], to collectionView: UICollectionView) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(users, toSection: .main)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    private func applySnapshotToWomen(users: [RandomWomen], to collectionView: UICollectionView) {
        var snapshot = Snapshot2()
        snapshot.appendSections([.main])
        snapshot.appendItems(users, toSection: .main)
        dataSource2?.apply(snapshot, animatingDifferences: true)
    }
    
    private func loadExistingData(for gender: ViewControllerReactor.Gender) {
        if gender == .male {
            applySnapshotToMen(users: self.reactor?.currentState.menUsers ?? [], to: self.collectionView)
        } else {
            applySnapshotToWomen(users: self.reactor?.currentState.womenUsers ?? [], to: self.collectionView2)
        }
    }
    
    func bind(reactor: ViewControllerReactor) {
        // 세그먼트 컨트롤 값 변경에 따른 액션 바인딩
        genderSegmentedControl.rx.selectedSegmentIndex
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] index in
                let gender = index == 0 ? ViewControllerReactor.Gender.male : .female
                if (gender == .male && self?.reactor?.currentState.menUsers.isEmpty == true) ||
                    (gender == .female && self?.reactor?.currentState.womenUsers.isEmpty == true) {
                    self?.reactor?.action.onNext(.selectGender(gender))
                } else {
                    self?.loadExistingData(for: gender)
                }
            })
            .disposed(by: disposeBag)
        
        // 스크롤 뷰의 페이지 변경에 따른 세그먼트 컨트롤 값 변경
        scrollView.rx.didEndDecelerating
            .map { _ in
                Int(self.scrollView.contentOffset.x / self.scrollView.frame.width)
            }
            .bind(to: genderSegmentedControl.rx.selectedSegmentIndex)
            .disposed(by: disposeBag)
        reactor.state.map { $0.menUsers }
            .subscribe(onNext: { [weak self] users in
                self?.applySnapshotToMen(users: users, to: self?.collectionView ?? UICollectionView())
            })
            .disposed(by: disposeBag)
        
        // 여성 사용자 데이터 로드
        reactor.state.map { $0.womenUsers }
            .subscribe(onNext: { [weak self] users in
                self?.applySnapshotToWomen(users: users, to: self?.collectionView2 ?? UICollectionView())
            })
            .disposed(by: disposeBag)
        
        // 레이아웃 변경에 따른 액션 바인딩
        viewOptionButton.rx.tap
            .map { Reactor.Action.toggleLayout }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // 컬럼 레이아웃 변경에 따른 UI 업데이트
        reactor.state.map { $0.columnLayout }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] columnLayout in
                let title = columnLayout == 2 ? "보기옵션: 2열" : "보기옵션: 1열"
                self?.viewOptionButton.setTitle(title, for: .normal)
                self?.collectionView.collectionViewLayout = self?.createLayout(columns: columnLayout) ?? UICollectionViewLayout()
                self?.collectionView2.collectionViewLayout = self?.createLayout(columns: columnLayout) ?? UICollectionViewLayout()
            })
            .disposed(by: disposeBag)
    }
}

