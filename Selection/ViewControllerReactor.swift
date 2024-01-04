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
    private func loadData(for gender: Gender, isMoreData: Bool = false) -> Observable<Mutation> {
        let service: RandomUserService = (gender == .male) ? .getMenUsers : .getWomenUsers
        return self.provider.rx.request(service)
            .filterSuccessfulStatusCodes()
            .flatMap { response -> Single<Mutation> in
                do {
                    let userResponse = try response.map(UserResponse.self)
                    let newUsers = userResponse.results
                    if isMoreData {
                        // 기존 사용자 목록에 새 사용자 추가
                        print("\(gender) 추가")
                        let updatedUsers = gender == .male ? self.currentState.menUsers + newUsers : self.currentState.womenUsers + newUsers
                        return Single.just(gender == .male ? Mutation.setMenUsers(updatedUsers) : Mutation.setWomenUsers(updatedUsers))
                    } else {
                        // 새 사용자 목록 설정
                        print("\(gender) 설정")
                        return Single.just(gender == .male ? Mutation.setMenUsers(newUsers) : Mutation.setWomenUsers(newUsers))
                    }
                } catch {
                    return Single.just(Mutation.setError(error))
                }
            }
            .asObservable()
    }
    
    // 초기 상태 설정
    let initialState: State = State(selectedGender: .male, columnLayout: 1, menUsers: [], womenUsers: [])
    let provider = MoyaProvider<RandomUserService>()
    
    func mutate(action: Action) -> Observable<Mutation> {
        let gender = currentState.selectedGender
        switch action {
        case let .selectGender(gender):
            print("\(action)-\(gender)")
            var mutations: [Observable<Mutation>] = [Observable.just(Mutation.setSelectedGender(gender))]
            // 데이터가 없는 경우에만 데이터 로드
            if (gender == .male && currentState.menUsers.isEmpty) ||
                (gender == .female && currentState.womenUsers.isEmpty) {
                mutations.append(loadData(for: gender, isMoreData: false))
            }
            return Observable.concat(mutations)
        case .refreshData:
            print("\(action)-\(gender)")
            return loadData(for: gender, isMoreData: false)
        case .toggleLayout:
            print("\(action)-\(gender)")
            let newLayout = currentState.columnLayout == 1 ? 2 : 1
            return Observable.just(Mutation.setLayout(newLayout))
        case .moreLoadData:
            // 추가 데이터 로드
            print("\(action)-\(gender)")
            return loadData(for: gender, isMoreData: true)
        case let .deleteUser(indexPath):
            print("\(action)-\(gender)")
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
