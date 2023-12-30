//
//  ViewReactor.swift
//  Selection
//
//  Created by 김정원 on 12/27/23.
//
import ReactorKit
import RxSwift

import Moya

class ViewReactor: Reactor {
    // Moya Provider 정의 (여기서는 예시 API 서비스를 가정합니다)
    let provider = MoyaProvider<YourAPIService>()

    enum Action {
        case updateSegment(Int)
        case fetchData
    }

    enum Mutation {
        case setSegmentIndex(Int)
        case setData(SomeDataType)
        case setError(Error)
    }

    struct State {
        var selectedIndex: Int
        var data: SomeDataType?
        var error: Error?
    }

    let initialState: State

    init() {
        self.initialState = State(selectedIndex: 0, data: nil, error: nil)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateSegment(let index):
            return Observable.just(Mutation.setSegmentIndex(index))

        case .fetchData:
            return provider.rx.request(.fetchData)
                .map(SomeDataType.self) // 'SomeDataType'를 자신의 데이터 타입으로 변경
                .asObservable()
                .map(Mutation.setData)
                .catchError { Observable.just(Mutation.setError($0)) }
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setSegmentIndex(let index):
            newState.selectedIndex = index
        case .setData(let data):
            newState.data = data
            newState.error = nil
        case .setError(let error):
            newState.error = error
        }
        return newState
    }
}
