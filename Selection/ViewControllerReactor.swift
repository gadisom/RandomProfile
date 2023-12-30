//
//  ViewControllerReactor.swift
//  Selection
//
//  Created by 김정원 on 12/27/23.
//

import ReactorKit

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
    }
    
    // 뷰의 상태를 나타내는 구조체
    struct State {
        var selectedGender: Gender
        var columnLayout :Int
    }
    
    // 성별을 나타내는 열거형
    enum Gender {
        case male
        case female
    }
    
    // 초기 상태 설정
    let initialState: State = State(selectedGender: .male, columnLayout: 1)

    // 액션을 뮤테이션으로 변환하는 함수
    func mutate(action: Action) -> Observable<Mutation> {
           switch action {
           case let .selectGender(gender):
               return Observable.just(Mutation.setSelectedGender(gender))
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
                newState.columnLayout = layout // Int 타입으로 업데이트
            }
            return newState
        }
}



