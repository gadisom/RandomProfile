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
        case setMenUsers([RandomMen])
        case setWomenUsers([RandomWomen])
        case setError(Error)
    }

    // 뷰의 상태를 나타내는 구조체
    struct State {
        var selectedGender: Gender
        var columnLayout: Int
        var menUsers: [RandomMen]
        var womenUsers: [RandomWomen]
    }
    
    // 성별을 나타내는 열거형
    enum Gender {
        case male
        case female
    }
    
    // 초기 상태 설정
    let initialState: State = State(selectedGender: .male, columnLayout: 1, menUsers: [], womenUsers: [])
    let provider = MoyaProvider<RandomUserService>()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .selectGender(gender):
            let service: RandomUserService = (gender == .male) ? .getMenUsers : .getWomenUsers
            return self.provider.rx.request(service)
                .filterSuccessfulStatusCodes()
                .flatMap { response -> Single<Mutation> in // Single<Mutation> 반환
                    do {
                        if gender == .male {
                            let menResponse = try response.map(RandomMenResponse.self)
                            return Single.just(Mutation.setMenUsers(menResponse.results))
                        } else {
                            let womenResponse = try response.map(RandomWomenResponse.self)
                            return Single.just(Mutation.setWomenUsers(womenResponse.results))
                        }
                    } catch {
                        return Single.just(Mutation.setError(error))
                    }
                }
                .asObservable() // Single을 Observable로 변환

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
        case let .setMenUsers(users):
            newState.menUsers = users
        case let .setWomenUsers(users):
            newState.womenUsers = users
        case .setError(let error):
            print("Error: \(error)")
        }
        return newState
    }
}
