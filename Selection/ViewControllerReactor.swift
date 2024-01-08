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
import Foundation

class ViewControllerReactor: Reactor {
    
    // 사용자 액션을 나타내는 열거형
    enum Action {
        case selectGender(Gender)
        case toggleLayout
        case refreshData
        case moreLoadData
        case deleteUser(IndexPath)
        
    }
    
    // 상태 변화를 나타내는 열거형
    enum Mutation {
        case setSelectedGender(Gender)
        case setLayout(Int)
        case setMenUsers([User])
        case setWomenUsers([User])
        case deleteUser(IndexPath)
        case setError(Error)
    }
    
    // 뷰의 상태를 나타내는 구조체
    struct State {
        var selectedGender: Gender
        var columnLayout: Int
        var menUsers: [User]
        var womenUsers: [User]
    }
    
    enum Gender {
        case male
        case female
    }
    private func loadData(for gender: Gender, isMoreData: Bool) -> Observable<Mutation> {
        let service: RandomUserService = (gender == .male) ? .getMenUsers : .getWomenUsers
        return provider.rx.request(service)
            .filterSuccessfulStatusCodes()
            .map(UserResponse.self)
            .map { response in
                let newUsers = response.results
                let updatedUsers = isMoreData ? (gender == .male ? self.currentState.menUsers + newUsers : self.currentState.womenUsers + newUsers) : newUsers
                return gender == .male ? Mutation.setMenUsers(updatedUsers) : Mutation.setWomenUsers(updatedUsers)
            }
            .asObservable() // Single을 Observable로 변환
            .catch { error in
                return .just(Mutation.setError(error)) // Observable.just 사용
            }
    }
    // 초기 상태 설정
    let initialState: State = State(selectedGender: .male, columnLayout: 1, menUsers: [], womenUsers: [])
    let provider = MoyaProvider<RandomUserService>()
    
    func mutate(action: Action) -> Observable<Mutation> {
        print("\(action)")
        switch action {
        case let .selectGender(newGender):
            let shouldLoadData = (newGender == .male && currentState.menUsers.isEmpty) || (newGender == .female && currentState.womenUsers.isEmpty)
            let mutations = [Observable.just(Mutation.setSelectedGender(newGender))]
            return shouldLoadData ? Observable.concat(mutations + [loadData(for: newGender, isMoreData: false)]) : Observable.concat(mutations)

        case .refreshData:
            return loadData(for: currentState.selectedGender, isMoreData: false)

        case .toggleLayout:
            let newLayout = currentState.columnLayout == 1 ? 2 : 1
            return Observable.just(Mutation.setLayout(newLayout))

        case .moreLoadData:
            return loadData(for: currentState.selectedGender, isMoreData: true)

        case let .deleteUser(indexPath):
            return Observable.just(Mutation.deleteUser(indexPath))
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
        case let .deleteUser( indexPath):
            if newState.selectedGender == .male {
                newState.menUsers.remove(at: indexPath.row)
            } else {
                newState.womenUsers.remove(at: indexPath.row)
            }
        case .setError(let error):
            print("Error: \(error)")
        }
        return newState
    }
}
