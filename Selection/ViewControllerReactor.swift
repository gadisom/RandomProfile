//
//  ViewControllerReactor.swift
//  Selection
//
//  Created by 김정원 on 12/27/23.
//
import Moya
import ReactorKit
import RxCocoa
import RxSwift
import RxMoya
class ViewControllerReactor: Reactor {
    
    // 사용자 액션을 나타내는 열거형
    enum Action {
        case selectGender(Gender)
        case toggleLayout
        
    }
    
    // 상태 변화를 나타내는 열거형
    enum Mutation {
        case setSelectedGender(Gender)
        case setLayout(Int)
        case setUsers([RandomUser])
        case setError(Error)
    }

    // 뷰의 상태를 나타내는 구조체
    struct State {
        var selectedGender: Gender
        var columnLayout :Int
        var users :[RandomUser]
    }
    
    // 성별을 나타내는 열거형
    enum Gender {
        case male
        case female
        var stringValue: String {
                switch self {
                case .male:
                    return "male"
                case .female:
                    return "female"
                }
            }
    }
    
    // 초기 상태 설정
    let initialState: State = State(selectedGender: .male, columnLayout: 1,users: [])
    let provider = MoyaProvider<RandomUserService>()
    // 액션을 뮤테이션으로 변환하는 함수
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .selectGender(gender):
            return Observable.just(gender)
                .distinctUntilChanged() // 중복된 성별 변경 필터링
                .flatMapLatest { gender in
                    return self.provider.rx.request(.getUsers(gender: gender))
                        .filterSuccessfulStatusCodes()
                        .map(RandomUserResponse.self)
                        .map { Mutation.setUsers($0.results) }
                        .asObservable()
                        .catch { error in
                            return Observable.just(Mutation.setError(error))
                        }
                }
            
        case .toggleLayout:
            let newLayout = currentState.columnLayout == 1 ? 2 : 1
            return Observable.just(Mutation.setLayout(newLayout))
        }
    }


    
    // 뮤테이션으로 상태를 변경하는 함수
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case let .setSelectedGender(gender):
            newState.selectedGender = gender
        case let .setLayout(layout):
            newState.columnLayout = layout
        case let .setUsers(users):
            newState.users = users // 사용자 목록 업데이트
        case .setError(let error):
            // 오류 처리
            print(error)
        }
        return newState
    }

}



