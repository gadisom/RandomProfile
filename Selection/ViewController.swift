import UIKit
import RxSwift
import ReactorKit
import RxCocoa

class ViewController: UIViewController, StoryboardView, UIScrollViewDelegate, UICollectionViewDelegate {
    var disposeBag = DisposeBag()
    typealias Reactor = ViewControllerReactor
    typealias MenDataSource = UICollectionViewDiffableDataSource<Section, User>
    typealias MenSnapshot = NSDiffableDataSourceSnapshot<Section, User>
    
    
    typealias WomenDataSource = UICollectionViewDiffableDataSource<Section, User>
    typealias WomenSnapshot = NSDiffableDataSourceSnapshot<Section, User>
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var viewOptionButton: UIButton!
    @IBOutlet weak var genderSegmentedControl: UISegmentedControl!
    @IBOutlet weak var menCollectionView: UICollectionView!
    @IBOutlet weak var womenCollectionView: UICollectionView!
    
    private var menDataSource: MenDataSource!
    private var womenDataSource: WomenDataSource!
    private var isTwoColumnLayout = false
    
    private let refreshControl1 = UIRefreshControl()
    private let refreshControl2 = UIRefreshControl()
    
    
    enum Section {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reactor = ViewControllerReactor()
        
        setupLongGesture()
        genderSegmentedControl.isUserInteractionEnabled = false
        scrollView.delegate = self
        
        configureCollectionView(collectionView: menCollectionView)
        configureCollectionView(collectionView: womenCollectionView)
        setupRefreshControl(for: menCollectionView, refreshControl: refreshControl1)
        setupRefreshControl(for: womenCollectionView, refreshControl: refreshControl2)
        setupLoadMoreDataTrigger(for: menCollectionView, gender: .male)
        setupLoadMoreDataTrigger(for: womenCollectionView, gender: .female)
        if let reactor = self.reactor {
            bind(reactor: reactor)
            reactor.action.onNext(.selectGender(.male)) // 초기 API 호출
        }
        viewOptionButton.addTarget(self, action: #selector(toggleViewOption), for: .touchUpInside)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "imageStr",
           let destinationVC = segue.destination as? ProfileImageViewController,
           let cell = sender as? UICollectionViewCell {
            
            // 확인: menCollectionView의 셀인지, 아니면 womenCollectionView의 셀인지
            let isMenCell = menCollectionView.indexPath(for: cell) != nil
            let indexPath = isMenCell ? menCollectionView.indexPath(for: cell) : womenCollectionView.indexPath(for: cell)
            
            if let indexPath = indexPath {
                let selectedImageUrl = isMenCell ?
                reactor?.currentState.menUsers[indexPath.item].picture.large :
                reactor?.currentState.womenUsers[indexPath.item].picture.large
                
                destinationVC.imageUrl = selectedImageUrl
            }
        }
    }
    
    
    
    private func setupLongGesture(){
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
        menCollectionView.addGestureRecognizer(longPressGesture)
        
        let longPressGesture2 = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
        womenCollectionView.addGestureRecognizer(longPressGesture2)
    }
    
    private func setupLoadMoreDataTrigger(for collectionView: UICollectionView, gender: ViewControllerReactor.Gender) {
        collectionView.rx.contentOffset
            .map { [unowned collectionView] offset in
                return offset.y + collectionView.frame.size.height > collectionView.contentSize.height
            }
            .distinctUntilChanged()
            .filter { $0 }
            .map { _ in Reactor.Action.moreLoadData }
            .bind(to: reactor!.action)
            .disposed(by: disposeBag)
    }
    
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state != .began {
            return
        }
        
        let point = gesture.location(in: gesture.view == menCollectionView ? menCollectionView : womenCollectionView)
        guard let indexPath = (gesture.view == menCollectionView ? menCollectionView : womenCollectionView).indexPathForItem(at: point),
              let reactor = reactor else {
            return
        }
        
        let alert = UIAlertController(title: nil, message: "삭제하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            reactor.action.onNext(.deleteUser(indexPath))
        }))
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    
    private func setupRefreshControl(for collectionView: UICollectionView, refreshControl: UIRefreshControl) {
        collectionView.refreshControl = refreshControl
        refreshControl.rx.controlEvent(.valueChanged)
            .map { Reactor.Action.refreshData }
            .bind(to: reactor!.action)
            .disposed(by: disposeBag)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        genderSegmentedControl.selectedSegmentIndex = pageIndex
        reactor?.action.onNext(.selectGender(pageIndex == 0 ? .male : .female))
    }
    private func configureCollectionView(collectionView: UICollectionView) {
        if collectionView == self.menCollectionView {
            collectionView.collectionViewLayout = createLayout(columns: 1)
            menDataSource = MenDataSource(collectionView: collectionView) { [weak self] (collectionView, indexPath, user) -> UICollectionViewCell? in
                return self?.configureCell(collectionView: collectionView, indexPath: indexPath)
            }
        } else if collectionView == self.womenCollectionView {
            collectionView.collectionViewLayout = createLayout(columns: 2)
            womenDataSource = WomenDataSource(collectionView: collectionView) { [weak self] (collectionView, indexPath, user) -> UICollectionViewCell? in
                return self?.configureCell(collectionView: collectionView, indexPath: indexPath)
            }
        }
    }
    
    private func configureCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell? {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileCell", for: indexPath) as? ProfileCell else {
            fatalError("Unable to dequeue ProfileCell")
        }
        let columnLayout = self.reactor?.currentState.columnLayout ?? 1
        
        // 현재 컬렉션 뷰의 데이터 소스에서 사용자 정보를 가져옵니다.
        let user: User?
        if collectionView == menCollectionView {
            user = reactor?.currentState.menUsers[indexPath.row]
        } else if collectionView == womenCollectionView {
            user = reactor?.currentState.womenUsers[indexPath.row]
        } else {
            user = nil
        }
        
        // user가 nil이 아닐 경우에만 셀을 구성합니다.
        if let user = user {
            cell.configure(with: user, reactor: self.reactor!, columnLayout: columnLayout)
        }
        
        return cell
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
        // section.interGroupSpacing = 10
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    @objc private func toggleViewOption() {
        reactor?.action.onNext(.toggleLayout)
    }
    
    
    private func applySnapshotToMen(users: [User], to collectionView: UICollectionView) {
        var snapshot = MenSnapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(users, toSection: .main)
        menDataSource?.apply(snapshot, animatingDifferences: true)
        refreshControl1.endRefreshing()
    }
    
    private func applySnapshotToWomen(users: [User], to collectionView: UICollectionView) {
        var snapshot = WomenSnapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(users, toSection: .main)
        womenDataSource?.apply(snapshot, animatingDifferences: true)
        refreshControl2.endRefreshing()
    }
    
    private func loadExistingData(for gender: ViewControllerReactor.Gender) {
        if gender == .male {
            applySnapshotToMen(users: self.reactor?.currentState.menUsers ?? [], to: self.menCollectionView)
        } else {
            applySnapshotToWomen(users: self.reactor?.currentState.womenUsers ?? [], to: self.womenCollectionView)
        }
    }
    
    func bind(reactor: ViewControllerReactor) {
        // 스크롤 뷰의 페이지 변경에 따른 세그먼트 컨트롤 값 변경
        scrollView.rx.didEndDecelerating
            .map { _ in
                Int(self.scrollView.contentOffset.x / self.scrollView.frame.width)
            }
            .bind(to: genderSegmentedControl.rx.selectedSegmentIndex)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.menUsers }
            .subscribe(onNext: { [weak self] users in
                self!.loadExistingData(for: .male)
            })
            .disposed(by: disposeBag)
        
        // 여성 사용자 데이터 로드
        reactor.state.map { $0.womenUsers }
            .subscribe(onNext: { [weak self] users in
                self!.loadExistingData(for: .female)
            })
            .disposed(by: disposeBag)
        
        // 컬럼 레이아웃 변경에 따른 UI 업데이트
        reactor.state.map { $0.columnLayout }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] columnLayout in
                let title = columnLayout == 2 ? "보기옵션: 2열" : "보기옵션: 1열"
                self?.viewOptionButton.setTitle(title, for: .normal)
                self?.menCollectionView.collectionViewLayout = self?.createLayout(columns: columnLayout) ?? UICollectionViewLayout()
                self?.womenCollectionView.collectionViewLayout = self?.createLayout(columns: columnLayout) ?? UICollectionViewLayout()
            })
            .disposed(by: disposeBag)
        
    }
}

