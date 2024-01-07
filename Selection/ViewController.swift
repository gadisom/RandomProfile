import UIKit
import RxSwift
import ReactorKit
import RxCocoa

class ViewController: UIViewController, StoryboardView, UIScrollViewDelegate, UICollectionViewDelegate {
    var disposeBag = DisposeBag()
    typealias Reactor = ViewControllerReactor
    typealias DataSource = UICollectionViewDiffableDataSource<Section, User>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, User>
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var viewOptionButton: UIButton!
    @IBOutlet weak var genderSegmentedControl: UISegmentedControl!
    @IBOutlet weak var menCollectionView: UICollectionView!
    @IBOutlet weak var womenCollectionView: UICollectionView!
    @IBAction func genderSegmentedControl(_ sender: UISegmentedControl){}
    @IBAction func viewOptionButton(_ sender: Any) {}
    
    private var menDataSource: DataSource!
    private var womenDataSource: DataSource!
    private var isTwoColumnLayout = false
    private var isInitialLoadCompleted = false // 플래그 변수
    private let menRefreshControl = UIRefreshControl()
    private let womenRefreshControl = UIRefreshControl()
    
    enum Section {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reactor = ViewControllerReactor()
        scrollView.delegate = self
        setCollectionView()
    }
    //MARK: - CollectionView 설정
    private func setCollectionView() {
        configureCollectionView(collectionView: menCollectionView, refreshControl: menRefreshControl, gender: .male, columns: 1)
        configureCollectionView(collectionView: womenCollectionView, refreshControl: womenRefreshControl, gender: .female, columns: 1)
        isInitialLoadCompleted = true // 초기 로드 완료 표시
    }
    
    private func createDataSource(for collectionView: UICollectionView) -> DataSource {
        return DataSource(collectionView: collectionView) { [weak self] (collectionView, indexPath, user) -> UICollectionViewCell? in
            return self?.configureCell(collectionView: collectionView, indexPath: indexPath)
        }
    }
    
    private func configureCollectionView(collectionView: UICollectionView, refreshControl: UIRefreshControl, gender: Reactor.Gender, columns: Int) {
        collectionView.collectionViewLayout = createLayout(columns: columns)
        let dataSource = createDataSource(for: collectionView)
        gender == .male ? (menDataSource = dataSource) : (womenDataSource = dataSource)
        collectionView.refreshControl = refreshControl
    }
    private func configureCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell? {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileCell", for: indexPath) as? ProfileCell else {
            fatalError("Unable to dequeue ProfileCell")
        }
        let columnLayout = self.reactor?.currentState.columnLayout ?? 1
        // 현재 컬렉션 뷰의 데이터 소스에서 사용자 정보를 가져온다.
        let user: User?
        if collectionView == menCollectionView {
            user = reactor?.currentState.menUsers[indexPath.row]
        } else if collectionView == womenCollectionView {
            user = reactor?.currentState.womenUsers[indexPath.row]
        } else {
            user = nil
            print("프로필 호출 Error")
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
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(itemHightFraction))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    
}
//MARK: - Bind

extension ViewController {
    
    func bind(reactor: ViewControllerReactor) {
        
        genderSegmentedControl.rx.selectedSegmentIndex
            .distinctUntilChanged()
            .bind { index in
                self.moveToPage(index)
                reactor.action.onNext(index == 0 ? .selectGender(.male) : .selectGender(.female))
            }
            .disposed(by: disposeBag)
        viewOptionButton.rx.tap
            .map { Reactor.Action.toggleLayout }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.menUsers }
            .bind { [weak self] users in
                self?.applySnapshot(users: users, to: self!.menCollectionView, refreshControl: self!.menRefreshControl)
            }
            .disposed(by: disposeBag)
        
        // 여성 사용자 데이터 로드
        reactor.state.map { $0.womenUsers }
            .bind { [weak self] users in
                self?.applySnapshot(users: users, to: self!.womenCollectionView, refreshControl: self!.womenRefreshControl)
            }
            .disposed(by: disposeBag)
        
        // 컬럼 레이아웃 변경에 따른 UI 업데이트
        reactor.state.map { $0.columnLayout }
            .distinctUntilChanged()
            .bind { [weak self] columnLayout in
                let title = "보기옵션: \(columnLayout)열"
                self?.viewOptionButton.setTitle(title, for: .normal)
                self?.menCollectionView.collectionViewLayout = self?.createLayout(columns: columnLayout) ?? UICollectionViewLayout()
                self?.womenCollectionView.collectionViewLayout = self?.createLayout(columns: columnLayout) ?? UICollectionViewLayout()
            }
            .disposed(by: disposeBag)
        
        menCollectionView.rx.contentOffset
            .filter { _ in self.isInitialLoadCompleted }
            .map { [self] offset in
                offset.y + menCollectionView.frame.size.height > self.menCollectionView.contentSize.height
            }
            .distinctUntilChanged()
            .filter { $0 }
            .map { _ in Reactor.Action.moreLoadData }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        womenCollectionView.rx.contentOffset
            .filter { _ in self.isInitialLoadCompleted }
            .map { [self] offset in
                offset.y + womenCollectionView.frame.size.height > self.womenCollectionView.contentSize.height
            }
            .distinctUntilChanged()
            .filter { $0 }
            .map { _ in Reactor.Action.moreLoadData }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        menRefreshControl.rx.controlEvent(.valueChanged)
            .map { Reactor.Action.refreshData }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        womenRefreshControl.rx.controlEvent(.valueChanged)
            .map { Reactor.Action.refreshData }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        menCollectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let vc = self, let selectedUser = vc.reactor?.currentState.menUsers[indexPath.row] else { return }
                vc.navigateToProfileImageView(with: selectedUser.picture.large)
            })
            .disposed(by: disposeBag)

        womenCollectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let vc = self, let selectedUser = vc.reactor?.currentState.womenUsers[indexPath.row] else { return }
                vc.navigateToProfileImageView(with: selectedUser.picture.large)
            })
            .disposed(by: disposeBag)

        let menLongPressGesture = UILongPressGestureRecognizer()
        menCollectionView.addGestureRecognizer(menLongPressGesture)
        let womenLongPressGesture = UILongPressGestureRecognizer()
        womenCollectionView.addGestureRecognizer(womenLongPressGesture)
        menLongPressGesture.rx.event
            .filter { $0.state == .began }
            .map { [weak self] gesture -> IndexPath? in
                let point = gesture.location(in: self?.menCollectionView)
                return self?.menCollectionView.indexPathForItem(at: point)
            }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] indexPath in
                self?.showDeletionAlert(for: indexPath, in: self?.menCollectionView, reactor: reactor)
            })
            .disposed(by: disposeBag)
        
        womenLongPressGesture.rx.event
            .filter { $0.state == .began }
            .map { [weak self] gesture -> IndexPath? in
                let point = gesture.location(in: self?.womenCollectionView)
                return self?.womenCollectionView.indexPathForItem(at: point)
            }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] indexPath in
                self?.showDeletionAlert(for: indexPath, in: self?.womenCollectionView, reactor: reactor)
            })
            .disposed(by: disposeBag)
        
    }
    
    //MARK: - 동작관련
    private func applySnapshot(users: [User], to collectionView: UICollectionView, refreshControl: UIRefreshControl) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(users, toSection: .main)
        if collectionView == menCollectionView {
            menDataSource?.apply(snapshot, animatingDifferences: true)
        } else if collectionView == womenCollectionView {
            womenDataSource?.apply(snapshot, animatingDifferences: true)
        }
        refreshControl.endRefreshing()
    }
    private func navigateToProfileImageView(with imageUrl: String?) {
        guard let imageUrl = imageUrl else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let profileImageVC = storyboard.instantiateViewController(withIdentifier: "ProfileImageViewController") as? ProfileImageViewController {
            profileImageVC.imageUrl = imageUrl
            self.navigationController?.pushViewController(profileImageVC, animated: true)
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        genderSegmentedControl.selectedSegmentIndex = pageIndex
        reactor?.action.onNext(.selectGender(pageIndex == 0 ? .male : .female))
    }
    func moveToPage (_ index: Int)
    {
        let width = scrollView.frame.width
        let offset = CGPoint(x: width * CGFloat(index), y: 0)
        scrollView.setContentOffset(offset, animated: true)
    }
    private func showDeletionAlert(for indexPath: IndexPath, in collectionView: UICollectionView?, reactor: ViewControllerReactor) {
        let alert = UIAlertController(title: nil, message: "삭제하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            reactor.action.onNext(.deleteUser(indexPath))
        }))
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}
